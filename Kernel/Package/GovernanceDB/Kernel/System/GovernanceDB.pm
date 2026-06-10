# --
# Copyright (C) 2026 TESSERA
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# --

package Kernel::System::GovernanceDB;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub ObjectAdd {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(Name ZTSMCode UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $Class      = $Param{Class}      || 'StateBook';
    my $Status     = $Param{ZTSMStatus} || 'Draft';
    my $Definition = $Param{Definition} || '';
    my $Description = $Param{Description} // '';
    my $VersionString = '1';
    my $GOID       = $Param{GOID}       || $Self->GOIDCreate( Class => $Class, UserID => $Param{UserID} );

    return if !$GOID;

    my $ClassID = $Self->_ClassIDGet(Class => $Class);
    return if !$ClassID;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $DefinitionData;
    if ($Definition) {
        my $DefinitionID = $Self->DefinitionAdd(
            ClassID    => $ClassID,
            Definition => $Definition,
            UserID     => $Param{UserID},
        );
        $DefinitionData = $Self->DefinitionGet( DefinitionID => $DefinitionID ) if $DefinitionID;
    }
    else {
        $DefinitionData = $Self->DefinitionGet( ClassID => $ClassID );
    }

    if ( !$DefinitionData ) {
        my $DefinitionID = $Self->DefinitionAdd(
            ClassID    => $ClassID,
            Definition => "---\nFields: []\n",
            UserID     => $Param{UserID},
        );
        $DefinitionData = $Self->DefinitionGet( DefinitionID => $DefinitionID ) if $DefinitionID;
    }
    return if !$DefinitionData || !$DefinitionData->{DefinitionID};

    return if !$DBObject->Do(
        SQL => '
            INSERT INTO governance_object
                (goid, ztsm_code, ztsm_status, class_id, create_time, create_by, change_time, change_by)
            VALUES (?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [ \$GOID, \$Param{ZTSMCode}, \$Status, \$ClassID, \$Param{UserID}, \$Param{UserID} ],
    );

    my ($ObjectID) = $DBObject->SelectRowArray(
        SQL => '
            SELECT id
            FROM governance_object
            WHERE goid = ?',
        Bind  => [ \$GOID ],
        Limit => 1,
    );
    return if !$ObjectID;

    return if !$DBObject->Do(
        SQL => '
            INSERT INTO governance_object_version
                (governance_object_id, name, description, definition_id, version_string, create_time, create_by)
            VALUES (?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$ObjectID,
            \$Param{Name},
            \$Description,
            \$DefinitionData->{DefinitionID},
            \$VersionString,
            \$Param{UserID},
        ],
    );

    my ($VersionID) = $DBObject->SelectRowArray(
        SQL => '
            SELECT id
            FROM governance_object_version
            WHERE governance_object_id = ?
            ORDER BY id DESC',
        Bind  => [ \$ObjectID ],
        Limit => 1,
    );
    return if !$VersionID;

    return if !$DBObject->Do(
        SQL  => 'UPDATE governance_object SET last_version_id = ? WHERE id = ?',
        Bind => [ \$VersionID, \$ObjectID ],
    );

    return $ObjectID;
}

sub ObjectGet {
    my ( $Self, %Param ) = @_;

    if ( !$Param{ObjectID} && !$Param{GOID} && !$Param{ZTSMCode} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ObjectID, GOID, or ZTSMCode!',
        );
        return;
    }

    my @Bind;
    my $Where = 'go.id = ?';
    if ( $Param{ObjectID} ) {
        @Bind = ( \$Param{ObjectID} );
    }
    elsif ( $Param{GOID} ) {
        $Where = 'go.goid = ?';
        @Bind = ( \$Param{GOID} );
    }
    else {
        $Where = 'go.ztsm_code = ?';
        @Bind = ( \$Param{ZTSMCode} );
    }

    my @Row = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
        SQL => "
            SELECT go.id, go.goid, go.ztsm_code, go.ztsm_status, go.class_id,
                go.last_version_id, gov.name, gov.description, gov.version_string,
                go.create_time, go.create_by, go.change_time, go.change_by,
                god.definition
            FROM governance_object go
            LEFT JOIN governance_object_version gov
                ON go.last_version_id = gov.id
            LEFT JOIN governance_object_definition god
                ON gov.definition_id = god.id
            WHERE $Where",
        Bind  => \@Bind,
        Limit => 1,
    );

    return if !@Row;

    my $ClassList = $Self->ClassList();

    return {
        ObjectID      => $Row[0],
        GOID          => $Row[1],
        ZTSMCode      => $Row[2],
        ZTSMStatus    => $Row[3],
        ClassID       => $Row[4],
        Class         => $ClassList->{ $Row[4] } || '',
        LastVersionID => $Row[5],
        Name          => $Row[6],
        Description   => $Row[7],
        VersionString => $Row[8],
        CreateTime    => $Row[9],
        CreateBy      => $Row[10],
        ChangeTime    => $Row[11],
        ChangeBy      => $Row[12],
        Definition    => $Row[13],
        DefinitionData => $Self->_JSONDecode( Data => $Row[13] ),
    };
}

