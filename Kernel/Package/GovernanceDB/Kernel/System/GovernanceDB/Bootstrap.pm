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
    'Kernel::System::GenericAgent',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GeneralCatalog::Document',
    'Kernel::System::GovernanceDB',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Group',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::ProcessManagement::DB::Process',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Service',
    'Kernel::System::State',
    'Kernel::System::SysConfig',
    'Kernel::System::Type',
    'Kernel::System::YAML',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub InstallDefaults {
    my ( $Self, %Param ) = @_;

    $Self->_ActivityTablesEnsure();

    my $Defaults = $Self->_DefaultsLoad();
    return if !$Defaults;

    my $GeneralCatalogObject  = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    $Self->_HistoryTypesEnsure();
    $Self->_GeneralCatalogSeedEnsure();

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

    $Self->_ReferenceDisplayTypesRepair();

    $Self->_ITSMConfigItemLifecycleDateDynamicFieldsEnsure();

    $Self->_ITSMControlDefaultsEnsure();

    $Self->_CustomerUserPreferenceDynamicFieldsEnsure();

    $Self->_TicketRuntimeDynamicFieldsEnsure();

    $Self->_RuntimePrerequisitesEnsure();

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

    $Self->_CustomerBrandingEnsure();

    $Self->_CustomerDashboardEnsure();

    $Self->_CustomerAssetFrontendEnsure();

    $Self->_SysConfigDeploy();

    $Self->_ServiceTicketTypeACLsRebuild();

    return 1;
}

# Upgrade-safe repair for activity tables. A failed 0.1.100 attempt may already
# have created the ConfigItem table, so upgrade metadata must not blindly create
# it again. Fresh installs still use the SOPM DatabaseInstall definitions.
sub _ActivityTablesEnsure {
    my ($Self) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my %Table = map { lc($_) => 1 } $DBObject->ListTables();

    if ( !$Table{ztsm_configitem_activity} ) {
        $DBObject->Do( SQL => <<'END_SQL' );
CREATE TABLE ztsm_configitem_activity (
    id BIGINT NOT NULL AUTO_INCREMENT,
    configitem_id BIGINT NULL,
    configitem_number VARCHAR(100) NULL,
    event_type VARCHAR(100) NOT NULL,
    source VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body LONGBLOB NOT NULL,
    payload LONGBLOB NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    PRIMARY KEY (id),
    INDEX ztsm_configitem_activity_ci (configitem_id)
)
END_SQL
    }
    if ( !$Table{governance_object_activity} ) {
        $DBObject->Do( SQL => <<'END_SQL' );
CREATE TABLE governance_object_activity (
    id BIGINT NOT NULL AUTO_INCREMENT,
    governance_object_id BIGINT NULL,
    object_number VARCHAR(100) NULL,
    event_type VARCHAR(100) NOT NULL,
    source VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body LONGBLOB NOT NULL,
    payload LONGBLOB NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    PRIMARY KEY (id),
    INDEX governance_activity_object (governance_object_id)
)
END_SQL
    }
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

        # Existing definitions may have been customized by the customer. Merge
        # only missing packaged structure; existing values, order, and additions
        # remain authoritative and are never replaced by a reinstall/upgrade.
        my $Merged = $Self->_DefinitionMerge(
            Current => $CurrentDefinition->{Definition} || '',
            Wanted  => $Definition,
        );
        return 1 if !$Merged || $Self->_DefinitionNormalize($Merged) eq $Current;

        $AddParam{Definition} = $Merged;
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

sub _DefinitionMerge {
    my ( $Self, %Param ) = @_;
    my $YAMLObject = $Kernel::OM->Get('Kernel::System::YAML');
    my $Current = $YAMLObject->Load( Data => $Param{Current} );
    my $Wanted  = $YAMLObject->Load( Data => $Param{Wanted} );
    return if ref $Current ne 'HASH' || ref $Wanted ne 'HASH';
    my $Merged = $Self->_StructureMerge( Current => $Current, Wanted => $Wanted );
    return $YAMLObject->Dump( Data => $Merged );
}

sub _StructureMerge {
    my ( $Self, %Param ) = @_;
    my $Current = $Param{Current};
    my $Wanted  = $Param{Wanted};

    if ( ref $Current eq 'HASH' && ref $Wanted eq 'HASH' ) {
        my %Merged = %{$Current};
        for my $Key ( keys %{$Wanted} ) {
            if ( !exists $Merged{$Key} ) { $Merged{$Key} = $Wanted->{$Key}; next }
            $Merged{$Key} = $Self->_StructureMerge( Current => $Merged{$Key}, Wanted => $Wanted->{$Key} );
        }
        return \%Merged;
    }
    if ( ref $Current eq 'ARRAY' && ref $Wanted eq 'ARRAY' ) {
        my @Merged = @{$Current};
        WANTED:
        for my $WantedItem ( @{$Wanted} ) {
            my $Identity = $Self->_ArrayItemIdentity($WantedItem);
            if ( defined $Identity ) {
                for my $Index ( 0 .. $#Merged ) {
                    next if ( $Self->_ArrayItemIdentity( $Merged[$Index] ) // '' ) ne $Identity;
                    $Merged[$Index] = $Self->_StructureMerge( Current => $Merged[$Index], Wanted => $WantedItem );
                    next WANTED;
                }
            }
            else {
                for my $Existing (@Merged) {
                    next WANTED if !ref $Existing && !ref $WantedItem && defined $Existing
                        && defined $WantedItem && $Existing eq $WantedItem;
                }
            }
            push @Merged, $WantedItem;
        }
        return \@Merged;
    }
    return $Current;
}

sub _ArrayItemIdentity {
    my ( $Self, $Item ) = @_;
    return if ref $Item ne 'HASH';
    for my $Key (qw(Name Section DF Header)) {
        return "$Key=$Item->{$Key}" if defined $Item->{$Key} && !ref $Item->{$Key};
    }
    return;
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
                # OTOBO loads framework customizations from Custom before the
                # corresponding core path.  Never overwrite 11.1 framework
                # modules, configuration XML or templates during package
                # installation; keeping these files below Custom allows later
                # framework upgrades to update their own files independently.
                if ( $Target =~ m{\A(?:Kernel|scripts)[\\/]}xms ) {
                    $Target = "$Home/Custom/$Target";
                }
                else {
                    $Target = "$Home/$Target";
                }

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
        'ZTicket-OwnerGroup'    => [ 'Governance Role', 'Support Profile' ],
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

sub _ReferenceDisplayTypesRepair {
    my ($Self) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $List = $DynamicFieldObject->DynamicFieldList(
        Valid      => 0,
        ResultType => 'HASH',
    ) || {};

    for my $Name ( values %{$List} ) {
        my $Field = $DynamicFieldObject->DynamicFieldGet( Name => $Name );
        next if !$Field || ref $Field->{Config} ne 'HASH';

        my %DisplayTypeFor = (
            ConfigItem              => 'ClassConfigItemName',
            ConfigItemVersion       => 'ClassConfigItemName',
            GovernanceObject        => 'ClassGovernanceObjectName',
            GovernanceObjectVersion => 'ClassGovernanceObjectName',
        );
        my $DisplayType = $DisplayTypeFor{ $Field->{FieldType} || '' };
        next if !$DisplayType;
        next if ( $Field->{Config}{DisplayType} || '' ) eq $DisplayType;

        my %Config = ( %{ $Field->{Config} }, DisplayType => $DisplayType );
        $Self->_DynamicFieldUpdateForce(
            %{$Field},
            Config  => \%Config,
            UserID  => 1,
            Reorder => 0,
        );
    }

    $DynamicFieldObject->EventHandlerTransaction();
    return 1;
}

sub _ClassNameNormalize {
    my ( $Self, $Name ) = @_;

    $Name //= '';
    $Name =~ s{\s+}{}g;
    return lc $Name;
}

sub _RuntimePrerequisitesEnsure {
    my ( $Self, %Param ) = @_;

    $Self->_TicketStatesEnsure();
    $Self->_TicketTypesEnsure();
    $Self->_GovernanceRoleObjectsEnsure();
    $Self->_RuntimeProcessesEnsure();
    $Self->_GenericAgentJobsEnsure();

    return 1;
}

sub _ServiceTicketTypeACLsRebuild {
    my ( $Self, %Param ) = @_;

    my $Success = $Kernel::OM->Get('Kernel::System::Service')->UpdateTypServiceACLs(
        UserID => 1,
    );

    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'GovernanceDB bootstrap could not rebuild generated service ticket type ACLs.',
        );
        return;
    }

    return 1;
}

sub _TicketStatesEnsure {
    my ( $Self, %Param ) = @_;

    my @States = (
        { Name => 'approve',                 Type => 'open',             Comment => 'Pending Approval' },
        { Name => 'approved',                Type => 'open',             Comment => 'Approved' },
        { Name => 'assess',                  Type => 'open',             Comment => 'Assessment' },
        { Name => 'closed cancelled',        Type => 'closed',           Comment => 'Cancelled' },
        { Name => 'closed canceled',         Type => 'closed',           Comment => 'Canceled' },
        { Name => 'closed cascaded',         Type => 'closed',           Comment => 'Closed cascaded from parent.' },
        { Name => 'closed cascading',        Type => 'closed',           Comment => 'Closed because parent execution closed.' },
        { Name => 'closed duplicate',        Type => 'closed',           Comment => 'Duplicate Request' },
        { Name => 'closed invalid-info',     Type => 'closed',           Comment => 'Closed because mandatory service information is missing.' },
        { Name => 'closed no action',        Type => 'closed',           Comment => 'No Action Required' },
        { Name => 'closed rejected',         Type => 'closed',           Comment => 'Rejected during approval or assessment.' },
        { Name => 'closed rollback',         Type => 'closed',           Comment => 'Roll back' },
        { Name => 'closed successful',       Type => 'closed',           Comment => 'Ticket is closed successfully.' },
        { Name => 'closed unsuccessful',     Type => 'closed',           Comment => 'Ticket is closed unsuccessfully.' },
        { Name => 'closed with workaround',  Type => 'closed',           Comment => 'Ticket is closed with workaround.' },
        { Name => 'diagnosed',               Type => 'closed',           Comment => 'Diagnosis completed with observed incident evidence.' },
        { Name => 'endorse',                 Type => 'open',             Comment => 'Endorsement' },
        { Name => 'follow-up',               Type => 'open',             Comment => 'Follow Up' },
        { Name => 'in-progress',             Type => 'open',             Comment => 'In Progress' },
        { Name => 'merged',                  Type => 'merged',           Comment => 'State for merged tickets.' },
        { Name => 'new',                     Type => 'new',              Comment => 'New ticket created.' },
        { Name => 'onhold',                  Type => 'open',             Comment => 'On hold' },
        { Name => 'open',                    Type => 'open',             Comment => 'Open tickets.' },
        { Name => 'pending',                 Type => 'open',             Comment => 'Pending Fulfilment' },
        { Name => 'pending auto close+',     Type => 'pending auto',     Comment => 'Ticket is pending auto close positive.' },
        { Name => 'pending auto close-',     Type => 'pending auto',     Comment => 'Ticket is pending auto close negative.' },
        { Name => 'pending reminder',        Type => 'pending reminder', Comment => 'Ticket is pending reminder.' },
        { Name => 'rejected',                Type => 'open',             Comment => 'Rejected' },
        { Name => 'remediate',               Type => 'open',             Comment => 'Remediation' },
        { Name => 'removed',                 Type => 'removed',          Comment => 'Customer removed.' },
        { Name => 'support',                 Type => 'open',             Comment => 'Pending Support' },
        { Name => 'validate',                Type => 'open',             Comment => 'Validate' },
        { Name => 'verify',                  Type => 'open',             Comment => 'Verification' },
    );

    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    STATE:
    for my $State (@States) {
        my $TypeID = $StateObject->StateTypeLookup(
            StateType => $State->{Type},
        );
        if ( !$TypeID ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "GovernanceDB bootstrap could not resolve state type '$State->{Type}' for '$State->{Name}'.",
            );
            next STATE;
        }

        my $StateID = $StateObject->StateLookup(
            State => $State->{Name},
        );
        if ($StateID) {
            my %Current = $StateObject->StateGet(
                ID => $StateID,
            );
            next STATE
                if ( $Current{ValidID} || 0 ) == 1
                && ( $Current{TypeID} || 0 ) == $TypeID
                && ( $Current{Comment} || '' ) eq $State->{Comment};

            $StateObject->StateUpdate(
                ID      => $StateID,
                Name    => $State->{Name},
                ValidID => 1,
                TypeID  => $TypeID,
                Comment => $State->{Comment},
                UserID  => 1,
            );
            next STATE;
        }

        $StateObject->StateAdd(
            Name    => $State->{Name},
            ValidID => 1,
            TypeID  => $TypeID,
            Comment => $State->{Comment},
            UserID  => 1,
        );
    }

    return 1;
}

