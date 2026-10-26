"""Cuentas locales de Linde. SQLite contiene identidades, nunca personajes/mundo.

HTTPS autentica la cuenta y emite tickets efímeros de un solo uso. Solo el proceso
Godot, con una clave local independiente, puede consumirlos. ENet usa DTLS.
"""
from __future__ import annotations

import argparse
import collections
from contextlib import contextmanager
import datetime as dt
import hashlib
import hmac
import ipaddress
import json
import os
from pathlib import Path
import re
import secrets
import sqlite3
import ssl
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, VerificationError
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
import jwt
from identidad import Identidad, TOLERANCIA_SEGUNDOS, huella, verificar

PH = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=4)
MAX_BODY = 4096
TICKET_SECONDS = 30
USER = re.compile(r"[a-z0-9_-]{3,24}\Z")


class Rejected(Exception):
    def __init__(self, message: str, status: int = 400):
        self.message, self.status = message, status


def atomic(path: Path, data: bytes, private: bool = True):
    tmp = path.with_suffix(path.suffix + ".tmp")
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600 if private else 0o644)
    with os.fdopen(fd, "wb") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def certificate(folder: Path):
    key_file, cert_file = folder / "servidor.key", folder / "servidor.crt"
    if key_file.exists() != cert_file.exists():
        raise RuntimeError("Certificado incompleto; restaura el par .key/.crt del respaldo")
    if not key_file.exists():
        key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "linde.local")])
        now = dt.datetime.now(dt.timezone.utc)
        cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name)
                .public_key(key.public_key()).serial_number(x509.random_serial_number())
                .not_valid_before(now - dt.timedelta(minutes=5))
                .not_valid_after(now + dt.timedelta(days=3650))
                .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
                .add_extension(x509.SubjectAlternativeName([x509.DNSName("linde.local")]), critical=False)
                .sign(key, hashes.SHA256()))
        atomic(key_file, key.private_bytes(serialization.Encoding.PEM,
               serialization.PrivateFormat.TraditionalOpenSSL, serialization.NoEncryption()))
        atomic(cert_file, cert.public_bytes(serialization.Encoding.PEM), False)
    cert = x509.load_pem_x509_certificate(cert_file.read_bytes())
    return cert.fingerprint(hashes.SHA256()).hex()


