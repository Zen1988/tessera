# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
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

package Kernel::Modules::CustomerTicketZoom;

use v5.24;
use strict;
use warnings;

# core modules
use Digest::MD5 qw(md5_hex);
use List::Util  qw(any);

# CPAN modules

# OTOBO modules
use Kernel::Language              qw(Translatable);
use Kernel::System::ZTSMBlueBookRuntime ();
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = bless {%Param}, $Type;

    # frontend specific config
    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # get the dynamic fields for this screen
    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{FollowUpDynamicField} || {},
    );

    my $Definition = $Kernel::OM->Get('Kernel::System::Ticket::Mask')->DefinitionGet(
        Mask => $Self->{Action},
    ) || {};

    $Self->{MaskDefinition}       = $Definition->{Mask};
    $Self->{FollowUpDynamicField} = {};

    # align sysconfig and ticket mask data I
    DYNAMICFIELD:
    for my $DynamicField ( @{ $DynamicFieldList // [] } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicField);

        my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicField,
            Behavior           => 'IsCustomerInterfaceCapable',
        );

        # reduce the dynamic fields to only the ones that are designed for customer interface
        next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

        if ( exists $Definition->{DynamicFields}{ $DynamicField->{Name} } ) {
            my $Parameters = delete $Definition->{DynamicFields}{ $DynamicField->{Name} } // {};

            for my $Attribute ( keys $Parameters->%* ) {
                $DynamicField->{$Attribute} = $Parameters->{$Attribute};
            }
        }
        else {
            push $Self->{MaskDefinition}->@*, {
                DF        => $DynamicField->{Name},
                Mandatory => $Config->{FollowUpDynamicField}{ $DynamicField->{Name} } == 2 ? 1 : 0,
            };

            if ( $Config->{FollowUpDynamicField}{ $DynamicField->{Name} } == 2 ) {
                $DynamicField->{Mandatory} = 1;
            }
        }

        $Self->{FollowUpDynamicField}{ $DynamicField->{Name} } = $DynamicField;
    }

    # align sysconfig and ticket mask data II
    for my $DynamicFieldName ( keys $Definition->{DynamicFields}->%* ) {
        $Self->{FollowUpDynamicField}{$DynamicFieldName} = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicFieldName,
        );

        my $Parameters = $Definition->{DynamicFields}{$DynamicFieldName} // {};

        for my $Attribute ( keys $Parameters->%* ) {
            $Self->{FollowUpDynamicField}{$DynamicFieldName}{$Attribute} = $Parameters->{$Attribute};
        }
    }

    # get form id
    $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::FormCache')->PrepareFormID(
        ParamObject  => $Kernel::OM->Get('Kernel::System::Web::Request'),
        LayoutObject => $Kernel::OM->Get('Kernel::Output::HTML::Layout'),
    );

    # methods which are used to determine the possible values of the standard fields
    $Self->{FieldMethods} = [
        {
            FieldID => 'PriorityID',
            Method  => \&_GetPriorities
        },
        {
            FieldID => 'NextStateID',
            Method  => \&_GetNextStates
        },
    ];

    # dependencies of standard fields which are not defined via ACLs - here for consistency
    $Self->{InternalDependancy} = {};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $TicketNumber = $ParamObject->GetParam( Param => 'TicketNumber' );

    # ticket id lookup
    if ( !$Self->{TicketID} && $TicketNumber ) {
        $Self->{TicketID} = $TicketObject->TicketIDLookup(
            TicketNumber => $ParamObject->GetParam( Param => 'TicketNumber' ),
            UserID       => $Self->{UserID},
        );
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # customers should not get to know that whether an ticket exists or not
    # if a ticket does not exist, show a "no permission" screen
    if ( $TicketNumber && !$Self->{TicketID} ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    # check needed stuff
    if ( !$Self->{TicketID} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => Translatable('Need TicketID!'),
        );
        $Output .= $LayoutObject->CustomerFooter();

        return $Output;
    }

    # check permissions
    my $Access = $TicketObject->TicketCustomerPermission(
        Type     => 'ro',
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    # error screen, don't show ticket
    if ( !$Access ) {
        $Access = $Kernel::OM->Get('Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck')->Run(
            TicketID       => $Self->{TicketID},
            CustomerUserID => $Self->{UserID},
            Type           => 'ro',
        );

        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' )
            if !$Access;
    }

    my %ZTSMAccessTicket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
        UserID        => 1,
    );

    if (
        _ZTSMExecutionTicketProtected( Ticket => \%ZTSMAccessTicket )
        && !$Kernel::OM->Get('Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck')->Run(
            TicketID       => $Self->{TicketID},
            CustomerUserID => $Self->{UserID},
            Type           => 'ro',
        )
        )
    {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # process management
    my %ActivityErrorHTML;
    if ( $Self->{Subaction} eq 'StoreActivityDialog' ) {
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::Modules::CustomerTicketProcess") ) {
            return $LayoutObject->FatalError(
                Message => Translatable('Could not load process module.'),
            );
        }

        my $ProcessModule = ('Kernel::Modules::CustomerTicketProcess')->new(
            %{$Self},
            Action    => 'CustomerTicketProcess',
            Subaction => $Self->{Subaction},
            ModuleReg => $ConfigObject->Get('CustomerFrontend::Module')->{'CustomerTicketProcess'},
        );

        my $ActivityDialogEntityID = $ParamObject->GetParam( Param => 'ActivityDialogEntityID' );
        $ActivityErrorHTML{$ActivityDialogEntityID} = $ProcessModule->Run(%Param);

        # return directly in case of an error dialog
        return $ActivityErrorHTML{$ActivityDialogEntityID} if $ActivityErrorHTML{$ActivityDialogEntityID} =~ /^<!DOCTYPE html>/;
    }

    elsif ( $Self->{Subaction} eq 'AJAXUpdate' && $ParamObject->GetParam( Param => 'ActivityDialogEntityID' ) ) {
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::Modules::CustomerTicketProcess") ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Could not load process module."
            );
            return;
        }

        my $ProcessModule = ('Kernel::Modules::CustomerTicketProcess')->new(
            %{$Self},
            Action    => 'CustomerTicketProcess',
            Subaction => $Self->{Subaction},
            ModuleReg => $ConfigObject->Get('CustomerFrontend::Module')->{'CustomerTicketProcess'},
        );

        return $ProcessModule->Run(%Param);
    }

    # get ticket data
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
    );

    my $ZTSMReadOnlyView = $ParamObject->GetParam( Param => 'ZTSMReadOnlyView' ) ? 1 : 0;

    my $ZTSMRuntimeActions = $ZTSMReadOnlyView
        ? undef
        : $Self->_ZTSMRuntimeActions(
            Ticket => \%Ticket,
        );
    my $ZTSMStoryLinks = $Self->_ZTSMStoryLinks(
        Ticket => \%Ticket,
    );
    my $ZTSMRequestInfoHTML = $Self->_ZTSMRequestInfoHTML(
        Ticket => \%Ticket,
    );
    my $ZTSMHeaderOwnership = $Self->_ZTSMHeaderOwnership(
        Ticket => \%Ticket,
    );

    # get ACL restrictions
    my %PossibleActions;
    my $Counter = 0;

    # get all registered Actions
    if ( ref $ConfigObject->Get('CustomerFrontend::Module') eq 'HASH' ) {

        my %Actions = %{ $ConfigObject->Get('CustomerFrontend::Module') };

        # only use those Actions that starts with Customer
        %PossibleActions = map { ++$Counter => $_ }
            grep { substr( $_, 0, length 'Customer' ) eq 'Customer' }
            sort keys %Actions;
    }
    $PossibleActions{ ++$Counter } = 'CustomerTicketZoomReply';

    my $ACL = $TicketObject->TicketAcl(
        Data           => \%PossibleActions,
        Action         => $Self->{Action},
        TicketID       => $Self->{TicketID},
        ReturnType     => 'Action',
        ReturnSubType  => '-',
        CustomerUserID => $Self->{UserID},
    );

    my %AclAction = %PossibleActions;
    if ($ACL) {
        %AclAction = $TicketObject->TicketAclActionData();
    }

    # check if ACL restrictions exist
    my %AclActionLookup = reverse %AclAction;

    # show error screen if ACL prohibits this action
    if ( !$AclActionLookup{ $Self->{Action} } ) {
        return $LayoutObject->NoPermission( WithHeader => 'yes' );
    }

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');

    # get all articles of this ticket, that are visible for the customer
    my @ArticleList = $ArticleObject->ArticleList(
        TicketID             => $Self->{TicketID},
        IsVisibleForCustomer => 1,
        DynamicFields        => 0,
    );

    my @ArticleBox;
    my $ArticleBackendObject;

    ARTICLEMETADATA:
    for my $ArticleMetaData (@ArticleList) {

        next ARTICLEMETADATA if !$ArticleMetaData;
        next ARTICLEMETADATA if !IsHashRefWithData($ArticleMetaData);

        $ArticleBackendObject = $ArticleObject->BackendForArticle( %{$ArticleMetaData} );

        my %ArticleData = $ArticleBackendObject->ArticleGet(
            TicketID  => $Self->{TicketID},
            ArticleID => $ArticleMetaData->{ArticleID},
            RealNames => 1,
        );

        # Get channel specific fields
        my %ArticleFields = $LayoutObject->ArticleFields(
            TicketID  => $Self->{TicketID},
            ArticleID => $ArticleMetaData->{ArticleID},
        );

        $ArticleData{Subject}      = $ArticleFields{Subject};
        $ArticleData{FromRealname} = $ArticleFields{Sender};

        # Get attachment index.
        my %AtmIndex = $ArticleBackendObject->ArticleAttachmentIndex(
            ArticleID        => $ArticleMetaData->{ArticleID},
            ExcludePlainText => 1,
            ExcludeHTMLBody  => 1,
            ExcludeInline    => 1,
        );

        if ( IsHashRefWithData( \%AtmIndex ) ) {
            $ArticleData{Attachment} = \%AtmIndex;
        }

        push @ArticleBox, \%ArticleData;
    }

    my %GetParam;
    for my $Key (qw(Subject Body StateID PriorityID FromChatID FromChat)) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    # get Dynamic fields from ParamObject
    my %DynamicFieldValues;

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    if ( $GetParam{FromChatID} ) {
        if ( !$ConfigObject->Get('ChatEngine::Active') ) {
            return $LayoutObject->FatalError(
                Message => Translatable('Chat is not active.'),
            );
        }

        # Check chat participant
        my %ChatParticipant = $Kernel::OM->Get('Kernel::System::Chat')->ChatParticipantCheck(
            ChatID      => $GetParam{FromChatID},
            ChatterType => 'Customer',
            ChatterID   => $Self->{UserID},
        );

        if ( !%ChatParticipant ) {
            return $LayoutObject->FatalError(
                Message => Translatable('No permission.'),
            );
        }
    }

    my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( values $Self->{FollowUpDynamicField}->%* ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } = $BackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
        );
    }

    # convert dynamic field values into a structure for ACLs
    my %DynamicFieldACLParameters;
    DYNAMICFIELD:
    for my $DynamicField ( sort keys %DynamicFieldValues ) {
        next DYNAMICFIELD if !$DynamicField;
        next DYNAMICFIELD if !$DynamicFieldValues{$DynamicField};

        $DynamicFieldACLParameters{ 'DynamicField_' . $DynamicField } = $DynamicFieldValues{$DynamicField};
    }
    $GetParam{DynamicField} = \%DynamicFieldACLParameters;

    if ( $Self->{Subaction} eq 'AJAXUpdate' ) {

        # get TicketID
        if ( !$GetParam{TicketID} ) {
            $GetParam{TicketID} =
                $Self->{TicketID} ||
                $ParamObject->GetParam( Param => 'TicketID' );
        }

        my $CustomerUser = $Self->{UserID};

        my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' );

        # use the FieldIDs, which are found in AgentTicketPhone/Email, and CustomerTicketMessage
        my %Uniformity = (
            StateID => 'NextStateID',
        );
        if ( $ElementChanged && $Uniformity{$ElementChanged} ) {
            $ElementChanged = $Uniformity{$ElementChanged};
        }
        for my $DiversID ( keys %Uniformity ) {
            $GetParam{ $Uniformity{$DiversID} } = $GetParam{$DiversID};
        }

        my $FieldRestrictionsObject = $Kernel::OM->Get('Kernel::System::Ticket::FieldRestrictions');
        my $Autoselect              = $ConfigObject->Get('TicketACL::Autoselect') || undef;

        # track changing standard fields
        my $ACLPreselection;
        if ( $ConfigObject->Get('TicketACL::ACLPreselection') ) {

            # get cached preselection rules
            my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
            $ACLPreselection = $CacheObject->Get(
                Type => 'TicketACL',
                Key  => 'Preselection',
            );
            if ( !$ACLPreselection ) {
                $ACLPreselection = $FieldRestrictionsObject->SetACLPreselectionCache();
            }
        }

        my %Convergence = (
            StdFields => 0,
            Fields    => 0,
        );
        my %ChangedElements = $ElementChanged ? ( $ElementChanged => 1 ) : ();
        if ( $ChangedElements{ServiceID} ) {
            $ChangedElements{CustomerUserID} = 1;
            $ChangedElements{CustomerID}     = 1;

            $GetParam{CustomerUserID} = $Self->{UserID};
            $GetParam{CustomerID}     = $Self->{UserCustomerID};
        }
        my %ChangedElementsDFStart = %ChangedElements;
        my %ChangedStdFields       = $ElementChanged && $ElementChanged !~ /^DynamicField_/ ? %ChangedElements : ();

        my $LoopProtection = 100;
        my %StdFieldValues;
        my %DynFieldStates = (
            Visibility => {},
            Fields     => {},
            Sets       => {},
        );

        until ( $Convergence{Fields} ) {

            # determine standard field input
            until ( $Convergence{StdFields} ) {

                my %NewChangedElements;

                # which standard fields to check - FieldID => GetParamValue (necessary for Dest)
                my %Check = (
                    NextStateID => 'NextStateID',
                    PriorityID  => 'PriorityID',
                );
                if ($ACLPreselection) {
                    FIELD:
                    for my $FieldID ( sort keys %Check ) {
                        if ( !$ACLPreselection->{Fields}{$FieldID} ) {
                            next FIELD;
                        }
                        if ( $Autoselect && $Autoselect->{$FieldID} && $ChangedElements{$FieldID} ) {
                            next FIELD;
                        }
                        for my $Element ( sort keys %ChangedElements ) {
                            if (
                                $ACLPreselection->{Rules}{Ticket}{$Element}{$FieldID}
                                || $Self->{InternalDependancy}{$Element}{$FieldID}
                                )
                            {
                                next FIELD;
                            }
                            if ( !$ACLPreselection->{Fields}{$Element} ) {
                                next FIELD;
                            }
                        }

                        # delete unaffected fields
                        delete $Check{$FieldID};
                    }
                }

                # for each standard field which has to be checked, run the defined method
                METHOD:
                for my $Field ( @{ $Self->{FieldMethods} } ) {
                    next METHOD if !$Check{ $Field->{FieldID} };

                    # use $Check{ $Field->{FieldID} } for Dest=>QueueID
                    $StdFieldValues{ $Check{ $Field->{FieldID} } } = $Field->{Method}->(
                        $Self,
                        %GetParam,
                        StateID        => $GetParam{NextStateID},
                        CustomerUserID => $CustomerUser || '',
                        TicketID       => $Self->{TicketID},
                    );

                    # special stuff for QueueID/Dest: Dest is "QueueID||QueueName" => "QueueName";
                    if ( $Field->{FieldID} eq 'Dest' ) {
                        TOs:
                        for my $QueueID ( sort keys %{ $StdFieldValues{QueueID} } ) {
                            next TOs if ( $StdFieldValues{QueueID}{$QueueID} eq '-' );
                            $StdFieldValues{Dest}{"$QueueID||$StdFieldValues{QueueID}{ $QueueID }"} = $StdFieldValues{QueueID}{$QueueID};
                        }

                        # check current selection of QueueID (Dest will be done together with the other fields)
                        if ( $GetParam{QueueID} && !$StdFieldValues{Dest}{ $GetParam{Dest} } ) {
                            $GetParam{QueueID} = '';
                        }

                        # autoselect
                        if ( !$GetParam{QueueID} && $Autoselect && $Autoselect->{Dest} ) {
                            $GetParam{QueueID} = $FieldRestrictionsObject->Autoselect(
                                PossibleValues => $StdFieldValues{QueueID},
                            ) || '';
                        }
                    }

                    # check whether current selected value is still valid for the field
                    if (
                        $GetParam{ $Field->{FieldID} }
                        && !$StdFieldValues{ $Field->{FieldID} }{ $GetParam{ $Field->{FieldID} } }
                        )
                    {
                        # if not empty the field
                        $GetParam{ $Field->{FieldID} }           = '';
                        $NewChangedElements{ $Field->{FieldID} } = 1;
                        $ChangedStdFields{ $Field->{FieldID} }   = 1;
                    }

                    # autoselect
                    if ( !$GetParam{ $Field->{FieldID} } && $Autoselect && $Autoselect->{ $Field->{FieldID} } ) {
                        $GetParam{ $Field->{FieldID} } = $FieldRestrictionsObject->Autoselect(
                            PossibleValues => $StdFieldValues{ $Field->{FieldID} },
                        ) || '';
                        if ( $GetParam{ $Field->{FieldID} } ) {
                            $NewChangedElements{ $Field->{FieldID} } = 1;
                            $ChangedStdFields{ $Field->{FieldID} }   = 1;
                        }
                    }
                }

                if ( !%NewChangedElements ) {
                    $Convergence{StdFields} = 1;
                }
                else {
                    %ChangedElements = %NewChangedElements;
                }

                %ChangedElementsDFStart = (
                    %ChangedElementsDFStart,
                    %NewChangedElements,
                );

                if ( $LoopProtection-- < 1 ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'error',
                        Message  => "Ran into unresolvable loop!",
                    );

                    # TODO: is returning an empty list reasonable?
                    return;
                }
            }

            %ChangedElements        = %ChangedElementsDFStart;
            %ChangedElementsDFStart = ();

            # check dynamic fields
            my %CurFieldStates;
            if (%ChangedElements) {

                # get values and visibility of dynamic fields
                %CurFieldStates = $FieldRestrictionsObject->GetFieldStates(
                    TicketObject              => $TicketObject,
                    DynamicFields             => $Self->{FollowUpDynamicField},
                    DynamicFieldBackendObject => $BackendObject,
                    ChangedElements           => \%ChangedElements,               # optional to reduce ACL evaluation
                    Action                    => $Self->{Action},
                    TicketID                  => $Self->{TicketID},
                    FormID                    => $Self->{FormID},
                    CustomerUser              => $Self->{UserID},
                    GetParam                  => {%GetParam},
                    Autoselect                => $Autoselect,
                    ACLPreselection           => $ACLPreselection,
                    LoopProtection            => \$LoopProtection,
                );

                # combine FieldStates
                $DynFieldStates{Fields} = {
                    %{ $DynFieldStates{Fields} },
                    %{ $CurFieldStates{Fields} },
                };
                $DynFieldStates{Visibility} = {
                    %{ $DynFieldStates{Visibility} },
                    %{ $CurFieldStates{Visibility} },
                };
                $DynFieldStates{Sets} = {
                    %{ $DynFieldStates{Sets} },
                    %{ $CurFieldStates{Sets} },
                };

                # store new values
                $GetParam{DynamicField} = {
                    %{ $GetParam{DynamicField} },
                    %{ $CurFieldStates{NewValues} },
                };
            }

            # if dynamic fields changed, check standard fields again
            if ( %CurFieldStates && IsHashRefWithData( $CurFieldStates{NewValues} ) ) {
                $Convergence{StdFields} = 0;
                %ChangedElements = map { $_ => 1 } keys %{ $CurFieldStates{NewValues} };
            }
            else {
                $Convergence{Fields} = 1;
            }

        }

        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $Name ( sort keys %{ $DynFieldStates{Fields} } ) {
            my $DynamicFieldConfig = $Self->{FollowUpDynamicField}{$Name};

            if ( $DynamicFieldConfig->{Config}{MultiValue} && ref $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"} eq 'ARRAY' ) {
                for my $i ( 0 .. $#{ $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"} } ) {
                    my $DataValues = $DynFieldStates{Fields}{$Name}{NotACLReducible}
                        ? ( $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"}[$i] // '' )
                        :
                        (
                            $BackendObject->BuildSelectionDataGet(
                                DynamicFieldConfig => $DynamicFieldConfig,
                                PossibleValues     => $DynFieldStates{Fields}{$Name}{PossibleValues},
                                Value              => [ $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"}[$i] ],
                            )
                            || $DynFieldStates{Fields}{$Name}{PossibleValues}
                        );

                    # add dynamic field to the list of fields to update
                    push @DynamicFieldAJAX, {
                        Name        => "DynamicField_$DynamicFieldConfig->{Name}_$i",
                        Data        => $DataValues,
                        SelectedID  => $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"}[$i],
                        Translation => $DynamicFieldConfig->{Config}{TranslatableValues} || 0,
                        Max         => 100,
                    };
                }

                # add template value for keeping templates in line with ACLs
                if ( !$DynFieldStates{Fields}{$Name}{NotACLReducible} ) {
                    my $DataValues = (
                        $BackendObject->BuildSelectionDataGet(
                            DynamicFieldConfig => $DynamicFieldConfig,
                            PossibleValues     => $DynFieldStates{Fields}{$Name}{PossibleValues},
                            Value              => [ $DynamicFieldConfig->{Config}{DefaultValue} // '' ],
                            )
                            || $DynFieldStates{Fields}{$Name}{PossibleValues}
                    );

                    # add dynamic field to the list of fields to update
                    push @DynamicFieldAJAX, {
                        Name        => "DynamicField_$DynamicFieldConfig->{Name}_Template",
                        Data        => $DataValues,
                        SelectedID  => $DynamicFieldConfig->{Config}{DefaultValue} // '',
                        Translation => $DynamicFieldConfig->{Config}{TranslatableValues} || 0,
                        Max         => 100,
                    };
                }

                next DYNAMICFIELD;
            }

            my $DataValues = $DynFieldStates{Fields}{$Name}{NotACLReducible}
                ? ( $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"} // '' )
                :
                (
                    $BackendObject->BuildSelectionDataGet(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        PossibleValues     => $DynFieldStates{Fields}{$Name}{PossibleValues},
                        Value              => $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"},
                    )
                    || $DynFieldStates{Fields}{$Name}{PossibleValues}
                );

            # add dynamic field to the list of fields to update
            push @DynamicFieldAJAX, {
                Name        => 'DynamicField_' . $DynamicFieldConfig->{Name},
                Data        => $DataValues,
                SelectedID  => $GetParam{DynamicField}{"DynamicField_$DynamicFieldConfig->{Name}"},
                Translation => $DynamicFieldConfig->{Config}{TranslatableValues} || 0,
                Max         => 100,
            };
        }

        for my $SetField ( values $DynFieldStates{Sets}->%* ) {
            my $DynamicFieldConfig = $SetField->{DynamicFieldConfig};

            # the frontend name is the name of the inner field including its index or the '_Template' suffix
            DYNAMICFIELD:
            for my $FrontendName ( keys $SetField->{FieldStates}->%* ) {

                if ( $DynamicFieldConfig->{Config}{MultiValue} && ref $SetField->{Values}{$FrontendName} eq 'ARRAY' ) {
                    for my $i ( 0 .. $#{ $SetField->{Values}{$FrontendName} } ) {
                        my $DataValues = $SetField->{FieldStates}{$FrontendName}{NotACLReducible}
                            ? ( $SetField->{Values}{$FrontendName}[$i] // '' )
                            :
                            (
                                $BackendObject->BuildSelectionDataGet(
                                    DynamicFieldConfig => $DynamicFieldConfig,
                                    PossibleValues     => $SetField->{FieldStates}{$FrontendName}{PossibleValues},
                                    Value              => [ $SetField->{Values}{$FrontendName}[$i] ],
                                )
                                || $SetField->{FieldStates}{$FrontendName}{PossibleValues}
                            );

                        # add dynamic field to the list of fields to update
                        push @DynamicFieldAJAX, {
                            Name        => 'DynamicField_' . $FrontendName . "_$i",
                            Data        => $DataValues,
                            SelectedID  => $SetField->{Values}{$FrontendName}[$i],
                            Translation => $DynamicFieldConfig->{Config}{TranslatableValues} || 0,
                            Max         => 100,
                        };
                    }

                    # add template value for keeping templates in line with ACLs
                    if ( !$SetField->{FieldStates}{$FrontendName}{NotACLReducible} ) {
                        my $DataValues = (
                            $BackendObject->BuildSelectionDataGet(
                                DynamicFieldConfig => $DynamicFieldConfig,
                                PossibleValues     => $SetField->{FieldStates}{$FrontendName}{PossibleValues},
                                Value              => [ $DynamicFieldConfig->{Config}{DefaultValue} // '' ],
                                )
                                || $SetField->{FieldStates}{$FrontendName}{PossibleValues}
                        );

                        # add dynamic field to the list of fields to update
                        push @DynamicFieldAJAX, {
                            Name        => 'DynamicField_' . $FrontendName . "_Template",
                            Data        => $DataValues,
                            SelectedID  => $DynamicFieldConfig->{Config}{DefaultValue} // '',
                            Translation => $DynamicFieldConfig->{Config}{TranslatableValues} || 0,
                            Max         => 100,
                        };
                    }

                    next DYNAMICFIELD;
                }

                my $DataValues = $SetField->{FieldStates}{$FrontendName}{NotACLReducible}
                    ? ( $SetField->{Values}{$FrontendName} // '' )
                    :
                    (
                        $BackendObject->BuildSelectionDataGet(
                            DynamicFieldConfig => $DynamicFieldConfig,
                            PossibleValues     => $SetField->{FieldStates}{$FrontendName}{PossibleValues},
                            Value              => $SetField->{Values}{$FrontendName},
                        )
                        || $SetField->{FieldStates}{$FrontendName}{PossibleValues}
                    );

                # add dynamic field to the list of fields to update
                push @DynamicFieldAJAX, {
                    Name        => 'DynamicField_' . $FrontendName,
                    Data        => $DataValues,
                    SelectedID  => $SetField->{Values}{$FrontendName},
                    Translation => $DynamicFieldConfig->{Config}{TranslatableValues} || 0,
                    Max         => 100,
                };
            }
        }

        if ( IsHashRefWithData( $DynFieldStates{Visibility} ) ) {
            push @DynamicFieldAJAX, {
                Name => 'Restrictions_Visibility',
                Data => $DynFieldStates{Visibility},
            };
        }

        # build AJAX return for the standard fields
        my @StdFieldAJAX;
        my %Attributes = (
            PriorityID => {
                Translation => 1,
                Max         => 100,
            },
            NextStateID => {
                Translation => 1,
                Max         => 100,
            },
        );
        my %Diversity = reverse %Uniformity;
        for my $Field ( sort keys %StdFieldValues ) {
            push @StdFieldAJAX, {
                Name       => $Diversity{$Field} || $Field,
                Data       => $StdFieldValues{$Field},
                SelectedID => $GetParam{$Field},
                %{ $Attributes{$Field} },
            };
        }
        my $JSON = $LayoutObject->BuildSelectionJSON(
            [
                @StdFieldAJAX,
                @DynamicFieldAJAX,
            ],
        );

        return $LayoutObject->Attachment(
            ContentType => 'application/json',
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    #   end AJAX Update

    # save, if browser link message was closed
    elsif ( $Self->{Subaction} eq 'BrowserLinkMessage' ) {

        $Kernel::OM->Get('Kernel::System::CustomerUser')->SetPreferences(
            UserID => $Self->{UserID},
            Key    => 'UserCustomerDoNotShowBrowserLinkMessage',
            Value  => 1,
        );

        return $LayoutObject->Attachment(
            ContentType => 'text/html',
            Content     => 1,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # check follow up
    elsif ( $Self->{Subaction} eq 'Store' ) {

        if ( !$AclActionLookup{CustomerTicketZoomReply} ) {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck( Type => 'Customer' );

        my $NextScreen = $Self->{NextScreen} || $Config->{NextScreenAfterFollowUp};
        my %Error;

        # get follow up option (possible or not)
        my $QueueObject      = $Kernel::OM->Get('Kernel::System::Queue');
        my $FollowUpPossible = $QueueObject->GetFollowUpOption(
            QueueID => $Ticket{QueueID},
        );

        # get lock option (should be the ticket locked - if closed - after the follow up)
        my $Lock = $QueueObject->GetFollowUpLockOption(
            QueueID => $Ticket{QueueID},
        );

        my $StateObject = $Kernel::OM->Get('Kernel::System::State');

        # get ticket state details
        my %State = $StateObject->StateGet(
            ID => $Ticket{StateID},
        );
        if ( $FollowUpPossible =~ /(new ticket|reject)/i && $State{TypeName} =~ /^close/i ) {
            my $Output = $LayoutObject->CustomerHeader(
                Title => Translatable('Error'),
            );
            $Output .= $LayoutObject->CustomerWarning(
                Message => Translatable('Can\'t reopen ticket, not possible in this queue!'),
                Comment => Translatable('Create a new ticket!'),
            );
            $Output .= $LayoutObject->CustomerFooter();

            return $Output;
        }

        # rewrap body if no rich text is used
        if ( $GetParam{Body} && !$LayoutObject->{BrowserRichText} ) {
            $GetParam{Body} = $LayoutObject->WrapPlainText(
                MaxCharacters => $ConfigObject->Get('Ticket::Frontend::TextAreaNote'),
                PlainText     => $GetParam{Body},
            );
        }

        my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

        if ( $GetParam{FromChat} ) {
            $Error{FromChat}           = 1;
            $GetParam{FollowUpVisible} = 'Visible';
            if ( $GetParam{FromChatID} ) {
                my @ChatMessages = $Kernel::OM->Get('Kernel::System::Chat')->ChatMessageList(
                    ChatID => $GetParam{FromChatID},
                );
                if (@ChatMessages) {
                    for my $Message (@ChatMessages) {
                        $Message->{MessageText} = $LayoutObject->Ascii2Html(
                            Text        => $Message->{MessageText},
                            LinkFeature => 1,
                        );
                    }
                    $GetParam{ChatMessages} = \@ChatMessages;
                }
            }
        }

        if ( !$GetParam{FromChat} ) {
            if ( !$GetParam{Body} || $GetParam{Body} eq '<br />' ) {
                $Error{RichTextInvalid}    = 'ServerError';
                $GetParam{FollowUpVisible} = 'Visible';
            }
        }

        # skip validation of hidden fields
        my %Visibility;

        # transform dynamic field data into DFName => DFName pair
        my %DynamicFieldAcl = map { $_ => $_ } keys $Self->{FollowUpDynamicField}->%*;

        # call ticket ACLs for DynamicFields to check field visibility
        my $ACLResult = $TicketObject->TicketAcl(
            %GetParam,
            CustomerUserID => $Self->{UserID},
            Action         => $Self->{Action},
            ReturnType     => 'Form',
            ReturnSubType  => '-',
            Data           => \%DynamicFieldAcl,
            TicketID       => $Self->{TicketID},
        );
        if ($ACLResult) {
            %Visibility = map { 'DynamicField_' . $_ => 0 } keys $Self->{FollowUpDynamicField}->%*;
            my %AclData = $TicketObject->TicketAclData();
            for my $Field ( sort keys %AclData ) {
                $Visibility{ 'DynamicField_' . $Field } = 1;
            }
        }
        else {
            %Visibility = map { 'DynamicField_' . $_ => 1 } keys $Self->{FollowUpDynamicField}->%*;
        }

        # remember dynamic field validation result if erroneous
        my %DynamicFieldValidationResult;
        my %DynamicFieldPossibleValues;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Self->{FollowUpDynamicField}->%* ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $PossibleValuesFilter;

            my $IsACLReducible = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsACLReducible',
            );

            if ($IsACLReducible) {

                # get PossibleValues
                my $PossibleValues = $BackendObject->PossibleValuesGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                );

                # check if field has PossibleValues property in its configuration
                if ( IsHashRefWithData($PossibleValues) ) {

                    # convert possible values key => value to key => key for ACLs using a Hash slice
                    my %AclData = %{$PossibleValues};
                    @AclData{ keys %AclData } = keys %AclData;

                    # set possible values filter from ACLs
                    my $ACL = $TicketObject->TicketAcl(
                        %GetParam,
                        Action         => $Self->{Action},
                        TicketID       => $Self->{TicketID},
                        ReturnType     => 'Ticket',
                        ReturnSubType  => 'DynamicField_' . $DynamicFieldConfig->{Name},
                        Data           => \%AclData,
                        CustomerUserID => $Self->{UserID},
                    );
                    if ($ACL) {
                        my %Filter = $TicketObject->TicketAclData();

                        # convert Filer key => key back to key => value using map
                        %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} }
                            keys %Filter;
                    }
                }
            }

            $DynamicFieldPossibleValues{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $PossibleValuesFilter;

            my $ValidationResult;

            # do not validate invisible fields
            if ( $Visibility{ 'DynamicField_' . $DynamicFieldConfig->{Name} } ) {
                $ValidationResult = $BackendObject->EditFieldValueValidate(
                    DynamicFieldConfig   => $DynamicFieldConfig,
                    PossibleValuesFilter => $PossibleValuesFilter,
                    ParamObject          => $ParamObject,

                    # Mandatory is added to the configs by $Self->new
                    Mandatory => $DynamicFieldConfig->{Mandatory},
                );

                if ( !IsHashRefWithData($ValidationResult) ) {
                    my $Output = $LayoutObject->CustomerHeader(
                        Title => Translatable('Error'),
                    );
                    $Output .= $LayoutObject->CustomerError(
                        Message => $LayoutObject->{LanguageObject}->Translate( 'Could not perform validation on field %s!', $DynamicFieldConfig->{Label} ),
                        Comment => Translatable('Please contact the administrator.'),
                    );
                    $Output .= $LayoutObject->CustomerFooter();

                    return $Output;
                }

                # propagate validation error to the Error variable to be detected by the frontend
                if ( $ValidationResult->{ServerError} ) {
                    $Error{ $DynamicFieldConfig->{Name} }                        = ' ServerError';
                    $DynamicFieldValidationResult{ $DynamicFieldConfig->{Name} } = $ValidationResult;

                    # make FollowUp visible to correctly show the error
                    $GetParam{FollowUpVisible} = 'Visible';
                }
            }

        }

        # show edit again
        if (%Error) {

            # generate output
            my $Output = $LayoutObject->CustomerHeader( Value => $Ticket{TicketNumber} );
            $Output .= $Self->_Mask(
                TicketID   => $Self->{TicketID},
                ArticleBox => \@ArticleBox,
                Errors     => \%Error,
                %Ticket,
                TicketState   => $Ticket{State},
                TicketStateID => $Ticket{StateID},
                %GetParam,
                Visibility       => \%Visibility,
                DFPossibleValues => \%DynamicFieldPossibleValues,
                DFErrors         => \%DynamicFieldValidationResult,
                Reply            => $AclActionLookup{CustomerTicketZoomReply},
            );
            $Output .= $LayoutObject->CustomerNavigationBar();
            $Output .= $LayoutObject->CustomerFooter();

            return $Output;
        }

        # unlock ticket if agent is on vacation or invalid
        my $LockAction;
        if ( $Ticket{OwnerID} ) {
            my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
                UserID => $Ticket{OwnerID},
            );
            if ( %User && ( $User{OutOfOfficeMessage} || $User{ValidID} ne '1' ) ) {
                $LockAction = 'unlock';
            }
        }

        # set lock if ticket was closed
        if (
            !$LockAction
            && $Lock
            && $State{TypeName} =~ /^close/i && $Ticket{OwnerID} ne '1'
            )
        {

            $LockAction = 'lock';
        }

        if ($LockAction) {
            $TicketObject->TicketLockSet(
                TicketID => $Self->{TicketID},
                Lock     => $LockAction,
                UserID   => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        my $From     = "\"$Self->{UserFullname}\" <$Self->{UserEmail}>";
        my $MimeType = 'text/plain';
        if ( $LayoutObject->{BrowserRichText} ) {
            $MimeType = 'text/html';

            # verify html document
            $GetParam{Body} = $LayoutObject->RichTextDocumentComplete(
                String => $GetParam{Body},
            );
        }

        # set state
        my $NextState = $Config->{StateDefault} || 'open';
        if ( $GetParam{StateID} && $Config->{State} ) {
            my %NextStateData = $StateObject->StateGet( ID => $GetParam{StateID} );
            $NextState = $NextStateData{Name};
        }

        # change state if
        # customer set another state
        # or the ticket is not new
        if ( $Ticket{StateType} !~ /^new/ || $GetParam{StateID} ) {
            $TicketObject->StateSet(
                TicketID => $Self->{TicketID},
                State    => $NextState,
                UserID   => $ConfigObject->Get('CustomerPanelUserID'),
            );

            # set unlock on close state
            if ( $NextState =~ /^close/i ) {
                $TicketObject->TicketLockSet(
                    TicketID => $Self->{TicketID},
                    Lock     => 'unlock',
                    UserID   => $ConfigObject->Get('CustomerPanelUserID'),
                );
            }
        }

        # set priority
        if ( $Config->{Priority} && $GetParam{PriorityID} ) {
            $TicketObject->TicketPrioritySet(
                TicketID   => $Self->{TicketID},
                PriorityID => $GetParam{PriorityID},
                UserID     => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        my $ArticleID = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
            TicketID             => $Self->{TicketID},
            IsVisibleForCustomer => 1,
            SenderType           => $Config->{SenderType},
            From                 => $From,
            Subject              => $GetParam{Subject},
            Body                 => $GetParam{Body},
            MimeType             => $MimeType,
            Charset              => $LayoutObject->{UserCharset},
            UserID               => $ConfigObject->Get('CustomerPanelUserID'),
            OrigHeader           => {
                From    => $From,
                To      => 'System',
                Subject => $GetParam{Subject},
                Body    => $LayoutObject->RichText2Ascii( String => $GetParam{Body} ),
            },
            HistoryType      => $Config->{HistoryType},
            HistoryComment   => $Config->{HistoryComment} || '%%',
            AutoResponseType => ( $ConfigObject->Get('AutoResponseForWebTickets') ) ? 'auto follow up' : '',
        );
        if ( !$ArticleID ) {
            my $Output = $LayoutObject->CustomerHeader(
                Title => Translatable('Error'),
            );
            $Output .= $LayoutObject->CustomerError();
            $Output .= $LayoutObject->CustomerFooter();

            return $Output;
        }

        # get pre loaded attachment
        my @AttachmentData = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $Self->{FormID}
        );

        # get submit attachment
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'file_upload',
        );
        if (%UploadStuff) {
            push @AttachmentData, \%UploadStuff;
        }

        # write attachments
        ATTACHMENT:
        for my $Attachment (@AttachmentData) {

            my $ContentID = $Attachment->{ContentID};
            if (
                $ContentID
                && ( $Attachment->{ContentType} =~ /image/i )
                && ( $Attachment->{Disposition} eq 'inline' )
                )
            {
                my $ContentIDHTMLQuote = $LayoutObject->Ascii2Html(
                    Text => $ContentID,
                );

                # workaround for link encode of rich text editor, see bug#5053
                my $ContentIDLinkEncode = $LayoutObject->LinkEncode($ContentID);
                $GetParam{Body} =~ s/(ContentID=)$ContentIDLinkEncode/$1$ContentID/g;

                # ignore attachment if not linked in body
                if ( $GetParam{Body} !~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i ) {
                    next ATTACHMENT;
                }
            }

            # write existing file to backend
            $ArticleBackendObject->ArticleWriteAttachment(
                %{$Attachment},
                ArticleID => $ArticleID,
                UserID    => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        # set ticket dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Self->{FollowUpDynamicField}->%* ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Ticket';
            next DYNAMICFIELD if !$Visibility{"DynamicField_$DynamicFieldConfig->{Name}"};
            next DYNAMICFIELD if $DynamicFieldConfig->{Readonly};

            # set the value
            my $Success = $BackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $Self->{TicketID},
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        # set article dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Self->{FollowUpDynamicField}->%* ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Article';
            next DYNAMICFIELD if !$Visibility{"DynamicField_$DynamicFieldConfig->{Name}"};
            next DYNAMICFIELD if $DynamicFieldConfig->{Readonly};

            # set the value
            my $Success = $BackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ArticleID,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        # if user clicked submit on the main screen
        # store also chat protocol
        if ( !$GetParam{FromChat} && $GetParam{FromChatID} ) {
            my $ChatObject      = $Kernel::OM->Get('Kernel::System::Chat');
            my @ChatMessageList = $ChatObject->ChatMessageList(
                ChatID => $GetParam{FromChatID},
            );
            my $ChatArticleID;

            if (@ChatMessageList) {
                for my $Message (@ChatMessageList) {
                    $Message->{MessageText} = $LayoutObject->Ascii2Html(
                        Text        => $Message->{MessageText},
                        LinkFeature => 1,
                    );
                }

                my $ArticleChatBackend = $ArticleObject->BackendForChannel( ChannelName => 'Chat' );

                $ChatArticleID = $ArticleChatBackend->ArticleCreate(
                    TicketID             => $Self->{TicketID},
                    SenderType           => $Config->{SenderType},
                    ChatMessageList      => \@ChatMessageList,
                    IsVisibleForCustomer => 1,
                    UserID               => $ConfigObject->Get('CustomerPanelUserID'),
                    HistoryType          => $Config->{HistoryType},
                    HistoryComment       => $Config->{HistoryComment} || '%%',
                );
            }
            if ($ChatArticleID) {
                $ChatObject->ChatDelete(
                    ChatID => $GetParam{FromChatID},
                );
            }
        }

        # remove all form data
        $Kernel::OM->Get('Kernel::System::Web::FormCache')->FormIDRemove( FormID => $Self->{FormID} );

        # delete hidden fields cache
        $Kernel::OM->Get('Kernel::System::Cache')->Delete(
            Type => 'HiddenFields',
            Key  => $Self->{FormID},
        );

        # redirect to zoom view
        return $LayoutObject->Redirect(
            OP => "Action=$NextScreen;TicketID=$Self->{TicketID}",
        );
    }

    $Ticket{TmpCounter}      = 0;
    $Ticket{TicketTimeUnits} = $TicketObject->TicketAccountedTimeGet(
        TicketID => $Ticket{TicketID},
    );

    # set priority from ticket as fallback
    $GetParam{PriorityID} ||= $Ticket{PriorityID};

    # set initial state
    if ( $Config->{State} && $Config->{StatePreset} ) {
        my %NextStates = reverse $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
            %GetParam,
            TicketID       => $Self->{TicketID},
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
            Type           => undef,
        );

        if ( $NextStates{ $Config->{StatePreset} } ) {
            $GetParam{NextStateID} = $NextStates{ $Config->{StatePreset} };
        }
    }
    $GetParam{NextStateID} ||= $GetParam{StateID} || $Ticket{StateID};

    my $CustomerUser = $Self->{UserID};

    # Get values for Ticket fields and use default value for Article fields, if given (this
    # screen generates a new article, then article fields will be always default value or
    # empty at the beginning).
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( values $Self->{FollowUpDynamicField}->%* ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        if ( $DynamicFieldConfig->{ObjectType} eq 'Ticket' ) {

            # Value is stored in the database from Ticket.
            $GetParam{DynamicField}{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $Ticket{ 'DynamicField_' . $DynamicFieldConfig->{Name} };
        }
        elsif ( $DynamicFieldConfig->{ObjectType} eq 'Article' ) {
            $GetParam{DynamicField}{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $DynamicFieldConfig->{Config}->{DefaultValue} || '';
        }
    }

    my $FieldRestrictionsObject = $Kernel::OM->Get('Kernel::System::Ticket::FieldRestrictions');
    my $Autoselect              = $ConfigObject->Get('TicketACL::Autoselect') || undef;

    # gather fields which are supposed to be hidden when autoselected
    my $HideAutoselectedJSON;
    if ($Autoselect) {
        my @HideAutoselected = grep { !ref( $Autoselect->{$_} ) && $Autoselect->{$_} == 2 } keys %{$Autoselect};
        if ( $Autoselect->{DynamicField} ) {
            push @HideAutoselected,
                map { "DynamicField_" . $_ }
                ( grep { $Autoselect->{DynamicField}{$_} == 2 } keys %{ $Autoselect->{DynamicField} } );
        }

        if (@HideAutoselected) {
            my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');
            $HideAutoselectedJSON = $JSONObject->Encode(
                Data => \@HideAutoselected,
            );
        }
    }

    # track changing standard fields
    my $ACLPreselection;
    if ( $ConfigObject->Get('TicketACL::ACLPreselection') ) {

        # get cached preselection rules
        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
        $ACLPreselection = $CacheObject->Get(
            Type => 'TicketACL',
            Key  => 'Preselection',
        );
        if ( !$ACLPreselection ) {
            $ACLPreselection = $FieldRestrictionsObject->SetACLPreselectionCache();
        }
    }

    my %Convergence = (
        StdFields => 0,
        Fields    => 0,
    );
    my %ChangedElements        = ();
    my %ChangedElementsDFStart = ();
    my %ChangedStdFields;

    my $LoopProtection = 100;
    my %StdFieldValues;
    my %DynFieldStates = (
        Visibility => {},
        Fields     => {},
    );

    my $InitialRun = 1;

    until ( $Convergence{Fields} ) {

        # determine standard field input
        until ( $Convergence{StdFields} ) {

            my %NewChangedElements;

            # which standard fields to check - FieldID => GetParamValue (necessary for Dest)
            my %Check = (
                NextStateID => 'NextStateID',
                PriorityID  => 'PriorityID',
            );
            if ( $ACLPreselection && !$InitialRun ) {
                    FIELD:
                    for my $FieldID ( sort keys %Check ) {
                        if ( !$ACLPreselection->{Fields}{$FieldID} ) {
                            next FIELD;
                        }
                    if ( $Autoselect && $Autoselect->{$FieldID} && $ChangedElements{$FieldID} ) {
                        next FIELD;
                    }
                    for my $Element ( sort keys %ChangedElements ) {
                        if (
                            $ACLPreselection->{Rules}{Ticket}{$Element}{$FieldID}
                            || $Self->{InternalDependancy}{$Element}{$FieldID}
                            )
                            {
                                next FIELD;
                            }
                            if ( !$ACLPreselection->{Fields}{$Element} ) {
                                next FIELD;
                            }
                        }

                    # delete unaffected fields
                    delete $Check{$FieldID};
                }
            }

            # for each standard field which has to be checked, run the defined method
            METHOD:
            for my $Field ( @{ $Self->{FieldMethods} } ) {
                next METHOD if !$Check{ $Field->{FieldID} };

                # use $Check{ $Field->{FieldID} } for Dest=>QueueID
                $StdFieldValues{ $Check{ $Field->{FieldID} } } = $Field->{Method}->(
                    $Self,
                    %GetParam,
                    StateID        => $GetParam{NextStateID},
                    CustomerUserID => $CustomerUser || '',
                    TicketID       => $Self->{TicketID},
                );

                # special stuff for QueueID/Dest: Dest is "QueueID||QueueName" => "QueueName";
                if ( $Field->{FieldID} eq 'Dest' ) {
                    TOs:
                    for my $QueueID ( sort keys %{ $StdFieldValues{QueueID} } ) {
                        next TOs if ( $StdFieldValues{QueueID}{$QueueID} eq '-' );
                        $StdFieldValues{Dest}{"$QueueID||$StdFieldValues{QueueID}{ $QueueID }"} = $StdFieldValues{QueueID}{$QueueID};
                    }

                    # check current selection of QueueID (Dest will be done together with the other fields)
                    if ( $GetParam{QueueID} && !$StdFieldValues{Dest}{ $GetParam{Dest} } ) {
                        $GetParam{QueueID} = '';
                    }

                    # autoselect
                    if ( !$GetParam{QueueID} && $Autoselect && $Autoselect->{Dest} ) {
                        $GetParam{QueueID} = $FieldRestrictionsObject->Autoselect(
                            PossibleValues => $StdFieldValues{QueueID},
                        ) || '';
                    }
                }

                # check whether current selected value is still valid for the field
                if (
                    $GetParam{ $Field->{FieldID} }
                    && !$StdFieldValues{ $Field->{FieldID} }{ $GetParam{ $Field->{FieldID} } }
                    )
                {
                    # if not empty the field
                    $GetParam{ $Field->{FieldID} }           = '';
                    $NewChangedElements{ $Field->{FieldID} } = 1;
                    $ChangedStdFields{ $Field->{FieldID} }   = 1;
                }

                # autoselect
                if ( !$GetParam{ $Field->{FieldID} } && $Autoselect && $Autoselect->{ $Field->{FieldID} } ) {
                    $GetParam{ $Field->{FieldID} } = $FieldRestrictionsObject->Autoselect(
                        PossibleValues => $StdFieldValues{ $Field->{FieldID} },
                    ) || '';
                    if ( $GetParam{ $Field->{FieldID} } ) {
                        $NewChangedElements{ $Field->{FieldID} } = 1;
                        $ChangedStdFields{ $Field->{FieldID} }   = 1;
                    }
                }
            }

            if ( !%NewChangedElements ) {
                $Convergence{StdFields} = 1;
            }
            else {
                %ChangedElements = %NewChangedElements;
            }

            %ChangedElementsDFStart = (
                %ChangedElementsDFStart,
                %NewChangedElements,
            );

            if ( $LoopProtection-- < 1 ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Ran into unresolvable loop!",
                );

                # TODO: is returning an empty list reasonable?
                return;
            }
        }

        %ChangedElements        = %ChangedElementsDFStart;
        %ChangedElementsDFStart = ();

        # check dynamic fields
        my %CurFieldStates;
        if ( %ChangedElements || $InitialRun ) {

            # get values and visibility of dynamic fields
            %CurFieldStates = $FieldRestrictionsObject->GetFieldStates(
                TicketObject              => $TicketObject,
                DynamicFields             => $Self->{FollowUpDynamicField},
                DynamicFieldBackendObject => $BackendObject,
                ChangedElements           => \%ChangedElements,               # optional to reduce ACL evaluation
                Action                    => $Self->{Action},
                TicketID                  => $Self->{TicketID},
                FormID                    => $Self->{FormID},
                CustomerUser              => $Self->{UserID},
                GetParam                  => \%GetParam,
                Autoselect                => $Autoselect,
                ACLPreselection           => $ACLPreselection,
                LoopProtection            => \$LoopProtection,
            );

            # combine FieldStates
            $DynFieldStates{Fields} = {
                %{ $DynFieldStates{Fields} },
                %{ $CurFieldStates{Fields} },
            };
            $DynFieldStates{Visibility} = {
                %{ $DynFieldStates{Visibility} },
                %{ $CurFieldStates{Visibility} },
            };

            # store new values
            $GetParam{DynamicField} = {
                %{ $GetParam{DynamicField} },
                %{ $CurFieldStates{NewValues} },
            };
        }

        # if dynamic fields changed, check standard fields again
        if ( %CurFieldStates && IsHashRefWithData( $CurFieldStates{NewValues} ) ) {
            $Convergence{StdFields} = 0;
            %ChangedElements = map { $_ => 1 } keys %{ $CurFieldStates{NewValues} };
        }
        else {
            $Convergence{Fields} = 1;
        }

        $InitialRun = 0;
    }

    # remember dynamic field validation result if erroneous
    my %DynamicFieldPossibleValues = map {
        'DynamicField_' . $_ => defined $DynFieldStates{Fields}{$_}
            ? $DynFieldStates{Fields}{$_}{PossibleValues}
            : undef
    } ( keys $Self->{FollowUpDynamicField}->%* );

    # return output
    return join '',
        $LayoutObject->CustomerHeader( Value => $Ticket{TicketNumber} ),
        $Self->_Mask(
            TicketID   => $Self->{TicketID},
            ArticleBox => \@ArticleBox,
            %Ticket,
            TicketState   => $Ticket{State},
            TicketStateID => $Ticket{StateID},
            %GetParam,
            StateID           => $GetParam{NextStateID},
            TicketStateID     => $GetParam{NextStateID},                      # TODO: check whether this right
            AclAction         => \%AclAction,
            HideAutoselected  => $HideAutoselectedJSON,
            Visibility        => $DynFieldStates{Visibility},
            ActivityErrorHTML => \%ActivityErrorHTML,
            DFPossibleValues  => \%DynamicFieldPossibleValues,
            Reply             => $ZTSMReadOnlyView ? 0 : $AclActionLookup{CustomerTicketZoomReply},
            ZTSMReadOnlyView  => $ZTSMReadOnlyView,
            ZTSMRuntimeActions => $ZTSMRuntimeActions,
            ZTSMStoryLinks     => $ZTSMStoryLinks,
            ZTSMRequestInfoHTML => $ZTSMRequestInfoHTML,
            %{ $ZTSMHeaderOwnership || {} },
        ),
        $LayoutObject->CustomerNavigationBar,
        $LayoutObject->CustomerFooter;
}

sub _ZTSMStoryLinks {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $ParentTicketID = $Ticket->{'DynamicField_ZTicket-Parent'};
    if ( ref $ParentTicketID eq 'ARRAY' ) {
        $ParentTicketID = $ParentTicketID->[0];
    }

    my $StoryRootTicketID = $ParentTicketID || $Ticket->{TicketID};
    return if !$StoryRootTicketID;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my @ChildTicketIDs = $TicketObject->TicketSearch(
        Result => 'ARRAY',
        Limit  => 1000,

        'DynamicField_ZTicket-Parent' => {
            Equals => $StoryRootTicketID,
        },

        UserID => 1,
    );

    my @ChildTickets;
    CHILD:
    for my $ChildTicketID (@ChildTicketIDs) {
        next CHILD if !$ChildTicketID;

        my %ChildTicket = $TicketObject->TicketGet(
            TicketID      => $ChildTicketID,
            DynamicFields => 1,
            UserID        => 1,
        );

        next CHILD if !%ChildTicket;

        push @ChildTickets, {
            TicketID     => $ChildTicketID,
            TicketNumber => $ChildTicket{TicketNumber},
            Title        => $ChildTicket{Title},
            Type         => $ChildTicket{Type},
            State        => $ChildTicket{State},
            IsCurrent    => $ChildTicketID eq $Ticket->{TicketID} ? 1 : 0,
        };
    }

    return if !$ParentTicketID && !@ChildTickets;

    return {
        StoryRootTicketID => $StoryRootTicketID,
        ParentTicketID    => $ParentTicketID,
        ChildTickets      => \@ChildTickets,
    };
}

sub _ZTSMRequestRootTicketGet {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $Type = $Ticket->{Type} || '';
    my %RequestTypeLookup = reverse %{
        $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
            Class => 'ZTSM::RequestType',
            Valid => 1,
        ) || {}
    };

    if ( $Type && $RequestTypeLookup{$Type} ) {
        return {%{$Ticket}};
    }

    my $ParentTicketID = $Ticket->{'DynamicField_ZTicket-Parent'};
    if ( ref $ParentTicketID eq 'ARRAY' ) {
        $ParentTicketID = $ParentTicketID->[0];
    }
    return {%{$Ticket}} if !$ParentTicketID;

    my %ParentTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $ParentTicketID,
        DynamicFields => 1,
        UserID        => 1,
    );

    return %ParentTicket ? \%ParentTicket : {%{$Ticket}};
}

sub _ZTSMValueNormalize {
    my ($Value) = @_;

    if ( ref $Value eq 'ARRAY' ) {
        return $Value->[0] if @{$Value};
        return;
    }

    return $Value;
}

sub _ZTSMExecutionTicketProtected {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $Parent = _ZTSMValueNormalize( $Ticket->{'DynamicField_ZTicket-Parent'} );
    return if !defined $Parent || $Parent eq '';

    my $OwnerGroup = _ZTSMValueNormalize( $Ticket->{'DynamicField_ZTicket-OwnerGroup'} );
    my $Owner      = _ZTSMValueNormalize( $Ticket->{'DynamicField_ZTicket-Owner'} );

    return 1
        if ( defined $OwnerGroup && $OwnerGroup ne '' )
        || ( defined $Owner && $Owner ne '' );

    return;
}

sub _ZTSMRequestDynamicFieldDisplay {
    my ( $Self, %Param ) = @_;

    my $FieldName = $Param{FieldName};
    my $TicketID  = $Param{TicketID};
    return if !$FieldName || !$TicketID;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $FieldName,
    );
    return if !IsHashRefWithData($DynamicFieldConfig);

    my $Value = $BackendObject->ValueGet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $TicketID,
    );
    return if !defined $Value || $Value eq '';

    my $Display = $BackendObject->DisplayValueRender(
        DynamicFieldConfig => $DynamicFieldConfig,
        Value              => $Value,
        ValueMaxChars      => '',
        LayoutObject       => $LayoutObject,
    );

    return if !IsHashRefWithData($Display);

    return {
        Label => $DynamicFieldConfig->{Label} || $FieldName,
        Value => $Display->{Value} || '',
        Title => $Display->{Title} || '',
    };
}

sub _ZTSMCustomerUserDisplayName {
    my ( $Self, %Param ) = @_;

    my $CustomerUser = $Param{CustomerUser} || {};
    return '' if !IsHashRefWithData($CustomerUser);

    my $Firstname = $CustomerUser->{UserFirstname} || $CustomerUser->{UserFirstName} || '';
    my $Lastname  = $CustomerUser->{UserLastname}  || $CustomerUser->{UserLastName}  || '';
    my $Fullname  = join ' ', grep {$_} ( $Firstname, $Lastname );

    return $Fullname || $CustomerUser->{UserLogin} || $CustomerUser->{UserCustomerID} || '';
}

sub _ZTSMRequesterHTML {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if !$Ticket->{CustomerUserID};

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
        User => $Ticket->{CustomerUserID},
    );
    return if !%CustomerUser;

    my $CustomerName = '';
    if ( $CustomerUser{UserCustomerID} ) {
        my %CustomerCompany = $Kernel::OM->Get('Kernel::System::CustomerCompany')->CustomerCompanyGet(
            CustomerID => $CustomerUser{UserCustomerID},
        );
        $CustomerName = $CustomerCompany{CustomerCompanyName} || $CustomerUser{UserCustomerID};
    }

    my $RequesterName = $Self->_ZTSMCustomerUserDisplayName(
        CustomerUser => \%CustomerUser,
    );
    return if !$RequesterName;

    my @RequesterFields = (
        [ 'Name',          $RequesterName ],
        [ 'Phone',         $CustomerUser{UserPhone} || $CustomerUser{UserMobile} || '' ],
        [ 'Email',         $CustomerUser{UserEmail} || '' ],
        [ 'Customer Name', $CustomerName ],
    );

    my $RequesterID = 'ZTSMRequesterInfo' . ( $Ticket->{TicketID} || '' );

    my $HTML = '<button type="button" class="ZTSMRequesterButton" data-ztsm-toggle="'
        . $LayoutObject->Ascii2Html( Text => $RequesterID )
        . '">'
        . $LayoutObject->Ascii2Html( Text => $RequesterName )
        . '</button>';

    $HTML .= '<div id="' . $LayoutObject->Ascii2Html( Text => $RequesterID )
        . '" class="ZTSMRequesterModal ZTSMOverlayBackdrop Hidden" role="dialog" aria-modal="true" hidden>'
        . '<div class="ZTSMOverlayCard"><div class="ZTSMOverlayHead"><h3>Requester Information</h3>'
        . '<button type="button" class="ZTSMOverlayClose" data-ztsm-toggle="'
        . $LayoutObject->Ascii2Html( Text => $RequesterID )
        . '">Hide</button></div><dl class="ZTSMRequesterDetails">';

    FIELD:
    for my $Field (@RequesterFields) {
        next FIELD if !defined $Field->[1] || $Field->[1] eq '';

        $HTML .= '<div><dt>' . $LayoutObject->Ascii2Html( Text => $Field->[0] ) . '</dt><dd>'
            . $LayoutObject->Ascii2Html( Text => $Field->[1] ) . '</dd></div>';
    }

    $HTML .= '</dl></div></div>';

    return {
        Name => $RequesterName,
        HTML => $HTML,
    };
}

sub _ZTSMHeaderOwnership {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $OwnerGroup = _ZTSMValueNormalize( $Ticket->{'DynamicField_ZTicket-OwnerGroup'} );
    my $Owner      = _ZTSMValueNormalize( $Ticket->{'DynamicField_ZTicket-Owner'} );

    $OwnerGroup = $Self->_ZTSMSupportProfileDisplayName(
        SupportProfile => $OwnerGroup,
    ) || $OwnerGroup;

    if ($Owner) {
        my %OwnerUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $Owner,
        );
        if (%OwnerUser) {
            $Owner = $Self->_ZTSMCustomerUserDisplayName(
                CustomerUser => \%OwnerUser,
            ) || $Owner;
        }
    }

    return {
        ZTSMHeaderOwnerGroup => $OwnerGroup || '',
        ZTSMHeaderOwner      => $Owner      || '',
    };
}

sub _ZTSMSupportProfileDisplayName {
    my ( $Self, %Param ) = @_;

    my $SupportProfile = _ZTSMValueNormalize( $Param{SupportProfile} );
    return if !defined $SupportProfile || $SupportProfile eq '';
    return $SupportProfile if $SupportProfile !~ m{\A\d+\z};

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    for my $GetParam (
        { GovernanceObjectID => $SupportProfile },
        { VersionID    => $SupportProfile },
        )
    {
        my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
            %{$GetParam},
            DynamicFields => 0,
            Silent        => 1,
        );

        next if !IsHashRefWithData($GovernanceObject);
        next if ( $GovernanceObject->{Class} || '' ) ne 'SupportProfile';

        return $GovernanceObject->{Name} || $SupportProfile;
    }

    return $SupportProfile;
}

sub _ZTSMRequestAttachmentsHTML {
    my ( $Self, %Param ) = @_;

    my $TicketID = $Param{TicketID};
    return '' if !$TicketID;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my @ArticleList = $ArticleObject->ArticleList(
        TicketID             => $TicketID,
        IsVisibleForCustomer => 1,
        DynamicFields        => 0,
    );

    my @AttachmentHTML;
    ARTICLE:
    for my $ArticleMeta (@ArticleList) {
        next ARTICLE if !IsHashRefWithData($ArticleMeta);

        my $BackendObject = $ArticleObject->BackendForArticle( %{$ArticleMeta} );
        my %AttachmentIndex = $BackendObject->ArticleAttachmentIndex(
            ArticleID        => $ArticleMeta->{ArticleID},
            ExcludePlainText => 1,
            ExcludeHTMLBody  => 1,
            ExcludeInline    => 1,
        );
        next ARTICLE if !%AttachmentIndex;

        FILE:
        for my $FileID ( sort keys %AttachmentIndex ) {
            my $File = $AttachmentIndex{$FileID};
            next FILE if !IsHashRefWithData($File);

            my $Filename = $LayoutObject->Ascii2Html( Text => $File->{Filename} || "Attachment $FileID" );
            my $Size     = $File->{FilesizeRaw} ? ' <span>(' . $LayoutObject->Ascii2Html( Text => $File->{FilesizeRaw} ) . ')</span>' : '';
            my $Link     = $LayoutObject->{Baselink}
                . "Action=CustomerTicketAttachment;TicketID=$TicketID;ArticleID=$ArticleMeta->{ArticleID};FileID=$FileID";

            push @AttachmentHTML, '<a class="ZTSMRequestAttachment" href="' . $LayoutObject->Ascii2Html( Text => $Link ) . '">'
                . '<i class="fa fa-paperclip"></i><span>' . $Filename . '</span>' . $Size . '</a>';
        }
    }

    return '' if !@AttachmentHTML;
    return '<div class="ZTSMRequestAttachments">' . join( '', @AttachmentHTML ) . '</div>';
}

sub _ZTSMRequestDescriptionHTML {
    my ( $Self, %Param ) = @_;

    my $TicketID = $Param{TicketID};
    return '' if !$TicketID;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my @SnapshotLabels;

    if ( IsArrayRefWithData( $Param{ServiceFieldNames} ) ) {
        FIELD:
        for my $FieldName ( @{ $Param{ServiceFieldNames} } ) {
            my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
                Name => $FieldName,
            );
            next FIELD if !IsHashRefWithData($DynamicFieldConfig);

            push @SnapshotLabels, $DynamicFieldConfig->{Label} || $FieldName;
        }
    }

    my @ArticleList = $ArticleObject->ArticleList(
        TicketID             => $TicketID,
        IsVisibleForCustomer => 1,
        DynamicFields        => 0,
    );

    ARTICLE:
    for my $ArticleMeta (@ArticleList) {
        next ARTICLE if !IsHashRefWithData($ArticleMeta);

        my $BackendObject = $ArticleObject->BackendForArticle( %{$ArticleMeta} );
        my %Article = $BackendObject->ArticleGet(
            TicketID  => $TicketID,
            ArticleID => $ArticleMeta->{ArticleID},
        );
        next ARTICLE if !$Article{Body};

        my $Body = $Article{Body};
        if ( $Body =~ m{<[^>]+>} ) {
            $Body = $LayoutObject->RichText2Ascii( String => $Body );
        }

        $Body =~ s{\r\n}{\n}g;
        $Body =~ s{\s*Submitted\s+Details.*\z}{}is;
        for my $Label ( sort { length $b <=> length $a } @SnapshotLabels ) {
            next if !defined $Label || $Label eq '';

            my $QuotedLabel = quotemeta $Label;
            if ( $Body =~ m{(?:\A|\n|\s{2,})\s*$QuotedLabel\s*(?::)?\s*(?:\n|\z)}i ) {
                $Body =~ s{(?:\A|\n|\s{2,})\s*$QuotedLabel\s*(?::)?\s*(?:\n|.*\z).*}{}is;
                last;
            }
        }
        $Body =~ s{\n{3,}}{\n\n}g;
        $Body =~ s{\A\s+|\s+\z}{}g;
        next ARTICLE if !$Body;

        if ( length $Body > 900 ) {
            $Body = substr( $Body, 0, 897 ) . '...';
        }

        return $LayoutObject->Ascii2Html( Text => $Body ) =~ s{\n}{<br />}gr;
    }

    return '';
}

