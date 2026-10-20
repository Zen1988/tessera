#!/usr/bin/env perl
use strict;
use warnings;
use Kernel::System::ObjectManager;
use Kernel::System::TESSERA::Secrets ();
my $Mode=$ARGV[0] || 'ready';
my $OK=eval {
    local $Kernel::OM=Kernel::System::ObjectManager->new();
    my $Config=$Kernel::OM->Get('Kernel::Config');
    my $RedisConfig=$Config->Get('Cache::Redis') || {};
    die "PasswordSecret required\n" if !$RedisConfig->{PasswordSecret};
    Kernel::System::TESSERA::Secrets::Read($RedisConfig->{PasswordSecret});
    my $Module=$Config->Get('Cache::Module') || '';
    die "Secret Redis backend required\n" if $Module ne 'Kernel::System::Cache::Redis' && $Module ne 'Kernel::System::TESSERA::SecretRedis';
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "DB query failed\n" if !$DB->Prepare(SQL=>'SELECT 1');
    my @Row=$DB->FetchrowArray();
    die "DB result failed\n" if !@Row || $Row[0]!=1;
    $DB->FetchrowArray();
    my $Redis=$Kernel::OM->Get($Module);
    my $Client=$Module eq 'Kernel::System::TESSERA::SecretRedis'
        ? $Redis->_Client() : ($Redis->_Connect() ? $Redis->{Redis} : undef);
    die "Redis authentication failed\n" if !$Client || !$Client->ping();
    if ($Mode eq 'smoke') {
        my $Key='image-smoke-'.$$.'-'.time;
        $Redis->Set(Type=>'TESSERAImageSmoke',Key=>$Key,Value=>'nonsecret-fixture',TTL=>60);
        die "Cache roundtrip failed\n" if ($Redis->Get(Type=>'TESSERAImageSmoke',Key=>$Key) || '') ne 'nonsecret-fixture';
        $Redis->Delete(Type=>'TESSERAImageSmoke',Key=>$Key);
    }
    1;
};
# Never forward driver/AUTH exceptions or dump configuration.
die "TESSERA readiness failed: check mounted configuration, DB, Redis and permissions\n" if !$OK;
print "TESSERA dependency check OK\n" if $Mode eq 'smoke';
