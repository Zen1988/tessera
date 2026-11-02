#!/usr/bin/env python3
"""Read release metadata in a diagnostic Job cloned from a failed upgrade Job.

Does not invoke PackageUpgrade, configure, release claims or workload scaling.
The failed Job and maintenance lock are preserved.
"""
import argparse
import copy
import json
import re
import subprocess
import time
import uuid

PERL = r'''
use strict; use warnings; use JSON::PP (); use Digest::SHA qw(sha256_hex);
my $Stage='start';
my $OK=eval {
    chdir '/opt/otobo' or die "Application directory unavailable.\n";
    print "diagnostic=read-only-release-metadata\n";
    $Stage='image-metadata';
    open my $FH,'<:raw','/opt/tessera/dependencies/release.json' or die "Release metadata unreadable.\n";
    my $Meta=do {local $/;JSON::PP->new->decode(<$FH>)};close $FH;
    die "Invalid release metadata.\n" if ref $Meta ne 'HASH' || ($Meta->{version} || '')!~/\A[0-9]+\.[0-9]+\.[0-9]+\z/;
    print "image_version=$Meta->{version}\n";
    open $FH,'<:raw','/opt/tessera/dependencies/package.opm' or die "Image package unreadable.\n";
    my $Bytes=do {local $/;<$FH>};close $FH;
    print 'image_package_hash_matches=',sha256_hex($Bytes) eq ($Meta->{package_sha256} || '') ? 'yes' : 'no',"\n";
    print 'application_tree_writable=',-w '/opt/otobo/Kernel/System' ? 'yes' : 'no',"\n";
    $Stage='object-manager';
    require Kernel::System::ObjectManager;
    local $Kernel::OM=Kernel::System::ObjectManager->new();
    $Stage='release-service';
    my $Gate=$Kernel::OM->Get('Kernel::System::TESSERA::ReleaseUpgrade');
    $Stage='release-state';
    my $State=$Gate->_Decode($Gate->_Read());
    if ($State) {
        for my $K (qw(phase version from)) {
            my $V=$State->{$K} // 'absent';
            print "receipt_$K=",$V=~/\A[A-Za-z0-9_.-]{1,60}\z/ ? $V : 'invalid',"\n";
        }
        print 'receipt_matches_image=',($State->{version} || '') eq $Meta->{version} && ($State->{hash} || '') eq ($Meta->{package_sha256} || '') ? 'yes' : 'no',"\n";
    } else {print "receipt=absent\n"}
    $Stage='package-registry';
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Package registry unavailable.\n" if !$DB->Prepare(SQL=>q{SELECT name, version, install_status FROM package_repository WHERE name IN ('TESSERA-Base','GovernanceDB')});
    while (my @R=$DB->FetchrowArray()) {
        print 'registry=',join(',',map {defined $_ && /\A[A-Za-z0-9_. -]{1,80}\z/ ? $_ : 'invalid'} @R),"\n";
    }
    $Stage='installed-version';
    my $Current=$Gate->_Version();print "target_version=$Current\n";
    my %Allowed=map {$_=>1} @{$Meta->{upgrade_from} || []};
    print 'target_origin_allowed=',($Current eq $Meta->{version} || $Allowed{$Current}) ? 'yes' : 'no',"\n";
    $Stage='installed-artifact';
    my $Hash=$Gate->_InstalledHash($Current);
    print 'target_artifact_matches_image=',$Hash eq ($Meta->{package_sha256} || '') ? 'yes' : 'no',"\n";
    if ($State && ($State->{phase} || '') eq 'READY') {
        print 'ready_receipt_matches_target=',($State->{version} || '') eq $Current && ($State->{hash} || '') eq $Hash ? 'yes' : 'no',"\n";
    }
    $Stage='package-parser';
    my $Package=$Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
    require Encode;
    my $String=Encode::decode('UTF-8',$Bytes,Encode::FB_CROAK());
    my %Structure=$Package->PackageParse(String=>$String);
    print 'package_parse_matches_image=',($Structure{Name}{Content} || '') eq 'TESSERA-Base' && ($Structure{Version}{Content} || '') eq $Meta->{version} ? 'yes' : 'no',"\n";
    print "diagnostic=completed-no-upgrade-run\n";
    1;
};
if (!$OK) {
    my $Error=$@ || '';
    print "failed_stage=$Stage\n";
    # Emit known bounded diagnostics, never arbitrary exception/config content.
    if ($Error =~ /\A((?:Missing or ambiguous installed package|Release state unavailable|Ambiguous release state|Invalid release state|Package registry unavailable|Installed package artifact unavailable|Application directory unavailable|Release metadata unreadable|Invalid release metadata|Image package unreadable)\.)/) {print "reason=$1\n"}
    elsif ($Error =~ /Can't locate ([A-Za-z0-9_\/.:-]+\.pm)/) {print "missing_module=$1\n"}
    else {print "reason=unclassified; original exception withheld to protect configuration values\n"}
    exit 1;
}
'''

