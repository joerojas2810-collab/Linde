"""Identidad de Linde independiente del mundo, con RS256 de PyJWT.

El token de sesión nunca se entrega a un servidor de juego: se canjea ante la
autoridad por un permiso breve ligado al certificado de ese mundo concreto.
"""
import re
import time
import uuid
from pathlib import Path

import jwt
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization

SESION_SEGUNDOS = 2 * 60 * 60
PERMISO_SEGUNDOS = 60
TOLERANCIA_SEGUNDOS = 5


def certificado(path: Path):
    return x509.load_pem_x509_certificate(path.read_bytes())


def huella(path: Path) -> str:
    return certificado(path).fingerprint(hashes.SHA256()).hex()


def verificar(token: str, cert_path: Path, audiencia: str) -> dict:
    if not isinstance(token, str) or not 32 <= len(token) <= 8192:
        raise ValueError("Token inválido")
    cert = certificado(cert_path)
    public = cert.public_key()
    claims = jwt.decode(token, public, algorithms=["RS256"], audience=audiencia,
                        issuer="linde:" + huella(cert_path), leeway=TOLERANCIA_SEGUNDOS,
                        options={"require": ["sub", "name", "iss", "aud", "iat", "exp", "jti"]})
    if (not re.fullmatch(r"cuenta:[a-f0-9]{32}", claims["sub"])
            or not isinstance(claims["name"], str) or not 2 <= len(claims["name"]) <= 16
            or not isinstance(claims["jti"], str) or not re.fullmatch(r"[a-f0-9]{32}", claims["jti"])
            or type(claims["exp"]) is not int or type(claims["iat"]) is not int):
        raise ValueError("Identidad inválida")
    return claims


class Identidad:
    def __init__(self, folder: Path):
        self.cert = folder / "servidor.crt"
        self.key = serialization.load_pem_private_key((folder / "servidor.key").read_bytes(), password=None)

    def emitir(self, account: str, name: str, audience="linde-sesion", seconds=SESION_SEGUNDOS) -> tuple[str, int]:
        now = int(time.time())
        claims = dict(sub=account, name=name, aud=audience, iss="linde:" + huella(self.cert),
                      iat=now, exp=now + seconds, jti=uuid.uuid4().hex)
        return jwt.encode(claims, self.key, algorithm="RS256"), claims["exp"]

    def permiso(self, session: str, destino: str) -> str:
        if not isinstance(destino, str) or not re.fullmatch(r"[a-f0-9]{64}", destino):
            raise ValueError("Certificado de mundo inválido")
        claims = verificar(session, self.cert, "linde-sesion")
        return self.emitir(claims["sub"], claims["name"], "linde-mundo:" + destino, PERMISO_SEGUNDOS)[0]
