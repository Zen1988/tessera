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

    $Self->_ITSMConfigItemLifecycleDateDynamicFieldsEnsure();

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

    $Self->_SysConfigDeploy();

    $Self->_ServiceTicketTypeACLsRebuild();

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

    ROLE:
    for my $Role (@Roles) {
        next ROLE if $Self->_GovernanceObjectNameExists(
            ClassID => $ClassID,
            Name    => $Role,
        );

        my $Number = 'TESSERA-ROLE-' . $Role;
        $Number =~ s{[^A-Za-z0-9-]}{-}g;

        next ROLE if $GovernanceObjectObject->GovernanceObjectLookup(
            GOID => $Number,
        );

        $GovernanceObjectObject->GovernanceObjectAdd(
            ClassID      => $ClassID,
            ZTSMStatusID => $StatusID,
            Number       => $Number,
            Name         => $Role,
            Description  => "Default governance role used by TESSERA runtime orchestration.",
            UserID       => 1,
        );
    }

    return 1;
}

sub _GovernanceObjectNameExists {
    my ( $Self, %Param ) = @_;

    return if !$Param{ClassID} || !$Param{Name};

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Prepare(
        SQL => <<'END_SQL',
SELECT v.id
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

    my @Fields = (
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
                DefaultValue => 'Symptom Observed',
                Link         => '',
                LinkPreview  => '',
                MultiValue   => 0,
                PossibleNone => 0,
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

    FIELD:
    for my $Field (@Fields) {
        my $Existing = $DynamicFieldObject->DynamicFieldGet(
            Name => $Field->{Name},
        );
        next FIELD if $Existing && $Existing->{ID};

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
