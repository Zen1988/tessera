# Configuration fragment inside Kernel::Config::Load, after a reviewed Base192 install.
# Keep an independent unlinked emergency local administrator and restart workers.
# Remove additional AuthModule1..10 entries; this router must be the sole backend.
$Self->{'TESSERA::LocalIdentity::Enabled'} = 1;
$Self->{'AuthModule'} = 'Kernel::System::Auth::TESSERALocalIdentity';
$Self->{'AuthModule::UseSyncBackend'} = '';
# Preserve native agent MFA configuration.
# Customer authentication must already support the primary local customer DB.
# This fragment does not replace LDAP/OIDC customer configuration automatically.
