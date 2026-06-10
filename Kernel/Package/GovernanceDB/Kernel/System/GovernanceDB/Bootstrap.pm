# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::System::GovernanceDB::Bootstrap;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::DynamicField',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceDB',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Group',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::SysConfig',
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

        my $ExistingDefinition = $GovernanceObjectObject->RoleDefinitionGet(
            RoleID => $RoleID,
        );
        next ROLE if $ExistingDefinition;

        $GovernanceObjectObject->RoleDefinitionAdd(
            RoleID     => $RoleID,
            Definition => $Role->{Definition},
            UserID     => 1,
        );
    }

    $Self->_DynamicFieldsEnsure(
        Classes => $Defaults->{Classes} || [],
    );

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

        my $ExistingDefinition = $GovernanceObjectObject->DefinitionGet(
            ClassID => $ClassID,
        );
        next CLASS if $ExistingDefinition;

        $GovernanceObjectObject->DefinitionAdd(
            ClassID    => $ClassID,
            Definition => $Class->{Definition},
            UserID     => 1,
        );
    }

    $Self->_SysConfigDeploy();

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

sub _CatalogItemEnsure {
    my ( $Self, %Param ) = @_;

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my $Item = $GeneralCatalogObject->ItemGet(
        Class => $Param{Class},
        Name  => $Param{Name},
    );
    return $Item->{ItemID} if $Item && $Item->{ItemID};

    return $GeneralCatalogObject->ItemAdd(
        Class   => $Param{Class},
        Name    => $Param{Name},
        ValidID => 1,
        UserID  => 1,
    );
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
        if ( $Key eq 'Permission' && ref $Preferences{$Key} eq 'ARRAY' ) {
            my %Existing = map { $_ => 1 } @{ $Preferences{$Key} };
            my @Merged = ( @{ $Preferences{$Key} }, grep { !$Existing{$_}++ } @{ $Wanted{$Key} } );
            next KEY if @Merged == @{ $Preferences{$Key} };

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

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my %AllowedClasses = map { $_->{Name} => 1 } @{ $Param{Classes} || [] };

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

            next FIELD if $Self->_DynamicFieldConfigEqual(
                Left  => {
                    Name      => $Existing->{Name},
                    Label     => $Existing->{Label},
                    FieldType => $Existing->{FieldType},
                    Config    => $CurrentConfig,
                },
                Right => {
                    Name      => $FieldName,
                    Label     => $Label,
                    FieldType => $FieldType,
                    Config    => $Config,
                },
            );

            $DynamicFieldObject->DynamicFieldUpdate(
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

    if ( ref $Sanitized{ClassIDs} eq 'ARRAY' ) {
        my @ClassIDs = grep { $AllowedClasses->{$_} } @{ $Sanitized{ClassIDs} };
        $Sanitized{ClassIDs} = \@ClassIDs;
    }

    return \%Sanitized;
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
    my @DirtySettings   = (
        'DynamicFields::ObjectType###GovernanceObject',
        'DynamicFieldScreens###GovernanceDB',
        'DefaultColumnsScreens###GovernanceDB',
        'DynamicFieldScreens::ObjectTypes###GovernanceDB',
        'DynamicFields::Driver###GovernanceObject',
        'DynamicFields::Driver###GovernanceObjectVersion',
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

1;
