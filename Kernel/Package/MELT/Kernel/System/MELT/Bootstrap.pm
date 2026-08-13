# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::System::MELT::Bootstrap;

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
    'Kernel::System::GeneralCatalog::MELTDocument',
    'Kernel::System::MELT',
    'Kernel::System::MELTObject',
    'Kernel::System::Group',
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

    $Self->_ActivityTableEnsure();

    my $Defaults = $Self->_DefaultsLoad();
    return if !$Defaults;

    my $GeneralCatalogObject  = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    $Self->_HistoryTypesEnsure();
    $Self->_GeneralCatalogSeedEnsure();

    my $ClassNamespace       = $Defaults->{ClassNamespace}       || 'ZTSM::MELT::Class';
    my $RoleNamespace        = $Defaults->{RoleNamespace}        || 'ZTSM::MELT::Role';
    my $DefinitionNamespace  = $Defaults->{DefinitionNamespace}  || 'ZTSM::MELT::Definition';
    my $CategoryNamespace    = $Defaults->{CategoryNamespace}    || 'ZTSM::MELT::Category';
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
            MELTObjectObject => $MELTObjectObject,
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
            MELTObjectObject => $MELTObjectObject,
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

    $Self->_RuntimeOverlayInstall();

    $Self->_SysConfigDeploy();

    return 1;
}

sub _ActivityTableEnsure {
    my ($Self) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    my %Table = map { lc($_) => 1 } $DBObject->ListTables();
    return 1 if $Table{melt_object_activity_article};
    return $DBObject->Do( SQL => <<'END_SQL' );
CREATE TABLE melt_object_activity_article (
    id BIGINT NOT NULL AUTO_INCREMENT,
    melt_object_id BIGINT NULL,
    object_number VARCHAR(100) NULL,
    event_type VARCHAR(100) NOT NULL,
    source VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body LONGBLOB NOT NULL,
    payload LONGBLOB NULL,
    create_time DATETIME NOT NULL,
    create_by INTEGER NOT NULL,
    PRIMARY KEY (id),
    INDEX melt_activity_object (melt_object_id)
)
END_SQL
}

sub CopiedObjectDataClear {
    my ($Self) = @_;

    # Compatibility no-op. Preview builds copied external objects into MELT,
    # but an upgrade must never delete runtime evidence or user-created data.
    return 1;
}

