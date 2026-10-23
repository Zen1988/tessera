"""Track Longhorn recovery progress; repair only one demonstrably failed manager.

Longhorn alone rebuilds replicas. No engine/replica/volume writes or force detach.
"""
from recovery import Blocked, age, conditions, result, utc


def validate(policy):
    import re
    if set(policy) != {'name','kind','namespace','stall_seconds'} or policy['namespace'] != 'longhorn-system' or not re.fullmatch(r'[a-z0-9][a-z0-9.-]{0,62}',policy['name']):
        raise ValueError('explicit Longhorn recovery policy required')
    if type(policy['stall_seconds']) is not int or not 600 <= policy['stall_seconds'] <= 7200:
        raise ValueError('Longhorn stall window must be 600..7200 seconds')


def progress(volume, engines):
    relevant = [e for e in engines if e.get('spec',{}).get('volumeName') == volume['metadata']['name']
                and e.get('spec',{}).get('active') is True]
    if len(relevant) != 1:
        return None
    status = relevant[0].get('status',{})
    if status.get('currentState') != 'running':
        return None
    modes = status.get('replicaModeMap',{})
    rw = sum(mode == 'RW' for mode in modes.values())
    percentages = {}
    for address, row in status.get('rebuildStatus',{}).items():
        value = row.get('progress')
        if type(value) in (int,float) and 0 <= value <= 100:
            percentages[address] = value
    return {'engine_uid':relevant[0]['metadata']['uid'], 'rw':rw, 'rebuild':percentages}


def observe(volume, engines, previous, threshold):
    now = utc()
    sample = progress(volume, engines)
    status = volume.get('status',{})
    # Intentionally unused detached volumes are not a failed application.
    wanted = volume.get('spec',{}).get('nodeID')
    problem = status.get('robustness') in ('degraded','faulted') or (bool(wanted) and status.get('state') != 'attached')
    if not problem:
        return None, {'volume':volume['metadata']['name'],'phase':'healthy' if status.get('robustness') == 'healthy' else 'idle'}
    if not previous or previous.get('uid') != volume['metadata']['uid'] or age(previous.get('sampled_at')) > 600:
        previous = {'uid':volume['metadata']['uid'],'first_seen':now,'last_progress':now,'samples':0,'sample':sample}
    previous['samples'] += 1
    advanced = False
    if sample is not None:
        best_rw = previous.setdefault('best_rw', sample['rw'])
        if sample['rw'] > best_rw:
            advanced = True
            previous['best_rw'] = sample['rw']
        best = previous.setdefault('best_rebuild', {})
        for address, value in sample['rebuild'].items():
            key = sample['engine_uid'] + ':' + address
            if key in best and value > best[key]:
                advanced = True
            if key in best or len(best) < 64:
                best[key] = max(best.get(key,value),value)
    if advanced:
        previous['last_progress'] = now
    previous.update(sampled_at=now, sample=sample)
    stalled = previous['samples'] >= 3 and age(previous['last_progress']) >= threshold
    phase = 'stalled' if stalled else 'recovering'
    reason = 'native recovery has not made observed progress' if stalled else 'allowing native Longhorn recovery'
    if sample is None:
        reason += '; active engine progress unavailable'
    return previous, {'volume':volume['metadata']['name'],'phase':phase,'reason':reason,
        'robustness':status.get('robustness'),'volume_state':status.get('state'),
        'seconds_without_progress':int(age(previous['last_progress'])),'threshold_seconds':threshold,
        'progress':sample,'conditions':conditions(volume)}


