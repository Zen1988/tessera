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

package Kernel::Modules::AgentReferenceSearch;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules
use List::Util qw(none);

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {%Param}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # only search is supported
    return $LayoutObject->JSONReply(
        Data => {
            Success => 0,
            Message => qq{Subaction '$Self->{Subaction}' is not supported!},
        },
    ) if $Self->{Subaction};

    # Get name of the dynamic field from $ParamObject, bail out when not found.
    # The multi value fields are marked by a trailing qr{_\d+}.
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Field       = $ParamObject->GetParam( Param => 'Field' );
    my $FieldName;
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldConfig;

    # check if we deal with process and if so, retrieve activity dialog id
    my $ActivityDialogEntityID;
    my $ProcessSuffix               = '';
    my $ActivityDialogEntityIDParam = $ParamObject->GetParam( Param => 'ActivityDialogEntityID' ) || '';
    if ( $ActivityDialogEntityIDParam =~ /^ActivityDialog-([0-9a-f]+)/ ) {
        $ActivityDialogEntityID = $1;
    }

    # possible prefix constellations:
    #   Autocomplete_DynamicField_Fieldname
    #   Autocomplete_Search_DynamicField_Fieldname
    # possible suffix constellations:
    #   [...]_FieldName
    #   [...]_FieldName_0          (set or multivalue)
    #   [...]_FieldName_0_0        (set and multivalue)
    #   [...]_FieldName_0a1b2c     (process suffix)
    #   [...]_FieldName_0a1b2c_0   (process suffix with set or multivalue)
    #   [...]_FieldName_0a1b2c_0_0 (process suffix with set and multivalue)

    my $Error = 1;
    if ($Field) {

        # match with activity dialog entity id is needed
        if ( $ActivityDialogEntityID && $LayoutObject->{SessionSource} eq 'CustomerInterface' ) {
            if ( $Field && $Field =~ m{ \A (?: Autocomplete (?: _Search )? ) _DynamicField_ ([A-Za-z0-9\-]*?) (_$ActivityDialogEntityID) (?:_[0-9]+){0,2} \z }xms ) {
                $FieldName     = $1;    # remove either the prefix 'Autocomplete_DynamicField_' or the prefix 'Search_DynamicField_'
                $ProcessSuffix = $2;
                $Error         = 0;
            }
        }

        # match without activity dialog entity id is needed
        else {
            if ( $Field =~ m{ \A (?: Autocomplete (?: _Search )? ) _DynamicField_ ([A-Za-z0-9\-]*?) (?:_[0-9]+){0,2} \z }xms ) {
                $FieldName = $1;        # remove either the prefix 'Autocomplete_DynamicField_' or the prefix 'Search_DynamicField_'
                $Error     = 0;
            }
        }
    }

    if ($Error) {
        CANDIDATE:
        for my $Candidate ( _TESSERAReferenceFieldNameCandidatesGet( Field => $Field ) ) {
            my $CandidateConfig = $DynamicFieldObject->DynamicFieldGet(
                Name => $Candidate,
            );
            next CANDIDATE if !IsHashRefWithData($CandidateConfig);
            next CANDIDATE if !$DynamicFieldBackendObject->HasBehavior(
                DynamicFieldConfig => $CandidateConfig,
                Behavior           => 'IsReferenceField',
            );

            $FieldName          = $Candidate;
            $DynamicFieldConfig = $CandidateConfig;
            $Error              = 0;
            last CANDIDATE;
        }
    }

    if ($Error) {
        return $LayoutObject->JSONReply(
            Data => {
                Success => 0,
                Message => 'Need Field!',
            },
        );
    }

    # Get config for the dynamic field and check the sanity.
    $DynamicFieldConfig ||= $DynamicFieldObject->DynamicFieldGet( Name => $FieldName );
    if (
        !IsHashRefWithData($DynamicFieldConfig)
        ||
        !$DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsReferenceField',
        )
        )
    {
        return $LayoutObject->JSONReply(
            Data => {
                Success => 0,
                Message => qq{Error reading the dynamic field '$FieldName'!},
            }
        );
    }

    # search referenced object
    my $MaxResults = int( $ParamObject->GetParam( Param => 'MaxResults' ) || 20 );
    my $Term       = $ParamObject->GetParam( Param => 'Term' ) || '';
    my $SetIndex   = $ParamObject->GetParam( Param => 'SetIndex' );
    my $TraceID    = $ParamObject->GetParam( Param => 'ZTSMServiceSubmitTraceID' ) || '';
    my $PickerMode = $ParamObject->GetParam( Param => 'Picker' ) || 0;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    if ( $LayoutObject->{SessionSource} eq 'CustomerInterface' && $FieldName =~ m{\AZTicket-} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "TESSERA AgentReferenceSearch hit field=$FieldName rawField=$Field term=$Term trace=$TraceID session=CustomerInterface",
        );
    }

    my %UserData;
    if ( $LayoutObject->{SessionSource} eq 'CustomerInterface' ) {
        $UserData{CustomerUserID} = $Self->{UserID};
    }
    else {
        $UserData{UserID} = $Self->{UserID};
    }

    my @ObjectIDs = $DynamicFieldBackendObject->SearchObjects(
        DynamicFieldConfig => $DynamicFieldConfig,    # this might contain search restrictions
        Term               => $Term,
        MaxResults         => $MaxResults,
        ParamObject        => $ParamObject,
        %UserData,
    );

    if ( $PickerMode && $Term ne '' ) {
        my @PickerObjectIDs = $DynamicFieldBackendObject->SearchObjects(
            DynamicFieldConfig => $DynamicFieldConfig,
            Term               => '',
            MaxResults         => 200,
            ParamObject        => $ParamObject,
            %UserData,
        );

        my %SeenObjectID = map { $_ => 1 } @ObjectIDs;
        for my $ObjectID (@PickerObjectIDs) {
            next if $SeenObjectID{$ObjectID};
            push @ObjectIDs, $ObjectID;
            $SeenObjectID{$ObjectID} = 1;
        }
    }

    my %ContextFilter = _TESSERAReferenceContextFilterGet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectIDs          => \@ObjectIDs,
        ParamObject => $ParamObject,
        FieldName   => $FieldName,
    );
    if ( $ContextFilter{Applied} ) {
        my %AllowedObjectID = map { $_ => 1 } @{ $ContextFilter{ObjectIDs} || [] };
        @ObjectIDs = grep { $AllowedObjectID{$_} } @ObjectIDs;
    }

    if ( $LayoutObject->{SessionSource} eq 'CustomerInterface' && $FieldName =~ m{\AZTicket-} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "TESSERA AgentReferenceSearch result field=$FieldName term=$Term trace=$TraceID count=" . scalar(@ObjectIDs)
                . " contextFilter=" . ( $ContextFilter{Summary} || '' ),
        );
    }

    my $FormID = $ParamObject->GetParam( Param => 'FormID' );

    # differentiate depending on whether field is multivalue
    my @FormDataObjectIDs = @ObjectIDs;
    if ( $DynamicFieldConfig->{Config}{MultiValue} && $FormID ) {

        # if so, do GetFormData() and store value combined with ObjectIDs
        my $LastSearchResults = $Kernel::OM->Get('Kernel::System::Web::FormCache')->GetFormData(
            LayoutObject => $LayoutObject,
            FormID       => $FormID,
            Key          => 'PossibleValues_DynamicField_' . $DynamicFieldConfig->{Name} . $ProcessSuffix,
        );

        if ($LastSearchResults) {
            for my $ResultItem ( $LastSearchResults->@* ) {
                if ( none { $_ eq $ResultItem } @FormDataObjectIDs ) {
                    push @FormDataObjectIDs, $ResultItem;
                }
            }
        }
    }

    # store all possible values for this field and form id for later verification
    if ($FormID) {
        $Kernel::OM->Get('Kernel::System::Web::FormCache')->SetFormData(
            LayoutObject => $LayoutObject,
            FormID       => $FormID,
            Key          => 'PossibleValues_DynamicField_' . $DynamicFieldConfig->{Name} . $ProcessSuffix . ( defined $SetIndex ? "_$SetIndex" : '' ),
            Value        => \@FormDataObjectIDs,
        );
    }

    my @Results;
    for my $ObjectID (@ObjectIDs) {
        my %Description = $DynamicFieldBackendObject->ObjectDescriptionGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            LayoutObject       => $LayoutObject,
            ObjectID           => $ObjectID,
            UserID             => 1,
        );

        my $Value = $Description{Long}
            || $Description{Normal}
            || $Description{Short}
            || $Description{Name}
            || $ObjectID;

        my %PickerDetails = $PickerMode ? _TESSERAPickerObjectDetailsGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $ObjectID,
        ) : ();

        if (
            $PickerMode
            && $Term ne ''
            && !_TESSERAPickerTermMatches(
                Term        => $Term,
                Value       => $Value,
                Description => $Description{Long} || '',
                Details     => \%PickerDetails,
            )
            )
        {
            next;
        }

        push @Results, {
            Key   => $ObjectID,
            Value => "$Value",
            $PickerMode ? (
                Label       => "$Value",
                Description => $Description{Long} || "$Value",
                Field       => $FieldName,
                MultiValue  => $DynamicFieldConfig->{Config}{MultiValue} ? 1 : 0,
                %PickerDetails,
            ) : (),
        };
    }

    # sort results by value
    @Results = sort { ( $a->{Value} || '' ) cmp ( $b->{Value} || '' ) } @Results;

    return $LayoutObject->JSONReply(
        Data => \@Results,
    );
}

