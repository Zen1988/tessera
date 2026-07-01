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

package Kernel::System::MELTObject::Version;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules
use List::Util qw(any);

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::MELTObject::Version - sub module of Kernel::System::MELTObject

=head1 DESCRIPTION

All version functions for MELT Object objects.

=head1 PUBLIC INTERFACE

=head2 VersionZoomList()

return a MELT Object version list as array-hash reference

    my $VersionListRef = $MELTObjectObject->VersionZoomList(
        MELTObjectID => 123,
    );

=cut

sub VersionZoomList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{MELTObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need MELTObjectID!',
        );
        return;
    }

    # get MELT Object
    my $MELTObject = $Self->MELTObjectGet(
        MELTObjectID => $Param{MELTObjectID},
    );

    # get version zoom list
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => <<'END_SQL',
SELECT id, name, version_string, ztsm_status_id, description, create_time, create_by, change_time, change_by
  FROM melt_object_item_version
  WHERE melt_object_id = ?
  ORDER BY id
END_SQL
        Bind => [ \$Param{MELTObjectID} ],
    );

    # fetch the result
    my @VersionList;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        push @VersionList,
            {
                VersionID     => $Row[0],
                Name          => $Row[1],
                VersionString => $Row[2],
                ZTSMStatusID   => $Row[3],
                Description   => $Row[4],
                CreateTime    => $Row[5],
                CreateBy      => $Row[6],
                ChangeTime    => $Row[7],
                ChangeBy      => $Row[8],
            };

    }

    for my $Version (@VersionList) {

        # get ZTSM Status functionality
        my $ZTSMStatus;
        if ( $Version->{ZTSMStatusID} ) {
            $ZTSMStatus = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
                ItemID => $Version->{ZTSMStatusID},
            );
        }

        $Version->{ZTSMStatus}     = $ZTSMStatus->{Name} if $ZTSMStatus;
        $Version->{ZTSMStatusType} = $ZTSMStatus && ref $ZTSMStatus->{Functionality} eq 'ARRAY'
            ? $ZTSMStatus->{Functionality}[0] // ''
            : '';

        # add MELT Object data
        $Version->{ClassID}          = $MELTObject->{ClassID};
        $Version->{Class}            = $MELTObject->{Class};
        $Version->{Number}           = $MELTObject->{Number};
        $Version->{ZTSMStatusID}   = $MELTObject->{ZTSMStatusID};
        $Version->{ZTSMStatus}     = $MELTObject->{ZTSMStatus};
        $Version->{ZTSMStatusType} = $MELTObject->{ZTSMStatusType};
    }

    return \@VersionList;
}

=head2 VersionListAll()

Returns a two-dimensional hash reference with the MELT Object ids as keys of the first level
and the corresponding version ids as keys of the second level,
then followed by the version data as hash reference.

    my $VersionListRef = $MELTObjectObject->VersionListAll(
        MELTObjectIDs => [ 1, 2, 3, 4, ...],    # optional

        OlderDate     => '2014-12-22 23:59:59', # optional
                                                # finds versions older than the given date
                                                # Format MUST be
                                                # YYYY-MM-DD HH:MM:SS
                                                # fill missing values with 0 first
                                                # Example: 2014-04-01 07:03:04
                                                # otherwise it won't be taken as
                                                # valid search parameter

        Limit         => 1000000,               # optional
    );

Returns:

    $VersionListRef = {

        # MELTObjectID
        1 => {

            # VersionID
            100 => {
                VersionID     => 100,
                MELTObjectID  => 1,
                Name          => 'MELTObject1',
                VersionString => 'Version1',
                DefinitionID  => 5,
                ZTSMStatusID   => 3,
                ZTSMStatusID   => 2,
                Description   => 'ABCD',
                CreateTime    => '2016-03-22 17:58:00',
                CreateBy      => 1,
            },

            # VersionID
            101 => {
                VersionID     => 101,
                MELTObjectID  => 1,
                Name          => 'MELTObject2',
                VersionString => 'Version2',
                DefinitionID  => 5,
                ZTSMStatusID   => 3,
                ZTSMStatusID   => 2,
                Description   => 'ABCD',
                CreateTime    => '2016-03-22 17:58:00',
                CreateBy      => 1,
            },
        },

        # MELTObjectID
        2 => {

            # VersionID
            150 => {
                VersionID     => 150,
                MELTObjectID  => 2,
                Name          => 'MELTObject1',
                VersionString => 'Version1',
                DefinitionID  => 5,
                ZTSMStatusID   => 3,
                ZTSMStatusID   => 2,
                Description   => 'ABCD',
                CreateTime    => '2016-03-22 17:58:00',
                CreateBy      => 1,
            },

            # VersionID
            151 => {
                VersionID     => 151,
                MELTObjectID  => 2,
                Name          => 'MELTObject1',
                VersionString => 'Version1',
                DefinitionID  => 5,
                ZTSMStatusID   => 3,
                ZTSMStatusID   => 2,
                Description   => 'ABCD',
                CreateTime    => '2016-03-22 17:58:00',
                CreateBy      => 1,
            },
        },
    };

=cut

