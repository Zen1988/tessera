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
package Kernel::Modules::AgentMELTObjectBulk;

use strict;
use warnings;

use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get("MELTObject::Frontend::$Self->{Action}");

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check if bulk feature is enabled
    if ( !$ConfigObject->Get('MELTObject::Frontend::BulkFeature') ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Bulk feature is not enabled!'),
        );
    }

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get involved MELT Objects, filtering empty MELTObjectIDs
    my @MELTObjectIDs = grep {$_}
        $ParamObject->GetArray( Param => 'MELTObjectID' );

    # check needed stuff
    if ( !@MELTObjectIDs ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No MELTObjectID is given!'),
            Comment => Translatable('You need at least one selected Configuration Item!'),
        );
    }
    my $Output = $LayoutObject->Header(
        Type => 'Small',
    );

    # declare the variables for all the parameters
    my %Error;

    my %GetParam;

    # get MELT Object object
    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    # get all parameters and check for errors
    if ( $Self->{Subaction} eq 'Do' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get all parameters
        for my $Key (
            qw( LinkTogether LinkTogetherAnother LinkType LinkTogetherLinkType ZTSMStatusID )
            )
        {
            $GetParam{$Key} = $ParamObject->GetParam( Param => $Key ) || '';
        }

        if ( $GetParam{'LinkTogetherAnother'} ) {
            $Kernel::OM->Get('Kernel::System::CheckItem')->StringClean(
                StringRef => \$GetParam{'LinkTogetherAnother'},
                TrimLeft  => 1,
                TrimRight => 1,
            );
            my $MELTObjectID = $MELTObjectObject->MELTObjectLookup(
                MELTID => $GetParam{'LinkTogetherAnother'},
            );
            if ( !$MELTObjectID ) {
                $Error{'LinkTogetherAnotherInvalid'} = 'ServerError';
            }
        }
    }

    # preprocess MELT Object
    my @SelectedMELTObjects;
    my %MELTObjectClasses;

    # get link object
    my $LinkObject = $Kernel::OM->Get('Kernel::System::LinkObject');

    # loop over MELT Objects to predetermine access and dynamic field handling
    melt_object_id:
    for my $MELTObjectID (@MELTObjectIDs) {
        my $MELTObject = $MELTObjectObject->MELTObjectGet(
            MELTObjectID  => $MELTObjectID,
            DynamicFields => 1,
        );

        next melt_object_id unless IsHashRefWithData($MELTObject);

        # check permissions
        my $Access = $MELTObjectObject->Permission(
            Scope  => 'Item',
            ItemID => $MELTObjectID,
            UserID => $Self->{UserID},
            Type   => $Self->{Config}->{Permission},
        );

        if ( !$Access ) {

            # error screen, don't show MELT Object
            $Output .= $LayoutObject->Notify(
                Data => $LayoutObject->{LanguageObject}->Translate(
                    'You don\'t have write access to this configuration item: %s.',
                    $MELTObject->{Number},
                ),
            );
            next melt_object_id;
        }

        # remember selected MELT Object classes and ids
        push @SelectedMELTObjects, $MELTObject;
        $MELTObjectClasses{ $MELTObject->{Class} } = $MELTObject->{ClassID};
    }

    # check if dynamic fields should be displayed and which ones
    my $DynamicFieldList;
    my %DynamicFieldValues;
    my %ACLReducibleDynamicFields;

    # dynamic fields are only displayed if all MELT Objects are from the same class
    if ( scalar keys %MELTObjectClasses == 1 ) {
        my $Class      = ( keys %MELTObjectClasses )[0];
        my $Definition = $Kernel::OM->Get('Kernel::System::MELTObject')->DefinitionGet(
            ClassID => $MELTObjectClasses{$Class},
        );

        if ( !$Definition->{DefinitionID} ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate( 'No definition was defined for class %s!', $Class ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }
        else {
            $Self->{Definition} = $Definition;
            $Self->{Class}      = $Class;
            $DynamicFieldList   = $Definition->{DynamicFieldRef} ? [ values $Definition->{DynamicFieldRef}->%* ] : [];
        }
    }

    # get dynamic field backend object
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # fetch dynamic field values
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( $DynamicFieldList->@* ) {
        next DYNAMICFIELD unless IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD unless $Self->{Config}->{ $DynamicFieldConfig->{Name} };

        # extract the dynamic field value from the web request
        $DynamicFieldValues{"DynamicField_$DynamicFieldConfig->{Name}"} = $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
        );

        # perform ACLs on values
        my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible'
        );

        if ($IsACLReducible) {
            $ACLReducibleDynamicFields{ $DynamicFieldConfig->{Name} } = 1;
        }
    }

    # process MELT Objects
    my $ActionFlag = 0;
    my $Counter    = 1;

    melt_object_id:
    for my $MELTObject (@SelectedMELTObjects) {

        # do some actions on CIs
        if ( ( $Self->{Subaction} eq 'Do' ) && ( !%Error ) ) {

            # challenge token check for write action
            $LayoutObject->ChallengeTokenCheck();

            # bulk action MELT Object update
            $MELTObjectObject->MELTObjectUpdate(
                $MELTObject->%*,
                %GetParam,
                %DynamicFieldValues,
                UserID => $Self->{UserID},
            );

            # bulk action links
            # link all MELT Objects to another MELT Object
            if ( $GetParam{'LinkTogetherAnother'} ) {
                my $MainMELTObjectID = $MELTObjectObject->MELTObjectLookup(
                    MELTID => $GetParam{'LinkTogetherAnother'},
                );

                # split the type identifier
                my @Type = split /::/, $GetParam{LinkType};

                if ( $Type[0] && $Type[1] && ( $Type[1] eq 'Source' || $Type[1] eq 'Target' ) ) {

                    my $SourceKey = $MELTObject->{MELTObjectID};
                    my $TargetKey = $MainMELTObjectID;

                    if ( $Type[1] eq 'Target' ) {
                        $SourceKey = $MainMELTObjectID;
                        $TargetKey = $MELTObject->{MELTObjectID};
                    }

                    for my $MELTObjectIDPartner ( map { $_->{MELTObjectID} } @SelectedMELTObjects ) {
                        if ( $MainMELTObjectID ne $MELTObjectIDPartner ) {
                            $LinkObject->LinkAdd(
                                SourceObject => 'MELTObject',
                                SourceKey    => $SourceKey,
                                TargetObject => 'MELTObject',
                                TargetKey    => $TargetKey,
                                Type         => $Type[0],
                                State        => 'Valid',
                                UserID       => $Self->{UserID},
                            );
                        }
                    }
                }
            }

            # link together
            if ( $GetParam{'LinkTogether'} ) {

                # split the type identifier
                my @Type = split /::/, $GetParam{LinkTogetherLinkType};

                if ( $Type[0] && $Type[1] && ( $Type[1] eq 'Source' || $Type[1] eq 'Target' ) ) {
                    for my $MELTObjectIDPartner ( map { $_->{MELTObjectID} } @SelectedMELTObjects ) {

                        my $SourceKey = $MELTObject->{MELTObjectID};
                        my $TargetKey = $MELTObjectIDPartner;

                        if ( $Type[1] eq 'Target' ) {
                            $SourceKey = $MELTObjectIDPartner;
                            $TargetKey = $MELTObject->{MELTObjectID};
                        }

                        if ( $MELTObject->{MELTObjectID} ne $MELTObjectIDPartner ) {
                            $LinkObject->LinkAdd(
                                SourceObject => 'MELTObject',
                                SourceKey    => $SourceKey,
                                TargetObject => 'MELTObject',
                                TargetKey    => $TargetKey,
                                Type         => $Type[0],
                                State        => 'Valid',
                                UserID       => $Self->{UserID},
                            );
                        }
                    }
                }
            }
            $ActionFlag = 1;
        }
        $Counter++;
    }

    # redirect
    if ($ActionFlag) {
        return $LayoutObject->PopupClose(
            URL => ( $Self->{LastScreenOverview} || 'Action=AgentDashboard' ),
        );
    }

    $Output .= $Self->_Mask(
        %Param,
        %GetParam,
        DynamicField  => \%DynamicFieldValues,
        MELTObjectIDs => [ map { $_->{MELTObjectID} } @SelectedMELTObjects ],
        Errors        => \%Error,
    );
    $Output .= $LayoutObject->Footer(
        Type => 'Small',
    );
    return $Output;
}

