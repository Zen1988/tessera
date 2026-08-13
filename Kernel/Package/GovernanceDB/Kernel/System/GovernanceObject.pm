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

package Kernel::System::GovernanceObject;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use parent qw(
    Kernel::System::EventHandler
    Kernel::System::GovernanceObject::GovernanceObjectACL
    Kernel::System::GovernanceObject::GovernanceObjectSearch
    Kernel::System::GovernanceObject::Definition
    Kernel::System::GovernanceObject::History
    Kernel::System::GovernanceObject::Link
    Kernel::System::GovernanceObject::Number
    Kernel::System::GovernanceObject::Permission
    Kernel::System::GovernanceObject::Version
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

Kernel::System::Governance Object - library for Governance objects.

=head1 DESCRIPTION

All GovernanceObject functions. Note that additional parent modules are loaded
which effectively add more methods.

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    use Kernel::System::ObjectManager;

    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

=cut

sub new {
    my ($Type) = @_;

    # allocate new hash for object
    my $Self = bless {}, $Type;

    $Self->{CacheType} = 'GovernanceDB';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    # init of event handler
    $Self->EventHandlerInit(
        Config => 'GovernanceObject::EventModulePost',
    );

    return $Self;
}

=head2 GovernanceObjectCount()

count all productive Governance Objects of a Governance Object class

    my $Count = $GovernanceObjectObject->GovernanceObjectCount(
        ClassID => 123,
    );

=cut

sub GovernanceObjectCount {
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
        Class       => 'ZTSM::GovernanceObject::Status',
        Preferences => {
            Functionality => [ 'preproductive', 'productive' ],
        },
    );

    return 0 if ref $StateList ne 'HASH' || !%{$StateList};

    # create state string
    my $ZTSMStatusString = join q{, }, keys %{$StateList};

    # ask database
    my ($Count) = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
        SQL => "SELECT COUNT(id) FROM governance_object_item WHERE class_id = ? AND "
            . "ztsm_status_id IN ( $ZTSMStatusString )",
        Bind  => [ \$Param{ClassID} ],
        Limit => 1,
    );

    return $Count;
}

=head2 GovernanceObjectResultList()

return a Governance Object list as array hash reference

    my $GovernanceObjectListRef = $GovernanceObjectObject->GovernanceObjectResultList(
        ClassID => 123,
        Start   => 100,
        Limit   => 50,
    );

=cut

sub GovernanceObjectResultList {
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
        Class       => 'ZTSM::GovernanceObject::Status',
        Preferences => {
            Functionality => [ 'preproductive', 'productive' ],
        },
    );

    # An installation may temporarily have no productive status catalog items
    # during bootstrap or repair. Never generate an invalid SQL IN () clause.
    return [] if ref $StateList ne 'HASH' || !%{$StateList};

    # create state string
    my $ZTSMStatusString = join q{, }, keys %{$StateList};

    # ask database
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => "SELECT id FROM governance_object_item "
            . "WHERE class_id = ? AND ztsm_status_id IN ( $ZTSMStatusString ) "
            . "ORDER BY change_time DESC",
        Bind  => [ \$Param{ClassID} ],
        Start => $Param{Start},
        Limit => $Param{Limit},
    );

    # fetch the result
    my @GovernanceObjectIDList;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        push @GovernanceObjectIDList, $Row[0];
    }

    # get last versions data
    my @GovernanceObjectList;
    for my $GovernanceObjectID (@GovernanceObjectIDList) {

        # get version data
        my $GovernanceObject = $Self->GovernanceObjectGet(
            GovernanceObjectID  => $GovernanceObjectID,
            DynamicFields => 0,
        );

        push @GovernanceObjectList, $GovernanceObject;
    }

    return \@GovernanceObjectList;
}

=head2 GovernanceObjectGet()

return a Governance Object as a hash reference. The latest version is retrieved when C<GovernanceObjectID> is passed as parameter.

    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        GovernanceObjectID  => 123,
        DynamicFields => 1,    # (optional) default 0 (0|1)
    );

A specific version is returned when the C<VersionID> is passed.

    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        VersionID     => 243,
        DynamicFields => 1,    # (optional) default 0 (0|1)
    );

When both C<GovernanceObjectID> and C<VersionID> are passed, then a consistency check is performed
and the data for the specific version is returned.

Error messages are suppressed if the parameter C<Silent> is passed.

    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        VersionID     => 243,
        DynamicFields => 1,    # (optional) default 0 (0|1)
        Silent        => 1,    # (optional) default 0 (0|1)
    );

A hashref with the following keys is returned:

=over 4

=item GovernanceObjectID

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

