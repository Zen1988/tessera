# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::System::DynamicField::Driver::MELTObject;

## nofilter(TidyAll::Plugin::OTOBO::Perl::ParamObject)

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

BEGIN {
    my $Module = __PACKAGE__;
    my $Parent = 'Kernel::System::DynamicField::Driver::BaseReference';
    local $SIG{__WARN__} = sub {
        warn "ZTSM DynamicField Driver diagnostic: warning while loading parent $Parent for $Module: @_";
    };
    eval {
        require parent;
        parent->import($Parent);
        1;
    } or do {
        my $Error = $@ || 'unknown error';
        my $ParentFile = "$Parent.pm" =~ s{::}{/}smxgr;
        die "ZTSM DynamicField Driver diagnostic: failed to load parent $Parent for $Module; "
            . "INC{$ParentFile}="
            . ( defined $INC{$ParentFile} ? $INC{$ParentFile} : '<undef>' )
            . "; error=$Error";
    };
}

# core modules
use List::Util   qw(any);
use Scalar::Util qw(reftype);

# CPAN modules

# OTOBO modules
use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Language',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Log',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::MELTObject',
);

=head1 NAME

Kernel::System::DynamicField::Driver::MELT Object - backend for the Reference dynamic field

=head1 DESCRIPTION

MELT Object backend for the Reference dynamic field.

=head1 PUBLIC INTERFACE

=head2 new()

it is usually not necessary to explicitly create instances of dynamic field drivers.
Instances of the drivers are created in the constructor of the
dynamic field backend object C<Kernel::System::DynamicField::Backend>.

=cut

sub new {
    my ($Type) = @_;

    # allocate new hash for object
    my $Self = bless {}, $Type;

    # Some reference dynamic fields are stored in the database table attribute dynamic_field_value.value_int.
    $Self->{ValueType}      = 'Integer';
    $Self->{ValueKey}       = 'ValueInt';
    $Self->{TableAttribute} = 'value_int';

    # Used for declaring CSS classes
    $Self->{FieldCSSClass} = 'DynamicFieldReference';

    # set field behaviors
    $Self->{Behaviors} = {
        'IsACLReducible'               => 0,
        'IsNotificationEventCondition' => 0,
        'IsSortable'                   => 1,
        'IsFiltrable'                  => 1,
        'IsStatsCondition'             => 0,
        'IsCustomerInterfaceCapable'   => 1,
        'IsHiddenInTicketInformation'  => 0,
        'IsReferenceField'             => 1,
        'IsSetCapable'                 => 1,
        'SetsDynamicContent'           => 1,
    };

    $Self->{ReferencedObjectType} = 'MELTObject';

    return $Self;
}

=head2 ValueGet()

This method contains special support for the case of Lenses. A Lens operates directly on dynamic field of an specific object.
The specific object is usually identified by the value of the Reference dynamic field. But there is at least one special case.
When the reference is to an C<MELTObject> then the relevant ID is the ID of the last version. This case is handled
when the parameter C<ForLens> is passed.

=cut

sub ValueGet {
    my ( $Self, %Param ) = @_;

    # get the value from the parent class
    my $Value = $Self->SUPER::ValueGet(%Param);

    # special handling only for Lens
    return $Value unless $Param{ForLens};

    # for usage in lenses we might have to interpret the values to be usable for their ValueGet()
    return $Self->ValueForLens(
        %Param,
        Value => $Value
    );
}

=head2 ValueSet()

This method handles MELTObject-Link sync for C<MELTObject>s when Dynamic Field References between 2
MELTObject(Version) are updated.

=cut

