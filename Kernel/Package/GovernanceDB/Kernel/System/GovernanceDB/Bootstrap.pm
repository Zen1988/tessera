# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::System::GovernanceDB::Bootstrap;

use strict;
use warnings;
use File::Find ();
use File::Path qw(make_path);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceDB',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Group',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SysConfig',
    'Kernel::System::YAML',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub InstallDefaults {
    my ( $Self, %Param ) = @_;

    my $Defaults = $Self->_DefaultsLoad();
    return if !$Defaults;

    my $GeneralCatalogObject  = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    $Self->_HistoryTypesEnsure();

    my $ClassNamespace       = $Defaults->{ClassNamespace}       || 'ZTSM::GovernanceObject::Class';
    my $RoleNamespace        = $Defaults->{RoleNamespace}        || 'ZTSM::GovernanceObject::Role';
    my $DefinitionNamespace  = $Defaults->{DefinitionNamespace}  || 'ZTSM::GovernanceObject::Definition';
    my $CategoryNamespace    = $Defaults->{CategoryNamespace}    || 'ZTSM::GovernanceObject::Category';
    my $LegacyCategoryNS     = $Defaults->{CompatibilityCategoryNamespace};
    my @CategoryNamespaces   = grep {$_} ( $CategoryNamespace, $LegacyCategoryNS );

    for my $Category ( @{ $Defaults->{Categories} || [] } ) {
        for my $Namespace (@CategoryNamespaces) {
            $Self->_CatalogItemEnsure(
                Class => $Namespace,
                Name  => $Category,
            );
        }
    }

    $Self->_CatalogItemEnsure(
        Class => $DefinitionNamespace,
        Name  => 'ClassDefinition',
    );

    ROLE:
    for my $Role ( @{ $Defaults->{Roles} || [] } ) {
        my $RoleName = ref $Role eq 'HASH' ? $Role->{Name} : $Role;
        next ROLE if !$RoleName;

        my $RoleID = $Self->_CatalogItemEnsure(
            Class => $RoleNamespace,
            Name  => $RoleName,
        );
        next ROLE if !$RoleID;

        next ROLE if ref $Role ne 'HASH' || !$Role->{Definition};

        $Self->_DefinitionEnsure(
            GovernanceObjectObject => $GovernanceObjectObject,
            Type                   => 'Role',
            RoleID     => $RoleID,
            Definition => $Role->{Definition},
            UserID     => 1,
        );
    }

    CLASS:
    for my $Class ( @{ $Defaults->{Classes} || [] } ) {
        next CLASS if !$Class->{Name};

        my $ClassID = $Self->_CatalogItemEnsure(
            Class => $ClassNamespace,
            Name  => $Class->{Name},
        );
        next CLASS if !$ClassID;

        $Self->_ClassPreferencesEnsure(
            ItemID => $ClassID,
            Class  => $Class,
        );

        next CLASS if !$Class->{Definition};

        $Self->_DefinitionEnsure(
            GovernanceObjectObject => $GovernanceObjectObject,
            Type                   => 'Class',
            ClassID    => $ClassID,
            Definition => $Class->{Definition},
            UserID     => 1,
        );
    }

    $Self->_DynamicFieldsEnsure(
        Classes => $Defaults->{Classes} || [],
    );

    $Self->_CustomerUserPreferenceDynamicFieldsEnsure();

    $Self->_TicketRuntimeDynamicFieldsEnsure();

    $Self->_TicketReferenceDynamicFieldsRepair(
        Classes => $Defaults->{Classes} || [],
    );

    $Self->_ConfigItemsCopyToGovernanceObjects(
        Classes => $Defaults->{Classes} || [],
    );

    $Self->_TicketReferenceValuesRepair(
        Classes => $Defaults->{Classes} || [],
    );

    $Self->_RuntimeOverlayInstall();

    $Self->_SysConfigDeploy();

    return 1;
}

sub _DefinitionEnsure {
    my ( $Self, %Param ) = @_;

    my $GovernanceObjectObject = $Param{GovernanceObjectObject};
    my $Definition             = $Param{Definition};
    my $Type                   = $Param{Type} || 'Class';

    return if !$GovernanceObjectObject || !$Definition;

    my %GetParam;
    my %AddParam = (
        Definition => $Definition,
        UserID     => $Param{UserID} || 1,
    );

    if ( $Type eq 'Role' ) {
        return if !$Param{RoleID};

        %GetParam = ( RoleID => $Param{RoleID} );
        $AddParam{RoleID} = $Param{RoleID};
    }
    else {
        return if !$Param{ClassID};

        %GetParam = ( ClassID => $Param{ClassID} );
        $AddParam{ClassID} = $Param{ClassID};
    }

    my $CurrentDefinition = $Type eq 'Role'
        ? $GovernanceObjectObject->RoleDefinitionGet(%GetParam)
        : $GovernanceObjectObject->DefinitionGet(%GetParam);

    if ( $CurrentDefinition && $CurrentDefinition->{DefinitionID} ) {
        my $Current = $Self->_DefinitionNormalize( $CurrentDefinition->{Definition} || '' );
        my $Wanted  = $Self->_DefinitionNormalize($Definition);

        return 1 if $Current eq $Wanted;

        $AddParam{Force} = 1;
    }

    my $Result = $Type eq 'Role'
        ? $GovernanceObjectObject->RoleDefinitionAdd(%AddParam)
        : $GovernanceObjectObject->DefinitionAdd(%AddParam);

    if ( $Result && $Result->{Success} ) {
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
            Type => 'GovernanceObjectDefinition',
        );
    }

    return $Result && $Result->{Success};
}