sub _TESSERAReferenceFieldNameCandidatesGet {
    my (%Param) = @_;

    my $Field = $Param{Field} || '';
    return if !$Field;

    $Field =~ s{\A(?:Autocomplete(?:_Search)?_)?DynamicField_}{};
    $Field =~ s{_[0-9a-f]{8,}(?=_[0-9]+|\z)}{}i;
    $Field =~ s{(?:_[0-9]+){1,2}\z}{};

    my @Candidates;
    my %Seen;

    for my $Part ( reverse split m{_}, $Field ) {
        next if !$Part || $Seen{$Part}++;
        push @Candidates, $Part;
    }

    if ( !$Seen{$Field}++ ) {
        push @Candidates, $Field;
    }

    return @Candidates;
}

sub _TESSERAPickerTermMatches {
    my (%Param) = @_;

    my $Term = lc( $Param{Term} || '' );
    return 1 if $Term eq '';

    my @Values = (
        $Param{Value}       || '',
        $Param{Description} || '',
    );

    if ( ref $Param{Details} eq 'HASH' ) {
        push @Values, map { $Param{Details}->{$_} || '' } qw(Name Number Class Status ObjectType);
    }

    for my $Value (@Values) {
        return 1 if lc($Value) =~ m{\Q$Term\E};
    }

    return;
}

