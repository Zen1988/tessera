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

package Kernel::System::MELTObject;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use parent qw(
    Kernel::System::EventHandler
    Kernel::System::MELTObject::MELTObjectACL
    Kernel::System::MELTObject::MELTObjectSearch
    Kernel::System::MELTObject::Definition
    Kernel::System::MELTObject::History
    Kernel::System::MELTObject::Link
    Kernel::System::MELTObject::Number
    Kernel::System::MELTObject::Permission
    Kernel::System::MELTObject::Version
);

# core modules
use Storable       qw(dclone);
use List::AllUtils qw(first true);

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Cache',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::LinkObject',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Service',
    'Kernel::System::User',
    'Kernel::System::VirtualFS',
    'Kernel::System::XML',
);

=head1 NAME

Kernel::System::MELT Object - library for MELT objects.

=head1 DESCRIPTION

All MELTObject functions. Note that additional parent modules are loaded
which effectively add more methods.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    use Kernel::System::ObjectManager;

    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

=cut

sub new {
    my ($Type) = @_;

    # allocate new hash for object
    my $Self = bless {}, $Type;

    $Self->{CacheType} = 'MELT';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    # init of event handler
    $Self->EventHandlerInit(
        Config => 'MELTObject::EventModulePost',
    );

    return $Self;
}

=head2 MELTObjectCount()

count all productive MELT Objects of a MELT Object class

    my $Count = $MELTObjectObject->MELTObjectCount(
        ClassID => 123,
    );

=cut

sub MELTObjectCount {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ClassID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ClassID!',
        );

        return;
    }

    # get list of productive ZTSM Statuss
    my $StateList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class       => 'ZTSM::MELT::Status',
        Preferences => {
            Functionality => [ 'preproductive', 'productive' ],
        },
    );

    return 0 if !%{$StateList};

    # create state string
    my $ZTSMStatusString = join q{, }, keys %{$StateList};

    # ask database
    my ($Count) = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
        SQL => "SELECT COUNT(id) FROM melt_object_item WHERE class_id = ? AND "
            . "ztsm_status_id IN ( $ZTSMStatusString )",
        Bind  => [ \$Param{ClassID} ],
        Limit => 1,
    );

    return $Count;
}

=head2 MELTObjectResultList()

return a MELT Object list as array hash reference

    my $MELTObjectListRef = $MELTObjectObject->MELTObjectResultList(
        ClassID => 123,
        Start   => 100,
        Limit   => 50,
    );

=cut

sub MELTObjectResultList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ClassID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ClassID!',
        );
        return;
    }

    # get state list
    my $StateList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class       => 'ZTSM::MELT::Status',
        Preferences => {
            Functionality => [ 'preproductive', 'productive' ],
        },
    );

    # create state string
    my $ZTSMStatusString = join q{, }, keys %{$StateList};

    # ask database
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => "SELECT id FROM melt_object_item "
            . "WHERE class_id = ? AND ztsm_status_id IN ( $ZTSMStatusString ) "
            . "ORDER BY change_time DESC",
        Bind  => [ \$Param{ClassID} ],
        Start => $Param{Start},
        Limit => $Param{Limit},
    );

    # fetch the result
    my @MELTObjectIDList;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        push @MELTObjectIDList, $Row[0];
    }

    # get last versions data
    my @MELTObjectList;
    for my $MELTObjectID (@MELTObjectIDList) {

        # get version data
        my $MELTObject = $Self->MELTObjectGet(
            MELTObjectID  => $MELTObjectID,
            DynamicFields => 0,
        );

        push @MELTObjectList, $MELTObject;
    }

    return \@MELTObjectList;
}

=head2 MELTObjectGet()

return a MELT Object as a hash reference. The latest version is retrieved when C<MELTObjectID> is passed as parameter.

    my $MELTObject = $MELTObjectObject->MELTObjectGet(
        MELTObjectID  => 123,
        DynamicFields => 1,    # (optional) default 0 (0|1)
    );

A specific version is returned when the C<VersionID> is passed.

    my $MELTObject = $MELTObjectObject->MELTObjectGet(
        VersionID     => 243,
        DynamicFields => 1,    # (optional) default 0 (0|1)
    );

When both C<MELTObjectID> and C<VersionID> are passed, then a consistency check is performed
and the data for the specific version is returned.

Error messages are suppressed if the parameter C<Silent> is passed.

    my $MELTObject = $MELTObjectObject->MELTObjectGet(
        VersionID     => 243,
        DynamicFields => 1,    # (optional) default 0 (0|1)
        Silent        => 1,    # (optional) default 0 (0|1)
    );

A hashref with the following keys is returned:

=over 4

=item MELTObjectID

=item Number

=item ClassID

=item Class

=item LastVersionID

=item ZTSMStatusID

=item ZTSMStatus

=item ZTSMStatusType

=item ZTSMStatusID

=item ZTSMStatus

=item ZTSMStatusType

=item VersionID

=item Name

=item VersionString

=item Description

=item DefinitionID

=item ZTSMStatusID

=item ZTSMStatus

=item ZTSMStatusType

=item ZTSMStatusID

=item ZTSMStatus

=item ZTSMStatusType

=item CreateTime

=item CreateBy

=item ChangeTime

=item ChangeBy

=back

Caching can't be turned off.

When the parameter C<DynamicFields> is passed then the dynamic fields are returned additionally.

=cut

