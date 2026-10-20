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

    my $Number = $Document->{number} // '';
    my $ConfigItemID = $Number ? $ConfigItemObject->ConfigItemLookup( ConfigItemNumber => $Number ) : 0;
    my $Existing = $ConfigItemID ? $ConfigItemObject->ConfigItemGet(
        ConfigItemID => $ConfigItemID,
        DynamicFields => 1,
    ) : {};
    return { Success => 0, Message => 'Existing ConfigItem could not be read for merge.' }
        if $ConfigItemID && !IsHashRefWithData($Existing);
    my $Version = $Document->{version};
    $Version = $ConfigItemID ? $Existing->{VersionString} : '1'
        if !defined $Version || $Version !~ m{\S};

    my %ObjectData = (
        ClassID       => $ClassID,
        Name          => $Document->{name} // '',
        VersionString => $Version,
        Description   => $Document->{description} // '',
        UserID        => $Param{UserID},
    );
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
        my $Value = eval { $Self->_ValueFromDocument(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Fields->{$Name},
            UserID             => $Param{UserID},
        ) };
        if ($@) {
            my $Error = $@;
            $Error =~ s{\s+\z}{};
            return { Success => 0, Message => "Field '$Name': $Error No changes were saved." };
        }
        if ( $Self->_IsPortableObjectReference($DynamicFieldConfig) ) {
            my @Input = ref $Fields->{$Name} eq 'ARRAY' ? @{ $Fields->{$Name} } : ( $Fields->{$Name} );
            my @Resolved = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);
            for my $Index ( 0 .. $#Input ) {
                next if !defined $Input[$Index] || $Input[$Index] eq '';
                return { Success => 0, Message => "Field '$Name' contains an unresolved or ambiguous reference. No changes were saved." }
                    if !defined $Resolved[$Index] || $Resolved[$Index] eq '';
            }
        }
        if ( $DynamicFieldConfig->{FieldType} =~ /\A(?:Date|DateTime)\z/ ) {
            my $Converted = eval { $Self->_ImportDateNormalize(
                Value => $Fields->{$Name}, FieldType => $DynamicFieldConfig->{FieldType},
                Excel => ($Param{Source} || '') eq 'Excel Import', ExcelDate1904 => $Param{ExcelDate1904} ); };
            return { Success => 0, Message => "Field '$Name' has an invalid date. Use YYYY-MM-DD or YYYY-MM-DD HH:MM:SS. No changes were saved." } if $@;
            $Value = $Converted;
        }
        $ObjectData{ 'DynamicField_' . $Name } = $Value;
    }

    my $UsesAssetTag = IsHashRefWithData( $Definition->{DynamicFieldRef}->{'ZTAM-AssetTag'} );
    # A blank import cell merges with the current identity instead of replacing it.
    if ( $UsesAssetTag && $ConfigItemID
        && ( !defined $ObjectData{'DynamicField_ZTAM-AssetTag'}
            || $ObjectData{'DynamicField_ZTAM-AssetTag'} !~ m{\S} ) )
    {
        $ObjectData{'DynamicField_ZTAM-AssetTag'} = $Existing->{'DynamicField_ZTAM-AssetTag'};
    }
    my $VirtualAssetCode = '';
    if ( $UsesAssetTag && ( $ObjectData{'DynamicField_ZTAM-AssetTag'} // '' ) !~ m{\S} ) {
        my $ApplicationID = $ObjectData{'DynamicField_ZTAM-Application'};
        $ApplicationID = $ApplicationID->[0] if ref $ApplicationID eq 'ARRAY';
        my $Application = $ApplicationID
            ? $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
                GovernanceObjectID => $ApplicationID,
                DynamicFields      => 1,
            )
            : {};
        return { Success => 0, Message => 'ZTAM-AssetTag is empty and the Application cannot be resolved.' }
            if !IsHashRefWithData($Application);
        $VirtualAssetCode = $Application->{'DynamicField_ZTSM-Code'} // '';
    }

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
    if ( $Success && $UsesAssetTag && ( $ObjectData{'DynamicField_ZTAM-AssetTag'} // '' ) !~ m{\S} ) {
        my $Pattern = $Kernel::OM->Get('Kernel::Config')->Get('TESSERA::CMDB::VirtualAssetTag###Pattern')
            || '<ZTSM-Code>-VT-<running id>';
        # An Application code is optional; a resolved Application is still required.
        $Pattern = 'tessera-virtualtag-<running id>' if $VirtualAssetCode !~ m{\S};
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

sub _ImportDateNormalize {
    my ( $Self, %Param ) = @_;
    my $Value = $Param{Value};
    return $Value if !defined $Value || $Value eq '';
    die "Invalid date value" if ref $Value;
    require DateTime;
    $Value =~ s/\A\s+|\s+\z//g;
    return '' if $Value eq '';
    my $Date;
    if ( $Param{Excel} && $Value =~ /\A\d+(?:\.\d+)?\z/ ) {
        die "Excel date out of range" if $Value > 2958465;
        my $Day = int($Value);
        die "Excel's fictional leap day is invalid" if !$Param{ExcelDate1904} && $Day == 60;
        $Date = DateTime->new( year => $Param{ExcelDate1904} ? 1904 : 1899,
            month => $Param{ExcelDate1904} ? 1 : 12, day => $Param{ExcelDate1904} ? 1 : 31,
            time_zone => 'floating' );
        $Day-- if !$Param{ExcelDate1904} && $Day > 60;
        $Date->add( days => $Day, seconds => int(($Value - int($Value)) * 86400 + 0.5) );
    }
    else {
        my ($Y,$M,$D,$h,$m,$s) = $Value =~ /\A(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?\z/;
        die "Unsupported date string" if !defined $Y;
        $Date = DateTime->new( year=>$Y, month=>$M, day=>$D, hour=>$h || 0,
            minute=>$m || 0, second=>$s || 0, time_zone=>'floating' );
    }
    die "Date year out of range" if $Date->year < 1900 || $Date->year > 9999;
    return $Date->ymd . ' ' . ($Param{FieldType} eq 'Date' ? '00:00:00' : $Date->hms);
}

1;