sub _DefinitionNormalize {
    my ( $Self, $Definition ) = @_;

    $Definition ||= '';
    $Definition =~ s{\r\n}{\n}xmsg;
    $Definition =~ s{\r}{\n}xmsg;
    $Definition =~ s{\s+\z}{}xms;

    return $Definition;
}

sub _RuntimeOverlayInstall {
    my ( $Self, %Param ) = @_;

    my $Home      = $Kernel::OM->Get('Kernel::Config')->Get('Home') || '.';
    my $SourceDir = "$Home/var/governancedb/runtime_overlay";

    return 1 if !-d $SourceDir;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    File::Find::find(
        {
            wanted => sub {
                return if !-f $File::Find::name;

                my $Source = $File::Find::name;
                my $Target = $Source;
                $Target =~ s{\A\Q$SourceDir\E[\\/]}{}xms;
                $Target = "$Home/$Target";

                my $TargetDir = $Target;
                $TargetDir =~ s{[\\/][^\\/]+\z}{};

                if ( !-d $TargetDir ) {
                    make_path($TargetDir);
                }

                open my $SourceFH, '<:raw', $Source or do {
                    $LogObject->Log(
                        Priority => 'error',
                        Message  => "GovernanceDB runtime overlay could not read $Source: $!",
                    );
                    return;
                };
                local $/;
                my $Content = <$SourceFH>;
                close $SourceFH;

                open my $TargetFH, '>:raw', $Target or do {
                    $LogObject->Log(
                        Priority => 'error',
                        Message  => "GovernanceDB runtime overlay could not write $Target: $!",
                    );
                    return;
                };
                print {$TargetFH} $Content;
                close $TargetFH;

                return;
            },
            no_chdir => 1,
        },
        $SourceDir,
    );

    return 1;
}

sub _TicketReferenceValuesRepair {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject      = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $ConfigItemObject        = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GovernanceObjectObject  = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $DBObject                = $Kernel::OM->Get('Kernel::System::DB');

    my %FieldNames = map { $_ => 1 } qw(
        ZTicket-Application
        ZTicket-ApprovalModel
        ZTicket-BlueBook
        ZTicket-Env
        ZTicket-Location
        ZTicket-OwnerGroup
        ZTicket-Profile
        ZTicket-Role
        ZTicket-StateBook
        ZFirewall-DstSystem
        ZFirewall-Env
        ZFirewall-SrcSystem
        ZTSMSupportAssignment-SupportProfile
        ZTSMServiceSupportMap-Application
        ZTSMServiceSupportMap-Environment
        ZTSMServiceSupportMap-Location
    );

    for my $Class ( @{ $Param{Classes} || [] } ) {
        FIELD:
        for my $FieldName ( keys %{ $Class->{DynamicFields} || {} } ) {
            my $Field = $Class->{DynamicFields}{$FieldName};
            next FIELD if ref $Field ne 'HASH';
            next FIELD if ( $Field->{FieldType} || '' ) ne 'GovernanceObject';

            $FieldNames{ $Field->{Name} || $FieldName } = 1;
        }
    }

    FIELD:
    for my $FieldName ( sort keys %FieldNames ) {
        my $Field = $DynamicFieldObject->DynamicFieldGet( Name => $FieldName );
        next FIELD if !$Field || !$Field->{ID};

        return if !$DBObject->Prepare(
            SQL => <<'END_SQL',
SELECT id, value_int
  FROM dynamic_field_value
  WHERE field_id = ?
    AND value_int IS NOT NULL
END_SQL
            Bind => [ \$Field->{ID} ],
        );

        my @ValueRows;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            push @ValueRows, {
                ID            => $Row[0],
                ConfigItemID  => $Row[1],
            };
        }

        VALUE:
        for my $ValueRow (@ValueRows) {
            next VALUE if !$ValueRow->{ConfigItemID};

            my $ExistingGovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $ValueRow->{ConfigItemID},
                Silent             => 1,
            );
            next VALUE if $ExistingGovernanceObject && $ExistingGovernanceObject->{GovernanceObjectID};

            my $ConfigItem = $ConfigItemObject->ConfigItemGet(
                ConfigItemID => $ValueRow->{ConfigItemID},
                Silent       => 1,
            );
            next VALUE if !$ConfigItem || !$ConfigItem->{Number};

            my $GovernanceObjectID = $GovernanceObjectObject->GovernanceObjectLookup(
                GOID => $ConfigItem->{Number},
            );
            next VALUE if !$GovernanceObjectID;
            next VALUE if $GovernanceObjectID == $ValueRow->{ConfigItemID};

            $DBObject->Do(
                SQL  => 'UPDATE dynamic_field_value SET value_int = ? WHERE id = ?',
                Bind => [ \$GovernanceObjectID, \$ValueRow->{ID} ],
            );
        }
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'DynamicFieldValue',
    );

    return 1;
}

