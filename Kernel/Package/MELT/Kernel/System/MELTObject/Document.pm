# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2019-2026 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::System::MELTObject::Document;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::MELTObject',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::MELTObject::Document - YAML/JSON document codec for MELT Objects.

=head1 DESCRIPTION

This module exposes a document-oriented import/export interface for Governance
Objects. It intentionally uses the existing MELTObject add/update APIs so
MELTIDs, versioning, history, link sync, and DynamicField drivers stay authoritative.

=cut

sub new {
    my ($Type) = @_;

    return bless {}, $Type;
}

=head2 Export()

Returns a hash reference or a YAML/JSON string for a MELT Object.

=cut

sub Export {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');
    my $MELTObject       = $MELTObjectObject->MELTObjectGet(
        MELTObjectID => $Param{MELTObjectID},
        VersionID          => $Param{VersionID},
        DynamicFields      => 1,
    );

    if ( !IsHashRefWithData($MELTObject) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Could not load MELT Object for document export.',
        );
        return;
    }

    my $Definition = $MELTObjectObject->DefinitionGet(
        ClassID => $MELTObject->{ClassID},
    );

    my %Fields;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( values %{ $Definition->{DynamicFieldRef} // {} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $Name  = $DynamicFieldConfig->{Name};
        my $Value = $MELTObject->{ 'DynamicField_' . $Name };

        next DYNAMICFIELD if !defined $Value;

        $Fields{$Name} = $Self->_ValueForDocument(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            UserID             => $Param{UserID},
        );
    }

    my $Document = {
        object_type => 'MELTObject',
        class       => $MELTObject->{Class},
        number      => $MELTObject->{Number},
        name        => $MELTObject->{Name},
        version     => $MELTObject->{VersionString},
        ztsm_status => $MELTObject->{ZTSMStatus},
        description => $MELTObject->{Description} // '',
        fields      => \%Fields,
    };

    return $Self->Serialize(
        Data   => $Document,
        Format => $Param{Format},
    ) if $Param{Format};

    return $Document;
}

=head2 Import()

Creates or updates a MELT Object from a parsed document or YAML/JSON string.

=cut

