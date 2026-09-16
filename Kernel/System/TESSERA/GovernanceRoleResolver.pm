# --
# Kernel/System/TESSERA/GovernanceRoleResolver.pm
# --

package Kernel::System::TESSERA::GovernanceRoleResolver;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::CustomerUser',
    'Kernel::System::GovernanceObject',
    'Kernel::System::TESSERA::ScriptEngine',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub Resolve {
    my ( $Self, %Param ) = @_;

    my $Role = $Param{GovernanceRole};
    if ( ref $Role ne 'HASH' ) {
        return { Success => 0, Status => 'UNKNOWN', Error => 'GovernanceRole is required.' }
            if !defined $Role || $Role eq '';
        $Role = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $Role,
            DynamicFields      => 1,
            Silent             => 1,
        );
    }
    return { Success => 0, Status => 'UNKNOWN', Error => 'GovernanceRole could not be loaded.' }
        if ref $Role ne 'HASH' || ( $Role->{Class} || '' ) ne 'GovernanceRole';

    my $Source = _Scalar( $Role->{'DynamicField_ZTSM-ScriptEngine'} );
    return { Success => 0, Status => 'NO_SCRIPT', Error => 'GovernanceRole has no ZTSM-ScriptEngine value.' }
        if !defined $Source || $Source eq '';

    my $Ticket = ref $Param{Ticket} eq 'HASH' ? { %{ $Param{Ticket} } } : {};
    my $CustomerUserID = $Ticket->{CustomerUserID} || $Ticket->{CustomerUser};
    if ($CustomerUserID) {
        my %CustomerUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $CustomerUserID,
        );
        $Ticket->{CustomerUser} = {
            %CustomerUser,
            __Type  => 'CustomerUser',
            __Value => $CustomerUserID,
        };
    }

    my $ApplicationID = _Scalar( $Ticket->{'DynamicField_ZTicket-Application'} );
    if ($ApplicationID) {
        my $Application = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $ApplicationID,
            DynamicFields      => 1,
            Silent             => 1,
        );
        $Ticket->{'ZTicket-Application'} = $Application if ref $Application eq 'HASH';
    }

    my $RoleReference = $Role->{GovernanceObjectID} || $Role->{LastVersionID} || $Param{GovernanceRole};
    return $Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine')->ScriptEvaluate(
        Source  => $Source,
        UserID  => $Param{UserID} || 1,
        Context => {
            'CURRENT OBJECT' => $RoleReference,
            TICKET           => $Ticket,
        },
    );
}

sub _Scalar {
    my ($Value) = @_;
    $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
    $Value = $Value->{Content} if ref $Value eq 'HASH' && exists $Value->{Content};
    return if ref $Value;
    return $Value;
}

1;