sub _TicketReferenceDynamicFieldsRepair {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my $ClassID2Name = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
    ) || {};

    my %ClassNameLookup;
    for my $Class ( @{ $Param{Classes} || [] } ) {
        next if ref $Class ne 'HASH' || !$Class->{Name};

        my ($ClassID) = grep { ( $ClassID2Name->{$_} || '' ) eq $Class->{Name} } keys %{$ClassID2Name};
        next if !$ClassID;

        $ClassNameLookup{ $Self->_ClassNameNormalize( $Class->{Name} ) } = $ClassID;
    }

    my %TicketReferenceFields = (
        'ZTicket-Application'    => ['Application'],
        'ZTicket-ApprovalModel' => ['Approval Model'],
        'ZTicket-BlueBook'      => ['BlueBook'],
        'ZTicket-Env'           => ['Environment'],
        'ZTicket-Location'      => ['Location'],
        'ZTicket-OwnerGroup'    => ['Support Profile'],
        'ZTicket-Profile'       => [ 'Governance Role', 'Support Profile' ],
        'ZTicket-Role'          => ['Governance Role'],
        'ZTicket-StateBook'     => ['StateBook'],
        'ZFirewall-DstSystem'   => [ 'Application', 'Location' ],
        'ZFirewall-Env'         => ['Environment'],
        'ZFirewall-SrcSystem'   => [ 'Application', 'Location' ],
    );

    FIELD:
    for my $FieldName ( sort keys %TicketReferenceFields ) {
        my $Field = $DynamicFieldObject->DynamicFieldGet( Name => $FieldName );
        next FIELD if !$Field || ref $Field ne 'HASH';
        next FIELD if ( $Field->{ObjectType} || '' ) ne 'Ticket';

        my @ClassIDs;
        for my $ClassName ( @{ $TicketReferenceFields{$FieldName} } ) {
            my $GovernanceClassID = $ClassNameLookup{ $Self->_ClassNameNormalize($ClassName) };
            push @ClassIDs, $GovernanceClassID if $GovernanceClassID;
        }

        my %Config = %{ $Field->{Config} || {} };
        $Config{ClassIDs}             = \@ClassIDs;
        $Config{ReferencedObjectType} = 'GovernanceObject';
        $Config{DisplayType}          ||= '';
        $Config{EditFieldMode}        ||= 'Dropdown';
        $Config{LinkDirection}        ||= 'ReferencingIsSource';
        $Config{MultiValue}           ||= '0';
        $Config{Multiselect}          ||= '0';
        $Config{PossibleNone}         = exists $Config{PossibleNone} ? $Config{PossibleNone} : '1';
        $Config{ReferenceFilterList}  ||= [];
        delete $Config{DeplStateIDs};

        my $Updated = $Self->_DynamicFieldUpdateForce(
            ID         => $Field->{ID},
            Name       => $Field->{Name},
            Label      => $Field->{Label},
            FieldOrder => $Field->{FieldOrder},
            FieldType  => 'GovernanceObject',
            ObjectType => 'Ticket',
            Config     => \%Config,
            ValidID    => $Field->{ValidID} || 1,
            UserID     => 1,
            Reorder    => 0,
        );

        if ( !$Updated ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "GovernanceDB bootstrap could not repair ticket dynamic field $FieldName to GovernanceObject.",
            );
        }
    }

    $DynamicFieldObject->EventHandlerTransaction();

    return 1;
}