sub ValueSet {
    my ( $Self, %Param ) = @_;

    my $Result = $Self->SUPER::ValueSet(%Param);

    if ($Result) {

        # optional MELT Object links
        my $DynamicFieldConfig = $Param{DynamicFieldConfig};

        my $ObjectType = $DynamicFieldConfig->{ObjectType};
        my $FieldType  = $DynamicFieldConfig->{FieldType};

        # only proceed if this is a CI <-> CI relationship
        return $Result unless $ObjectType =~ /^MELTObject/;
        return $Result unless $FieldType  =~ /^MELTObject/;

        my $ValueType = ref( $Param{Value} );
        my @Values    = $ValueType && $ValueType eq 'ARRAY' ? $Param{Value}->@*
            : $Param{Value} ? ( $Param{Value} ) : ();

        if ( $Param{Set} ) {

            # in sets we expect either array references or undef for the single set indices
            # from [ [Val11, Val12], undef, [Val31] ]
            # via  ( [Val11, Val12], undef, [Val31] )
            # to   ( Val11, Val12, Val31 )
            @Values = map { $_ ? $_->@* : () } @Values;
        }

        my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');
        my $MELTObject       = $MELTObjectObject->MELTObjectGet(
            VersionID     => $Param{ObjectID},
            DynamicFields => 0,
        );

        # update melt_object_item_link
        $MELTObjectObject->SyncLinkTable(
            DynamicFieldConfig      => $DynamicFieldConfig,
            MELTObjectID            => $MELTObject->{MELTObjectID},
            MELTObjectLastVersionID => $MELTObject->{LastVersionID},
            MELTObjectVersionID     => $MELTObject->{VersionID},
            Value                   => \@Values,
        );
    }

    return $Result;
}

# Override from BaseReference to prevent LinkObject-Auto-Linking for CI <-> CI relations

sub _CreateAutoLinkObjectLink {
    my ( $Self, %Param ) = @_;

    my $DynamicField = $Param{DynamicField};
    my $ObjectType   = $DynamicField->{ObjectType};
    my $FieldType    = $DynamicField->{FieldType};

    $FieldType  =~ s/^MELTObject/MELTObject/;
    $FieldType  =~ s/^MELTObjectVersion/MELTObject/;
    $ObjectType =~ s/^MELTObjectVersion/MELTObject/;

    if ( $FieldType eq $ObjectType && $FieldType =~ /^MELTObject/ ) {

        # skip dynamic linking for MELT Object <-> MELT Object links
        return;
    }

    my $Result = $Self->SUPER::_CreateAutoLinkObjectLink(%Param);
    return $Result;
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    # get the value from the parent class
    my $Value = $Self->SUPER::EditFieldValueGet(%Param);

    # for this field the normal return an the ReturnValueStructure are the same
    return $Value unless $Param{ForLens};

    # for usage in lenses we might have to interpret the values to be usable for their ValueGet()
    return $Self->ValueForLens( Value => $Value );
}

=head2 GetFieldTypeSettings()

Get the field type settings for the referenced object type C<MELTObject>.
The generic settings for all referenced object types are included as well.

=cut