sub ObjectList {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $SQL = '
        SELECT go.id, go.goid, go.ztsm_code, go.ztsm_status, gov.name, gov.description, go.change_time
        FROM governance_object go
        LEFT JOIN governance_object_version gov
            ON go.last_version_id = gov.id
        ORDER BY go.change_time DESC';

    return if !$DBObject->Prepare( SQL => $SQL );

    my @Objects;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @Objects, {
            ObjectID    => $Row[0],
            GOID        => $Row[1],
            ZTSMCode    => $Row[2],
            ZTSMStatus  => $Row[3],
            Name        => $Row[4],
            Description => $Row[5],
            ChangeTime  => $Row[6],
        };
    }

    return \@Objects;
}

sub ClassList {
    my ( $Self, %Param ) = @_;

    return $Self->_DefinitionTargetList(
        Type  => 'Class',
        Valid => $Param{Valid},
    );
}

sub CategoryList {
    my ( $Self, %Param ) = @_;

    return $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => $Self->_GeneralCatalogClassName(Type => 'Category'),
        Valid => $Param{Valid},
    );
}

sub RoleList {
    my ( $Self, %Param ) = @_;

    return $Self->_DefinitionTargetList(
        Type  => 'Role',
        Valid => $Param{Valid},
    );
}

sub StatusList {
    my ( $Self, %Param ) = @_;

    return $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => $Self->_GeneralCatalogClassName(Type => 'Status'),
        Valid => $Param{Valid},
    );
}

sub ObjectCopyFromConfigItem {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(ConfigItemID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $ConfigItem = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID  => $Param{ConfigItemID},
        DynamicFields => 1,
        Silent        => 1,
    );

    if ( !$ConfigItem ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Could not load ConfigItemID $Param{ConfigItemID}!",
        );
        return;
    }

    my $ZTSMCode = $Param{ZTSMCode}
        || $ConfigItem->{'DynamicField_ZTSM-Code'}
        || $ConfigItem->{Number};

    my $ZTSMStatus = $Param{ZTSMStatus}
        || $ConfigItem->{'DynamicField_ZTSM-Status'}
        || $ConfigItem->{CurDeplState}
        || 'Draft';

    my $Class = $Param{Class}
        || $ConfigItem->{Class}
        || 'StateBook';

    my %DefinitionPayload = (
        SourceObjectType => 'ITSMConfigItem',
        SourceObjectID   => $ConfigItem->{ConfigItemID},
        SourceNumber     => $ConfigItem->{Number},
        SourceClass      => $ConfigItem->{Class},
        DynamicFields    => {
            map {
                my $Key = $_;
                ( $Key => $ConfigItem->{$Key} );
            } grep { $_ =~ m{\A DynamicField_}xms } keys %{$ConfigItem}
        },
    );

    my $Definition = $Param{Definition}
        || $Kernel::OM->Get('Kernel::System::JSON')->Encode( Data => \%DefinitionPayload );

    return $Self->ObjectAdd(
        Class       => $Class,
        GOID        => $Param{GOID},
        ZTSMCode    => $ZTSMCode,
        ZTSMStatus  => $ZTSMStatus,
        Name        => $Param{Name} // $ConfigItem->{Name} // $ConfigItem->{Number},
        Description => $Param{Description} // $ConfigItem->{Description} // '',
        Definition  => $Definition,
        UserID      => $Param{UserID},
    );
}

sub DefinitionList {
    my ( $Self, %Param ) = @_;

    my $TargetID = $Param{ClassID} || $Param{RoleID};
    my $Type     = $Param{RoleID} ? 'Role' : 'Class';

    return if !$TargetID;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => '
            SELECT id, class_id, definition, version, create_time, create_by
            FROM governance_object_definition
            WHERE class_id = ?
            ORDER BY version ASC, id ASC',
        Bind => [ \$TargetID ],
    );

    my @Definitions;
    my $TargetList = $Self->_DefinitionTargetLookup(Type => $Type);

    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @Definitions, {
            DefinitionID => $Row[0],
            ( $Type eq 'Role' ? ( RoleID => $Row[1], Role => $TargetList->{ $Row[1] } || '' ) : ( ClassID => $Row[1], Class => $TargetList->{ $Row[1] } || '' ) ),
            Definition   => $Row[2],
            Version      => $Row[3],
            CreateTime   => $Row[4],
            CreateBy     => $Row[5],
        };
    }

    return \@Definitions;
}

