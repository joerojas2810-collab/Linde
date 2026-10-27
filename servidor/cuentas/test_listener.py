"""El listener de acceso no debe depender de DNS inverso para empezar a escuchar."""
from http.server import BaseHTTPRequestHandler
import unittest
from unittest.mock import patch

from servicio import LimitedServer


class ListenerTests(unittest.TestCase):
    def test_bind_no_consulta_dns_inverso(self):
        with patch('socket.getfqdn', side_effect=AssertionError('DNS inverso inesperado')):
            server = LimitedServer(('127.0.0.1', 0), BaseHTTPRequestHandler)
            try:
                self.assertEqual(server.server_name, '127.0.0.1')
                self.assertGreater(server.server_port, 0)
            finally:
                server.server_close()
