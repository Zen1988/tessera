package Kernel::System::ITSMConfigItem::CustomerEntitlement;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::CustomerUser',
    'Kernel::System::GovernanceObject',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub CustomerHasAssetRole {
    my ( $Self, %Param ) = @_;

    return if !$Param{CustomerUserID};

    my $Assignments = $Self->_AssignmentsGet(
        CustomerUserID => $Param{CustomerUserID},
        RequireRole    => 'ASSET',
    );

    return @{$Assignments} ? 1 : undef;
}

sub CustomerHasRole {
    my ( $Self, %Param ) = @_;
    return if !$Param{CustomerUserID} || !$Param{Role};
    my $Assignments = $Self->_AssignmentsGet(
        CustomerUserID => $Param{CustomerUserID},
        RequireRole    => $Param{Role},
    );
    return @{$Assignments} ? 1 : undef;
}

sub ContractEntitlementAccessCheck {
    my ( $Self, %Param ) = @_;
    return if !$Param{CustomerUserID} || !$Param{ContractEntitlementID};

    my $Entitlement = $Self->_ConfigItemReferenceGet(
        Value => $Param{ContractEntitlementID},
        Class => 'ContractEntitlement',
    );
    return $Self->_Denied(%Param) if !$Entitlement;

    my @EntitledProfiles = $Self->_ReferenceObjects(
        Value => $Entitlement->{'DynamicField_Contract-SupportProfie'},
        Class => 'SupportProfile',
    );
    return $Self->_Denied(%Param) if !@EntitledProfiles;
    my %EntitledProfileID = map { $_->{GovernanceObjectID} => 1 } @EntitledProfiles;

    my $Assignments = $Self->_AssignmentsGet(
        CustomerUserID => $Param{CustomerUserID},
        RequireRole    => $Param{RequireRole},
    );
    for my $Assignment ( @{$Assignments} ) {
        my @AssignedProfiles = $Self->_ReferenceObjects(
            Value => $Assignment->{'DynamicField_ZTSMSupportAssignment-SupportProfile'},
            Class => 'SupportProfile',
        );
        return 1 if grep { $EntitledProfileID{ $_->{GovernanceObjectID} } } @AssignedProfiles;
    }
    return $Self->_Denied(%Param);
}

sub ConfigItemDiscoveryCheck {
    my ( $Self, %Param ) = @_;

    return $Self->_ConfigItemAccessCheck(
        %Param,
        RequireAssetRole => 0,
    );
}

sub ConfigItemDetailAccessCheck {
    my ( $Self, %Param ) = @_;

    return $Self->_ConfigItemAccessCheck(
        %Param,
        RequireAssetRole => 1,
    );
}

sub ConfigItemIDsFilter {
    my ( $Self, %Param ) = @_;

    return [] if !$Param{CustomerUserID};
    return [] if ref $Param{ConfigItemIDs} ne 'ARRAY';

    my @Allowed;
    for my $ConfigItemID ( @{ $Param{ConfigItemIDs} } ) {
        next if !$ConfigItemID;
        next if !$Self->_ConfigItemAccessCheck(
            CustomerUserID  => $Param{CustomerUserID},
            ConfigItemID    => $ConfigItemID,
            RequireAssetRole => $Param{RequireAssetRole} ? 1 : 0,
            LogNo           => 1,
        );
        push @Allowed, $ConfigItemID;
    }

    return \@Allowed;
}

sub _ConfigItemAccessCheck {
    my ( $Self, %Param ) = @_;

    return if !$Param{CustomerUserID};
    return if !$Param{ConfigItemID};

    my $ConfigItem = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID  => $Param{ConfigItemID},
        DynamicFields => 1,
    );
    return $Self->_Denied(%Param) if !$ConfigItem || !$ConfigItem->{ConfigItemID};

    my @EntitlementIDs = $Self->_ScalarValues(
        $ConfigItem->{'DynamicField_ZTAM-ContractEntitlement'}
    );
    return $Self->_Denied(%Param) if @EntitlementIDs != 1;

    my $Entitlement = $Self->_ConfigItemReferenceGet(
        Value => $EntitlementIDs[0],
        Class => 'ContractEntitlement',
    );
    return $Self->_Denied(%Param) if !$Entitlement;

    return $Self->ContractEntitlementAccessCheck(
        CustomerUserID       => $Param{CustomerUserID},
        ContractEntitlementID => $Entitlement->{ConfigItemID},
        RequireRole          => $Param{RequireRole} || ( $Param{RequireAssetRole} ? 'ASSET' : undef ),
        LogNo                => $Param{LogNo},
    );
}