sub VersionListAll {
    my ( $Self, %Param ) = @_;

    # collect the conditions for the WHERE clause
    my @Conditions;
    my @BindParameter;

    # if we got MELTObjectIDs make sure we just have numeric ids,
    # extract those and use it for the query
    if ( IsArrayRefWithData( $Param{MELTObjectIDs} ) ) {
        my @MELTObjectIDs = grep { $_ =~ m/^\d+$/ } @{ $Param{MELTObjectIDs} };
        push @Conditions, 'melt_object_id IN (' . ( join ', ', @MELTObjectIDs ) . ')';
    }

    if ( $Param{OlderDate} && $Param{OlderDate} =~ m/^\d{4}\-\d{2}\-\d{2}\ \d{2}\:\d{2}:\d{2}$/ ) {
        push @Conditions,    'create_time < ?';
        push @BindParameter, \$Param{OlderDate};
    }

    # build sql
    my $SQL = <<'END_SQL';
SELECT id, melt_object_id, name, version_string, definition_id, ztsm_status_id, description,
    create_time, create_by, change_time, change_by
  FROM melt_object_item_version
END_SQL

    if (@Conditions) {
        $SQL .= 'WHERE ' . join ' AND ', @Conditions;
    }

    # set limit
    if ( $Param{Limit} ) {
        $Param{Limit} = $Kernel::OM->Get('Kernel::System::DB')->Quote( $Param{Limit}, 'Integer' );
    }

    if (@BindParameter) {
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL   => $SQL,
            Bind  => \@BindParameter,
            Limit => $Param{Limit},
        );
    }
    else {
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL   => $SQL,
            Limit => $Param{Limit},
        );
    }

    my %Results;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Results{ $Row[1] }->{ $Row[0] } = {
            VersionID     => $Row[0],
            MELTObjectID  => $Row[1],
            Name          => $Row[2]  || '',
            VersionString => $Row[3]  || '',
            DefinitionID  => $Row[4]  || '',
            ZTSMStatusID   => $Row[5]  || '',
            Description   => $Row[6]  || '',
            CreateTime    => $Row[7]  || '',
            CreateBy      => $Row[8]  || '',
            ChangeTime    => $Row[9]  || '',
            ChangeBy      => $Row[10] || '',
        };
    }

    return \%Results;
}

=head2 VersionList()

return the list of MELT Object version IDs of the specified MELT Object as an array reference.
The IDs are sorted in ascending order.

    my $VersionListRef = $MELTObjectObject->VersionList(
        MELTObjectID => 123,
    );

=cut

sub VersionList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{MELTObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need MELTObjectID!',
        );

        return;
    }

    # get version list
    my @VersionList = $Kernel::OM->Get('Kernel::System::DB')->SelectColArray(
        SQL => <<'END_SQL',
SELECT id
  FROM melt_object_item_version
  WHERE melt_object_id = ?
  ORDER BY id
END_SQL
        Bind => [ \$Param{MELTObjectID} ],
    );

    return \@VersionList;
}

=head2 VersionNameGet()

returns the name of a version of a MELT Object.

    my $VersionName = $MELTObjectObject->VersionNameGet(
        VersionID => 123,
    );

or

    my $VersionName = $MELTObjectObject->VersionNameGet(
        MELTObjectID => 123,
    );

=cut

sub VersionNameGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{VersionID} && !$Param{MELTObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need VersionID or MELTObjectID!',
        );
        return;
    }

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    if ( $Param{VersionID} ) {

        # check if result is already cached
        my $CacheKey = 'VersionNameGet::VersionID::' . $Param{VersionID};
        my $Cache    = $CacheObject->Get(
            Type => $Self->{CacheType},
            Key  => $CacheKey,
        );
        return ${$Cache} if $Cache;

        # get version
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL => 'SELECT id, name '
                . 'FROM melt_object_item_version WHERE id = ?',
            Bind  => [ \$Param{VersionID} ],
            Limit => 1,
        );
    }
    else {

        # check if result is already cached
        my $CacheKey = 'VersionNameGet::MELTObjectID::' . $Param{MELTObjectID};
        my $Cache    = $CacheObject->Get(
            Type => $Self->{CacheType},
            Key  => $CacheKey,
        );
        return ${$Cache} if $Cache;

        # get version
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL => 'SELECT id, name '
                . 'FROM melt_object_item_version '
                . 'WHERE melt_object_id = ? ORDER BY id DESC',
            Bind  => [ \$Param{MELTObjectID} ],
            Limit => 1,
        );
    }

    # fetch the result
    my %Version;
    while ( my ( $Id, $Name ) = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Version{VersionID} = $Id;
        $Version{Name}      = $Name;
    }

    # check version
    if ( !$Version{VersionID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'No such MELT Object version!',
        );
        return;
    }

    # set cache for VersionID (always)
    my $CacheKey = 'VersionNameGet::VersionID::' . $Version{VersionID};
    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \$Version{Name},
    );

    # set cache for MELTObjectID (only if called with MELTObjectID)
    if ( $Param{MELTObjectID} ) {
        $CacheKey = 'VersionNameGet::MELTObjectID::' . $Param{MELTObjectID};
        $CacheObject->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => \$Version{Name},
        );
    }

    return $Version{Name};
}

=head2 VersionMELTObjectIDGet()

return the MELT Object id of a version

    my $MELTObjectID = $MELTObjectObject->VersionMELTObjectIDGet(
        VersionID => 123,
    );

=cut

sub VersionMELTObjectIDGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{VersionID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need VersionID!',
        );
        return;
    }

    # check if result is already cached
    return $Self->{Cache}->{VersionMELTObjectIDGet}->{ $Param{VersionID} }
        if $Self->{Cache}->{VersionMELTObjectIDGet}->{ $Param{VersionID} };

    # get MELT Object id
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => 'SELECT melt_object_id FROM melt_object_item_version WHERE id = ?',
        Bind  => [ \$Param{VersionID} ],
        Limit => 1,
    );

    # fetch the result
    my $MELTObjectID;
    while ( my ($Id) = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $MELTObjectID = $Id;
    }

    # cache the result
    $Self->{Cache}->{VersionMELTObjectIDGet}->{ $Param{VersionID} } = $MELTObjectID;

    return $MELTObjectID;
}

=head2 VersionAdd()

adds a new version to either an existing MELT Object.
Or adds the initial version to an MELT Object that is being created.

    my $VersionID = $MELTObjectObject->VersionAdd(
        MELTObjectID      => 123,
        LastVersionID     => 123,
        LastVersion       => {...}          # either MELTObjectID or LastVersion(ID) is mandatory
        UserID            => 1,
        Name              => 'The Name',    # optional
        VersionString     => 'The Version', # optional
        ZTSMStatusID       => 8,             # optional
        ZTSMStatusID       => 4,             # optional
        Description       => 'ABCD',        # optional
        DynamicField_Name => $Value,        # optional
    );

=cut