sub MELTObjectGet {
    my ( $Self, %Param ) = @_;

    # whether to suppress error messages
    my $Silent = $Param{Silent} ? 1 : 0;

    # check needed stuff
    if ( !$Param{MELTObjectID} && !$Param{VersionID} ) {
        if ( !$Silent ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Need MELTObjectID or VersionID!',
            );
        }

        return;
    }

    # ignore DynamicFields per default,
    # make sure that the variable is either 0 or 1, as it is used for the cache key
    my $DFData = $Param{DynamicFields} ? 1 : 0;

    # check if result is already cached, considering the DynamicFields parameter
    my $CacheKey = $Param{VersionID}
        ?
        join(
            '::', 'MELTObjectGet',
            VersionID => $Param{VersionID},
            DFData    => $DFData
        )
        :
        join(
            '::', 'MELTObjectGet',
            MELTObjectID => $Param{MELTObjectID},
            DFData       => $DFData
        );

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $Cache       = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    if ($Cache) {
        if ( $Param{VersionID} && $Param{MELTObjectID} && $Param{MELTObjectID} ne $Cache->{MELTObjectID} ) {
            if ( !$Silent ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "VersionID $Param{VersionID} is not a version of MELTObjectID $Param{MELTObjectID}!",
                );
            }

            return;
        }

        return dclone($Cache) if $Cache;
    }

    # get specific MELTObjectVersion
    # The parameter VersionID takes precedence over MELTObjectID
    my @Row;
    if ( $Param{VersionID} ) {

        @Row = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
            SQL => <<'END_SQL',
SELECT ci.id, ci.meltid, ci.class_id, ci.last_version_id,
    ci.ztsm_status_id, ci.ztsm_status_id,
    v.id, v.name, v.version_string, v.definition_id, v.ztsm_status_id, v.ztsm_status_id, v.description,
    v.create_time, v.create_by, v.change_time, v.change_by
  FROM melt_object_item_version v
  INNER JOIN melt_object_item ci
    ON v.melt_object_id = ci.id
  WHERE v.id = ?
END_SQL
            Bind  => [ \$Param{VersionID} ],
            Limit => 1,
        );
    }

    # get latest MELTObjectVersion
    else {

        @Row = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
            SQL => <<'END_SQL',
SELECT ci.id, ci.meltid, ci.class_id, ci.last_version_id,
    ci.ztsm_status_id, ci.ztsm_status_id,
    v.id, v.name, v.version_string, v.definition_id, v.ztsm_status_id, v.ztsm_status_id, v.description,
    ci.create_time, ci.create_by, ci.change_time, ci.change_by
  FROM melt_object_item ci
  LEFT JOIN melt_object_item_version v
    ON ci.last_version_id = v.id
  WHERE ci.id = ?
END_SQL
            Bind  => [ \$Param{MELTObjectID} ],
            Limit => 1,
        );
    }

    # fetch the result
    my %MELTObject;
    $MELTObject{MELTObjectID}   = $Row[0];
    $MELTObject{Number}         = $Row[1];
    $MELTObject{ClassID}        = $Row[2];
    $MELTObject{LastVersionID}  = $Row[3];
    $MELTObject{ZTSMStatusID} = $Row[4];
    $MELTObject{ZTSMStatusID} = $Row[5];
    $MELTObject{VersionID}      = $Row[6];
    $MELTObject{Name}           = $Row[7];
    $MELTObject{VersionString}  = $Row[8];
    $MELTObject{DefinitionID}   = $Row[9];
    $MELTObject{ZTSMStatusID}    = $Row[10];
    $MELTObject{ZTSMStatusID}    = $Row[11];
    $MELTObject{Description}    = $Row[12];
    $MELTObject{CreateTime}     = $Row[13];
    $MELTObject{CreateBy}       = $Row[14];
    $MELTObject{ChangeTime}     = $Row[15];
    $MELTObject{ChangeBy}       = $Row[16];

    # check MELT Object
    if ( !$MELTObject{MELTObjectID} ) {
        if ( !$Silent ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No such MELTObjectID ($Param{MELTObjectID})!",
            );
        }

        return;
    }
    if ( $Param{VersionID} && $Param{MELTObjectID} && $Param{MELTObjectID} ne $MELTObject{MELTObjectID} ) {
        if ( !$Silent ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "VersionID $Param{VersionID} is not a version of MELTObjectID $Param{MELTObjectID}!",
            );
        }

        return;
    }

    # check if need to return DynamicFields
    if ( $DFData && $MELTObject{DefinitionID} ) {

        # get dynamic field objects
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        my $Definition = $Self->DefinitionGet(
            DefinitionID => $MELTObject{DefinitionID},
        );

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Definition->{DynamicFieldRef}->%* ) {

            # validate each dynamic field
            next DYNAMICFIELD unless $DynamicFieldConfig;
            next DYNAMICFIELD unless IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD unless $DynamicFieldConfig->{Name};

            # get the current value for each dynamic field
            my $Value = $DynamicFieldBackendObject->ValueGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $MELTObject{VersionID},
            );

            # set the dynamic field name and value into the ticket hash
            $MELTObject{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $Value;
        }
    }

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # add the Class, based on the ClassID
    {
        my $ClassList = $GeneralCatalogObject->ItemList(
            Class => 'ZTSM::MELT::Class',
        );

        $MELTObject{Class} = $ClassList->{ $MELTObject{ClassID} };
    }

    # Add more readable names for the various states.
    # Add the state types.
    STATE:
    for my $State (qw/ZTSMStatus ZTSMStatus ZTSMStatus ZTSMStatus/) {
        next STATE unless $MELTObject{ $State . 'ID' };

        my $Item = $GeneralCatalogObject->ItemGet(
            ItemID => $MELTObject{ $State . 'ID' },
        );

        $MELTObject{$State} = $Item->{Name};
        $MELTObject{ $State . 'Type' } = $Item->{Functionality}[0] // '';
    }

    # cache the result
    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => dclone( \%MELTObject ),
    );

    return \%MELTObject;
}

=head2 MELTObjectAdd()

add a new MELT Object. This implies that an initial version is created as well.

    my $MELTObjectID = $MELTObjectObject->MELTObjectAdd(
        ClassID        => 123,
        Name           => 'Name',    # optional when a name module is configured for the class
        VersionString  => 'Version', # optional when a version number module is configured for the class
        ZTSMStatusID    => 3,
        ZTSMStatusID    => 2,
        Description    => 'ABCD',
        UserID         => 1,
        Number         => '111',    # optional, a number will generated when no number is passed
        DynamicField_X => $Value,   # optional
    );

No MELT Object will be created when an already existing Number is passed.

=cut

sub MELTObjectAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ClassID UserID ZTSMStatusID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # get class list
    my $ClassList = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::MELT::Class',
    );

    return unless $ClassList;
    return unless ref $ClassList eq 'HASH';

    # check the class id
    if ( !$ClassList->{ $Param{ClassID} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'No valid class id given!',
        );

        return;
    }

    # get ZTSM Status list
    my $ZTSMStatusList = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::MELT::Status',
    );

    return unless $ZTSMStatusList;
    return unless ref $ZTSMStatusList eq 'HASH';

    # check the ZTSM Status id
    if ( !$ZTSMStatusList->{ $Param{ZTSMStatusID} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'No valid ZTSM Status id given!',
        );

        return;
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my %ClassPreferences = $GeneralCatalogObject->GeneralCatalogPreferencesGet(
        ItemID => $Param{ClassID},
    );

    # create MELT Object number
    if ( $Param{Number} ) {

        # find existing MELT Object number
        my $Exists = $Self->MELTIDLookup(
            MELTID => $Param{Number},
        );

        if ($Exists) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'MELT Object number already exists!',
            );

            return;
        }
    }
    else {

        my $NumberModule = $ClassPreferences{NumberModule} ? $ClassPreferences{NumberModule}[0] : 'AutoIncrement';

        # create MELT Object number
        $Param{Number} = $Self->MELTIDCreate(
            Type    => "Kernel::System::MELTObject::Number::$NumberModule",
            ClassID => $Param{ClassID},
        );
    }

    my $NameModule = $ClassPreferences{NameModule} ? $ClassPreferences{NameModule}[0] : '';
    if ($NameModule) {

        # check if name module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::MELTObject::Name::$NameModule") ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load name module for class $ClassList->{ $Param{ClassID} }!",
            );

            return;
        }
    }
    else {

        # check, whether the feature to check for a unique name is enabled
        if ( $ConfigObject->Get('UniqueCIName::EnableUniquenessCheck') ) {

            my $NameDuplicates = $Self->UniqueNameCheck(
                MELTObjectID => 'NEW',
                ClassID      => $Param{ClassID},
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

    # check needed stuff II
    if ( !$Param{Name} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Name!",
        );

        return;
    }

    # insert new MELT Object
    $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO melt_object_item ('
            . 'meltid, ztsm_status_id'
            . ', class_id, create_time, create_by, change_time, change_by'
            . ') VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [ \$Param{Number}, \$Param{ZTSMStatusID}, \$Param{ClassID}, \$Param{UserID}, \$Param{UserID} ],
    );

    # find id of new item
    # TODO: what about concurrent INSERTs ???
    my ($MELTObjectID) = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
        SQL => <<'END_SQL',
SELECT id
  FROM melt_object_item
  WHERE meltid = ?
    AND class_id = ?
  ORDER BY id DESC
END_SQL
        Bind => [ \$Param{Number}, \$Param{ClassID} ],
    );

    # trigger MELTObjectCreate
    $Self->EventHandler(
        Event => 'MELTObjectCreate',
        Data  => {
            MELTObjectID => $MELTObjectID,
            Comment      => $MELTObjectID . '%%' . $Param{Number},
        },
        UserID => $Param{UserID},
    );

    # add the first version
    my $VersionID = $Self->VersionAdd(
        Description => '',
        %Param,
        MELTObjectID => $MELTObjectID,
        LastVersion  => {
            MELTObjectID => 'NEW',
        },
    );

    if ( !$VersionID ) {

        # delete history entries
        $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'DELETE FROM melt_object_item_history WHERE melt_object_id = ?',
            Bind => [ \$MELTObjectID ],
        );

        # delete MELT Object if no version could be created
        $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'DELETE FROM melt_object_item WHERE id = ?',
            Bind => [ \$MELTObjectID ],
        );

        # write an error log message containing all the duplicate IDs
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Could not create version!",
        );

        return;
    }

    return $MELTObjectID;
}

