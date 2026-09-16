# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://ncs.com.sg
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::System::DynamicField::ObjectType::GovernanceObject;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Log',
    'Kernel::System::Web::Request',
    'Kernel::System::Cache',
    'Kernel::System::DynamicField::Backend',
);

=head1 NAME

Kernel::System::DynamicField::ObjectType::Governance Object - support for Governance Object as an object type

=head1 DESCRIPTION

Attach dynamic fields to an GovernanceObject.

=head1 PUBLIC INTERFACE

=head2 new()

Usually, you want to create an instance of this
by using Kernel::System::DynamicField::ObjectType::GovernanceObject->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {}, $Type;
}

=head2 PreValueSet()

Perform specific functions before the value is set for a dynamic field for this object type.

    my $Success = $DynamicFieldGovernanceObjectHandlerObject->PreValueSet(
        Param              => \%Param,
    );

This handler can be skipped by passing the attribute C<GovernanceObjectHandled> in C<Param>.

=cut

sub PreValueSet {
    my ( $Self, %Param ) = @_;

    # all needed params are checked by the backend before
    if ( !$Param{Param} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Param of backend!",
        );

        return;
    }

    # if we are coming from Version.pm nothing has to be changed
    return 1 if $Param{Param}{GovernanceObjectHandled};

    # upgrade version of subsequent dynamic field changes if a version was added in this request
    if ( $Self->{VersionUpgrade} && $Self->{VersionUpgrade}{ $Param{Param}{ObjectID} } ) {
        $Param{Param}{ObjectID} = $Self->{VersionUpgrade}{ $Param{Param}{ObjectID} };

        return 1;
    }

    return 1 if !$Param{Param}{DynamicFieldConfig}{CIClass};

    # check whether the changed field triggers a new Governance Object version and if so, add a new one
    my $ClassPreferences = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
        Class => 'ZTSM::GovernanceObject::Class',
        Name  => $Param{Param}{DynamicFieldConfig}{CIClass},
    );
    my %VersionTrigger = map { $_ => 1 } @{ $ClassPreferences->{VersionTrigger} // [] };

    if ( $VersionTrigger{ 'DynamicField_' . $Param{Param}{DynamicFieldConfig}{Name} } ) {
        my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

        my $NewVersionID = $GovernanceObjectObject->VersionAdd(
            LastVersionID => $Param{Param}{ObjectID},
            UserID        => $Param{Param}{UserID},
        );

        if ( !$NewVersionID ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Could not create new version for LastVersionID $Param{Param}{ObjectID}!",
            );

            return;
        }

        # set old and new version to new one to make sure, that lenses can work with either
        $Self->{VersionUpgrade}{ $Param{Param}{ObjectID} } = $NewVersionID;
        $Self->{VersionUpgrade}{$NewVersionID}             = $NewVersionID;
        $Param{Param}{ObjectID}                            = $NewVersionID;
    }

    return 1;
}

=head2 PostValueSet()

Perform specific functions after the value has been set for a dynamic field for this object type.

    my $Success = $DynamicFieldGovernanceObjectHandlerObject->PostValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,      # complete config of the DynamicField
        ObjectID           => $ObjectID,                # ID of the current object that the field
                                                        # must be linked to, e. g. GovernanceObjectID
        Value              => $Value,                   # Value to store, depends on backend type
        UserID             => 123,
        GovernanceObjectHandled  => 1,                        # optional, skips this if handled elsewhere
    );

This handler can be skipped by passing the attribute C<GovernanceObjectHandled> in C<Param>.

=cut