sub _TicketTypesEnsure {
    my ( $Self, %Param ) = @_;

    my @Types = qw(
        Approval
        Assessment
        Change
        Change::Major
        Diagnosis
        Endorsement
        Implementation
        Incident
        Incident::Major
        Problem
        ServiceRequest
        Task
        Unclassified
        Verification
    );

    my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

    TYPE:
    for my $Type (@Types) {
        my $TypeID = $TypeObject->TypeLookup(
            Type => $Type,
        );
        if ($TypeID) {
            my %Current = $TypeObject->TypeGet(
                ID => $TypeID,
            );
            next TYPE if ( $Current{ValidID} || 0 ) == 1;

            $TypeObject->TypeUpdate(
                ID      => $TypeID,
                Name    => $Type,
                ValidID => 1,
                UserID  => 1,
            );
            next TYPE;
        }

        $TypeObject->TypeAdd(
            Name    => $Type,
            ValidID => 1,
            UserID  => 1,
        );
    }

    return 1;
}

sub _GovernanceRoleObjectsEnsure {
    my ( $Self, %Param ) = @_;

    my @Roles = qw(
        REQUESTER
        REQUESTER-DEFAULT
        REQUESTER-SUPPORT-GROUP
        DIAGNOSE
        ASSESSOR
        ENDORSER
        APPROVER
        IMPLEMENTER
        VERIFIER
        SUPPORT
        ASSET
        ESCALATION
    );

    my $GeneralCatalogObject   = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    my %ClassByName = reverse %{ $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
    ) || {} };
    my $ClassID = $ClassByName{GovernanceRole} || $ClassByName{'Governance Role'};
    return if !$ClassID;

    my %StatusByName = reverse %{ $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::GovernanceObject::Status',
    ) || {} };
    my $StatusID = $StatusByName{Active} || $StatusByName{Approved} || $StatusByName{Draft};
    return if !$StatusID;

    my $RequesterScript = <<'END_REQUESTER_SCRIPT';
---
SCRIPT: Resolve Requester Governance Role
VERSION: 1
RETURN:
  IF:
    VALUE: TICKET.CustomerUser.ZUser-SupportProfile
    IS NOT EMPTY: true
  THEN:
    VALUE: TICKET.CustomerUser.ZUser-SupportProfile
    AS: GovernanceObject.SupportProfile
  ELSE:
    VALUE: TICKET.CustomerUser
    AS: CustomerUser
END_REQUESTER_SCRIPT

    my $DynamicResolverScript = <<'END_DYNAMIC_RESOLVER_SCRIPT';
---
SCRIPT: Resolve Dynamic Governance Role
VERSION: 1
SEARCH:
  FOR: GovernanceObject.SupportAssignment
  AS: MATCHING_ASSIGNMENTS
  WHERE:
    ZTSMSupportAssignment-Role:
      EQUALS: CURRENT OBJECT
    ZTSMSupportAssignment-Application:
      EQUALS: TICKET.ZTicket-Application
  LIMIT: 100
RETURN:
  FROM: MATCHING_ASSIGNMENTS
  REQUIRE: EXACTLY ONE
  FIELD: ZTSMSupportAssignment-SupportProfile
  AS: GovernanceObject.SupportProfile