=head2 MELTObjectDelete()

delete an existing MELT Object

    my $True = $MELTObjectObject->MELTObjectDelete(
        MELTObjectID => 123,
        UserID       => 1,
    );

=cut

sub MELTObjectDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(MELTObjectID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    # remember MELT Object data before delete
    my $MELTObjectData = $Self->MELTObjectGet(
        MELTObjectID => $Param{MELTObjectID},
    );

    # delete all links to this MELT Object before deleting the versions.
    # LinkDeleteAll() calls LinkDelete() internally. This means that
    # the event handlers are honored. This means that the table melt_object_item_link
    # is also purged.
    return unless $Kernel::OM->Get('Kernel::System::LinkObject')->LinkDeleteAll(
        Object => 'MELTObject',
        Key    => $Param{MELTObjectID},
        UserID => $Param{UserID},
    );

    # delete dynamic link table entries, if any

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Do(
        SQL  => 'DELETE FROM melt_object_item_link WHERE source_melt_object_id = ?',
        Bind => [ \$Param{MELTObjectID} ],
    );
    $DBObject->Do(
        SQL  => 'DELETE FROM melt_object_item_link WHERE target_melt_object_id = ?',
        Bind => [ \$Param{MELTObjectID} ],
    );

    # if there are static (versioned) links, delete all of them
    my $VersionListRef = $Self->VersionList(
        MELTObjectID => $Param{MELTObjectID},
    );

    for my $VersionID (@$VersionListRef) {
        $DBObject->Do(
            SQL  => 'DELETE FROM melt_object_item_link WHERE source_melt_object_item_version_id = ?',
            Bind => [ \$VersionID ],
        );
        $DBObject->Do(
            SQL  => 'DELETE FROM melt_object_item_link WHERE target_melt_object_item_version_id = ?',
            Bind => [ \$VersionID ],
        );
    }

    # delete existing versions
    $Self->VersionDelete(
        MELTObjectID => $Param{MELTObjectID},
        UserID       => $Param{UserID},
    );

    # get a list of all attachments
    my @ExistingAttachments = $Self->MELTObjectAttachmentList(
        MELTObjectID => $Param{MELTObjectID},
    );

    # delete all attachments of this MELT Object
    FILENAME:
    for my $Filename (@ExistingAttachments) {

        # delete the attachment
        my $DeletionSuccess = $Self->MELTObjectAttachmentDelete(
            MELTObjectID => $Param{MELTObjectID},
            Filename     => $Filename,
            UserID       => $Param{UserID},
        );

        if ( !$DeletionSuccess ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Unknown problem when deleting attachment $Filename of MELT Object "
                    . "$Param{MELTObjectID}. Please check the VirtualFS backend for stale "
                    . "files!",
            );
        }
    }

    my %ClassPreferences = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesGet(
        ItemID => $MELTObjectData->{ClassID},
    );
    my $NameModule = $ClassPreferences{NameModule} ? $ClassPreferences{NameModule}[0] : '';
    if ($NameModule) {

        # check if name module exists
        if ( $Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::MELTObject::Name::$NameModule") ) {

            # create a backend object
            my $NameModuleObject = $Kernel::OM->Get($NameModule);

            if ( $NameModuleObject->can('MELTObjectNameDelete') ) {
                $NameModuleObject->MELTObjectNameDelete(
                    Name => $MELTObjectData->{Name},
                );
            }
        }
        else {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load name module for class $MELTObjectData->{Class}!",
            );
        }
    }

    # trigger MELTObjectDelete event
    # this must be done before deleting the MELT Object from the database,
    # because of a foreign key constraint in the melt_object_item_history table
    $Self->EventHandler(
        Event => 'MELTObjectDelete',
        Data  => {
            MELTObjectID => $Param{MELTObjectID},
            Comment      => $Param{MELTObjectID},
            Number       => $MELTObjectData->{Number},
            Class        => $MELTObjectData->{Class},
        },
        UserID => $Param{UserID},
    );

    # delete MELT Object
    my $Success = $DBObject->Do(
        SQL  => 'DELETE FROM melt_object_item WHERE id = ?',
        Bind => [ \$Param{MELTObjectID} ],
    );

    # delete the cache
    for my $DFData ( 0, 1 ) {
        $Kernel::OM->Get('Kernel::System::Cache')->Delete(
            Type => $Self->{CacheType},
            Key  => join(
                'MELTObjectGet',
                MELTObjectID => $Param{MELTObjectID},
                DFData       => $DFData
            ),
        );
    }

    return $Success;
}

=head2 MELTObjectUpdate()

update a MELT Object. A new version will be created only when a version trigger applies.

    my $Success = $MELTObjectObject->MELTObjectUpdate(
        MELTObjectID   => 27,
        Number         => '111',    # ID or Number is required
        UserID         => 1,
        Name           => 'Name',   # optional
        DefinitionID   => 123,      # optional
        ZTSMStatusID    => 3,        # optional
        ZTSMStatusID    => 2,        # optional
        Description    => 'ABCD',   # optional
        DynamicField_X => $Value,   # optional
    );

=cut

