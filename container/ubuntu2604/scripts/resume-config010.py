#!/usr/bin/env python3
"""One-attempt configuration-only continuation for the verified 0.1.0 receipt."""
import argparse
import copy
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import time
import uuid

HERE = Path(__file__).resolve().parent

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

helper = load('config_resume_deploy', HERE / 'upgrade-deploy.py')
common = load('config_resume_common', HERE / 'recover-179-to-184.py')
before = load('config_resume_before', HERE / 'resume-before-upgrade.py')
diagnostic = load('config_resume_diagnostic', HERE / 'diagnose-release.py')

CONTROL = r'''
use strict;use warnings;use JSON::PP ();$|=1;
require '/usr/local/lib/tessera/package-inventory.pl';
my $Stage='preflight';
my $OK=eval {
 die "Quiescence required.\n" if ($ENV{TESSERA_UPGRADE_QUIESCED} || '') ne '1' || !-w '/opt/otobo/Kernel/System';
 open my $F,'<:raw','/opt/tessera/dependencies/release.json' or die;
 my $Meta=do {local $/;JSON::PP->new->decode(<$F>)};close $F;
 die "Recovery requires exact0.1.0 artifact.\n" if ($Meta->{version} || '') ne '0.1.0'
  || ($Meta->{package_sha256} || '') ne 'ecedb348d955af2ee0461f367a7234ddd1fc3ceb2698ab1f3288c3ba1a10cb2d';
 open $F,'<:raw','/opt/tessera/dependencies/package-modules.json' or die;
 my $Inventory=do {local $/;JSON::PP->new->decode(<$F>)};close $F;
 require Kernel::System::ObjectManager;
 local $Kernel::OM=Kernel::System::ObjectManager->new();
 my $Gate=$Kernel::OM->Get('Kernel::System::TESSERA::ReleaseUpgrade');
 my $State=$Gate->_Decode($Gate->_Read());
 die "Only exact CONFIGURING receipt may continue.\n" if !$State || ($State->{phase} || '') ne 'CONFIGURING'
  || ($State->{version} || '') ne $Meta->{version} || ($State->{hash} || '') ne $Meta->{package_sha256}
  || $Gate->_Version() ne $Meta->{version} || $Gate->_InstalledHash($Meta->{version}) ne $Meta->{package_sha256};
 my $DB=$Kernel::OM->Get('Kernel::System::DB');
 my $Package=$Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
 CheckInventory($Inventory,$DB,$Package); # Direct installed hashes, no hooks or journals.
 $Stage='configuration';
 print "Configuration-only continuation: package inventory verified; no package hooks permitted\n";
 $Gate->Run(Version=>$Meta->{version},Hash=>$Meta->{package_sha256},FromVersions=>$Meta->{upgrade_from},ResumeConfig=>1,
  Upgrade=>sub {die "Package replay is prohibited by this continuation.\n"},
  Configure=>sub {
   CheckInventory($Inventory,$DB,$Package);
   die "Execution history schema incomplete.\n" if !$DB->Prepare(SQL=>'SELECT request_data, dispatch_data FROM ztsm_async_execution WHERE 1 = 0');
   $DB->FetchrowArray();
   system('/usr/bin/python3','/opt/tessera-config-recovery/configure.py')==0;
  });
 print "Configuration-only continuation: READY verified\n";1;
};
if (!$OK) {print STDERR "Configuration-only continuation failed at $Stage; retain Job, claims and evidence.\n";exit 1}
'''

class Client:
    def __init__(self, namespace): self.prefix = ['kubectl', '-n', namespace]
    def get(self, *args): return json.loads(subprocess.check_output(self.prefix + ['get', *args, '-o', 'json'], text=True))
    def run(self, *args): subprocess.run(self.prefix + list(args), check=True)
    def write(self, obj, verb='create', dry=False):
        subprocess.run(self.prefix + [verb] + (['--dry-run=server'] if dry else []) + ['-f', '-'],
                       input=json.dumps(obj), text=True, check=True)

