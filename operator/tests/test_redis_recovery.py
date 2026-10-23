import copy
import unittest
from unittest.mock import Mock
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import recovery
import redis_recovery as rr

class RedisRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.pods=[{'metadata':{'name':f'r-{i}'},'status':{'podIP':f'10.0.0.{i}','conditions':[{'type':'Ready','status':'True'}]}} for i in range(3)]
        self.controller=Mock()
        self.probe=Mock()
        self.probe.primary.return_value=('10.0.0.0',6379,2)
        self.master={'role':'master','master_replid':'id','master_repl_offset':100}
        self.replica={'role':'slave','master_host':'10.0.0.0','master_port':6379,'master_link_status':'up','master_sync_in_progress':0,'master_replid':'id','slave_repl_offset':100}
        self.probe.info.side_effect=lambda p: self.master if p['metadata']['name']=='r-0' else self.replica
        self.policy={'redis_port':6379}
    def test_authority(self):
        self.assertEqual(rr.authority(self.controller,self.policy,self.probe,self.pods,'r-2'),['10.0.0.0',6379,2,'id'])
    def test_never_replace_primary(self):
        with self.assertRaises(recovery.Blocked): rr.authority(self.controller,self.policy,self.probe,self.pods,'r-0')
    def test_wrong_upstream(self):
        self.replica['master_host']='other'
        with self.assertRaises(recovery.Blocked): rr.authority(self.controller,self.policy,self.probe,self.pods,'r-2')
    def test_identity_mismatch(self):
        self.replica['master_replid']='other'
        with self.assertRaises(recovery.Blocked): rr.authority(self.controller,self.policy,self.probe,self.pods,'r-2')
    def test_no_quorum(self):
        self.probe.primary.side_effect=recovery.Blocked('no quorum')
        with self.assertRaises(recovery.Blocked): rr.authority(self.controller,self.policy,self.probe,self.pods,'r-2')
    def test_unknown_primary(self):
        self.probe.primary.return_value=('outside',6379,2)
        with self.assertRaises(recovery.Blocked): rr.authority(self.controller,self.policy,self.probe,self.pods,'r-2')
    def test_node_unreachable(self):
        self.controller.node_ok.side_effect=recovery.Blocked('node')
        with self.assertRaises(recovery.Blocked): rr.authority(self.controller,self.policy,self.probe,self.pods,'r-2')
    def test_sync_in_progress(self):
        self.replica['master_sync_in_progress']=1
        with self.assertRaises(recovery.Blocked): rr.authority(self.controller,self.policy,self.probe,self.pods,'r-2')

class SentinelTransportTests(unittest.TestCase):
    def setUp(self):
        import json
        from pathlib import Path
        self.policy=json.loads((Path(__file__).resolve().parents[1]/'redis-policy-ncs.json').read_text())
    def test_explicit_plaintext_policy(self):
        rr.validate(self.policy)
        del self.policy['tls']
        with self.assertRaises(ValueError): rr.validate(self.policy)
    def test_tls_requires_certificate_keys(self):
        self.policy['tls']=True
        with self.assertRaises(ValueError): rr.validate(self.policy)
    def test_plaintext_does_not_create_certificate_files(self):
        from unittest.mock import patch
        import base64
        api=Mock()
        api.get.return_value={'data':{'password':base64.b64encode(b'test-only').decode()}}
        with patch('tempfile.TemporaryDirectory') as directory, patch('redis.Redis') as client:
            probe=rr.Probe(api,self.policy)
            probe.client('host')
            directory.assert_not_called()
            self.assertFalse(client.call_args.kwargs['ssl'])
            probe.close()
    def test_set_flags_and_quorum(self):
        probe=rr.Probe.__new__(rr.Probe);probe.policy=self.policy
        client=Mock();client.sentinel_master.return_value={'flags':{'master'},'ip':'172.30.1.1','port':6379,'config-epoch':0}
        client.execute_command.return_value='OK 3 usable Sentinels'
        probe.client=Mock(return_value=client)
        self.assertEqual(probe.primary(),('172.30.1.1',6379,0))
    def test_set_down_flags_cannot_authorize(self):
        probe=rr.Probe.__new__(rr.Probe);probe.policy=self.policy
        client=Mock();client.sentinel_master.return_value={'flags':{'master','s_down'},'ip':'ip','port':6379,'config-epoch':0}
        probe.client=Mock(return_value=client)
        with self.assertRaises(recovery.Blocked):probe.primary()
    def test_reachable_disagreement_blocks_even_without_quorum(self):
        probe=rr.Probe.__new__(rr.Probe);probe.policy=self.policy
        clients=[Mock() for _ in range(3)]
        for i,client in enumerate(clients):
            client.sentinel_master.return_value={'flags':'master','ip':'a' if i<2 else 'b','port':6379,'config-epoch':0}
            client.execute_command.return_value='OK' if i<2 else 'NOQUORUM'
        probe.client=Mock(side_effect=clients)
        with self.assertRaises(recovery.Blocked):probe.primary()