sub Import {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $Document = $Param{Data};
    if ( !ref $Document ) {
        $Document = $Self->Parse(
            Data   => $Param{Content},
            Format => $Param{Format},
        );
    }

    if ( !IsHashRefWithData($Document) ) {
        return {
            Success => 0,
            Message => 'Document must be a YAML or JSON object.',
        };
    }

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    my $ClassID = $Self->_ClassIDResolve( $Document->{class} || $Document->{Class} || $Param{Class} );
    if ( !$ClassID ) {
        return {
            Success => 0,
            Message => 'Could not resolve MELT Object class.',
        };
    }

    my $Status = $Document->{ztsm_status} // $Document->{ZTSMStatus} // $Document->{ZTSMStatusID};
    my $ZTSMStatusID = $Self->_GeneralCatalogIDResolve(
        Class => 'ZTSM::MELT::Status',
        Value => $Status,
    );

    if ( !$ZTSMStatusID ) {
        return {
            Success => 0,
            Message => 'Could not resolve ztsm_status.',
        };
    }

    my $Definition = $MELTObjectObject->DefinitionGet(
        ClassID => $ClassID,
    );

    if ( !IsHashRefWithData($Definition) || !IsHashRefWithData( $Definition->{DynamicFieldRef} ) ) {
        return {
            Success => 0,
            Message => 'Could not load MELT Object definition.',
        };
    }

    my %ObjectData = (
        ClassID       => $ClassID,
        Name          => $Document->{name} // $Document->{Name} // '',
        VersionString => $Document->{version} // $Document->{VersionString} // '1',
        ZTSMStatusID  => $ZTSMStatusID,
        Description   => $Document->{description} // $Document->{Description} // '',
        UserID        => $Param{UserID},
        ExternalSource => 1,
    );

    if ( IsStringWithData( $Document->{number} // $Document->{Number} ) ) {
        $ObjectData{Number} = $Document->{number} // $Document->{Number};
    }

    my $Fields = $Document->{fields} || $Document->{Fields} || {};
    if ( !ref $Fields || ref $Fields ne 'HASH' ) {
        return {
            Success => 0,
            Message => 'fields must be a YAML or JSON object.',
        };
    }

    FIELD:
    for my $FieldName ( sort keys %{$Fields} ) {
        my $DynamicFieldConfig = $Definition->{DynamicFieldRef}{$FieldName};
        next FIELD if !IsHashRefWithData($DynamicFieldConfig);
        next FIELD if $DynamicFieldConfig->{Readonly};

        my $Value = $Self->_ValueFromDocument(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Fields->{$FieldName},
            UserID             => $Param{UserID},
        );

        $ObjectData{ 'DynamicField_' . $FieldName } = $Value if defined $Value;
    }

    my $MELTObjectID = $Self->_ExistingObjectIDResolve(
        ClassID => $ClassID,
        Number  => $ObjectData{Number},
        Name    => $ObjectData{Name},
    );

    if ($MELTObjectID) {
        my $Access = $MELTObjectObject->Permission(
            Scope  => 'Item',
            ItemID => $MELTObjectID,
            Type   => 'rw',
            UserID => $Param{UserID},
        );

        if ( !$Access ) {
            return {
                Success => 0,
                Message => 'No write access is given for this MELT Object.',
            };
        }

        my $Success = $MELTObjectObject->MELTObjectUpdate(
            %ObjectData,
            MELTObjectID => $MELTObjectID,
            DefinitionID       => $Definition->{DefinitionID},
        );

        return {
            Success            => $Success ? 1 : 0,
            Action             => 'Updated',
            MELTObjectID => $MELTObjectID,
            Message            => $Success ? 'MELT Object updated.' : 'MELT Object update failed.',
        };
    }

    my $Access = $MELTObjectObject->Permission(
        Scope   => 'Class',
        ClassID => $ClassID,
        Type    => 'rw',
        UserID  => $Param{UserID},
    );

    if ( !$Access ) {
        return {
            Success => 0,
            Message => 'No write access is given for this MELT Object class.',
        };
    }

    my $NewMELTObjectID = $MELTObjectObject->MELTObjectAdd(%ObjectData);

    return {
        Success            => $NewMELTObjectID ? 1 : 0,
        Action             => 'Created',
        MELTObjectID => $NewMELTObjectID,
        Message            => $NewMELTObjectID ? 'MELT Object created.' : 'MELT Object create failed.',
    };
}

sub Parse {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Data} && !defined $Param{Content};

    my $Data   = defined $Param{Data} ? $Param{Data} : $Param{Content};
    my $Format = lc( $Param{Format} || '' );

    if ( !$Format ) {
        $Format = $Data =~ m{\A\s*[\{\[]}xms ? 'json' : 'yaml';
    }

    if ( $Format eq 'json' ) {
        return $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Data,
        );
    }

    return $Kernel::OM->Get('Kernel::System::YAML')->Load(
        Data => $Data,
    );
}

sub Serialize {
    my ( $Self, %Param ) = @_;

    my $Format = lc( $Param{Format} || 'yaml' );

    if ( $Format eq 'json' ) {
        return $Kernel::OM->Get('Kernel::System::JSON')->Encode(
            Data     => $Param{Data},
            SortKeys => 1,
            Pretty   => 1,
        );
    }

    return $Kernel::OM->Get('Kernel::System::YAML')->Dump(
        Data => $Param{Data},
    );
}

sub _ValueForDocument {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $Value              = $Param{Value};

    if ( $DynamicFieldConfig->{FieldType} eq 'Set' ) {
        return $Self->_SetValueForDocument(%Param);
    }

    if ( $Self->_IsMELTObjectReference($DynamicFieldConfig) ) {
        return $Self->_ReferenceValueForDocument(%Param);
    }

    if ( $DynamicFieldConfig->{FieldType} eq 'GeneralCatalog' ) {
        return $Self->_GeneralCatalogValueForDocument(%Param);
    }

    return $Value;
}

sub _ValueFromDocument {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};

    if ( $DynamicFieldConfig->{FieldType} eq 'Set' ) {
        return $Self->_SetValueFromDocument(%Param);
    }

    if ( $Self->_IsMELTObjectReference($DynamicFieldConfig) ) {
        return $Self->_ReferenceValueFromDocument(%Param);
    }

    if ( $DynamicFieldConfig->{FieldType} eq 'GeneralCatalog' ) {
        return $Self->_GeneralCatalogValueFromDocument(%Param);
    }

    return $Param{Value};
}

