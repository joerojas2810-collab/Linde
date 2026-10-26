import importlib.util
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('servicio', Path(__file__).with_name('servicio.py'))
s = importlib.util.module_from_spec(spec)
spec.loader.exec_module(s)

class AccountsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.folder = Path(self.tmp.name)
        self.a = s.Accounts(self.folder)
    def tearDown(self):
        self.tmp.cleanup()
    def data(self, user='amigo1', password='PruebaSegura123!'):
        return dict(usuario=user, password=password, nombre='El Rayo', servidor_password='')
    def test_registration_login_and_unique_identity(self):
        first = self.a.auth('registro', self.data(), '127.0.0.1')
        second = self.a.auth('login', self.data(), '127.0.0.1')
        self.assertEqual(self.a.claim(first)['id'], self.a.claim(second)['id'])
        other = self.a.auth('registro', self.data('amigo2'), '127.0.0.2')
        self.assertTrue(self.a.claim(other)['id'].startswith('cuenta:'))
        with self.assertRaises(s.Rejected): self.a.claim(first)
        with self.assertRaises(s.Rejected): self.a.auth('registro', self.data(), '127.0.0.1')
        with self.assertRaises(s.Rejected): self.a.auth('login', self.data(password='Incorrecta123!'), '127.0.0.1')
        with self.a.db() as db:
            hashes = db.execute('SELECT password FROM accounts').fetchall()
        self.assertTrue(all(row[0].startswith('$argon2id$') for row in hashes))
        self.assertNotEqual(hashes[0][0], hashes[1][0])
    def test_private_server_separate_password(self):
        with self.a.db() as db: db.execute("INSERT INTO meta VALUES('server_password',?)", (s.PH.hash('Privado123!'),))
        with self.assertRaises(s.Rejected): self.a.auth('registro', self.data(), '127.0.0.1')
        d=self.data();d['servidor_password']='Privado123!'
        self.assertTrue(self.a.auth('registro', d, '127.0.0.1')['ok'])
    def test_expiration_limits_and_backup(self):
        ticket = self.a.auth('registro', self.data(), '127.0.0.1')
        with self.a.db() as db: db.execute('UPDATE tickets SET expires=0')
        with self.assertRaises(s.Rejected): self.a.claim(ticket)
        for _ in range(8): self.a.limit('192.0.2.1', 'limitado')
        with self.assertRaises(s.Rejected) as cm: self.a.limit('192.0.2.1', 'limitado')
        self.assertEqual(cm.exception.status,429)
        self.a.backup()
        with sqlite3.connect(self.folder/'cuentas.respaldo.sqlite3') as db:
            self.assertEqual(db.execute('PRAGMA integrity_check').fetchone()[0],'ok')
        db.close()
    def test_password_without_minimum_length(self):
        first = self.a.auth('registro', self.data(password='x'), '127.0.0.1', identidad=True)
        second = self.a.auth('login', self.data(password='x'), '127.0.0.1', identidad=True)
        self.assertEqual(first['id'], second['id'])
        for password in ('', 'x' * 129):
            with self.assertRaises(s.Rejected):
                self.a.auth('registro', self.data('otro', password), '127.0.0.1', identidad=True)
    def test_certificate_reused(self):
        fp=s.certificate(self.folder)
        self.assertEqual(fp,s.certificate(self.folder))
        self.assertEqual(len(fp),64)

if __name__=='__main__': unittest.main(verbosity=2)