sub _Mask {
    my ( $Self, %Param ) = @_;

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # prepare errors!
    if ( $Param{Errors} ) {
        for my $KeyError ( sort keys %{ $Param{Errors} } ) {
            $Param{$KeyError} = $LayoutObject->Ascii2Html( Text => $Param{Errors}->{$KeyError} );
        }
    }

    $LayoutObject->Block(
        Name => 'BulkAction',
        Data => \%Param,
    );

    # remember MELT Object ids
    if ( $Param{MELTObjectIDs} ) {
        for my $MELTObjectID ( @{ $Param{MELTObjectIDs} } ) {
            $LayoutObject->Block(
                Name => 'UsedMELTObjectID',
                Data => {
                    MELTObjectID => $MELTObjectID,
                },
            );
        }
    }

    # get needed objects
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # ZTSM Status
    if ( $Self->{Config}->{ZTSMStatus} ) {
        my $ZTSMStatusList = $GeneralCatalogObject->ItemList(
            Class => 'ZTSM::MELT::Status',
        );

        # generate ZTSMStatusStrg
        $Param{ZTSMStatusStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => $ZTSMStatusList,
            Name         => 'ZTSMStatusID',
            PossibleNone => 1,
            SelectedID   => $Param{ZTSMStatusID},
            Sort         => 'AlphanumericValue',
        );
        $LayoutObject->Block(
            Name => 'ZTSMStatus',
            Data => {%Param},
        );
    }

    # ZTSM Status
    if ( $Self->{Config}->{ZTSMStatus} ) {

        # get ZTSM Status list
        my $ZTSMStatusList = $GeneralCatalogObject->ItemList(
            Class       => 'ZTSM::MELT::Status',
            Preferences => {
                Functionality => [ 'operational', 'incident' ],
            },
        );

        # generate ZTSMStatusStrg
        $Param{ZTSMStatusStrg} = $LayoutObject->BuildSelection(
            Class        => 'Modernize',
            Data         => $ZTSMStatusList,
            Name         => 'ZTSMStatusID',
            PossibleNone => 1,
            SelectedID   => $Param{ZTSMStatusID},
            Sort         => 'AlphanumericValue',
        );
        $LayoutObject->Block(
            Name => 'ZTSMStatus',
            Data => {%Param},
        );
    }

    # get link object
    my $LinkObject = $Kernel::OM->Get('Kernel::System::LinkObject');

    # link types list
    # get possible types list
    my %PossibleTypesList = $LinkObject->PossibleTypesList(
        Object1 => 'MELTObject',
        Object2 => 'MELTObject',
        UserID  => $Self->{UserID},
    );

    # define blank line entry
    my %BlankLine = (
        Key      => '-',
        Value    => '-------------------------',
        Disabled => 1,
    );

    # create the selectable type list
    my $Counter = 0;
    my @SelectableTypesList;
    my @LinkTogetherTypeList;
    POSSIBLETYPE:
    for my $PossibleType ( sort { lc $a cmp lc $b } keys %PossibleTypesList ) {

        # lookup type id
        my $TypeID = $LinkObject->TypeLookup(
            Name   => $PossibleType,
            UserID => $Self->{UserID},
        );

        # get type
        my %Type = $LinkObject->TypeGet(
            TypeID => $TypeID,
            UserID => $Self->{UserID},
        );

        # type list for link together can contain only
        # link types which are not directed (not pointed)
        if ( !$Type{Pointed} ) {

            # create the source name
            my %SourceName;
            $SourceName{Key}   = $PossibleType . '::Source';
            $SourceName{Value} = $Type{SourceName};

            push @LinkTogetherTypeList, \%SourceName;
        }

        # create the source name
        my %SourceName;
        $SourceName{Key}   = $PossibleType . '::Source';
        $SourceName{Value} = $Type{SourceName};

        push @SelectableTypesList, \%SourceName;

        next POSSIBLETYPE if !$Type{Pointed};

        # create the target name
        my %TargetName;
        $TargetName{Key}   = $PossibleType . '::Target';
        $TargetName{Value} = $Type{TargetName};

        push @SelectableTypesList, \%TargetName;
    }
    continue {

        # add blank line
        push @SelectableTypesList, \%BlankLine;

        $Counter++;
    }

    # removed last (empty) entry
    pop @SelectableTypesList;

    # add blank lines on top and bottom of the list if more then two linktypes
    if ( $Counter > 2 ) {
        unshift @SelectableTypesList, \%BlankLine;
        push @SelectableTypesList, \%BlankLine;
    }

    # generate LinkTypeStrg
    $Param{LinkTypeStrg} = $LayoutObject->BuildSelection(
        Class        => 'Modernize',
        Data         => \@SelectableTypesList,
        Name         => 'LinkType',
        PossibleNone => 0,
        SelectedID   => $Param{TypeIdentifier} || 'AlternativeTo::Source',
        Sort         => 'AlphanumericValue',
    );
    $Param{LinkTogetherLinkTypeStrg} = $LayoutObject->BuildSelection(
        Class        => 'Modernize',
        Data         => \@LinkTogetherTypeList,
        Name         => 'LinkTogetherLinkType',
        PossibleNone => 0,
        SelectedID   => $Param{TypeIdentifier} || 'AlternativeTo::Source',
        Sort         => 'AlphanumericValue',
    );

    $Param{LinkTogetherYesNoOption} = $LayoutObject->BuildSelection(
        Class      => 'Modernize',
        Data       => $ConfigObject->Get('YesNoOptions'),
        Name       => 'LinkTogether',
        SelectedID => $Param{LinkTogether} || 0,
    );

    # render dynamic fields
    if ( IsHashRefWithData( $Self->{Definition} ) && IsHashRefWithData( $Self->{Definition}{DefinitionRef} ) && $Self->{Definition}{DefinitionRef}{Sections} ) {

        # TODO: It would be nice to switch between pages for the edit mask, too. Keeping the fields in sync
        #       while editing needs a bit more preparation though
        # Thus for now make sure to show dynamic fields only once, even if present on multiple pages/sections
        my $FieldsSeen = {};

        for my $Page ( $Self->{Definition}{DefinitionRef}{Pages}->@* ) {

            SECTION:
            for my $SectionConfig ( $Page->{Content}->@* ) {
                my $Section = $Self->{Definition}{DefinitionRef}{Sections}{ $SectionConfig->{Section} };

                next SECTION unless $Section;
                next SECTION if $Section->{Type} && $Section->{Type} ne 'DynamicFields';

                # weed out multiple occurances of dynamic fields - see comment above
                $Section->{Content} = $Self->_DiscardFieldsSeen(
                    Content       => $Section->{Content},
                    ConfiguredDFs => $Self->{Config}->{DynamicField},
                    Seen          => $FieldsSeen,
                );

                # do not proceed if content is empty
                next SECTION unless $Section->{Content}->@*;

                $Param{DynamicFieldHTML} .= $Kernel::OM->Get('Kernel::Output::HTML::DynamicField::Mask')->EditSectionRender(
                    Content            => $Section->{Content},
                    DynamicFields      => $Self->{Definition}{DynamicFieldRef},
                    LayoutObject       => $LayoutObject,
                    ParamObject        => $Kernel::OM->Get('Kernel::System::Web::Request'),
                    DynamicFieldValues => $Param{DynamicField},
                    AJAXUpdatable      => 0,

                    # TODO ask if this should be used
                    # PossibleValuesFilter => \%DynamicFieldPossibleValues,
                    # Errors               => \%DynamicFieldValidationResult,
                    # Visibility           => \%DynamicFieldVisibility,
                    Object => {
                        Class => $Self->{Class},
                        $Param{DynamicField}->%*,
                    },
                );
            }
        }
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'AgentMELTObjectBulk',
        Data         => \%Param,
    );
}

