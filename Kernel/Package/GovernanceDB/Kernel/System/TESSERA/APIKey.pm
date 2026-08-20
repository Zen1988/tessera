package Kernel::System::TESSERA::APIKey;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

use Digest::SHA qw(sha256_hex);

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::CustomerUser',
    'Kernel::System::Main',
    'Kernel::System::Time',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub KeyCreate {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(CustomerUserID Name CreateBy)) {
        return if !defined $Param{$Needed} || $Param{$Needed} eq '';
    }
    my %CustomerUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
        User => $Param{CustomerUserID},
    );
    return if !%CustomerUser || !$CustomerUser{UserLogin};

    my $Secret = $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString( Length => 64 );
    my $Prefix = 'ztsm_' . $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString( Length => 12 );
    my $Token  = $Prefix . '.' . $Secret;
    my $Hash   = sha256_hex($Token);

    my $ExpiresTime;
    if ( $Param{ExpiresIn} ) {
        $ExpiresTime = $Kernel::OM->Get('Kernel::System::Time')->SystemTime2TimeStamp(
            SystemTime => time() + $Param{ExpiresIn},
        );
    }

    my $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO ztsm_api_key '
            . '(customer_user_id, key_name, key_prefix, key_hash, expires_time, create_time, create_by) '
            . 'VALUES (?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Param{CustomerUserID}, \$Param{Name}, \$Prefix, \$Hash, \$ExpiresTime, \$Param{CreateBy},
        ],
    );
    return if !$Success;

    my $KeyID = $Self->_KeyIDByHash($Hash);
    return if !$KeyID;

    return {
        KeyID       => $KeyID,
        CustomerUserID => $Param{CustomerUserID},
        Name        => $Param{Name},
        Prefix      => $Prefix,
        APIKey      => $Token,
        ExpiresTime => $ExpiresTime,
    };
}

sub KeyAuthenticate {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{APIKey} || $Param{APIKey} !~ m{\Aztsm_[A-Za-z0-9]{12}\.[A-Za-z0-9]{64}\z};
    my $Hash = sha256_hex( $Param{APIKey} );

    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => 'SELECT k.id, k.customer_user_id, k.key_name, k.key_prefix, k.expires_time '
            . 'FROM ztsm_api_key k INNER JOIN customer_user u ON u.login = k.customer_user_id '
            . 'WHERE k.key_hash = ? AND k.revoke_time IS NULL '
            . 'AND (k.expires_time IS NULL OR k.expires_time > current_timestamp) '
            . 'AND u.valid_id = 1',
        Bind  => [ \$Hash ],
        Limit => 1,
    );
    my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray();
    return if !@Row;

    $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'UPDATE ztsm_api_key SET last_used_time = current_timestamp WHERE id = ?',
        Bind => [ \$Row[0] ],
    );

    return {
        KeyID       => $Row[0],
        CustomerUserID => $Row[1],
        Name        => $Row[2],
        Prefix      => $Row[3],
        ExpiresTime => $Row[4],
    };
}

sub KeyRenew {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(KeyID CreateBy)) {
        return if !$Param{$Needed};
    }
    my $Old = $Self->KeyGet( KeyID => $Param{KeyID} );
    return if !$Old || $Old->{RevokeTime};

    my $New = $Self->KeyCreate(
        CustomerUserID => $Old->{CustomerUserID},
        Name     => $Param{Name} || $Old->{Name} . ' (renewed)',
        ExpiresIn => $Param{ExpiresIn},
        CreateBy => $Param{CreateBy},
    );
    return if !$New;

    my $OverlapSeconds = defined $Param{OverlapSeconds} ? $Param{OverlapSeconds} : 86400;
    $OverlapSeconds = 0 if $OverlapSeconds < 0;
    my $OldExpires = $Kernel::OM->Get('Kernel::System::Time')->SystemTime2TimeStamp(
        SystemTime => time() + $OverlapSeconds,
    );

    my $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ztsm_api_key SET expires_time = ?, replaced_by = ?, change_time = current_timestamp, change_by = ? '
            . 'WHERE id = ? AND revoke_time IS NULL',
        Bind => [ \$OldExpires, \$New->{KeyID}, \$Param{CreateBy}, \$Param{KeyID} ],
    );
    if ( !$Success ) {
        $Self->KeyRevoke( KeyID => $New->{KeyID}, UserID => $Param{CreateBy} );
        return;
    }

    $New->{ReplacesKeyID} = $Param{KeyID};
    $New->{OldKeyExpiresTime} = $OldExpires;
    return $New;
}

sub KeyRevoke {
    my ( $Self, %Param ) = @_;
    return if !$Param{KeyID} || !$Param{UserID};
    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ztsm_api_key SET revoke_time = current_timestamp, revoke_by = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ? AND revoke_time IS NULL',
        Bind => [ \$Param{UserID}, \$Param{UserID}, \$Param{KeyID} ],
    );
}

sub KeyGet {
    my ( $Self, %Param ) = @_;
    return if !$Param{KeyID};
    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => 'SELECT id, customer_user_id, key_name, key_prefix, expires_time, last_used_time, revoke_time, replaced_by, create_time, create_by '
            . 'FROM ztsm_api_key WHERE id = ?',
        Bind  => [ \$Param{KeyID} ],
        Limit => 1,
    );
    my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray();
    return if !@Row;
    return {
        KeyID => $Row[0], CustomerUserID => $Row[1], Name => $Row[2], Prefix => $Row[3],
        ExpiresTime => $Row[4], LastUsedTime => $Row[5], RevokeTime => $Row[6],
        ReplacedBy => $Row[7], CreateTime => $Row[8], CreateBy => $Row[9],
    };
}

sub _KeyIDByHash {
    my ( $Self, $Hash ) = @_;
    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => 'SELECT id FROM ztsm_api_key WHERE key_hash = ?', Bind => [ \$Hash ], Limit => 1,
    );
    my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray();
    return $Row[0];
}

1;