END_DYNAMIC_RESOLVER_SCRIPT

    my %ScriptFor = (
        REQUESTER                 => $RequesterScript,
        'REQUESTER-DEFAULT'       => $RequesterScript,
        'REQUESTER-SUPPORT-GROUP' => $RequesterScript,
        map { $_ => $DynamicResolverScript }
            qw(DIAGNOSE ASSESSOR ENDORSER APPROVER IMPLEMENTER VERIFIER SUPPORT ASSET ESCALATION),
    );

    ROLE:
    for my $Role (@Roles) {
        my $ExistingID = $Self->_GovernanceObjectNameExists(
            ClassID => $ClassID,
            Name    => $Role,
        );

        if ($ExistingID) {
            next ROLE if !$ScriptFor{$Role};
            my $Existing = $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $ExistingID,
                DynamicFields      => 1,
                Silent             => 1,
            );
            next ROLE if !$Existing || ref $Existing ne 'HASH';
            my $CurrentScript = $Existing->{'DynamicField_ZTSM-ScriptEngine'};
            next ROLE if $Self->_BootstrapValueHasContent($CurrentScript);

            my $Updated = $GovernanceObjectObject->GovernanceObjectUpdate(
                GovernanceObjectID                 => $ExistingID,
                'DynamicField_ZTSM-ScriptEngine'   => $ScriptFor{$Role},
                UserID                             => 1,
            );
            if ( !$Updated ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "TESSERA bootstrap could not seed ZTSM-ScriptEngine for GovernanceRole $Role ($ExistingID).",
                );
            }
            next ROLE;
        }

        my $Number = 'TESSERA-ROLE-' . $Role;
        $Number =~ s{[^A-Za-z0-9-]}{-}g;

        next ROLE if $GovernanceObjectObject->GovernanceObjectLookup(
            GOID => $Number,
        );

        my $CreatedID = $GovernanceObjectObject->GovernanceObjectAdd(
            ClassID      => $ClassID,
            ZTSMStatusID => $StatusID,
            Number       => $Number,
            Name         => $Role,
            Description  => "Default governance role used by TESSERA runtime orchestration.",
            ( $ScriptFor{$Role}
                ? ( 'DynamicField_ZTSM-ScriptEngine' => $ScriptFor{$Role} )
                : () ),
            UserID       => 1,
        );
        if ( !$CreatedID ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "TESSERA bootstrap could not create default GovernanceRole $Role.",
            );
        }
    }

    return 1;
}

sub _BootstrapValueHasContent {
    my ( $Self, $Value ) = @_;

    return if !defined $Value;
    return $Value =~ m{\S} ? 1 : 0 if !ref $Value;

    if ( ref $Value eq 'ARRAY' ) {
        for my $Entry ( @{$Value} ) {
            return 1 if $Self->_BootstrapValueHasContent($Entry);
        }
        return;
    }

    if ( ref $Value eq 'HASH' ) {
        return $Self->_BootstrapValueHasContent( $Value->{Content} )
            if exists $Value->{Content};
        for my $Entry ( values %{$Value} ) {
            return 1 if $Self->_BootstrapValueHasContent($Entry);
        }
        return;
    }

    # Unknown reference shapes are treated as authored content. Bootstrap must
    # not overwrite a value it cannot safely prove to be empty.
    return 1;
}

sub _GovernanceObjectNameExists {
    my ( $Self, %Param ) = @_;

    return if !$Param{ClassID} || !$Param{Name};

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Prepare(
        SQL => <<'END_SQL',
SELECT i.id
  FROM governance_object_item_version v
  INNER JOIN governance_object_item i
    ON i.last_version_id = v.id
  WHERE i.class_id = ?
    AND v.name = ?
END_SQL
        Bind  => [ \$Param{ClassID}, \$Param{Name} ],
        Limit => 1,
    );

    my $Found;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Found = $Row[0];
    }

    return $Found;
}

sub _RuntimeProcessesEnsure {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home') || '.';
    my @Files = (
        "$Home/var/governancedb/runtime_seed/ztsm-ticket-lifecycle-orchestration.yml",
        "$Home/var/governancedb/runtime_seed/ztsm-activity-lifecycle-orchestration.yml",
    );

    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process');
    my $YAMLObject    = $Kernel::OM->Get('Kernel::System::YAML');
    my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');

    my $Changed;

    FILE:
    for my $File (@Files) {
        my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $File,
            Mode     => 'utf8',
        );
        next FILE if !$Content;

        my $Data = $YAMLObject->Load( Data => ${$Content} );
        if ( ref $Data ne 'HASH' || ref $Data->{Process} ne 'HASH' || !$Data->{Process}->{Name} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "GovernanceDB bootstrap could not read process seed $File.",
            );
            next FILE;
        }

        if ( $Self->_ActiveProcessNameExists( Name => $Data->{Process}->{Name} ) ) {
            next FILE;
        }

        my %Import = $ProcessObject->ProcessImport(
            Content                   => ${$Content},
            OverwriteExistingEntities => 1,
            UserID                    => 1,
        );
        if ( !$Import{Success} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "GovernanceDB bootstrap could not import process '$Data->{Process}->{Name}': "
                    . ( $Import{Message} || '' ),
            );
            next FILE;
        }

        $Changed = 1;
    }

    if ($Changed) {
        my $ConfigFileLocation = "$Home/Kernel/Config/Files/ZZZProcessManagement.pm";
        my $Dump = $ProcessObject->ProcessDump(
            ResultType => 'FILE',
            Location   => $ConfigFileLocation,
            UserID     => 1,
        );
        if ( !$Dump ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => 'GovernanceDB bootstrap could not dump process configuration after runtime process import.',
            );
        }
    }

    return 1;
}

sub _ActiveProcessNameExists {
    my ( $Self, %Param ) = @_;

    return if !$Param{Name};

    my $List = $Kernel::OM->Get('Kernel::System::ProcessManagement::DB::Process')->ProcessListGet(
        UserID => 1,
    ) || [];

    PROCESS:
    for my $Process ( @{$List} ) {
        next PROCESS if ref $Process ne 'HASH';
        next PROCESS if ( $Process->{Name} || '' ) ne $Param{Name};
        next PROCESS if ( $Process->{State} || '' ) ne 'Active';
        return 1;
    }

    return;
}

sub _GenericAgentJobsEnsure {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home') || '.';
    my $File = "$Home/var/governancedb/runtime_seed/generic_agents.yml";

    my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $File,
        Mode     => 'utf8',
    );
    return 1 if !$Content;

    my $Data = $Kernel::OM->Get('Kernel::System::YAML')->Load(
        Data => ${$Content},
    );
    return 1 if ref $Data ne 'HASH' || ref $Data->{GenericAgents} ne 'HASH';

    my $DynamicFieldDriverConfig = $Kernel::OM->Get('Kernel::Config')->Get('DynamicFields::Driver') || {};
    if (
        ref $DynamicFieldDriverConfig ne 'HASH'
        || ref $DynamicFieldDriverConfig->{GovernanceObject} ne 'HASH'
        || !$DynamicFieldDriverConfig->{GovernanceObject}->{Module}
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => 'GovernanceDB bootstrap deferred GenericAgent job seed because the GovernanceObject dynamic field driver is not active yet.',
        );
        return 1;
    }

    my $GenericAgentObject = $Kernel::OM->Get('Kernel::System::GenericAgent');
    my $StateObject        = $Kernel::OM->Get('Kernel::System::State');
    my $TypeObject         = $Kernel::OM->Get('Kernel::System::Type');

    JOB:
    for my $JobName ( sort keys %{ $Data->{GenericAgents} } ) {
        my %Job = %{ $Data->{GenericAgents}{$JobName} || {} };
        $Job{Name} ||= $JobName;

        delete @Job{qw(ChangeTime CreateTime ScheduleLastRun ScheduleLastRunUnixTime)};
        $Self->_GenericAgentSearchArraysSanitize(
            Job => \%Job,
        );

        if ( ref $Job{States} eq 'ARRAY' ) {
            my @StateIDs;
            for my $State ( @{ $Job{States} } ) {
                my $StateID = $StateObject->StateLookup( State => $State );
                push @StateIDs, $StateID if $StateID;
            }
            $Job{StateIDs} = \@StateIDs if @StateIDs;
        }

        if ( ref $Job{Types} eq 'ARRAY' ) {
            my @TypeIDs;
            for my $Type ( @{ $Job{Types} } ) {
                my $TypeID = $TypeObject->TypeLookup( Type => $Type );
                push @TypeIDs, $TypeID if $TypeID;
            }
            $Job{TypeIDs} = \@TypeIDs if @TypeIDs;
        }
        $Self->_GenericAgentSearchArraysSanitize(
            Job => \%Job,
        );

        my %Existing = $GenericAgentObject->JobGet(
            Name => $Job{Name},
        );
        if (%Existing) {
            $GenericAgentObject->JobDelete(
                Name   => $Job{Name},
                UserID => 1,
            );
        }

        $GenericAgentObject->JobAdd(
            Name   => $Job{Name},
            Data   => \%Job,
            UserID => 1,
        );
    }

    return 1;
}