sub _ZTSMRequestServiceFieldNames {
    my ( $Self, %Param ) = @_;

    my $ServiceID = $Param{ServiceID};
    return if !$ServiceID;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $ServiceFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZService-Field',
    );
    return if !IsHashRefWithData($ServiceFieldConfig);
    return if ( $ServiceFieldConfig->{ObjectType} || '' ) ne 'Service';

    my $Value = $BackendObject->ValueGet(
        DynamicFieldConfig => $ServiceFieldConfig,
        ObjectID           => $ServiceID,
        UserID             => 1,
    );
    return if !defined $Value;

    my @RawValues = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);
    my @FieldNames;
    my %Seen;

    VALUE:
    for my $RawValue (@RawValues) {
        next VALUE if !defined $RawValue || $RawValue eq '';

        PART:
        for my $Part ( split m{\s*[|,;\r\n]\s*}, $RawValue ) {
            $Part =~ s{\A\s+|\s+\z}{}g;
            next PART if !$Part;

            my ($FieldName) = split m{\s*:\s*}, $Part, 2;
            $FieldName =~ s{\A\s+|\s+\z}{}g;
            $FieldName =~ s{\ADynamicField_}{};
            next PART if !$FieldName || $Seen{$FieldName}++;

            push @FieldNames, $FieldName;
        }
    }

    return \@FieldNames if @FieldNames;
    return;
}