sub _TESSERAPickerObjectDetailsGet {
    my (%Param) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig} || {};
    my $ObjectID           = $Param{ObjectID};
    return if !$ObjectID;

    my $Driver = $DynamicFieldConfig->{FieldType} || '';

    if ( $Driver eq 'GovernanceObject' || $Driver eq 'GovernanceObjectVersion' ) {
        my $Object = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $ObjectID,
            DynamicFields      => 1,
            UserID             => 1,
            Silent             => 1,
        );

        if ( IsHashRefWithData($Object) ) {
            return (
                ObjectType => 'GO',
                Name       => $Object->{Name}   || '',
                Number     => $Object->{Number} || '',
                Class      => $Object->{Class}  || '',
                Status     => $Object->{Status} || $Object->{CurDeplState} || '',
            );
        }
    }

    if ( $Driver eq 'ConfigItem' || $Driver eq 'ConfigItemVersion' ) {
        my $Object = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
            ConfigItemID => $ObjectID,
            DynamicFields => 1,
            UserID       => 1,
            Silent       => 1,
        );

        if ( IsHashRefWithData($Object) ) {
            return (
                ObjectType => 'CI',
                Name       => $Object->{Name}             || '',
                Number     => $Object->{ConfigItemNumber} || $Object->{Number} || '',
                Class      => $Object->{Class}            || '',
                Status     => $Object->{CurDeplState}     || $Object->{DeplState} || '',
            );
        }
    }

    return (
        ObjectType => $Driver || 'Reference',
        Name       => '',
        Number     => '',
        Class      => '',
        Status     => '',
    );
}

