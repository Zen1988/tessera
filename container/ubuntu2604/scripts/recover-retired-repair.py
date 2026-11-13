#!/usr/bin/env python3
"""One-attempt retirement of reviewed one-time repair and continuation of failed195."""
import argparse
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import time
import uuid

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('recovery_common',HERE/'recover-179-to-184.py')
common=importlib.util.module_from_spec(spec)
spec.loader.exec_module(common)

CONTROL=r'''use strict;use warnings;use JSON::PP ();use Digest::SHA qw(sha256_hex);use File::Temp qw(tempdir);use File::Copy qw(copy);$|=1;
{
 package RetirementPlanPackage;
 sub new {my ($Class,$Native)=@_;return bless {native=>$Native},$Class}
 sub PackageParse {
  my ($Self,%P)=@_;my %S=$Self->{native}->PackageParse(%P);
  # This exact installed target-only repair is being removed, not installed.
  # Its obsolete forward install dependencies do not constrain the new image.
  # Native uninstall still checks reverse dependencies without Force.
  delete $S{PackageRequired} if ($S{Name}{Content} || '') eq 'TESSERAMELTCrossObjectRecovery';
  return %S;
 }
}
sub VerifyRepairRetirementContract {
 my ($R)=@_;
 die "Repair uninstall contract differs.\n" if ref $R ne 'HASH'
  || ($R->{Name}{Content} || '') ne 'TESSERAMELTCrossObjectRecovery'
  || ($R->{Version}{Content} || '') ne '0.0.1'
  || exists $R->{CodeUninstall} || exists $R->{DatabaseUninstall}
  || ref $R->{Filelist} ne 'ARRAY' || @{$R->{Filelist}}!=1
  || ($R->{Filelist}[0]{Location} || '') ne 'Kernel/System/TESSERA/MELTCrossObjectRecovery.pm';
 return 1;
}
my $Stage='preflight';
my $OK=eval {
 die "Quiescence required.\n" if ($ENV{TESSERA_UPGRADE_QUIESCED} || '') ne '1' || !-w '/opt/otobo/Kernel/System';
 open my $FH,'<:raw','/opt/tessera/dependencies/release.json' or die;
 my $Meta=JSON::PP->new->decode(do {local $/;<$FH>});close $FH;
 die "Requires image195.\n" if ($Meta->{version} || '') ne '0.0.195';
 my $Directory='/opt/tessera/upgrade-bundle';
 system('/usr/bin/python3','/usr/local/lib/tessera/check-package-bundle.py',$Directory,'/opt/tessera/dependencies')==0 or die "Bundle verification failed.\n";
 open $FH,'<:raw',"$Directory/package-modules.json" or die;
 my $Inventory=JSON::PP->new->utf8->decode(do {local $/;<$FH>});close $FH;
 require Kernel::System::ObjectManager;local $Kernel::OM=Kernel::System::ObjectManager->new();
 my $Gate=$Kernel::OM->Get('Kernel::System::TESSERA::ReleaseUpgrade');
 my $DB=$Kernel::OM->Get('Kernel::System::DB');
 my $Package=$Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
 my $Raw=$Gate->_Read();my $State=$Gate->_Decode($Raw);
 die "Release claim changed.\n" if !$State || $State->{phase} ne 'UPGRADING' || $State->{version} ne '0.0.195' || $State->{from} ne '0.0.194' || $State->{hash} ne $Meta->{package_sha256};
 die "Base no longer194.\n" if $Gate->_Version() ne '0.0.194';
 my ($Name,$Version,$Hash)=('TESSERAMELTCrossObjectRecovery','0.0.1','49fbcb650ae70940e5c250df0628e90b7018f0bf872ea9799fc8897bb65dd21f');
 my $Actual=InstalledArtifactHash($DB,$Name,$Version);print "repair_artifact_sha256=$Actual\n";
 die "Reviewed repair artifact differs.\n" if $Actual ne $Hash;
 die "Repair must be absent from image.\n" if grep {$_->{name} eq $Name} @{$Inventory->{packages}};
 die "Repair registry unreadable.\n" if !$DB->Prepare(SQL=>q{SELECT content FROM package_repository WHERE name = ? AND version = ? AND install_status = ?},Bind=>[\$Name,\$Version,\(my $Status='installed')]);
 my @Rows;while(my @R=$DB->FetchrowArray()){push @Rows,$R[0]}
 die "Repair registry ambiguous.\n" if @Rows!=1;
 my $XML=$Rows[0];$XML=decode_base64($XML) if !$DB->GetDatabaseFunction('DirectBlob') && $XML =~ /\A[a-zA-Z0-9+\/\n]+={0,2}[\n]?\z/;
 my $ReviewBytes=$XML;
 my $ReviewString=utf8::is_utf8($XML)?$XML:Encode::decode('UTF-8',$ReviewBytes,Encode::FB_CROAK());
 my %Review=$Package->PackageParse(String=>$ReviewString);
 VerifyRepairRetirementContract(\%Review);
 print "repair_retirement_contract=sole-repair-module,no-uninstall-code,no-uninstall-database\n";
 my $Bytes=utf8::is_utf8($XML)?Encode::encode('UTF-8',$XML):$XML;
 die "Repair changed while reading.\n" if sha256_hex($Bytes) ne $Hash;
 # Include the reviewed target-only package in a temporary planning inventory.
 # This proves the complete remaining upgrade plan before native uninstall.
 my $Temp=tempdir('retired-repair-XXXXXXXX',DIR=>'/opt/otobo/var/tmp',CLEANUP=>1);
 for my $P (@{$Inventory->{packages}}) {my $H=$P->{package_sha256};die "Invalid artifact hash.\n" if $H !~ /\A[a-f0-9]{64}\z/;copy("$Directory/packages/$H.opm","$Temp/$H.opm") or die}
 open $FH,'>:raw',"$Temp/$Hash.opm" or die;print {$FH} $Bytes;close $FH;
 my $Plan=JSON::PP->new->decode(JSON::PP->new->encode($Inventory));push @{$Plan->{packages}},{name=>$Name,version=>$Version,package_sha256=>$Hash};
 ReconcilePackages($Plan,$DB,RetirementPlanPackage->new($Package),$Temp,1);
 # Keep the existing durable claim; take ownership by CAS, never reset it.
 $State->{owner}=$Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length=>40);
 $State->{recovery}='retire-one-time-repair';my $Owned=$Gate->_Write($Raw,$Gate->_Encode($State));
 $Stage='native-uninstall';
 my $Key='TESSERA::PackageUpgrade::'.$Name;
 my $Journal=JSON::PP->new->canonical->encode({phase=>'UNINSTALLING',version=>$Version,hash=>$Hash});
 my $Handle=$DB->Connect() or die;
 my $N=$Handle->do('INSERT INTO system_data (data_key,data_value,create_time,create_by,change_time,change_by) VALUES (?,?,current_timestamp,1,current_timestamp,1)',undef,$Key,$Journal);
 die "Retirement already claimed.\n" if !defined $N || $N!=1;
 print "Retiring reviewed one-time repair via native uninstall\n";
 my $String=utf8::is_utf8($XML)?$XML:Encode::decode('UTF-8',$XML,Encode::FB_CROAK());
 die "Native repair uninstall failed.\n" if !$Package->PackageUninstall(String=>$String);
 die if !$DB->Prepare(SQL=>q{SELECT name FROM package_repository WHERE name = ? AND install_status = ?},Bind=>[\$Name,\$Status]);
 my @Still=$DB->FetchrowArray();die "Repair remains installed.\n" if @Still;
 $N=$Handle->do('DELETE FROM system_data WHERE data_key = ? AND data_value = ?',undef,$Key,$Journal);
 die "Retirement journal changed.\n" if !defined $N || $N!=1;
 $Stage='native-reconciliation';ReconcilePackages($Inventory,$DB,$Package,"$Directory/packages");
 die "Base upgrade verification failed.\n" if $Gate->_Version() ne $Meta->{version} || $Gate->_InstalledHash($Meta->{version}) ne $Meta->{package_sha256};
 CheckInventory($Inventory,$DB,$Package);
 $State->{phase}='CONFIGURING';$Owned=$Gate->_Write($Owned,$Gate->_Encode($State));
 $Stage='configuration';
 die "Execution storage incomplete.\n" if !$DB->Prepare(SQL=>'SELECT request_data, dispatch_data FROM ztsm_async_execution WHERE 1 = 0');$DB->FetchrowArray();
 die "Configuration rebuild failed.\n" if system('/usr/bin/python3','/usr/local/lib/tessera/configure.py')!=0;
 CheckInventory($Inventory,$DB,$Package);
 die "Base changed during configure.\n" if $Gate->_Version() ne $Meta->{version} || $Gate->_InstalledHash($Meta->{version}) ne $Meta->{package_sha256};
 $State->{phase}='READY';$Gate->_Write($Owned,$Gate->_Encode($State));
 $Gate->Check(Version=>$Meta->{version},Hash=>$Meta->{package_sha256});print "Recovery READY verified\n";1;
};
if (!$OK) {
 print STDERR "Recovery failed at $Stage; preserve claims and Job.\n";
 my $Error=$@ || '';
 if ($Error =~ /\A([A-Za-z0-9 ;:,.\/-]{1,180})\n/) {print STDERR "$1\n"}
 else {print STDERR "Exception detail withheld; inspect restricted application logs.\n"}
 exit 1;
}
'''