class RedisStepTests(unittest.TestCase):
    def setUp(self):
        import json
        from pathlib import Path
        self.policy=json.loads((Path(__file__).resolve().parents[1]/'redis-policy-ncs.json').read_text())
        self.c=Mock();self.c.load.return_value=({}, {})
        self.c.api.get.return_value={'metadata':{'uid':'sts'},'spec':{'replicas':3}}
        self.pods=[]
        for i in range(3):
            self.pods.append({'metadata':{'name':f'r-{i}','uid':f'old-{i}','resourceVersion':'1','ownerReferences':[{'kind':'StatefulSet','uid':'sts'}]},'status':{'podIP':f'10.0.0.{i}','conditions':[{'type':'Ready','status':'True' if i<2 else 'False'}]}})
        self.c.api.items.return_value=self.pods
        self.p=Mock();self.p.primary.return_value=('10.0.0.0',6379,1)
        self.p.info.side_effect=lambda pod: {'role':'master','master_replid':'id','master_repl_offset':100} if pod['metadata']['name']=='r-0' else {'role':'slave','master_host':'10.0.0.0','master_port':6379,'master_link_status':'up','master_sync_in_progress':0,'master_replid':'id','slave_repl_offset':100}
        self.factory=Mock(return_value=self.p)
    def test_confirm_then_persist_before_eviction(self):
        rr.step(self.c,self.policy,self.factory)
        ledger=self.c.save.call_args.args[1]
        state=ledger['redis-recovery']
        import datetime as dt
        state['first_seen']=(dt.datetime.now(dt.timezone.utc)-dt.timedelta(seconds=180)).isoformat()
        state['confirmations']=2
        self.c.load.return_value=({},ledger)
        rr.step(self.c,self.policy,self.factory)
        self.assertEqual(self.c.mutate.call_count,1)
        body=self.c.mutate.call_args.args[2]
        self.assertEqual(body['deleteOptions']['preconditions']['uid'],'old-2')
        self.assertEqual(state['phase'],'waiting')
        self.pods[2]['metadata']['uid']='new-2'
        self.pods[2]['status']['conditions'][0]['status']='True'
        rr.step(self.c,self.policy,self.factory)
        self.assertEqual(state['phase'],'completed')
        stamp=state['updated_at']
        rr.step(self.c,self.policy,self.factory)
        self.assertEqual(state['updated_at'],stamp)
    def test_terminating_member_never_force_deleted(self):
        self.pods[2]['metadata']['deletionTimestamp']=recovery.utc()
        with self.assertRaises(recovery.Blocked):rr.step(self.c,self.policy,self.factory)
        self.c.mutate.assert_not_called()
    def test_all_ready_split_primary_is_not_healthy(self):
        self.pods[2]['status']['conditions'][0]['status']='True'
        self.p.info.side_effect=None;self.p.info.return_value={'role':'master'}
        with self.assertRaises(recovery.Blocked):rr.step(self.c,self.policy,self.factory)
        self.c.mutate.assert_not_called()