sub GovernanceObjectGet {
    my ( $Self, %Param ) = @_;

    # whether to suppress error messages
    my $Silent = $Param{Silent} ? 1 : 0;

    # check needed stuff
    if ( !$Param{GovernanceObjectID} && !$Param{VersionID} ) {
        if ( !$Silent ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Need GovernanceObjectID or VersionID!',
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
            '::', 'GovernanceObjectGet',
            VersionID => $Param{VersionID},
            DFData    => $DFData
        )
        :
        join(
            '::', 'GovernanceObjectGet',
            GovernanceObjectID => $Param{GovernanceObjectID},
            DFData       => $DFData
        );

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $Cache       = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );

    if ($Cache) {
        if ( $Param{VersionID} && $Param{GovernanceObjectID} && $Param{GovernanceObjectID} ne $Cache->{GovernanceObjectID} ) {
            if ( !$Silent ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "VersionID $Param{VersionID} is not a version of GovernanceObjectID $Param{GovernanceObjectID}!",
                );
            }

            return;
        }

        return dclone($Cache) if $Cache;
    }

    # get specific GovernanceObjectVersion
    # The parameter VersionID takes precedence over GovernanceObjectID
    my @Row;
    if ( $Param{VersionID} ) {

        @Row = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
            SQL => <<'END_SQL',
SELECT ci.id, ci.goid, ci.class_id, ci.last_version_id,
    ci.ztsm_status_id, ci.ztsm_status_id,
    v.id, v.name, v.version_string, v.definition_id, v.ztsm_status_id, v.ztsm_status_id, v.description,
    v.create_time, v.create_by, v.change_time, v.change_by
  FROM governance_object_item_version v
  INNER JOIN governance_object_item ci
    ON v.governance_object_id = ci.id
  WHERE v.id = ?
END_SQL
            Bind  => [ \$Param{VersionID} ],
            Limit => 1,
        );
    }

    # get latest GovernanceObjectVersion
    else {

        @Row = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
            SQL => <<'END_SQL',
SELECT ci.id, ci.goid, ci.class_id, ci.last_version_id,
    ci.ztsm_status_id, ci.ztsm_status_id,
    v.id, v.name, v.version_string, v.definition_id, v.ztsm_status_id, v.ztsm_status_id, v.description,
    ci.create_time, ci.create_by, ci.change_time, ci.change_by
  FROM governance_object_item ci
  LEFT JOIN governance_object_item_version v
    ON ci.last_version_id = v.id
  WHERE ci.id = ?
END_SQL
            Bind  => [ \$Param{GovernanceObjectID} ],
            Limit => 1,
        );
    }

    # fetch the result
    my %GovernanceObject;
    $GovernanceObject{GovernanceObjectID}   = $Row[0];
    $GovernanceObject{Number}         = $Row[1];
    $GovernanceObject{ClassID}        = $Row[2];
    $GovernanceObject{LastVersionID}  = $Row[3];
    $GovernanceObject{ZTSMStatusID} = $Row[4];
    $GovernanceObject{ZTSMStatusID} = $Row[5];
    $GovernanceObject{VersionID}      = $Row[6];
    $GovernanceObject{Name}           = $Row[7];
    $GovernanceObject{VersionString}  = $Row[8];
    $GovernanceObject{DefinitionID}   = $Row[9];
    $GovernanceObject{ZTSMStatusID}    = $Row[10];
    $GovernanceObject{ZTSMStatusID}    = $Row[11];
    $GovernanceObject{Description}    = $Row[12];
    $GovernanceObject{CreateTime}     = $Row[13];
    $GovernanceObject{CreateBy}       = $Row[14];
    $GovernanceObject{ChangeTime}     = $Row[15];
    $GovernanceObject{ChangeBy}       = $Row[16];

    # check Governance Object
    if ( !$GovernanceObject{GovernanceObjectID} ) {
        if ( !$Silent ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No such GovernanceObjectID ($Param{GovernanceObjectID})!",
            );
        }

        return;
    }
    if ( $Param{VersionID} && $Param{GovernanceObjectID} && $Param{GovernanceObjectID} ne $GovernanceObject{GovernanceObjectID} ) {
        if ( !$Silent ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "VersionID $Param{VersionID} is not a version of GovernanceObjectID $Param{GovernanceObjectID}!",
            );
        }

        return;
    }

    # check if need to return DynamicFields
    if ( $DFData && $GovernanceObject{DefinitionID} ) {

        # get dynamic field objects
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        my $Definition = $Self->DefinitionGet(
            DefinitionID => $GovernanceObject{DefinitionID},
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
                ObjectID           => $GovernanceObject{VersionID},
            );

            # set the dynamic field name and value into the ticket hash
            $GovernanceObject{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $Value;
        }
    }

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # add the Class, based on the ClassID
    {
        my $ClassList = $GeneralCatalogObject->ItemList(
            Class => 'ZTSM::GovernanceObject::Class',
        );

        $GovernanceObject{Class} = $ClassList->{ $GovernanceObject{ClassID} };
    }

    # Add more readable names for the various states.
    # Add the state types.
    STATE:
    for my $State (qw/ZTSMStatus ZTSMStatus ZTSMStatus ZTSMStatus/) {
        next STATE unless $GovernanceObject{ $State . 'ID' };

        my $Item = $GeneralCatalogObject->ItemGet(
            ItemID => $GovernanceObject{ $State . 'ID' },
        );

        $GovernanceObject{$State} = $Item->{Name};
        $GovernanceObject{ $State . 'Type' } = $Item->{Functionality}[0] // '';
    }

    # cache the result
    $CacheObject->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => dclone( \%GovernanceObject ),
    );

    return \%GovernanceObject;
}

=head2 GovernanceObjectAdd()

add a new Governance Object. This implies that an initial version is created as well.

    my $GovernanceObjectID = $GovernanceObjectObject->GovernanceObjectAdd(
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

No Governance Object will be created when an already existing Number is passed.

=cut

sub GovernanceObjectAdd {
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
        Class => 'ZTSM::GovernanceObject::Class',
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
        Class => 'ZTSM::GovernanceObject::Status',
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

    # create Governance Object number
    if ( $Param{Number} ) {

        # find existing Governance Object number
        my $Exists = $Self->GOIDLookup(
            GOID => $Param{Number},
        );

        if ($Exists) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Governance Object number already exists!',
            );

            return;
        }
    }
    else {

        my $NumberModule = $ClassPreferences{NumberModule} ? $ClassPreferences{NumberModule}[0] : 'AutoIncrement';

        # create Governance Object number
        $Param{Number} = $Self->GOIDCreate(
            Type    => "Kernel::System::GovernanceObject::Number::$NumberModule",
            ClassID => $Param{ClassID},
        );
    }

    my $NameModule = $ClassPreferences{NameModule} ? $ClassPreferences{NameModule}[0] : '';
    if ($NameModule) {

        # check if name module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::GovernanceObject::Name::$NameModule") ) {
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
                GovernanceObjectID => 'NEW',
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
                    Message  => "The name $Param{Name} is already in use (GovernanceObjectIDs: $Duplicates)!",
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

    # insert new Governance Object
    $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO governance_object_item ('
            . 'goid, ztsm_status_id'
            . ', class_id, create_time, create_by, change_time, change_by'
            . ') VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [ \$Param{Number}, \$Param{ZTSMStatusID}, \$Param{ClassID}, \$Param{UserID}, \$Param{UserID} ],
    );

    # find id of new item
    # TODO: what about concurrent INSERTs ???
    my ($GovernanceObjectID) = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
        SQL => <<'END_SQL',
SELECT id
  FROM governance_object_item
  WHERE goid = ?
    AND class_id = ?
  ORDER BY id DESC
END_SQL
        Bind => [ \$Param{Number}, \$Param{ClassID} ],
    );

    # trigger GovernanceObjectCreate
    $Self->EventHandler(
        Event => 'GovernanceObjectCreate',
        Data  => {
            GovernanceObjectID => $GovernanceObjectID,
            Comment      => $GovernanceObjectID . '%%' . $Param{Number},
        },
        UserID => $Param{UserID},
    );

    # add the first version
    my $VersionID = $Self->VersionAdd(
        Description => '',
        %Param,
        GovernanceObjectID => $GovernanceObjectID,
        LastVersion  => {
            GovernanceObjectID => 'NEW',
        },
    );

    if ( !$VersionID ) {

        # delete history entries
        $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'DELETE FROM governance_object_item_history WHERE governance_object_id = ?',
            Bind => [ \$GovernanceObjectID ],
        );

        # delete Governance Object if no version could be created
        $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'DELETE FROM governance_object_item WHERE id = ?',
            Bind => [ \$GovernanceObjectID ],
        );

        # write an error log message containing all the duplicate IDs
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Could not create version!",
        );

        return;
    }

    return $GovernanceObjectID;
}

