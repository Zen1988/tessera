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

package Kernel::System::GovernanceObject::Document;

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
    'Kernel::System::HTMLUtils',
    'Kernel::System::GovernanceObject',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::GovernanceObject::Document - YAML/JSON document codec for Governance Objects.

=head1 DESCRIPTION

This module exposes a document-oriented import/export interface for Governance
Objects. It intentionally uses the existing GovernanceObject add/update APIs so
GOIDs, versioning, history, link sync, and DynamicField drivers stay authoritative.

=cut

sub new {
    my ($Type) = @_;

    return bless {}, $Type;
}

=head2 Export()

Returns a hash reference or a YAML/JSON string for a Governance Object.

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

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $GovernanceObject       = $GovernanceObjectObject->GovernanceObjectGet(
        GovernanceObjectID => $Param{GovernanceObjectID},
        VersionID          => $Param{VersionID},
        DynamicFields      => 1,
    );

    if ( !IsHashRefWithData($GovernanceObject) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Could not load Governance Object for document export.',
        );
        return;
    }

    my $Definition = $GovernanceObjectObject->DefinitionGet(
        ClassID => $GovernanceObject->{ClassID},
    );

    my %Fields;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( values %{ $Definition->{DynamicFieldRef} // {} } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $Name  = $DynamicFieldConfig->{Name};
        my $Value = $GovernanceObject->{ 'DynamicField_' . $Name };

        next DYNAMICFIELD if !defined $Value;

        $Fields{$Name} = $Self->_ValueForDocument(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            UserID             => $Param{UserID},
        );
    }

    my $Document = {
        object_type => 'GovernanceObject',
        class       => $GovernanceObject->{Class},
        number      => $GovernanceObject->{Number},
        name        => $GovernanceObject->{Name},
        version     => $GovernanceObject->{VersionString},
        ztsm_status => $GovernanceObject->{ZTSMStatus},
        description => $Self->_RichTextValueForDocument(
            Value => $GovernanceObject->{Description} // '',
        ),
        fields      => \%Fields,
    };

    return $Self->Serialize(
        Data   => $Document,
        Format => $Param{Format},
    ) if $Param{Format};

    return $Document;
}

=head2 Import()