sub _ConfigItemsCopyToGovernanceObjects {
    my ( $Self, %Param ) = @_;

    my $GeneralCatalogObject   = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ConfigItemObject       = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    my %GovernanceClassByName = reverse %{ $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
    ) || {} };
    return if !%GovernanceClassByName;

    my %GovernanceClassByNormalizedName = map {
        $Self->_ClassNameNormalize($_) => {
            Name => $_,
            ID   => $GovernanceClassByName{$_},
        }
    } keys %GovernanceClassByName;

    my %ConfigItemClassByName = reverse %{ $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    ) || {} };

    my %StatusByName = reverse %{ $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::GovernanceObject::Status',
    ) || {} };
    my $DefaultStatusID = $StatusByName{Active} || $StatusByName{Draft} || ( values %StatusByName )[0];
    return if !$DefaultStatusID;

    CLASS:
    for my $ConfigItemClassName ( sort keys %ConfigItemClassByName ) {
        my $GovernanceClass = $GovernanceClassByNormalizedName{ $Self->_ClassNameNormalize($ConfigItemClassName) };
        next CLASS if !$GovernanceClass || !$GovernanceClass->{ID};

        my @ConfigItemIDs = $ConfigItemObject->ConfigItemSearch(
            Classes => [$ConfigItemClassName],
            Result  => 'ARRAY',
            Limit   => 100000,
        );
        next CLASS if !@ConfigItemIDs;

        CONFIGITEM:
        for my $ConfigItemID (@ConfigItemIDs) {
            my $ConfigItem = $ConfigItemObject->ConfigItemGet(
                ConfigItemID  => $ConfigItemID,
                DynamicFields => 1,
                Silent        => 1,
            );
            next CONFIGITEM if !$ConfigItem || ref $ConfigItem ne 'HASH';
            next CONFIGITEM if !$ConfigItem->{Number};

            my $ExistingID = $GovernanceObjectObject->GovernanceObjectLookup(
                GOID => $ConfigItem->{Number},
            );
            next CONFIGITEM if $ExistingID;

            my %DynamicFieldParam;
            KEY:
            for my $Key ( sort keys %{$ConfigItem} ) {
                next KEY if $Key !~ m{\A DynamicField_}xms;
                $DynamicFieldParam{$Key} = $ConfigItem->{$Key};
            }

            my $ZTSMStatusID = $DefaultStatusID;
            if ( $ConfigItem->{'DynamicField_ZTSM-Status'} && $StatusByName{ $ConfigItem->{'DynamicField_ZTSM-Status'} } ) {
                $ZTSMStatusID = $StatusByName{ $ConfigItem->{'DynamicField_ZTSM-Status'} };
            }

            my $GovernanceObjectID = $GovernanceObjectObject->GovernanceObjectAdd(
                ClassID      => $GovernanceClass->{ID},
                ZTSMStatusID => $ZTSMStatusID,
                Number       => $ConfigItem->{Number},
                Name         => $ConfigItem->{Name} || $ConfigItem->{Number},
                Description  => $ConfigItem->{Description} || '',
                %DynamicFieldParam,
                UserID       => 1,
            );

            if ( !$GovernanceObjectID ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "GovernanceDB bootstrap could not copy ConfigItemID $ConfigItemID to GovernanceObject.",
                );
            }
        }
    }

    return 1;
}

sub _DynamicFieldUpdateForce {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $Updated = $DynamicFieldObject->DynamicFieldUpdate(%Param);
    return 1 if $Updated;

    my $Config = $Kernel::OM->Get('Kernel::System::YAML')->Dump(
        Data => $Param{Config} || {},
    );

    my $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE dynamic_field SET name = ?, label = ?, field_order = ?, field_type = ?, '
            . 'object_type = ?, config = ?, valid_id = ?, change_time = current_timestamp, '
            . 'change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Label}, \$Param{FieldOrder}, \$Param{FieldType},
            \$Param{ObjectType}, \$Config, \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "GovernanceDB bootstrap could not force-update dynamic field $Param{Name}.",
        );
        return;
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'DynamicField',
    );
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'DynamicFieldValue',
    );

    return 1;
}

sub _ClassNameNormalize {
    my ( $Self, $Name ) = @_;

    $Name //= '';
    $Name =~ s{\s+}{}g;
    return lc $Name;
}

sub _DefaultsLoad {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home') || '.';
    my $File = "$Home/var/governancedb/default_classes.json";

    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $File,
        Mode     => 'utf8',
    );
    if ( !$ContentRef ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "GovernanceDB default class seed file not found: $File",
        );
        return;
    }

    return $Kernel::OM->Get('Kernel::System::JSON')->Decode(
        Data => ${$ContentRef},
    );
}

sub _CatalogItemEnsure {
    my ( $Self, %Param ) = @_;

    return if !$Param{Class} || !defined $Param{Name} || $Param{Name} eq '';

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my $ItemID2Name = $GeneralCatalogObject->ItemList(
        Class => $Param{Class},
        Valid => 0,
    );
    for my $ItemID ( sort keys %{ $ItemID2Name || {} } ) {
        return $ItemID if $ItemID2Name->{$ItemID} eq $Param{Name};
    }

    my $ItemID = $GeneralCatalogObject->ItemAdd(
        Class   => $Param{Class},
        Name    => $Param{Name},
        ValidID => 1,
        UserID  => 1,
    );
    return $ItemID if $ItemID;

    # ItemAdd can return false when another install/upgrade already created the item.
    # Re-read the catalog so package upgrades stay idempotent and do not fail on duplicates.
    $ItemID2Name = $GeneralCatalogObject->ItemList(
        Class => $Param{Class},
        Valid => 0,
    );
    for my $ExistingItemID ( sort keys %{ $ItemID2Name || {} } ) {
        return $ExistingItemID if $ItemID2Name->{$ExistingItemID} eq $Param{Name};
    }

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => "Could not ensure GovernanceDB catalog item '$Param{Name}' in class '$Param{Class}'.",
    );

    return;
}