=head2 GovernanceObjectDelete()

delete an existing Governance Object

    my $True = $GovernanceObjectObject->GovernanceObjectDelete(
        GovernanceObjectID => 123,
        UserID       => 1,
    );

=cut

sub GovernanceObjectDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(GovernanceObjectID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    # remember Governance Object data before delete
    my $GovernanceObjectData = $Self->GovernanceObjectGet(
        GovernanceObjectID => $Param{GovernanceObjectID},
    );

    # delete all links to this Governance Object before deleting the versions.
    # LinkDeleteAll() calls LinkDelete() internally. This means that
    # the event handlers are honored. This means that the table governance_object_item_link
    # is also purged.
    return unless $Kernel::OM->Get('Kernel::System::LinkObject')->LinkDeleteAll(
        Object => 'GovernanceObject',
        Key    => $Param{GovernanceObjectID},
        UserID => $Param{UserID},
    );

    # delete dynamic link table entries, if any

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Do(
        SQL  => 'DELETE FROM governance_object_item_link WHERE source_governance_object_id = ?',
        Bind => [ \$Param{GovernanceObjectID} ],
    );
    $DBObject->Do(
        SQL  => 'DELETE FROM governance_object_item_link WHERE target_governance_object_id = ?',
        Bind => [ \$Param{GovernanceObjectID} ],
    );

    # if there are static (versioned) links, delete all of them
    my $VersionListRef = $Self->VersionList(
        GovernanceObjectID => $Param{GovernanceObjectID},
    );

    for my $VersionID (@$VersionListRef) {
        $DBObject->Do(
            SQL  => 'DELETE FROM governance_object_item_link WHERE source_governance_object_item_version_id = ?',
            Bind => [ \$VersionID ],
        );
        $DBObject->Do(
            SQL  => 'DELETE FROM governance_object_item_link WHERE target_governance_object_item_version_id = ?',
            Bind => [ \$VersionID ],
        );
    }

    # delete existing versions
    $Self->VersionDelete(
        GovernanceObjectID => $Param{GovernanceObjectID},
        UserID       => $Param{UserID},
    );

    # get a list of all attachments
    my @ExistingAttachments = $Self->GovernanceObjectAttachmentList(
        GovernanceObjectID => $Param{GovernanceObjectID},
    );

    # delete all attachments of this Governance Object
    FILENAME:
    for my $Filename (@ExistingAttachments) {

        # delete the attachment
        my $DeletionSuccess = $Self->GovernanceObjectAttachmentDelete(
            GovernanceObjectID => $Param{GovernanceObjectID},
            Filename     => $Filename,
            UserID       => $Param{UserID},
        );

        if ( !$DeletionSuccess ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Unknown problem when deleting attachment $Filename of Governance Object "
                    . "$Param{GovernanceObjectID}. Please check the VirtualFS backend for stale "
                    . "files!",
            );
        }
    }

    my %ClassPreferences = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesGet(
        ItemID => $GovernanceObjectData->{ClassID},
    );
    my $NameModule = $ClassPreferences{NameModule} ? $ClassPreferences{NameModule}[0] : '';
    if ($NameModule) {

        # check if name module exists
        if ( $Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::GovernanceObject::Name::$NameModule") ) {

            # create a backend object
            my $NameModuleObject = $Kernel::OM->Get($NameModule);

            if ( $NameModuleObject->can('GovernanceObjectNameDelete') ) {
                $NameModuleObject->GovernanceObjectNameDelete(
                    Name => $GovernanceObjectData->{Name},
                );
            }
        }
        else {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load name module for class $GovernanceObjectData->{Class}!",
            );
        }
    }

    # trigger GovernanceObjectDelete event
    # this must be done before deleting the Governance Object from the database,
    # because of a foreign key constraint in the governance_object_item_history table
    $Self->EventHandler(
        Event => 'GovernanceObjectDelete',
        Data  => {
            GovernanceObjectID => $Param{GovernanceObjectID},
            Comment      => $Param{GovernanceObjectID},
            Number       => $GovernanceObjectData->{Number},
            Class        => $GovernanceObjectData->{Class},
        },
        UserID => $Param{UserID},
    );

    # delete Governance Object
    my $Success = $DBObject->Do(
        SQL  => 'DELETE FROM governance_object_item WHERE id = ?',
        Bind => [ \$Param{GovernanceObjectID} ],
    );

    # delete the cache
    for my $DFData ( 0, 1 ) {
        $Kernel::OM->Get('Kernel::System::Cache')->Delete(
            Type => $Self->{CacheType},
            Key  => join(
                'GovernanceObjectGet',
                GovernanceObjectID => $Param{GovernanceObjectID},
                DFData       => $DFData
            ),
        );
    }

    return $Success;
}

=head2 GovernanceObjectUpdate()

