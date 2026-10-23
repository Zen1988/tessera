import os
import unittest
import urllib.error
from unittest.mock import MagicMock, patch
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import monitor
import recovery

class APIFailoverTests(unittest.TestCase):
    def env(self):
        return patch.dict(os.environ, {'KUBERNETES_SERVICE_HOST':'10.96.0.1','KUBERNETES_SERVICE_PORT_HTTPS':'443','TESSERA_API_ENDPOINTS':'https://10.0.1.61:6443,https://10.0.1.62:6443,https://10.0.1.63:6443'})
    def test_read_fails_over_and_keeps_endpoint(self):
        with self.env(): api=monitor.Kube()
        sa=MagicMock();(sa/'token').read_text.return_value='token'
        with patch.object(monitor,'SA',sa),patch.object(monitor,'get_json',side_effect=[urllib.error.URLError('down'),urllib.error.URLError('down'),{'ok':True}]) as get:
            self.assertEqual(api.get('/api'),{'ok':True})
            self.assertEqual(api.base,'https://10.0.1.62:6443')
            self.assertEqual(get.call_count,3)
    def test_rbac_denial_not_retried(self):
        with self.env(): api=monitor.Kube()
        with patch.object(monitor,'SA',MagicMock()),patch.object(monitor,'get_json',side_effect=urllib.error.HTTPError('url',403,'Forbidden',{},None)) as get:
            with self.assertRaises(urllib.error.HTTPError):api.get('/api')
            self.assertEqual(get.call_count,1)
    def test_no_plaintext_or_credentials_in_origins(self):
        for value in ('http://10.0.1.61:6443','https://user:password@10.0.1.61:6443','https://10.0.1.61:6443/path'):
            with patch.dict(os.environ,{'TESSERA_API_ENDPOINTS':value}):
                with self.assertRaises(ValueError):monitor.Kube()
    def test_uncertain_mutation_is_never_replayed(self):
        with self.env(): api=recovery.API()
        sa=MagicMock();(sa/'token').read_text.return_value='token'
        opener=MagicMock();opener.open.side_effect=TimeoutError('uncertain')
        with patch.object(api,'get',return_value={}),patch.object(recovery,'SA',sa),patch.object(recovery.ssl,'create_default_context'),patch.object(recovery.urllib.request,'build_opener',return_value=opener):
            with self.assertRaises(TimeoutError):api.request('POST','/eviction',{})
            self.assertEqual(opener.open.call_count,1)