sub _ReferenceValueForDocument {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};

    if ( ref $Value eq 'ARRAY' ) {
        return [
            map { $Self->_SingleReferenceForDocument( DynamicFieldConfig => $Param{DynamicFieldConfig}, Value => $_ ) }
                @{$Value}
        ];
    }

    return $Self->_SingleReferenceForDocument(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Value              => $Value,
    );
}

sub _ReferenceValueFromDocument {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};

    if ( ref $Value eq 'ARRAY' ) {
        return [
            map {
                $Self->_SingleReferenceFromDocument(
                    DynamicFieldConfig => $Param{DynamicFieldConfig},
                    Value              => $_,
                    UserID             => $Param{UserID},
                )
            } @{$Value}
        ];
    }

    return $Self->_SingleReferenceFromDocument(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Value              => $Value,
        UserID             => $Param{UserID},
    );
}

sub _SingleReferenceForDocument {
    my ( $Self, %Param ) = @_;

    return $Param{Value} if !defined $Param{Value} || $Param{Value} eq '';

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');
    my %GetParam = $Param{DynamicFieldConfig}->{FieldType} eq 'MELTObjectVersion'
        ? ( VersionID => $Param{Value} )
        : ( MELTObjectID => $Param{Value} );

    my $MELTObject = $MELTObjectObject->MELTObjectGet(
        %GetParam,
        DynamicFields => 1,
        Silent        => 1,
    );

    return $Param{Value} if !IsHashRefWithData($MELTObject);

    return $MELTObject->{'DynamicField_ZTSM-Code'}
        || $MELTObject->{Name}
        || $MELTObject->{Number}
        || $Param{Value};
}

sub _SingleReferenceFromDocument {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    return $Value if !defined $Value || ref $Value;
    return '' if $Value eq '';

    if ( $Value =~ m{\A.*::(?<ID>\d+)\z}xms ) {
        return $+{ID};
    }

    my $ID = $Self->_GovernanceReferenceIDResolve(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Value              => $Value,
        UserID             => $Param{UserID},
    );

    return $ID if $ID;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "Could not resolve MELT Object reference '$Value' for $Param{DynamicFieldConfig}->{Name}.",
    );

    return;
}

sub _GovernanceReferenceIDResolve {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $Value              = $Param{Value};

    my @ClassIDs = $Self->_GeneralCatalogRestrictionIDsGet(
        Class  => 'ZTSM::MELT::Class',
        Values => $DynamicFieldConfig->{Config}{ClassIDs},
    );

    my @Attempts = (
        { Name   => $Value },
        { Number => $Value },
        {
            'DynamicField_ZTSM-Code' => {
                Equals => $Value,
            },
        },
    );

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');
    ATTEMPT:
    for my $Attempt (@Attempts) {
        my @IDs = $MELTObjectObject->MELTObjectSearch(
            Result     => 'ARRAY',
            Limit      => 2,
            ClassIDs   => IsArrayRefWithData(\@ClassIDs) ? \@ClassIDs : undef,
            Permission => 'ro',
            UserID     => $Param{UserID} || 1,
            %{$Attempt},
        );

        next ATTEMPT if @IDs != 1;

        if ( $DynamicFieldConfig->{FieldType} eq 'MELTObjectVersion' ) {
            my $MELTObject = $MELTObjectObject->MELTObjectGet(
                MELTObjectID => $IDs[0],
                DynamicFields      => 0,
            );
            return $MELTObject->{VersionID};
        }

        return $IDs[0];
    }

    return;
}

sub _GeneralCatalogValueForDocument {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};

    if ( ref $Value eq 'ARRAY' ) {
        return [
            map { $Self->_SingleGeneralCatalogValueForDocument( DynamicFieldConfig => $Param{DynamicFieldConfig}, Value => $_ ) }
                @{$Value}
        ];
    }

    return $Self->_SingleGeneralCatalogValueForDocument(%Param);
}

sub _GeneralCatalogValueFromDocument {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};

    if ( ref $Value eq 'ARRAY' ) {
        return [
            map { $Self->_SingleGeneralCatalogValueFromDocument( DynamicFieldConfig => $Param{DynamicFieldConfig}, Value => $_ ) }
                @{$Value}
        ];
    }

    return $Self->_SingleGeneralCatalogValueFromDocument(%Param);
}

sub _SingleGeneralCatalogValueForDocument {
    my ( $Self, %Param ) = @_;

    return $Param{Value} if !defined $Param{Value} || $Param{Value} !~ m{\A\d+\z}xms;

    my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
        ItemID => $Param{Value},
    );

    return IsHashRefWithData($Item) ? $Item->{Name} : $Param{Value};
}

