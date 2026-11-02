#!/usr/bin/env python3
"""Explicit, one-attempt recovery of the rejected 179 -> 184 upgrade.

Requires the original failed helper's private state and maintenance ownership.
Keeps the shipped image/OPM unchanged. Does not enable arbitrary upgrade origins.
"""
import argparse
import copy
import json
import os
from pathlib import Path
import subprocess
import time
import uuid

CONTROL = r'''
use strict;use warnings;use JSON::PP ();use Digest::SHA qw(sha256_hex);$|=1;
my $Stage='image';
my $OK=eval {
    die "Quiescence required.\n" if ($ENV{TESSERA_UPGRADE_QUIESCED} || '') ne '1';
    die "Workspace not writable.\n" if !-w '/opt/otobo/Kernel/System';
    open my $F,'<:raw','/opt/tessera/dependencies/release.json' or die "Release metadata unavailable.\n";
    my $Meta=do {local $/;JSON::PP->new->decode(<$F>)};close $F;
    die "Recovery requires image184.\n" if ($Meta->{package} || '') ne 'TESSERA-Base' || ($Meta->{version} || '') ne '0.0.184';
    open $F,'<:raw','/opt/tessera/dependencies/package.opm' or die "Image package unavailable.\n";
    my $Bytes=do {local $/;<$F>};close $F;
    die "Image package hash mismatch.\n" if sha256_hex($Bytes) ne ($Meta->{package_sha256} || '');
    $Stage='target-preflight';
    require Kernel::System::ObjectManager;
    local $Kernel::OM=Kernel::System::ObjectManager->new();
    my $Gate=$Kernel::OM->Get('Kernel::System::TESSERA::ReleaseUpgrade');
    die "Recovery requires absent release receipt.\n" if defined $Gate->_Read();
    die "Recovery requires installed179.\n" if $Gate->_Version() ne '0.0.179';
    my $Package=$Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
    require Encode;
    my $String=Encode::decode('UTF-8',$Bytes,Encode::FB_CROAK());
    my %Structure=$Package->PackageParse(String=>$String);
    die "Image package identity mismatch.\n" if ($Structure{Name}{Content} || '') ne 'TESSERA-Base' || ($Structure{Version}{Content} || '') ne '0.0.184';
    # Explicitly reviewed recovery compatibility: native179 already has the
    # async table;184's idempotent StorageEnsure adds the two history columns.
    # Keep the native version filtering, package hash checks and durable CAS.
    $Stage='release-claim';print "Recovery179-to-184: preflight passed\n";
    $Gate->Run(Version=>'0.0.184',Hash=>$Meta->{package_sha256},FromVersions=>['0.0.179'],
        Upgrade=>sub {$Stage='native-upgrade';print "Recovery179-to-184: native package upgrade\n";$Package->PackageUpgrade(String=>$String)},
        Configure=>sub {
            $Stage='schema-verification';my $DB=$Kernel::OM->Get('Kernel::System::DB');
            die "Execution history schema incomplete.\n" if !$DB->Prepare(SQL=>'SELECT request_data, dispatch_data FROM ztsm_async_execution WHERE 1 = 0');
            $DB->FetchrowArray();$Stage='configuration';print "Recovery179-to-184: configuration rebuild\n";
            system('/usr/bin/python3','/usr/local/lib/tessera/configure.py')==0;
        });
    print "Recovery179-to-184: READY verified\n";1;
};
if (!$OK) {
    my $Error=$@ || '';
    print STDERR "Recovery179-to-184 failed at $Stage; retain Job and release state.\n";
    if ($Error =~ /\A([A-Za-z0-9 ;:,.\/-]{1,180})\n/) {print STDERR "$1\n"}
    else {print STDERR "Exception detail withheld; inspect release state and restricted application logs.\n"}
    exit 1;
}
'''

SHELL = '''set -eu
cd /opt/otobo
if [ -r /run/tessera-tls/ca.crt ]; then
  openssl x509 -in /run/tessera-tls/ca.crt -noout -checkend 0 >/dev/null
  openssl x509 -in /run/tessera-tls/ca.crt -noout -ext basicConstraints | grep -q 'CA:TRUE'
  cat /etc/ssl/certs/ca-certificates.crt /run/tessera-tls/ca.crt > var/tmp/tessera-ca-bundle.pem
  export SSL_CERT_FILE=/opt/otobo/var/tmp/tessera-ca-bundle.pem
  export PERL_LWP_SSL_CA_FILE="$SSL_CERT_FILE"
fi
exec /usr/bin/perl -e "$1"
'''