update a Governance Object. A new version will be created only when a version trigger applies.

    my $Success = $GovernanceObjectObject->GovernanceObjectUpdate(
        GovernanceObjectID   => 27,
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

sub GovernanceObjectUpdate {
    my ( $Self, %Param ) = @_;

    # lookup
    $Param{GovernanceObjectID} //= $Self->GovernanceObjectLookup(
        GOID => $Param{Number},
    );

    # check needed parameters
    for my $Key (qw/GovernanceObjectID UserID/) {
        if ( !$Param{$Key} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need " . ( $Key eq 'GovernanceObjectID' ? 'GovernanceObjectID or Number' : $Key ),
            );

            return;
        }
    }

    # gather dynamic field keys
    my @DynamicFieldNames = map
        {m/^DynamicField_(.+)/}
        sort keys %Param;

    # get current Governance Object, including info from the last version
    my $GovernanceObject = $Self->GovernanceObjectGet(
        GovernanceObjectID  => $Param{GovernanceObjectID},
        DynamicFields => 1,
    );

    my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
    );
    my $Class = $ClassList->{ $GovernanceObject->{ClassID} };

    if ( !$Class ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No valid class found for id '$GovernanceObject->{ClassID}' (GovernanceObject#$GovernanceObject->{Number})!",
        );

        return;
    }

    # ignore the passed in name when a name module is active
    my %ClassPreferences = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesGet(
        ItemID => $GovernanceObject->{ClassID},
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
    elsif ( $Param{Name} && $Param{Name} ne $GovernanceObject->{Name} ) {

        # check, whether the feature to check for a unique name is enabled
        if ( $Kernel::OM->Get('Kernel::Config')->Get('UniqueCIName::EnableUniquenessCheck') ) {

            my $NameDuplicates = $Self->UniqueNameCheck(
                GovernanceObjectID => $Param{GovernanceObjectID},
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
                    Message  => "The name $Param{Name} is already in use (GovernanceObjectIDs: $Duplicates)!",
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
        next ATTR if $Param{$Attribute} eq $GovernanceObject->{$Attribute};

        $Changed{$Attribute} = {
            Old => $GovernanceObject->{$Attribute},
            New => $Param{$Attribute},
        };

        $UpdateVersion = 1;

        if ( $VersionTrigger{$Attribute} ) {
            $AddVersion = 1;
        }
    }

    # get latest definition for the class
    my $Definition = $Self->DefinitionGet(
        ClassID => $GovernanceObject->{ClassID},
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
                    Value2             => $GovernanceObject->{"DynamicField_$Name"},
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
            Description => $GovernanceObject->{Description} // '',
            %Param,
            %SkipForUpdateDFs,
            LastVersion => $GovernanceObject,
        );
        return unless $Success;
    }
    elsif ($UpdateVersion) {
        my $Success = $Self->VersionUpdate(
            %Param,
            Version => $GovernanceObject,
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
                GovernanceObjectID => $GovernanceObject->{GovernanceObjectID},
                Comment      => $Changed{$Key}{New} . '%%' . $Changed{$Key}{Old},
            },
            UserID => $Param{UserID},
        );
    }

    # trigger GovernanceObjectUpdate but only if there were updates
    if ( $AddVersion || $UpdateVersion || %Changed ) {
        $Self->EventHandler(
            Event => 'GovernanceObjectUpdate',
            Data  => {
                GovernanceObjectID => $GovernanceObject->{GovernanceObjectID},
                Comment      => $GovernanceObject->{GovernanceObjectID} . '%%' . $GovernanceObject->{Number},
                OldZTSMStatus => $Changed{ZTSMStatusID}{Old},
            },
            UserID => $Param{UserID},
        );
    }

    return 1;
}

=head2 GovernanceObjectAttachmentAdd()

adds an attachment to a Governance Object

    my $Success = $GovernanceObjectObject->GovernanceObjectAttachmentAdd(
        GovernanceObjectID    => 1,
        Filename        => 'filename',
        Content         => 'content',
        ContentType     => 'text/plain',
        UserID          => 1,
    );

=cut

sub GovernanceObjectAttachmentAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(GovernanceObjectID Filename Content ContentType UserID)) {
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
        Filename    => "GovernanceObject/$Param{GovernanceObjectID}/$Param{Filename}",
        Mode        => 'binary',
        Content     => \$Param{Content},
        Preferences => {
            ContentID    => $Param{ContentID},
            ContentType  => $Param{ContentType},
            GovernanceObjectID => $Param{GovernanceObjectID},
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
                GovernanceObjectID => $Param{GovernanceObjectID},
                Comment      => $Param{Filename},
                HistoryType  => 'AttachmentAdd',
            },
            UserID => $Param{UserID},
        );
    }
    else {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Cannot add attachment for Governance Object $Param{GovernanceObjectID}",
        );

        return;
    }

    return 1;
}

=head2 GovernanceObjectAttachmentDelete()

Delete the given file from the virtual filesystem.

    my $Success = $GovernanceObjectObject->GovernanceObjectAttachmentDelete(
        GovernanceObjectID => 123,               # used in event handling, e.g. for logging the history
        Filename     => 'Projectplan.pdf', # identifies the attachment (together with the GovernanceObjectID)
        UserID       => 1,
    );

=cut

sub GovernanceObjectAttachmentDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(GovernanceObjectID Filename UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    # add prefix
    my $Filename = 'GovernanceObject/' . $Param{GovernanceObjectID} . '/' . $Param{Filename};

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
                GovernanceObjectID => $Param{GovernanceObjectID},
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

=head2 GovernanceObjectAttachmentGet()

This method returns information about one specific attachment.

    my $Attachment = $GovernanceObjectObject->GovernanceObjectAttachmentGet(
        GovernanceObjectID => 4,
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

sub GovernanceObjectAttachmentGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(GovernanceObjectID Filename)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # add prefix
    my $Filename = 'GovernanceObject/' . $Param{GovernanceObjectID} . '/' . $Param{Filename};

    # find all attachments of this Governance Object
    my @Attachments = $Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Filename    => $Filename,
        Preferences => {
            GovernanceObjectID => $Param{GovernanceObjectID},
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

=head2 GovernanceObjectAttachmentList()

Returns an array with all attachments of the given Governance Object.

    my @Attachments = $GovernanceObjectObject->GovernanceObjectAttachmentList(
        GovernanceObjectID => 123,
    );

returns

    @Attachments = (
        'filename.txt',
        'other_file.pdf',
    );

=cut

sub GovernanceObjectAttachmentList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{GovernanceObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need GovernanceObjectID!',
        );

        return;
    }

    # find all attachments of this Governance Object
    my @Attachments = $Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Preferences => {
            GovernanceObjectID => $Param{GovernanceObjectID},
        },
    );

    for my $Filename (@Attachments) {

        # remove extra information from filename
        $Filename =~ s{ \A Governance Object / \d+ / }{}xms;
    }

    return @Attachments;
}