sub _GenericAgentSearchArraysSanitize {
    my ( $Self, %Param ) = @_;

    my $Job = $Param{Job};
    return if ref $Job ne 'HASH';

    KEY:
    for my $Key (
        qw(
            Types TypeIDs CreatedTypes CreatedTypeIDs States StateIDs CreatedStates CreatedStateIDs StateTypeIDs
            Locks LockIDs OwnerIDs ResponsibleIDs CreatedUserIDs Queues QueueIDs CreatedQueues CreatedQueueIDs
            Priorities PriorityIDs CreatedPriorities CreatedPriorityIDs Services ServiceIDs SLAs SLAIDs WatchUserIDs
        )
        )
    {
        next KEY if ref $Job->{$Key} ne 'ARRAY';

        my @Values = grep { defined $_ && $_ ne '' } @{ $Job->{$Key} };
        if (@Values) {
            $Job->{$Key} = \@Values;
            next KEY;
        }

        delete $Job->{$Key};
    }

    return 1;
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

sub _ITSMControlDefaultsEnsure {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home') || '.';
    my $File = "$Home/var/governancedb/default_control_configitem.json";
    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $File,
        Mode     => 'utf8',
    );
    return 1 if !$ContentRef;

    my $JSON = $Kernel::OM->Get('Kernel::System::JSON');
    my $Seed = $JSON->Decode( Data => ${$ContentRef} );
    return if ref $Seed ne 'ARRAY';

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $ImportSeed = $JSON->Decode( Data => ${$ContentRef} );
    my $Import = $ConfigItemObject->ClassImport(
        Content     => $ImportSeed,
        ClassExists => 'IGNORE',
    );
    if ( !$Import || !$Import->{Success} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'GovernanceDB could not ensure the ConfigItem Control model: '
                . ( $Import->{ErrorMessage} || 'unknown import error' ),
        );
        return;
    }

    my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my %ClassID = reverse %{ $Catalog->ItemList( Class => 'ITSM::ConfigItem::Class', Valid => 0 ) || {} };
    my %RoleID  = reverse %{ $Catalog->ItemList( Class => 'ITSM::ConfigItem::Role',  Valid => 0 ) || {} };
    my $YAML = $Kernel::OM->Get('Kernel::System::YAML');

    ITEM:
    for my $Item ( @{$Seed} ) {
        next ITEM if ref $Item ne 'HASH' || !defined $Item->{Definition};
        my ( $ID, $Current, $Add );
        if ( $Item->{RoleName} ) {
            $ID = $RoleID{ $Item->{RoleName} } || next ITEM;
            $Current = $ConfigItemObject->RoleDefinitionGet( RoleID => $ID ) || {};
            $Add = sub { $ConfigItemObject->RoleDefinitionAdd( RoleID => $ID, Definition => $_[0], UserID => 1 ) };
        }
        elsif ( ref $Item->{Class} eq 'HASH' && $Item->{Class}{Name} ) {
            $ID = $ClassID{ $Item->{Class}{Name} } || next ITEM;
            $Current = $ConfigItemObject->DefinitionGet( ClassID => $ID ) || {};
            $Add = sub { $ConfigItemObject->DefinitionAdd( ClassID => $ID, Definition => $_[0], UserID => 1 ) };
        }
        else {
            next ITEM;
        }

        my $WantedRef  = $YAML->Load( Data => $Item->{Definition} ) || {};
        my $CurrentRef = $YAML->Load( Data => $Current->{Definition} || '--- {}' ) || {};
        my $Merged = $Self->_StructureMerge( Current => $CurrentRef, Wanted => $WantedRef );
        next ITEM if $JSON->Encode( Data => $Merged ) eq $JSON->Encode( Data => $CurrentRef );

        my $Result = $Add->( $YAML->Dump( Data => $Merged ) );
        if ( !$Result || !$Result->{Success} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'GovernanceDB could not merge missing ConfigItem Control definition structure.',
            );
            return;
        }
    }

    return 1;
}

