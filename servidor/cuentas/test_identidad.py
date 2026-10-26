import tempfile
from pathlib import Path
import unittest
import jwt
from identidad import Identidad,verificar,huella
from servicio import Accounts,certificate,Rejected

class IdentidadTest(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.root=Path(self.tmp.name)
        self.global_dir=self.root/'identidad';self.world=self.root/'mundo'
        self.global_dir.mkdir();self.world.mkdir();certificate(self.global_dir);certificate(self.world)
        self.accounts=Accounts(self.global_dir);self.game=Accounts(self.world)
        self.identity=Identidad(self.global_dir)
        self.account=self.accounts.auth('registro',{'usuario':'rayo','password':'ClaveLinde123!','nombre':'El Rayo'},'127.0.0.1',identidad=True)
    def tearDown(self):self.tmp.cleanup()
    def test_session_stable_and_password_not_copied_to_world(self):
        login=self.accounts.auth('login',{'usuario':'rayo','password':'ClaveLinde123!'},'127.0.0.2',identidad=True)
        self.assertEqual(self.account['id'],login['id'])
        token,_=self.identity.emitir(login['id'],login['nombre'])
        self.assertEqual(verificar(token,self.identity.cert,'linde-sesion')['sub'],login['id'])
        with self.game.db() as db:self.assertEqual(db.execute('SELECT count(*) FROM accounts').fetchone()[0],0)
    def test_permit_bound_to_world_and_single_use(self):
        token,_=self.identity.emitir(self.account['id'],self.account['nombre'])
        permit=self.identity.permiso(token,huella(self.world/'servidor.crt'))
        claims=verificar(permit,self.identity.cert,'linde-mundo:'+huella(self.world/'servidor.crt'))
        ticket=self.game.admitir(claims,'','127.0.0.1')
        self.assertEqual(self.game.claim(ticket)['id'],self.account['id'])
        with self.assertRaises(Rejected):self.game.admitir(claims,'','127.0.0.1')
        with self.assertRaises(Rejected):self.game.claim(ticket)
        with self.assertRaises(jwt.PyJWTError):verificar(permit,self.identity.cert,'linde-mundo:otro')
        with self.assertRaises(jwt.PyJWTError):verificar(token,self.identity.cert,'linde-mundo:'+huella(self.world/'servidor.crt'))
        # El margen de reloj no permite reutilizar un permiso cerca de su caducidad.
        grace,_=self.identity.emitir(self.account['id'],self.account['nombre'],'linde-mundo:'+huella(self.world/'servidor.crt'),seconds=-1)
        grace_claims=verificar(grace,self.identity.cert,'linde-mundo:'+huella(self.world/'servidor.crt'))
        self.game.admitir(grace_claims,'','127.0.0.1')
        with self.assertRaises(Rejected):self.game.admitir(grace_claims,'','127.0.0.1')
    def test_rejects_expiry_wrong_issuer_signature_and_algorithm(self):
        expired,_=self.identity.emitir(self.account['id'],self.account['nombre'],seconds=-10)
        with self.assertRaises(jwt.PyJWTError):verificar(expired,self.identity.cert,'linde-sesion')
        good,_=self.identity.emitir(self.account['id'],self.account['nombre'])
        with self.assertRaises(jwt.PyJWTError):verificar(good,self.world/'servidor.crt','linde-sesion')
        unsigned=jwt.encode({'sub':self.account['id']},key='',algorithm='none')
        with self.assertRaises(jwt.PyJWTError):verificar(unsigned,self.identity.cert,'linde-sesion')
    def test_world_password_is_independent(self):
        from servicio import PH
        with self.game.db() as db:db.execute("INSERT INTO meta VALUES('server_password',?)",(PH.hash('OtraClave123!'),))
        token,_=self.identity.emitir(self.account['id'],self.account['nombre'])
        permit=self.identity.permiso(token,huella(self.world/'servidor.crt'))
        claims=verificar(permit,self.identity.cert,'linde-mundo:'+huella(self.world/'servidor.crt'))
        with self.assertRaises(Rejected):self.game.admitir(claims,'ClaveLinde123!','127.0.0.1')
        self.assertTrue(self.game.admitir(claims,'OtraClave123!','127.0.0.1')['ok'])

if __name__=='__main__':unittest.main(verbosity=2)
