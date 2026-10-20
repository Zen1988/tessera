# Insert inside Kernel::Config::Load, after ordinary defaults. Keep the existing
# host, database name, user, DSN and other non-secret configuration.
# All launcher include paths must contain /opt/otobo/Custom before Config loads.
require Kernel::System::TESSERA::Secrets;
$Self->{'DatabasePw'} = Kernel::System::TESSERA::Secrets::Read('db-password');
# OTOBO treats a wholly brace-wrapped password as its legacy encrypted format,
# and the string "0" as false in DB constructor fallback. Reject these rather
# than decrypting or falling back to another password.
die "TESSERA database credential incompatible with native OTOBO password handling\n"
    if $Self->{'DatabasePw'} eq '0' || $Self->{'DatabasePw'} =~ /\A\{.*\}\z/s;

# Native Cache::Redis has no Password option in the inspected 11.1 source.
# This TESSERA-owned backend supplies authentication and operation-boundary refresh.
$Self->{'Cache::Module'} = 'Kernel::System::TESSERA::SecretRedis';
$Self->{'Cache::Redis'} = {
    Server         => 'redis:6379',
    DatabaseNumber => 0,
    RedisFast      => 0,
    PasswordSecret => 'redis-password',
};
$Self->{'Cache::InMemory'} = 0; # persistent workers must reach the backend

# Integrations should read at their own safe connection/request boundary:
# my $Token = Kernel::System::TESSERA::Secrets::Read('api-token');
# Merely assigning a token in Config.pm does not refresh existing API clients.
