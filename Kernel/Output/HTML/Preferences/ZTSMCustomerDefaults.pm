# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::CustomerUser',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Web::Request',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    for my $Needed (qw(UserID ConfigItem)) {
        die "Got no $Needed!" if !$Self->{$Needed};
    }

    return $Self;
}

sub Param {
    my ( $Self, %Param ) = @_;

    return if !$Param{UserData} || !$Param{UserData}->{UserLogin};

    my @Fields = (
        {
            Name    => 'ZUser-SupportProfile',
            Key     => 'Default Support Profile',
            Classes => ['SupportProfile'],
            Filter  => 'SupportAssignment',
        },
        {
            Name    => 'ZUser-Application',
            Key     => 'Default Application',
            Classes => ['Application'],
        },
        {
            Name    => 'ZUser-Environment',
            Key     => 'Default Environment',
            Classes => ['Environment'],
        },
        {
            Name    => 'ZUser-Location',
            Key     => 'Default Ticket Location',
            Classes => ['Location'],
        },
    );

    my @Params;
    FIELD:
    for my $Field (@Fields) {
        my $DynamicFieldConfig = $Self->_DynamicFieldConfigGet( Name => $Field->{Name} );
        next FIELD if !$DynamicFieldConfig;

        my $SelectedID = $Self->_DynamicFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            CustomerUserLogin  => $Param{UserData}->{UserLogin},
        );

        my %Data = $Field->{Filter}
            ? $Self->_SupportProfileData( CustomerUserID => $Param{UserData}->{UserLogin} )
            : $Self->_GovernanceObjectData( Classes => $Field->{Classes} );

        next FIELD if !%Data && !$SelectedID;

        if ( $SelectedID && !$Data{$SelectedID} ) {
            my $Name = $Self->_GovernanceObjectName( GovernanceObjectID => $SelectedID );
            $Data{$SelectedID} = $Name || $SelectedID;
        }

        my $Option = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->BuildSelection(
            Data         => \%Data,
            Name         => $Field->{Name},
            ID           => $Field->{Name},
            Class        => 'Modernize',
            SelectedID   => $SelectedID || '',
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 0,
        );

        push @Params, {
            %Param,
            Name   => $Field->{Name},
            Key    => $Field->{Key},
            Option => $Option,
        };
    }

    return @Params;
}

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Param{UserData} || !$Param{UserData}->{UserLogin};

    my %AllowedSupportProfile = $Self->_SupportProfileData(
        CustomerUserID => $Param{UserData}->{UserLogin},
    );

    FIELD:
    for my $FieldName (qw(ZUser-SupportProfile ZUser-Application ZUser-Environment ZUser-Location)) {
        my $DynamicFieldConfig = $Self->_DynamicFieldConfigGet( Name => $FieldName );
        next FIELD if !$DynamicFieldConfig;

        my $Value = $Param{GetParam}->{$FieldName} ? $Param{GetParam}->{$FieldName}->[0] : '';
        $Value = $Self->_NormalizeValue($Value) || '';

        if (
            $FieldName eq 'ZUser-SupportProfile'
            && $Value
            && !$AllowedSupportProfile{$Value}
            )
        {
            $Self->{Error} = Translatable('Selected support profile is not assigned to this customer user.');
            return;
        }

        my $Success;
        if ($Value) {
            $Success = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectName         => $Param{UserData}->{UserLogin},
                Value              => $Value,
                UserID             => $Self->{UserID},
            );
        }
        else {
            my $ObjectID = $Self->_DynamicFieldObjectIDGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                CustomerUserLogin  => $Param{UserData}->{UserLogin},
            );

            # No mapping means that this customer user has no DynamicField
            # values to delete. Keep an empty preference submission idempotent.
            $Success = !$ObjectID
                ? 1
                : $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueDelete(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $ObjectID,
                    UserID             => $Self->{UserID},
                );
        }

        if ( !$Success ) {
            $Self->{Error} = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->{LanguageObject}->Translate(
                'Unable to set value for dynamic field %s!',
                $FieldName,
            );
            return;
        }
    }

    $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserCacheClear(
        User => $Param{UserData}->{UserLogin},
    );

    $Self->{Message} = Translatable('Preferences updated successfully!');
    return 1;
}

sub Error {
    my ( $Self, %Param ) = @_;

    return $Self->{Error} || '';
}

sub Message {
    my ( $Self, %Param ) = @_;

    return $Self->{Message} || '';
}

sub _DynamicFieldConfigGet {
    my ( $Self, %Param ) = @_;

    return if !$Param{Name};

    return $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        Name => $Param{Name},
    );
}