sub _TESSERAReferenceContextFilterGet {
    my (%Param) = @_;

    my $ParamObject = $Param{ParamObject};
    my $FieldName   = $Param{FieldName} || '';
    my @ObjectIDs   = @{ $Param{ObjectIDs} || [] };
    return if !$ParamObject || !$FieldName || !@ObjectIDs;

    my @Specs = _TESSERAReferenceContextFilterSpecsGet();
    my @MatchedSpecs = grep { ( $_->{TargetField} || '' ) eq $FieldName } @Specs;
    return if !@MatchedSpecs;

    my %AllowedObjectID = map { $_ => 1 } @ObjectIDs;
    my @Summary;

    SPEC:
    for my $Spec (@MatchedSpecs) {
        my $ContextValue = _TESSERAReferenceParamValueGet(
            ParamObject => $ParamObject,
            Field       => $Spec->{ContextField},
        );
        next SPEC if !$ContextValue;

        if ( $Spec->{Mode} && $Spec->{Mode} eq 'SourceListContainsTarget' ) {
            my $SourceObject = _TESSERAReferenceObjectGet(
                FieldType => $Spec->{SourceObjectType},
                ObjectID  => $ContextValue,
            );
            next SPEC if !IsHashRefWithData($SourceObject);

            my %AllowedFromSource;
            for my $AllowedID ( _TESSERAObjectDynamicFieldValues(
                Object => $SourceObject,
                Field  => $Spec->{SourceObjectField},
            ) )
            {
                next if !$AllowedID;
                $AllowedFromSource{$AllowedID} = 1;
            }
            next SPEC if !%AllowedFromSource;

            for my $ObjectID ( keys %AllowedObjectID ) {
                delete $AllowedObjectID{$ObjectID} if !$AllowedFromSource{$ObjectID};
            }

            push @Summary, "$Spec->{ContextField}:$ContextValue->$Spec->{SourceObjectField}";
            next SPEC;
        }

        if ( $Spec->{Mode} && $Spec->{Mode} eq 'TargetFieldEqualsContext' ) {
            for my $ObjectID ( keys %AllowedObjectID ) {
                my $TargetObject = _TESSERAReferenceObjectGet(
                    FieldType => $Param{DynamicFieldConfig}->{FieldType},
                    ObjectID  => $ObjectID,
                );
                if (
                    !IsHashRefWithData($TargetObject)
                    || !_TESSERAValueListContains(
                        Values => [
                            _TESSERAObjectDynamicFieldValues(
                                Object => $TargetObject,
                                Field  => $Spec->{TargetObjectField},
                            )
                        ],
                        Value => $ContextValue,
                    )
                    )
                {
                    delete $AllowedObjectID{$ObjectID};
                }
            }

            push @Summary, "$Spec->{ContextField}:$ContextValue->$Spec->{TargetObjectField}";
            next SPEC;
        }
    }

    my @AllowedObjectIDs = sort keys %AllowedObjectID;
    return if @AllowedObjectIDs == @ObjectIDs;

    return (
        Applied   => 1,
        ObjectIDs => \@AllowedObjectIDs,
        Summary   => join( ',', @Summary ),
    );
}