sub MELTObjectUpdate {
    my ( $Self, %Param ) = @_;

    # lookup
    $Param{MELTObjectID} //= $Self->MELTObjectLookup(
        MELTID => $Param{Number},
    );

    # check needed parameters
    for my $Key (qw/MELTObjectID UserID/) {
        if ( !$Param{$Key} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need " . ( $Key eq 'MELTObjectID' ? 'MELTObjectID or Number' : $Key ),
            );

            return;
        }
    }

    # gather dynamic field keys
    my @DynamicFieldNames = map
        {m/^DynamicField_(.+)/}
        sort keys %Param;

    # get current MELT Object, including info from the last version
    my $MELTObject = $Self->MELTObjectGet(
        MELTObjectID  => $Param{MELTObjectID},
        DynamicFields => 1,
    );

    my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::MELT::Class',
    );
    my $Class = $ClassList->{ $MELTObject->{ClassID} };

    if ( !$Class ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No valid class found for id '$MELTObject->{ClassID}' (MELTObject#$MELTObject->{Number})!",
        );

        return;
    }

    # ignore the passed in name when a name module is active
    my %ClassPreferences = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesGet(
        ItemID => $MELTObject->{ClassID},
    );

    # execute name check only if name has changed
    my $NameModule = $ClassPreferences{NameModule} ? $ClassPreferences{NameModule}[0] : '';
    if ($NameModule) {

        # check if name module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($NameModule) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load name module for class $ClassList->{ $Param{ClassID} }!",
            );

            return;
        }

        delete $Param{Name};
    }
    elsif ( $Param{Name} && $Param{Name} ne $MELTObject->{Name} ) {

        # check, whether the feature to check for a unique name is enabled
        if ( $Kernel::OM->Get('Kernel::Config')->Get('UniqueCIName::EnableUniquenessCheck') ) {

            my $NameDuplicates = $Self->UniqueNameCheck(
                MELTObjectID => $Param{MELTObjectID},
                ClassID      => $Param{ClassID},
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

    my %VersionTrigger = map
        { $_ => 1 }
        ( $ClassPreferences{VersionTrigger} // [] )->@*;

    my %Changed;              # track changed values for the Event handler, e.g. for writing history
    my $AddVersion    = 0;    # flag for deciding whether a new version is created
    my $UpdateVersion = 0;    # flag for deciding whether the current version needs an update

    # check name, deployment and ZTSM Status, as well as Description
    ATTR:
    for my $Attribute (qw/Name ZTSMStatusID Description/) {
        next ATTR unless defined $Param{$Attribute};
        next ATTR if $Param{$Attribute} eq $MELTObject->{$Attribute};

        $Changed{$Attribute} = {
            Old => $MELTObject->{$Attribute},
            New => $Param{$Attribute},
        };

        $UpdateVersion = 1;

        if ( $VersionTrigger{$Attribute} ) {
            $AddVersion = 1;
        }
    }

    # get latest definition for the class
    my $Definition = $Self->DefinitionGet(
        ClassID => $MELTObject->{ClassID},
    );

    my %SkipForUpdateDFs;

    # check for changed dynamic fields to trigger versions and filter history entries
    if (@DynamicFieldNames) {
        my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        # dynamic fields
        NAME:
        for my $Name (@DynamicFieldNames) {
            next NAME unless $Definition->{DynamicFieldRef}{$Name};

            my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
                Name => $Name,
            );

            if (
                !$DynamicFieldBackendObject->ValueIsDifferent(
                    DynamicFieldConfig => $DynamicField,
                    Value1             => $Param{"DynamicField_$Name"},
                    Value2             => $MELTObject->{"DynamicField_$Name"},
                    ExternalSource     => $Param{ExternalSource},
                )
                )
            {
                # do not pass unchanged dynamic fields to VersionUpdate()
                # store them for VersionAdd() because of potential difference from ExternalSource
                $SkipForUpdateDFs{"DynamicField_$Name"} = delete $Param{"DynamicField_$Name"};

                next NAME;
            }

            $UpdateVersion = 1;

            if ( $VersionTrigger{"DynamicField_$Name"} ) {
                $AddVersion = 1;
            }
        }
    }

    if ($AddVersion) {
        my $Success = $Self->VersionAdd(
            Description => $MELTObject->{Description} // '',
            %Param,
            %SkipForUpdateDFs,
            LastVersion => $MELTObject,
        );
        return unless $Success;
    }
    elsif ($UpdateVersion) {
        my $Success = $Self->VersionUpdate(
            %Param,
            Version => $MELTObject,
        );
        return unless $Success;
    }

    my %Events = (
        Name        => 'NameUpdate',
        ZTSMStatusID => 'DeploymentStateUpdate',
        ZTSMStatusID => 'IncidentStateUpdate',
    );

    CHANGE:
    for my $Key ( keys %Changed ) {
        next CHANGE if !$Events{$Key};

        $Self->EventHandler(
            Event => $Events{$Key},
            Data  => {
                MELTObjectID => $MELTObject->{MELTObjectID},
                Comment      => $Changed{$Key}{New} . '%%' . $Changed{$Key}{Old},
            },
            UserID => $Param{UserID},
        );
    }

    # trigger MELTObjectUpdate but only if there were updates
    if ( $AddVersion || $UpdateVersion || %Changed ) {
        $Self->EventHandler(
            Event => 'MELTObjectUpdate',
            Data  => {
                MELTObjectID => $MELTObject->{MELTObjectID},
                Comment      => $MELTObject->{MELTObjectID} . '%%' . $MELTObject->{Number},
                OldZTSMStatus => $Changed{ZTSMStatusID}{Old},
            },
            UserID => $Param{UserID},
        );
    }

    return 1;
}

=head2 MELTObjectAttachmentAdd()

adds an attachment to a MELT Object

    my $Success = $MELTObjectObject->MELTObjectAttachmentAdd(
        MELTObjectID    => 1,
        Filename        => 'filename',
        Content         => 'content',
        ContentType     => 'text/plain',
        UserID          => 1,
    );

=cut

sub MELTObjectAttachmentAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(MELTObjectID Filename Content ContentType UserID)) {
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
        Filename    => "MELTObject/$Param{MELTObjectID}/$Param{Filename}",
        Mode        => 'binary',
        Content     => \$Param{Content},
        Preferences => {
            ContentID    => $Param{ContentID},
            ContentType  => $Param{ContentType},
            MELTObjectID => $Param{MELTObjectID},
            UserID       => $Param{UserID},
        },
    );

    # check for error
    if ($Success) {

        # trigger AttachmentAdd-Event
        $Self->EventHandler(
            Event => 'AttachmentAddPost',
            Data  => {
                %Param,
                MELTObjectID => $Param{MELTObjectID},
                Comment      => $Param{Filename},
                HistoryType  => 'AttachmentAdd',
            },
            UserID => $Param{UserID},
        );
    }
    else {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Cannot add attachment for MELT Object $Param{MELTObjectID}",
        );

        return;
    }

    return 1;
}

=head2 MELTObjectAttachmentDelete()

Delete the given file from the virtual filesystem.

    my $Success = $MELTObjectObject->MELTObjectAttachmentDelete(
        MELTObjectID => 123,               # used in event handling, e.g. for logging the history
        Filename     => 'Projectplan.pdf', # identifies the attachment (together with the MELTObjectID)
        UserID       => 1,
    );

=cut

