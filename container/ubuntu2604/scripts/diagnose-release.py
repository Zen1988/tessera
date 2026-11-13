#!/usr/bin/env python3
"""Read release metadata in a diagnostic Job cloned from a failed upgrade Job.

Does not invoke PackageUpgrade, configure, release claims or workload scaling.
The failed Job and maintenance lock are preserved.
"""
import argparse
import copy
import json
from pathlib import Path
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
    print "image_package_payload=external-upgrade-bundle\n";
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
    # PACKAGE_PLAN
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

PACKAGE_PLAN = r'''
    $Stage='package-journals';
    die "Package journal unavailable.\n" if !$DB->Prepare(SQL=>q{SELECT data_key, data_value FROM system_data WHERE data_key LIKE 'TESSERA::PackageUpgrade::%'});
    my $Count=0;
    while (my @R=$DB->FetchrowArray()) {
        $Count++;
        my $J=eval {JSON::PP->new->decode($R[1])} || {};
        my @Safe=map {defined $_ && /\A[A-Za-z0-9_:.-]{1,160}\z/?$_:'invalid'} ($R[0],$J->{phase},$J->{version});
        print 'package_journal=',join(',',@Safe),"\n";
    }
    print "package_journal_count=$Count\n";
    $Stage='package-plan';
    open my $PlanFH,'<:raw','/opt/tessera/dependencies/package-modules.json' or die "Package inventory unavailable.\n";
    my $Inventory=JSON::PP->new->utf8->decode(do {local $/;<$PlanFH>});close $PlanFH;
    my $Package=$Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
    print 'native_repository_cache_clear_available=', $Package->can('_RepositoryCacheClear')?'yes':'no',"\n";
    my %Expected=map {$_->{name}=>$_->{version}} @{$Inventory->{packages} || []};
    die "Package registry unavailable.\n" if !$DB->Prepare(SQL=>q{SELECT name, version FROM package_repository WHERE install_status = ? ORDER BY name, version},Bind=>[\(my $Status='installed')]);
    while (my @R=$DB->FetchrowArray()) {
        my @Safe=map {defined $_ && /\A[A-Za-z0-9_.-]{1,120}\z/?$_:'invalid'} ($R[0],$R[1],$Expected{$R[0]} // 'absent-from-image');
        print 'package_compare=',join(',',@Safe),"\n";
    }
    my $PlanOK=eval {ReconcilePackages($Inventory,$DB,$Package,'/opt/tessera/upgrade-bundle/packages',1);1};
    if (!$PlanOK) {
        my $Error=$@ || '';
        if ($Error =~ /\A((?:Incomplete package upgrade journal; inspect before retry|Invalid package manifest|Invalid package identity|Missing bundled OPM for [A-Za-z0-9_.-]+|Bundled OPM (?:hash|identity) mismatch for [A-Za-z0-9_.-]+|Extra or ambiguous target package; reconciliation stopped|Unsupported target version for [A-Za-z0-9_.-]+|Refusing package downgrade for [A-Za-z0-9_.-]+|Same-version artifact mismatch for [A-Za-z0-9_.-]+|Cyclic package dependency at [A-Za-z0-9_.-]+|Missing bundled dependency for [A-Za-z0-9_.-]+|Package artifact unavailable(?: or ambiguous)? for [A-Za-z0-9_.-]+)\.)/) {
            print "package_plan_error=$1\n";
        } elsif ($Error =~ /Can't locate ([A-Za-z0-9_\/.:-]+\.pm)/) {print "package_plan_missing_module=$1\n"}
        else {print "package_plan_error=unclassified; exception withheld\n"}
    } else {print "package_plan_status=passed-no-hooks-run\n"}
'''


def diagnostic_program(package_plan=False):
    if not package_plan:
        return PERL
    image = Path(__file__).resolve().parents[1] / 'image'
    inventory = (image / 'package-inventory.pl').read_text().split('unless (caller)', 1)[0]
    reconcile = (image / 'package-reconcile.pl').read_text()
    if '$PlanOnly' not in reconcile:
        raise ValueError('Updated read-only planner is required')
    return inventory + '\n' + reconcile + '\n' + PERL.replace('    # PACKAGE_PLAN', PACKAGE_PLAN)

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


def diagnostic_job(original, namespace, name, package_plan=False):
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
    main['args'] = [diagnostic_program(package_plan)]
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
    parser.add_argument('--package-plan', action='store_true', help='Read package journals and run read-only planning; never execute native hooks')
    args = parser.parse_args()
    for value in (args.namespace, args.job):
        if not re.fullmatch(r'[a-z0-9][a-z0-9.-]*', value): parser.error('Invalid Kubernetes name')
    prefix = ['kubectl', '-n', args.namespace]
    original = json.loads(subprocess.check_output(prefix + ['get', 'job', args.job, '-o', 'json'], text=True))
    name = 'tessera-release-diag-' + uuid.uuid4().hex[:12]
    manifest = diagnostic_job(original, args.namespace, name, args.package_plan)
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