sub VersionAdd {
    my ( $Self, %Param ) = @_;

    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );

        return;
    }

    my $LastVersion = $Param{LastVersion} || $Self->MELTObjectGet(
        MELTObjectID  => $Param{MELTObjectID},
        VersionID     => $Param{LastVersionID},
        DynamicFields => 1,
    );

    my %Version = (
        $LastVersion->%*,
        %Param,
    );

    # check needed stuff
    for my $Attribute (qw(MELTObjectID Name ZTSMStatusID)) {
        if ( !$Version{$Attribute} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Attribute!",
            );

            return;
        }
    }

    # get class list
    my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::MELT::Class',
    );

    return unless $ClassList;
    return unless ref $ClassList eq 'HASH';

    my %ClassPreferences = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesGet(
        ItemID => $Version{ClassID},
    );

    my $NameModuleObject;
    my $NameModule = $ClassPreferences{NameModule} ? $ClassPreferences{NameModule}[0] : '';
    if ($NameModule) {

        # check if name module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::MELTObject::Name::$NameModule") ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load name module for class $Version{Class}!",
            );

            return;
        }

        # create a backend object
        $NameModuleObject = $Kernel::OM->Get("Kernel::System::MELTObject::Name::$NameModule");

        # override possible incoming name
        $Version{Name} = $NameModuleObject->MELTObjectNameCreate(%Param);

        # check, whether the feature to check for a unique name is enabled
        if ( $Kernel::OM->Get('Kernel::Config')->Get('UniqueCIName::EnableUniquenessCheck') ) {

            my $NameDuplicates = $Self->UniqueNameCheck(
                MELTObjectID => 'NEW',
                ClassID      => $Version{ClassID},
                Name         => $Version{Name},
            );

            # stop processing if the name is not unique
            if ( IsArrayRefWithData($NameDuplicates) ) {

                # build a string of all duplicate IDs
                my $Duplicates = join ', ', @{$NameDuplicates};

                # write an error log message containing all the duplicate IDs
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "The name $Version{Name} is already in use (MELTObjectIDs: $Duplicates)!",
                );

                return;
            }
        }
    }

    my $VersionStringModuleObject;
    my $VersionStringModule = $ClassPreferences{VersionStringModule} ? $ClassPreferences{VersionStringModule}[0] : '';
    if ($VersionStringModule) {

        # check if version string module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::MELTObject::VersionString::$VersionStringModule") ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load version string module for class $ClassList->{ $Param{ClassID} }!",
            );

            return;
        }

        # create a backend object
        $VersionStringModuleObject = $Kernel::OM->Get("Kernel::System::MELTObject::VersionString::$VersionStringModule");

        # override possible incoming version string
        $Version{VersionString} = $VersionStringModuleObject->VersionStringGet(
            Version    => \%Version,
            VersionAdd => 1,
        );
    }

    # new versions are always added with the newest definition
    my $Definition = $Self->DefinitionGet(
        ClassID => $Version{ClassID},
    );

    if ( !$Definition ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Definition!",
        );

        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert new version
    my $InsertSuccess = $DBObject->Do(
        SQL => <<'END_SQL',
INSERT INTO melt_object_item_version (
    melt_object_id, name, version_string, definition_id, ztsm_status_id, description,
    create_time, create_by, change_time, change_by
)
VALUES (
    ?, ?, ?, ?, ?, ?,
   current_timestamp, ?, current_timestamp, ?
)
END_SQL
        Bind => [
            \$Version{MELTObjectID},
            \$Version{Name},
            \$Version{VersionString},
            \$Definition->{DefinitionID},
            \$Version{ZTSMStatusID},
            \$Version{Description},
            \$Param{UserID},
            \$Param{UserID},
        ],
    );

    return unless $InsertSuccess;

    # get id of new version
    my ($VersionID) = $DBObject->SelectRowArray(
        SQL => <<'END_SQL',
SELECT id
  FROM melt_object_item_version
  WHERE melt_object_id = ?
  ORDER BY id DESC
END_SQL
        Bind  => [ \$Version{MELTObjectID} ],
        Limit => 1,
    );

    # check version id
    if ( !$VersionID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't get the new version id!",
        );

        return;
    }

    my $RecalcZTSMStatus = $Self->_UpdateCurAttr(
        Version     => \%Version,
        LastVersion => $LastVersion,
        VersionID   => $VersionID,
        UserID      => $Param{UserID},
    );

    # Clear the cache for MELTObjectGet without dynamic fields
    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    $CacheObject->Delete(
        Type => $Self->{CacheType},
        Key  => join(
            '::', 'MELTObjectGet',
            MELTObjectID => $Version{MELTObjectID},
            DFData       => 0,
        ),
    );

    # trigger VersionCreate even
    $Self->EventHandler(
        Event => 'VersionCreate',
        Data  => {
            MELTObjectID => $Version{MELTObjectID},
            Comment      => $VersionID,
            OldZTSMStatus => $LastVersion->{ZTSMStatus},
        },
        UserID => $Param{UserID},
    );

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my @UpdatedDynamicFields;

    DYNAMICFIELD:
    for my $DynamicField ( values $Definition->{DynamicFieldRef}->%* ) {
        next DYNAMICFIELD if !defined $Version{ 'DynamicField_' . $DynamicField->{Name} };
        next DYNAMICFIELD if $DynamicField->{FieldType} eq 'Lens' && !$Param{ 'DynamicField_' . $DynamicField->{Name} };

        my $Success = $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicField,
            ObjectID           => $VersionID,
            Value              => $Version{ 'DynamicField_' . $DynamicField->{Name} },
            UserID             => $Param{UserID},
            MELTObjectHandled  => 1,
            ConfigItemHandled        => 1,
            ExternalSource     => ( $Param{ExternalSource} && exists $Param{ 'DynamicField_' . $DynamicField->{Name} } ),
        );

        # only throw events for fields changed from the last version - checked by MELTObjectUpdate()
        if ( $Success && exists $Param{ 'DynamicField_' . $DynamicField->{Name} } ) {
            push @UpdatedDynamicFields, $DynamicField->{Name};
        }

        # update version data with actual dynamic field values
        # important in case of reference fields
        if ( $Param{ExternalSource} && $DynamicField->{Config}{ImportSearchAttribute} ) {
            my $Value = $DynamicFieldBackendObject->ValueGet(
                DynamicFieldConfig => $DynamicField,
                ObjectID           => $VersionID,
            );
            $Version{ 'DynamicField_' . $DynamicField->{Name} } = $Value;
        }
    }

    # Clear the cache for MELTObjectGet with dynamic fields
    $CacheObject->Delete(
        Type => $Self->{CacheType},
        Key  => join(
            '::', 'MELTObjectGet',
            MELTObjectID => $Version{MELTObjectID},
            DFData       => 1,
        ),
    );

    for my $Name (@UpdatedDynamicFields) {

        # prepare readable values for the history
        my $ReadableValue = $DynamicFieldBackendObject->ReadableValueRender(
            DynamicFieldConfig => $Definition->{DynamicFieldRef}{$Name},
            Value              => $Version{ 'DynamicField_' . $Name },
        );
        my $ReadableOldValue = $DynamicFieldBackendObject->ReadableValueRender(
            DynamicFieldConfig => $Definition->{DynamicFieldRef}{$Name},
            Value              => $LastVersion->{ 'DynamicField_' . $Name },
        );

        # Trigger dynamic field update event.
        # This might update the table melt_object_item_link.
        # Also pass in the last version in order to allow for special handling when the last version is changed.
        $Self->EventHandler(
            Event => 'MELTObjectDynamicFieldUpdate_' . $Name,
            Data  => {
                FieldName               => $Name,
                Value                   => $Version{ 'DynamicField_' . $Name },
                OldValue                => $LastVersion->{ 'DynamicField_' . $Name },
                ReadableValue           => $ReadableValue->{Value},
                ReadableOldValue        => $ReadableOldValue->{Value},
                MELTObjectID            => $Version{MELTObjectID},
                MELTObjectVersionID     => $VersionID,
                MELTObjectLastVersionID => $VersionID,
                UserID                  => $Param{UserID},
            },
            UserID => $Param{UserID},
        );
    }

    # recalculate the current ZTSM Status of all linked MELT Objects
    if ($RecalcZTSMStatus) {
        $Self->ZTSMStatusRecalc(
            MELTObjectID => $Version{MELTObjectID},
        );
    }

    return $VersionID;
}

