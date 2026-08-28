# --
# TESSERA ConfigItem YAML/JSON document codec.
# --
package Kernel::System::ITSMConfigItem::Document;

use v5.24;
use strict;
use warnings;
use parent qw(Kernel::System::GovernanceObject::Document);
use namespace::autoclean;

use Kernel::System::VariableCheck qw(IsHashRefWithData IsStringWithData);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CustomerCompany',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::FAQ',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::System::GovernanceObject',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::ITSMConfigItem::Activity',
    'Kernel::System::Log',
    'Kernel::System::Queue',
    'Kernel::System::Service',
    'Kernel::System::SLA',
    'Kernel::System::Ticket',
    'Kernel::System::Type',
    'Kernel::System::User',
    'Kernel::System::YAML',
);

sub Export {
    my ( $Self, %Param ) = @_;

    return if !$Param{ConfigItemID} || !$Param{UserID};

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $ConfigItem = $ConfigItemObject->ConfigItemGet(
        ConfigItemID  => $Param{ConfigItemID},
        VersionID     => $Param{VersionID},
        DynamicFields => 1,
    );
    return if !IsHashRefWithData($ConfigItem);

    my $Definition = $ConfigItemObject->DefinitionGet(
        DefinitionID => $ConfigItem->{DefinitionID},
    );
    my %Fields;
    for my $DynamicFieldConfig ( values %{ $Definition->{DynamicFieldRef} // {} } ) {
        next if !IsHashRefWithData($DynamicFieldConfig) || !$DynamicFieldConfig->{Name};
        my $Name  = $DynamicFieldConfig->{Name};
        my $Value = $ConfigItem->{ 'DynamicField_' . $Name };
        next if !defined $Value;
        $Fields{$Name} = $Self->_ValueForDocument(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            UserID             => $Param{UserID},
        );
    }

    my $Document = {
        object_type     => 'ITSMConfigItem',
        class           => $ConfigItem->{Class},
        number          => $ConfigItem->{Number},
        name            => $ConfigItem->{Name},
        version         => $ConfigItem->{VersionString},
        deployment_state => $ConfigItem->{DeplState},
        incident_state   => $ConfigItem->{InciState},
        description     => $Self->_RichTextValueForDocument(
            Value => $ConfigItem->{Description} // '',
        ),
        fields          => \%Fields,
    };

    return $Param{Format}
        ? $Self->Serialize( Data => $Document, Format => $Param{Format} )
        : $Document;
}

sub Import {
    my ( $Self, %Param ) = @_;

    return { Success => 0, Message => 'Need UserID.' } if !$Param{UserID};
    my $Document = ref $Param{Data} ? $Param{Data} : $Self->Parse(
        Content => $Param{Content},
        Format  => $Param{Format},
    );
    return { Success => 0, Message => 'Document must be a YAML or JSON object.' }
        if !IsHashRefWithData($Document);
    return { Success => 0, Message => 'object_type must be ITSMConfigItem.' }
        if ( $Document->{object_type} // 'ITSMConfigItem' ) ne 'ITSMConfigItem';

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ClassList = $GeneralCatalogObject->ItemList( Class => 'ITSM::ConfigItem::Class' ) || {};
    my ($ClassID) = grep { $ClassList->{$_} eq ( $Document->{class} // '' ) } keys %{$ClassList};
    return { Success => 0, Message => 'Unknown ConfigItem class name.' } if !$ClassID;

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $Definition = $ConfigItemObject->DefinitionGet( ClassID => $ClassID );
    return { Success => 0, Message => 'No active definition exists for this class.' }
        if !IsHashRefWithData($Definition);

    my %ObjectData = (
        ClassID       => $ClassID,
        Name          => $Document->{name} // '',
        VersionString => $Document->{version} // '1',
        Description   => $Document->{description} // '',
        UserID        => $Param{UserID},
    );
    my $Number = $Document->{number} // '';
    $ObjectData{Number} = $Number if IsStringWithData($Number);

    for my $StateSpec (
        [ DeplStateID => 'ITSM::ConfigItem::DeploymentState', $Document->{deployment_state} ],
        [ InciStateID => 'ITSM::Core::IncidentState',         $Document->{incident_state} ],
        )
    {
        my $Items = $GeneralCatalogObject->ItemList( Class => $StateSpec->[1] ) || {};
        my ($ID) = grep { $Items->{$_} eq ( $StateSpec->[2] // '' ) } keys %{$Items};
        return { Success => 0, Message => "Unknown state name '$StateSpec->[2]'." } if !$ID;
        $ObjectData{ $StateSpec->[0] } = $ID;
    }

    my $Fields = $Document->{fields} // {};
    return { Success => 0, Message => 'fields must be an object.' } if ref $Fields ne 'HASH';
    for my $Name ( sort keys %{$Fields} ) {
        my $DynamicFieldConfig = $Definition->{DynamicFieldRef}->{$Name};
        return { Success => 0, Message => "Field '$Name' is not in class '$Document->{class}'." }
            if !IsHashRefWithData($DynamicFieldConfig);
        my $Value = $Self->_ValueFromDocument(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Fields->{$Name},
            UserID             => $Param{UserID},
        );
        $ObjectData{ 'DynamicField_' . $Name } = $Value;
    }

    my $UsesAssetTag = IsHashRefWithData( $Definition->{DynamicFieldRef}->{'ZTAM-AssetTag'} );
    my $VirtualAssetCode = '';
    if ( $UsesAssetTag && !$ObjectData{'DynamicField_ZTAM-AssetTag'} ) {
        my $ApplicationID = $ObjectData{'DynamicField_ZTAM-Application'};
        $ApplicationID = $ApplicationID->[0] if ref $ApplicationID eq 'ARRAY';
        my $Application = $ApplicationID
            ? $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
                GovernanceObjectID => $ApplicationID,
                DynamicFields      => 1,
            )
            : {};
        $VirtualAssetCode = IsHashRefWithData($Application) ? $Application->{'DynamicField_ZTSM-Code'} : '';
        return { Success => 0, Message => 'ZTAM-AssetTag is empty and the Application ZTSM-Code cannot be resolved.' }
            if !IsStringWithData($VirtualAssetCode);
    }

    my $ConfigItemID = $Number ? $ConfigItemObject->ConfigItemLookup( ConfigItemNumber => $Number ) : 0;
    my $Success;
    if ($ConfigItemID) {
        $Success = $ConfigItemObject->ConfigItemUpdate(
            %ObjectData,
            ConfigItemID => $ConfigItemID,
        );
    }
    else {
        $ConfigItemID = $ConfigItemObject->ConfigItemAdd(%ObjectData);
        $Success = $ConfigItemID;
    }

    # Virtual assets have no physical tag. Generate a stable, readable tag only
    # after the ConfigItem has an ID; the ConfigItemID is the monotonic running ID.
    if ( $Success && $UsesAssetTag && !$ObjectData{'DynamicField_ZTAM-AssetTag'} ) {
        my $Pattern = $Kernel::OM->Get('Kernel::Config')->Get('TESSERA::CMDB::VirtualAssetTag###Pattern')
            || '<ZTSM-Code>-VT-<running id>';
        $Pattern =~ s{<ZTSM-Code>}{$VirtualAssetCode}g;
        $Pattern =~ s{<running id>}{$ConfigItemID}g;
        $Success = $ConfigItemObject->ConfigItemUpdate(
            ConfigItemID                 => $ConfigItemID,
            UserID                       => $Param{UserID},
            'DynamicField_ZTAM-AssetTag' => $Pattern,
        );
    }

    if ($Success) {
        my $Operation = $Document->{number} ? 'Update' : 'Create';
        $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Activity')->ActivityAdd(
            ConfigItemID => $ConfigItemID,
            EventType    => 'DocumentImport',
            Source       => $Param{Source} || 'YAML/JSON Import',
            Subject      => "$Operation ConfigItem from structured document",
            Body         => "$Operation completed through " . ( $Param{Source} || 'YAML/JSON Import' ) . '.',
            Payload      => $Document,
            UserID       => $Param{UserID},
        );
        return { Success => 1, ConfigItemID => $ConfigItemID, Message => 'ConfigItem document imported.' };
    }
    return { Success => 0, Message => 'ConfigItem import failed.' };
}

1;