=head2 GovernanceObjectAttachmentExists()

Checks if a file with a given filename exists.

    my $Exists = $GovernanceObjectObject->GovernanceObjectAttachmentExists(
        Filename => 'test.txt',
        GovernanceObjectID => 123,
        UserID   => 1,
    );

=cut

sub GovernanceObjectAttachmentExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Filename GovernanceObjectID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    return if !$Kernel::OM->Get('Kernel::System::VirtualFS')->Find(
        Filename => 'GovernanceObject/' . $Param{GovernanceObjectID} . '/' . $Param{Filename},
    );

    return 1;
}

=head2 GovernanceObjectLookup()

This method does a lookup for a config-item. If a config-item id is given,
it returns the number of the config-item. If a config-item number is given,
the appropriate id is returned.

    my $Number = $GovernanceObjectObject->GovernanceObjectLookup(
        GovernanceObjectID => 1234,
    );

or

    my $ID = $GovernanceObjectObject->GovernanceObjectLookup(
        GOID => 1000001,
    );

=cut

sub GovernanceObjectLookup {
    my ( $Self, %Param ) = @_;

    my ($Key) = first { $Param{$_} } qw(GovernanceObjectID GOID);

    # check for needed stuff
    if ( !$Key ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need GovernanceObjectID or GOID!',
        );

        return;
    }

    # if result is cached return that result
    return $Self->{Cache}{GovernanceObjectLookup}{$Key}{ $Param{$Key} }
        if $Self->{Cache}{GovernanceObjectLookup}{$Key}{ $Param{$Key} };

    # set the appropriate SQL statement
    my $SQL = $Key eq 'GOID'
        ?
        'SELECT id                FROM governance_object_item WHERE goid = ?'
        :
        'SELECT goid FROM governance_object_item WHERE id = ?';

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

    $Self->{Cache}{GovernanceObjectLookup}{$Key}{ $Param{$Key} } = $Value;

    return $Value;
}

=head2 UniqueNameCheck()

This method checks all already existing Governance Objects, whether the given name does already exist
within the same Governance Object class or among all classes, depending on the SysConfig value of
UniqueCIName::UniquenessCheckScope (Class or Global).

This method requires 3 parameters: GovernanceObjectID, Name and Class
"GovernanceObjectID"  is the ID of the GovernanceObject, which is to be checked for uniqueness
"Name"          is the Governance Object name to be checked for uniqueness
"ClassID"       is the ID of the Governance Object's class

All parameters are mandatory.

    my $DuplicateNames = $GovernanceObjectObject->UniqueNameCheck(
        GovernanceObjectID => '73'
        Name         => 'PC#005',
        ClassID      => '32',
    );

The given name is not unique

    my $NameDuplicates = [ 5, 35, 48, ];    # IDs of GovernanceObjects with the same name

The given name is unique

    my $NameDuplicates = [];

=cut

sub UniqueNameCheck {
    my ( $Self, %Param ) = @_;

    # check for needed stuff
    for my $Needed (qw(GovernanceObjectID Name ClassID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Missing parameter $Needed!",
            );
            return;
        }
    }

    # check GovernanceObjectID param for valid format
    if (
        !IsInteger( $Param{GovernanceObjectID} )
        && ( IsStringWithData( $Param{GovernanceObjectID} ) && $Param{GovernanceObjectID} ne 'NEW' )
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "The GovernanceObjectID parameter needs to be an integer or 'NEW'",
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
        Class => 'ZTSM::GovernanceObject::Class',
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
            Message  => "Unable to determine a Governance Object class using the given ClassID!",
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

    # add the Governance Object class to the search criteria if the uniqueness scope is not global
    if ( $Scope ne 'global' ) {
        $SearchCriteria{ClassIDs} = [ $Param{ClassID} ];
    }

    $SearchCriteria{Name} = $Param{Name};

    # search for a Governance Object matching the given name
    my @GovernanceObjectIDs = $Self->GovernanceObjectSearch(
        %SearchCriteria,
        Result => 'ARRAY'
    );

    # remove the provided GovernanceObjectID from the results, otherwise the duplicate check would fail
    # because the Governance Object itself is found as duplicate
    my @Duplicates = grep { $_ ne $Param{GovernanceObjectID} } @GovernanceObjectIDs;

    # if a Governance Object was found, the given name is not unique
    # if no Governance Object was found, the given name is unique

    # return the result of the Governance Object search for duplicates
    return \@Duplicates;
}

=head2 ZTSMStatusRecalc()

recalculates the current ZTSM Status of this Governance Object and of Governance Objects
that are linked to it. Only links between Governance Objects are considered here. Links to
or FROM governance_object_item versions are ignored.

The current ZTSM Status depends on the ZTSM Statuss that this Governance Object depends on.
A change of the ZTSM Status might have repercussions on the current ZTSM Status
of the Governance Objects that depend on this Governance Object.

It is a common use case that C<ZTSMStatusRecalc()> is called in a loop over a list of Governance Objects.
Examples are the console command C<Admin::ITSM::IncidentState::Recalculate> or when the linking
of the Governance Objects has changed. For optimizing that case there are the parameters
C<NewGovernanceObjectIncidentState> and C<ScannedGovernanceObjectIDs> which carry state between
invocations of this method. They provide caching and prevent infinite loops.

Changing the ZTSM Status of Governance Objects has repercussions on services. These effects
are handled in this method as well.

    my $Success = $GovernanceObjectObject->ZTSMStatusRecalc(
        GovernanceObjectID               => 123,
        NewGovernanceObjectIncidentState => $NewGovernanceObjectIncidentState,  # optional, ZTSM Statuss of already checked CIs
        ScannedGovernanceObjectIDs       => $ScannedGovernanceObjectIDs,        # optional, IDs and ZTSM Statuss of already checked CIs
    );