sub _GeneralCatalogSeedEnsure {
    my ( $Self, %Param ) = @_;

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home') || '.';
    my $File = "$Home/var/governancedb/default_general_catalog.yml";

    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $File,
        Mode     => 'utf8',
    );
    if ( !$ContentRef ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "GovernanceDB default General Catalog seed file not found: $File",
        );
        return 1;
    }

    my $Result = $Kernel::OM->Get('Kernel::System::GeneralCatalog::Document')->Import(
        Content => ${$ContentRef},
        Format  => 'yaml',
        UserID  => 1,
        CreateOnly => 1,
    );

    if ( !$Result || !$Result->{Success} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'GovernanceDB default General Catalog seed import failed: '
                . ( $Result && $Result->{Message} ? $Result->{Message} : 'unknown error' ),
        );
        return;
    }

    return 1;
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

    my @Categories = grep {$_} (
        ref $Class->{Categories} eq 'ARRAY' ? @{ $Class->{Categories} } : (),
        $Class->{Category},
    );
    my %CategorySeen;
    @Categories = grep { !$CategorySeen{$_}++ } @Categories;

    my @VersionTrigger = ref $Class->{VersionTrigger} eq 'ARRAY' && @{ $Class->{VersionTrigger} }
        ? @{ $Class->{VersionTrigger} }
        : qw(Name Description DefinitionUpdate);

    my %Wanted = (
        Categories          => @Categories ? \@Categories : undef,
        NumberModule        => $Class->{NumberModule} ? [ $Class->{NumberModule} ] : ['GOID'],
        VersionStringModule => $Class->{VersionStringModule} ? [ $Class->{VersionStringModule} ] : ['Incremental'],
        VersionTrigger      => \@VersionTrigger,
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
            my $MergedConfig = $Self->_StructureMerge(
                Current => $CurrentConfig,
                Wanted  => $Config,
            );

            next FIELD if $Self->_DynamicFieldConfigEqual(
                Left  => {
                    Name       => $Existing->{Name},
                    Label      => $Existing->{Label},
                    FieldType  => $Existing->{FieldType},
                    ObjectType => $Existing->{ObjectType},
                    Config     => $CurrentConfig,
                },
                Right => {
                    Name       => $Existing->{Name},
                    Label      => $Existing->{Label},
                    FieldType  => $Existing->{FieldType},
                    ObjectType => $Existing->{ObjectType},
                    Config     => $MergedConfig,
                },
            );

            $Self->_DynamicFieldUpdateForce(
                ID          => $Existing->{ID},
                Name        => $Existing->{Name},
                Label       => $Existing->{Label},
                FieldOrder  => $Existing->{FieldOrder},
                FieldType   => $Existing->{FieldType},
                ObjectType  => $Existing->{ObjectType},
                Config      => $MergedConfig,
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

    my @Fields = (
        {
            Name       => 'ZRM-Query',
            Label      => 'Attestation Query',
            FieldOrder => 530,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Attestation Query',
            },
        },
        {
            Name       => 'ZRM-Response',
            Label      => 'Response',
            FieldOrder => 531,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Attestation Response',
            },
        },
        {
            Name       => 'Attestation',
            Label      => 'Attestation',
            FieldOrder => 532,
            FieldType  => 'Set',
            Config     => {
                Include => [
                    { DF => 'ZRM-Query' },
                    { DF => 'ZRM-Response' },
                ],
                MultiValue   => 1,
                RenderLayout => 'Vertical',
                Tooltip      => undef,
            },
        },
        {
            Name       => 'ZTicket-HoldState',
            Label      => 'Requester Hold State',
            FieldOrder => 10100,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Stores the previous ticket state while requester hold is active.',
            },
        },
        {
            Name       => 'ZCH-Seq',
            Label      => 'Sequence',
            FieldOrder => 10404,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [
                    {
                        ErrorMessage => 'Sequence must be in number',
                        Value        => '^[0-9]+$',
                    },
                ],
                Tooltip => 'Sequence Number (Execution Order)',
            },
        },
        {
            Name       => 'ZCH-BlueLevel',
            Label      => 'Level',
            FieldOrder => 10405,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [
                    {
                        ErrorMessage => 'Execution Number must be in sequence',
                        Value        => '^[0-9]+$',
                    },
                ],
                Tooltip => 'Level (Group of execution order)',
            },
        },
        {
            Name       => 'ZCH-Strict',
            Label      => 'Strict',
            FieldOrder => 10406,
            FieldType  => 'Checkbox',
            Config     => {
                DefaultValue => 1,
                MultiValue   => 0,
                Tooltip      => 'Strict Follow Scheduled Execution Time',
            },
        },
        {
            Name       => 'ZCH-Mandatory',
            Label      => 'Mandatory',
            FieldOrder => 10407,
            FieldType  => 'Checkbox',
            Config     => {
                DefaultValue => 1,
                MultiValue   => 0,
                Tooltip      => 'Mandatory Execution Task',
            },
        },
        {
            Name       => 'ZCH-ScheduleStart',
            Label      => 'Schedule Start',
            FieldOrder => 10408,
            FieldType  => 'DateTime',
            Config     => {
                DateRestriction => '',
                DefaultValue    => 0,
                Link            => '',
                LinkPreview     => '',
                MultiValue      => 0,
                Tooltip         => 'Scheduled Start',
                YearsInFuture   => 5,
                YearsInPast     => 5,
                YearsPeriod     => 0,
            },
        },
        {
            Name       => 'ZCH-ScheduleFinish',
            Label      => 'Schedule Finish',
            FieldOrder => 10409,
            FieldType  => 'DateTime',
            Config     => {
                DateRestriction => '',
                DefaultValue    => 0,
                Link            => '',
                LinkPreview     => '',
                MultiValue      => 0,
                Tooltip         => 'Scheduled Finish Date/Time',
                YearsInFuture   => 5,
                YearsInPast     => 5,
                YearsPeriod     => 0,
            },
        },
        {
            Name       => 'ZCH-TicketType',
            Label      => 'Ticket Type',
            FieldOrder => 10410,
            FieldType  => 'GeneralCatalog',
            Config     => {
                Class        => 'ZTSM::Type',
                MultiValue   => 0,
                Multiselect  => 0,
                PossibleNone => 0,
                Tooltip      => 'Ticket Type',
            },
        },
        {
            Name       => 'ZCH-Activity',
            Label      => 'Activity',
            FieldOrder => 10411,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Activity Summary',
            },
        },
        {
            Name       => 'ZCH-Template',
            Label      => 'Template',
            FieldOrder => 10412,
            FieldType  => 'GovernanceObject',
            Config     => {
                ClassIDs              => ['Template'],
                DisplayType           => '',
                EditFieldMode         => 'AutoComplete',
                ImportSearchAttribute => '',
                LinkDirection         => 'ReferencingIsSource',
                LinkType              => '',
                MultiValue            => 0,
                Multiselect           => 0,
                PossibleNone          => 1,
                ReferenceFilterList   => [],
                ReferencedObjectType  => 'GovernanceObject',
                SearchAttribute       => 'Name',
                Tooltip               => 'Template',
                ZTSMStatusIDs         => ['Active'],
            },
        },
        {
            Name       => 'ZCH-Description',
            Label      => 'Description',
            FieldOrder => 10414,
            FieldType  => 'RichText',
            Config     => {
                DefaultValue => '',
                RegExList    => [],
                Tooltip      => 'Description',
            },
        },
        {
            Name       => 'ZCH-Profile',
            Label      => 'Profile',
            FieldOrder => 10418,
            FieldType  => 'GovernanceObject',
            Config     => {
                ClassIDs              => ['SupportProfile'],
                DisplayType           => '',
                EditFieldMode         => 'AutoComplete',
                ImportSearchAttribute => '',
                LinkDirection         => 'ReferencingIsSource',
                LinkType              => '',
                MultiValue            => 0,
                Multiselect           => 0,
                PossibleNone          => 1,
                ReferenceFilterList   => [],
                ReferencedObjectType  => 'GovernanceObject',
                SearchAttribute       => 'Name',
                Tooltip               => 'OwnerGroup',
                ZTSMStatusIDs         => ['Active'],
            },
        },
        {
            Name       => 'ZCH-Owner',
            Label      => 'Owner',
            FieldOrder => 10419,
            FieldType  => 'CustomerUser',
            Config     => {
                EditFieldMode         => 'AutoComplete',
                ImportSearchAttribute => '',
                MultiValue            => 0,
                Multiselect           => 0,
                PossibleNone          => 1,
                ReferencedObjectType  => 'CustomerUser',
                Tooltip               => 'Owner',
            },
        },
        {
            Name       => 'ZCH-Weightage',
            Label      => 'Weightage',
            FieldOrder => 10420,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => 1,
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Weightage',
            },
        },
        {
            Name       => 'ZTicket-Custom',
            Label      => 'Custom Hostname Segment',
            FieldOrder => 10105,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Custom hostname value or custom hostname segment for provisioning policy.',
            },
        },
        {
            Name       => 'ZTicket-Hostname',
            Label      => 'Hostname',
            FieldOrder => 10106,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Resolved provisioning hostname for the VM row.',
            },
        },
        {
            Name       => 'ZIN-Observed',
            Label      => 'Observed Behavior',
            FieldOrder => 10110,
            FieldType  => 'RichText',
            Config     => {
                DefaultValue => '',
                RegExList    => [],
                Tooltip      => 'Requester-provided observed incident behavior.',
            },
        },
        {
            Name       => 'ZIN-ErrorMessage',
            Label      => 'Error Message / System Log / Alert',
            FieldOrder => 10120,
            FieldType  => 'RichText',
            Config     => {
                DefaultValue => '',
                RegExList    => [],
                Tooltip      => 'Requester-provided error message, alert, log snippet, or symptom evidence.',
            },
        },
        {
            Name       => 'ZIN-AffectedCI',
            Label      => 'Affected Component',
            FieldOrder => 10130,
            FieldType  => 'ConfigItem',
            Config     => {
                ClassIDs              => [],
                DeplStateIDs          => [],
                DisplayType           => '',
                EditFieldMode         => 'AutoComplete',
                ImportSearchAttribute => '',
                LinkDirection         => 'ReferencingIsSource',
                LinkType              => '',
                MultiValue            => 1,
                Multiselect           => 0,
                PossibleNone          => 1,
                ReferenceFilterList   => [],
                ReferencedObjectType  => 'ITSMConfigItem',
                SearchAttribute       => 'Name',
                Tooltip               => 'Requester-provided affected component.',
            },
        },
        {
            Name       => 'ZIN-Diagnosis',
            Label      => 'Diagnosis',
            FieldOrder => 10140,
            FieldType  => 'RichText',
            Config     => {
                DefaultValue => '',
                RegExList    => [],
                Tooltip      => 'Diagnoser investigation notes, reasoning, findings, and ruled-out causes.',
            },
        },
        {
            Name       => 'ZIN-Outcome',
            Label      => 'Diagnosis Outcome',
            FieldOrder => 10150,
            FieldType  => 'Dropdown',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                PossibleNone => 1,
                PossibleValues => {
                    'Symptom Observed'    => 'Symptom Observed',
                    'Cause Observed'      => 'Cause Observed',
                    'Root Cause Observed' => 'Root Cause Observed',
                    'Severity Confirmed'  => 'Severity Confirmed',
                    'Not Applicable'      => 'Not Applicable',
                    Recovered             => 'Recovered',
                },
                Tooltip            => 'Structured diagnosis outcome.',
                TranslatableValues => 0,
                TreeView           => 0,
            },
        },
        {
            Name       => 'ZIN-Status',
            Label      => 'Status',
            FieldOrder => 10152,
            FieldType  => 'Dropdown',
            Config     => {
                DefaultValue => 'Resolved',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                PossibleNone => 0,
                PossibleValues => {
                    'Auto-Confirmed'     => 'Auto-Confirmed',
                    'Not Resolved'       => 'Not Resolved',
                    'Partially Resolved' => 'Partially Resolved',
                    Recurring            => 'Recurring',
                    Resolved             => 'Resolved',
                    'Unable to Confirm'  => 'Unable to Confirm',
                },
                Tooltip            => 'Incident Status',
                TranslatableValues => 0,
                TreeView           => 0,
            },
        },
        {
            Name       => 'ZIN-Severity',
            Label      => 'Severity',
            FieldOrder => 10155,
            FieldType  => 'GovernanceObject',
            Config     => {
                ClassIDs              => ['IncidentSeverity'],
                DisplayType           => '',
                EditFieldMode         => 'Dropdown',
                ImportSearchAttribute => '',
                LinkDirection         => 'ReferencingIsSource',
                LinkType              => '',
                MultiValue            => 0,
                Multiselect           => 0,
                PossibleNone          => 1,
                ReferenceFilterList   => [],
                ReferencedObjectType  => 'GovernanceObject',
                SearchAttribute       => '',
                Tooltip               => 'Incident Severity',
                ZTSMStatusIDs         => ['Active'],
            },
        },
        {
            Name       => 'ZIN-KB',
            Label      => 'KB',
            FieldOrder => 10158,
            FieldType  => 'FAQ',
            Config     => {
                DisplayType                => '',
                EditFieldMode              => 'AutoComplete',
                LinkDirection              => 'ReferencingIsSource',
                LinkObjectForReferenceType => '',
                MultiValue                 => 0,
                Multiselect                => 0,
                PossibleNone               => 1,
                ReferenceFilterList        => [],
                ReferencedObjectType       => 'FAQ',
                SearchAttribute            => 'Title',
                Tooltip                    => 'Related Knowledge Based',
            },
        },
        {
            Name       => 'ZIN-Plan',
            Label      => 'Resolution Plan',
            FieldOrder => 10160,
            FieldType  => 'RichText',
            Config     => {
                DefaultValue => '',
                RegExList    => [],
                Tooltip      => 'Proposed recovery, workaround, or next action plan.',
            },
        },
        {
            Name       => 'ZIN-Summary',
            Label      => 'Summary',
            FieldOrder => 10170,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Short diagnosis summary.',
            },
        },
        {
            Name       => 'ZIN-Iteration',
            Label      => 'Iteration',
            FieldOrder => 10180,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '1',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Current incident investigation iteration.',
            },
        },
        {
            Name       => 'ZIN-SourceDiagnosisTicketID',
            Label      => 'Source Diagnosis Ticket ID',
            FieldOrder => 10190,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Diagnosis child ticket that produced this downstream task.',
            },
        },
        {
            Name       => 'ZIN-SourceDiagnosisIteration',
            Label      => 'Source Diagnosis Iteration',
            FieldOrder => 10200,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Incident iteration of the source diagnosis child.',
            },
        },
        {
            Name       => 'ZIN-SourceDiagnosisOutcome',
            Label      => 'Source Diagnosis Outcome',
            FieldOrder => 10210,
            FieldType  => 'Text',
            Config     => {
                DefaultValue => '',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                RegExList    => [],
                Tooltip      => 'Actionable outcome copied from the source diagnosis child.',
            },
        },
    );

    my @ChangeSetIncludedFields = qw(
        ZCH-BlueLevel
        ZCH-Seq
        ZCH-Strict
        ZCH-Mandatory
        ZCH-ScheduleStart
        ZCH-ScheduleFinish
        ZCH-TicketType
        ZCH-Activity
        ZCH-Description
        ZCH-Profile
        ZCH-Owner
        ZCH-Weightage
    );
    my @ChangeSetDefinitions = (
        [ 'ZCH-Precheck',       'Pre-check',      10413 ],
        [ 'ZCH-Implementation', 'Implementation', 10415 ],
        [ 'ZCH-Rollback',       'Rollback',       10416 ],
        [ 'ZCH-PostChange',     'Post-Change',    10417 ],
    );

    for my $Definition (@ChangeSetDefinitions) {
        my ( $Name, $Label, $FieldOrder ) = @{$Definition};
        push @Fields, {
            Name       => $Name,
            Label      => $Label,
            FieldOrder => $FieldOrder,
            FieldType  => 'Set',
            Config     => {
                Include      => [ map { { DF => $_ } } @ChangeSetIncludedFields ],
                MultiValue   => 1,
                RenderLayout => 'Vertical',
                Tooltip      => '',
            },
        };
    }

    FIELD:
    for my $Field (@Fields) {
        $Field->{Config} = $Self->_TicketRuntimeDynamicFieldConfigPrepare(
            FieldType => $Field->{FieldType},
            Config    => $Field->{Config},
        );

        my $Existing = $DynamicFieldObject->DynamicFieldGet(
            Name => $Field->{Name},
        );
        if ( $Existing && $Existing->{ID} ) {
            my $NeedsReferenceRepair = $Field->{Name} eq 'ZIN-KB'
                && !$Self->_DynamicFieldConfigEqual(
                    Left => {
                        Name       => $Existing->{Name},
                        Label      => $Existing->{Label},
                        FieldType  => $Existing->{FieldType},
                        ObjectType => $Existing->{ObjectType},
                        Config     => $Existing->{Config} || {},
                    },
                    Right => {
                        Name       => $Field->{Name},
                        Label      => $Field->{Label},
                        FieldType  => $Field->{FieldType},
                        ObjectType => 'Ticket',
                        Config     => $Field->{Config},
                    },
                );

            if ($NeedsReferenceRepair) {
                $Self->_DynamicFieldUpdateForce(
                    ID         => $Existing->{ID},
                    Name       => $Field->{Name},
                    Label      => $Field->{Label},
                    FieldOrder => $Existing->{FieldOrder},
                    FieldType  => $Field->{FieldType},
                    ObjectType => 'Ticket',
                    Config     => $Field->{Config},
                    ValidID    => $Existing->{ValidID} || 1,
                    UserID     => 1,
                    Reorder    => 0,
                );
            }

            next FIELD;
        }

        my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
            Name       => $Field->{Name},
            Label      => $Field->{Label},
            FieldOrder => $Field->{FieldOrder},
            FieldType  => $Field->{FieldType},
            ObjectType => 'Ticket',
            Config     => $Field->{Config},
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

sub _TicketRuntimeDynamicFieldConfigPrepare {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config} || {};
    my %Prepared = %{$Config};

    return \%Prepared if ( $Param{FieldType} || '' ) ne 'GovernanceObject';

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my %ClassName2ID = reverse %{
        $GeneralCatalogObject->ItemList(
            Class => 'ZTSM::GovernanceObject::Class',
            Valid => 1,
        ) || {}
    };
    my %StatusName2ID = reverse %{
        $GeneralCatalogObject->ItemList(
            Class => 'ZTSM::GovernanceObject::Status',
            Valid => 1,
        ) || {}
    };

    if ( ref $Prepared{ClassIDs} eq 'ARRAY' ) {
        my @ClassIDs = grep {$_} map { $_ =~ m{\A\d+\z} ? $_ : $ClassName2ID{$_} } @{ $Prepared{ClassIDs} };
        $Prepared{ClassIDs} = \@ClassIDs;
    }

    if ( ref $Prepared{ZTSMStatusIDs} eq 'ARRAY' ) {
        my @StatusIDs = grep {$_} map { $_ =~ m{\A\d+\z} ? $_ : $StatusName2ID{$_} } @{ $Prepared{ZTSMStatusIDs} };
        $Prepared{ZTSMStatusIDs} = \@StatusIDs;
    }

    return \%Prepared;
}