sub _ZTSMServiceFieldVisibleSkipLookup {
    my ( $Self, %Param ) = @_;

    my $FieldNames = $Param{FieldNames};
    return {} if !IsArrayRefWithData($FieldNames);

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my %Skip = map { $_ => 1 } @{$FieldNames};

    FIELDNAME:
    for my $FieldName ( @{$FieldNames} ) {
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $FieldName,
        );
        next FIELDNAME if !IsHashRefWithData($DynamicFieldConfig);
        next FIELDNAME if ( $DynamicFieldConfig->{FieldType} || '' ) ne 'Set';
        next FIELDNAME if !IsArrayRefWithData( $DynamicFieldConfig->{Config}->{Include} );

        my $CollectIncludedFields;
        $CollectIncludedFields = sub {
            my ($Element) = @_;

            return if !IsHashRefWithData($Element);

            if ( $Element->{DF} ) {
                $Skip{ $Element->{DF} } = 1;
                return;
            }

            return if !IsHashRefWithData( $Element->{Grid} ) || !IsArrayRefWithData( $Element->{Grid}->{Rows} );

            for my $Row ( @{ $Element->{Grid}->{Rows} } ) {
                next if ref $Row ne 'ARRAY';

                $CollectIncludedFields->($_) for @{$Row};
            }

            return;
        };

        $CollectIncludedFields->($_) for @{ $DynamicFieldConfig->{Config}->{Include} };
    }

    return \%Skip;
}