class Accounts:
    def __init__(self, folder: Path):
        self.folder = folder
        self.path = folder / "cuentas.sqlite3"
        self.lock = threading.RLock()
        self.gate = threading.BoundedSemaphore(2)  # máximo 128 MiB simultáneos de Argon2
        self.attempts: dict[str, collections.deque] = {}
        self.dummy = PH.hash(secrets.token_urlsafe(32))
        with self.db() as db:
            db.executescript("""
                CREATE TABLE IF NOT EXISTS accounts(
                  id TEXT PRIMARY KEY, username TEXT UNIQUE NOT NULL,
                  password TEXT NOT NULL, display TEXT NOT NULL, created INTEGER NOT NULL);
                CREATE TABLE IF NOT EXISTS tickets(
                  hash TEXT PRIMARY KEY, account TEXT NOT NULL REFERENCES accounts(id), expires REAL NOT NULL);
                CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
                CREATE TABLE IF NOT EXISTS admisiones(
                  hash TEXT PRIMARY KEY, account TEXT NOT NULL, display TEXT NOT NULL, expires REAL NOT NULL);
                CREATE TABLE IF NOT EXISTS permisos_usados(jti TEXT PRIMARY KEY, expires REAL NOT NULL);
            """)

    @contextmanager
    def db(self):
        db = sqlite3.connect(self.path, timeout=5)
        db.execute("PRAGMA journal_mode=WAL")
        db.execute("PRAGMA synchronous=FULL")
        db.execute("PRAGMA foreign_keys=ON")
        try:
            yield db
            db.commit()
        except BaseException:
            db.rollback()
            raise
        finally:
            db.close()

    def limit(self, ip: str, username: str):
        now = time.monotonic()
        with self.lock:
            if len(self.attempts) > 4096:
                self.attempts = {k: v for k, v in self.attempts.items() if v and v[-1] > now - 60}
            if len(self.attempts) >= 8192 and ("ip:" + ip) not in self.attempts:
                raise Rejected("Servidor ocupado. Intenta en un minuto.", 429)
            for key, cap in [("ip:" + ip, 15), ("user:" + username, 8)]:
                q = self.attempts.setdefault(key, collections.deque())
                while q and q[0] < now - 60:
                    q.popleft()
                if len(q) >= cap:
                    raise Rejected("Demasiados intentos. Espera un minuto.", 429)
                q.append(now)

    @staticmethod
    def verify(encoded: str, password: str) -> bool:
        try:
            return PH.verify(encoded, password)
        except (VerifyMismatchError, VerificationError):
            return False

    def auth(self, action: str, data: dict, ip: str, identidad: bool = False) -> dict:
        username = data.get("usuario", "")
        password = data.get("password", "")
        server_password = data.get("servidor_password", "")
        if not all(isinstance(x, str) for x in (username, password, server_password)):
            raise Rejected("Campos inválidos")
        username = username.strip().lower()
        if not USER.fullmatch(username) or not password or len(password) > 128 or len(server_password) > 128:
            raise Rejected("Usuario: 3–24 letras sin acentos, cifras, _ o -. Contraseña obligatoria, máximo 128 caracteres.")
        self.limit(ip, username)
        if not self.gate.acquire(blocking=False):
            raise Rejected("Servidor ocupado. Intenta en unos segundos.", 429)
        try:
            with self.db() as db:
                world_pass = db.execute("SELECT value FROM meta WHERE key='server_password'").fetchone()
                if world_pass and world_pass[0] and not self.verify(world_pass[0], server_password):
                    raise Rejected("Contraseña del servidor incorrecta.", 403)
                row = db.execute("SELECT id,password,display FROM accounts WHERE username=?", (username,)).fetchone()
                if action == "registro":
                    display = data.get("nombre", username)
                    if not isinstance(display, str) or not 2 <= len(display.strip()) <= 16 or any(ord(c) < 32 for c in display):
                        raise Rejected("Nombre del personaje: 2–16 caracteres.")
                    if row:
                        raise Rejected("Ese usuario ya existe.", 409)
                    account = "cuenta:" + uuid.uuid4().hex
                    try:
                        db.execute("INSERT INTO accounts VALUES(?,?,?,?,?)",
                                   (account, username, PH.hash(password), display.strip(), int(time.time())))
                    except sqlite3.IntegrityError:
                        raise Rejected("Ese usuario ya existe.", 409)
                    row = (account, "", display.strip())
                else:
                    valid = self.verify(row[1] if row else self.dummy, password)
                    if not row or not valid:
                        raise Rejected("Usuario o contraseña incorrectos.", 401)
                    if PH.check_needs_rehash(row[1]):
                        db.execute("UPDATE accounts SET password=? WHERE id=?", (PH.hash(password), row[0]))
                if identidad:
                    return {"ok": True, "id": row[0], "nombre": row[2]}
                ticket = secrets.token_urlsafe(32)
                db.execute("DELETE FROM tickets WHERE expires<?", (time.time(),))
                db.execute("INSERT INTO tickets VALUES(?,?,?)",
                           (hashlib.sha256(ticket.encode()).hexdigest(), row[0], time.time() + TICKET_SECONDS))
            return {"ok": True, "ticket": ticket, "nombre": row[2]}
        finally:
            self.gate.release()

    def claim(self, data: dict) -> dict:
        ticket = data.get("ticket", "")
        if not isinstance(ticket, str) or not 32 <= len(ticket) <= 64:
            raise Rejected("Ticket inválido", 401)
        key = hashlib.sha256(ticket.encode()).hexdigest()
        with self.lock, self.db() as db:
            db.execute("BEGIN IMMEDIATE")
            admision = db.execute("SELECT account,display,expires FROM admisiones WHERE hash=?", (key,)).fetchone()
            if admision and admision[2] >= time.time():
                db.execute("DELETE FROM admisiones WHERE hash=?", (key,))
                return {"ok": True, "id": admision[0], "nombre": admision[1]}
            row = db.execute("SELECT a.id,a.display,t.expires FROM tickets t JOIN accounts a ON t.account=a.id WHERE t.hash=?", (key,)).fetchone()
            db.execute("DELETE FROM tickets WHERE hash=?", (key,))
            if not row or row[2] < time.time():
                raise Rejected("La sesión de acceso caducó. Inicia sesión de nuevo.", 401)
        return {"ok": True, "id": row[0], "nombre": row[1]}

    def admitir(self, claims: dict, password: str, ip: str) -> dict:
        """Permiso firmado ya validado: concede solo entrada, nunca crea otra cuenta."""
        if not isinstance(password, str) or len(password) > 128:
            raise Rejected("Contraseña del servidor inválida")
        self.limit(ip, claims["sub"])
        if not self.gate.acquire(False):
            raise Rejected("Servidor ocupado. Intenta en unos segundos.", 429)
        try:
            with self.db() as db:
                row = db.execute("SELECT value FROM meta WHERE key='server_password'").fetchone()
                if row and row[0] and not self.verify(row[0], password):
                    raise Rejected("Contraseña del servidor incorrecta.", 403)
                db.execute("DELETE FROM permisos_usados WHERE expires<?", (time.time(),))
                db.execute("DELETE FROM admisiones WHERE expires<?", (time.time(),))
                try:
                    db.execute("INSERT INTO permisos_usados VALUES(?,?)", (claims["jti"], claims["exp"] + TOLERANCIA_SEGUNDOS))
                except sqlite3.IntegrityError:
                    raise Rejected("Este permiso ya se utilizó. Vuelve a conectar.", 401)
                ticket = secrets.token_urlsafe(32)
                db.execute("INSERT INTO admisiones VALUES(?,?,?,?)", (hashlib.sha256(ticket.encode()).hexdigest(),
                           claims["sub"], claims["name"], time.time() + TICKET_SECONDS))
            return {"ok": True, "ticket": ticket}
        finally:
            self.gate.release()

    def backup(self):
        with self.db() as source:
            dest = sqlite3.connect(self.folder / "cuentas.respaldo.sqlite3")
            try:
                source.backup(dest)
            finally:
                dest.close()