def find_state(job, root=Path('artifacts')):
    matches = []
    for path in root.glob('*/upgrade-job.json'):
        saved = json.loads(path.read_text())
        if saved.get('metadata', {}).get('name') == job: matches.append(path.parent)
    if len(matches) != 1: raise ValueError('Need the unique original private state directory for this Job; use --state-directory')
    return matches[0].resolve()

def recovery_manifest(original, namespace, name):
    result = diagnostic.diagnostic_job(original, namespace, name)
    pod = result['spec']['template']['spec']
    labels = result['spec']['template']['metadata']['labels']
    labels.pop('tessera-release-diagnostic', None)
    labels['tessera-config-continuation'] = 'true'
    main = pod['containers'][0]
    main['command'] = ['/bin/bash', '-c', diagnostic.SHELL, 'resume-config010']
    main['args'] = [CONTROL]
    main.setdefault('env', []).append({'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'})
    if any(v['name'] == 'tessera-config-recovery' for v in pod['volumes']): raise ValueError('Recovery mount already exists')
    pod['volumes'].append({'name': 'tessera-config-recovery', 'configMap': {'name': name + '-code', 'defaultMode': 0o444}})
    main['volumeMounts'].append({'name': 'tessera-config-recovery', 'mountPath': '/opt/tessera-config-recovery', 'readOnly': True})
    return result