sub _ZTSMRequestInfoHTML {
    my ( $Self, %Param ) = @_;

    my $RootTicket = $Self->_ZTSMRequestRootTicketGet(%Param);
    return '' if !IsHashRefWithData($RootTicket);

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $TicketID = $RootTicket->{TicketID};
    my $TicketHook = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Hook') || 'Ticket';
    my $TicketHookDivider = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::HookDivider') || '#';

    my @SummaryFields = (
        [ 'Ticket ID', $TicketHook . $TicketHookDivider . ( $RootTicket->{TicketNumber} || '' ) ],
        [ 'Type',      $RootTicket->{Type} || '' ],
        [ 'Service',   $RootTicket->{Service} || '' ],
        [ 'Title',     $RootTicket->{Title} || '' ],
        [ 'Created',   $RootTicket->{Created} || $RootTicket->{CreateTime} || '' ],
    );

    my $Requester = $Self->_ZTSMRequesterHTML(
        Ticket => $RootTicket,
    );
    if ( IsHashRefWithData($Requester) ) {
        push @SummaryFields, [ 'Requested By', $Requester->{HTML}, 1 ];
    }

    my $ServiceFieldNames = $Self->_ZTSMRequestServiceFieldNames(
        ServiceID => $RootTicket->{ServiceID},
    );
    my $ServiceDynamicField = $Self->_ZTSMServiceFieldVisibleSkipLookup(
        FieldNames => $ServiceFieldNames,
    );

    my @ContextFields;
    FIELD:
    for my $FieldName (qw(ZTicket-Application ZTicket-Env ZTicket-Location)) {
        next FIELD if $ServiceDynamicField->{$FieldName};

        my $Display = $Self->_ZTSMRequestDynamicFieldDisplay(
            FieldName => $FieldName,
            TicketID  => $TicketID,
        );
        next FIELD if !IsHashRefWithData($Display) || !$Display->{Value};

        push @ContextFields, [ $Display->{Label}, $Display->{Value} ];
    }

    my @DetailFields;
    my %SummaryDynamicField = map { $_ => 1 } qw(
        ZTicket-Parent
    );

    if ( IsArrayRefWithData($ServiceFieldNames) ) {
        SERVICEFIELD:
        for my $FieldName ( @{$ServiceFieldNames} ) {
            next SERVICEFIELD if $SummaryDynamicField{$FieldName};

            my $Display = $Self->_ZTSMRequestDynamicFieldDisplay(
                FieldName => $FieldName,
                TicketID  => $TicketID,
            );
            next SERVICEFIELD if !IsHashRefWithData($Display) || !$Display->{Value};

            push @DetailFields, $Display;
        }
    }
    else {
        my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
            Valid      => 1,
            ObjectType => ['Ticket'],
        ) || [];

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicFieldList} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $SummaryDynamicField{ $DynamicFieldConfig->{Name} };

            my $Display = $Self->_ZTSMRequestDynamicFieldDisplay(
                FieldName => $DynamicFieldConfig->{Name},
                TicketID  => $TicketID,
            );
            next DYNAMICFIELD if !IsHashRefWithData($Display) || !$Display->{Value};

            push @DetailFields, $Display;
        }
    }

    my $HTML = '<section class="ZTSMRequestInfoPanel">'
        . '<div class="ZTSMSectionHead"><span>Request context</span><strong>'
        . $LayoutObject->Ascii2Html( Text => $RootTicket->{State} || '' )
        . '</strong></div>'
        . '<dl class="ZTSMRequestSummary">';

    for my $Field (@SummaryFields) {
        next if !defined $Field->[1] || $Field->[1] eq '';
        $HTML .= '<div><dt>' . $LayoutObject->Ascii2Html( Text => $Field->[0] ) . '</dt><dd>'
            . ( $Field->[2] ? $Field->[1] : $LayoutObject->Ascii2Html( Text => $Field->[1] ) )
            . '</dd></div>';
    }

    $HTML .= '</dl>';

    my $DescriptionHTML = $Self->_ZTSMRequestDescriptionHTML(
        TicketID           => $TicketID,
        ServiceFieldNames => [ keys %{$ServiceDynamicField} ],
    );
    if ($DescriptionHTML) {
        $HTML .= '<div class="ZTSMRequestDescription"><span>Description</span><p>' . $DescriptionHTML . '</p></div>';
    }

    if (@ContextFields) {
        $HTML .= '<div class="ZTSMRequestContext">';
        for my $Field (@ContextFields) {
            $HTML .= '<div><span>' . $LayoutObject->Ascii2Html( Text => $Field->[0] ) . '</span><strong>'
                . $Field->[1] . '</strong></div>';
        }
        $HTML .= '</div>';
    }

    my $AttachmentHTML = $Self->_ZTSMRequestAttachmentsHTML( TicketID => $TicketID );
    if ($AttachmentHTML) {
        $HTML .= '<div class="ZTSMRequestAttachmentBlock"><h4>Attachments</h4>' . $AttachmentHTML . '</div>';
    }

    if (@DetailFields) {
        $HTML .= '<details class="ZTSMRequestMore"><summary><span>Submitted Details</span>'
            . '<span class="ZTSMOverlayButton">Open</span></summary><div class="ZTSMRequestDetailGrid">';
        for my $Field (@DetailFields) {
            $HTML .= '<div class="ZTSMRequestDetailItem"><span>' . $LayoutObject->Ascii2Html( Text => $Field->{Label} ) . '</span><div>'
                . $Field->{Value} . '</div></div>';
        }
        $HTML .= '</div></details>';
    }

    $HTML .= '</section>';

    return $HTML;
}