sub _AssignmentsGet {
    my ( $Self, %Param ) = @_;

    my @CustomerReferences = $Self->_CustomerUserReferences( $Param{CustomerUserID} );
    return [] if !@CustomerReferences;

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %AssignmentID;
    for my $CustomerReference (@CustomerReferences) {
        my @IDs = $GovernanceObjectObject->GovernanceObjectSearch(
            Classes => ['SupportAssignment'],
            'DynamicField_ZTSMSupportAssignment-UserAccount' => {
                Equals => $CustomerReference,
            },
            Result => 'ARRAY',
            Limit  => 1000,
            UserID => 1,
        );
        $AssignmentID{$_} = 1 for @IDs;
    }

    my @Assignments;
    ASSIGNMENT_ID:
    for my $AssignmentID ( sort { $a <=> $b } keys %AssignmentID ) {
        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $AssignmentID,
            DynamicFields      => 1,
            Silent             => 1,
        );
        next ASSIGNMENT_ID if !$Assignment;
        next ASSIGNMENT_ID if !$Self->_CustomerUserValueMatches(
            Value      => $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'},
            Candidates => \@CustomerReferences,
        );

        if ( $Param{RequireRole} ) {
            my @Roles = $Self->_ReferenceObjects(
                Value => $Assignment->{'DynamicField_ZTSMSupportAssignment-Role'},
                Class => 'GovernanceRole',
            );
            next ASSIGNMENT_ID if @Roles != 1;
            next ASSIGNMENT_ID if uc( $Roles[0]{Name} || '' ) ne uc $Param{RequireRole};
        }

        push @Assignments, $Assignment;
    }

    return \@Assignments;
}

sub _CustomerUserReferences {
    my ( $Self, $CustomerUserID ) = @_;

    return if !defined $CustomerUserID || $CustomerUserID eq '';
    my %Reference = ( $CustomerUserID => 1 );
    for my $CustomerID (
        $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerIDs(
            User => $CustomerUserID,
        )
        )
    {
        $Reference{$CustomerID} = 1 if defined $CustomerID && $CustomerID ne '';
    }
    return sort keys %Reference;
}

sub _CustomerUserValueMatches {
    my ( $Self, %Param ) = @_;
    my @Values = $Self->_ScalarValues( $Param{Value} );
    my %Candidate = map { lc($_) => 1 } @{ $Param{Candidates} || [] };
    return scalar grep { $Candidate{ lc $_ } } @Values;
}

sub _ConfigItemReferenceGet {
    my ( $Self, %Param ) = @_;

    my @Values = $Self->_ScalarValues( $Param{Value} );
    return if @Values != 1 || $Values[0] !~ m{\A\d+\z};

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my @Candidates;
    my @ConfigItemIDs = ( $Values[0] );
    my $VersionConfigItemID = $ConfigItemObject->VersionConfigItemIDGet(
        VersionID => $Values[0],
    );
    push @ConfigItemIDs, $VersionConfigItemID if $VersionConfigItemID;

    for my $ConfigItemID (@ConfigItemIDs) {
        my $Object = eval {
            $ConfigItemObject->ConfigItemGet(
                ConfigItemID  => $ConfigItemID,
                DynamicFields => 1,
            );
        };
        push @Candidates, $Object if $Object && ref $Object eq 'HASH';
    }

    my %Unique = map { $_->{ConfigItemID} => $_ }
        grep { ( $_->{Class} || '' ) eq $Param{Class} && $_->{ConfigItemID} } @Candidates;
    return if keys %Unique != 1;
    return ( values %Unique )[0];
}

sub _ReferenceObjects {
    my ( $Self, %Param ) = @_;

    my @Values = $Self->_ScalarValues( $Param{Value} );
    my $Object = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %Found;

    for my $Value (@Values) {
        my @Candidates;
        if ( $Value =~ m{\A\d+\z} ) {
            for my $Lookup ( { GovernanceObjectID => $Value }, { VersionID => $Value } ) {
                my $Candidate = eval {
                    $Object->GovernanceObjectGet(
                        %{$Lookup},
                        DynamicFields => 0,
                        Silent        => 1,
                    );
                };
                push @Candidates, $Candidate if $Candidate && ref $Candidate eq 'HASH';
            }
        }
        else {
            my @IDs = $Object->GovernanceObjectSearch(
                Classes => [ $Param{Class} ],
                Name    => $Value,
                Result  => 'ARRAY',
                Limit   => 10,
                UserID  => 1,
            );
            for my $ID (@IDs) {
                my $Candidate = $Object->GovernanceObjectGet(
                    GovernanceObjectID => $ID,
                    DynamicFields      => 0,
                    Silent             => 1,
                );
                push @Candidates, $Candidate if $Candidate;
            }
        }

        for my $Candidate (@Candidates) {
            next if ( $Candidate->{Class} || '' ) ne $Param{Class};
            $Found{ $Candidate->{GovernanceObjectID} } = $Candidate;
        }
    }

    return values %Found;
}

sub _ScalarValues {
    my ( $Self, $Value ) = @_;
    return if !defined $Value;
    if ( ref $Value eq 'ARRAY' ) {
        return map { $Self->_ScalarValues($_) } @{$Value};
    }
    if ( ref $Value eq 'HASH' ) {
        for my $Key (qw(Value Key Content ID)) {
            return $Self->_ScalarValues( $Value->{$Key} ) if defined $Value->{$Key};
        }
        return;
    }
    return $Value eq '' ? () : ($Value);
}

sub _Denied {
    my ( $Self, %Param ) = @_;
    if ( !$Param{LogNo} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => 'TESSERA customer ConfigItem access denied: CustomerUserID='
                . ( $Param{CustomerUserID} || '<missing>' )
                . ' ConfigItemID=' . ( $Param{ConfigItemID} || '<missing>' )
                . ' RequireAssetRole=' . ( $Param{RequireAssetRole} ? 1 : 0 ),
        );
    }
    return;
}

1;