sub _DiscardFieldsSeen {
    my ( $Self, %Param ) = @_;

    my $Content;
    my $Ref = ref $Param{Content};

    if ( $Ref eq 'ARRAY' ) {
        my @CleanedArray;

        ELEMENT:
        for my $Element ( $Param{Content}->@* ) {
            my $RefElement = ref $Element;

            if ( $RefElement eq 'ARRAY' ) {
                push @CleanedArray, $Self->_DiscardFieldsSeen(
                    Content => $Element,
                    Seen    => $Param{Seen},
                );

                next ELEMENT;
            }

            elsif ( $RefElement eq 'HASH' ) {
                if ( !$Element->{DF} ) {
                    push @CleanedArray, $Self->_DiscardFieldsSeen(
                        Content => $Element,
                        Seen    => $Param{Seen},
                    );

                    next ELEMENT;
                }

                if ( !$Param{ConfiguredDFs}{ $Element->{DF} } || $Param{Seen}{ $Element->{DF} }++ ) {
                    next ELEMENT;
                }
            }

            push @CleanedArray, $Element;
        }

        $Content = \@CleanedArray;
    }

    elsif ( $Ref eq 'HASH' ) {
        my %CleanedHash;

        for my $Key ( keys $Param{Content}->%* ) {
            $CleanedHash{$Key} = $Self->_DiscardFieldsSeen(
                Content => $Param{Content}{$Key},
                Seen    => $Param{Seen},
            );
        }

        $Content = \%CleanedHash;
    }

    else {
        $Content = $Param{Content};
    }

    return $Content;
}

1;