def terminal(job, condition):
    return not job.get('status', {}).get('active', 0) and any(
        c.get('type') == condition and c.get('status') == 'True'
        for c in job.get('status', {}).get('conditions', []))


def recovery_job(saved, name):
    result = copy.deepcopy(saved)
    result.pop('status', None)
    pod = result['spec']['template']['spec']
    if len(pod['containers']) != 1 or pod['containers'][0].get('args') != ['upgrade']:
        raise ValueError('Expected original single-container upgrade manifest')
    if [i['name'] for i in pod.get('initContainers', [])] != ['stage-upgrade']:
        raise ValueError('Expected isolated stage-upgrade workspace')
    c = pod['containers'][0]
    if c['image'] != 'docker.io/library/tessera:0.0.184-ubuntu26.04':
        raise ValueError('This recovery is scoped to the observed184 image')
    if not any(e.get('name') == 'TESSERA_UPGRADE_QUIESCED' and e.get('value') == '1' for e in c.get('env', [])):
        raise ValueError('Original manifest lacks quiescence contract')
    c['command'] = ['/bin/bash', '-c', SHELL, 'recovery179-to184']
    c['args'] = [CONTROL]
    result['metadata'] = {'name': name, 'namespace': saved['metadata']['namespace']}
    result['spec']['template']['metadata']['labels']['tessera-release-upgrade'] = name
    result['spec']['backoffLimit'] = 0
    return result