Creates or updates a Governance Object from a parsed document or YAML/JSON string.

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

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    my $ClassID = $Self->_ClassIDResolve( $Document->{class} || $Document->{Class} || $Param{Class} );
    if ( !$ClassID ) {
        return {
            Success => 0,
            Message => 'Could not resolve Governance Object class.',
        };
    }

    my $Status = $Document->{ztsm_status} // $Document->{ZTSMStatus} // $Document->{ZTSMStatusID};
    my $ZTSMStatusID = $Self->_GeneralCatalogIDResolve(
        Class => 'ZTSM::GovernanceObject::Status',
        Value => $Status,
    );

    if ( !$ZTSMStatusID ) {
        return {
            Success => 0,
            Message => 'Could not resolve ztsm_status.',
        };
    }

    my $Definition = $GovernanceObjectObject->DefinitionGet(
        ClassID => $ClassID,
    );

    if ( !IsHashRefWithData($Definition) || !IsHashRefWithData( $Definition->{DynamicFieldRef} ) ) {
        return {
            Success => 0,
            Message => 'Could not load Governance Object definition.',
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

    my $GovernanceObjectID = $Self->_ExistingObjectIDResolve(
        ClassID => $ClassID,
        Number  => $ObjectData{Number},
        Name    => $ObjectData{Name},
        MatchByName => exists $Param{MatchByName} ? $Param{MatchByName} : 1,
    );

    if ($GovernanceObjectID) {
        my $Access = $GovernanceObjectObject->Permission(
            Scope  => 'Item',
            ItemID => $GovernanceObjectID,
            Type   => 'rw',
            UserID => $Param{UserID},
        );

        if ( !$Access ) {
            return {
                Success => 0,
                Message => 'No write access is given for this Governance Object.',
            };
        }

        my $Success = $GovernanceObjectObject->GovernanceObjectUpdate(
            %ObjectData,
            GovernanceObjectID => $GovernanceObjectID,
            DefinitionID       => $Definition->{DefinitionID},
        );

        return {
            Success            => $Success ? 1 : 0,
            Action             => 'Updated',
            GovernanceObjectID => $GovernanceObjectID,
            Message            => $Success ? 'Governance Object updated.' : 'Governance Object update failed.',
        };
    }

    my $Access = $GovernanceObjectObject->Permission(
        Scope   => 'Class',
        ClassID => $ClassID,
        Type    => 'rw',
        UserID  => $Param{UserID},
    );

    if ( !$Access ) {
        return {
            Success => 0,
            Message => 'No write access is given for this Governance Object class.',
        };
    }

    my $NewGovernanceObjectID = $GovernanceObjectObject->GovernanceObjectAdd(%ObjectData);

    return {
        Success            => $NewGovernanceObjectID ? 1 : 0,
        Action             => 'Created',
        GovernanceObjectID => $NewGovernanceObjectID,
        Message            => $NewGovernanceObjectID ? 'Governance Object created.' : 'Governance Object create failed.',
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

    if ( $DynamicFieldConfig->{FieldType} eq 'RichText' ) {
        return $Self->_RichTextValueForDocument( Value => $Value );
    }

    if ( $DynamicFieldConfig->{FieldType} eq 'Set' ) {
        return $Self->_SetValueForDocument(%Param);
    }

    if ( $Self->_IsPortableObjectReference($DynamicFieldConfig) ) {
        return $Self->_ReferenceValueForDocument(%Param);
    }

    if ( $DynamicFieldConfig->{FieldType} eq 'GeneralCatalog' ) {
        return $Self->_GeneralCatalogValueForDocument(%Param);
    }

    return $Value;
}

sub _RichTextValueForDocument {
    my ( $Self, %Param ) = @_;
    my $Value = $Param{Value};
    return $Value if !defined $Value || ref $Value;

    # RichText storage contains CKEditor HTML. Export the authored information,
    # not editor markup, attributes, widgets, or CK-specific wrapper state.
    my $Text = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
        String => $Value,
    );
    $Text //= '';
    $Text =~ s{\x{00A0}}{ }g;
    $Text =~ s{[ \t]+\n}{\n}g;
    $Text =~ s{\A\s+|\s+\z}{}g;
    return $Text;
}

sub _ValueFromDocument {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};

    if ( $DynamicFieldConfig->{FieldType} eq 'Set' ) {
        return $Self->_SetValueFromDocument(%Param);
    }

    if ( $Self->_IsPortableObjectReference($DynamicFieldConfig) ) {
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

    if ( $Param{DynamicFieldConfig}->{FieldType} =~ m{\AConfigItem(?:Version)?\z}xms ) {
        return $Self->_SingleConfigItemReferenceForDocument(%Param);
    }

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %GetParam = $Param{DynamicFieldConfig}->{FieldType} eq 'GovernanceObjectVersion'
        ? ( VersionID => $Param{Value} )
        : ( GovernanceObjectID => $Param{Value} );

    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        %GetParam,
        DynamicFields => 1,
        Silent        => 1,
    );

    return if !IsHashRefWithData($GovernanceObject);

    return ( $GovernanceObject->{Class} && $GovernanceObject->{Name} )
        ? "$GovernanceObject->{Class}: $GovernanceObject->{Name}"
        : $GovernanceObject->{Name}
        || $GovernanceObject->{Number};
}

sub _SingleReferenceFromDocument {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    return $Value if !defined $Value || ref $Value;
    return '' if $Value eq '';

    if ( $Value =~ m{\A.*::(?<ID>\d+)\z}xms ) {
        return $+{ID};
    }

    if ( $Param{DynamicFieldConfig}->{FieldType} =~ m{\AConfigItem(?:Version)?\z}xms ) {
        return $Self->_ConfigItemReferenceIDResolve(%Param);
    }

    my $ID = $Self->_GovernanceReferenceIDResolve(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Value              => $Value,
        UserID             => $Param{UserID},
    );

    return $ID if $ID;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "Could not resolve Governance Object reference '$Value' for $Param{DynamicFieldConfig}->{Name}.",
    );

    return;
}

sub _SingleConfigItemReferenceForDocument {
    my ( $Self, %Param ) = @_;

    my %GetParam = $Param{DynamicFieldConfig}->{FieldType} eq 'ConfigItemVersion'
        ? ( VersionID => $Param{Value} )
        : ( ConfigItemID => $Param{Value} );
    my $ConfigItem = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        %GetParam,
        DynamicFields => 0,
        Silent        => 1,
    );

    return if !IsHashRefWithData($ConfigItem);
    return if !$ConfigItem->{Class} || !$ConfigItem->{Name};
    return "$ConfigItem->{Class}: $ConfigItem->{Name}";
}

sub _ConfigItemReferenceIDResolve {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    my ( $ClassName, $Name ) = $Value =~ m{\A\s*([^:]+?)\s*:\s*(.+?)\s*\z}xms;
    return if !$ClassName || !$Name;

    my $Classes = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    ) || {};
    my ($ClassID) = grep { lc( $Classes->{$_} // '' ) eq lc $ClassName } keys %{$Classes};
    return if !$ClassID;

    my @AllowedClassIDs = @{ $Param{DynamicFieldConfig}->{Config}->{ClassIDs} || [] };
    return if @AllowedClassIDs && !grep { $_ == $ClassID } @AllowedClassIDs;

    my @IDs = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemSearch(
        Result     => 'ARRAY',
        Limit      => 2,
        ClassIDs   => [$ClassID],
        Name       => $Name,
        Permission => 'ro',
        UserID     => $Param{UserID} || 1,
    );
    return if @IDs != 1;

    return $IDs[0] if $Param{DynamicFieldConfig}->{FieldType} eq 'ConfigItem';
    my $ConfigItem = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID => $IDs[0],
        DynamicFields => 0,
        Silent        => 1,
    );
    return IsHashRefWithData($ConfigItem) ? $ConfigItem->{VersionID} : undef;
}