sub MELTObjectAttachmentDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(MELTObjectID Filename UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    # add prefix
    my $Filename = 'MELTObject/' . $Param{MELTObjectID} . '/' . $Param{Filename};

    # delete file
    my $Success = $Kernel::OM->Get('Kernel::System::VirtualFS')->Delete(
        Filename => $Filename,
    );

    # check for error
    if ($Success) {

        # trigger AttachmentDeletePost-Event
        $Self->EventHandler(
            Event => 'AttachmentDeletePost',
            Data  => {
                %Param,
                MELTObjectID => $Param{MELTObjectID},
                Comment      => $Param{Filename},
                HistoryType  => 'AttachmentDelete',
            },
            UserID => $Param{UserID},
        );
    }
    else {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Cannot delete attachment $Filename!",
        );

        return;
    }

    return $Success;
}

=head2 MELTObjectAttachmentGet()

This method returns information about one specific attachment.

    my $Attachment = $MELTObjectObject->MELTObjectAttachmentGet(
        MELTObjectID => 4,
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

sub MELTObjectAttachmentGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(MELTObjectID Filename)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # add prefix
    my $Filename = 'MELTObject/' . $Param{MELTObjectID} . '/' . $Param{Filename};

    # find all attachments of this MELT Object
    my @Attachments = $Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Filename    => $Filename,
        Preferences => {
            MELTObjectID => $Param{MELTObjectID},
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
        ContentType => $AttachmentData{Preferences}{ContentType},
        Type        => 'attachment',
        Filesize    => $AttachmentData{Preferences}{FilesizeRaw},
    };

    return $AttachmentInfo;
}

=head2 MELTObjectAttachmentList()

Returns an array with all attachments of the given MELT Object.

    my @Attachments = $MELTObjectObject->MELTObjectAttachmentList(
        MELTObjectID => 123,
    );

returns

    @Attachments = (
        'filename.txt',
        'other_file.pdf',
    );

=cut

sub MELTObjectAttachmentList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{MELTObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need MELTObjectID!',
        );

        return;
    }

    # find all attachments of this MELT Object
    my @Attachments = $Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Preferences => {
            MELTObjectID => $Param{MELTObjectID},
        },
    );

    for my $Filename (@Attachments) {

        # remove extra information from filename
        $Filename =~ s{ \A MELT Object / \d+ / }{}xms;
    }

    return @Attachments;
}

=head2 MELTObjectAttachmentExists()

Checks if a file with a given filename exists.

    my $Exists = $MELTObjectObject->MELTObjectAttachmentExists(
        Filename => 'test.txt',
        MELTObjectID => 123,
        UserID   => 1,
    );

=cut

sub MELTObjectAttachmentExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Filename MELTObjectID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    return if !$Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Filename => 'MELTObject/' . $Param{MELTObjectID} . '/' . $Param{Filename},
    );

    return 1;
}

=head2 MELTObjectLookup()

This method does a lookup for a config-item. If a config-item id is given,
it returns the number of the config-item. If a config-item number is given,
the appropriate id is returned.

    my $Number = $MELTObjectObject->MELTObjectLookup(
        MELTObjectID => 1234,
    );

or

    my $ID = $MELTObjectObject->MELTObjectLookup(
        MELTID => 1000001,
    );

=cut

sub MELTObjectLookup {
    my ( $Self, %Param ) = @_;

    my ($Key) = first { $Param{$_} } qw(MELTObjectID MELTID);

    # check for needed stuff
    if ( !$Key ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need MELTObjectID or MELTID!',
        );

        return;
    }

    # if result is cached return that result
    return $Self->{Cache}{MELTObjectLookup}{$Key}{ $Param{$Key} }
        if $Self->{Cache}{MELTObjectLookup}{$Key}{ $Param{$Key} };

    # set the appropriate SQL statement
    my $SQL = $Key eq 'MELTID'
        ?
        'SELECT id                FROM melt_object_item WHERE meltid = ?'
        :
        'SELECT meltid FROM melt_object_item WHERE id = ?';

    # fetch the requested value
    return unless $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Param{$Key} ],
        Limit => 1,
    );

    my $Value;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Value = $Row[0];
    }

    $Self->{Cache}{MELTObjectLookup}{$Key}{ $Param{$Key} } = $Value;

    return $Value;
}

=head2 UniqueNameCheck()

This method checks all already existing MELT Objects, whether the given name does already exist
within the same MELT Object class or among all classes, depending on the SysConfig value of
UniqueCIName::UniquenessCheckScope (Class or Global).

This method requires 3 parameters: MELTObjectID, Name and Class
"MELTObjectID"  is the ID of the MELTObject, which is to be checked for uniqueness
"Name"          is the MELT Object name to be checked for uniqueness
"ClassID"       is the ID of the MELT Object's class

All parameters are mandatory.

    my $DuplicateNames = $MELTObjectObject->UniqueNameCheck(
        MELTObjectID => '73'
        Name         => 'PC#005',
        ClassID      => '32',
    );

The given name is not unique

    my $NameDuplicates = [ 5, 35, 48, ];    # IDs of MELTObjects with the same name

The given name is unique

    my $NameDuplicates = [];

=cut

sub UniqueNameCheck {
    my ( $Self, %Param ) = @_;

    # check for needed stuff
    for my $Needed (qw(MELTObjectID Name ClassID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Missing parameter $Needed!",
            );
            return;
        }
    }

    # check MELTObjectID param for valid format
    if (
        !IsInteger( $Param{MELTObjectID} )
        && ( IsStringWithData( $Param{MELTObjectID} ) && $Param{MELTObjectID} ne 'NEW' )
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "The MELTObjectID parameter needs to be an integer or 'NEW'",
        );
        return;
    }

    # check Name param for valid format
    if ( !IsStringWithData( $Param{Name} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "The Name parameter needs to be a string!",
        );
        return;
    }

    # check ClassID param for valid format
    if ( !IsInteger( $Param{ClassID} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "The ClassID parameter needs to be an integer",
        );
        return;
    }

    # get class list
    my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::MELT::Class',
    );

    # check class list for validity
    if ( !IsHashRefWithData($ClassList) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Unable to retrieve a valid class list!",
        );
        return;
    }

    # get the class name from the class list
    my $Class = $ClassList->{ $Param{ClassID} };

    # check class for validity
    if ( !IsStringWithData($Class) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Unable to determine a MELT Object class using the given ClassID!",
        );
        return;
    }
    elsif ( $Kernel::OM->Get('Kernel::Config')->{Debug} > 0 ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'debug',
            Message  => "Resolved ClassID $Param{ClassID} to class $Class",
        );
    }

    # get the uniqueness scope from SysConfig
    my $Scope = $Kernel::OM->Get('Kernel::Config')->Get('UniqueCIName::UniquenessCheckScope');

    # check scope for validity
    if ( !IsStringWithData($Scope) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "The configuration of UniqueCIName::UniquenessCheckScope is invalid!",
        );

        return;
    }

    if ( $Scope ne 'global' && $Scope ne 'class' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "UniqueCIName::UniquenessCheckScope is $Scope, but must be either "
                . "'global' or 'class'!",
        );

        return;
    }

    if ( $Kernel::OM->Get('Kernel::Config')->{Debug} > 0 ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'debug',
            Message  => "The scope for checking the uniqueness is $Scope",
        );
    }

    my %SearchCriteria;

    # add the MELT Object class to the search criteria if the uniqueness scope is not global
    if ( $Scope ne 'global' ) {
        $SearchCriteria{ClassIDs} = [ $Param{ClassID} ];
    }

    $SearchCriteria{Name} = $Param{Name};

    # search for a MELT Object matching the given name
    my @MELTObjectIDs = $Self->MELTObjectSearch(
        %SearchCriteria,
        Result => 'ARRAY'
    );

    # remove the provided MELTObjectID from the results, otherwise the duplicate check would fail
    # because the MELT Object itself is found as duplicate
    my @Duplicates = grep { $_ ne $Param{MELTObjectID} } @MELTObjectIDs;

    # if a MELT Object was found, the given name is not unique
    # if no MELT Object was found, the given name is unique

    # return the result of the MELT Object search for duplicates
    return \@Duplicates;
}