sub _HistoryTypesEnsure {
    my ($Self) = @_;

    my @HistoryTypes = qw(
        GovernanceObjectCreate
        LinkAdd
        LinkDelete
        NameUpdate
        IncidentStateUpdate
        DeploymentStateUpdate
        DefinitionUpdate
        VersionCreate
        VersionDelete
        AttachmentAddPost
        AttachmentDeletePost
        ValueUpdate
    );

    HISTORYTYPE:
    for my $HistoryType (@HistoryTypes) {
        next HISTORYTYPE if !$HistoryType;

        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
        return if !$DBObject->Prepare(
            SQL   => 'SELECT id FROM governance_object_item_history_type WHERE name = ?',
            Bind  => [ \$HistoryType ],
            Limit => 1,
        );

        my $HistoryTypeID;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $HistoryTypeID = $Row[0];
        }
        next HISTORYTYPE if $HistoryTypeID;

        my $Comment = "$HistoryType history entry.";
        return if !$DBObject->Do(
            SQL => 'INSERT INTO governance_object_item_history_type '
                . '(name, comments, valid_id, create_time, create_by, change_time, change_by) '
                . 'VALUES (?, ?, 1, current_timestamp, 1, current_timestamp, 1)',
            Bind => [
                \$HistoryType,
                \$Comment,
            ],
        );
    }

    return 1;
}

sub _ClassPreferencesEnsure {
    my ( $Self, %Param ) = @_;

    my $Class = $Param{Class} || {};
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my %Preferences = $GeneralCatalogObject->GeneralCatalogPreferencesGet(
        ItemID => $Param{ItemID},
    );

    my @PermissionGroups = grep {$_} (
        'admin',
        'governance-db',
        $Class->{PermissionGroup},
        ref $Class->{PermissionGroups} eq 'ARRAY' ? $Class->{PermissionGroups}->@* : (),
    );
    my %PermissionGroupSeen;
    @PermissionGroups = grep { !$PermissionGroupSeen{$_}++ } @PermissionGroups;

    my @GroupIDs;
    for my $Group (@PermissionGroups) {
        my $GroupID = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup(
            Group => $Group,
        );
        push @GroupIDs, $GroupID if $GroupID;
    }

    my %Wanted = (
        Categories          => $Class->{Category} ? [ $Class->{Category} ] : undef,
        NumberModule        => $Class->{NumberModule} ? [ $Class->{NumberModule} ] : ['GOID'],
        VersionStringModule => $Class->{VersionStringModule} ? [ $Class->{VersionStringModule} ] : ['Incremental'],
        VersionTrigger      => [ qw(Name Description DefinitionUpdate) ],
        Permission          => @GroupIDs ? \@GroupIDs : undef,
    );

    KEY:
    for my $Key ( sort keys %Wanted ) {
        next KEY if !$Wanted{$Key};
        if ( $Key eq 'Permission' ) {
            my @Existing = ref $Preferences{$Key} eq 'ARRAY'
                ? @{ $Preferences{$Key} }
                : grep {$_} ( $Preferences{$Key} );

            my %Existing = map { $_ => 1 } @Existing;
            my @Merged = ( @Existing, grep { !$Existing{$_}++ } @{ $Wanted{$Key} } );
            next KEY if @Existing && @Merged == @Existing;

            $GeneralCatalogObject->GeneralCatalogPreferencesSet(
                ItemID => $Param{ItemID},
                Key    => $Key,
                Value  => \@Merged,
            );
            next KEY;
        }

        next KEY if $Preferences{$Key};

        $GeneralCatalogObject->GeneralCatalogPreferencesSet(
            ItemID => $Param{ItemID},
            Key    => $Key,
            Value  => $Wanted{$Key},
        );
    }

    return 1;
}