sub GetFieldTypeSettings {
    my ( $Self, %Param ) = @_;

    my $ReferencingObjectType = $Param{ObjectType};

    # First fetch the generic settings.
    my @FieldTypeSettings = $Self->SUPER::GetFieldTypeSettings(
        %Param,
    );

    # Add the selection of the MELT Object class.
    {
        my $ClassID2Name = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
            Class => 'ZTSM::MELT::Class',
        );

        push @FieldTypeSettings,
            {
                ConfigParamName => 'ClassIDs',
                Label           => Translatable('Class restrictions for the MELT Object'),
                Explanation     => Translatable('Select one or more classes to restrict selectable MELT Objects'),
                InputType       => 'Selection',
                SelectionData   => $ClassID2Name,
                PossibleNone    => 0,                                                                                # the class is required
                Multiple        => 1,
            };
    }

    # Add the selection of the MELT Object ZTSM Status.
    {
        my $DeploymentStatesList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
            Class => 'ZTSM::MELT::Status',
        );
        push @FieldTypeSettings,
            {
                ConfigParamName => 'ZTSMStatusIDs',
                Label           => Translatable('ZTSM Status restrictions for the MELT Object'),
                Explanation     => Translatable('Select one or more ZTSM Statuss to restrict selectable MELT Objects'),
                InputType       => 'Selection',
                SelectionData   => $DeploymentStatesList,
                PossibleNone    => 1,
                Multiple        => 1,
            };
    }

    # Select the link referencing type
    if ( $ReferencingObjectType =~ m/^MELTObject/ ) {
        my @SelectionData = (
            {
                Key   => 'Dynamic',
                Value => Translatable('Dynamic (MELTObject)'),
            },
            {
                Key   => 'Static',
                Value => Translatable('Static (Version)'),
            },
        );

        push @FieldTypeSettings,
            {
                ConfigParamName => 'LinkReferencingType',
                Label           => Translatable('Link Referencing Type'),
                Explanation     => Translatable(
                'Whether this link applies to the MELT Object or the static version of the referencing object. Current ZTSM Status calculation only is performed on dynamic links.'
                ),
                InputType     => 'Selection',
                SelectionData => \@SelectionData,
                DefaultKey    => 'Dynamic',
                PossibleNone  => 0,
            };
    }

    # Support configurable search key
    push @FieldTypeSettings,
        {
            ConfigParamName => 'SearchAttribute',
            Label           => Translatable('Attribute which will be searched on autocomplete'),
            Explanation     => Translatable('Select the attribute which MELT Objects will be searched by'),
            InputType       => 'Selection',
            SelectionData   => {
                'Number' => 'Number',
                'Name'   => 'Name',
            },
            PossibleNone => 1,
            Multiple     => 0,
        };

    my $DynamicFieldsList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldList(
        ObjectType => ['MELTObject'],
        Valid      => 1,
        ResultType => 'HASH',
    );
    my %DFSelectionData = map { ( "DynamicField_$_" => "DynamicField_$_" ) } values $DynamicFieldsList->%*;

    # Support configurable import search attribute
    push @FieldTypeSettings,
        {
            ConfigParamName => 'ImportSearchAttribute',
            Label           => Translatable('External-source key'),
            Explanation     => Translatable('When set via an external source (e.g. web service or import / export), the value will be interpreted as this attribute.'),
            InputType       => 'Selection',
            SelectionData   => {
                'Name'   => 'Name',
                'Number' => 'Number',
                %DFSelectionData,
            },
            PossibleNone => 1,
            Multiple     => 0,
        };

    # Support various display options
    push @FieldTypeSettings,
        {
            ConfigParamName => 'DisplayType',
            Label           => Translatable('Attribute which is displayed for values'),
            Explanation     => Translatable('Select the type of display'),
            InputType       => 'Selection',
            SelectionData   => {
                'MELTID'      => '<MELT Object Number>',
                'MELTObjectName'        => '<MELT Object Name>',
                'ClassMELTID' => '<Class Name>: <MELT Object Number>',
                'ClassMELTObjectName'   => '<Class Name>: <MELT Object Name>',
            },
            PossibleNone => 1,
            Multiple     => 0,
        };

    # Support reference filters
    push @FieldTypeSettings,
        {
            ConfigParamName => 'ReferenceFilterList',
        };

    return @FieldTypeSettings;
}

=head2 ObjectPermission()

checks read permission for a given object and UserID.

    $Permission = $BackendObject->ObjectPermission(
        Key     => 123,
        UserID  => 1,
    );

=cut

sub ObjectPermission {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Key UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    return $Kernel::OM->Get('Kernel::System::MELTObject')->Permission(
        Scope  => 'Item',
        ItemID => $Param{Key},
        UserID => $Param{UserID},
        Type   => 'ro',
    );
}

=head2 ObjectDescriptionGet()

return a hash of object descriptions.

    my %Description = $BackendObject->ObjectDescriptionGet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => 123,
        UserID             => 1,
    );

Return

    %Description = (
        Normal => "CI# 1234455",
        Long   => "CI# 1234455: Need a sample MELT Object title",
    );

=cut

sub ObjectDescriptionGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ObjectID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    my $MELTObject = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
        MELTObjectID => $Param{ObjectID},
        Silent       => 1,
    );

    if ( !$MELTObject ) {
        return (
            Normal => "$Param{ObjectID} (deleted)",
            Long   => "$Param{ObjectID} (deleted)",
        );
    }

    # prepare translation of class name if possible
    my $ClassNameStrg = $MELTObject->{Class};
    if ( $Param{LayoutObject} ) {
        $ClassNameStrg = $Param{LayoutObject}{LanguageObject}->Translate($ClassNameStrg);
    }

    my $DFConfig = $Param{DynamicFieldConfig} || {};
    my $DFDetails = $DFConfig->{Config} || $DFConfig;

    my %Descriptions;
    if ( $DFDetails->{DisplayType} ) {

        # prepare string as configured
        my $DisplayType = $DFDetails->{DisplayType};
        if ( $DisplayType eq 'MELTID' || $DisplayType eq 'ConfigItemNumber' ) {
            $Descriptions{Normal} = "$MELTObject->{Number}";
            $Descriptions{Long}   = "$MELTObject->{Number}";
        }
        elsif ( $DisplayType eq 'MELTObjectName' || $DisplayType eq 'ConfigItemName' ) {
            $Descriptions{Normal} = "$MELTObject->{Name}";
            $Descriptions{Long}   = "$MELTObject->{Name}";
        }
        elsif ( $DisplayType eq 'ClassMELTID' || $DisplayType eq 'ClassConfigItemNumber' ) {
            $Descriptions{Normal} = "$ClassNameStrg: $MELTObject->{Number}";
            $Descriptions{Long}   = "$ClassNameStrg: $MELTObject->{Number}";
        }
        elsif ( $DisplayType eq 'ClassMELTObjectName' || $DisplayType eq 'ClassConfigItemName' ) {
            $Descriptions{Normal} = "$ClassNameStrg: $MELTObject->{Name}";
            $Descriptions{Long}   = "$ClassNameStrg: $MELTObject->{Name}";
        }
    }

    if ( !$Descriptions{Long} ) {
        $Descriptions{Normal} = "$MELTObject->{Name}";
        $Descriptions{Long}   = "$ClassNameStrg: $MELTObject->{Name}";
    }

    my $Link;
    if ( $Param{Link} && $Param{LayoutObject}{SessionSource} ) {
        if ( $Param{LayoutObject}{SessionSource} eq 'AgentInterface' ) {

            # TODO: only show the link if the user $Param{UserID} has permissions
            $Link = $Param{LayoutObject}{Baselink} . "Action=AgentMELTObjectZoom;MELTObjectID=$Param{ObjectID}";
        }
    }

    # create description
    return (
        %Descriptions,
        Link => $Link,
    );
}