# Reproduce the entrypoint's CA bundle setup without running upgrade/configure.
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


def diagnostic_job(original, namespace, name):
    conditions = original.get('status', {}).get('conditions', [])
    if original.get('status', {}).get('active', 0) or not any(c.get('type') == 'Failed' and c.get('status') == 'True' for c in conditions):
        raise ValueError('Source upgrade Job must be terminal Failed with no active Pods')
    pod = copy.deepcopy(original['spec']['template']['spec'])
    if len(pod.get('containers', [])) != 1 or pod['containers'][0].get('args') not in (['upgrade'], ['upgrade', '--resume-config']):
        raise ValueError('Expected the controlled single-container upgrade Job')
    main = pod['containers'][0]
    if [c['name'] for c in pod.get('initContainers', [])] != ['stage-upgrade']:
        raise ValueError('Expected the isolated stage-upgrade init container')
    main['command'] = ['/bin/bash', '-c', SHELL, 'diagnose-release']
    main['args'] = [PERL]
    main['env'] = [e for e in main.get('env', []) if e['name'] != 'TESSERA_UPGRADE_QUIESCED']
    for key in ('livenessProbe', 'readinessProbe', 'startupProbe', 'lifecycle', 'ports'):
        main.pop(key, None)
    pod['restartPolicy'] = 'Never'
    labels = {k: v for k, v in original['spec']['template']['metadata'].get('labels', {}).items()
              if k not in {'controller-uid', 'job-name', 'batch.kubernetes.io/controller-uid', 'batch.kubernetes.io/job-name'}}
    labels['tessera-release-upgrade'] = name
    labels['tessera-release-diagnostic'] = 'true'
    return {'apiVersion': 'batch/v1', 'kind': 'Job', 'metadata': {'name': name, 'namespace': namespace},
            'spec': {'backoffLimit': 0, 'activeDeadlineSeconds': 600,
                     'template': {'metadata': {'labels': labels}, 'spec': pod}}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--namespace', required=True)
    parser.add_argument('--job', required=True)
    args = parser.parse_args()
    for value in (args.namespace, args.job):
        if not re.fullmatch(r'[a-z0-9][a-z0-9.-]*', value): parser.error('Invalid Kubernetes name')
    prefix = ['kubectl', '-n', args.namespace]
    original = json.loads(subprocess.check_output(prefix + ['get', 'job', args.job, '-o', 'json'], text=True))
    name = 'tessera-release-diag-' + uuid.uuid4().hex[:12]
    manifest = diagnostic_job(original, args.namespace, name)
    payload = json.dumps(manifest)
    subprocess.run(prefix + ['create', '--dry-run=server', '-f', '-'], input=payload, text=True, check=True)
    subprocess.run(prefix + ['create', '-f', '-'], input=payload, text=True, check=True)
    print('Diagnostic Job:', name, flush=True)
    for _ in range(125):
        current = json.loads(subprocess.check_output(prefix + ['get', 'job', name, '-o', 'json'], text=True))
        if any(c.get('type') in ('Complete', 'Failed') and c.get('status') == 'True' for c in current.get('status', {}).get('conditions', [])):
            for container in ['stage-upgrade', manifest['spec']['template']['spec']['containers'][0]['name']]:
                subprocess.run(prefix + ['logs', 'job/' + name, '-c', container, '--tail=100'], check=False)
            return
        time.sleep(5)
    print('Diagnostic not yet terminal; inspect: kubectl -n', args.namespace, 'describe job', name)


if __name__ == '__main__': main()