=head2 ZTSMStatusRecalc()

recalculates the current ZTSM Status of this MELT Object and of MELT Objects
that are linked to it. Only links between MELT Objects are considered here. Links to
or FROM melt_object_item versions are ignored.

The current ZTSM Status depends on the ZTSM Statuss that this MELT Object depends on.
A change of the ZTSM Status might have repercussions on the current ZTSM Status
of the MELT Objects that depend on this MELT Object.

It is a common use case that C<ZTSMStatusRecalc()> is called in a loop over a list of MELT Objects.
Examples are the console command C<Admin::ITSM::IncidentState::Recalculate> or when the linking
of the MELT Objects has changed. For optimizing that case there are the parameters
C<NewMELTObjectIncidentState> and C<ScannedMELTObjectIDs> which carry state between
invocations of this method. They provide caching and prevent infinite loops.

Changing the ZTSM Status of MELT Objects has repercussions on services. These effects
are handled in this method as well.

    my $Success = $MELTObjectObject->ZTSMStatusRecalc(
        MELTObjectID               => 123,
        NewMELTObjectIncidentState => $NewMELTObjectIncidentState,  # optional, ZTSM Statuss of already checked CIs
        ScannedMELTObjectIDs       => $ScannedMELTObjectIDs,        # optional, IDs and ZTSM Statuss of already checked CIs
    );

For asynchronous execution it is convenient to pass a list of MELT Objects to C<ZTSMStatusRecalc()>.

    my $Success = $MELTObjectObject->ZTSMStatusRecalc(
        MELTObjectIDs              => [ 123, 124, 125 ],
    );

In that case the loop is discontinued when an iteration reported a failure.

=cut