=head2 SearchObjects()

This is used in auto completion when searching for possible object IDs.

    my @ObjectIDs = $BackendObject->SearchObjects(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $ObjectID,                # (optional) if given, takes precedence over Term
        Term               => $Term,                    # (optional) defaults to wildcard search with empty string
        MaxResults         => $MaxResults,
        UserID             => 1,
        Object             => {
            %Data,
        },
        ParamObject        => $ParamObject,
    );

=cut

sub SearchObjects {
    my ( $Self, %Param ) = @_;

    $Param{Term} //= '';

    my $DFDetails = $Param{DynamicFieldConfig}{Config} // {};
    my $ClassIDs  = $Self->_GeneralCatalogRestrictionIDsGet(
        Class  => 'ZTSM::MELT::Class',
        Values => $DFDetails->{ClassIDs},
    );
    my $ZTSMStatusIDs = $Self->_GeneralCatalogRestrictionIDsGet(
        Class  => 'ZTSM::MELT::Status',
        Values => $DFDetails->{ZTSMStatusIDs},
    );

    my %SearchParams;

    if ( $Param{ObjectID} ) {
        $SearchParams{MELTObjectID} = $Param{ObjectID};
    }
    elsif ( $Param{ExternalSource} ) {

        # include configured search param if present
        my $SearchAttribute = $DFDetails->{ImportSearchAttribute} || 'Name';

        $SearchParams{$SearchAttribute} = "$Param{Term}";
    }
    else {

        # include configured search param if present
        my $SearchAttribute = $DFDetails->{SearchAttribute} || 'Name';

        if ( length $Param{Term} ) {
            $SearchParams{$SearchAttribute} = "*$Param{Term}*";
        }
    }

    # prepare mapping of edit mask attribute names
    my %AttributeNameMapping = (
        CustomerUser => [

            # AgentTicketEmail
            'From',

            # AgentTicketPhone
            'SelectedCustomerUser',
        ],
        ResponsibleID => [
            'NewResponsibleID',
        ],
        OwnerID => [
            'NewOwnerID',
            'NewUserID',
        ],
        QueueID => [
            'Dest',
            'NewQueueID',
        ],
        StateID => [
            'NewStateID',
            'NextStateID',
        ],
        PriorityID => [
            'NewPriorityID',
        ],
    );

    # incorporate referencefilterlist into search params
    if ( IsArrayRefWithData( $DFDetails->{ReferenceFilterList} ) && !$Param{ExternalSource} ) {
        FILTERITEM:
        for my $FilterItem ( $DFDetails->{ReferenceFilterList}->@* ) {

            # map ID to IDs if necessary
            my $AttributeName = $FilterItem->{ReferenceObjectAttribute};
            if ( any { $_ eq $AttributeName } qw(QueueID TypeID StateID PriorityID ServiceID SLAID OwnerID ResponsibleID ) ) {
                $AttributeName .= 's';
            }

            # check filter config
            next FILTERITEM unless $FilterItem->{ReferenceObjectAttribute};
            next FILTERITEM unless ( $FilterItem->{EqualsObjectAttribute} || $FilterItem->{EqualsString} );

            if ( $FilterItem->{EqualsObjectAttribute} ) {

                # don't perform search if object attribute to search for is empty
                my $EqualsObjectAttribute;
                if ( IsHashRefWithData( $Param{Object} ) ) {
                    $EqualsObjectAttribute = $Param{Object}{DynamicField}{ $FilterItem->{EqualsObjectAttribute} } // $Param{Object}{ $FilterItem->{EqualsObjectAttribute} };
                }
                elsif ( defined $Param{ParamObject} ) {
                    if ( $FilterItem->{EqualsObjectAttribute} =~ /^DynamicField_(?<DFName>\S+)/ ) {
                        my $FilterItemDFConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
                            Name => $+{DFName},
                        );
                        next FILTERITEM unless IsHashRefWithData($FilterItemDFConfig);
                        $EqualsObjectAttribute = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->EditFieldValueGet(
                            ParamObject        => $Param{ParamObject},
                            DynamicFieldConfig => $FilterItemDFConfig,
                            TransformDates     => 0,
                        );
                    }
                    else {

                        # match standard ticket attribute names with edit mask attribute names
                        my @ParamNames = $Param{ParamObject}->GetParamNames;

                        # check if attribute name itself is in params
                        # NOTE trying attribute itself is crucially important in case of QueueID
                        #   because AgentTicketPhone does not provide QueueID, but puts the id in
                        #   Dest, and AgentTicketEmail leaves Dest as a string but puts the id in QueueID
                        my ($ParamName) = grep { $_ eq $FilterItem->{EqualsObjectAttribute} } @ParamNames;

                        # if not, try to find a mapped attribute name
                        if ( !$ParamName ) {

                            # check if mapped attribute names exist at all
                            my $MappedAttributes = $AttributeNameMapping{ $FilterItem->{EqualsObjectAttribute} };
                            if ( ref $MappedAttributes eq 'ARRAY' ) {

                                MAPPEDATTRIBUTE:
                                for my $MappedAttribute ( $MappedAttributes->@* ) {
                                    ($ParamName) = grep { $_ eq $MappedAttribute } @ParamNames;

                                    last MAPPEDATTRIBUTE if $ParamName;
                                }
                            }
                        }

                        return unless $ParamName;

                        $EqualsObjectAttribute = $Param{ParamObject}->GetParam( Param => $ParamName );

                        # when called by AgentReferenceSearch, Dest is a string and we need to extract the QueueID
                        if ( $ParamName eq 'Dest' ) {
                            my $QueueID = '';
                            if ( $EqualsObjectAttribute =~ /^(\d{1,100})\|\|.+?$/ ) {
                                $QueueID = $1;
                            }
                            $EqualsObjectAttribute = $QueueID;
                        }
                    }
                }

                # ensure that for EqualsObjectAttribute UserID always $Self->{UserID} is used in the end
                if ( $FilterItem->{EqualsObjectAttribute} eq 'UserID' ) {
                    $EqualsObjectAttribute = $Param{UserID};
                }

                return unless $EqualsObjectAttribute;
                return if ( ref $EqualsObjectAttribute eq 'ARRAY' && !$EqualsObjectAttribute->@* );

                # MELT Object attribute
                if ( $FilterItem->{ReferenceObjectAttribute} =~ m{^Con}i ) {
                    $SearchParams{$AttributeName} = $EqualsObjectAttribute;
                }

                # dynamic field attribute
                elsif ( $FilterItem->{ReferenceObjectAttribute} =~ m{^Dyn}i ) {
                    $SearchParams{$AttributeName} = {
                        Equals => $EqualsObjectAttribute,
                    };
                }

                # array attribute
                else {
                    $SearchParams{$AttributeName} = [$EqualsObjectAttribute];
                }
            }
            elsif ( $FilterItem->{EqualsString} ) {

                # MELT Object attribute
                # TODO check if this has to be adapted for ticket search
                if ( $FilterItem->{ReferenceObjectAttribute} =~ m{^Con}i ) {
                    $SearchParams{$AttributeName} = $FilterItem->{EqualsString};
                }

                # dynamic field attribute
                elsif ( $FilterItem->{ReferenceObjectAttribute} =~ m{^Dyn}i ) {
                    $SearchParams{$AttributeName} = {
                        Equals => $FilterItem->{EqualsString},
                    };
                }

                # array attribute
                else {
                    $SearchParams{$AttributeName} = [ $FilterItem->{EqualsString} ];
                }
            }
        }
    }

    # Support restriction by class
    if ( IsArrayRefWithData($ClassIDs) && !$Param{ExternalSource} ) {
        if ( $SearchParams{ClassIDs} ) {
            my @ClassIDs;
            for my $ClassID ( $SearchParams{ClassIDs}->@* ) {
                if ( any { $_ eq $ClassID } $ClassIDs->@* ) {
                    push @ClassIDs, $ClassID;
                }
            }

            return unless @ClassIDs;

            $SearchParams{ClassIDs} = \@ClassIDs;
        }
        else {
            $SearchParams{ClassIDs} = $ClassIDs;
        }
    }

    # Support restriction by ZTSM Status
    if ( IsArrayRefWithData($ZTSMStatusIDs) ) {
        if ( $SearchParams{ZTSMStatusIDs} ) {
            my @DeploymentStateIDs;
            for my $DeploymentStateID ( $SearchParams{ZTSMStatusIDs}->@* ) {
                if ( any { $_ eq $DeploymentStateID } $ZTSMStatusIDs->@* ) {
                    push @DeploymentStateIDs, $DeploymentStateID;
                }
            }

            return unless @DeploymentStateIDs;

            $SearchParams{ZTSMStatusIDs} = \@DeploymentStateIDs;
        }
        else {
            $SearchParams{ZTSMStatusIDs} = $ZTSMStatusIDs;
        }
    }

    # return a list of MELT Object IDs
    return $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectSearch(
        Limit   => $Param{MaxResults},
        Result  => 'ARRAY',
        SortBy  => 'Number',
        OrderBy => 'Down',
        UserID  => 1,
        %SearchParams,
    );
}