sub _DefinitionEnsure {
    my ( $Self, %Param ) = @_;

    my $MELTObjectObject = $Param{MELTObjectObject};
    my $Definition             = $Param{Definition};
    my $Type                   = $Param{Type} || 'Class';

    return if !$MELTObjectObject || !$Definition;

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
        ? $MELTObjectObject->RoleDefinitionGet(%GetParam)
        : $MELTObjectObject->DefinitionGet(%GetParam);

    if ( $CurrentDefinition && $CurrentDefinition->{DefinitionID} ) {
        my $Current = $Self->_DefinitionNormalize( $CurrentDefinition->{Definition} || '' );
        my $Wanted  = $Self->_DefinitionNormalize($Definition);

        return 1 if $Current eq $Wanted;

        $AddParam{Force} = 1;
    }

    my $Result = $Type eq 'Role'
        ? $MELTObjectObject->RoleDefinitionAdd(%AddParam)
        : $MELTObjectObject->DefinitionAdd(%AddParam);

    if ( $Result && $Result->{Success} ) {
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
            Type => 'MELTObjectDefinition',
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
    my $SourceDir = "$Home/var/melt/runtime_overlay";

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
                        Message  => "MELT runtime overlay could not read $Source: $!",
                    );
                    return;
                };
                local $/;
                my $Content = <$SourceFH>;
                close $SourceFH;

                open my $TargetFH, '>:raw', $Target or do {
                    $LogObject->Log(
                        Priority => 'error',
                        Message  => "MELT runtime overlay could not write $Target: $!",
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
    # Disabled compatibility bridge. MELT does not rewrite values owned by
    # Ticket, ConfigItem, GovernanceObject, or any other object type.
    return 1;
}

sub _TicketReferenceDynamicFieldsRepair {
    my ( $Self, %Param ) = @_;
    # Disabled compatibility bridge. Ticket references remain owned by their
    # defining package and retain their original field driver and values.
    return 1;
}

sub _ConfigItemsCopyToMELTObjects {
    my ( $Self, %Param ) = @_;
    # Disabled compatibility bridge. MELT starts and remains independent; it
    # does not copy ConfigItem or GovernanceObject records during installation.
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
            Message  => "MELT bootstrap could not force-update dynamic field $Param{Name}.",
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
            Message  => 'MELT bootstrap could not rebuild generated service ticket type ACLs.',
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
        { Name => 'closed no action',        Type => 'closed',           Comment => 'No Action Required' },
        { Name => 'closed rejected',         Type => 'closed',           Comment => 'Rejected during approval or assessment.' },
        { Name => 'closed rollback',         Type => 'closed',           Comment => 'Roll back' },
        { Name => 'closed successful',       Type => 'closed',           Comment => 'Ticket is closed successfully.' },
        { Name => 'closed unsuccessful',     Type => 'closed',           Comment => 'Ticket is closed unsuccessfully.' },
        { Name => 'closed with workaround',  Type => 'closed',           Comment => 'Ticket is closed with workaround.' },
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
                Message  => "MELT bootstrap could not resolve state type '$State->{Type}' for '$State->{Name}'.",
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
        ASSESSOR
        ENDORSER
        APPROVER
        IMPLEMENTER
        VERIFIER
        SUPPORT
        ESCALATION
    );

    my $GeneralCatalogObject   = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    my %ClassByName = reverse %{ $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::MELT::Class',
    ) || {} };
    my $ClassID = $ClassByName{GovernanceRole} || $ClassByName{'Governance Role'};
    return if !$ClassID;

    my %StatusByName = reverse %{ $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::MELT::Status',
    ) || {} };
    my $StatusID = $StatusByName{Active} || $StatusByName{Approved} || $StatusByName{Draft};
    return if !$StatusID;

    ROLE:
    for my $Role (@Roles) {
        next ROLE if $Self->_MELTObjectNameExists(
            ClassID => $ClassID,
            Name    => $Role,
        );

        my $Number = 'TESSERA-ROLE-' . $Role;
        $Number =~ s{[^A-Za-z0-9-]}{-}g;

        next ROLE if $MELTObjectObject->MELTObjectLookup(
            MELTID => $Number,
        );

        $MELTObjectObject->MELTObjectAdd(
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

sub _MELTObjectNameExists {
    my ( $Self, %Param ) = @_;

    return if !$Param{ClassID} || !$Param{Name};

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Prepare(
        SQL => <<'END_SQL',
SELECT v.id
  FROM melt_object_item_version v
  INNER JOIN melt_object_item i
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
        "$Home/var/melt/runtime_seed/ztsm-ticket-lifecycle-orchestration.yml",
        "$Home/var/melt/runtime_seed/ztsm-activity-lifecycle-orchestration.yml",
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
                Message  => "MELT bootstrap could not read process seed $File.",
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
                Message  => "MELT bootstrap could not import process '$Data->{Process}->{Name}': "
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
                Message  => 'MELT bootstrap could not dump process configuration after runtime process import.',
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
    my $File = "$Home/var/melt/runtime_seed/generic_agents.yml";

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
        || ref $DynamicFieldDriverConfig->{MELTObject} ne 'HASH'
        || !$DynamicFieldDriverConfig->{MELTObject}->{Module}
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => 'MELT bootstrap deferred GenericAgent job seed because the MELTObject dynamic field driver is not active yet.',
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
    my $File = "$Home/var/melt/default_classes.json";

    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $File,
        Mode     => 'utf8',
    );
    if ( !$ContentRef ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "MELT default class seed file not found: $File",
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
    my $File = "$Home/var/melt/default_general_catalog.yml";

    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $File,
        Mode     => 'utf8',
    );
    if ( !$ContentRef ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "MELT default General Catalog seed file not found: $File",
        );
        return 1;
    }

    my $Result = $Kernel::OM->Get('Kernel::System::GeneralCatalog::MELTDocument')->Import(
        Content => ${$ContentRef},
        Format  => 'yaml',
        UserID  => 1,
    );

    if ( !$Result || !$Result->{Success} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'MELT default General Catalog seed import failed: '
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
        Message  => "Could not ensure MELT catalog item '$Param{Name}' in class '$Param{Class}'.",
    );

    return;
}

sub _HistoryTypesEnsure {
    my ($Self) = @_;

    my @HistoryTypes = qw(
        MELTObjectCreate
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
            SQL   => 'SELECT id FROM melt_object_item_history_type WHERE name = ?',
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
            SQL => 'INSERT INTO melt_object_item_history_type '
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
        'melt',
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
        NumberModule        => $Class->{NumberModule} ? [ $Class->{NumberModule} ] : ['MELTID'],
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
        Class => 'ZTSM::MELT::Class',
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
            if ( ( $Existing->{ObjectType} || '' ) ne 'MELTObject' ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'notice',
                    Message  => "MELT bootstrap skipped dynamic field $FieldName because it belongs to object type "
                        . ( $Existing->{ObjectType} || '<unknown>' ) . '.',
                );
                next FIELD;
            }

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
                    ObjectType => 'MELTObject',
                    Config     => $Config,
                },
            );

            $Self->_DynamicFieldUpdateForce(
                ID          => $Existing->{ID},
                Name        => $FieldName,
                Label       => $Label,
                FieldOrder  => $Existing->{FieldOrder},
                FieldType   => $FieldType,
                ObjectType  => 'MELTObject',
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
            ObjectType => 'MELTObject',
            Config     => $Config,
            ValidID    => 1,
            UserID     => 1,
            Reorder    => 0,
        );

        next FIELD if $FieldID;

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "MELT bootstrap could not create dynamic field $FieldName.",
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
            Message  => 'MELT bootstrap could not create dynamic field ZTicket-HoldState.',
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
        Class => 'ZTSM::MELT::Class',
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
            DisplayType  => 'MELTObjectName',
            DefaultValue => '',
            Link         => '',
            LinkPreview  => '',
            MultiValue   => 0,
            Tooltip      => '',
        };

        my $Existing = $DynamicFieldObject->DynamicFieldGet( Name => $Field->{Name} );
        if ($Existing) {
            if (
                ( $Existing->{ObjectType} || '' ) ne 'CustomerUser'
                || ( $Existing->{FieldType} || '' ) ne 'MELTObject'
                )
            {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'notice',
                    Message  => "MELT bootstrap skipped customer-user field $Field->{Name} because it is owned by "
                        . ( $Existing->{ObjectType} || '<unknown>' ) . '/'
                        . ( $Existing->{FieldType} || '<unknown>' ) . '.',
                );
                next FIELD;
            }

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
                    FieldType  => 'MELTObject',
                    ObjectType => 'CustomerUser',
                    Config     => $Config,
                },
            );

            $Self->_DynamicFieldUpdateForce(
                ID          => $Existing->{ID},
                Name        => $Field->{Name},
                Label       => $Field->{Label},
                FieldOrder  => $Existing->{FieldOrder} || $Field->{FieldOrder},
                FieldType   => 'MELTObject',
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
            FieldType  => 'MELTObject',
            ObjectType => 'CustomerUser',
            Config     => $Config,
            ValidID    => 1,
            UserID     => 1,
            Reorder    => 0,
        );

        next FIELD if $FieldID;

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "MELT bootstrap could not create dynamic field $Field->{Name}.",
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
        MELTID
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
        ObjectType => 'MELTObject',
    );
    $Self->_DynamicFieldDriverObjectTypeEnsure(
        Driver     => 'Set',
        ObjectType => 'MELTObject',
    );

    my @DirtySettings   = (
        'DynamicFields::ObjectType###MELTObject',
        'DynamicFieldScreens###MELT',
        'DefaultColumnsScreens###MELT',
        'DynamicFieldScreens::ObjectTypes###MELT',
        'DynamicFields::Driver###Ticket',
        'DynamicFields::Driver###MELTAgent',
        'DynamicFields::Driver###CustomerCompany',
        'DynamicFields::Driver###CustomerUser',
        'DynamicFields::Driver###Service',
        'DynamicFields::Driver###Set',
        'DynamicFields::Driver###MELTObject',
        'DynamicFields::Driver###MELTObjectVersion',
        'MELTObject::Frontend::AgentMELTObject###DefaultCategory',
        'MELTObject::Frontend::AgentMELTObject###DefaultColumns',
        'MELTObject::Frontend::AgentMELTObject###ClassColumnsAvailable',
        'MELTObject::Frontend::AgentMELTObject###ClassColumnsDefault',
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
        Comments      => 'MELT package bootstrap',
        DirtySettings => \@DirtySettings,
        UserID        => 1,
        Force         => 1,
    );

    if ( !$DeploymentResult{Success} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'MELT could not deploy SysConfig settings.',
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
        Comments => 'MELT dynamic field driver object type registration',
        UserID   => 1,
    );

    if ( !$Success ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "MELT could not update SysConfig setting $SettingName.",
        );
        return;
    }

    return 1;
}

1;