sub _GovernanceReferenceIDResolve {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $Value              = $Param{Value};
    my $ClassName;
    if ( $Value =~ m{\A\s*([^:]+?)\s*:\s*(.+)\z}xms ) {
        ( $ClassName, $Value ) = ( $1, $2 );
    }

    my @ClassIDs = $Self->_GeneralCatalogRestrictionIDsGet(
        Class  => 'ZTSM::GovernanceObject::Class',
        Values => $DynamicFieldConfig->{Config}{ClassIDs},
    );
    if ($ClassName) {
        my $Classes = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
            Class => 'ZTSM::GovernanceObject::Class',
        ) || {};
        my ($NamedClassID) = grep { lc( $Classes->{$_} // '' ) eq lc $ClassName } keys %{$Classes};
        return if !$NamedClassID;
        return if @ClassIDs && !grep { $_ == $NamedClassID } @ClassIDs;
        @ClassIDs = ($NamedClassID);
    }

    my @Attempts = (
        { Name   => $Value },
        { Number => $Value },
        {
            'DynamicField_ZTSM-Code' => {
                Equals => $Value,
            },
        },
    );

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    ATTEMPT:
    for my $Attempt (@Attempts) {
        my @IDs = $GovernanceObjectObject->GovernanceObjectSearch(
            Result     => 'ARRAY',
            Limit      => 2,
            ClassIDs   => IsArrayRefWithData(\@ClassIDs) ? \@ClassIDs : undef,
            Permission => 'ro',
            UserID     => $Param{UserID} || 1,
            %{$Attempt},
        );

        next ATTEMPT if @IDs != 1;

        if ( $DynamicFieldConfig->{FieldType} eq 'GovernanceObjectVersion' ) {
            my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $IDs[0],
                DynamicFields      => 0,
            );
            return $GovernanceObject->{VersionID};
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

    my %GovernanceObjectClassByField = (
        'ZBlue-Profile'    => ['GovernanceRole'],
        'ZBlue-Role'       => ['GovernanceRole'],
        'ZBlue-Template'   => ['Template'],
        'ZBlue-PurpleBook' => ['BlueBook'],
    );

    my %GovernanceObjectFieldDefaults = (
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
        $Self->_IsGovernanceObjectReference($DynamicFieldConfig)
        && !IsArrayRefWithData( $Config->{ClassIDs} )
        && IsArrayRefWithData( $GovernanceObjectClassByField{$Name} )
        )
    {
        my @ClassIDs = $Self->_GeneralCatalogRestrictionIDsGet(
            Class  => 'ZTSM::GovernanceObject::Class',
            Values => $GovernanceObjectClassByField{$Name},
        );
        $Config->{ClassIDs} = \@ClassIDs if @ClassIDs;
    }

    if ( IsHashRefWithData( $GovernanceObjectFieldDefaults{$Name} ) ) {
        for my $Key ( sort keys %{ $GovernanceObjectFieldDefaults{$Name} } ) {
            $Config->{$Key} = $GovernanceObjectFieldDefaults{$Name}->{$Key}
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

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    if ( IsStringWithData( $Param{Number} ) ) {
        my $ID = $GovernanceObjectObject->GovernanceObjectLookup(
            GOID => $Param{Number},
        );
        return $ID if $ID;
    }

    return if !$Param{MatchByName} || !IsStringWithData( $Param{Name} );

    my @IDs = $GovernanceObjectObject->GovernanceObjectSearch(
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
        Class => 'ZTSM::GovernanceObject::Class',
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

sub _IsGovernanceObjectReference {
    my ( $Self, $DynamicFieldConfig ) = @_;

    return $DynamicFieldConfig->{FieldType} eq 'GovernanceObject'
        || $DynamicFieldConfig->{FieldType} eq 'GovernanceObjectVersion';
}

sub _IsPortableObjectReference {
    my ( $Self, $DynamicFieldConfig ) = @_;

    return if !IsHashRefWithData($DynamicFieldConfig);
    return 1 if $Self->_IsGovernanceObjectReference($DynamicFieldConfig);
    return 1 if ( $DynamicFieldConfig->{FieldType} // '' ) =~ m{\AConfigItem(?:Version)?\z}xms;
    return;
}

1;