class LimitedServer(ThreadingHTTPServer):
    daemon_threads = True
    request_queue_size = 16
    def __init__(self, *args):
        self.slots = threading.BoundedSemaphore(16)
        super().__init__(*args)

    def process_request(self, request, address):
        if not self.slots.acquire(False):
            self.shutdown_request(request)
            return
        try:
            super().process_request(request, address)
        except BaseException:
            self.slots.release()
            raise

    def process_request_thread(self, request, address):
        try:
            # El handshake no bloquea accept(): también está limitado a 16 hilos / 5 s.
            request.settimeout(5)
            request = self.tls_context.wrap_socket(request, server_side=True)
            super().process_request_thread(request, address)
        except (ssl.SSLError, OSError):
            self.shutdown_request(request)
        finally:
            self.slots.release()


def serve(folder: Path, host: str, port: int, rol="legado", autoridad: Path | None = None):
    accounts = Accounts(folder)
    control = (folder / "control.key").read_text().strip()
    identidad = Identidad(folder) if rol == "identidad" else None
    if rol == "mundo" and (autoridad is None or not autoridad.is_file()):
        raise RuntimeError("El mundo necesita el certificado de la autoridad de cuentas")
    class Handler(BaseHTTPRequestHandler):
        def setup(self):
            super().setup()
            self.connection.settimeout(5)

        def log_message(self, *_):
            pass  # Nunca registrar credenciales, tickets ni cuerpos.

        def respond(self, code, result):
            body = json.dumps(result, ensure_ascii=False).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path == "/estado":
                self.respond(200, {"ok": True, "rol": rol})
            else:
                self.respond(404, {"ok": False, "motivo": "Ruta desconocida"})

        def do_POST(self):
            try:
                length = int(self.headers.get("Content-Length", "0"))
                if not 1 <= length <= MAX_BODY:
                    raise Rejected("Petición demasiado grande", 413)
                data = json.loads(self.rfile.read(length))
                if not isinstance(data, dict):
                    raise Rejected("Petición inválida")
                if self.path in ("/registro", "/login"):
                    if rol == "mundo":
                        raise Rejected("Inicia sesión en Linde antes de elegir un mundo.", 403)
                    result = accounts.auth(self.path[1:], data, self.client_address[0], identidad=rol == "identidad")
                    if identidad:
                        token, expires = identidad.emitir(result["id"], result["nombre"])
                        result.update(token=token, exp=expires)
                elif self.path == "/permiso" and identidad:
                    result = {"ok": True, "permiso": identidad.permiso(data.get("token", ""), data.get("destino", ""))}
                elif self.path == "/admitir" and rol == "mundo":
                    claims = verificar(data.get("permiso", ""), autoridad, "linde-mundo:" + huella(folder / "servidor.crt"))
                    result = accounts.admitir(claims, data.get("servidor_password", ""), self.client_address[0])
                elif self.path == "/consumir":
                    if rol == "identidad":raise Rejected("Este servicio no aloja partidas.", 403)
                    if not ipaddress.ip_address(self.client_address[0]).is_loopback or not hmac.compare_digest(self.headers.get("X-Linde-Control", ""), control):
                        raise Rejected("No autorizado", 403)
                    result = accounts.claim(data)
                else:
                    raise Rejected("Ruta desconocida", 404)
                self.respond(200, result)
            except Rejected as e:
                self.respond(e.status, {"ok": False, "motivo": e.message})
            except jwt.PyJWTError:
                self.respond(401, {"ok": False, "motivo": "La sesión no es válida o ha caducado. Inicia sesión de nuevo."})
            except (ValueError, TypeError, UnicodeError):
                self.respond(400, {"ok": False, "motivo": "Petición inválida"})
            except Exception:
                self.respond(500, {"ok": False, "motivo": "Error interno de cuentas"})

    server = LimitedServer((host, port), Handler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.minimum_version = ssl.TLSVersion.TLSv1_2
    ctx.load_cert_chain(folder / "servidor.crt", folder / "servidor.key")
    server.tls_context = ctx
    def watch():
        last_backup = time.monotonic()
        while True:
            time.sleep(1)
            heartbeat = folder / "latido"
            if (folder / "detener_cuentas").exists() or (rol != "identidad" and heartbeat.exists() and time.time() - heartbeat.stat().st_mtime > 20):
                server.shutdown()
                return
            if time.monotonic() - last_backup > 60:
                accounts.backup()
                last_backup = time.monotonic()
    threading.Thread(target=watch, daemon=True).start()
    try:
        server.serve_forever(poll_interval=0.2)
    finally:
        server.server_close()
        accounts.backup()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--datos", type=Path, required=True)
    parser.add_argument("--iniciar", action="store_true")
    parser.add_argument("--config", type=Path)
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--puerto", type=int, default=7778)
    args = parser.parse_args()
    args.datos.mkdir(parents=True, exist_ok=True)
    # También la inicialización se bloquea: otro arranque no puede cambiar la
    # contraseña del servidor activo antes de descubrir que el puerto está ocupado.
    lockfile = open(args.datos / "servidor.lock", "a+b")
    if os.name == "nt":
        import msvcrt
        lockfile.write(b"0"); lockfile.flush(); lockfile.seek(0)
        msvcrt.locking(lockfile.fileno(), msvcrt.LK_NBLCK, 1)
    else:
        import fcntl
        fcntl.flock(lockfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
    rol = "legado"
    autoridad = None
    if args.iniciar or args.config:
        config = json.loads(args.config.read_text(encoding="utf-8-sig")) if args.config else {}
        if args.config:
            args.config.unlink()
        rol = config.get("rol", "legado")
        if rol not in ("identidad", "mundo", "legado"):raise ValueError("Rol de cuentas inválido")
        autoridad = Path(config["autoridad"]) if config.get("autoridad") else None
        fingerprint = certificate(args.datos)
        accounts = Accounts(args.datos)
        password = config.get("password", "") if rol != "identidad" else ""
        if not isinstance(password, str) or len(password) > 128:
            raise ValueError("Contraseña del servidor inválida")
        with accounts.db() as db:
            db.execute("INSERT OR REPLACE INTO meta VALUES('server_password',?)", (PH.hash(password) if password else "",))
        if not (args.datos / "control.key").exists():
            atomic(args.datos / "control.key", secrets.token_urlsafe(32).encode())
        accounts.backup()
        info = {"ok": True, "huella": fingerprint}
        nonce = config.get("inicio", "")
        if nonce and not re.fullmatch(r"[a-f0-9]{32}", nonce):
            raise ValueError("Identificador de arranque inválido")
        atomic(args.datos / ("backend_estado_" + nonce + ".json" if nonce else "backend_estado.json"), json.dumps(info).encode())
        if args.iniciar:
            print(json.dumps(info))
    if not args.iniciar:
        serve(args.datos, args.host, args.puerto, rol, autoridad)


if __name__ == "__main__":
    main()