=head2 VersionUpdate()

update a version

    my $VersionID = $MELTObjectObject->VersionUpdate(
        VersionID              => 123,
        Version                => {...}          # either VersionID or Version is mandatory
        UserID                 => 1,
        DefinitionID           => 123,           # optional, ID of the definition which was used for creating the input
        Name                   => 'The Name',    # optional
        VersionString          => 'The Version', # optional
        ZTSMStatusID            => 8,             # optional
        ZTSMStatusID            => 4,             # optional
        Description            => 'ABCD',        # optional
        DynamicField_<$DFName> => $Value,        # optional, one parameter for each dynamic field which should be updated
    );

=cut

sub VersionUpdate {
    my ( $Self, %Param ) = @_;

    my $Version = $Param{Version} || $Self->MELTObjectGet(
        VersionID     => $Param{VersionID},
        DynamicFields => 1,
    );

    # check needed stuff
    for my $Attribute (qw(UserID)) {
        if ( !$Param{$Attribute} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Attribute!",
            );

            return;
        }
    }

    if ( !$Version ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Version or VersionID!",
        );

        return;
    }

    my %ClassPreferences = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesGet(
        ItemID => $Version->{ClassID},
    );

    my $NameModuleObject;
    my $NameModule = $ClassPreferences{NameModule} ? $ClassPreferences{NameModule}[0] : '';
    if ($NameModule) {

        # check if name module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::MELTObject::Name::$NameModule") ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load name module for class $Version->{Class}!",
            );

            return;
        }

        # create a backend object
        $NameModuleObject = $Kernel::OM->Get("Kernel::System::MELTObject::Name::$NameModule");

        # TODO: Improve behaviour of modules which allow name reusage and do not always delete and recreate names
        # In case we have a name module which creates names incrementally, we currently have to delete first and recreate then
        if ( $NameModuleObject->can('MELTObjectNameDelete') ) {
            $NameModuleObject->MELTObjectNameDelete( $Version->{Name} );
        }

        $Param{Name} = $NameModuleObject->MELTObjectNameCreate(
            $Version->%*,
            %Param,
        );

        # check, whether the feature to check for a unique name is enabled
        if ( $Kernel::OM->Get('Kernel::Config')->Get('UniqueCIName::EnableUniquenessCheck') && $Param{Name} ne $Version->{Name} ) {

            my $NameDuplicates = $Self->UniqueNameCheck(
                MELTObjectID => $Version->{MELTObjectID},
                ClassID      => $Version->{ClassID},
                Name         => $Param{Name},
            );

            # stop processing if the name is not unique
            if ( IsArrayRefWithData($NameDuplicates) ) {

                # build a string of all duplicate IDs
                my $Duplicates = join ', ', @{$NameDuplicates};

                # write an error log message containing all the duplicate IDs
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "The name $Param{Name} is already in use (MELTObjectIDs: $Duplicates)!",
                );

                return;
            }
        }
    }

    my $VersionStringModuleObject;
    my $VersionStringModule = $ClassPreferences{VersionStringModule} ? $ClassPreferences{VersionStringModule}[0] : '';
    if ($VersionStringModule) {

        # check if version string module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::MELTObject::VersionString::$VersionStringModule") ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load version string module for class $Version->{Class}!",
            );

            return;
        }

        # create a backend object
        $VersionStringModuleObject = $Kernel::OM->Get("Kernel::System::MELTObject::VersionString::$VersionStringModule");

        # override possible incoming version string
        $Version->{VersionString} = $VersionStringModuleObject->VersionStringGet(
            Version => {
                $Version->%*,
                %Param,
            },
        );
    }

    my $CacheObject        = $Kernel::OM->Get('Kernel::System::Cache');
    my $RecalcZTSMStatus = 0;

    if ( any { defined $Param{$_} } qw/Name VersionString ZTSMStatusID DefinitionID Description/ ) {
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        for my $Attribute (qw/Name VersionString ZTSMStatusID DefinitionID Description/) {
            $Param{$Attribute} ||= $Version->{$Attribute};
        }

        # update existing version
        my $UpdateSuccess = $DBObject->Do(
            SQL => <<'END_SQL',
UPDATE melt_object_item_version
  SET name = ?, version_string = ?, definition_id = ?, ztsm_status_id = ?, description = ?, change_time = current_timestamp, change_by = ?
  WHERE id = ?
END_SQL
            Bind => [
                \$Param{Name},
                \$Param{VersionString},
                \$Param{DefinitionID},
                \$Param{ZTSMStatusID},
                \$Param{Description},
                \$Param{UserID},
                \$Version->{VersionID},
            ],
        );

        return unless $UpdateSuccess;

        # The MELT Object is only affected when the last version was modified
        if ( $Version->{VersionID} eq $Version->{LastVersionID} ) {
            $Param{MELTObjectID} = $Version->{MELTObjectID};

            $RecalcZTSMStatus = $Self->_UpdateCurAttr(
                Version     => \%Param,
                LastVersion => $Version,
                VersionID   => $Version->{VersionID},
                UserID      => $Param{UserID},
            );

            # Clear the cache for base attributes
            $CacheObject->Delete(
                Type => $Self->{CacheType},
                Key  => join(
                    '::', 'MELTObjectGet',
                    VersionID => $Version->{VersionID},
                    DFData    => 0,
                ),
            );
            $CacheObject->Delete(
                Type => $Self->{CacheType},
                Key  => join(
                    '::', 'MELTObjectGet',
                    MELTObjectID => $Version->{MELTObjectID},
                    DFData       => 0,
                ),
            );

            $CacheObject->Delete(
                Type => $Self->{CacheType},
                Key  => join( '::', 'VersionNameGet', VersionID => $Version->{VersionID} ),
            );

            # trigger VersionUpdate event
            $Self->EventHandler(
                Event => 'VersionUpdate',
                Data  => {
                    MELTObjectID => $Version->{MELTObjectID},
                    Comment      => $Version->{VersionID},
                    OldZTSMStatus => $Version->{ZTSMStatus},
                },
                UserID => $Param{UserID},
            );
        }
    }

    # get latest definition for the class
    my $Definition = $Self->DefinitionGet(
        ClassID => $Version->{ClassID},
    );

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my @UpdatedDynamicFields;

    DYNAMICFIELD:
    for my $Attribute ( keys %Param ) {
        next DYNAMICFIELD unless $Attribute =~ m/^DynamicField_(.+)/;
        next DYNAMICFIELD unless $Definition->{DynamicFieldRef}{$1};

        my $DynamicField = $Definition->{DynamicFieldRef}{$1};

        my $Success = $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicField,
            ObjectID           => $Version->{VersionID},
            Value              => $Param{$Attribute},
            UserID             => $Param{UserID},
            MELTObjectHandled  => 1,
            ConfigItemHandled        => 1,
            ExternalSource     => $Param{ExternalSource},
        );

        if ($Success) {
            push @UpdatedDynamicFields, $DynamicField->{Name};
        }

        # update version data with actual dynamic field values
        # important in case of reference fields
        if ( $Param{ExternalSource} && $DynamicField->{Config}{ImportSearchAttribute} ) {
            my $Value = $DynamicFieldBackendObject->ValueGet(
                DynamicFieldConfig => $DynamicField,
                ObjectID           => $Version->{VersionID},
            );
            $Param{$Attribute} = $Value;
        }
    }

    # Clear the cache for dynamic fields, too
    $CacheObject->Delete(
        Type => $Self->{CacheType},
        Key  => join(
            '::', 'MELTObjectGet',
            VersionID => $Version->{VersionID},
            DFData    => 1,
        ),
    );
    $CacheObject->Delete(
        Type => $Self->{CacheType},
        Key  => join(
            '::', 'MELTObjectGet',
            MELTObjectID => $Version->{MELTObjectID},
            DFData       => 1,
        ),
    );

    for my $Name (@UpdatedDynamicFields) {

        # prepare readable values for the history
        my $ReadableValue = $DynamicFieldBackendObject->ReadableValueRender(
            DynamicFieldConfig => $Definition->{DynamicFieldRef}{$Name},
            Value              => $Param{ 'DynamicField_' . $Name },
        );
        my $ReadableOldValue = $DynamicFieldBackendObject->ReadableValueRender(
            DynamicFieldConfig => $Definition->{DynamicFieldRef}{$Name},
            Value              => $Version->{ 'DynamicField_' . $Name },
        );

        # Trigger the dynamic field update event.
        # This might update the table melt_object_item_link.
        # Also pass in the last version in order to allow for special handling when the last version is changed.
        $Self->EventHandler(
            Event => 'MELTObjectDynamicFieldUpdate_' . $Name,
            Data  => {
                FieldName               => $Name,
                Value                   => $Param{ 'DynamicField_' . $Name },
                OldValue                => $Version->{ 'DynamicField_' . $Name },
                ReadableValue           => $ReadableValue->{Value},
                ReadableOldValue        => $ReadableOldValue->{Value},
                MELTObjectID            => $Version->{MELTObjectID},
                MELTObjectVersionID     => $Version->{VersionID},
                MELTObjectLastVersionID => $Version->{LastVersionID},
                UserID                  => $Param{UserID},
            },
            UserID => $Param{UserID},
        );
    }

    if ($RecalcZTSMStatus) {

        # recalculate the current ZTSM Status of all linked MELT Objects
        $Self->ZTSMStatusRecalc(
            MELTObjectID => $Version->{MELTObjectID},
        );
    }

    return 1;
}