def step(controller, policy):
    controller.lead()
    record, ledger = controller.load()
    ns = policy['namespace']
    root = f'/apis/longhorn.io/v1beta2/namespaces/{ns}'
    volumes = controller.api.items(root+'/volumes')
    engines = controller.api.items(root+'/engines')
    wait = controller.api.get(root+'/settings/replica-replenishment-wait-interval')
    threshold = max(policy['stall_seconds'], int(wait['value']) + 300)
    if not 600 <= threshold <= 86400:
        raise Blocked('native Longhorn replenishment delay is outside supported bounds')
    if len(volumes) > 200:
        raise Blocked('Longhorn tracking capacity exceeded')
    state = ledger.setdefault(policy['name'],{'volumes':{},'actions':[]})
    tracked, checks = {}, []
    for volume in volumes:
        name = volume['metadata']['name']
        entry, check = observe(volume,engines,state['volumes'].get(name),threshold)
        if entry:
            tracked[name] = entry
        checks.append(check)
    state['volumes'] = tracked
    stalled = [row for row in checks if row['phase']=='stalled']
    state['updated_at'] = utc()
    # Evidence persists across operator restarts and leadership changes.
    controller.save(record,ledger)
    details={'checks':checks,'stalled_count':len(stalled),'action':'none'}
    if not stalled:
        return result('recovery/'+policy['name'],'degraded' if tracked else 'healthy',
            'Longhorn native recovery progressing or within observation window' if tracked else 'no persistent Longhorn failure',details)
    actions = state['actions']
    if len(actions) >= 20 or (actions and age(actions[-1]['at']) < 21600):
        details['blocked_reason']='manager repair cooldown or receipt capacity reached'
        return result('recovery/'+policy['name'],'degraded','Longhorn recovery stalled',details)
    ds = controller.api.get(f'/apis/apps/v1/namespaces/{ns}/daemonsets/longhorn-manager')
    managers = [p for p in controller.api.items(f'/api/v1/namespaces/{ns}/pods') if any(
        owner.get('kind')=='DaemonSet' and owner.get('uid')==ds['metadata']['uid']
        for owner in p['metadata'].get('ownerReferences',[]))]
    failed=[p for p in managers if conditions(p).get('Ready',{}).get('status') != 'True']
    if len(failed) != 1 or len(managers) < 3:
        details['blocked_reason']='no single failed manager with two healthy peers; inspect disk, network, scheduling and attachment evidence'
        return result('recovery/'+policy['name'],'degraded','Longhorn recovery stalled',details)
    target=failed[0]
    # Never restart a healthy manager merely because storage is slow.
    statuses=target.get('status',{}).get('containerStatuses',[])
    crashes=[s for s in statuses if s.get('name')=='longhorn-manager' and s.get('restartCount',0)>=3
             and s.get('state',{}).get('waiting',{}).get('reason')=='CrashLoopBackOff']
    if len(crashes)!=1 or target['metadata'].get('deletionTimestamp'):
        details['blocked_reason']='manager has no eligible repeated crash signature'
        return result('recovery/'+policy['name'],'degraded','Longhorn recovery stalled',details)
    for pod in managers:
        controller.node_ok(pod)
        if pod is not target and (pod['metadata'].get('deletionTimestamp') or conditions(pod).get('Ready',{}).get('status')!='True'):
            raise Blocked('Longhorn manager peer is not healthy')
    # A failed manager must be on the node owning one of the stalled volumes.
    node=target.get('spec',{}).get('nodeName')
    eligible=[v for v in volumes if v['metadata']['name'] in {x['volume'] for x in stalled}
        and v.get('status',{}).get('ownerID')==node and v.get('status',{}).get('state')=='attached'
        and v.get('status',{}).get('robustness')=='degraded' and v.get('status',{}).get('currentNodeID')==node
        and (progress(v,engines) or {}).get('rw',0)>=1]
    if not eligible:
        details['blocked_reason']='no attached stalled volume with a running engine and a healthy replica under this manager'
        return result('recovery/'+policy['name'],'degraded','Longhorn recovery stalled',details)
    # Save intent before mutation. A timeout consumes the attempt; no duplicate restart loop.
    action={'at':utc(),'pod':target['metadata']['name'],'uid':target['metadata']['uid'],'phase':'requested',
            'volumes':[v['metadata']['name'] for v in eligible]}
    actions.append(action)
    controller.save(record,ledger)
    controller.mutate('POST',f"/api/v1/namespaces/{ns}/pods/{action['pod']}/eviction",
        {'apiVersion':'policy/v1','kind':'Eviction','metadata':{'name':action['pod'],'namespace':ns},
         'deleteOptions':{'preconditions':{'uid':action['uid'],'resourceVersion':target['metadata']['resourceVersion']}}})
    action['phase']='eviction-accepted'
    controller.save(record,ledger)
    details.update(action='manager replacement requested',pod=action['pod'])
    return result('recovery/'+policy['name'],'degraded','stalled Longhorn controller recovery requested; volume recovery not yet verified',details)
