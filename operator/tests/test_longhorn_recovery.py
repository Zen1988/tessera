import copy
import datetime as dt
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import unittest
from unittest.mock import Mock
import longhorn_recovery as lh
import recovery


def stamp(seconds=1000):
    return (dt.datetime.now(dt.timezone.utc)-dt.timedelta(seconds=seconds)).isoformat()

class LonghornTests(unittest.TestCase):
    def setUp(self):
        self.v={'metadata':{'name':'v','uid':'volume-uid'},'spec':{'nodeID':'node2','numberOfReplicas':3},'status':{'state':'attached','robustness':'degraded','ownerID':'node2','currentNodeID':'node2'}}
        self.e={'metadata':{'uid':'engine-uid'},'spec':{'volumeName':'v','active':True},'status':{'currentState':'running','replicaModeMap':{'r1':'RW','r2':'WO'},'rebuildStatus':{'r2':{'progress':20}}}}
        self.previous={'uid':'volume-uid','first_seen':stamp(),'last_progress':stamp(),'sampled_at':recovery.utc(),'samples':3,'best_rw':1,'best_rebuild':{'engine-uid:r2':20}}
    def test_stalled_after_window(self):
        entry,check=lh.observe(self.v,[self.e],copy.deepcopy(self.previous),900)
        self.assertEqual(check['phase'],'stalled')
    def test_advancing_rebuild_resets_timer(self):
        self.e['status']['rebuildStatus']['r2']['progress']=30
        entry,check=lh.observe(self.v,[self.e],copy.deepcopy(self.previous),900)
        self.assertEqual(check['phase'],'recovering')
    def test_progress_oscillation_does_not_reset_timer(self):
        self.e['status']['rebuildStatus']['r2']['progress']=10
        entry,_=lh.observe(self.v,[self.e],copy.deepcopy(self.previous),900)
        self.e['status']['rebuildStatus']['r2']['progress']=20
        entry,check=lh.observe(self.v,[self.e],entry,900)
        self.assertEqual(check['phase'],'stalled')
    def test_new_healthy_replica_is_progress(self):
        self.e['status']['replicaModeMap']['r2']='RW'
        _,check=lh.observe(self.v,[self.e],copy.deepcopy(self.previous),900)
        self.assertEqual(check['phase'],'recovering')
    def test_detached_unused_not_failed(self):
        self.v['spec']['nodeID']=''
        self.v['status'].update(state='detached',robustness='unknown')
        entry,check=lh.observe(self.v,[],None,900)
        self.assertIsNone(entry);self.assertEqual(check['phase'],'idle')
    def test_attachment_stall_without_engine(self):
        self.v['status'].update(state='attaching',robustness='unknown')
        _,check=lh.observe(self.v,[],copy.deepcopy(self.previous),900)
        self.assertEqual(check['phase'],'stalled');self.assertIsNone(check['progress'])
    def test_inventory_gap_restarts_observation(self):
        self.previous['sampled_at']=stamp()
        _,check=lh.observe(self.v,[self.e],self.previous,900)
        self.assertEqual(check['phase'],'recovering')
    def test_replaced_volume_resets_timer(self):
        self.previous['uid']='old'
        _,check=lh.observe(self.v,[self.e],self.previous,900)
        self.assertEqual(check['phase'],'recovering')
    def controller(self):
        c=Mock();self.ledger={'lh':{'volumes':{'v':copy.deepcopy(self.previous)},'actions':[]}}
        c.load.return_value=({},self.ledger)
        self.managers=[]
        for i in range(3):
            self.managers.append({'metadata':{'name':f'm-{i}','uid':f'uid-{i}','resourceVersion':'1','ownerReferences':[{'kind':'DaemonSet','uid':'ds'}]},'spec':{'nodeName':f'node{i}'},'status':{'conditions':[{'type':'Ready','status':'False' if i==2 else 'True'}],'containerStatuses':[{'name':'longhorn-manager','restartCount':5,'state':{'waiting':{'reason':'CrashLoopBackOff'}}}]}})
        c.api.items.side_effect=lambda path: [self.v] if path.endswith('/volumes') else [self.e] if path.endswith('/engines') else self.managers
        c.api.get.side_effect=lambda path: {'value':'600'} if '/settings/' in path else {'metadata':{'uid':'ds'}}
        return c
    def run_step(self,c):
        return lh.step(c,{'name':'lh','kind':'longhorn-stall-recovery','namespace':'longhorn-system','stall_seconds':900})
    def test_single_crashing_manager_replaced_with_preconditions(self):
        c=self.controller();res=self.run_step(c)
        self.assertEqual(res['details']['action'],'manager replacement requested')
        self.assertEqual(c.mutate.call_args.args[2]['deleteOptions']['preconditions'],{'uid':'uid-2','resourceVersion':'1'})
        self.run_step(c);self.assertEqual(c.mutate.call_count,1)
    def test_healthy_manager_never_restarted(self):
        c=self.controller();self.managers[2]['status']['conditions'][0]['status']='True'
        self.assertEqual(self.run_step(c)['details']['stalled_count'],1)
        c.mutate.assert_not_called()
    def test_node_failure_blocks_eviction(self):
        c=self.controller();c.node_ok.side_effect=recovery.Blocked('node not healthy')
        with self.assertRaises(recovery.Blocked):self.run_step(c)
        c.mutate.assert_not_called()
    def test_faulted_volume_not_salvaged(self):
        c=self.controller();self.v['status']['robustness']='faulted'
        self.run_step(c);c.mutate.assert_not_called()
    def test_zero_healthy_replicas_no_eviction(self):
        c=self.controller();self.e['status']['replicaModeMap']={}
        self.run_step(c);c.mutate.assert_not_called()
    def test_long_native_wait_is_respected(self):
        c=self.controller();c.api.get.side_effect=lambda path:{'value':'3600'} if '/settings/' in path else {'metadata':{'uid':'ds'}}
        res=self.run_step(c);self.assertEqual(res['details']['checks'][0]['threshold_seconds'],3900)
        c.mutate.assert_not_called()
    def test_cas_record_can_be_saved_twice(self):
        from test_recovery import FakeAPI,config
        c=recovery.Controller(config(),FakeAPI())
        record,state=c.load();c.save(record,state);c.save(record,state)
        self.assertEqual(record['metadata']['resourceVersion'],'3')