sub _TESSERAReferenceContextFilterSpecsGet {
    return (
        {
            TargetField       => 'ZTicket-Platform',
            ContextField      => 'ZTicket-Application',
            Mode              => 'SourceListContainsTarget',
            SourceObjectType  => 'GovernanceObject',
            SourceObjectField => 'ZTSMAppSystem-Platform',
        },
        {
            TargetField       => 'ZCompute-Image',
            ContextField      => 'ZTicket-Platform',
            Mode              => 'TargetFieldEqualsContext',
            TargetObjectField => 'ZTAM-Platform',
        },
        {
            TargetField       => 'ZCompute-Image',
            ContextField      => 'ZTicket-Location',
            Mode              => 'TargetFieldEqualsContext',
            TargetObjectField => 'ZTAM-Location',
        },
    );
}

sub _TESSERAReferenceObjectGet {
    my (%Param) = @_;

    my $FieldType = $Param{FieldType} || '';
    my $ObjectID  = $Param{ObjectID};
    return if !$ObjectID;

    if ( $FieldType eq 'GovernanceObject' || $FieldType eq 'GovernanceObjectVersion' ) {
        return $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $ObjectID,
            DynamicFields      => 1,
            UserID             => 1,
            Silent             => 1,
        );
    }

    if ( $FieldType eq 'ConfigItem' || $FieldType eq 'ConfigItemVersion' ) {
        return $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
            ConfigItemID   => $ObjectID,
            DynamicFields  => 1,
            UserID         => 1,
            Silent         => 1,
        );
    }

    return;
}

sub _TESSERAValueListContains {
    my (%Param) = @_;

    my $Value = $Param{Value};
    return if !defined $Value || $Value eq '';

    for my $Item ( @{ $Param{Values} || [] } ) {
        next if !defined $Item || $Item eq '';
        return 1 if "$Item" eq "$Value";
    }

    return;
}

sub _TESSERAReferenceParamValueGet {
    my (%Param) = @_;

    my $ParamObject = $Param{ParamObject};
    my $Field       = $Param{Field};
    return if !$ParamObject || !$Field;

    PARAM:
    for my $ParamName (
        'DynamicField_' . $Field,
        'DynamicField_' . $Field . '_0',
        'Autocomplete_DynamicField_' . $Field,
        'Autocomplete_DynamicField_' . $Field . '_0',
    )
    {
        my $Value = $ParamObject->GetParam( Param => $ParamName );
        next PARAM if !defined $Value || $Value eq '';
        return $Value =~ m{\A(\d+)\z} ? $1 : $Value;
    }

    return;
}

sub _TESSERAObjectDynamicFieldValues {
    my (%Param) = @_;

    my $Object = $Param{Object};
    my $Field  = $Param{Field};

    return if !$Object || ref $Object ne 'HASH';
    return if !$Field;

    my @Values = _TESSERANormalizeArray( $Object->{ 'DynamicField_' . $Field } );
    return @Values if @Values;

    my $XMLData = $Object->{XMLData};
    return if !$XMLData || ref $XMLData ne 'HASH';
    return if !exists $XMLData->{$Field};

    my $XMLValue = $XMLData->{$Field};
    my @Items = ref $XMLValue eq 'ARRAY' ? @{$XMLValue} : ($XMLValue);
    my @XMLValues;

    ITEM:
    for my $Item (@Items) {
        next ITEM if !defined $Item;
        next ITEM if !ref $Item && $Item eq '';

        if ( ref $Item eq 'HASH' ) {
            push @XMLValues, _TESSERANormalizeArray(
                exists $Item->{Content} ? $Item->{Content} : $Item
            );
            next ITEM;
        }

        push @XMLValues, _TESSERANormalizeArray($Item);
    }

    return grep { defined $_ && $_ ne '' } @XMLValues;
}

sub _TESSERANormalizeArray {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'HASH' ) {
        $Value = [ $Value ];
    }

    if ( ref $Value eq 'ARRAY' ) {
        my @Result;

        ITEM:
        for my $Item ( @{$Value} ) {
            next ITEM if !defined $Item || $Item eq '';

            if ( ref $Item eq 'HASH' ) {
                push @Result, _TESSERANormalizeArray(
                    exists $Item->{Content} ? $Item->{Content} : $Item
                );
                next ITEM;
            }

            push @Result, $Item;
        }

        return @Result;
    }

    return $Value;
}

1;