sub _DynamicFieldsEnsure {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my $ClassID2Name = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
    ) || {};

    my %AllowedClasses;
    for my $Class ( @{ $Param{Classes} || [] } ) {
        next if !$Class->{Name};

        my ($ClassID) = grep { ( $ClassID2Name->{$_} || '' ) eq $Class->{Name} } keys %{$ClassID2Name};
        next if !$ClassID;

        $AllowedClasses{$ClassID} = $ClassID;
        $AllowedClasses{ $Class->{Name} } = $ClassID;
        $AllowedClasses{ $Self->_ClassNameNormalize( $Class->{Name} ) } = $ClassID;
    }

    my %Fields;
    for my $Class ( @{ $Param{Classes} || [] } ) {
        for my $Name ( keys %{ $Class->{DynamicFields} || {} } ) {
            $Self->_DynamicFieldCollect(
                Fields => \%Fields,
                Name   => $Name,
                Field  => $Class->{DynamicFields}{$Name},
            );
        }
    }

    my $Order = 10000;
    FIELD:
    for my $Name ( sort keys %Fields ) {
        my $Field = $Fields{$Name};
        next FIELD if ref $Field ne 'HASH';
        next FIELD if $Self->_OfficialField($Name);

        my $Config = $Self->_DynamicFieldConfigSanitize(
            Config         => $Field->{Config} || {},
            AllowedClasses => \%AllowedClasses,
        );
        if ( $Field->{FieldType} && $Field->{FieldType} eq 'Set' && ref $Config->{Include} eq 'ARRAY' ) {
            $Config = {
                %{$Config},
                Include => [
                    map {
                        {
                            DF => $_->{DF},
                        }
                    } @{ $Config->{Include} },
                ],
            };
        }

        my $FieldName = $Field->{Name} || $Name;
        my $Label     = $Field->{Label} || $Field->{Name} || $Name;
        my $FieldType = $Field->{FieldType} || 'Text';
        my $Existing  = $DynamicFieldObject->DynamicFieldGet( Name => $FieldName );

        if ($Existing) {
            my $CurrentConfig = $Self->_DynamicFieldConfigSanitize(
                Config         => $Existing->{Config} || {},
                AllowedClasses => \%AllowedClasses,
            );
            my $NeedsClassIDRepair = $Self->_DynamicFieldClassIDsNeedRepair(
                Config       => $Existing->{Config} || {},
                WantedConfig => $Config,
            );

            next FIELD if !$NeedsClassIDRepair && $Self->_DynamicFieldConfigEqual(
                Left  => {
                    Name       => $Existing->{Name},
                    Label      => $Existing->{Label},
                    FieldType  => $Existing->{FieldType},
                    ObjectType => $Existing->{ObjectType},
                    Config     => $CurrentConfig,
                },
                Right => {
                    Name       => $FieldName,
                    Label      => $Label,
                    FieldType  => $FieldType,
                    ObjectType => 'GovernanceObject',
                    Config     => $Config,
                },
            );

            $Self->_DynamicFieldUpdateForce(
                ID          => $Existing->{ID},
                Name        => $FieldName,
                Label       => $Label,
                FieldOrder  => $Existing->{FieldOrder},
                FieldType   => $FieldType,
                ObjectType  => 'GovernanceObject',
                Config      => $Config,
                ValidID     => $Existing->{ValidID} || 1,
                UserID      => 1,
                Reorder     => 0,
            );
            next FIELD;
        }

        my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
            Name       => $FieldName,
            Label      => $Label,
            FieldOrder => ++$Order,
            FieldType  => $FieldType,
            ObjectType => 'GovernanceObject',
            Config     => $Config,
            ValidID    => 1,
            UserID     => 1,
            Reorder    => 0,
        );

        next FIELD if $FieldID;

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "GovernanceDB bootstrap could not create dynamic field $FieldName.",
        );
    }

    $DynamicFieldObject->EventHandlerTransaction();

    return 1;
}

sub _TicketRuntimeDynamicFieldsEnsure {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $Existing = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZTicket-HoldState',
    );
    return 1 if $Existing && $Existing->{ID};

    my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
        Name       => 'ZTicket-HoldState',
        Label      => 'Requester Hold State',
        FieldOrder => 10100,
        FieldType  => 'Text',
        ObjectType => 'Ticket',
        Config     => {
            DefaultValue => '',
            Link         => '',
            LinkPreview  => '',
            MultiValue   => 0,
            RegExList    => [],
            Tooltip      => 'Stores the previous ticket state while requester hold is active.',
        },
        ValidID => 1,
        UserID  => 1,
        Reorder => 0,
    );

    if ( !$FieldID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'GovernanceDB bootstrap could not create dynamic field ZTicket-HoldState.',
        );
        return;
    }

    $DynamicFieldObject->EventHandlerTransaction();

    return 1;
}