sub DefinitionGet {
    my ( $Self, %Param ) = @_;

    my $Type = $Param{RoleID} ? 'Role' : 'Class';

    if ( !$Param{DefinitionID} && !$Param{ClassID} && !$Param{RoleID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need DefinitionID, ClassID, or RoleID!',
        );
        return;
    }

    my @Bind;
    my $Where = 'id = ?';
    if ( $Param{DefinitionID} ) {
        @Bind = ( \$Param{DefinitionID} );
    }
    else {
        $Where = 'class_id = ?';
        @Bind  = ( $Type eq 'Role' ? \$Param{RoleID} : \$Param{ClassID} );
    }

    my @Row = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
        SQL => "
            SELECT id, class_id, definition, version, create_time, create_by
            FROM governance_object_definition
            WHERE $Where
            ORDER BY version DESC, id DESC",
        Bind  => \@Bind,
        Limit => 1,
    );

    return if !@Row;

    my $TargetList = $Self->_DefinitionTargetLookup(Type => $Type);

    return {
        DefinitionID => $Row[0],
        ( $Type eq 'Role' ? ( RoleID => $Row[1], Role => $TargetList->{ $Row[1] } || '' ) : ( ClassID => $Row[1], Class => $TargetList->{ $Row[1] } || '' ) ),
        Definition   => $Row[2],
        Version      => $Row[3],
        CreateTime   => $Row[4],
        CreateBy     => $Row[5],
    };
}

sub DefinitionAdd {
    my ( $Self, %Param ) = @_;

    my $TargetID = $Param{ClassID} || $Param{RoleID};

    for my $Needed (qw(Definition UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }
    if ( !$TargetID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ClassID or RoleID!',
        );
        return;
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my ($Version) = $DBObject->SelectRowArray(
        SQL => '
            SELECT MAX(version)
            FROM governance_object_definition
            WHERE class_id = ?',
        Bind => [ \$TargetID ],
    );
    $Version ||= 0;
    $Version++;

    return if !$DBObject->Do(
        SQL => '
            INSERT INTO governance_object_definition
                (class_id, definition, version, create_time, create_by)
            VALUES (?, ?, ?, current_timestamp, ?)',
        Bind => [ \$TargetID, \$Param{Definition}, \$Version, \$Param{UserID} ],
    );

    my ($DefinitionID) = $DBObject->SelectRowArray(
        SQL => '
            SELECT id
            FROM governance_object_definition
            WHERE class_id = ?
            ORDER BY id DESC',
        Bind  => [ \$TargetID ],
        Limit => 1,
    );

    return $DefinitionID;
}

sub RoleDefinitionList {
    my ( $Self, %Param ) = @_;

    $Param{RoleID} = delete $Param{ClassID} if $Param{ClassID} && !$Param{RoleID};

    return $Self->DefinitionList(%Param);
}

sub RoleDefinitionGet {
    my ( $Self, %Param ) = @_;

    $Param{RoleID} = delete $Param{ClassID} if $Param{ClassID} && !$Param{RoleID};

    return $Self->DefinitionGet(%Param);
}

sub RoleDefinitionAdd {
    my ( $Self, %Param ) = @_;

    $Param{RoleID} = delete $Param{ClassID} if $Param{ClassID} && !$Param{RoleID};

    return $Self->DefinitionAdd(%Param);
}

sub ServiceSupportConditionList {
    my ( $Self, %Param ) = @_;

    my $Condition = $Kernel::OM->Get('Kernel::Config')->Get('GovernanceDB::ServiceSupportMap::Condition') || {};

    return $Condition if ref $Condition eq 'ARRAY';

    if ( ref $Condition eq 'HASH' ) {
        return [
            map {
                {
                    MapField    => $_,
                    TicketField => $Condition->{$_},
                }
            }
                sort keys %{$Condition}
        ];
    }

    return [];
}

sub ServiceSupportConditionMatch {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(MapObject Ticket)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    CONDITION:
    for my $Condition ( @{ $Self->ServiceSupportConditionList() } ) {
        next CONDITION if !$Condition->{MapField} || !$Condition->{TicketField};

        my $MapValue = $Self->_FieldValueGet(
            Object => $Param{MapObject},
            Field  => $Condition->{MapField},
        );
        my $TicketValue = $Self->_FieldValueGet(
            Object => $Param{Ticket},
            Field  => $Condition->{TicketField},
        );

        next CONDITION if !$MapValue;
        return if !$TicketValue;
        return if $MapValue ne $TicketValue;
    }

    return 1;
}

sub GOIDCreate {
    my ( $Self, %Param ) = @_;

    my $Module = $Kernel::OM->Get('Kernel::Config')->Get('GovernanceDB::NumberGenerator')
        || 'Kernel::System::GovernanceDB::Number::GOID';

    return if !$Kernel::OM->Get('Kernel::System::Main')->Require($Module);

    my $Object = $Module->new();

    return $Object->GOIDCreate(%Param);
}

sub _ClassIDGet {
    my ( $Self, %Param ) = @_;

    my $Class = $Param{Class} || 'StateBook';

    my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
        Class => $Self->_GeneralCatalogClassName(Type => 'Class'),
        Name  => $Class,
    );

    return $Item->{ItemID} if $Item && $Item->{ItemID};

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => "Unknown Governance Object class '$Class'!",
    );

    return;
}