sub _DynamicFieldValueGet {
    my ( $Self, %Param ) = @_;

    return if !$Param{DynamicFieldConfig} || !$Param{CustomerUserLogin};

    my $Value = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        ObjectName         => $Param{CustomerUserLogin},
    );

    return $Self->_NormalizeValue($Value);
}

sub _DynamicFieldObjectIDGet {
    my ( $Self, %Param ) = @_;

    return if !$Param{DynamicFieldConfig} || !$Param{CustomerUserLogin};

    my $ObjectIDs = $Kernel::OM->Get('Kernel::System::DynamicField')->ObjectMappingGet(
        ObjectName => $Param{CustomerUserLogin},
        ObjectType => $Param{DynamicFieldConfig}->{ObjectType},
    );

    return if !$ObjectIDs || ref $ObjectIDs ne 'HASH';
    return $ObjectIDs->{ $Param{CustomerUserLogin} };
}

sub _GovernanceObjectData {
    my ( $Self, %Param ) = @_;

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @ObjectIDs = $GovernanceObjectObject->GovernanceObjectSearch(
        Classes => $Param{Classes} || [],
        Result  => 'ARRAY',
        Limit   => 1000,
    );

    my %Data;
    OBJECTID:
    for my $ObjectID (@ObjectIDs) {
        my $Object = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $ObjectID,
            Silent             => 1,
        );
        next OBJECTID if !$Object || !$Object->{GovernanceObjectID};

        $Data{ $Object->{GovernanceObjectID} } = $Object->{Name} || $Object->{Number} || $Object->{GovernanceObjectID};
    }

    return %Data;
}

sub _SupportProfileData {
    my ( $Self, %Param ) = @_;

    return if !$Param{CustomerUserID};

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @AssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(
        Classes => ['SupportAssignment'],
        Result  => 'ARRAY',
        Limit   => 1000,
    );

    my %CustomerUserID = map { lc $_ => 1 } $Self->_CustomerUserReferenceIDs(
        CustomerUserID => $Param{CustomerUserID},
    );

    my %ProfileID;
    ASSIGNMENT:
    for my $AssignmentID (@AssignmentIDs) {
        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $AssignmentID,
            DynamicFields      => 1,
            Silent             => 1,
        );
        next ASSIGNMENT if !$Assignment || ref $Assignment ne 'HASH';

        my $AssignmentUser = $Self->_NormalizeReferenceValue(
            $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'},
        );
        next ASSIGNMENT if !$AssignmentUser || !$CustomerUserID{ lc $AssignmentUser };

        my $ProfileID = $Self->_NormalizeReferenceValue(
            $Assignment->{'DynamicField_ZTSMSupportAssignment-SupportProfile'},
        );
        next ASSIGNMENT if !$ProfileID || $ProfileID !~ m{\A\d+\z};

        $ProfileID{$ProfileID} = 1;
    }

    my %Data;
    PROFILEID:
    for my $ProfileID ( sort { $a <=> $b } keys %ProfileID ) {
        my $Name = $Self->_GovernanceObjectName( GovernanceObjectID => $ProfileID );
        next PROFILEID if !$Name;

        $Data{$ProfileID} = $Name;
    }

    return %Data;
}

sub _GovernanceObjectName {
    my ( $Self, %Param ) = @_;

    return if !$Param{GovernanceObjectID};

    my $Object = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $Param{GovernanceObjectID},
        Silent             => 1,
    );

    return if !$Object || ref $Object ne 'HASH';

    return $Object->{Name} || $Object->{Number} || $Object->{GovernanceObjectID};
}

sub _CustomerUserReferenceIDs {
    my ( $Self, %Param ) = @_;

    my $CustomerUserID = $Self->_NormalizeValue( $Param{CustomerUserID} );
    return if !defined $CustomerUserID || $CustomerUserID eq '';

    my %CustomerUserID = ( $CustomerUserID => 1 );

    for my $CustomerID (
        $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerIDs(
            User => $CustomerUserID,
        )
        )
    {
        my $Value = $Self->_NormalizeValue($CustomerID);
        $CustomerUserID{$Value} = 1 if defined $Value && $Value ne '';
    }

    return sort keys %CustomerUserID;
}

sub _NormalizeReferenceValue {
    my ( $Self, $Value ) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return $Self->_NormalizeReferenceValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Content} if defined $Value->{Content};
    }

    return $Value;
}

sub _NormalizeValue {
    my ( $Self, $Value ) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return $Self->_NormalizeValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Content} if defined $Value->{Content};
    }

    return $Value;
}

1;