sub _ZTSMRuntimeActions {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $IPCDelegateAccess = $Self->_ZTSMCurrentCustomerIsIPC();
    my $TicketClosed      = ( $Ticket->{StateType} || '' ) eq 'closed';
    my $FollowUpState     = lc( $Ticket->{State} || '' ) eq 'follow-up';
    my $OverrideState     = lc( $Ticket->{State} || '' ) eq 'override';

    return if $TicketClosed && !$IPCDelegateAccess;
    return if $FollowUpState && !$IPCDelegateAccess;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Config = $ConfigObject->Get('Ticket::Frontend::CustomerTicketZTSMAction') || {};
    my $Actions = $Config->{Actions} || {
        Approve => {
            Label => 'Approve',
            State => 'closed successful',
            Types => ['Approval'],
        },
        Endorse => {
            Label => 'Endorse',
            State => 'closed successful',
            Types => ['Endorsement'],
        },
        Assess => {
            Label => 'Submit Assessment',
            State => 'closed successful',
            Types => ['Assessment'],
        },
        CloseDuplicate => {
            Label => 'Duplicate',
            State => 'closed duplicate',
            Types => ['Assessment'],
        },
        CloseNoAction => {
            Label => 'No Action',
            State => 'closed no action',
            Types => ['Assessment'],
        },
        Reject => {
            Label => 'Reject',
            State => 'closed rejected',
            Types => [ 'Approval', 'Assessment', 'Endorsement' ],
        },
    };
    my $AssessmentFields = $Config->{AssessmentFields} || [
        'ZTicket-TechnicalRisk',
        'ZTicket-BusinessRisk',
        'ZTicket-GovernanceRisk',
    ];

    my $Permission = $Config->{Permission} || 'ztsm_action';
    my $ActionAccess = $TicketObject->TicketCustomerPermission(
        Type     => $Permission,
        TicketID => $Ticket->{TicketID},
        UserID   => $Self->{UserID},
        LogNo    => 1,
    );

    my $FailbackAccess = $TicketObject->TicketCustomerPermission(
        Type     => 'ztsm_failback',
        TicketID => $Ticket->{TicketID},
        UserID   => $Self->{UserID},
        LogNo    => 1,
    );

    my $RequesterCancelAccess = $Self->_ZTSMRequesterCancelAllowed(
        Ticket => $Ticket,
        Config => $Config,
    );

    my $RequesterPauseAccess = $Self->_ZTSMRequesterExecutionPauseAllowed(
        Ticket => $Ticket,
        Config => $Config,
    );

    my $ExternalPartyRequestAccess = $Self->_ZTSMExternalPartyRequestAllowed(
        Ticket => $Ticket,
        Config => $Config,
    );

    return if !$ActionAccess && !$FailbackAccess && !$RequesterCancelAccess && !$RequesterPauseAccess && !$ExternalPartyRequestAccess && !$IPCDelegateAccess;

    my $HoldState = $Ticket->{'DynamicField_ZTicket-HoldState'};
    if ( ref $HoldState eq 'ARRAY' ) {
        $HoldState = $HoldState->[0];
    }

    if ( $HoldState && $RequesterPauseAccess ) {
        return [
            {
                Action          => 'RequesterResume',
                Label           => 'Resume',
                DirectURL       => 1,
                RiskFieldsHTML  => '',
                RemarksRequired => 0,
                InActionMenu    => 1,
            },
        ];
    }

    return if $HoldState;

    my $TicketOwner = $Ticket->{'DynamicField_ZTicket-Owner'};
    if ( ref $TicketOwner eq 'ARRAY' ) {
        $TicketOwner = $TicketOwner->[0];
    }

    my @RuntimeActions;

    if ($IPCDelegateAccess) {
        if ( ( $Ticket->{Type} || '' ) eq 'Approval' && !$OverrideState ) {
            push @RuntimeActions, {
                Action          => 'Override',
                Label           => 'Override',
                DirectURL       => 1,
                RiskFieldsHTML  => '',
                RemarksRequired => 0,
                InActionMenu    => 1,
            };
        }

        push @RuntimeActions, {
            Action          => 'Delegate',
            Label           => 'Delegate',
            RiskFieldsHTML  => $Self->_ZTSMDelegateOverrideHTML( TicketID => $Ticket->{TicketID} ),
            RemarksRequired => 0,
            InActionMenu    => 1,
        };

        return \@RuntimeActions if $TicketClosed || $FollowUpState;
    }

    my $ActionableType;
    my $TaskLikeTicket = $Self->_ZTSMTaskLikeTicket( Ticket => $Ticket );
    ACTION:
    for my $Action ( sort keys %{$Actions} ) {
        my $ActionConfig = $Actions->{$Action};
        next ACTION if !$ActionConfig->{State};

        my %AllowedTypes = map { $_ => 1 } @{ $ActionConfig->{Types} || [] };
        next ACTION if !$AllowedTypes{ $Ticket->{Type} };
        next ACTION if ( $Ticket->{Type} || '' ) eq 'Assessment'
            && ( $Action eq 'CloseDuplicate' || $Action eq 'CloseNoAction' );

        $ActionableType = 1;

        if (
            $IPCDelegateAccess
            && $OverrideState
            && ( $Ticket->{Type} || '' ) eq 'Approval'
            && ( $Action eq 'Approve' || $Action eq 'Reject' )
            )
        {
            push @RuntimeActions, {
                Action         => $Action,
                Label          => ( $ActionConfig->{Label} || $Action ) . ' Override',
                DirectURL      => '',
                RiskFieldsHTML => '',
                InActionMenu   => 1,
            };
            next ACTION;
        }

        next ACTION if !$TicketOwner;
        next ACTION if lc $TicketOwner ne lc $Self->{UserID};

        my %RuntimeAction = (
            Action         => $Action,
            Label          => $ActionConfig->{Label} || $Action,
            DirectURL      => '',
            RiskFieldsHTML => '',
        );

        if ( $Ticket->{Type} eq 'Assessment' && $Action eq 'Assess' ) {
            $RuntimeAction{IsRiskAssessment} = 1;
        }

        push @RuntimeActions, \%RuntimeAction;
    }

    $ActionableType ||= $TaskLikeTicket;

    if (
        $ActionAccess
        && $ActionableType
        && $TicketOwner
        && lc $TicketOwner eq lc $Self->{UserID}
        && $Self->_ZTSMAddRequiredSupportProfileAllowed(
            Ticket => $Ticket,
            Config => $Config,
        )
        )
    {
        push @RuntimeActions, {
            Action          => 'AddRequiredSupportProfile',
            Label           => 'Amend',
            RiskFieldsHTML  => $Self->_ZTSMSupportProfileSelectionHTML(),
            RemarksRequired => 0,
            InActionMenu    => 1,
        };
    }

    if (
        $ActionAccess
        && $TaskLikeTicket
        && $TicketOwner
        && lc $TicketOwner eq lc $Self->{UserID}
        )
    {
        push @RuntimeActions, {
            Action          => 'CompleteTask',
            Label           => 'Complete',
            RiskFieldsHTML  => $Self->_ZTSMTaskCompletionHTML(
                Ticket => $Ticket,
            ),
            RemarksRequired => 0,
        };
    }

    if (
        $ActionAccess
        && ( $Ticket->{Type} || '' ) eq 'Verification'
        && $TicketOwner
        && lc $TicketOwner eq lc $Self->{UserID}
        )
    {
        push @RuntimeActions, {
            Action          => 'CompleteVerification',
            Label           => 'Complete Verification',
            RiskFieldsHTML  => $Self->_ZTSMVerificationCompletionHTML(),
            RemarksRequired => 0,
            InActionMenu    => 1,
        };
    }

    if (
        $ActionAccess
        && $TicketOwner
        && lc $TicketOwner eq lc $Self->{UserID}
        && $Self->_ZTSMFollowUpAllowed(
            Ticket => $Ticket,
            Config => $Config,
        )
        )
    {
        push @RuntimeActions, {
            Action          => 'FollowUp',
            Label           => 'Follow-up',
            RiskFieldsHTML  => '',
            RemarksRequired => 1,
            InActionMenu    => 1,
        };
    }

    if ($ExternalPartyRequestAccess) {
        push @RuntimeActions, {
            Action          => 'CreateExternalPartyRequest',
            Label           => 'Clone',
            RiskFieldsHTML  => $Self->_ZTSMServiceSupportMapSelectionHTML(
                Ticket => $Ticket,
            ),
            RemarksRequired => 0,
            InActionMenu    => 1,
        };
    }

    if (
        !$TicketOwner
        && $ActionableType
        && !$IPCDelegateAccess
        && $Self->_ZTSMCurrentUserCanTakeOwnership(
            Ticket => $Ticket,
        )
        )
    {
        push @RuntimeActions, {
            Action         => 'TakeOwnership',
            Label          => 'Take Ownership',
            RiskFieldsHTML => '',
        } if $ActionAccess;
    }

    if ( $FailbackAccess && $ActionableType ) {
        push @RuntimeActions, {
            Action          => 'Unlock',
            Label           => 'Unlock',
            RiskFieldsHTML  => $Self->_ZTSMUnlockAssignmentHTML(
                Ticket => $Ticket,
            ),
            InActionMenu    => 1,
        };
    }

    if ($RequesterCancelAccess) {
        push @RuntimeActions, {
            Action          => 'CancelRequest',
            Label           => 'Cancel Ticket',
            RiskFieldsHTML  => '',
            RemarksRequired => 1,
            InActionMenu    => 1,
        };
    }

    if ($RequesterPauseAccess) {
        if (
            $Self->_ZTSMRequesterHoldStateName( Config => $Config )
            && !$Self->_ZTSMRequesterHoldStateActive( Ticket => $Ticket, Config => $Config )
            )
        {
            push @RuntimeActions, {
                Action          => 'RequesterHold',
                Label           => 'On Hold',
                DirectURL       => 1,
                RiskFieldsHTML  => '',
                RemarksRequired => 0,
                InActionMenu    => 1,
            };
        }
    }

    return \@RuntimeActions if @RuntimeActions;
    return;
}

sub _ZTSMCurrentCustomerIsIPC {
    my ( $Self, %Param ) = @_;

    return if !$Self->{UserID};

    return 1
        if $Kernel::OM->Get('Kernel::System::CustomerGroup')->PermissionCheck(
        UserID    => $Self->{UserID},
        GroupName => 'IPC',
        Type      => 'rw',
        );

    my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
        UserLogin => $Self->{UserID},
        Silent    => 1,
    );

    return if !$UserID;

    return $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
        UserID    => $UserID,
        GroupName => 'IPC',
        Type      => 'rw',
    );
}

sub _ZTSMDelegateOverrideHTML {
    my ( $Self, %Param ) = @_;

    my $TextAreaCols = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::TextAreaNote') || 80;
    my $TicketID     = $Param{TicketID} || '';

    return '<div class="Row ZTSMRiskField ZTSMDelegateWarning">'
        . '<div class="Field">'
        . '<p>This measure must only be used for critical or time-sensitive activities.</p>'
        . '<p>Use requires written approval from the user, original assignee, or VVIP approver. Upload the approval now or attach it later if the situation is critical.</p>'
        . '<label><input type="checkbox" name="ZTSMDelegateAcknowledge" value="1" class="Validate_Required" /> I acknowledge the delegation override conditions.</label>'
        . '</div>'
        . '<label class="Mandatory">Override conditions: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>'
        . '<div class="Row ZTSMRiskField">'
        . '<div class="Field">'
        . '<input type="hidden" id="ZTSMDelegateTarget" name="ZTSMDelegateTarget" value="" />'
        . '<input type="text" id="ZTSMDelegateTargetSearch" name="ZTSMDelegateTargetSearch" list="ZTSMDelegateTargetList" autocomplete="off" class="Validate_Required" />'
        . '<datalist id="ZTSMDelegateTargetList"></datalist>'
        . '</div>'
        . '<label for="ZTSMDelegateTargetSearch" class="Mandatory">Delegate to: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>'
        . '<div class="Row ZTSMRiskField">'
        . '<div class="Field"><input type="file" id="ZTSMDelegateFileUpload" name="file_upload" /></div>'
        . '<label for="ZTSMDelegateFileUpload">Written approval:</label>'
        . '<div class="Clear"></div>'
        . '</div>'
        . '<script>(function(){'
        . 'var Input=document.getElementById("ZTSMDelegateTargetSearch"),Hidden=document.getElementById("ZTSMDelegateTarget"),List=document.getElementById("ZTSMDelegateTargetList"),Timer,Choices={};'
        . 'if(!Input||!Hidden||!List){return;}'
        . 'function BaseLink(){return window.Core&&Core.Config&&typeof Core.Config.Get==="function"?Core.Config.Get("Baselink"):"' . $Kernel::OM->Get('Kernel::Output::HTML::Layout')->{Baselink} . '";}'
        . 'function Search(){var Term=Input.value||"";if(Term.length<2){return;}var Request=new XMLHttpRequest();Request.open("GET",BaseLink()+"Action=CustomerTicketZTSMAction;TicketID=' . $TicketID . ';Subaction=ZTSMCustomerUserSearch;Term="+encodeURIComponent(Term),true);Request.onreadystatechange=function(){if(Request.readyState!==4||Request.status<200||Request.status>=300){return;}var Payload;try{Payload=JSON.parse(Request.responseText);}catch(Error){return;}Payload=Payload&&Payload.Data?Payload.Data:Payload;Choices={};List.innerHTML="";(Payload||[]).forEach(function(Item){var Option=document.createElement("option");Option.value=Item.Label;Choices[Item.Label]=Item.Value;List.appendChild(Option);});};Request.send();}'
        . 'Input.addEventListener("input",function(){Hidden.value=Choices[Input.value]||"";window.clearTimeout(Timer);Timer=window.setTimeout(Search,250);});'
        . 'Input.addEventListener("change",function(){Hidden.value=Choices[Input.value]||Hidden.value||"";});'
        . '}());</script>';
}

sub _ZTSMAddRequiredSupportProfileAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $Config = $Param{Config} || {};

    return if !IsHashRefWithData($Ticket);
    return if ( $Ticket->{StateType} || '' ) eq 'closed';

    my $ParentTicketID = $Ticket->{'DynamicField_ZTicket-Parent'};
    if ( ref $ParentTicketID eq 'ARRAY' ) {
        $ParentTicketID = $ParentTicketID->[0];
    }
    return if !$ParentTicketID;

    for my $FieldName (qw(ZTicket-BlueBook ZTicket-BlueLevel ZTicket-Chapter)) {
        my $Value = $Ticket->{ 'DynamicField_' . $FieldName };
        if ( ref $Value eq 'ARRAY' ) {
            $Value = $Value->[0];
        }
        return if !defined $Value || $Value eq '';
    }

    my $AllowedTypes = $Config->{AddRequiredSupportProfileTypes} || [
        'Assessment',
        'Endorsement',
        'Approval',
    ];
    my %AllowedType = map { $_ => 1 } @{$AllowedTypes};

    return $AllowedType{ $Ticket->{Type} };
}

sub _ZTSMTaskCompletionHTML {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $OutcomeValues = $Self->_ZTSMTaskOutcomeValues();
    my $SelectedOutcome = $Param{Ticket}->{'DynamicField_ZTicket-Outcome'} || '';
    if ( ref $SelectedOutcome eq 'ARRAY' ) {
        $SelectedOutcome = $SelectedOutcome->[0];
    }

    my $OutcomeSelection = $LayoutObject->BuildSelection(
        Data         => $OutcomeValues,
        Name         => 'ZTicketOutcome',
        SelectedID   => $SelectedOutcome,
        PossibleNone => 1,
        Class        => 'Modernize Validate_Required',
    );

    return '<div class="Row ZTSMRiskField">'
        . '<div class="Field">' . $OutcomeSelection . '</div>'
        . '<label for="ZTicketOutcome" class="Mandatory">Outcome: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>'
        . '<div class="Row ZTSMRiskField">'
        . '<div class="Field"><textarea id="ZTicketResult" name="ZTicketResult" rows="6" cols="'
        . $LayoutObject->Ascii2Html( Text => $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::TextAreaNote') || 80 )
        . '" class="Validate_Required"></textarea></div>'
        . '<label for="ZTicketResult" class="Mandatory">Details: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>'
        . '<div class="Row ZTSMRiskField">'
        . '<div class="Field"><input type="file" id="ZTSMTaskFileUpload" name="file_upload" /></div>'
        . '<label for="ZTSMTaskFileUpload">Attachment:</label>'
        . '<div class="Clear"></div>'
        . '</div>';
}

sub _ZTSMTaskOutcomeValues {
    my ( $Self, %Param ) = @_;

    return {
        0    => 'Successful',
        1    => 'No Action',
        2    => 'Partial Success',
        '-1' => 'Failed',
        '-2' => 'Rollback',
    };
}

sub _ZTSMVerificationCompletionHTML {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $OutcomeSelection = $LayoutObject->BuildSelection(
        Data => {
            0    => 'Successful',
            '-1' => 'Failed',
        },
        Name         => 'ZTicketOutcome',
        PossibleNone => 1,
        Class        => 'Modernize Validate_Required',
    );

    return '<div class="Row ZTSMRiskField">'
        . '<div class="Field">' . $OutcomeSelection . '</div>'
        . '<label for="ZTicketOutcome" class="Mandatory">Result: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>'
        . '<div class="Row ZTSMRiskField">'
        . '<div class="Field"><textarea id="ZTicketResult" name="ZTicketResult" rows="6" cols="'
        . $LayoutObject->Ascii2Html( Text => $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::TextAreaNote') || 80 )
        . '" class="Validate_Required"></textarea></div>'
        . '<label for="ZTicketResult" class="Mandatory">Details: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>'
        . '<div class="Row ZTSMRiskField">'
        . '<div class="Field"><input type="file" id="ZTSMVerificationFileUpload" name="file_upload" class="Validate_Required" /></div>'
        . '<label for="ZTSMVerificationFileUpload" class="Mandatory">Artifact: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>';
}

sub _ZTSMFollowUpAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $Config = $Param{Config} || {};

    return if !IsHashRefWithData($Ticket);
    return if ( $Ticket->{StateType} || '' ) eq 'closed';

    my $AllowedTypes = $Config->{FollowUpTypes} || [
        'Assessment',
        'Endorsement',
        'Approval',
        'Implementation',
        'Verification',
    ];
    my %AllowedType = map { $_ => 1 } @{$AllowedTypes};
    return if !$AllowedType{ $Ticket->{Type} || '' };

    for my $FieldName (qw(ZTicket-Parent ZTicket-BlueBook ZTicket-BlueLevel ZTicket-Chapter)) {
        my $Value = $Ticket->{ 'DynamicField_' . $FieldName };
        if ( ref $Value eq 'ARRAY' ) {
            $Value = $Value->[0];
        }
        return if !defined $Value || $Value eq '';
    }

    return $Self->_ZTSMFollowUpPurpleBookID( Ticket => $Ticket );
}

sub _ZTSMFollowUpPurpleBookID {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $BlueBookID = $Ticket->{'DynamicField_ZTicket-BlueBook'};
    my $BlueLevel  = $Ticket->{'DynamicField_ZTicket-BlueLevel'};
    my $Chapter    = $Ticket->{'DynamicField_ZTicket-Chapter'};

    for my $Value ( \$BlueBookID, \$BlueLevel, \$Chapter ) {
        if ( ref ${$Value} eq 'ARRAY' ) {
            ${$Value} = ${$Value}->[0];
        }
    }

    return if !$BlueBookID || !defined $BlueLevel || $BlueLevel eq '' || !$Chapter;

    my $BlueBook = Kernel::System::ZTSMBlueBookRuntime::BlueBookGet(
        BlueBookID => $BlueBookID,
    );
    my @Records = Kernel::System::ZTSMBlueBookRuntime::RecordsParse(
        BlueBook => $BlueBook,
    );

    RECORD:
    for my $Record (@Records) {
        next RECORD if !$Record || ref $Record ne 'HASH';
        next RECORD if !$Self->_ZTSMBlueLevelMatch(
            BlueLevel => $BlueLevel,
            Record    => $Record,
        );
        next RECORD if !defined $Record->{Chapter} || $Record->{Chapter} ne $Chapter;
        next RECORD if $Record->{Type} && ( $Ticket->{Type} || '' ) && $Record->{Type} ne $Ticket->{Type};

        my $PurpleBookID = $Record->{PurpleBook};
        if ( ref $PurpleBookID eq 'ARRAY' ) {
            $PurpleBookID = $PurpleBookID->[0];
        }

        return $PurpleBookID if $PurpleBookID;
    }

    return;
}

sub _ZTSMBlueLevelMatch {
    my ( $Self, %Param ) = @_;

    my $BlueLevel = $Param{BlueLevel};
    if ( ref $BlueLevel eq 'ARRAY' ) {
        $BlueLevel = $BlueLevel->[0];
    }

    return if !defined $BlueLevel || $BlueLevel eq '';
    return if !$Param{Record} || ref $Param{Record} ne 'HASH';

    for my $RecordBlueLevel ( $Param{Record}->{BlueLevel}, $Param{Record}->{RawBlueLevel} ) {
        if ( ref $RecordBlueLevel eq 'ARRAY' ) {
            $RecordBlueLevel = $RecordBlueLevel->[0];
        }
        next if !defined $RecordBlueLevel || $RecordBlueLevel eq '';
        return 1 if $RecordBlueLevel eq $BlueLevel;
    }

    return;
}

sub _ZTSMExternalPartyRequestAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if ( $Ticket->{StateType} || '' ) eq 'closed';

    my $ParentTicketID = $Ticket->{'DynamicField_ZTicket-Parent'};
    if ( ref $ParentTicketID eq 'ARRAY' ) {
        $ParentTicketID = $ParentTicketID->[0];
    }

    if ($ParentTicketID) {
        my $Owner = $Ticket->{'DynamicField_ZTicket-Owner'};
        if ( ref $Owner eq 'ARRAY' ) {
            $Owner = $Owner->[0];
        }

        return 1 if defined $Owner && $Owner ne '' && lc $Owner eq lc $Self->{UserID};
        return;
    }

    return 1
        if $Ticket->{CustomerUserID}
        && lc $Ticket->{CustomerUserID} eq lc $Self->{UserID};

    return;
}

sub _ZTSMTaskLikeTicket {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    return 1 if ( $Ticket->{Type} || '' ) eq 'Task';
    return 1 if ( $Ticket->{Title} || '' ) =~ m{\ATask\s+-\s+}i;

    return;
}

sub _ZTSMServiceSupportMapSelectionHTML {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ServiceSupportMaps = $Self->_ZTSMServiceSupportMapList(
        Ticket => $Param{Ticket},
    );

    return '<div class="Row ZTSMRiskField">'
        . '<div class="Field">'
        . '<span class="Marker">*</span> No ServiceSupportMap records available.'
        . '</div>'
        . '<label for="TargetServiceSupportMapID">ServiceSupportMap:</label>'
        . '<div class="Clear"></div>'
        . '</div>' if !IsHashRefWithData($ServiceSupportMaps);

    my $Selection = $LayoutObject->BuildSelection(
        Data         => $ServiceSupportMaps,
        Name         => 'TargetServiceSupportMapID',
        SelectedID   => '',
        PossibleNone => 1,
        Class        => 'Modernize Validate_Required',
    );

    return '<div class="Row ZTSMRiskField">'
        . '<div class="Field">' . $Selection . '</div>'
        . '<label for="TargetServiceSupportMapID" class="Mandatory">ServiceSupportMap: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>';
}

sub _ZTSMServiceSupportMapList {
    my ( $Self, %Param ) = @_;

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $Ticket = $Param{Ticket};
    my $SourceServiceID;

    if ( IsHashRefWithData($Ticket) ) {
        my $RootTicket = $Self->_ZTSMRequestRootTicketGet(
            Ticket => $Ticket,
        );
        $SourceServiceID = IsHashRefWithData($RootTicket)
            ? $RootTicket->{ServiceID}
            : $Ticket->{ServiceID};
    }

    my @ServiceSupportMapIDs = $GovernanceObjectObject->GovernanceObjectSearch(
        Classes => ['ServiceSupportMap'],
        Result  => 'ARRAY',
        Limit   => 1000,
        UserID  => 1,
    );

    return if !@ServiceSupportMapIDs;

    my %ServiceSupportMap;
    SERVICESUPPORTMAPID:
    for my $ServiceSupportMapID (@ServiceSupportMapIDs) {
        my $ServiceSupportMapObject = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $ServiceSupportMapID,
            DynamicFields      => 1,
            UserID             => 1,
            Silent             => 1,
        );
        next SERVICESUPPORTMAPID if !IsHashRefWithData($ServiceSupportMapObject);

        if ($SourceServiceID) {
            my $MapServiceID = $Self->_ZTSMServiceIDResolve(
                Service => $ServiceSupportMapObject->{'DynamicField_ZTSMServiceSupportMap-Service'},
            );
            next SERVICESUPPORTMAPID if !$MapServiceID;
            next SERVICESUPPORTMAPID if $MapServiceID ne $SourceServiceID;
        }

        $ServiceSupportMap{$ServiceSupportMapID} = $ServiceSupportMapObject->{Name} || $ServiceSupportMapID;
    }

    return \%ServiceSupportMap if %ServiceSupportMap;
    return;
}

sub _ZTSMServiceIDResolve {
    my ( $Self, %Param ) = @_;

    my $Service = $Param{Service};
    if ( ref $Service eq 'ARRAY' ) {
        $Service = $Service->[0];
    }
    if ( ref $Service eq 'HASH' ) {
        $Service = $Service->{Key} || $Service->{Value} || $Service->{Content};
    }

    return if !defined $Service || $Service eq '';
    return $Service if $Service =~ m{\A\d+\z};

    $Service =~ s{\AService:\s*}{}i;
    $Service =~ s{\s+\z}{};
    return if $Service eq '';

    return $Kernel::OM->Get('Kernel::System::Service')->ServiceLookup(
        Name => $Service,
    );
}

sub _ZTSMSupportProfileSelectionHTML {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $SupportProfiles = $Self->_ZTSMSupportProfileList();

    return '<div class="Row ZTSMRiskField">'
        . '<div class="Field">'
        . '<span class="Marker">*</span> No support profiles available.'
        . '</div>'
        . '<label for="SupportProfile">Support Profile:</label>'
        . '<div class="Clear"></div>'
        . '</div>' if !IsHashRefWithData($SupportProfiles);

    my $Selection = $LayoutObject->BuildSelection(
        Data         => $SupportProfiles,
        Name         => 'SupportProfile',
        SelectedID   => '',
        PossibleNone => 1,
        Class        => 'Modernize Validate_Required',
    );

    return '<div class="Row ZTSMRiskField">'
        . '<div class="Field">' . $Selection . '</div>'
        . '<label for="SupportProfile" class="Mandatory">Support Profile: <span class="Marker">*</span></label>'
        . '<div class="Clear"></div>'
        . '</div>';
}

sub _ZTSMSupportProfileList {
    my ( $Self, %Param ) = @_;

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @SupportProfileIDs = $GovernanceObjectObject->GovernanceObjectSearch(
        Classes => ['SupportProfile'],
        Result  => 'ARRAY',
        Limit   => 1000,
        UserID  => 1,
    );

    return if !@SupportProfileIDs;

    my %SupportProfile;
    SUPPORTPROFILEID:
    for my $SupportProfileID (@SupportProfileIDs) {
        my $SupportProfileObject = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $SupportProfileID,
            DynamicFields      => 0,
            UserID             => 1,
            Silent             => 1,
        );
        next SUPPORTPROFILEID if !IsHashRefWithData($SupportProfileObject);

        $SupportProfile{$SupportProfileID} = $SupportProfileObject->{Name} || $SupportProfileID;
    }

    return \%SupportProfile if %SupportProfile;
    return;
}

sub _ZTSMRequesterExecutionPauseAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};

    return if !IsHashRefWithData($Ticket);
    return if !$Ticket->{CustomerUserID};
    return if lc $Ticket->{CustomerUserID} ne lc $Self->{UserID};
    return if ( $Ticket->{StateType} || '' ) eq 'closed';

    my $ParentTicketID = $Ticket->{'DynamicField_ZTicket-Parent'};
    if ( ref $ParentTicketID eq 'ARRAY' ) {
        $ParentTicketID = $ParentTicketID->[0];
    }

    return if $ParentTicketID;
    return 1;
}

sub _ZTSMRequesterHoldStateName {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config} || {};
    my @StateCandidates;
    push @StateCandidates, $Config->{RequesterHoldState} if $Config->{RequesterHoldState};
    if ( IsArrayRefWithData( $Config->{RequesterHoldStates} ) ) {
        push @StateCandidates, @{ $Config->{RequesterHoldStates} };
    }
    push @StateCandidates, ( 'onhold', 'On Hold', 'on hold' );

    my %Seen;
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    STATE:
    for my $State (@StateCandidates) {
        next STATE if !$State;
        next STATE if $Seen{$State}++;

        my $StateID = $StateObject->StateLookup(
            State => $State,
        );

        return $State if $StateID;
    }

    return;
}

sub _ZTSMRequesterHoldStateActive {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $Config = $Param{Config} || {};

    return if !IsHashRefWithData($Ticket);

    my @StateCandidates;
    push @StateCandidates, $Config->{RequesterHoldState} if $Config->{RequesterHoldState};
    if ( IsArrayRefWithData( $Config->{RequesterHoldStates} ) ) {
        push @StateCandidates, @{ $Config->{RequesterHoldStates} };
    }
    push @StateCandidates, ( 'onhold', 'On Hold', 'on hold' );

    my $CurrentState = $Ticket->{State} || '';
    STATE:
    for my $State (@StateCandidates) {
        next STATE if !$State;
        return 1 if lc $State eq lc $CurrentState;
    }

    return;
}

sub _ZTSMRequesterCancelAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $Config = $Param{Config} || {};

    return if !IsHashRefWithData($Ticket);

    my $ParentTicketID = $Ticket->{'DynamicField_ZTicket-Parent'};
    if ( ref $ParentTicketID eq 'ARRAY' ) {
        $ParentTicketID = $ParentTicketID->[0];
    }

    return if $ParentTicketID;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $CustomerAccess = $TicketObject->TicketCustomerPermission(
        Type     => 'ro',
        TicketID => $Ticket->{TicketID},
        UserID   => $Self->{UserID},
        LogNo    => 1,
    );

    return if !$CustomerAccess;

    my $ParentTypes = $Config->{RequesterCancelTypes} || [
        'ServiceRequest',
        'Change',
        'Incident',
        'Incident:Major',
        'Problem',
    ];

    my %AllowedType = map { $_ => 1 } @{$ParentTypes};

    return $AllowedType{ $Ticket->{Type} };
}

sub _ZTSMUnlockAssignmentHTML {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return '' if !IsHashRefWithData($Ticket);

    my $OwnerGroup = $Ticket->{'DynamicField_ZTicket-OwnerGroup'};
    if ( ref $OwnerGroup eq 'ARRAY' ) {
        $OwnerGroup = $OwnerGroup->[0];
    }

    return '' if !$OwnerGroup;

    my $AssignmentUsers = $Self->_ZTSMSupportAssignmentUsers(
        SupportProfile => $OwnerGroup,
    );

    return '' if !IsHashRefWithData($AssignmentUsers);

    $AssignmentUsers->{''} = '-';

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Selection = $LayoutObject->BuildSelection(
        Data         => $AssignmentUsers,
        Name         => 'OwnerTarget',
        SelectedID   => '',
        PossibleNone => 1,
        Class        => 'Modernize',
    );

    return '<div class="Row">'
        . '<div class="Field">' . $Selection . '</div>'
        . '<label for="OwnerTarget">'
        . $LayoutObject->Ascii2Html( Text => 'Assign to' )
        . ':</label>'
        . '<div class="Clear"></div>'
        . '</div>';
}