sub _SingleGeneralCatalogValueFromDocument {
    my ( $Self, %Param ) = @_;

    return $Param{Value} if !defined $Param{Value} || $Param{Value} eq '' || $Param{Value} =~ m{\A\d+\z}xms;

    my $Class = $Param{DynamicFieldConfig}->{Config}->{Class};
    return $Param{Value} if !$Class;

    return $Self->_GeneralCatalogIDResolve(
        Class => $Class,
        Value => $Param{Value},
    ) || $Param{Value};
}

sub _SetValueForDocument {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    return $Value if ref $Value ne 'ARRAY';

    my $IncludedFields = $Self->_IncludedDynamicFieldsGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
    );

    return $Value if !IsHashRefWithData($IncludedFields);

    my @Rows;
    ROW:
    for my $Row ( @{$Value} ) {
        next ROW if ref $Row ne 'HASH';

        my %DocumentRow;
        FIELD:
        for my $FieldName ( sort keys %{$Row} ) {
            my $InnerField = $IncludedFields->{$FieldName};
            next FIELD if !IsHashRefWithData($InnerField);

            $DocumentRow{$FieldName} = $Self->_ValueForDocument(
                DynamicFieldConfig => $InnerField,
                Value              => $Row->{$FieldName},
                UserID             => $Param{UserID},
            );
        }

        push @Rows, \%DocumentRow;
    }

    return \@Rows;
}

sub _SetValueFromDocument {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    return $Value if ref $Value ne 'ARRAY';

    my $IncludedFields = $Self->_IncludedDynamicFieldsGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
    );

    return $Value if !IsHashRefWithData($IncludedFields);

    my @Rows;
    ROW:
    for my $Row ( @{$Value} ) {
        next ROW if ref $Row ne 'HASH';

        my %ImportRow;
        FIELD:
        for my $FieldName ( sort keys %{$Row} ) {
            my $InnerField = $IncludedFields->{$FieldName};
            next FIELD if !IsHashRefWithData($InnerField);

            my $ImportValue = $Self->_ValueFromDocument(
                DynamicFieldConfig => $InnerField,
                Value              => $Row->{$FieldName},
                UserID             => $Param{UserID},
            );

            $ImportRow{$FieldName} = defined $ImportValue ? $ImportValue : '';
        }

        # DynamicField Set edit widgets can otherwise fall back to a first
        # selectable reference value for omitted child fields. Missing means blank.
        MISSINGFIELD:
        for my $FieldName ( sort keys %{$IncludedFields} ) {
            next MISSINGFIELD if exists $ImportRow{$FieldName};

            $ImportRow{$FieldName} = '';
        }

        push @Rows, \%ImportRow;
    }

    return \@Rows;
}

sub _IncludedDynamicFieldsGet {
    my ( $Self, %Param ) = @_;

    my $Include = $Param{DynamicFieldConfig}->{Config}->{Include};
    return if ref $Include ne 'ARRAY';

    my %DynamicFields;
    INCLUDE:
    for my $Entry ( @{$Include} ) {
        my $Name = ref $Entry eq 'HASH' ? $Entry->{DF} : $Entry;
        next INCLUDE if !$Name;

        my $DynamicField = $Entry->{Definition} || $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $Name,
        );
        next INCLUDE if !IsHashRefWithData($DynamicField);

        my %DynamicFieldCopy = %{$DynamicField};
        $DynamicFieldCopy{Config} = {
            %{ $DynamicFieldCopy{Config} || {} },
        };

        $Self->_SetChildReferenceConfigApply(
            DynamicFieldConfig => \%DynamicFieldCopy,
        );

        $DynamicFields{ $DynamicFieldCopy{Name} || $Name } = \%DynamicFieldCopy;
    }

    return \%DynamicFields;
}