sub _CustomerUserPreferenceDynamicFieldsEnsure {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my $ClassID2Name = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
    ) || {};
    my %ClassName2ID = map { $ClassID2Name->{$_} => $_ } keys %{$ClassID2Name};

    my @Fields = (
        {
            Name       => 'ZUser-Location',
            Label      => 'Ticket Location',
            FieldOrder => 10200,
            Classes    => ['Location'],
        },
        {
            Name       => 'ZUser-Application',
            Label      => 'Application System',
            FieldOrder => 10201,
            Classes    => ['Application'],
        },
        {
            Name       => 'ZUser-Environment',
            Label      => 'Environment',
            FieldOrder => 10202,
            Classes    => ['Environment'],
        },
        {
            Name       => 'ZUser-SupportProfile',
            Label      => 'Support Profile',
            FieldOrder => 10203,
            Classes    => ['SupportProfile'],
        },
    );

    FIELD:
    for my $Field (@Fields) {
        my @ClassIDs = grep {$_} map { $ClassName2ID{$_} } @{ $Field->{Classes} || [] };
        my $Config = {
            ClassIDs     => \@ClassIDs,
            DisplayType  => 'GovernanceObjectName',
            DefaultValue => '',
            Link         => '',
            LinkPreview  => '',
            MultiValue   => 0,
            Tooltip      => '',
        };

        my $Existing = $DynamicFieldObject->DynamicFieldGet( Name => $Field->{Name} );
        if ($Existing) {
            my $CurrentConfig = $Self->_DynamicFieldConfigSanitize(
                Config         => $Existing->{Config} || {},
                AllowedClasses => { map { $_ => $_ } @ClassIDs },
            );
            my $NeedsClassIDRepair = $Self->_DynamicFieldClassIDsNeedRepair(
                Config       => $Existing->{Config} || {},
                WantedConfig => $Config,
            );

            next FIELD if !$NeedsClassIDRepair && $Self->_DynamicFieldConfigEqual(
                Left  => {
                    Name       => $Existing->{Name},
                    Label      => $Existing->{Label},
                    FieldType  => $Existing->{FieldType},
                    ObjectType => $Existing->{ObjectType},
                    Config     => $CurrentConfig,
                },
                Right => {
                    Name       => $Field->{Name},
                    Label      => $Field->{Label},
                    FieldType  => 'GovernanceObject',
                    ObjectType => 'CustomerUser',
                    Config     => $Config,
                },
            );

            $Self->_DynamicFieldUpdateForce(
                ID          => $Existing->{ID},
                Name        => $Field->{Name},
                Label       => $Field->{Label},
                FieldOrder  => $Existing->{FieldOrder} || $Field->{FieldOrder},
                FieldType   => 'GovernanceObject',
                ObjectType  => 'CustomerUser',
                Config      => $Config,
                ValidID     => $Existing->{ValidID} || 1,
                UserID      => 1,
                Reorder     => 0,
            );
            next FIELD;
        }

        my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
            Name       => $Field->{Name},
            Label      => $Field->{Label},
            FieldOrder => $Field->{FieldOrder},
            FieldType  => 'GovernanceObject',
            ObjectType => 'CustomerUser',
            Config     => $Config,
            ValidID    => 1,
            UserID     => 1,
            Reorder    => 0,
        );

        next FIELD if $FieldID;

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "GovernanceDB bootstrap could not create dynamic field $Field->{Name}.",
        );
    }

    $DynamicFieldObject->EventHandlerTransaction();

    return 1;
}

sub _DynamicFieldCollect {
    my ( $Self, %Param ) = @_;

    my $Fields = $Param{Fields} || {};
    my $Field  = $Param{Field};
    my $Name   = $Param{Name};

    return if !$Name || ref $Field ne 'HASH';

    $Fields->{$Name} = $Field;

    my $Include = $Field->{Config}{Include};
    return if ref $Include ne 'ARRAY';

    for my $IncludedField ( @{$Include} ) {
        next if ref $IncludedField ne 'HASH';
        next if !$IncludedField->{DF} || ref $IncludedField->{Definition} ne 'HASH';

        $Self->_DynamicFieldCollect(
            Fields => $Fields,
            Name   => $IncludedField->{DF},
            Field  => $IncludedField->{Definition},
        );
    }

    return 1;
}

sub _OfficialField {
    my ( $Self, $Name ) = @_;

    return if !$Name;

    my %Official = map { $_ => 1 } qw(
        GOID
        ZTSM-Code
        ZTSM-Status
        Name
        Description
    );

    return $Official{$Name};
}

sub _DynamicFieldConfigSanitize {
    my ( $Self, %Param ) = @_;

    my $Config         = $Param{Config} || {};
    my $AllowedClasses = $Param{AllowedClasses} || {};
    my %Sanitized      = %{$Config};

    delete $Sanitized{DeplStateIDs};

    if ( ref $Sanitized{ClassIDs} eq 'ARRAY' ) {
        my @ClassIDs;
        my %Seen;
        for my $ClassID ( @{ $Sanitized{ClassIDs} } ) {
            my $ResolvedClassID = $AllowedClasses->{$ClassID}
                || $AllowedClasses->{ $Self->_ClassNameNormalize($ClassID) };

            if ( !$ResolvedClassID && $ClassID =~ m{\A\d+\z} ) {
                $ResolvedClassID = $ClassID;
            }

            next if !$ResolvedClassID;
            next if $Seen{$ResolvedClassID}++;
            push @ClassIDs, $ResolvedClassID;
        }
        $Sanitized{ClassIDs} = \@ClassIDs;
    }

    return \%Sanitized;
}

sub _DynamicFieldClassIDsNeedRepair {
    my ( $Self, %Param ) = @_;

    my $Config       = $Param{Config}       || {};
    my $WantedConfig = $Param{WantedConfig} || {};

    if ( ref $WantedConfig->{ClassIDs} eq 'ARRAY' && @{ $WantedConfig->{ClassIDs} } ) {
        return 1 if ref $Config->{ClassIDs} ne 'ARRAY';
        return 1 if !@{ $Config->{ClassIDs} };

        my %Wanted = map { $_ => 1 } @{ $WantedConfig->{ClassIDs} };
        for my $ClassID ( @{ $Config->{ClassIDs} } ) {
            return 1 if !$Wanted{$ClassID};
        }
        return 1 if @{ $Config->{ClassIDs} } != @{ $WantedConfig->{ClassIDs} };
    }

    return if ref $Config->{ClassIDs} ne 'ARRAY';

    for my $ClassID ( @{ $Config->{ClassIDs} } ) {
        return 1 if !defined $ClassID || $ClassID !~ m{\A\d+\z};
    }

    return;
}