=head2 VersionDelete()

delete an existing version or versions

    my $True = $MELTObjectObject->VersionDelete(
        VersionID => 123,
        UserID    => 1,
    );

or

    my $True = $MELTObjectObject->VersionDelete(
        MELTObjectID => 321,
        UserID       => 1,
    );

or

    my $True = $MELTObjectObject->VersionDelete(
        VersionIDs => [ 1, 2, 3, 4 ],
        UserID     => 1,
    );

=cut

sub VersionDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    if ( !$Param{VersionID} && !$Param{MELTObjectID} && !IsArrayRefWithData( $Param{VersionIDs} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need VersionID, MELTObjectID or VersionIDs!',
        );
        return;
    }

    my $VersionList = [];
    if ( $Param{VersionID} ) {
        push @{$VersionList}, $Param{VersionID};
    }
    elsif ( $Param{VersionIDs} ) {
        push @{$VersionList}, @{ $Param{VersionIDs} };
    }
    else {
        # get version list
        $VersionList = $Self->VersionList(
            MELTObjectID => $Param{MELTObjectID},
        );
    }

    return 1 if !scalar @{$VersionList};

    # get MELT Object id for version (needed for event handling)
    my $MELTObjectID = $Param{MELTObjectID};

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

    # to store unique MELT Object ids if there are versions from different MELT Objects
    my %MELTObjectIDs;

    my $Success;
    for my $VersionID ( @{$VersionList} ) {

        # get MELT Object id if necessary
        if ( $Param{VersionID} || $Param{VersionIDs} ) {
            $MELTObjectID = $Self->VersionMELTObjectIDGet(
                VersionID => $VersionID,
            );
        }

        # remember the unique MELT Object ids
        $MELTObjectIDs{$MELTObjectID} = 1;

        # get a list of all attachments
        my @ExistingAttachments = $Self->VersionAttachmentList(
            VersionID => $VersionID,
        );

        # delete all attachments of this MELT Object version
        FILENAME:
        for my $Filename (@ExistingAttachments) {

            # delete the attachment
            my $DeletionSuccess = $Self->VersionAttachmentDelete(
                VersionID => $VersionID,
                Filename  => $Filename,
                UserID    => $Param{UserID},
            );

            if ( !$DeletionSuccess ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Unknown problem when deleting attachment $Filename of MELT Object Version "
                        . "$VersionID. Please check the VirtualFS backend for stale "
                        . "files!",
                );
            }
        }

        # Delete dynamic field values for this version
        $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ObjectValuesDelete(
            ObjectType => 'MELTObject',
            ObjectID   => $VersionID,
            UserID     => $Param{UserID},
        );

        # delete version
        $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'DELETE FROM melt_object_item_version WHERE id = ?',
            Bind => [ \$VersionID ],
        );

        # trigger VersionDelete event when deletion was successful
        if ($Success) {

            $Self->EventHandler(
                Event => 'VersionDelete',
                Data  => {
                    MELTObjectID => $MELTObjectID,
                    Comment      => $VersionID,
                },
                UserID => $Param{UserID},
            );

            # delete affected caches
            for my $DFData (qw(0 1)) {
                $CacheObject->Delete(
                    Type => $Self->{CacheType},
                    Key  => join(
                        '::', 'MELTObjectGet',
                        VersionID => $VersionID,
                        DFData    => $DFData
                    ),
                );
            }
            $CacheObject->Delete(
                Type => $Self->{CacheType},
                Key  => join( '::', 'VersionNameGet', VersionID => $VersionID ),
            );

            delete $Self->{Cache}->{VersionMELTObjectIDGet}->{$VersionID};
        }
    }

    for my $MELTObjectID ( sort keys %MELTObjectIDs ) {

        # delete affected caches for MELTObjectID (most recent version might have been removed)
        for my $DFData (qw(0 1)) {
            $CacheObject->Delete(
                Type => $Self->{CacheType},
                Key  => join(
                    '::', 'MELTObjectGet',
                    MELTObjectID => $MELTObjectID,
                    DFData       => $DFData
                ),
            );
        }
        $CacheObject->Delete(
            Type => $Self->{CacheType},
            Key  => join( '::', 'VersionNameGet', MELTObjectID => $MELTObjectID ),
        );
    }

    return $Success;
}