For asynchronous execution it is convenient to pass a list of Governance Objects to C<ZTSMStatusRecalc()>.

    my $Success = $GovernanceObjectObject->ZTSMStatusRecalc(
        GovernanceObjectIDs              => [ 123, 124, 125 ],
    );

In that case the loop is discontinued when an iteration reported a failure.

=cut

sub ZTSMStatusRecalc {
    my ( $Self, %Param ) = @_;

    # useful for async execution
    # all other parameters will be ignored
    if ( $Param{GovernanceObjectIDs} ) {

        # these hashes will be filled in the calls to ZTSMStatusRecalc
        my ( %NewGovernanceObjectIncidentState, %ScannedGovernanceObjectIDs );

        for my $GovernanceObjectID ( $Param{GovernanceObjectIDs}->@* ) {
            my $Success = $Self->ZTSMStatusRecalc(
                GovernanceObjectID               => $GovernanceObjectID,
                NewGovernanceObjectIncidentState => \%NewGovernanceObjectIncidentState,
                ScannedGovernanceObjectIDs       => \%ScannedGovernanceObjectIDs,
            );

            return unless $Success;
        }

        # all fine
        return 1;
    }

    # check needed stuff
    if ( !$Param{GovernanceObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need GovernanceObjectID!',
        );

        return;
    }
    if ( ref $Param{GovernanceObjectID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'The parameter GovernanceObjectID must be a plain scalar!',
        );

        return;
    }

    # get incident link types and directions from config. E.g.
    # { DependsOn => 'Both', LocationOf => 'Source' }
    my $IncidentLinkTypeDirection = $Kernel::OM->Get('Kernel::Config')->Get('ITSM::Core::IncidentLinkTypeDirection');

    # $Param{NewGovernanceObjectIncidentState} holds the determined ZTSM Statuss of the considered Governance Objects.
    # It may contain contain content from previous calls of ZTSMStatusRecalc() so that unnecessary work
    # can be skipped.
    # New ZTSM Statuss are calculated from all incident link types.
    # The newly determined ZTSM Statuss are made available to the caller, so that the caller
    # can pass it to the next iteration.
    # Incorporate data from previous run(s) and remember known data.
    $Param{NewGovernanceObjectIncidentState} //= {};
    my $KnownNewGovernanceObjectIncidentState = dclone( $Param{NewGovernanceObjectIncidentState} );

    # Remember the scanned Governance Objects
    # Incorporate data from previous run(s) and remember known data.
    $Param{ScannedGovernanceObjectIDs} //= {};
    my $KnownScannedGovernanceObjectIDs = dclone( $Param{ScannedGovernanceObjectIDs} );

    # Find deeply connected Governance Objects with an ZTSM Status.
    # The direction in $IncidentLinkTypeDirection is ignored here because depended on items could change
    # the ZTSM Status of the current Governance Object. Or changes in
    # the current Governance Object could change downstream Governance Objects.
    $Self->_FindInciGovernanceObjects(
        GovernanceObjectID         => $Param{GovernanceObjectID},
        IncidentLinkTypes    => [ keys $IncidentLinkTypeDirection->%* ],
        ScannedGovernanceObjectIDs => $Param{ScannedGovernanceObjectIDs},
    );

    # to store the relation between services and linked CIs
    # The info will be used for updating the services.
    my %ServiceCIRelation;

    # calculate the new CI ZTSM Status for each configured linktype
    LINKTYPE:
    for my $LinkType ( sort keys $IncidentLinkTypeDirection->%* ) {

        # get the direction
        my $LinkDirection = $IncidentLinkTypeDirection->{$LinkType};

        # investigate all Governance Objects with a warning state
        GovernanceObjectID:
        for my $GovernanceObjectID ( sort keys %{ $Param{ScannedGovernanceObjectIDs} } ) {

            # Skip Governance Objects known from previous execution(s).
            if (
                IsStringWithData( $KnownScannedGovernanceObjectIDs->{$GovernanceObjectID}{Type} )
                &&
                $KnownScannedGovernanceObjectIDs->{$GovernanceObjectID}{Type} eq $Param{ScannedGovernanceObjectIDs}{$GovernanceObjectID}{Type}
                )
            {
                next GovernanceObjectID;
            }

            # investigate only Governance Objects with an ZTSM Status
            next GovernanceObjectID unless $Param{ScannedGovernanceObjectIDs}{$GovernanceObjectID}{Type} eq 'incident';

            # annotate linked Governance Objects with a warning
            $Self->_FindWarnGovernanceObjects(
                GovernanceObjectID         => $GovernanceObjectID,
                LinkType             => $LinkType,
                Direction            => $LinkDirection,
                NumberOfLinkTypes    => scalar keys $IncidentLinkTypeDirection->%*,
                ScannedGovernanceObjectIDs => $Param{ScannedGovernanceObjectIDs},
            );
        }

        GovernanceObjectID:
        for my $GovernanceObjectID ( sort keys %{ $Param{ScannedGovernanceObjectIDs} } ) {

            # Skip Governance Objects known from previous execution(s).
            if (
                IsStringWithData( $KnownScannedGovernanceObjectIDs->{$GovernanceObjectID}{Type} )
                &&
                $KnownScannedGovernanceObjectIDs->{$GovernanceObjectID}{Type} eq $Param{ScannedGovernanceObjectIDs}{$GovernanceObjectID}{Type}
                )
            {
                next GovernanceObjectID;
            }

            # extract ZTSM Status type
            my $ZTSMStatusType = $Param{ScannedGovernanceObjectIDs}{$GovernanceObjectID}{Type};

            # Find all linked services of this Governance Object.
            # These kind of links are not available from the table governance_object_item_link
            my %LinkedServiceIDs = $Kernel::OM->Get('Kernel::System::LinkObject')->LinkKeyList(
                Object1   => 'GovernanceObject',
                Key1      => $GovernanceObjectID,
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
                push $ServiceCIRelation{$ServiceID}->@*, $GovernanceObjectID;
            }

            next GovernanceObjectID if $ZTSMStatusType eq 'incident';

            $Param{NewGovernanceObjectIncidentState}{$GovernanceObjectID} = $ZTSMStatusType;
        }
    }

    # get the ZTSM Status list of warnings
    my $WarnStateList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class       => 'ZTSM::GovernanceObject::Status',
        Preferences => {
            Functionality => 'warning',
        },
    );

    if ( !defined $WarnStateList ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "ZTSM::GovernanceObject::Status Warning cannot be invalid.",
        );
    }

    my %ReverseWarnStateList = reverse %{$WarnStateList};
    my @SortedWarnList       = sort keys %ReverseWarnStateList;
    my $WarningStateID       = $ReverseWarnStateList{Warning} || $ReverseWarnStateList{ $SortedWarnList[0] };
    my $CacheObject          = $Kernel::OM->Get('Kernel::System::Cache');

    # set the new current ZTSM Status for CIs
    GovernanceObjectID:
    for my $GovernanceObjectID ( sort keys $Param{NewGovernanceObjectIncidentState}->%* ) {

        # Skip Governance Objects known from previous execution(s).
        if (
            IsStringWithData( $KnownNewGovernanceObjectIncidentState->{$GovernanceObjectID} )
            && $KnownNewGovernanceObjectIncidentState->{$GovernanceObjectID} eq $Param{NewGovernanceObjectIncidentState}{$GovernanceObjectID}
            )
        {
            next GovernanceObjectID;
        }

        # get new ZTSM Status type (can only be 'operational' or 'warning')
        my $ZTSMStatusType = $Param{NewGovernanceObjectIncidentState}{$GovernanceObjectID};

        # get last version
        my $LastVersion = $Self->GovernanceObjectGet(
            GovernanceObjectID  => $GovernanceObjectID,
            DynamicFields => 0,
        );

        my $ZTSMStatusID;
        if ( $ZTSMStatusType eq 'warning' ) {

            # check the current ZTSM Status type is in 'incident'
            # then we do not want to change it to warning
            next GovernanceObjectID if $LastVersion->{ZTSMStatusType} eq 'incident';

            $ZTSMStatusID = $WarningStateID;
        }
        elsif ( $ZTSMStatusType eq 'operational' ) {
            $ZTSMStatusID = $LastVersion->{ZTSMStatusID};
        }

        # No update necessary if ZTSM Status id of version and Governance Object match.
        next GovernanceObjectID if $LastVersion->{ZTSMStatusID} eq $ZTSMStatusID;

        # update current ZTSM Status
        $Kernel::OM->Get('Kernel::System::DB')->Do(
            SQL  => 'UPDATE governance_object_item SET ztsm_status_id = ? WHERE id = ?',
            Bind => [ \$ZTSMStatusID, \$GovernanceObjectID ],
        );

        # TODO: Also the VersionID-caches have to be considered, they also contain ZTSMStatus
        # delete the cache
        for my $DFData ( 0, 1 ) {
            $CacheObject->Delete(
                Type => $Self->{CacheType},
                Key  => join(
                    '::', 'GovernanceObjectGet',
                    GovernanceObjectID => $GovernanceObjectID,
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

        # get the unique Governance Object ids which are directly linked to this service
        my %UniqueGovernanceObjectIDs = map { $_ => 1 } $ServiceCIRelation{$ServiceID}->@*;

        # investigate the current ZTSM Status of each Governance Object
        GovernanceObjectID:
        for my $GovernanceObjectID ( sort keys %UniqueGovernanceObjectIDs ) {

            # get Governance Object data
            my $GovernanceObjectData = $Self->GovernanceObjectGet(
                GovernanceObjectID => $GovernanceObjectID,
                Cache        => 0,
            );

            next GovernanceObjectID if $GovernanceObjectData->{ZTSMStatusType} ne 'productive';
            next GovernanceObjectID if $GovernanceObjectData->{ZTSMStatusType} eq 'operational';

            # check if service must be set to 'warning'
            if ( $GovernanceObjectData->{ZTSMStatusType} eq 'warning' ) {
                $ZTSMStatusTypeFromCIs = 'warning';

                next GovernanceObjectID;
            }

            # check if service must be set to 'incident'
            if ( $GovernanceObjectData->{ZTSMStatusType} eq 'incident' ) {
                $ZTSMStatusTypeFromCIs = 'incident';

                last GovernanceObjectID;
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

returns the attributes a Governance Object can have on the system.

    my %Attributes = $TicketObject->ObjectAttributesGet(
        DynamicFields => (0|1),         # (optional) if dynamic field names are included, default 0
        Version       => (0|1),         # (optional) if version information is included, default 1
        EditMask      => (0|1),         # (optional) if edit mask attributes are returned instead of backend attributes, default 0
    );

=cut

sub ObjectAttributesGet {
    my ( $Self, %Param ) = @_;

    $Param{Version} //= 1;

    my %GovernanceObjectAttributes;

    if ( $Param{EditMask} ) {
        %GovernanceObjectAttributes = (
            ZTSMStatusID   => 1,
            ZTSMStatusID   => 1,
            Name          => 1,
            VersionString => 1,
        );
    }
    else {
        %GovernanceObjectAttributes = (
            GovernanceObjectID   => 1,
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
            %GovernanceObjectAttributes = (
                %GovernanceObjectAttributes,
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
            ObjectType => 'GovernanceObject',
            ResultType => 'HASH',
        );

        for my $FieldName ( values $DynamicFields->%* ) {
            $GovernanceObjectAttributes{"DynamicField_$FieldName"} = 1;
        }
    }

    return %GovernanceObjectAttributes;
}

=head1 INTERNAL INTERFACE

=head2 _FindInciGovernanceObjects()

find connected Governance Objects with an ZTSM Status.

    $GovernanceObjectObject->_FindInciGovernanceObjects(
        GovernanceObjectID         => $GovernanceObjectID,
        IncidentLinkTypes    => [ keys $IncidentLinkTypeDirection->%* ],
        ScannedGovernanceObjectIDs => \%ScannedGovernanceObjectIDs,
    );

The scanned Governance Objects will be entered in the C<ScannedGovernanceObjectIDs> hashref. Each Governance Object will be scanned only once.
The attribute C<Type> will be either 'operational' or 'incident'.

The search for Governance Objects with incidents recurses into the graph of linked Governance Objects. The directly
linked items will always be checked. Recursion stops once an incident has been found.

This method only collects data, no current ZTSM Statuss will be altered.

=cut

sub _FindInciGovernanceObjects {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    return unless $Param{GovernanceObjectID};

    # ignore already scanned ids (infinite loop protection)
    return if defined $Param{ScannedGovernanceObjectIDs}{ $Param{GovernanceObjectID} };

    # set a default so the Governance Object won't be scanned again
    $Param{ScannedGovernanceObjectIDs}{ $Param{GovernanceObjectID} } = {};
    $Param{ScannedGovernanceObjectIDs}{ $Param{GovernanceObjectID} }->{Type} = 'operational';

    # add own Governance Object id to list of linked Governance Objects
    my @GovernanceObjectIDs = $Param{GovernanceObjectID};

    # find the directly linked Governance Objects
    {
        # Direction must ALWAYS be 'Both' here as we need to include
        # all linked CIs that could influence this one!
        my $LinkedGovernanceObjects = $Self->LinkedGovernanceObjects(
            GovernanceObjectID => $Param{GovernanceObjectID},
            Types        => $Param{IncidentLinkTypes},
            Direction    => 'Both',
            UserID       => 1,
        );

        # remember only the linked Governance Object ids, ignore the Governance Object versions
        push @GovernanceObjectIDs,
            grep {defined}
            map  { $_->{GovernanceObjectID} }
            $LinkedGovernanceObjects->@*;
    }

    # Loop over the requested Governance Object and the directly linked Governance Objects
    GovernanceObjectID:
    for my $GovernanceObjectID ( sort @GovernanceObjectIDs ) {

        # get Governance Object data
        my $GovernanceObject = $Self->GovernanceObjectGet(
            GovernanceObjectID => $GovernanceObjectID,
            Cache        => 0,
        );

        # When an incident was found, mark the Governance Object and stop recursing
        if ( $GovernanceObject->{ZTSMStatusType} eq 'incident' ) {
            $Param{ScannedGovernanceObjectIDs}{$GovernanceObjectID}{Type} = 'incident';

            next GovernanceObjectID;
        }

        # no incident was encountered, continue with recursion
        # _FindInciGovernanceObjects() might be called with the current $Param{GovernanceObjectID}.
        # But that call will do nothing.
        $Self->_FindInciGovernanceObjects(
            GovernanceObjectID         => $GovernanceObjectID,
            IncidentLinkTypes    => $Param{IncidentLinkTypes},
            ScannedGovernanceObjectIDs => $Param{ScannedGovernanceObjectIDs},
        );
    }

    return;
}

=head2 _FindWarnGovernanceObjects()

This method is called for Governance Object that are in a incident or warning state.
Find connected Governance Objects and annotate them with a warning in C<ScannedGovernanceObjectIDs>. Propagate the warning.

    $GovernanceObjectObject->_FindWarnGovernanceObjects(
        GovernanceObjectID         => $GovernanceObjectID,
        LinkType             => $LinkType,
        Direction            => $LinkDirection,
        NumberOfLinkTypes    => 2,                     # just for infinite loop protection
        ScannedGovernanceObjectIDs => $ScannedGovernanceObjectIDs,
    );

=cut

sub _FindWarnGovernanceObjects {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    return unless $Param{GovernanceObjectID};

    # Infinite loop protection.
    # Ignore already scanned ids.
    # It is ok that a Governance Object is investigated as many times as there are configured link types * number of incident config iteems
    my $IncidentCount = true { ( $Param{ScannedGovernanceObjectIDs}{$_}{Type} || '' ) eq 'incident' }
    keys $Param{ScannedGovernanceObjectIDs}->%*;
    if (
        $Param{ScannedGovernanceObjectIDs}{ $Param{GovernanceObjectID} }->{FindWarn}
        &&
        $Param{ScannedGovernanceObjectIDs}{ $Param{GovernanceObjectID} }->{FindWarn} >= ( $Param{NumberOfLinkTypes} * $IncidentCount )
        )
    {
        return;
    }

    # increase the visit counter
    $Param{ScannedGovernanceObjectIDs}{ $Param{GovernanceObjectID} }->{FindWarn}++;

    # find Governance Objects to which the incident or warning must be propagated
    my $LinkedGovernanceObjects = $Self->LinkedGovernanceObjects(
        GovernanceObjectID => $Param{GovernanceObjectID},
        Types        => [ $Param{LinkType} ],
        Direction    => $Param{Direction},
        UserID       => 1,
    );
    my @LinkedGovernanceObjectIDs = map { $_->{GovernanceObjectID} } $LinkedGovernanceObjects->@*;

    GovernanceObjectID:
    for my $GovernanceObjectID ( sort @LinkedGovernanceObjectIDs ) {

        # start recursion
        $Self->_FindWarnGovernanceObjects(
            GovernanceObjectID         => $GovernanceObjectID,
            LinkType             => $Param{LinkType},
            Direction            => $Param{Direction},
            NumberOfLinkTypes    => $Param{NumberOfLinkTypes},
            ScannedGovernanceObjectIDs => $Param{ScannedGovernanceObjectIDs},
        );

        next GovernanceObjectID if ( $Param{ScannedGovernanceObjectIDs}{$GovernanceObjectID}{Type} || '' ) eq 'incident';

        # set warning state
        $Param{ScannedGovernanceObjectIDs}{$GovernanceObjectID}{Type} = 'warning';
    }

    return 1;
}

=head2 _PrepareLikeString()

internal function to prepare like strings

    $GovernanceObjectObject->_PrepareLikeString( $StringRef );

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

=head1 Governance object events:

GovernanceObjectCreate, GovernanceObjectUpdate, VersionCreate, VersionUpdate, DeploymentStateUpdate, IncidentStateUpdate,
GovernanceObjectDelete, LinkAdd, LinkDelete, DefinitionUpdate, NameUpdate, DefinitionCreate, VersionDelete

=cut

1;