def same_target(current, saved):
    if current['metadata']['uid'] != saved['metadata']['uid']:
        raise ValueError('Deployment identity changed')
    a, b = current['spec']['template']['spec'], saved['spec']['template']['spec']
    if len(a['containers']) != 1 or len(b['containers']) != 1:
        raise ValueError('Single-container deployments required')
    for field in ('name', 'env', 'envFrom', 'volumeMounts', 'securityContext'):
        if a['containers'][0].get(field) != b['containers'][0].get(field):
            raise ValueError('Target container configuration changed: ' + field)
    for field in ('volumes', 'serviceAccountName', 'securityContext'):
        if a.get(field) != b.get(field): raise ValueError('Target Pod configuration changed: ' + field)
    if current['spec']['selector'] != saved['spec']['selector']:
        raise ValueError('Deployment selectors changed')
    selector = current['spec']['selector']
    if selector.get('matchExpressions') or not selector.get('matchLabels'):
        raise ValueError('Explicit matchLabels selectors required before maintenance')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--state-directory', required=True)
    args = parser.parse_args()
    state = Path(args.state_directory).resolve()
    def load(name): return json.loads((state / name).read_text())
    saved, old_claim = load('upgrade-job.json'), load('maintenance-lock.json')
    namespace = saved['metadata']['namespace']
    prefix = ['kubectl', '-n', namespace]
    def get(*parts): return json.loads(subprocess.check_output(prefix + ['get', *parts, '-o', 'json'], text=True))
    def run(*parts): subprocess.run(prefix + list(parts), check=True)
    def write_object(verb, obj, dry=False):
        subprocess.run(prefix + [verb] + (['--dry-run=server'] if dry else []) + ['-f', '-'],
                       input=json.dumps(obj), text=True, check=True)
    failed = get('job', saved['metadata']['name'])
    if not terminal(failed, 'Failed'): raise ValueError('Original upgrade Job must be terminal Failed')
    lock = get('configmap', 'tessera-release-maintenance')
    if lock.get('metadata', {}).get('labels', {}).get('app.kubernetes.io/managed-by') != 'tessera-release-helper' or lock.get('data') != old_claim.get('data') or lock['data'].get('phase') != 'LOCKED':
        raise ValueError('Original maintenance ownership no longer matches saved state')
    for job in get('jobs')['items']:
        if job['spec']['template']['metadata'].get('labels', {}).get('tessera-release-upgrade') and not (terminal(job, 'Complete') or terminal(job, 'Failed')):
            raise ValueError('Another release or diagnostic Job is not terminal')
    workloads = []
    for filename in ('web-before.json', 'daemon-before.json'):
        before = load(filename);current = get('deployment', before['metadata']['name']);same_target(current, before)
        if current['spec'].get('replicas', 0) < 1: raise ValueError('Expected restored deployment; replica count must be known')
        workloads.append(current)
    names = {d['metadata']['name'] for d in workloads}
    if any(h['spec']['scaleTargetRef']['name'] in names for h in get('hpa')['items']):
        raise ValueError('HPA ownership must be resolved before maintenance')
    out = state / 'recovery179-to184'
    out.mkdir(mode=0o700, exist_ok=False)
    def save(name, obj):
        with (out / name).open('x', encoding='utf-8') as f:
            os.chmod(f.name, 0o600);json.dump(obj, f, indent=2)
    name = 'tessera-recover-179-184-' + uuid.uuid4().hex[:8]
    manifest = recovery_job(saved, name)
    save('job.json', manifest)
    for d in workloads: save(d['metadata']['name'] + '-before.json', d)
    write_object('create', manifest, dry=True)
    # Explicit recovery claims the existing failed operation using its saved
    # owner plus resourceVersion CAS. Never deletes or expires a live claim.
    lock['data']['owner'] = uuid.uuid4().hex
    save('maintenance-lock.json', lock)
    write_object('replace', lock)
    print('Recovery state:', out, '\nUpgrade Job:', name, flush=True)
    for d in workloads: run('scale', 'deployment/' + d['metadata']['name'], '--replicas=0')
    for d in workloads:
        selector = d['spec']['selector']
        if selector.get('matchExpressions') or not selector.get('matchLabels'): raise ValueError('Unsupported selector')
        label = ','.join(k + '=' + v for k, v in sorted(selector['matchLabels'].items()))
        def live(): return [p for p in get('pods', '-l', label)['items'] if p.get('status', {}).get('phase') not in ('Succeeded', 'Failed')]
        pods = live()
        if pods: run('wait', '--for=delete', *['pod/' + p['metadata']['name'] for p in pods], '--timeout=600s')
        if live(): raise ValueError('Application Pods remain; upgrade not started')
    write_object('create', manifest)
    deadline = time.monotonic() + 1860
    while time.monotonic() < deadline:
        status = get('job', name)
        if terminal(status, 'Failed'):
            subprocess.run(prefix + ['logs', 'job/' + name, '-c', manifest['spec']['template']['spec']['containers'][0]['name'], '--tail=100'], check=False)
            raise ValueError('Recovery Job failed; leave deployments stopped and inspect saved state')
        if terminal(status, 'Complete'): break
        time.sleep(5)
    else: raise ValueError('Recovery timed out; no automatic retry or activation')
    run('logs', 'job/' + name, '-c', manifest['spec']['template']['spec']['containers'][0]['name'], '--tail=100')
    image = manifest['spec']['template']['spec']['containers'][0]['image']
    for d in workloads:
        target = 'deployment/' + d['metadata']['name'];container = d['spec']['template']['spec']['containers'][0]['name']
        run('set', 'image', target, container + '=' + image)
        run('scale', target, '--replicas=' + str(d['spec']['replicas']))
        run('rollout', 'status', target, '--timeout=600s')
    current = get('configmap', 'tessera-release-maintenance')
    if current['data'] != lock['data']: raise ValueError('Maintenance owner changed; no completion publication')
    current['data']['phase'] = 'READY';save('maintenance-ready.json', current);write_object('replace', current)
    print('184 upgrade and both rollouts completed. Verify portal and daemon functionality. State:', out)


if __name__ == '__main__':
    try: main()
    except ValueError as error:
        raise SystemExit('Recovery stopped: ' + str(error) + '. Preserve Jobs, maintenance claim and state directory.') from None
    except FileNotFoundError as error:
        raise SystemExit('Recovery file not found: ' + str(error.filename) + '. Run on the host containing the original private state directory.') from None
    except (Exception, KeyboardInterrupt):
        raise SystemExit('Recovery stopped. Preserve Jobs, maintenance claim and state directory. Do not rerun or roll back after a migration failure; inspect Job logs first.') from None
