import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from lanzador import preparar, ejecutar


class LanzadorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.path = self.root / 'servidor.json'
        (self.root / 'autoridad.crt').write_text('fixture')

    def config(self, **kwargs):
        self.path.write_text(json.dumps({'autoridad': 'autoridad.crt'} | kwargs))

    def test_crea_config_privado_sin_autoridad(self):
        cfg = preparar(self.path)
        self.assertTrue(cfg["privado"])
        self.assertEqual(cfg["autoridad"], "")
        self.assertTrue(self.path.exists())

    def test_exige_autoridad(self):
        self.config(autoridad='', privado=False)
        with self.assertRaisesRegex(ValueError, 'Falta autoridad'):
            preparar(self.path)

    def test_valida_puertos(self):
        for value in [0, 65536, True, '7777']:
            self.config(puerto=value)
            with self.assertRaises(ValueError):
                preparar(self.path)

    def test_resuelve_rutas_relativas(self):
        self.config()
        self.assertEqual(preparar(self.path)['autoridad'], str(self.root / 'autoridad.crt'))

    def test_no_destruye_config_y_no_expone_password_en_argumentos(self):
        self.config(password='secreto')
        original = self.path.read_bytes()
        with patch('lanzador.subprocess.Popen') as popen:
            popen.return_value.wait.return_value = 0
            self.assertEqual(ejecutar('godot', self.path), 0)
            args = popen.call_args.args[0]
            self.assertNotIn('secreto', ' '.join(args))
            self.assertNotIn('--config=' + str(self.path), args)
        self.assertEqual(self.path.read_bytes(), original)
        self.assertEqual(list((self.root / 'mundos/amigos').glob('arranque_*')), [])

    def test_ctrl_c_solicita_guardar_sin_matar_motor(self):
        self.config()
        with patch('lanzador.subprocess.Popen') as popen:
            proc = popen.return_value
            proc.wait.side_effect = KeyboardInterrupt
            proc.poll.return_value = 0
            proc.returncode = 0
            self.assertEqual(ejecutar('godot', self.path), 0)
            proc.kill.assert_not_called()
        folder = self.root / 'mundos/amigos'
        self.assertTrue((folder / 'detener_servidor').exists())
        self.assertEqual(list(folder.glob('arranque_*')), [])

    def test_limpia_temporal_si_falla_motor(self):
        self.config()
        with patch('lanzador.subprocess.Popen', side_effect=FileNotFoundError):
            with self.assertRaises(FileNotFoundError):
                ejecutar('inexistente', self.path)
        self.assertEqual(list((self.root / 'mundos/amigos').glob('arranque_*')), [])


if __name__ == '__main__':
    unittest.main()