sub ZTSMStatusRecalc {
    my ( $Self, %Param ) = @_;

    # useful for async execution
    # all other parameters will be ignored
    if ( $Param{MELTObjectIDs} ) {

        # these hashes will be filled in the calls to ZTSMStatusRecalc
        my ( %NewMELTObjectIncidentState, %ScannedMELTObjectIDs );

        for my $MELTObjectID ( $Param{MELTObjectIDs}->@* ) {
            my $Success = $Self->ZTSMStatusRecalc(
                MELTObjectID               => $MELTObjectID,
                NewMELTObjectIncidentState => \%NewMELTObjectIncidentState,
                ScannedMELTObjectIDs       => \%ScannedMELTObjectIDs,
            );

            return unless $Success;
        }

        # all fine
        return 1;
    }

    # check needed stuff
    if ( !$Param{MELTObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need MELTObjectID!',
        );

        return;
    }
    if ( ref $Param{MELTObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'The parameter MELTObjectID must be a plain scalar!',
        );

        return;
    }

    # get incident link types and directions from config. E.g.
    # { DependsOn => 'Both', LocationOf => 'Source' }
    my $IncidentLinkTypeDirection = $Kernel::OM->Get('Kernel::Config')->Get('ITSM::Core::IncidentLinkTypeDirection');

    # $Param{NewMELTObjectIncidentState} holds the determined ZTSM Statuss of the considered MELT Objects.
    # It may contain contain content from previous calls of ZTSMStatusRecalc() so that unnecessary work
    # can be skipped.
    # New ZTSM Statuss are calculated from all incident link types.
    # The newly determined ZTSM Statuss are made available to the caller, so that the caller
    # can pass it to the next iteration.
    # Incorporate data from previous run(s) and remember known data.
    $Param{NewMELTObjectIncidentState} //= {};
    my $KnownNewMELTObjectIncidentState = dclone( $Param{NewMELTObjectIncidentState} );

    # Remember the scanned MELT Objects
    # Incorporate data from previous run(s) and remember known data.
    $Param{ScannedMELTObjectIDs} //= {};
    my $KnownScannedMELTObjectIDs = dclone( $Param{ScannedMELTObjectIDs} );

    # Find deeply connected MELT Objects with an ZTSM Status.
    # The direction in $IncidentLinkTypeDirection is ignored here because depended on items could change
    # the ZTSM Status of the current MELT Object. Or changes in
    # the current MELT Object could change downstream MELT Objects.
    $Self->_FindInciMELTObjects(
        MELTObjectID         => $Param{MELTObjectID},
        IncidentLinkTypes    => [ keys $IncidentLinkTypeDirection->%* ],
        ScannedMELTObjectIDs => $Param{ScannedMELTObjectIDs},
    );

    # to store the relation between services and linked CIs
    # The info will be used for updating the services.
    my %ServiceCIRelation;

    # calculate the new CI ZTSM Status for each configured linktype
    LINKTYPE:
    for my $LinkType ( sort keys $IncidentLinkTypeDirection->%* ) {

        # get the direction
        my $LinkDirection = $IncidentLinkTypeDirection->{$LinkType};

        # investigate all MELT Objects with a warning state
        MELTObjectID:
        for my $MELTObjectID ( sort keys %{ $Param{ScannedMELTObjectIDs} } ) {

            # Skip MELT Objects known from previous execution(s).
            if (
                IsStringWithData( $KnownScannedMELTObjectIDs->{$MELTObjectID}{Type} )
                &&
                $KnownScannedMELTObjectIDs->{$MELTObjectID}{Type} eq $Param{ScannedMELTObjectIDs}{$MELTObjectID}{Type}
                )
            {
                next MELTObjectID;
            }

            # investigate only MELT Objects with an ZTSM Status
            next MELTObjectID unless $Param{ScannedMELTObjectIDs}{$MELTObjectID}{Type} eq 'incident';

            # annotate linked MELT Objects with a warning
            $Self->_FindWarnMELTObjects(
                MELTObjectID         => $MELTObjectID,
                LinkType             => $LinkType,
                Direction            => $LinkDirection,
                NumberOfLinkTypes    => scalar keys $IncidentLinkTypeDirection->%*,
                ScannedMELTObjectIDs => $Param{ScannedMELTObjectIDs},
            );
        }

        MELTObjectID:
        for my $MELTObjectID ( sort keys %{ $Param{ScannedMELTObjectIDs} } ) {

            # Skip MELT Objects known from previous execution(s).
            if (
                IsStringWithData( $KnownScannedMELTObjectIDs->{$MELTObjectID}{Type} )
                &&
                $KnownScannedMELTObjectIDs->{$MELTObjectID}{Type} eq $Param{ScannedMELTObjectIDs}{$MELTObjectID}{Type}
                )
            {
                next MELTObjectID;
            }

            # extract ZTSM Status type
            my $ZTSMStatusType = $Param{ScannedMELTObjectIDs}{$MELTObjectID}{Type};

            # Find all linked services of this MELT Object.
            # These kind of links are not available from the table melt_object_item_link
            my %LinkedServiceIDs = $Kernel::OM->Get('Kernel::System::LinkObject')->LinkKeyList(
                Object1   => 'MELTObject',
                Key1      => $MELTObjectID,
                Object2   => 'Service',
                State     => 'Valid',
                Type      => $LinkType,
                Direction => $LinkDirection,
                UserID    => 1,
            );

            SERVICEID:
            for my $ServiceID ( sort keys %LinkedServiceIDs ) {

                # remember the CIs that are linked with this service
                $ServiceCIRelation{$ServiceID} //= [];
                push $ServiceCIRelation{$ServiceID}->@*, $MELTObjectID;
            }

            next MELTObjectID if $ZTSMStatusType eq 'incident';

            $Param{NewMELTObjectIncidentState}{$MELTObjectID} = $ZTSMStatusType;
        }
    }

    # get the ZTSM Status list of warnings
    my $WarnStateList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class       => 'ZTSM::MELT::Status',
        Preferences => {
            Functionality => 'warning',
        },
    );

    if ( !defined $WarnStateList ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "ZTSM::MELT::Status Warning cannot be invalid.",
        );
    }

    my %ReverseWarnStateList = reverse %{$WarnStateList};
    my @SortedWarnList       = sort keys %ReverseWarnStateList;
    my $WarningStateID       = $ReverseWarnStateList{Warning} || $ReverseWarnStateList{ $SortedWarnList[0] };
    my $CacheObject          = $Kernel::OM->Get('Kernel::System::Cache');

    # set the new current ZTSM Status for CIs
    MELTObjectID:
    for my $MELTObjectID ( sort keys $Param{NewMELTObjectIncidentState}->%* ) {

        # Skip MELT Objects known from previous execution(s).
        if (
            IsStringWithData( $KnownNewMELTObjectIncidentState->{$MELTObjectID} )
            && $KnownNewMELTObjectIncidentState->{$MELTObjectID} eq $Param{NewMELTObjectIncidentState}{$MELTObjectID}
            )
        {
            next MELTObjectID;
        }

        # get new ZTSM Status type (can only be 'operational' or 'warning')
        my $ZTSMStatusType = $Param{NewMELTObjectIncidentState}{$MELTObjectID};

        # get last version
        my $LastVersion = $Self->MELTObjectGet(
            MELTObjectID  => $MELTObjectID,
            DynamicFields => 0,
        );

        my $ZTSMStatusID;
        if ( $ZTSMStatusType eq 'warning' ) {

            # check the current ZTSM Status type is in 'incident'
            # then we do not want to change it to warning
            next MELTObjectID if $LastVersion->{ZTSMStatusType} eq 'incident';

            $ZTSMStatusID = $WarningStateID;
        }
        elsif ( $ZTSMStatusType eq 'operational' ) {
            $ZTSMStatusID = $LastVersion->{ZTSMStatusID};
        }

        # No update necessary if ZTSM Status id of version and MELT Object match.
        next MELTObjectID if $LastVersion->{ZTSMStatusID} eq $ZTSMStatusID;

        # update current ZTSM Status
        $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'UPDATE melt_object_item SET ztsm_status_id = ? WHERE id = ?',
            Bind => [ \$ZTSMStatusID, \$MELTObjectID ],
        );

        # TODO: Also the VersionID-caches have to be considered, they also contain ZTSMStatus
        # delete the cache
        for my $DFData ( 0, 1 ) {
            $CacheObject->Delete(
                Type => $Self->{CacheType},
                Key  => join(
                    '::', 'MELTObjectGet',
                    MELTObjectID => $MELTObjectID,
                    DFData       => $DFData
                ),
            );
        }
    }

    # set the current ZTSM Status type for each service (influenced by linked CIs)
    SERVICEID:
    for my $ServiceID ( sort keys %ServiceCIRelation ) {

        # set default ZTSM Status type
        my $ZTSMStatusTypeFromCIs = 'operational';

        # get the unique MELT Object ids which are directly linked to this service
        my %UniqueMELTObjectIDs = map { $_ => 1 } $ServiceCIRelation{$ServiceID}->@*;

        # investigate the current ZTSM Status of each MELT Object
        MELTObjectID:
        for my $MELTObjectID ( sort keys %UniqueMELTObjectIDs ) {

            # get MELT Object data
            my $MELTObjectData = $Self->MELTObjectGet(
                MELTObjectID => $MELTObjectID,
                Cache        => 0,
            );

            next MELTObjectID if $MELTObjectData->{ZTSMStatusType} ne 'productive';
            next MELTObjectID if $MELTObjectData->{ZTSMStatusType} eq 'operational';

            # check if service must be set to 'warning'
            if ( $MELTObjectData->{ZTSMStatusType} eq 'warning' ) {
                $ZTSMStatusTypeFromCIs = 'warning';

                next MELTObjectID;
            }

            # check if service must be set to 'incident'
            if ( $MELTObjectData->{ZTSMStatusType} eq 'incident' ) {
                $ZTSMStatusTypeFromCIs = 'incident';

                last MELTObjectID;
            }
        }

        # update the current ZTSM Status type from CIs of the service
        $Kernel::OM->Get('Kernel::System::Service')->ServicePreferencesSet(
            ServiceID => $ServiceID,
            Key       => 'ZTSMStatusTypeFromCIs',
            Value     => $ZTSMStatusTypeFromCIs,
            UserID    => 1,
        );
    }

    return 1;
}

=head2 ObjectAttributesGet()

returns the attributes a MELT Object can have on the system.

    my %Attributes = $TicketObject->ObjectAttributesGet(
        DynamicFields => (0|1),         # (optional) if dynamic field names are included, default 0
        Version       => (0|1),         # (optional) if version information is included, default 1
        EditMask      => (0|1),         # (optional) if edit mask attributes are returned instead of backend attributes, default 0
    );

=cut

sub ObjectAttributesGet {
    my ( $Self, %Param ) = @_;

    $Param{Version} //= 1;

    my %MELTObjectAttributes;

    if ( $Param{EditMask} ) {
        %MELTObjectAttributes = (
            ZTSMStatusID   => 1,
            ZTSMStatusID   => 1,
            Name          => 1,
            VersionString => 1,
        );
    }
    else {
        %MELTObjectAttributes = (
            MELTObjectID   => 1,
            Number         => 1,
            ClassID        => 1,
            Classes        => 1,
            ZTSMStatusID => 1,
            ZTSMStatuss  => 1,
            ZTSMStatusID => 1,
            ZTSMStatuss  => 1,
        );

        # if requested, set version attributes
        if ( $Param{Version} ) {
            %MELTObjectAttributes = (
                %MELTObjectAttributes,
                Name          => 1,
                VersionString => 1,
                ZTSMStatusID   => 1,
                ZTSMStatuss    => 1,
                ZTSMStatusID   => 1,
                ZTSMStatuss    => 1,
            );
        }
    }

    # check if dynamic fields need to be added
    if ( $Param{DynamicFields} ) {
        my $DynamicFields = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldList(
            Valid      => 1,
            ObjectType => 'MELTObject',
            ResultType => 'HASH',
        );

        for my $FieldName ( values $DynamicFields->%* ) {
            $MELTObjectAttributes{"DynamicField_$FieldName"} = 1;
        }
    }

    return %MELTObjectAttributes;
}