sub _GeneralCatalogRestrictionIDsGet {
    my ( $Self, %Param ) = @_;

    return [] if !IsArrayRefWithData( $Param{Values} );

    my $ID2Name = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => $Param{Class},
    ) || {};

    my %Name2ID = reverse %{$ID2Name};
    my @IDs;
    my %Seen;

    VALUE:
    for my $Value ( $Param{Values}->@* ) {
        next VALUE if !defined $Value || $Value eq '';

        my $ID = $Value =~ m{\A\d+\z} ? $Value : $Name2ID{$Value};
        next VALUE if !$ID;
        next VALUE if $Seen{$ID}++;

        push @IDs, $ID;
    }

    return \@IDs;
}

=head2 ValueForLens()

return the current last version ids used in dynamic_field_value.
The passed in value is a list of MELT Object IDs. These IDs are
transformed into the respective last version IDs.

    my $Value = $BackendObject->ValueForLens(
        Value => [17,17,19,20],
    );

=cut

sub ValueForLens {
    my ( $Self, %Param ) = @_;

    return if !$Param{Value};

    if ( ref $Param{Value} ne 'ARRAY' ) {
        $Param{Value} = [ $Param{Value} ];
    }

    my @LastVersionIDs;

    unless ( $Param{Set} ) {    ## no critic qw(ControlStructures::ProhibitUnlessBlocks)
        CONFIG_ITEM_ID:
        for my $MELTObjectID ( $Param{Value}->@* ) {
            my $MELTObject = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
                MELTObjectID => $MELTObjectID,
                Silent       => 1,
            );

            # only valid IDs
            next CONFIG_ITEM_ID unless $MELTObject;
            next CONFIG_ITEM_ID unless $MELTObject->{LastVersionID};

            push @LastVersionIDs, $MELTObject->{LastVersionID};
        }

        return \@LastVersionIDs;
    }

    # for sets we need to translate for every set value
    for my $SetValue ( $Param{Value}->@* ) {
        if ( ref $SetValue ne 'ARRAY' ) {
            $SetValue = [$SetValue];
        }

        my @SetVersionIDs;

        CONFIG_ITEM_ID:
        for my $MELTObjectID ( $SetValue->@* ) {
            my $MELTObject = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
                MELTObjectID => $MELTObjectID,
            );

            # only valid IDs
            next CONFIG_ITEM_ID unless $MELTObject;
            next CONFIG_ITEM_ID unless $MELTObject->{LastVersionID};

            push @SetVersionIDs, $MELTObject->{LastVersionID};
        }

        push @LastVersionIDs, \@SetVersionIDs;
    }

    return \@LastVersionIDs;
}

1;

