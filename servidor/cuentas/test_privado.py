"""HTTPS real del modo privado; no necesita Godot ni usa datos de jugadores."""
import http.client
import json
from pathlib import Path
import socket
import ssl
import subprocess
import sys
import tempfile
import time
import unittest

from identidad import huella


class PrivadoHTTPS(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.folder = Path(cls.tmp.name)
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            cls.port = sock.getsockname()[1]
        cfg = cls.folder / 'inicio.json'
        cfg.write_text(json.dumps({'rol': 'privado', 'password': 'amigos'}))
        cls.proc = subprocess.Popen([sys.executable, str(Path(__file__).with_name('servicio.py')),
            '--datos', str(cls.folder), '--config', str(cfg), '--host', '127.0.0.1', '--puerto', str(cls.port)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            for _ in range(100):
                try:
                    if cls.request('/estado')[1].get('rol') == 'privado':
                        return
                except (OSError, ssl.SSLError):
                    pass
                if cls.proc.poll() is not None:
                    raise RuntimeError('El servicio privado terminó al iniciar')
                time.sleep(.1)
            raise TimeoutError('El servicio privado no inició')
        except BaseException:
            cls.proc.kill(); cls.proc.wait(); cls.tmp.cleanup()
            raise

    @classmethod
    def tearDownClass(cls):
        (cls.folder / 'detener_cuentas').write_text('cerrar')
        try:
            cls.proc.wait(timeout=8)
        finally:
            if cls.proc.poll() is None:
                cls.proc.kill(); cls.proc.wait()
            cls.tmp.cleanup()

    @classmethod
    def request(cls, path, data=None, internal=False):
        context = ssl.create_default_context(cafile=str(cls.folder / 'servidor.crt'))
        conn = http.client.HTTPConnection('127.0.0.1', cls.port, timeout=5)
        conn.sock = context.wrap_socket(socket.create_connection(('127.0.0.1', cls.port), timeout=5), server_hostname='linde.local')
        try:
            headers = {'Content-Type': 'application/json'}
            if internal:
                headers['X-Linde-Control'] = (cls.folder / 'control.key').read_text().strip()
            conn.request('GET' if data is None else 'POST', path,
                         None if data is None else json.dumps(data), headers)
            res = conn.getresponse()
            return res.status, json.loads(res.read())
        finally:
            conn.close()

    def test_certificado_publico_coincide(self):
        status, info = self.request('/certificado')
        self.assertEqual(status, 200)
        self.assertEqual(info['huella'], huella(self.folder / 'servidor.crt'))
        self.assertEqual(info['certificado'], (self.folder / 'servidor.crt').read_text())
        self.assertNotIn('PRIVATE KEY', info['certificado'])

    def test_identidad_persiste_y_no_se_suplanta_por_nombre(self):
        data = dict(usuario='p0123456789abcdef012345', password='credencial-aleatoria', nombre='Amigo', servidor_password='amigos')
        status, first = self.request('/privado', data)
        self.assertEqual(status, 200, first)
        status, back = self.request('/privado', data)
        self.assertEqual(status, 200, back)
        _, first_id = self.request('/consumir', {'ticket': first['ticket']}, internal=True)
        _, back_id = self.request('/consumir', {'ticket': back['ticket']}, internal=True)
        self.assertEqual(first_id['id'], back_id['id'])
        self.assertNotEqual(self.request('/consumir', {'ticket': first['ticket']}, internal=True)[0], 200)
        self.assertNotEqual(first['ticket'], back['ticket'])
        status, _ = self.request('/privado', data | {'password': 'otro-secreto'})
        self.assertNotEqual(status, 200)

    def test_password_mundo_se_exige_antes_de_registrar(self):
        status, _ = self.request('/privado', dict(usuario='otraidentidad', password='secreto', nombre='Otro', servidor_password='incorrecta'))
        self.assertEqual(status, 403)

    def test_consumir_ticket_no_es_publico(self):
        status, _ = self.request('/consumir', {'ticket': 'falso'})
        self.assertEqual(status, 403)