=head2 VersionSearch()

return a MELT Object list as an array reference

    my $MELTObjectIDs = $MELTObjectObject->VersionSearch(
        Name         => 'The Name',      # (optional)
        ClassIDs     => [ 9, 8, 7, 6 ],  # (optional)
        ZTSMStatusIDs => [ 321, 123 ],    # (optional)
        ZTSMStatusIDs => [ 321, 123 ],    # (optional)

        PreviousVersionSearch => 1,  # (optional) default 0 (0|1)

        OrderBy => [ 'MELTObjectID', 'Number' ],                  # (optional)
        # default: [ 'MELTObjectID' ]
        # (MELTObjectID, Name, Number, ClassID, ZTSMStatusID, ZTSMStatusID
        # CreateTime, CreateBy, ChangeTime, ChangeBy)

        # Additional information for OrderBy:
        # The OrderByDirection can be specified for each OrderBy attribute.
        # The pairing is made by the array indices.

        OrderByDirection => [ 'Up', 'Down' ],                    # (optional)
        # default: [ 'Up' ]
        # (Down | Up)

        Limit          => 122,  # (optional)
        UsingWildcards => 0,    # (optional) default 1
    );

=cut

sub VersionSearch {
    my ( $Self, %Param ) = @_;

    # set default values
    if ( !defined $Param{UsingWildcards} ) {
        $Param{UsingWildcards} = 1;
    }

    # verify that all passed array parameters contain an arrayref
    ARGUMENT:
    for my $Argument (
        qw(
            OrderBy
            OrderByDirection
        )
        )
    {
        if ( !defined $Param{$Argument} ) {
            $Param{$Argument} ||= [];

            next ARGUMENT;
        }

        if ( ref $Param{$Argument} ne 'ARRAY' ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "$Argument must be an array reference!",
            );
            return;
        }
    }

    # set default order and order direction
    if ( !@{ $Param{OrderBy} } ) {
        $Param{OrderBy} = ['MELTObjectID'];
    }
    if ( !@{ $Param{OrderByDirection} } ) {
        $Param{OrderByDirection} = ['Up'];
    }

    # define order table
    my %OrderByTable = (
        MELTObjectID => 'vr.melt_object_id',
        Name         => 'vr.name',
        Number       => 'ci.meltid',
        ClassID      => 'ci.class_id',
        ZTSMStatusID  => 'vr.ztsm_status_id',
        ZTSMStatusID  => 'vr.ztsm_status_id',
        CreateTime   => 'ci.create_time',
        CreateBy     => 'ci.create_by',

        # the change time of the CI is the same as the create time of the version!
        ChangeTime => 'vr.create_time',

        ChangeBy => 'ci.change_by',
    );

    # check if OrderBy contains only unique valid values
    my %OrderBySeen;
    for my $OrderBy ( @{ $Param{OrderBy} } ) {

        if ( !$OrderBy || !$OrderByTable{$OrderBy} || $OrderBySeen{$OrderBy} ) {

            # found an error
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "OrderBy contains invalid value '$OrderBy' "
                    . 'or the value is used more than once!',
            );
            return;
        }

        # remember the value to check if it appears more than once
        $OrderBySeen{$OrderBy} = 1;
    }

    # check if OrderByDirection array contains only 'Up' or 'Down'
    DIRECTION:
    for my $Direction ( @{ $Param{OrderByDirection} } ) {

        # only 'Up' or 'Down' allowed
        next DIRECTION if $Direction eq 'Up';
        next DIRECTION if $Direction eq 'Down';

        # found an error
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "OrderByDirection can only contain 'Up' or 'Down'!",
        );
        return;
    }

    # assemble the ORDER BY clause
    my @SQLOrderBy;
    my $Count = 0;
    my @OrderBySelectColumns;
    for my $OrderBy ( @{ $Param{OrderBy} } ) {

        # set the default order direction
        my $Direction = 'DESC';

        # add the given order direction
        if ( $Param{OrderByDirection}->[$Count] ) {
            if ( $Param{OrderByDirection}->[$Count] eq 'Up' ) {
                $Direction = 'ASC';
            }
            elsif ( $Param{OrderByDirection}->[$Count] eq 'Down' ) {
                $Direction = 'DESC';
            }
        }

        # add SQL
        push @SQLOrderBy,           "$OrderByTable{$OrderBy} $Direction";
        push @OrderBySelectColumns, $OrderByTable{$OrderBy};

    }
    continue {
        $Count++;
    }

    # get like escape string needed for some databases (e.g. oracle)
    my $LikeEscapeString = $Kernel::OM->Get('Kernel::System::DB')->GetDatabaseFunction('LikeEscapeString');

    # add name to sql where array
    my @SQLWhere;
    if ( defined $Param{Name} && $Param{Name} ne '' ) {

        # duplicate the name
        my $Name = $Param{Name};

        # quote
        $Name = $Kernel::OM->Get('Kernel::System::DB')->Quote($Name);

        if ( $Param{UsingWildcards} ) {

            # prepare like string
            $Self->_PrepareLikeString( \$Name );

            push @SQLWhere, "LOWER(vr.name) LIKE LOWER('$Name') $LikeEscapeString";
        }
        else {
            push @SQLWhere, "LOWER(vr.name) = LOWER('$Name')";
        }
    }

    # set array params
    my %ArrayParams = (
        ClassIDs     => 'ci.id = vr.melt_object_id AND ci.class_id',
        ZTSMStatusIDs => 'vr.ztsm_status_id',
        ZTSMStatusIDs => 'vr.ztsm_status_id',
    );

    ARRAYPARAM:
    for my $ArrayParam ( sort keys %ArrayParams ) {

        next ARRAYPARAM if !$Param{$ArrayParam};

        if ( ref $Param{$ArrayParam} ne 'ARRAY' ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "$ArrayParam must be an array reference!",
            );
            return;
        }

        next ARRAYPARAM if !@{ $Param{$ArrayParam} };

        # quote as integer
        for my $OneParam ( @{ $Param{$ArrayParam} } ) {
            $OneParam = $Kernel::OM->Get('Kernel::System::DB')->Quote( $OneParam, 'Integer' );
        }

        # create string
        my $InString = join q{, }, @{ $Param{$ArrayParam} };

        push @SQLWhere, "$ArrayParams{ $ArrayParam } IN ($InString)";
    }

    # add previous version param
    if ( !$Param{PreviousVersionSearch} ) {
        push @SQLWhere, 'ci.last_version_id = vr.id';
    }

    # create where string
    my $WhereString = @SQLWhere ? ' WHERE ' . join q{ AND }, @SQLWhere : '';

    # set limit, quote as integer
    if ( $Param{Limit} ) {
        $Param{Limit} = $Kernel::OM->Get('Kernel::System::DB')->Quote( $Param{Limit}, 'Integer' );
    }

    # add the order by columns also to the selected columns
    my $OrderBySelectString = '';
    if (@OrderBySelectColumns) {
        $OrderBySelectString = join ', ', @OrderBySelectColumns;
        $OrderBySelectString = ', ' . $OrderBySelectString;
    }

    # build SQL
    my $SQL = "SELECT DISTINCT vr.melt_object_id $OrderBySelectString "
        . 'FROM melt_object_item ci, melt_object_item_version vr '
        . $WhereString;

    # add the ORDER BY clause
    if (@SQLOrderBy) {
        $SQL .= ' ORDER BY ';
        $SQL .= join ', ', @SQLOrderBy;
        $SQL .= ' ';
    }

    # ask the database
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => $SQL,
        Limit => $Param{Limit},
    );

    # fetch the result
    my @MELTObjectList;
    while ( my ($Id) = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        push @MELTObjectList, $Id;
    }

    return \@MELTObjectList;
}