sub _ITSMConfigItemLifecycleDateDynamicFieldsEnsure {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    my @FieldNames = qw(
        ZTAM-Released
        ZTAM-EoSale
        ZTAM-EoStandardSupport
        ZTAM-EoExtendedSupport
        ZTAM-EoServiceLife
    );

    my %FieldIDs;

    FIELD:
    for my $FieldName (@FieldNames) {
        my $Field = $DynamicFieldObject->DynamicFieldGet( Name => $FieldName );
        next FIELD if !$Field || ref $Field ne 'HASH';
        next FIELD if ( $Field->{ObjectType} || '' ) ne 'ITSMConfigItem';
        next FIELD if ( $Field->{FieldType}  || '' ) ne 'Date';

        $FieldIDs{ $Field->{Name} } = $Field->{ID};

        my %Config = %{ $Field->{Config} || {} };
        my $Changed;

        if ( ( $Config{YearsPeriod} // '' ) ne '1' ) {
            $Config{YearsPeriod} = '1';
            $Changed = 1;
        }

        my $YearsInFuture = $Config{YearsInFuture};
        if ( !defined $YearsInFuture || $YearsInFuture !~ m{\A\d+\z} || $YearsInFuture < 10 ) {
            $Config{YearsInFuture} = '10';
            $Changed = 1;
        }

        if ( !defined $Config{YearsInPast} || $Config{YearsInPast} !~ m{\A\d+\z} ) {
            $Config{YearsInPast} = '5';
            $Changed = 1;
        }

        next FIELD if !$Changed;

        my $Updated = $Self->_DynamicFieldUpdateForce(
            ID         => $Field->{ID},
            Name       => $Field->{Name},
            Label      => $Field->{Label},
            FieldOrder => $Field->{FieldOrder},
            FieldType  => $Field->{FieldType},
            ObjectType => $Field->{ObjectType},
            Config     => \%Config,
            ValidID    => $Field->{ValidID} || 1,
            UserID     => 1,
            Reorder    => 0,
        );

        if ( !$Updated ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "GovernanceDB bootstrap could not extend ITSM ConfigItem lifecycle date range for $FieldName.",
            );
        }
    }

    $DynamicFieldObject->EventHandlerTransaction();

    if (%FieldIDs) {
        my $ClassList = $GeneralCatalogObject->ItemList(
            Class => 'ITSM::ConfigItem::Class',
        ) || {};

        my %OutOfSyncDefinitions;
        CLASS:
        for my $ClassID ( sort keys %{$ClassList} ) {
            my $Definition = $ConfigItemObject->DefinitionGet(
                ClassID => $ClassID,
            );
            next CLASS if !$Definition || ref $Definition ne 'HASH';
            next CLASS if ref $Definition->{DynamicFieldRef} ne 'HASH';

            FIELD:
            for my $FieldName ( sort keys %FieldIDs ) {
                next FIELD if !$Definition->{DynamicFieldRef}{$FieldName};

                push @{ $OutOfSyncDefinitions{$ClassID} }, $FieldIDs{$FieldName};
            }
        }

        if (%OutOfSyncDefinitions) {
            my $SyncMarked = $ConfigItemObject->DefinitionSetOutOfSync(
                Classes => \%OutOfSyncDefinitions,
            );
            if ( !$SyncMarked ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => 'GovernanceDB bootstrap could not mark ITSM ConfigItem definitions out of sync for lifecycle date fields.',
                );
            }

            my $Synced = $ConfigItemObject->DefinitionSync();
            if ( !$Synced ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => 'GovernanceDB bootstrap could not sync ITSM ConfigItem definitions after lifecycle date range repair.',
                );
            }
        }
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'ConfigItemDefinition',
    );

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
    delete $Sanitized{ZTSMStatusIDs};

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
        'CustomerFrontend::NavBarModule###900-ZTSMCustomerAsset',
        'CustomerFrontend::Module###CustomerITSMConfigItem',
        'CustomerFrontend::Module###CustomerITSMConfigItemSearch',
        'CustomerFrontend::Module###CustomerITSMConfigItemZoom',
        'Loader::Module::CustomerITSMConfigItem###003-ITSMConfigItem',
        'CustomerFrontend::Navigation###CustomerITSMConfigItem###003-ITSMConfigItem',
        'Customer::ConfigItem::PermissionConditions###01',
        'ITSMConfigItem::Frontend::CustomerOverview###Small',
        'Customer::ConfigItem::PermissionConditionColumns###Default',
        'Customer::ConfigItem::PermissionConditionColumns###01',
        'CustomerLogin::Settings',
        'CustomerLogo',
        'Loader::Module::CustomerLogin###002-CustomerLogin',
        'CustomerDashboard::Configuration::Text',
        'CustomerDashboard::Tiles###NewTicket',
        'CustomerDashboard::Tiles###FeaturedLink-01',
        'CustomerDashboard::Tiles###TicketList-01',
        'Ticket::Frontend::CustomerDisableCompanyTicketAccess',
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