sub PostValueSet {
    my ( $Self, %Param ) = @_;

    # if we are coming from Version.pm nothing has to be changed
    return 1 if $Param{GovernanceObjectHandled};

    # all needed params are checked by the backend before
    my $GovernanceObjectObject          = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $CacheObject               = $Kernel::OM->Get('Kernel::System::Cache');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $GovernanceObjectID = $GovernanceObjectObject->VersionGovernanceObjectIDGet( VersionID => $Param{ObjectID} );

    # delete cache
    $CacheObject->Delete(
        Type => $GovernanceObjectObject->{CacheType},
        Key  => 'GovernanceObjectGet::VersionID::' . $Param{ObjectID} . '::DFData::1',
    );
    $CacheObject->Delete(
        Type => $GovernanceObjectObject->{CacheType},
        Key  => 'GovernanceObjectGet::GovernanceObjectID::' . $GovernanceObjectID . '::DFData::1',
    );

    # prepare readable values for the history,
    # the result is a hashref with the keys Value and Label
    my $ReadableValue = $DynamicFieldBackendObject->ReadableValueRender(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Value              => $Param{Value}
    );
    my $ReadableOldValue = $DynamicFieldBackendObject->ReadableValueRender(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Value              => $Param{OldValue},
    );

    # trigger event
    $GovernanceObjectObject->EventHandler(
        Event => 'GovernanceObjectDynamicFieldUpdate_' . $Param{DynamicFieldConfig}{Name},
        Data  => {
            FieldName        => $Param{DynamicFieldConfig}{Name},
            Value            => $Param{Value},
            OldValue         => $Param{OldValue},
            ReadableValue    => $ReadableValue->{Value},
            ReadableOldValue => $ReadableOldValue->{Value},
            GovernanceObjectID     => $GovernanceObjectID,
            UserID           => $Param{UserID},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 ObjectDataGet()

retrieves the data of the current object.

    my %ObjectData = $DynamicFieldGovernanceObjectHandlerObject->ObjectDataGet(
        DynamicFieldConfig => $DynamicFieldConfig,      # complete config of the DynamicField
        UserID             => 123,
    );

returns:

    %ObjectData = (
        ObjectID => 123,
        Data     => {
            GovernanceObjectID     => 123,
            Number           => '20101027000001',
            ClassID          => 17,
            ...
        }
    );

=cut

sub ObjectDataGet {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Needed (qw(DynamicFieldConfig UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Check DynamicFieldConfig (general).
    if ( !IsHashRefWithData( $Param{DynamicFieldConfig} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "The field configuration is invalid",
        );
        return;
    }

    # Check DynamicFieldConfig (internally).
    for my $Needed (qw(ID FieldType ObjectType)) {
        if ( !$Param{DynamicFieldConfig}->{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed in DynamicFieldConfig!",
            );
            return;
        }
    }

    # TODO: why does this method depend on the param object?
    my $GovernanceObjectID = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam(
        Param => 'GovernanceObjectID',
    );

    return unless $GovernanceObjectID;

    my %GovernanceObject = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $GovernanceObjectID,
    );

    return (
        ObjectID => $GovernanceObjectID,
        Data     => \%GovernanceObject,
    );
}

=head2 GetEntityIDforLinking()

retrieves GovernanceObjectID for given VersionID

    my $GovernanceObjectID = $DynamicFieldGovernanceObjectHandlerObject->GetEntityIDforLinking(
        VersionID => 123,
        LinkKey => 'Source',      # or 'Target'
        TypeName => 'GovernanceObject', # or 'GovernanceObjectVersion'
    );

=cut

sub GetEntityIDforLinking {

    my ( $Self, %Param ) = @_;

    my $ID       = $Param{ID};
    my $LinkKey  = $Param{LinkKey};
    my $TypeName = $Param{TypeName};

    # if the key is a 'Target' key ...
    if ( $LinkKey eq 'Target' ) {

        # ...then only GovernanceObjectVersion items will need VersionID resolution
        if ( $TypeName eq 'GovernanceObject' ) {
            return $ID;
        }
    }

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        VersionID     => $ID,
        DynamicFields => 0,
    );

    return $GovernanceObject->{GovernanceObjectID};
}

1;