sub _GeneralCatalogClassName {
    my ( $Self, %Param ) = @_;

    my $Classes = $Kernel::OM->Get('Kernel::Config')->Get('GovernanceDB::GeneralCatalogClasses') || {};
    return $Classes->{ $Param{Type} } if $Classes->{ $Param{Type} };

    my %Default = (
        Category      => 'ZTSM::GovernanceObject::Category',
        Class         => 'ZTSM::GovernanceObject::Class',
        ClassCategory => 'ZTSM::GovernanceObject::Class::Category',
        Definition    => 'ZTSM::GovernanceObject::Definition',
        Role          => 'ZTSM::GovernanceObject::Role',
        Status        => 'ZTSM::GovernanceObject::Status',
    );

    return $Default{ $Param{Type} } || 'ZTSM::GovernanceObject::Class';
}

sub _DefinitionTargetLookup {
    my ( $Self, %Param ) = @_;

    return $Self->RoleList( Valid => 1 ) if ( $Param{Type} || '' ) eq 'Role';

    return $Self->ClassList( Valid => 1 );
}

sub _DefinitionTargetList {
    my ( $Self, %Param ) = @_;

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $List = $GeneralCatalogObject->ItemList(
        Class => $Self->_GeneralCatalogClassName( Type => $Param{Type} ),
        Valid => $Param{Valid},
    ) || {};

    my $Defaults = $Self->DefaultDefinitionTargetsGet();
    my %Allowed  = map { $_ => 1 } @{ $Defaults->{ $Param{Type} } || [] };

    return $List if !%Allowed;

    my %Filtered = map {
        my $ID = $_;
        my $Name = $List->{$ID};
        $Allowed{$Name} ? ( $ID => $Name ) : ();
    } sort keys %{$List};

    return \%Filtered;
}

sub DefaultDefinitionTargetsGet {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home') || '.';
    my $File = "$Home/var/governancedb/default_classes.json";

    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $File,
        Mode     => 'utf8',
        DisableWarnings => 1,
    );
    return {} if !$ContentRef;

    my $Data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => ${$ContentRef},
    ) || {};

    return {
        Class => [ map { $_->{Name} } @{ $Data->{Classes} || [] } ],
        Role  => [ map { ref $_ eq 'HASH' ? $_->{Name} : $_ } @{ $Data->{Roles} || [] } ],
    };
}

sub _FieldValueGet {
    my ( $Self, %Param ) = @_;

    my $Object = $Param{Object} || {};
    my $Field  = $Param{Field}  || '';

    return if !$Field;

    my @Candidates = (
        $Field,
        'DynamicField_' . $Field,
    );

    for my $Candidate (@Candidates) {
        return $Object->{$Candidate} if defined $Object->{$Candidate} && $Object->{$Candidate} ne '';
    }

    my $DefinitionData = $Object->{DefinitionData} || $Self->_JSONDecode( Data => $Object->{Definition} );
    if ( $DefinitionData && $DefinitionData->{DynamicFields} ) {
        for my $Candidate (@Candidates) {
            return $DefinitionData->{DynamicFields}->{$Candidate}
                if defined $DefinitionData->{DynamicFields}->{$Candidate}
                && $DefinitionData->{DynamicFields}->{$Candidate} ne '';
        }
    }

    return;
}

sub _JSONDecode {
    my ( $Self, %Param ) = @_;

    return if !$Param{Data};

    my $Data;
    eval {
        $Data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Param{Data},
        );
    };

    return $Data;
}

1;