sub _ZTSMSupportAssignmentUsers {
    my ( $Self, %Param ) = @_;

    return if !$Param{SupportProfile};

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @AssignmentList = $GovernanceObjectObject->GovernanceObjectSearch(
        Classes => ['SupportAssignment'],
        'DynamicField_ZTSMSupportAssignment-SupportProfile' => {
            Equals => $Param{SupportProfile},
        },
        Result => 'ARRAY',
        Limit  => 1000,
    );

    return if !@AssignmentList;

    my %Users;
    ASSIGNMENT:
    for my $AssignmentID (@AssignmentList) {
        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $AssignmentID,
            DynamicFields => 1,
        );

        next ASSIGNMENT if !$Assignment;

        my $UserAccount = $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'};

        if ( ref $UserAccount eq 'ARRAY' ) {
            $UserAccount = $UserAccount->[0];
        }

        next ASSIGNMENT if !$UserAccount;

        $Users{$UserAccount} = $UserAccount;
    }

    return \%Users;
}

sub _ZTSMCurrentUserCanTakeOwnership {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $OwnerGroup = $Ticket->{'DynamicField_ZTicket-OwnerGroup'};
    if ( ref $OwnerGroup eq 'ARRAY' ) {
        $OwnerGroup = $OwnerGroup->[0];
    }

    return if !$OwnerGroup;

    my $AssignmentUsers = $Self->_ZTSMSupportAssignmentUsers(
        SupportProfile => $OwnerGroup,
    );

    return if !IsHashRefWithData($AssignmentUsers);
    return $AssignmentUsers->{ $Self->{UserID} };
}

sub _ZTSMRuntimeRiskFieldsHTML {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return '' if !IsHashRefWithData($Ticket);
    return '' if !IsArrayRefWithData( $Param{Fields} );

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject               = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $HTML = '';
    FIELD:
    for my $FieldName ( @{ $Param{Fields} } ) {
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $FieldName,
        );

        next FIELD if !IsHashRefWithData($DynamicFieldConfig);
        next FIELD if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

        my $DynamicFieldHTML = $DynamicFieldBackendObject->EditFieldRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Ticket->{ 'DynamicField_' . $FieldName },
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            Mandatory          => 1,
            CustomerInterface  => 1,
            Object             => $Ticket,
        );

        next FIELD if !IsHashRefWithData($DynamicFieldHTML);

        $HTML .= '<div class="Row ZTSMRiskField Row_DynamicField_' . $LayoutObject->Ascii2Html( Text => $FieldName ) . '">'
            . '<div class="Field">' . ( $DynamicFieldHTML->{Field} || '' ) . '</div>'
            . ( $DynamicFieldHTML->{Label} || '' )
            . '<div class="Clear"></div>'
            . '</div>';
    }

    return $HTML;
}

sub _GetNextStates {
    my ( $Self, %Param ) = @_;

    my %NextStates;
    if ( $Param{TicketID} ) {
        %NextStates = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},

            # %Param could contain Ticket Type as only Type, it should not be sent
            Type => undef,
        );
    }
    return \%NextStates;
}

sub _GetPriorities {
    my ( $Self, %Param ) = @_;

    # get priority
    my %Priorities;
    if ( $Param{TicketID} ) {
        %Priorities = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );
    }
    return \%Priorities;
}