def program():
 image=HERE.parent/'image'
 inventory=(image/'package-inventory.pl').read_text().split('unless (caller)',1)[0]
 return inventory+'\n'+(image/'package-reconcile.pl').read_text()+'\n'+CONTROL

def recovery_job(saved,name):
 result=copy.deepcopy(saved)
 pod=result['spec']['template']['spec']
 if len(pod['containers'])!=1 or pod['containers'][0].get('args')!=['upgrade']:
  raise ValueError('Expected original controlled upgrade manifest')
 c=pod['containers'][0]
 if c['image']!='docker.io/library/tessera:0.0.195-r5-ubuntu26.04':raise ValueError('Requires observed195-r5 image')
 if [i['name'] for i in pod.get('initContainers',[])]!=['stage-upgrade']:raise ValueError('Missing isolated staging')
 if not any(e.get('name')=='TESSERA_UPGRADE_QUIESCED' and e.get('value')=='1' for e in c.get('env',[])):raise ValueError('Missing quiescence')
 if not any(m.get('mountPath')=='/opt/tessera/upgrade-bundle' and m.get('readOnly') for m in c.get('volumeMounts',[])):raise ValueError('Missing read-only bundle')
 c['command']=['/bin/bash','-c',common.SHELL,'recover-retired-repair'];c['args']=[program()]
 result['metadata']={'name':name,'namespace':saved['metadata']['namespace']}
 result['spec']['template']['metadata']['labels']['tessera-release-upgrade']=name
 result['spec']['backoffLimit']=0
 return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--state-directory', help='Original failed deployment state; auto-detected under ./artifacts if omitted')
    args = parser.parse_args()
    if args.state_directory:
        state=Path(args.state_directory).resolve()
    else:
        candidates=[]
        for path in Path('artifacts').glob('deploy-*/upgrade-job.json'):
            if json.loads(path.read_text()).get('metadata',{}).get('name')=='tessera-release-1794548900': candidates.append(path.parent)
        if len(candidates)!=1: raise ValueError('Need original private state for Job tessera-release-1794548900; use --state-directory on original deployment host')
        state=candidates[0].resolve()
    def load(name): return json.loads((state / name).read_text())
    saved = load('upgrade-job.json')
    previous_dir=state/'recovery-retired-repair'
    if not previous_dir.is_dir(): raise ValueError('Requires saved first recovery preflight-failure state')
    old_claim=json.loads((previous_dir/'maintenance-lock.json').read_text())
    previous_job=json.loads((previous_dir/'job.json').read_text())
    if saved['metadata']['name']!='tessera-release-1794548900' or saved['metadata']['namespace']!='tessera': raise ValueError('Recovery scoped to failed Job1794548900 in tessera')
    namespace = saved['metadata']['namespace']
    prefix = ['kubectl', '-n', namespace]
    def get(*parts): return json.loads(subprocess.check_output(prefix + ['get', *parts, '-o', 'json'], text=True))
    def run(*parts): subprocess.run(prefix + list(parts), check=True)
    def write_object(verb, obj, dry=False):
        subprocess.run(prefix + [verb] + (['--dry-run=server'] if dry else []) + ['-f', '-'],
                       input=json.dumps(obj), text=True, check=True)
    previous=get('job',previous_job['metadata']['name'])
    if not common.terminal(previous,'Failed'): raise ValueError('Previous recovery must be terminal Failed')
    previous_log=subprocess.check_output(prefix+['logs','job/'+previous_job['metadata']['name'],'-c',previous_job['spec']['template']['spec']['containers'][0]['name']],text=True)
    if not all(text in previous_log for text in ['repair_artifact_sha256=49fbcb650ae70940e5c250df0628e90b7018f0bf872ea9799fc8897bb65dd21f','Recovery failed at preflight','Reviewed repair artifact differs.']) or 'Retiring reviewed' in previous_log:
        raise ValueError('Prior recovery did not stop at reviewed artifact preflight; no replay permitted')
    failed = get('job', saved['metadata']['name'])
    if not common.terminal(failed, 'Failed'): raise ValueError('Original upgrade Job must be terminal Failed')
    lock = get('configmap', 'tessera-release-maintenance')
    if lock.get('metadata', {}).get('labels', {}).get('app.kubernetes.io/managed-by') != 'tessera-release-helper' or lock.get('data') != old_claim.get('data') or lock['data'].get('phase') != 'LOCKED':
        raise ValueError('Original maintenance ownership no longer matches saved state')
    for job in get('jobs')['items']:
        if job['spec']['template']['metadata'].get('labels', {}).get('tessera-release-upgrade') and not (common.terminal(job, 'Complete') or common.terminal(job, 'Failed')):
            raise ValueError('Another release or diagnostic Job is not terminal')
    workloads = []
    for filename in ('web-before.json', 'daemon-before.json'):
        before = load(filename);current = get('deployment', before['metadata']['name']);common.same_target(current, before)
        if current['spec'].get('replicas', 0) != 0: raise ValueError('Expected stopped deployment')
        if current['spec']['template']['spec']['containers'][0]['image'] != before['spec']['template']['spec']['containers'][0]['image']: raise ValueError('Deployment image changed')
        workloads.append(before)
    names = {d['metadata']['name'] for d in workloads}
    if any(h['spec']['scaleTargetRef']['name'] in names for h in get('hpa')['items']):
        raise ValueError('HPA ownership must be resolved before maintenance')
    out = state / 'recovery-retired-repair-v2'
    out.mkdir(mode=0o700, exist_ok=False)
    def save(name, obj):
        with (out / name).open('x', encoding='utf-8') as f:
            os.chmod(f.name, 0o600);json.dump(obj, f, indent=2)
    name = 'tessera-retire-repair-' + uuid.uuid4().hex[:8]
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
    # Already stopped; verify no live writers before creating the recovery Job.
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
        if common.terminal(status, 'Failed'):
            subprocess.run(prefix + ['logs', 'job/' + name, '-c', manifest['spec']['template']['spec']['containers'][0]['name'], '--tail=100'], check=False)
            raise ValueError('Recovery Job failed; leave deployments stopped and inspect saved state')
        if common.terminal(status, 'Complete'): break
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
    print('195 upgrade and both rollouts completed. Verify portal and daemon functionality. State:', out)


if __name__ == '__main__':
    try: main()
    except ValueError as error:
        raise SystemExit('Recovery stopped: ' + str(error) + '. Preserve Jobs, maintenance claim and state directory.') from None
    except FileNotFoundError as error:
        raise SystemExit('Recovery file not found: ' + str(error.filename) + '. Run on the host containing the original private state directory.') from None
    except (Exception, KeyboardInterrupt):
        raise SystemExit('Recovery stopped. Preserve Jobs, maintenance claim and state directory. Do not rerun or roll back after a migration failure; inspect Job logs first.') from None