def resume(client, state, job_name, source, cleanup=None):
    state = Path(state).resolve()
    if before.active_runners(state): raise ValueError('Stop the original waiting local upgrade helper with Ctrl-C first')
    def saved(name): return json.loads((state / name).read_text())
    original, claim = saved('upgrade-job.json'), saved('maintenance-lock.json')
    main, pvc = before.validate_manifest(original)
    if original['metadata']['name'] != job_name or main['image'] != 'docker.io/library/tessera:0.1.0-ubuntu26.04':
        raise ValueError('Saved state does not match the failed0.1.0 Job/image')
    namespace = original['metadata']['namespace']
    failed = client.get('job', job_name)
    if not common.terminal(failed, 'Failed'): raise ValueError('Original Job must be terminal Failed')
    observed_main = failed['spec']['template']['spec']['containers'][0]
    if observed_main['image'] != main['image'] or observed_main.get('args') != ['upgrade']:
        raise ValueError('Failed Job command/image differs from saved state')
    _, observed_pvc = before.validate_manifest(failed)
    if observed_pvc != pvc or any(observed_main.get(k) != main.get(k) for k in ('name', 'env', 'envFrom', 'volumeMounts', 'securityContext', 'workingDir')):
        raise ValueError('Failed Job environment/mounts differ from private state')
    lock = client.get('configmap', helper.LOCK_NAME)
    if lock.get('metadata', {}).get('labels', {}).get('app.kubernetes.io/managed-by') != 'tessera-release-helper' or lock.get('data') != claim.get('data') or lock['data'].get('phase') != 'LOCKED':
        raise ValueError('Original maintenance ownership no longer matches')
    for item in client.get('jobs')['items']:
        if item['spec']['template']['metadata'].get('labels', {}).get('tessera-release-upgrade') and not (common.terminal(item, 'Complete') or common.terminal(item, 'Failed')):
            raise ValueError('Another release/diagnostic Job is active')
    workloads = []
    for filename in ('web-before.json', 'daemon-before.json'):
        old = saved(filename); current = client.get('deployment', old['metadata']['name'])
        common.same_target(current, old)
        if current['spec'].get('replicas', 1) != 0 or current['spec']['template']['spec']['containers'][0]['image'] != old['spec']['template']['spec']['containers'][0]['image']:
            raise ValueError('Workloads must remain quiesced with unchanged images')
        if helper.workload_pods(client.get('pods', '-l', helper.selector(old))['items']): raise ValueError('Application writers remain')
        workloads.append(old)
    names = {item['metadata']['name'] for item in workloads}
    if any(h['spec']['scaleTargetRef']['name'] in names for h in client.get('hpa')['items']): raise ValueError('HPA ownership must be resolved')
    bundle = client.get('pvc', pvc)
    if bundle['metadata'].get('deletionTimestamp'): raise ValueError('Current bundle is being deleted; preserve it before recovery')
    for old in workloads:
        print('Will restore', old['metadata']['name'], 'replicas:', old['spec'].get('replicas', 1), flush=True)
    out = state / 'resume-config010';out.mkdir(mode=0o700, exist_ok=False)
    def save(name, value):
        with (out / name).open('x', encoding='utf-8') as stream:
            os.chmod(stream.name, 0o600);json.dump(value, stream, indent=2)
    name = 'tessera-config-resume-' + uuid.uuid4().hex[:12]
    manifest = recovery_manifest(failed, namespace, name)
    code = {'apiVersion': 'v1', 'kind': 'ConfigMap', 'immutable': True, 'metadata': {'name': name + '-code', 'namespace': namespace,
            'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper'}}, 'data': {'configure.py': Path(source).read_text(encoding='utf-8')}}
    save('failed-job.json', failed);save('upgrade-job.json', manifest);save('bundle-pvc.json', bundle);save('rebuild-code.json', code)
    client.write(code, dry=True);client.write(manifest, dry=True)
    lock['data']['owner'] = uuid.uuid4().hex
    save('maintenance-lock.json', lock);client.write(lock, verb='replace')
    def owned():
        current = client.get('configmap', helper.LOCK_NAME)
        if current.get('data') != lock['data']: raise ValueError('Maintenance ownership changed')
        return current
    owned();client.write(code);owned();client.write(manifest)
    print('Configuration-only Job:', name, '\nPrivate continuation state:', out, flush=True)
    deadline = time.monotonic() + 660
    while time.monotonic() < deadline:
        status = client.get('job', name)
        if common.terminal(status, 'Failed'): raise ValueError('Configuration-only Job failed; preserve all claims and evidence')
        if common.terminal(status, 'Complete'): break
        time.sleep(3)
    else: raise ValueError('Configuration-only Job not terminal; inspect before retry')
    owned()
    for old in workloads:
        target = 'deployment/' + old['metadata']['name']; container = old['spec']['template']['spec']['containers'][0]['name']
        owned();client.run('set', 'image', target, container + '=' + main['image'])
        owned();client.run('scale', target, '--replicas=' + str(old['spec'].get('replicas', 1)))
        client.run('rollout', 'status', target, '--timeout=600s')
    owned()
    (cleanup or helper.cleanup_bundle)(client.prefix, out, name, main['name'], pvc, bundle['metadata']['uid'])
    ready = helper.maintenance_lock(owned(), namespace, lock['data']['owner'], 'READY')
    save('maintenance-ready.json', ready);client.write(ready, verb='replace')
    print('Configuration READY; exact saved replicas restored. Failed source Job retained. State:', out, flush=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--namespace', default='tessera');parser.add_argument('--job', required=True)
    parser.add_argument('--state-directory', type=Path)
    args = parser.parse_args()
    if any(not re.fullmatch(r'[a-z0-9][a-z0-9.-]*', v) for v in (args.namespace, args.job)): parser.error('Invalid Kubernetes name')
    state = args.state_directory or find_state(args.job)
    saved = json.loads((state / 'upgrade-job.json').read_text())
    if saved['metadata']['namespace'] != args.namespace: raise ValueError('Namespace differs from private state')
    resume(Client(args.namespace), state, args.job, HERE.parent / 'image/configure.py')

if __name__ == '__main__':
    try: main()
    except (Exception, KeyboardInterrupt) as error:
        raise SystemExit('Configuration continuation stopped: ' + str(error) + '. Preserve state/Job/bundle; no automatic retry.') from None