sub _SetChildReferenceConfigApply {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    return if !IsHashRefWithData($DynamicFieldConfig);

    my $Name   = $DynamicFieldConfig->{Name} || '';
    my $Config = $DynamicFieldConfig->{Config} ||= {};

    my %MELTObjectClassByField = (
        'ZBlue-Profile'    => ['GovernanceRole'],
        'ZBlue-Role'       => ['GovernanceRole'],
        'ZBlue-Template'   => ['Template'],
        'ZBlue-PurpleBook' => ['BlueBook'],
    );

    my %MELTObjectFieldDefaults = (
        'ZBlue-Profile' => {
            MultiValue   => 0,
            PossibleNone => 0,
        },
        'ZBlue-Role' => {
            MultiValue   => 0,
            PossibleNone => 1,
        },
        'ZBlue-Template' => {
            MultiValue   => 0,
            PossibleNone => 1,
        },
        'ZBlue-PurpleBook' => {
            MultiValue   => 0,
            PossibleNone => 1,
        },
    );

    if (
        $Self->_IsMELTObjectReference($DynamicFieldConfig)
        && !IsArrayRefWithData( $Config->{ClassIDs} )
        && IsArrayRefWithData( $MELTObjectClassByField{$Name} )
        )
    {
        my @ClassIDs = $Self->_GeneralCatalogRestrictionIDsGet(
            Class  => 'ZTSM::MELT::Class',
            Values => $MELTObjectClassByField{$Name},
        );
        $Config->{ClassIDs} = \@ClassIDs if @ClassIDs;
    }

    if ( IsHashRefWithData( $MELTObjectFieldDefaults{$Name} ) ) {
        for my $Key ( sort keys %{ $MELTObjectFieldDefaults{$Name} } ) {
            $Config->{$Key} = $MELTObjectFieldDefaults{$Name}->{$Key}
                if !defined $Config->{$Key};
        }
    }

    my %GeneralCatalogClassByField = (
        'ZBlue-TicketType' => 'ZTSM::Type',
    );

    my %GeneralCatalogFieldDefaults = (
        'ZBlue-TicketType' => {
            MultiValue   => 0,
            PossibleNone => 0,
        },
    );

    if (
        ( $DynamicFieldConfig->{FieldType} || '' ) eq 'GeneralCatalog'
        && !$Config->{Class}
        && $GeneralCatalogClassByField{$Name}
        )
    {
        $Config->{Class} = $GeneralCatalogClassByField{$Name};
    }

    if ( IsHashRefWithData( $GeneralCatalogFieldDefaults{$Name} ) ) {
        for my $Key ( sort keys %{ $GeneralCatalogFieldDefaults{$Name} } ) {
            $Config->{$Key} = $GeneralCatalogFieldDefaults{$Name}->{$Key}
                if !defined $Config->{$Key};
        }
    }

    return 1;
}

sub _ExistingObjectIDResolve {
    my ( $Self, %Param ) = @_;

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    if ( IsStringWithData( $Param{Number} ) ) {
        my $ID = $MELTObjectObject->MELTObjectLookup(
            MELTID => $Param{Number},
        );
        return $ID if $ID;
    }

    return if !IsStringWithData( $Param{Name} );

    my @IDs = $MELTObjectObject->MELTObjectSearch(
        Result   => 'ARRAY',
        Limit    => 2,
        ClassIDs => [ $Param{ClassID} ],
        Name     => $Param{Name},
        UserID   => 1,
    );

    return @IDs == 1 ? $IDs[0] : undef;
}

sub _ClassIDResolve {
    my ( $Self, $Value ) = @_;

    return if !defined $Value || $Value eq '';
    return $Value if $Value =~ m{\A\d+\z}xms;

    return $Self->_GeneralCatalogIDResolve(
        Class => 'ZTSM::MELT::Class',
        Value => $Value,
    );
}

sub _GeneralCatalogIDResolve {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Value} || $Param{Value} eq '';
    return $Param{Value} if $Param{Value} =~ m{\A\d+\z}xms;

    my $List = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => $Param{Class},
    );

    return if ref $List ne 'HASH';

    my @Matches = grep { $List->{$_} eq $Param{Value} } keys %{$List};
    return @Matches == 1 ? $Matches[0] : undef;
}

sub _GeneralCatalogRestrictionIDsGet {
    my ( $Self, %Param ) = @_;

    return if !IsArrayRefWithData( $Param{Values} );

    my @IDs;
    VALUE:
    for my $Value ( @{ $Param{Values} } ) {
        my $ID = $Self->_GeneralCatalogIDResolve(
            Class => $Param{Class},
            Value => $Value,
        );
        push @IDs, $ID if $ID;
    }

    return @IDs;
}

sub _IsMELTObjectReference {
    my ( $Self, $DynamicFieldConfig ) = @_;

    return $DynamicFieldConfig->{FieldType} eq 'MELTObject'
        || $DynamicFieldConfig->{FieldType} eq 'MELTObjectVersion';
}

1;