sub _DynamicFieldConfigEqual {
    my ( $Self, %Param ) = @_;

    my $JSON = $Kernel::OM->Get('Kernel::System::JSON');

    my $Left = $JSON->Encode( Data => $Param{Left} );
    my $Right = $JSON->Encode( Data => $Param{Right} );

    return defined $Left && defined $Right && $Left eq $Right;
}

sub _SysConfigDeploy {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

    $Self->_DynamicFieldDriverObjectTypeEnsure(
        Driver     => 'Service',
        ObjectType => 'GovernanceObject',
    );
    $Self->_DynamicFieldDriverObjectTypeEnsure(
        Driver     => 'Set',
        ObjectType => 'GovernanceObject',
    );

    my @DirtySettings   = (
        'DynamicFields::ObjectType###GovernanceObject',
        'DynamicFieldScreens###GovernanceDB',
        'DefaultColumnsScreens###GovernanceDB',
        'DynamicFieldScreens::ObjectTypes###GovernanceDB',
        'DynamicFields::Driver###Ticket',
        'DynamicFields::Driver###Agent',
        'DynamicFields::Driver###CustomerCompany',
        'DynamicFields::Driver###CustomerUser',
        'DynamicFields::Driver###Service',
        'DynamicFields::Driver###Set',
        'DynamicFields::Driver###GovernanceObject',
        'DynamicFields::Driver###GovernanceObjectVersion',
        'GovernanceObject::Frontend::AgentGovernanceObject###DefaultCategory',
        'GovernanceObject::Frontend::AgentGovernanceObject###DefaultColumns',
        'GovernanceObject::Frontend::AgentGovernanceObject###ClassColumnsAvailable',
        'GovernanceObject::Frontend::AgentGovernanceObject###ClassColumnsDefault',
        'DynamicFieldScreens###ZTSMGovernanceRuntime',
        'Frontend::Module###AgentTicketDecision',
        'Loader::Module::AgentTicketDecision###003-ZTSMGovernanceRuntime',
        'Ticket::Frontend::MenuModule###420-Decision',
        'Ticket::Frontend::AgentTicketDecision###Permission',
        'Ticket::Frontend::AgentTicketDecision###RequiredLock',
        'Ticket::Frontend::AgentTicketDecision###Note',
        'Ticket::Frontend::AgentTicketDecision###NoteMandatory',
        'Ticket::Frontend::AgentTicketDecision###Subject',
        'Ticket::Frontend::AgentTicketDecision###Body',
        'Ticket::Frontend::AgentTicketDecision###IsVisibleForCustomerDefault',
        'Ticket::Frontend::AgentTicketDecision###FormDraft',
        'Ticket::Frontend::AgentTicketDecision###HistoryType',
        'Ticket::Frontend::AgentTicketDecision###HistoryComment',
        'Ticket::Frontend::AgentTicketDecision###DynamicField',
        'Frontend::Module###AgentTicketQuickClose',
        'Ticket::Frontend::AgentTicketQuickClose###Permission',
        'Ticket::Frontend::MenuModule###430-QuickClose',
        'CustomerTicket::Permission###5-ZTSMUserIDCheck',
        'CustomerFrontend::Module###CustomerTicketZTSMAction',
        'ACLKeysLevel3::Actions###110-ZTSMGovernanceRuntime',
        'CustomerPreferencesGroups###ZTSMRequestDefaults',
    );

    my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
        Comments      => 'GovernanceDB package bootstrap',
        DirtySettings => \@DirtySettings,
        UserID        => 1,
        Force         => 1,
    );

    if ( !$DeploymentResult{Success} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'GovernanceDB could not deploy SysConfig settings.',
        );
        return;
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();

    return 1;
}

sub _DynamicFieldDriverObjectTypeEnsure {
    my ( $Self, %Param ) = @_;

    return if !$Param{Driver};
    return if !$Param{ObjectType};

    my $SettingName     = 'DynamicFields::Driver###' . $Param{Driver};
    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my %Setting         = $SysConfigObject->SettingGet(
        Name => $SettingName,
    );

    return if !%Setting;
    return if ref $Setting{EffectiveValue} ne 'HASH';

    my %EffectiveValue = %{ $Setting{EffectiveValue} };
    my @ObjectTypes    = ref $EffectiveValue{ObjectTypes} eq 'ARRAY'
        ? @{ $EffectiveValue{ObjectTypes} }
        : ();

    my %Seen = map { $_ => 1 } @ObjectTypes;
    return 1 if $Seen{ $Param{ObjectType} };

    push @ObjectTypes, $Param{ObjectType};
    $EffectiveValue{ObjectTypes} = \@ObjectTypes;

    my $Success = $SysConfigObject->SettingsSet(
        Settings => [
            {
                Name           => $SettingName,
                IsValid        => 1,
                EffectiveValue => \%EffectiveValue,
            },
        ],
        Comments => 'GovernanceDB dynamic field driver object type registration',
        UserID   => 1,
    );

    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "GovernanceDB could not update SysConfig setting $SettingName.",
        );
        return;
    }

    return 1;
}

1;