=head1 INTERNAL INTERFACE

=head2 _FindInciMELTObjects()

find connected MELT Objects with an ZTSM Status.

    $MELTObjectObject->_FindInciMELTObjects(
        MELTObjectID         => $MELTObjectID,
        IncidentLinkTypes    => [ keys $IncidentLinkTypeDirection->%* ],
        ScannedMELTObjectIDs => \%ScannedMELTObjectIDs,
    );

The scanned MELT Objects will be entered in the C<ScannedMELTObjectIDs> hashref. Each MELT Object will be scanned only once.
The attribute C<Type> will be either 'operational' or 'incident'.

The search for MELT Objects with incidents recurses into the graph of linked MELT Objects. The directly
linked items will always be checked. Recursion stops once an incident has been found.

This method only collects data, no current ZTSM Statuss will be altered.

=cut

sub _FindInciMELTObjects {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    return unless $Param{MELTObjectID};

    # ignore already scanned ids (infinite loop protection)
    return if defined $Param{ScannedMELTObjectIDs}{ $Param{MELTObjectID} };

    # set a default so the MELT Object won't be scanned again
    $Param{ScannedMELTObjectIDs}{ $Param{MELTObjectID} } = {};
    $Param{ScannedMELTObjectIDs}{ $Param{MELTObjectID} }->{Type} = 'operational';

    # add own MELT Object id to list of linked MELT Objects
    my @MELTObjectIDs = $Param{MELTObjectID};

    # find the directly linked MELT Objects
    {
        # Direction must ALWAYS be 'Both' here as we need to include
        # all linked CIs that could influence this one!
        my $LinkedMELTObjects = $Self->LinkedMELTObjects(
            MELTObjectID => $Param{MELTObjectID},
            Types        => $Param{IncidentLinkTypes},
            Direction    => 'Both',
            UserID       => 1,
        );

        # remember only the linked MELT Object ids, ignore the MELT Object versions
        push @MELTObjectIDs,
            grep {defined}
            map  { $_->{MELTObjectID} }
            $LinkedMELTObjects->@*;
    }

    # Loop over the requested MELT Object and the directly linked MELT Objects
    MELTObjectID:
    for my $MELTObjectID ( sort @MELTObjectIDs ) {

        # get MELT Object data
        my $MELTObject = $Self->MELTObjectGet(
            MELTObjectID => $MELTObjectID,
            Cache        => 0,
        );

        # When an incident was found, mark the MELT Object and stop recursing
        if ( $MELTObject->{ZTSMStatusType} eq 'incident' ) {
            $Param{ScannedMELTObjectIDs}{$MELTObjectID}{Type} = 'incident';

            next MELTObjectID;
        }

        # no incident was encountered, continue with recursion
        # _FindInciMELTObjects() might be called with the current $Param{MELTObjectID}.
        # But that call will do nothing.
        $Self->_FindInciMELTObjects(
            MELTObjectID         => $MELTObjectID,
            IncidentLinkTypes    => $Param{IncidentLinkTypes},
            ScannedMELTObjectIDs => $Param{ScannedMELTObjectIDs},
        );
    }

    return;
}

=head2 _FindWarnMELTObjects()

This method is called for MELT Object that are in a incident or warning state.
Find connected MELT Objects and annotate them with a warning in C<ScannedMELTObjectIDs>. Propagate the warning.

    $MELTObjectObject->_FindWarnMELTObjects(
        MELTObjectID         => $MELTObjectID,
        LinkType             => $LinkType,
        Direction            => $LinkDirection,
        NumberOfLinkTypes    => 2,                     # just for infinite loop protection
        ScannedMELTObjectIDs => $ScannedMELTObjectIDs,
    );

=cut

sub _FindWarnMELTObjects {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    return unless $Param{MELTObjectID};

    # Infinite loop protection.
    # Ignore already scanned ids.
    # It is ok that a MELT Object is investigated as many times as there are configured link types * number of incident config iteems
    my $IncidentCount = true { ( $Param{ScannedMELTObjectIDs}{$_}{Type} || '' ) eq 'incident' }
    keys $Param{ScannedMELTObjectIDs}->%*;
    if (
        $Param{ScannedMELTObjectIDs}{ $Param{MELTObjectID} }->{FindWarn}
        &&
        $Param{ScannedMELTObjectIDs}{ $Param{MELTObjectID} }->{FindWarn} >= ( $Param{NumberOfLinkTypes} * $IncidentCount )
        )
    {
        return;
    }

    # increase the visit counter
    $Param{ScannedMELTObjectIDs}{ $Param{MELTObjectID} }->{FindWarn}++;

    # find MELT Objects to which the incident or warning must be propagated
    my $LinkedMELTObjects = $Self->LinkedMELTObjects(
        MELTObjectID => $Param{MELTObjectID},
        Types        => [ $Param{LinkType} ],
        Direction    => $Param{Direction},
        UserID       => 1,
    );
    my @LinkedMELTObjectIDs = map { $_->{MELTObjectID} } $LinkedMELTObjects->@*;

    MELTObjectID:
    for my $MELTObjectID ( sort @LinkedMELTObjectIDs ) {

        # start recursion
        $Self->_FindWarnMELTObjects(
            MELTObjectID         => $MELTObjectID,
            LinkType             => $Param{LinkType},
            Direction            => $Param{Direction},
            NumberOfLinkTypes    => $Param{NumberOfLinkTypes},
            ScannedMELTObjectIDs => $Param{ScannedMELTObjectIDs},
        );

        next MELTObjectID if ( $Param{ScannedMELTObjectIDs}{$MELTObjectID}{Type} || '' ) eq 'incident';

        # set warning state
        $Param{ScannedMELTObjectIDs}{$MELTObjectID}{Type} = 'warning';
    }

    return 1;
}

=head2 _PrepareLikeString()

internal function to prepare like strings

    $MELTObjectObject->_PrepareLikeString( $StringRef );

=cut

sub _PrepareLikeString {
    my ( $Self, $Value ) = @_;

    return if !$Value;
    return if ref $Value ne 'SCALAR';

    # Quote
    ${$Value} = $Kernel::OM->Get('Kernel::System::DB')->Quote( ${$Value}, 'Like' );

    # replace * with %
    ${$Value} =~ s{ \*+ }{%}xmsg;

    return;
}

=head1 MELT object events:

MELTObjectCreate, MELTObjectUpdate, VersionCreate, VersionUpdate, DeploymentStateUpdate, IncidentStateUpdate,
MELTObjectDelete, LinkAdd, LinkDelete, DefinitionUpdate, NameUpdate, DefinitionCreate, VersionDelete

=cut

1;