sub _CustomerBrandingEnsure {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my @Settings;

    my %LoginSetting = $SysConfigObject->SettingGet(
        Name => 'CustomerLogin::Settings',
    );
    if ( ref $LoginSetting{EffectiveValue} eq 'HASH' ) {
        my %LoginValue = %{ $LoginSetting{EffectiveValue} };
        $LoginValue{LoginText}  = 'TESSERA ICT Ticket Platform';
        $LoginValue{Background} = '<OTOBO_CONFIG_Frontend::WebPath>common/img/TESSERA/LoginBG.jpg';
        push @Settings, {
            Name           => 'CustomerLogin::Settings',
            IsValid        => 1,
            EffectiveValue => \%LoginValue,
        };
    }

    my %LogoSetting = $SysConfigObject->SettingGet(
        Name => 'CustomerLogo',
    );
    if (%LogoSetting) {
        push @Settings, {
            Name    => 'CustomerLogo',
            IsValid => 1,
            EffectiveValue => {
                URLLogo   => 'common/img/TESSERA/TESSERA_LOGIN_v2.svg',
                URLSignet => 'common/img/TESSERA/TESSERA_MARK_v2.svg',
            },
        };
    }

    my $LoaderSettingName = 'Loader::Module::CustomerLogin###002-CustomerLogin';
    my %LoaderSetting = $SysConfigObject->SettingGet(
        Name => $LoaderSettingName,
    );
    if ( ref $LoaderSetting{EffectiveValue} eq 'HASH' ) {
        my %LoaderValue = %{ $LoaderSetting{EffectiveValue} };
        my @CSS = ref $LoaderValue{CSS} eq 'ARRAY' ? @{ $LoaderValue{CSS} } : ();
        my %Seen = map { $_ => 1 } @CSS;
        push @CSS, 'TESSERA.Customer.Branding.css' if !$Seen{'TESSERA.Customer.Branding.css'};
        $LoaderValue{CSS} = \@CSS;
        push @Settings, {
            Name           => $LoaderSettingName,
            IsValid        => 1,
            EffectiveValue => \%LoaderValue,
        };
    }

    return 1 if !@Settings;

    my $Success = $SysConfigObject->SettingsSet(
        Settings => \@Settings,
        Comments => 'GovernanceDB TESSERA customer branding',
        UserID   => 1,
    );

    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'GovernanceDB could not update TESSERA customer branding settings.',
        );
        return;
    }

    return 1;
}