=head2 VersionAttachmentAdd()

adds an attachment to a MELT Object

    my $Success = $MELTObjectObject->VersionAttachmentAdd(
        VersionID    => 1,
        Filename        => 'filename',
        Content         => 'content',
        ContentType     => 'text/plain',
        UserID          => 1,
    );

=cut

sub VersionAttachmentAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(VersionID Filename Content ContentType UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    # write to virtual fs
    my $Success = $Kernel::OM->Get('Kernel::System::VirtualFS')->Write(
        Filename    => "MELTObjectVersion/$Param{VersionID}/$Param{Filename}",
        Mode        => 'binary',
        Content     => \$Param{Content},
        Preferences => {
            ContentID   => $Param{ContentID},
            ContentType => $Param{ContentType},
            VersionID   => $Param{VersionID},
            UserID      => $Param{UserID},
        },
    );

    # check for error
    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Cannot add attachment for MELT Object version $Param{VersionID}",
        );

        return;
    }

    return 1;
}

=head2 VersionAttachmentDelete()

Delete the given file from the virtual filesystem.

    my $Success = $MELTObjectObject->VersionAttachmentDelete(
        VersionID => 123,               # used in event handling, e.g. for logging the history
        Filename     => 'Projectplan.pdf', # identifies the attachment (together with the VersionID)
        UserID       => 1,
    );