sub _Mask {
    my ( $Self, %Param ) = @_;

    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    my %AclActionLookup;
    if ( $Param{AclAction} ) {
        %AclActionLookup = reverse %{ $Param{AclAction} };
    }

    $Param{FormID} = $Self->{FormID};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # show back link
    if ( $Self->{LastScreenOverview} ) {
        $LayoutObject->Block(
            Name => 'Back',
            Data => \%Param,
        );
    }

    if ( IsArrayRefWithData( $Param{ZTSMRuntimeActions} ) ) {
        for my $RuntimeAction ( @{ $Param{ZTSMRuntimeActions} } ) {
            next if $RuntimeAction->{DirectURL};

            $LayoutObject->Block(
                Name => 'ZTSMRuntimeActionDialog',
                Data => {
                    %{$RuntimeAction},
                    TicketID => $Param{TicketID},
                },
            );
        }
    }

    if ( IsHashRefWithData( $Param{ZTSMStoryLinks} ) ) {
        $LayoutObject->Block(
            Name => 'ZTSMStoryLinks',
            Data => $Param{ZTSMStoryLinks},
        );

        if ( $Param{ZTSMStoryLinks}->{ParentTicketID} ) {
            $LayoutObject->Block(
                Name => 'ZTSMOriginalTicketLink',
                Data => $Param{ZTSMStoryLinks},
            );
        }

        if ( IsArrayRefWithData( $Param{ZTSMStoryLinks}->{ChildTickets} ) ) {
            $LayoutObject->Block(
                Name => 'ZTSMChildTicketLinks',
            );

            for my $ChildTicket ( @{ $Param{ZTSMStoryLinks}->{ChildTickets} } ) {
                $LayoutObject->Block(
                    Name => 'ZTSMChildTicketLink',
                    Data => $ChildTicket,
                );
            }
        }
    }

    my $NextActivitiesBlockShown;

    # build article stuff
    my $SelectedArticleID = $ParamObject->GetParam( Param => 'ArticleID' ) || '';
    my @ArticleBox        = @{ $Param{ArticleBox} };

    # prepare errors!
    if ( $Param{Errors} ) {
        for my $KeyError ( sort keys %{ $Param{Errors} } ) {
            $Param{$KeyError} = $LayoutObject->Ascii2Html( Text => $Param{Errors}->{$KeyError} );
        }
    }

    my $ArticleID           = '';
    my $LastCustomerArticle = '';
    if (@ArticleBox) {

        # get last customer article
        my $CounterArray = 0;
        my $LastCustomerArticleID;
        $LastCustomerArticle = $#ArticleBox;

        for my $ArticleTmp (@ArticleBox) {
            my %Article = %{$ArticleTmp};

            # if it is a customer article
            if ( $Article{SenderType} eq 'customer' ) {
                $LastCustomerArticleID = $Article{ArticleID};
                $LastCustomerArticle   = $CounterArray;
            }
            $CounterArray++;
            if ( ($SelectedArticleID) && ( $SelectedArticleID eq $Article{ArticleID} ) ) {
                $ArticleID = $Article{ArticleID};
            }
        }

        # try to use the latest non internal agent article
        if ( !$ArticleID ) {
            $ArticleID         = $ArticleBox[-1]->{ArticleID};
            $SelectedArticleID = $ArticleID;
        }

        # try to use the latest customer article
        if ( !$ArticleID && $LastCustomerArticleID ) {
            $ArticleID         = $LastCustomerArticleID;
            $SelectedArticleID = $ArticleID;
        }
    }

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # set display options
    $Param{Hook} = $ConfigObject->Get('Ticket::Hook') || 'Ticket#';

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    # ticket accounted time
    if ( $Config->{ZoomTimeDisplay} ) {
        $LayoutObject->Block(
            Name => 'TicketTimeUnits',
            Data => \%Param,
        );
    }

    # ticket priority flag
    if ( $Config->{AttributesView}->{Priority} ) {
        $LayoutObject->Block(
            Name => 'PriorityFlag',
            Data => \%Param,
        );
    }

    # render ticket info head depending on sysconfig setting
    if ( $Config->{TicketInfoDisplayType} eq 'Header' ) {
        $LayoutObject->Block(
            Name => 'HeaderInfo',
        );
    }

    # ticket type
    if ( $ConfigObject->Get('Ticket::Type') && $Config->{AttributesView}->{Type} ) {

        my %Type = $Kernel::OM->Get('Kernel::System::Type')->TypeGet(
            Name => $Param{Type},
        );

        $LayoutObject->Block(
            Name => 'Type',
            Data => {
                Valid => $Type{ValidID},
                %Param,
            }
        );
    }

    # ticket service
    if (
        $Param{Service}
        &&
        $ConfigObject->Get('Ticket::Service')
        && $Config->{AttributesView}->{Service}
        )
    {
        $LayoutObject->Block(
            Name => 'Service',
            Data => \%Param,
        );
        if (
            $Param{SLA}
            && $ConfigObject->Get('Ticket::Service')
            && $Config->{AttributesView}->{SLA}
            )
        {
            $LayoutObject->Block(
                Name => 'SLA',
                Data => \%Param,
            );
        }
    }

    # ticket state
    if ( $Config->{AttributesView}->{State} ) {
        $LayoutObject->Block(
            Name => 'State',
            Data => \%Param,
        );
    }

    # ticket priority
    if ( $Config->{AttributesView}->{Priority} ) {
        $LayoutObject->Block(
            Name => 'Priority',
            Data => \%Param,
        );
    }

    # ticket queue
    if ( $Config->{AttributesView}->{Queue} ) {
        $LayoutObject->Block(
            Name => 'Queue',
            Data => \%Param,
        );
    }

    my $AgentUserObject = $Kernel::OM->Get('Kernel::System::User');

    # ticket owner
    if ( $Config->{AttributesView}->{Owner} ) {
        my $OwnerName = $AgentUserObject->UserName(
            UserID => $Param{OwnerID},
        );
        $LayoutObject->Block(
            Name => 'Owner',
            Data => { OwnerName => $OwnerName },
        );
    }

    # ticket responsible
    if (
        $ConfigObject->Get('Ticket::Responsible')
        &&
        $Config->{AttributesView}->{Responsible}
        )
    {
        my $ResponsibleName = $AgentUserObject->UserName(
            UserID => $Param{ResponsibleID},
        );
        $LayoutObject->Block(
            Name => 'Responsible',
            Data => {
                ResponsibleName => $ResponsibleName,
            },
        );
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # check if ticket is normal or process ticket
    my $IsProcessTicket = $TicketObject->TicketCheckForProcessType(
        'TicketID' => $Self->{TicketID},
    );

    # show process widget  and activity dialogs on process tickets
    if ( $IsProcessTicket && !$Param{ZTSMReadOnlyView} ) {

        # get the DF where the ProcessEntityID is stored
        my $ProcessEntityIDField = 'DynamicField_'
            . $ConfigObject->Get("Process::DynamicFieldProcessManagementProcessID");

        # get the DF where the AtivityEntityID is stored
        my $ActivityEntityIDField = 'DynamicField_'
            . $ConfigObject->Get("Process::DynamicFieldProcessManagementActivityID");

        # create additional objects for process management
        my $ActivityObject       = $Kernel::OM->Get('Kernel::System::ProcessManagement::Activity');
        my $ActivityDialogObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::ActivityDialog');
        my $ProcessObject        = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');
        my $ProcessData          = $ProcessObject->ProcessGet(
            ProcessEntityID => $Param{$ProcessEntityIDField},
        );

        my $ActivityData = $ActivityObject->ActivityGet(
            Interface        => 'CustomerInterface',
            ActivityEntityID => $Param{$ActivityEntityIDField},
        );

        # output process information in the sidebar
        $LayoutObject->Block(
            Name => 'ProcessData',
            Data => {
                Process  => $ProcessData->{Name}  || '',
                Activity => $ActivityData->{Name} || '',
            },
        );

        # output the process widget on the main screen
        $LayoutObject->Block(
            Name => 'ProcessWidget',
            Data => {
                WidgetTitle => $Param{WidgetTitle},
            },
        );

        # get next activity dialogs
        my $NextActivityDialogs;
        if ( $Param{$ActivityEntityIDField} ) {
            $NextActivityDialogs = $ActivityData;
        }

        if ( IsHashRefWithData($NextActivityDialogs) ) {

            # we don't need the whole Activity config,
            # just the Activity Dialogs of the current Activity
            if ( IsHashRefWithData( $NextActivityDialogs->{ActivityDialog} ) ) {
                %{$NextActivityDialogs} = %{ $NextActivityDialogs->{ActivityDialog} };
            }
            else {
                $NextActivityDialogs = {};
            }

            if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::Modules::CustomerTicketProcess") ) {
                return $LayoutObject->FatalError(
                    Message => Translatable('Could not load process module.'),
                );
            }
            my $ProcessModule = ('Kernel::Modules::CustomerTicketProcess')->new(
                %{$Self},
                Action    => 'CustomerTicketProcess',
                Subaction => 'DisplayActivityDialog',
                ModuleReg => $ConfigObject->Get('CustomerFrontend::Module')->{'CustomerTicketProcess'},
            );

            # we have to check if the current user has the needed permissions to view the
            # different activity dialogs, so we loop over every activity dialog and check if there
            # is a permission configured. If there is a permission configured we check this
            # and display/hide the activity dialog link
            my %PermissionRights;
            my %PermissionActivityDialogList;
            ACTIVITYDIALOGPERMISSION:
            for my $Index ( sort { $a <=> $b } keys %{$NextActivityDialogs} ) {
                my $CurrentActivityDialogEntityID = $NextActivityDialogs->{$Index};
                my $CurrentActivityDialog         = $ActivityDialogObject->ActivityDialogGet(
                    ActivityDialogEntityID => $CurrentActivityDialogEntityID,
                    Interface              => 'CustomerInterface',
                );

                # create an interface lookup-list
                my %InterfaceLookup = map { $_ => 1 } @{ $CurrentActivityDialog->{Interface} };

                next ACTIVITYDIALOGPERMISSION if !$InterfaceLookup{CustomerInterface};

                if ( $CurrentActivityDialog->{Permission} ) {

                    # performance-boost/cache
                    if ( !defined $PermissionRights{ $CurrentActivityDialog->{Permission} } ) {
                        $PermissionRights{ $CurrentActivityDialog->{Permission} } = $TicketObject->TicketCustomerPermission(
                            Type     => $CurrentActivityDialog->{Permission},
                            TicketID => $Param{TicketID},
                            UserID   => $Self->{UserID},
                        );
                    }

                    if ( !$PermissionRights{ $CurrentActivityDialog->{Permission} } ) {
                        next ACTIVITYDIALOGPERMISSION;
                    }
                }

                $PermissionActivityDialogList{$Index} = $CurrentActivityDialogEntityID;
            }

            # reduce next activity dialogs to the ones that have permissions
            $NextActivityDialogs = \%PermissionActivityDialogList;

            # get ACL restrictions
            my $ACL = $TicketObject->TicketAcl(
                Data           => \%PermissionActivityDialogList,
                TicketID       => $Param{TicketID},
                Action         => $Self->{Action},
                ReturnType     => 'ActivityDialog',
                ReturnSubType  => '-',
                CustomerUserID => $Self->{UserID},
            );

            if ($ACL) {
                %{$NextActivityDialogs} = $TicketObject->TicketAclData();
            }

            $LayoutObject->Block(
                Name => 'NextActivities',
            );
            $NextActivitiesBlockShown = 1;

            $Param{ActivityErrorHTML} //= {};

            for my $NextActivityDialogKey ( sort { $a <=> $b } keys %{$NextActivityDialogs} ) {
                my $ActivityDialogData = $ActivityDialogObject->ActivityDialogGet(
                    ActivityDialogEntityID => $NextActivityDialogs->{$NextActivityDialogKey},
                    Interface              => 'CustomerInterface',
                );

                # decide whether to output direct submit or link to new window
                my $DirectSubmit = $ActivityDialogData->{DirectSubmit};
                if ( any { $ActivityDialogData->{Fields}{$_}{Display} } keys $ActivityDialogData->{Fields}->%* ) {
                    $DirectSubmit = 0;
                }

                if ($DirectSubmit) {
                    $LayoutObject->Block(
                        Name => 'ActivityDialogDirectSubmit',
                        Data => {
                            ActivityDialogEntityID
                                => $NextActivityDialogs->{$NextActivityDialogKey},
                            Name            => $ActivityDialogData->{SubmitButtonText} || $ActivityDialogData->{Name},
                            ProcessEntityID => $Param{$ProcessEntityIDField},
                            TicketID        => $Param{TicketID},
                        },
                    );
                }
                else {
                    $LayoutObject->Block(
                        Name => 'ActivityDialog',
                        Data => {
                            ActivityDialogEntityID
                                => $NextActivityDialogs->{$NextActivityDialogKey},
                            Name            => $ActivityDialogData->{Name},
                            ProcessEntityID => $Param{$ProcessEntityIDField},
                            TicketID        => $Param{TicketID},
                        },
                    );
                }

                my $ActivityHTML = $Param{ActivityErrorHTML}{ $NextActivityDialogs->{$NextActivityDialogKey} } // $ProcessModule->Run(
                    ActivityDialogEntityID => $NextActivityDialogs->{$NextActivityDialogKey},
                    ProcessEntityID        => $Param{$ProcessEntityIDField},
                );
                $LayoutObject->Block(
                    Name => 'ProcessActivity',
                    Data => {
                        ActivityHTML           => $ActivityHTML,
                        ActivityDialogEntityID => $NextActivityDialogs->{$NextActivityDialogKey},
                    },
                );
            }

            if ( !IsHashRefWithData($NextActivityDialogs) ) {
                $LayoutObject->Block(
                    Name => 'NoActivityDialog',
                    Data => {},
                );
            }
        }
    }

    if ( IsArrayRefWithData( $Param{ZTSMRuntimeActions} ) ) {
        if ( !$NextActivitiesBlockShown ) {
            $LayoutObject->Block(
                Name => 'NextActivities',
            );
        }

        for my $RuntimeAction ( @{ $Param{ZTSMRuntimeActions} } ) {
            if ( $RuntimeAction->{InActionMenu} ) {
                $LayoutObject->Block(
                    Name => 'ZTSMRuntimeActionMenuItem',
                    Data => {
                        %{$RuntimeAction},
                        TicketID => $Param{TicketID},
                    },
                );
                next;
            }

            $LayoutObject->Block(
                Name => 'ZTSMRuntimeAction',
                Data => {
                    %{$RuntimeAction},
                    TicketID => $Param{TicketID},
                },
            );
        }
    }

    # get dynamic field config for frontend module
    my $DynamicFieldFilter = $Config->{DynamicField};

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # gather categories to be shown
    my %Categories;
    my $CategoryConfig = $ConfigObject->Get("Ticket::Frontend::CustomerTicketCategories");

    # standard ticket categories
    CAT:
    for my $CatName (qw/Priority Type Queue Service State Owner/) {
        next CAT if !$Param{$CatName};
        if ( $CategoryConfig->{$CatName} ) {
            my $Conf = $CategoryConfig->{$CatName};
            my $Text = $Conf->{Text} // $Param{$CatName};

            $Conf->{ColorSelection} //= {};
            my $Color = $Conf->{ColorSelection}{ $Param{$CatName} } // $Conf->{ColorDefault};

            push @{ $Categories{ $Conf->{Order} } }, {
                Text   => $Text,
                Color  => $Color,
                Value  => $Param{$CatName},
                Config => $Conf,
            };
        }
    }

    my %DynamicFieldCategories = $CategoryConfig->{DynamicField}
        ?
        map { $CategoryConfig->{DynamicField}{$_}{DynamicField} => $_ } keys %{ $CategoryConfig->{DynamicField} }
        : ();

    # get the dynamic fields for ticket object
    my $DynamicField = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => ['Ticket'],
        FieldFilter => $DynamicFieldFilter || {},
    );

    # cycle trough the activated Dynamic Fields for ticket object
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # skip the dynamic field if is not designed for customer interface
        my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsCustomerInterfaceCapable',
        );
        next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{TicketID},
        );

        next DYNAMICFIELD if !defined $Value;
        next DYNAMICFIELD if $Value eq "";

        # get print string for this dynamic field
        my $ValueStrg = $BackendObject->DisplayValueRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            ValueMaxChars      => 25,
            LayoutObject       => $LayoutObject,
        );

        my $Label = $DynamicFieldConfig->{Label};

        $LayoutObject->Block(
            Name => 'TicketDynamicField',
            Data => {
                Label => $Label,
            },
        );

        if ( $DynamicFieldConfig->{Config}->{Link} ) {
            $LayoutObject->Block(
                Name => 'TicketDynamicFieldLink',
                Data => {
                    Value                       => $ValueStrg->{Value},
                    Title                       => $ValueStrg->{Title},
                    Link                        => $DynamicFieldConfig->{Config}->{Link},
                    LinkPreview                 => $DynamicFieldConfig->{Config}->{LinkPreview},
                    $DynamicFieldConfig->{Name} => $ValueStrg->{Value},
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'TicketDynamicFieldPlain',
                Data => {
                    Value => $ValueStrg->{Value},
                    Title => $ValueStrg->{Title},
                },
            );
        }

        # example of dynamic fields order customization
        $LayoutObject->Block(
            Name => 'TicketDynamicField_' . $DynamicFieldConfig->{Name},
            Data => {
                Label => $Label,
                Value => $ValueStrg->{Value},
                Title => $ValueStrg->{Title},
            },
        );

        # build %Categories as $Categories{<Order>} = [ {Text => '', Color => ''}, ... ]
        if ( $DynamicFieldCategories{ $DynamicFieldConfig->{Name} } ) {
            my $Conf = $CategoryConfig->{DynamicField}{ $DynamicFieldCategories{ $DynamicFieldConfig->{Name} } };
            my $Text = $Conf->{Text} // $ValueStrg->{Value};

            $Conf->{ColorSelection} //= {};
            my $Color = $Conf->{ColorSelection}{ $ValueStrg->{Value} } // $Conf->{ColorDefault};

            push @{ $Categories{ $Conf->{Order} } }, {
                Text   => $Text,
                Color  => $Color,
                Value  => $ValueStrg->{Value},
                Config => $Conf,
            };
        }
    }

    # prepare categories for header and info block
    if (%Categories) {
        $LayoutObject->Block( Name => 'InfoCategories' );
        for my $Order ( sort { $a <=> $b } keys %Categories ) {
            for my $Category ( @{ $Categories{$Order} } ) {
                $LayoutObject->Block(
                    Name => 'Categories',
                    Data => $Category,
                );
                $LayoutObject->Block(
                    Name => 'CategoriesI',
                    Data => $Category,
                );
            }
        }
    }

    # check is chat available and is starting a chat from ticket zoom available
    my $ChatConfig = $ConfigObject->Get('Ticket::Customer::StartChatFromTicket');
    if (
        $ChatConfig->{Allowed}
        && $ConfigObject->Get('ChatEngine::Active')
        )
    {
        # get all queues to tickets relations
        my %QueueChatChannelRelations = $Kernel::OM->Get('Kernel::System::ChatChannel')->ChatChannelQueuesGet(
            CustomerInterface => 1,
        );

        # if a support chat channel is set for this queue
        if ( $QueueChatChannelRelations{ $Param{QueueID} } ) {

            # check is starting a chat from ticket zoom allowed to all user or only to ticket customer user_agent
            if (
                !$ChatConfig->{Permissions}
                || ( $Param{CustomerUserID} eq $Self->{UserID} )
                )
            {
                # add chat channelID to Param
                $Param{ChatChannelID} = $QueueChatChannelRelations{ $Param{QueueID} };

                if ( $Param{ChatChannelID} ) {

                    # check should chat be available only if there are available agents in this chat channelID
                    if ( !$ChatConfig->{AllowChatOnlyIfAgentsAvailable} ) {

                        # show start a chat icon
                        $LayoutObject->Block(
                            Name => 'Chat',
                            Data => {
                                %Param,
                            },
                        );
                    }
                    else {
                        # Get channels data
                        my %ChatChannelData = $Kernel::OM->Get('Kernel::System::ChatChannel')->ChatChannelGet(
                            ChatChannelID => $Param{ChatChannelID},
                        );

                        # Get all online users
                        my $AvailabilityCheck = $Kernel::OM->Get('Kernel::Config')->Get("ChatEngine::CustomerFrontend::AvailabilityCheck")
                            || 0;
                        my %AvailableUsers;
                        if ($AvailabilityCheck) {
                            %AvailableUsers = $Kernel::OM->Get('Kernel::System::Chat')->AvailableUsersGet(
                                Key => 'ExternalChannels',
                            );
                        }

                        # Rename hash key: ChatChannelID => Key
                        $ChatChannelData{Key} = delete $ChatChannelData{ChatChannelID};

                        if ($AvailabilityCheck) {
                            my $UserAvailable = 0;

                            AVAILABLE_USER:
                            for my $AvailableUser ( sort keys %AvailableUsers ) {
                                if ( any {/^$ChatChannelData{Key}$/} @{ $AvailableUsers{$AvailableUser} } ) {
                                    $UserAvailable = 1;
                                    last AVAILABLE_USER;
                                }
                            }

                            if ($UserAvailable) {
                                $LayoutObject->Block(
                                    Name => 'Chat',
                                    Data => {
                                        %Param,
                                    },
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    # print option
    if (
        $ConfigObject->Get('CustomerFrontend::Module')->{CustomerTicketPrint}
        && $AclActionLookup{CustomerTicketPrint}
        )
    {
        $LayoutObject->Block(
            Name => 'Print',
            Data => \%Param,
        );
    }

    # get params
    my $ZoomExpand = $ParamObject->GetParam( Param => 'ZoomExpand' );
    if ( !defined $ZoomExpand ) {
        $ZoomExpand = $ConfigObject->Get('Ticket::Frontend::CustomerTicketZoom')->{CustomerZoomExpand} || '';
    }

    # Expand option
    my $ExpandOption = ( $ZoomExpand ? 'One'              : 'All' );
    my $ExpandText   = ( $ZoomExpand ? 'Show one article' : 'Show all articles' );
    $LayoutObject->Block(
        Name => 'Expand',
        Data => {
            ZoomExpand   => !$ZoomExpand,
            ExpandOption => $ExpandOption,
            ExpandText   => $ExpandText,
            %Param,
        },
    );

    my %Ticket = $TicketObject->TicketGet(
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID},
    );

    my $ShownArticles;
    my $LastSenderType = '';
    my $ArticleHTML    = '';

    for my $ArticleTmp ( reverse @ArticleBox ) {
        my %Article = $ArticleTmp->%*;

        # check if article should be expanded (visible)
        if ( $SelectedArticleID eq $Article{ArticleID} || $ZoomExpand ) {
            $Article{Class} = 'Visible';
            $ShownArticles++;
        }

        # Calculate difference between article create time and now in seconds.
        my $ArticleCreateTimeObject = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Article{CreateTime},
            },
        );
        my $Delta = $ArticleCreateTimeObject->Delta(
            DateTimeObject => $Kernel::OM->Create('Kernel::System::DateTime'),
        );

        # do some html quoting
        $Article{Age} = $LayoutObject->CustomerAge(
            Age   => $Delta->{AbsoluteSeconds},
            Space => ' ',
        );

        $Article{Subject} = $TicketObject->TicketSubjectClean(
            TicketNumber => $Ticket{TicketNumber},
            Subject      => $Article{Subject} || '',
            Size         => 150,
        );

        if ( ( $Article{Subject} || '' ) =~ m{\[VVIP Delegate\]} ) {
            $Article{Class} = join ' ', grep {$_} $Article{Class}, 'ZTSMDelegateAudit';
        }

        $LastSenderType = $Article{SenderType};

        if ( !defined $Self->{ShowBrowserLinkMessage} ) {
            my %UserPreferences = $Kernel::OM->Get('Kernel::System::CustomerUser')->GetPreferences(
                UserID => $Self->{UserID},
            );

            if ( $UserPreferences{UserCustomerDoNotShowBrowserLinkMessage} ) {
                $Self->{ShowBrowserLinkMessage} = 0;
            }
            else {
                $Self->{ShowBrowserLinkMessage} = 1;
            }
        }

        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForArticle(
            TicketID  => $Param{TicketID},
            ArticleID => $Article{ArticleID},
        );

        my $ChannelName = $ArticleBackendObject->ChannelNameGet();

        $ArticleHTML .= $Kernel::OM->Get("Kernel::Output::HTML::TicketZoom::Customer::$ChannelName")->ArticleRender(
            TicketID               => $Param{TicketID},
            ArticleID              => $Article{ArticleID},
            Class                  => $Article{Class},
            UserID                 => $Self->{UserID},
            ShowBrowserLinkMessage => $Self->{ShowBrowserLinkMessage},
            ArticleExpanded        => $SelectedArticleID eq $Article{ArticleID} || $ZoomExpand,
            ArticleAge             => $Article{Age},
        );
    }

    # TODO: Refactor
    # if there are no viewable articles show NoArticles message
    if ( !@ArticleBox ) {
        $Param{NoArticles} = 1;
    }

    my %Article;
    if (@ArticleBox) {

        my $ArticleOB = {};
        if ($LastCustomerArticle) {
            $ArticleOB = $ArticleBox[$LastCustomerArticle];
        }

        %Article = $ArticleOB->%*;

        # if no customer articles found use ticket values
        if ( !IsHashRefWithData( \%Article ) ) {
            %Article = %Param;
            if ( !$Article{StateID} ) {
                $Article{StateID} = $Param{TicketStateID};
            }
        }

        for my $ArticleTmp (@ArticleBox) {
            my %ArticleTmp1 = $ArticleTmp->%*;
            if ( $ArticleID eq $ArticleTmp1{ArticleID} ) {
                %Article = %ArticleTmp1;
            }
        }
    }

    # fallback to ticket info if there is no article
    if ( !IsHashRefWithData( \%Article ) ) {
        %Article = %Param;
        if ( !$Article{StateID} ) {
            $Article{StateID} = $Param{TicketStateID};
        }
    }

    # check follow up permissions
    my $FollowUpPossible = $Kernel::OM->Get('Kernel::System::Queue')->GetFollowUpOption(
        QueueID => $Ticket{QueueID},
    );
    my %State = $Kernel::OM->Get('Kernel::System::State')->StateGet(
        ID => $Ticket{StateID},
    );
    if (
        !$Param{ZTSMReadOnlyView}
        && $TicketObject->TicketCustomerPermission(
            Type     => 'update',
            TicketID => $Self->{TicketID},
            UserID   => $Self->{UserID},
        )
        && (
            ( $FollowUpPossible !~ /(new ticket|reject)/i && $State{TypeName} =~ /^close/i )
            || $State{TypeName} !~ /^close|merged/i
        )
        )
    {

        if ( $Param{HideAutoselected} ) {

            # add Autoselect JS
            $LayoutObject->AddJSOnDocumentComplete(
                Code => "Core.Form.InitHideAutoselected({ FieldIDs: $Param{HideAutoselected} });",
            );
        }

        # add information whether activated activity dialog button should be hidden
        $LayoutObject->AddJSData(
            Key   => 'HideActivatedActivityDialogButton',
            Value => $Config->{'HideActivatedActivityDialogButton'} // 0,
        );

        # check subject
        if ( !$Param{Subject} ) {
            $Param{Subject} = "Re: " . ( $Param{Title} // '' );
        }
        if ( $Param{Reply} ) {
            $LayoutObject->Block(
                Name => 'ReplyButton',
            );
        }
        $LayoutObject->Block(
            Name => 'FollowUp',
            Data => \%Param,
        );

        # add rich text editor
        if ( $LayoutObject->{BrowserRichText} ) {

            # use height/width defined for this screen
            $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
            $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

            # set up customer rich text editor
            $LayoutObject->CustomerSetRichTextParameters(
                Data => \%Param,
            );
        }

        # build next states string
        if ( $Config->{State} ) {
            my $NextStates = $Self->_GetNextStates(
                %Param,
                TicketID => $Self->{TicketID},
            );
            my %StateSelected;
            if ( $Param{StateID} ) {
                $StateSelected{SelectedID} = $Param{StateID};
            }
            else {
                $StateSelected{SelectedValue} = $Config->{StateDefault};
            }
            $Param{NextStatesStrg} = $LayoutObject->BuildSelection(
                Data => $NextStates,
                Name => 'StateID',
                %StateSelected,
                Class       => 'Modernize FormUpdate',
                Translation => 1,
            );
            $LayoutObject->Block(
                Name => 'FollowUpState',
                Data => \%Param,
            );
        }

        # get priority
        if ( $Config->{Priority} ) {
            my $Priorities = $Self->_GetPriorities(
                %Param,
                TicketID => $Self->{TicketID},
            );
            my %PrioritySelected;
            if ( $Param{PriorityID} ) {
                $PrioritySelected{SelectedID} = $Param{PriorityID};
            }
            else {
                $PrioritySelected{SelectedValue} = $Config->{PriorityDefault}
                    || '3 normal';
            }
            $Param{PriorityStrg} = $LayoutObject->BuildSelection(
                Data => $Priorities,
                Name => 'PriorityID',
                %PrioritySelected,
                Class => 'Modernize FormUpdate',
            );
            $LayoutObject->Block(
                Name => 'FollowUpPriority',
                Data => \%Param,
            );
        }

        my $SeparateDynamicFields = $ConfigObject->Get('Ticket::CustomerFrontend::SeparateDynamicFields');

        # render dynamic fields
        if ( $Self->{FollowUpDynamicField}->%* ) {

            # grep dynamic field values
            my %DynamicFieldValues = map { $_ => $Param{$_} } grep {/^DynamicField_/} keys %Param;

            # TODO rendering throws error 'Need ID in DynamicFieldConfig!' in process case because ids in %DynamicFieldConfig are concatenated with activitydialogid
            $Param{DynamicFieldHTML} = $Kernel::OM->Get('Kernel::Output::HTML::DynamicField::Mask')->EditSectionRender(
                Content               => $Self->{MaskDefinition},
                DynamicFields         => $Self->{FollowUpDynamicField},
                LayoutObject          => $LayoutObject,
                ParamObject           => $Kernel::OM->Get('Kernel::System::Web::Request'),
                DynamicFieldValues    => \%DynamicFieldValues,
                PossibleValuesFilter  => $Param{DFPossibleValues},
                Errors                => $Param{DFErrors},
                Visibility            => $Param{Visibility},
                SeparateDynamicFields => $SeparateDynamicFields,
                CustomerInterface     => 1,
                Object                => {
                    CustomerID     => $Self->{CustomerID},
                    CustomerUserID => $Self->{UserID},
                    %DynamicFieldValues,
                },
            );

        }

        # show attachments
        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

        ATTACHMENT:
        for my $Attachment (@Attachments) {
            if (
                $Attachment->{ContentID}
                && $LayoutObject->{BrowserRichText}
                && ( $Attachment->{ContentType} =~ /image/i )
                && ( $Attachment->{Disposition} eq 'inline' )
                )
            {
                next ATTACHMENT;
            }

            push @{ $Param{AttachmentList} }, $Attachment;
        }
    }

    # name and avatar
    my %CustomerUser = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
        User => $Article{CustomerUserID} || $Ticket{CustomerUserID},
    );
    my ( $Avatar, $UserInitials );
    if ( $ConfigObject->Get('Frontend::AvatarEngine') eq 'Gravatar' && $CustomerUser{UserEmail} ) {
        my $DefaultIcon = $ConfigObject->Get('Frontend::Gravatar::DefaultImage') || 'mm';
        $Avatar = '//www.gravatar.com/avatar/' . md5_hex( lc $CustomerUser{UserEmail} ) . '?s=100&d=' . $DefaultIcon;
    }
    else {
        $UserInitials = substr( $CustomerUser{UserFirstName} || '', 0, 1 )
            . substr( $CustomerUser{UserLastName} || '', 0, 1 );
    }

    # explanatory message about asterisk
    if ( $ConfigObject->Get('Ticket::Frontend::AsteriskExplanation') ) {
        $LayoutObject->Block(
            Name => 'AsteriskExplanation',
        );
    }

    # select the output template
    return $LayoutObject->Output(
        TemplateFile => 'CustomerTicketZoom',
        Data         => {
            %Article,
            %Param,
            TicketInfoDisplayType => $Config->{TicketInfoDisplayType} || 'Header',
            Articles              => $ArticleHTML,
            Avatar                => $Avatar,
            UserInitials          => $UserInitials,
            UserFirstname         => $CustomerUser{UserFirstname},
            UserLastname          => $CustomerUser{UserLastname},
        },
    );
}

1;