sub _CustomerDashboardEnsure {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my @Settings;

    my %DashboardSettings = (
        'CustomerDashboard::Configuration::Text' => {
            WelcomeText => 'Welcome %s, to your TESSERA workspace.',
            Name        => 'UserFirstname',
            SubText     => 'This service portal is available to you all day every day.',
        },
        'CustomerDashboard::Tiles###NewTicket' => {
            Order    => '1',
            Template => 'Dashboard/TileNewTicket',
            Config   => {
                Color => '#001bff',
            },
        },
        'CustomerDashboard::Tiles###FeaturedLink-01' => {
            Order    => '2',
            Module   => 'Kernel::Output::HTML::CustomerDashboard::TileFeaturedFAQ',
            Template => 'Dashboard/TileFeaturedFAQ',
            Config   => {
                CategoryName => 'Announcement',
                StartField   => 'ZFAQ-Start',
                ExpiryField  => 'ZFAQ-Expiry',
                Limit        => '5',
                EmptyText    => 'No current announcements.',
            },
        },
        'CustomerDashboard::Tiles###TicketList-01' => {
            Order  => '3',
            Module => 'Kernel::Output::HTML::CustomerDashboard::TileTicketList',
            Config => {
                Text           => 'My workspace',
                SortBy         => 'Age',
                OrderBy        => 'Down',
                StateType      => '',
                CompanyTickets => '0',
                MaxTickets     => '9',
            },
        },
    );

    for my $SettingName ( sort keys %DashboardSettings ) {
        my %Setting = $SysConfigObject->SettingGet( Name => $SettingName );
        next if !%Setting;

        push @Settings, {
            Name           => $SettingName,
            IsValid        => 1,
            EffectiveValue => $DashboardSettings{$SettingName},
        };
    }

    my $DisableCompanyTicketsName = 'Ticket::Frontend::CustomerDisableCompanyTicketAccess';
    my %DisableCompanyTicketsSetting = $SysConfigObject->SettingGet( Name => $DisableCompanyTicketsName );
    if (%DisableCompanyTicketsSetting) {
        push @Settings, {
            Name           => $DisableCompanyTicketsName,
            IsValid        => 1,
            EffectiveValue => 1,
        };
    }

    return 1 if !@Settings;

    my $Success = $SysConfigObject->SettingsSet(
        Settings => \@Settings,
        Comments => 'GovernanceDB TESSERA customer dashboard',
        UserID   => 1,
    );

    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'GovernanceDB could not activate TESSERA customer dashboard settings.',
        );
        return;
    }

    return 1;
}

sub _CustomerAssetFrontendEnsure {
    my ( $Self, %Param ) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my @SettingNames = (
        'CustomerFrontend::Module###CustomerITSMConfigItem',
        'CustomerFrontend::Module###CustomerITSMConfigItemSearch',
        'CustomerFrontend::Module###CustomerITSMConfigItemZoom',
        'Customer::ConfigItem::PermissionConditions###01',
    );

    my @Settings;
    for my $SettingName (@SettingNames) {
        my %Setting = $SysConfigObject->SettingGet( Name => $SettingName );
        next if !%Setting;
        push @Settings, {
            Name           => $SettingName,
            IsValid        => 1,
            EffectiveValue => $Setting{EffectiveValue},
        };
    }

    my $AssetLoaderName = 'Loader::Module::CustomerITSMConfigItem###003-ITSMConfigItem';
    my %AssetLoaderSetting = $SysConfigObject->SettingGet( Name => $AssetLoaderName );
    if ( ref $AssetLoaderSetting{EffectiveValue} eq 'HASH' ) {
        my %LoaderValue = %{ $AssetLoaderSetting{EffectiveValue} };
        my @JavaScript = ref $LoaderValue{JavaScript} eq 'ARRAY' ? @{ $LoaderValue{JavaScript} } : ();
        if ( !grep { $_ eq 'ZTSM.Customer.AssetFilters.js' } @JavaScript ) {
            push @JavaScript, 'ZTSM.Customer.AssetFilters.js';
        }
        $LoaderValue{JavaScript} = \@JavaScript;
        push @Settings, {
            Name           => $AssetLoaderName,
            IsValid        => 1,
            EffectiveValue => \%LoaderValue,
        };
    }

    my $AgentLoaderName = 'Loader::Module::AgentITSMConfigItem###003-ITSMConfigItem';
    my %AgentLoaderSetting = $SysConfigObject->SettingGet( Name => $AgentLoaderName );
    if ( ref $AgentLoaderSetting{EffectiveValue} eq 'HASH' ) {
        my %AgentLoaderValue = %{ $AgentLoaderSetting{EffectiveValue} };
        my @JavaScript = ref $AgentLoaderValue{JavaScript} eq 'ARRAY'
            ? @{ $AgentLoaderValue{JavaScript} }
            : ();
        @JavaScript = grep {
            $_ ne 'ITSM.UI.ConfigItemActionRow.js'
                && $_ ne 'ZTSM.Agent.ConfigItem.OverviewGuard.js'
                && $_ ne 'ZTSM.Agent.ConfigItem.DataActions.js'
        } @JavaScript;
        my $OverviewIndex = scalar @JavaScript;
        for my $Index ( 0 .. $#JavaScript ) {
            if ( $JavaScript[$Index] eq 'ITSM.Agent.ConfigItem.Overview.js' ) {
                $OverviewIndex = $Index;
                last;
            }
        }
        splice @JavaScript, $OverviewIndex, 0,
            'ITSM.UI.ConfigItemActionRow.js',
            'ZTSM.Agent.ConfigItem.OverviewGuard.js',
            'ZTSM.Agent.ConfigItem.DataActions.js';
        $AgentLoaderValue{JavaScript} = \@JavaScript;
        push @Settings, {
            Name           => $AgentLoaderName,
            IsValid        => 1,
            EffectiveValue => \%AgentLoaderValue,
        };
    }

    my $OverviewBackendName = 'ITSMConfigItem::Frontend::CustomerOverview###Small';
    my %OverviewBackend = $SysConfigObject->SettingGet( Name => $OverviewBackendName );
    if ( ref $OverviewBackend{EffectiveValue} eq 'HASH' ) {
        my %OverviewValue = %{ $OverviewBackend{EffectiveValue} };
        $OverviewValue{Module} = 'Kernel::Output::HTML::ITSMConfigItem::ZTSMCustomerOverviewSmall';
        push @Settings, {
            Name           => $OverviewBackendName,
            IsValid        => 1,
            EffectiveValue => \%OverviewValue,
        };
    }

    my $AgentOverviewBackendName = 'ITSMConfigItem::Frontend::Overview###Small';
    my %AgentOverviewBackend = $SysConfigObject->SettingGet( Name => $AgentOverviewBackendName );
    if ( ref $AgentOverviewBackend{EffectiveValue} eq 'HASH' ) {
        my %AgentOverviewValue = %{ $AgentOverviewBackend{EffectiveValue} };
        $AgentOverviewValue{Module} = 'Kernel::Output::HTML::ITSMConfigItem::ZTSMOverviewSmall';
        push @Settings, {
            Name           => $AgentOverviewBackendName,
            IsValid        => 1,
            EffectiveValue => \%AgentOverviewValue,
        };
    }

    my @AssetColumns = (
        'Number', 'Name', 'ZTSMAssetTag', 'Class', 'ZTSMProductModel',
        'ZTSMApplication', 'ZTSMEnvironment', 'ZTSMLocation',
        'ZTSMDomain', 'ZTSMFunctionProfile', 'CurDeplState',
    );
    for my $ColumnSettingName (
        'Customer::ConfigItem::PermissionConditionColumns###Default',
        'Customer::ConfigItem::PermissionConditionColumns###01',
        )
    {
        my %ColumnSetting = $SysConfigObject->SettingGet( Name => $ColumnSettingName );
        next if !%ColumnSetting;
        push @Settings, {
            Name           => $ColumnSettingName,
            IsValid        => 1,
            EffectiveValue => [@AssetColumns],
        };
    }

    my $NavigationName = 'CustomerFrontend::Navigation###CustomerITSMConfigItem###003-ITSMConfigItem';
    my %NavigationSetting = $SysConfigObject->SettingGet( Name => $NavigationName );
    if ( ref $NavigationSetting{EffectiveValue} eq 'ARRAY' ) {
        my @Navigation = map { ref $_ eq 'HASH' ? { %{$_} } : $_ } @{ $NavigationSetting{EffectiveValue} };
        if ( ref $Navigation[0] eq 'HASH' ) {
            $Navigation[0]{Name}        = 'Assets';
            $Navigation[0]{Description} = 'Assets covered by your support assignments.';
            $Navigation[0]{svgIcon}     = 'var/httpd/htdocs/skins/Customer/default/img/ztsm_assets.svg';
        }
        push @Settings, {
            Name           => $NavigationName,
            IsValid        => 1,
            EffectiveValue => \@Navigation,
        };
    }

    return 1 if !@Settings;

    my $Success = $SysConfigObject->SettingsSet(
        Settings => \@Settings,
        Comments => 'GovernanceDB customer asset portal registration',
        UserID   => 1,
    );

    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'GovernanceDB could not enable the customer asset portal settings.',
        );
        return;
    }

    return 1;
}

1;
