# Inside Kernel::Config::Load. Preserve current Server/database choices.
# Custom must precede the application root in every Web/Daemon launcher @INC.
$Self->{'Cache::Module'} = 'Kernel::System::Cache::Redis';
$Self->{'Cache::Redis'} = {
    Server         => 'redis:6379',
    DatabaseNumber => 0,
    RedisFast      => 0,
    PasswordSecret => 'redis-password',
};
$Self->{'Cache::InMemory'} = 0;
# Runtime file: /run/tessera-secrets/redis-password. No value in Config.pm.
# Build179 Kernel::System::TESSERA::SecretRedis remains supported unchanged.