=cut

sub VersionAttachmentDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(VersionID Filename UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    # add prefix
    my $Filename = 'MELTObjectVersion/' . $Param{VersionID} . '/' . $Param{Filename};

    # delete file
    my $Success = $Kernel::OM->Get('Kernel::System::VirtualFS')->Delete(
        Filename => $Filename,
    );

    # check for error
    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Cannot delete attachment $Filename!",
        );

        return;
    }

    return $Success;
}

=head2 VersionAttachmentGet()

This method returns information about one specific attachment.

    my $Attachment = $MELTObjectObject->VersionAttachmentGet(
        VersionID => 4,
        Filename     => 'test.txt',
    );

returns

    {
        Preferences => {
            AllPreferences => 'test',
        },
        Filename    => 'test.txt',
        Content     => 'content',
        ContentType => 'text/plain',
        Filesize    => 12348409,
        Type        => 'attachment',
    }

=cut

sub VersionAttachmentGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(VersionID Filename)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # add prefix
    my $Filename = 'MELTObjectVersion/' . $Param{VersionID} . '/' . $Param{Filename};

    # find all attachments of this MELT Object
    my @Attachments = $Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Filename    => $Filename,
        Preferences => {
            VersionID => $Param{VersionID},
        },
    );

    # return error if file does not exist
    if ( !@Attachments ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Message  => "No such attachment ($Filename)!",
            Priority => 'error',
        );
        return;
    }

    # get data for attachment
    my %AttachmentData = $Kernel::OM->Get('Kernel::System::VirtualFS')->Read(
        Filename => $Filename,
        Mode     => 'binary',
    );

    my $AttachmentInfo = {
        %AttachmentData,
        Filename    => $Param{Filename},
        Content     => ${ $AttachmentData{Content} },
        ContentType => $AttachmentData{Preferences}->{ContentType},
        Type        => 'attachment',
        Filesize    => $AttachmentData{Preferences}->{FilesizeRaw},
    };

    return $AttachmentInfo;
}

=head2 VersionAttachmentList()

Returns an array with all attachments of the given MELT Object.

    my @Attachments = $MELTObjectObject->VersionAttachmentList(
        VersionID => 123,
    );

returns

    @Attachments = (
        'filename.txt',
        'other_file.pdf',
    );

=cut

sub VersionAttachmentList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{VersionID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need VersionID!',
        );

        return;
    }

    # find all attachments of this MELT Object
    my @Attachments = $Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Preferences => {
            VersionID => $Param{VersionID},
        },
    );

    for my $Filename (@Attachments) {

        # remove extra information from filename
        $Filename =~ s{ \A MELTObjectVersion / \d+ / }{}xms;
    }

    return @Attachments;
}

=head2 VersionAttachmentExists()

Checks if a file with a given filename exists.

    my $Exists = $MELTObjectObject->VersionAttachmentExists(
        Filename  => 'test.txt',
        VersionID => 123,
        UserID    => 1,
    );

=cut

sub VersionAttachmentExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Filename VersionID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    return if !$Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Filename => 'MELTObjectVersion/' . $Param{VersionID} . '/' . $Param{Filename},
    );

    return 1;
}

sub _UpdateCurAttr {
    my ( $Self, %Param ) = @_;

    my $ZTSMStatusID;
    my $RecalcZTSMStatus = 0;

    # if the last version does not yet have a ZTSMStatusID yet the MELT Object is new
    # set current ZTSMStatusID; recalculation is not necessary (no links can exist yet)
    if ( !defined $Param{LastVersion}{ZTSMStatusID} ) {
        $ZTSMStatusID = $Param{Version}{ZTSMStatusID};
    }

    # if the MELT Object update does not change the ZTSMStatusID
    # we just keep the ZTSMStatusID; no recalculation
    elsif ( $Param{Version}{ZTSMStatusID} eq $Param{LastVersion}{ZTSMStatusID} ) {
        $ZTSMStatusID = $Param{LastVersion}{ZTSMStatusID};
    }

    # if the ZTSM Status changes, we start the recalculation
    # we do not test for cases like same ZTSMStatusType, or new ZTSMStatus eq last ZTSMStatus
    else {
        $ZTSMStatusID     = $Param{Version}{ZTSMStatusID};
        $RecalcZTSMStatus = 1;
    }

    # Update last version and ZTSM status of the MELT Object.
    # ztsm_status_id is needed by ZTSMStatusRecalc().
    my $UpdateSuccess = $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => <<'END_SQL',
UPDATE melt_object_item
  SET
    last_version_id   = ?,
    ztsm_status_id = ?,
    change_time       = current_timestamp,
    change_by         = ?
  WHERE id = ?
END_SQL
        Bind => [
            \$Param{VersionID},
            \$ZTSMStatusID,
            \$Param{UserID},
            \$Param{Version}{MELTObjectID},
        ],
    );

    if ( !$UpdateSuccess ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Could not update current attributes of MELTObjectID $Param{Version}{MELTObjectID}!",
        );
    }

    return $RecalcZTSMStatus;
}

1;

