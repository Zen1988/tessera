package Kernel::System::Console::Command::Admin::TESSERA::APIKey;

use v5.24;
use strict;
use warnings;
use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = ('Kernel::System::TESSERA::APIKey');

sub Configure {
    my ( $Self, %Param ) = @_;
    $Self->Description('Create, renew, or revoke a TESSERA API key. Plaintext keys are displayed once.');
    $Self->AddOption( Name => 'action', Description => 'create|renew|revoke', Required => 1, HasValue => 1, ValueRegex => qr/\A(?:create|renew|revoke)\z/ );
    $Self->AddOption( Name => 'customer-user', Description => 'API-only CustomerUser login (create).', Required => 0, HasValue => 1, ValueRegex => qr/.+/ );
    $Self->AddOption( Name => 'name', Description => 'Human-readable key name.', Required => 0, HasValue => 1, ValueRegex => qr/.+/ );
    $Self->AddOption( Name => 'key-id', Description => 'Existing key ID (renew/revoke).', Required => 0, HasValue => 1, ValueRegex => qr/\A\d+\z/ );
    $Self->AddOption( Name => 'expires-in-days', Description => 'New key lifetime in days; omit for no fixed expiry.', Required => 0, HasValue => 1, ValueRegex => qr/\A\d+\z/ );
    $Self->AddOption( Name => 'overlap-hours', Description => 'Renewal overlap before the old key expires (default 24).', Required => 0, HasValue => 1, ValueRegex => qr/\A\d+\z/ );
    return;
}

sub Run {
    my ( $Self, %Param ) = @_;
    my $Action = $Self->GetOption('action');
    my $Object = $Kernel::OM->Get('Kernel::System::TESSERA::APIKey');
    my $ExpiresIn = $Self->GetOption('expires-in-days');
    $ExpiresIn *= 86400 if defined $ExpiresIn;

    if ( $Action eq 'revoke' ) {
        my $KeyID = $Self->GetOption('key-id') || return $Self->_Missing('--key-id');
        return $Object->KeyRevoke( KeyID => $KeyID, UserID => 1 )
            ? $Self->_Done('Key revoked immediately.') : $Self->_Failed('Could not revoke key.');
    }

    my $Result;
    if ( $Action eq 'create' ) {
        my $CustomerUserID = $Self->GetOption('customer-user') || return $Self->_Missing('--customer-user');
        my $Name = $Self->GetOption('name') || return $Self->_Missing('--name');
        $Result = $Object->KeyCreate( CustomerUserID => $CustomerUserID, Name => $Name, ExpiresIn => $ExpiresIn, CreateBy => 1 );
    }
    else {
        my $KeyID = $Self->GetOption('key-id') || return $Self->_Missing('--key-id');
        my $Overlap = $Self->GetOption('overlap-hours');
        $Overlap = 24 if !defined $Overlap;
        $Result = $Object->KeyRenew(
            KeyID => $KeyID, Name => $Self->GetOption('name'), ExpiresIn => $ExpiresIn,
            OverlapSeconds => $Overlap * 3600, CreateBy => 1,
        );
    }
    return $Self->_Failed('Could not create key.') if !$Result;
    $Self->Print("<red>Copy this API key now. It cannot be recovered:</red>\n$Result->{APIKey}\n");
    $Self->Print("KeyID: $Result->{KeyID}\nPrefix: $Result->{Prefix}\n");
    $Self->Print("Old key expires: $Result->{OldKeyExpiresTime}\n") if $Result->{OldKeyExpiresTime};
    return $Self->ExitCodeOk();
}

sub _Missing { my ( $Self, $Name ) = @_; $Self->PrintError("$Name is required for this action."); return $Self->ExitCodeError(); }
sub _Failed  { my ( $Self, $Text ) = @_; $Self->PrintError($Text); return $Self->ExitCodeError(); }
sub _Done    { my ( $Self, $Text ) = @_; $Self->Print("<green>$Text</green>\n"); return $Self->ExitCodeOk(); }

1;
