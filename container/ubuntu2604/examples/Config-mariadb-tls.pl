# FUTURE Config.pm integration, after MariaDB server TLS is configured/tested.
# Keep current non-secret DB settings; DSN hostname MUST match db.tessera.local
# or another explicitly issued SAN. Merge existing Database::Attribute options.
$Self->{'Database::Attribute'} ||= {};
$Self->{'Database::Attribute'}->{mariadb_ssl} = 1;
$Self->{'Database::Attribute'}->{mariadb_ssl_ca_file} = '/run/tessera-tls/ca.crt';
$Self->{'Database::Attribute'}->{mariadb_ssl_verify_server_cert} = 1;
# DatabasePw continues to come from the mounted secret reader, not this file.
