#!/usr/bin/env python3
"""Probe failed upgrade Redis credentials/operations without rerunning package hooks."""
import importlib.util
from pathlib import Path

PERL = r'''
use strict; use warnings;
use Kernel::System::ObjectManager;
use Kernel::System::TESSERA::Secrets ();
sub Classification {
    my ($Error)=@_;
    for my $Code (qw(WRONGPASS NOAUTH NOPERM READONLY MASTERDOWN CLUSTERDOWN LOADING OOM MISCONF)) {
        return $Code if $Error =~ /\b\Q$Code\E\b/;
    }
    return 'connection-error' if $Error =~ /connect|timed? ?out|refused|unreachable/i;
    return 'operation-error';
}
sub Probe {
    my ($Name,$Code)=@_;
    my $OK=eval {$Code->();1};
    my $Error=$@;
    print "$Name=", $OK?'ok':Classification($Error),"\n";
    return $OK;
}
print "diagnostic=redis-operation-probe-no-package-hooks\n";
local $Kernel::OM=Kernel::System::ObjectManager->new();
my $Config=$Kernel::OM->Get('Kernel::Config')->Get('Cache::Redis') || {};
my $Module=$Kernel::OM->Get('Kernel::Config')->Get('Cache::Module') || '';
print 'cache_backend=', $Module eq 'Kernel::System::Cache::Redis'?'native-secret-override':
    $Module eq 'Kernel::System::TESSERA::SecretRedis'?'secret-redis':'other',"\n";
my $Password;
if (!Probe('secret_read',sub {
    die "Missing secret\n" if !$Config->{PasswordSecret};
    $Password=Kernel::System::TESSERA::Secrets::Read($Config->{PasswordSecret});
})) {exit 1;}
my $Class=$Config->{RedisFast}?'Redis::Fast':'Redis';
print "redis_client=$Class\n";
my $Client;
if (!Probe('redis_connect_auth_select',sub {
    die "Client unavailable\n" if !$Kernel::OM->Get('Kernel::System::Main')->Require($Class);
    $Client=$Class->new(server=>$Config->{Server} || '127.0.0.1:6379',password=>$Password);
    $Client->ping();
    $Client->select($Config->{DatabaseNumber} || 0);
})) {exit 1;}
undef $Password;
Probe('replication_role_query',sub {
    my $Info=$Client->info('replication');
    my $Role=ref $Info eq 'HASH'?$Info->{role}:defined $Info && $Info=~/^role:(master|slave|replica)\r?$/m?$1:'unknown';
    $Role='unknown' if !defined $Role || $Role!~/\A(?:master|slave|replica)\z/;
    print "redis_role=$Role\n";
});
# Only disposable, uniquely named probes. Never flush caches or change
# release receipts, SysConfig values or package journals.
my $Key='TESSERADiagnostic:'.$$.'-'.time.'-'.int(rand(1000000000));
my $Set=Probe('redis_set_ex',sub {$Client->set($Key,'nonsecret-probe','EX',60)});
Probe('redis_get',sub {
    my $Value=$Client->get($Key);
    die "Readback mismatch\n" if !defined $Value || $Value ne 'nonsecret-probe';
}) if $Set;
my $SetKey=$Key.':set';
if (Probe('redis_sadd',sub {$Client->sadd($SetKey,'probe')})) {
    Probe('redis_expire',sub {$Client->expire($SetKey,60)});
}
Probe('redis_delete_probe',sub {$Client->del($Key,$SetKey)});
my $Backend;
if (Probe('cache_backend_load',sub {
    die "Unreviewed backend\n" if $Module ne 'Kernel::System::Cache::Redis'
        && $Module ne 'Kernel::System::TESSERA::SecretRedis';
    $Backend=$Kernel::OM->Get($Module);
})) {
    my $CacheKey='probe';
    my $Type='TESSERADiagnostic_'.$$.'_'.time.'_'.int(rand(1000000000));
    if (Probe('cache_set_roundtrip',sub {
        die "Cache write failed\n" if !$Backend->Set(Type=>$Type,Key=>$CacheKey,Value=>'nonsecret-probe',TTL=>60);
        die "Cache readback failed\n" if ($Backend->Get(Type=>$Type,Key=>$CacheKey) || '') ne 'nonsecret-probe';
    })) {Probe('cache_delete_probe',sub {$Backend->Delete(Type=>$Type,Key=>$CacheKey)})}
    Probe('cache_probe_cleanup',sub {
        $Client->del($Type.':'.$CacheKey);
        $Client->srem('namespaces',$Type);
    });
}
my $DB=$Kernel::OM->Get('Kernel::System::DB');
Probe('sysconfig_existing_row_query',sub {
    my $Name='DynamicFieldScreens::ObjectTypes###ITSMChangeManagement';
    die "Metadata unavailable\n" if !$DB->Prepare(
        SQL=>'SELECT COUNT(*) FROM sysconfig_default WHERE name = ?',Bind=>[\$Name]);
    my @Row=$DB->FetchrowArray();
    die "Invalid metadata\n" if !defined $Row[0] || $Row[0]!~/\A[0-9]+\z/;
    print "sysconfig_change_setting_rows=$Row[0]\n";
    $DB->FetchrowArray();
});
print "diagnostic=completed-no-upgrade-no-journal-change\n";
'''


def load_diagnostic():
    spec = importlib.util.spec_from_file_location(
        "tessera_redis_diagnostic", Path(__file__).with_name("diagnose-release.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.PERL = PERL
    module.diagnostic_program = lambda package_plan=False: PERL
    return module


if __name__ == "__main__":
    load_diagnostic().main()
