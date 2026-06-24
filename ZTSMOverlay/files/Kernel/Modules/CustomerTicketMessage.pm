# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://ncs.com.sg
# --
# $origin: otobo - e423ee3f4f0faf7995db27018567746054da97e5 - Kernel/Modules/CustomerTicketMessage.pm
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

package Kernel::Modules::CustomerTicketMessage;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language              qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # frontend specific config
    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # get the dynamic fields for this screen
    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket', 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    my $Definition = $Kernel::OM->Get('Kernel::System::Ticket::Mask')->DefinitionGet(
        Mask => $Self->{Action},
    ) || {};

    $Self->{MaskDefinition} = $Definition->{Mask};
    $Self->{DynamicField}   = {};

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
                Mandatory => $Config->{DynamicField}{ $DynamicField->{Name} } == 2 ? 1 : 0,
            };

            if ( $Config->{DynamicField}{ $DynamicField->{Name} } == 2 ) {
                $DynamicField->{Mandatory} = 1;
            }
        }

        $Self->{DynamicField}{ $DynamicField->{Name} } = $DynamicField;
    }

    # align sysconfig and ticket mask data II
    for my $DynamicFieldName ( keys $Definition->{DynamicFields}->%* ) {
        $Self->{DynamicField}{$DynamicFieldName} = $DynamicFieldObject->DynamicFieldGet(
            Name => $DynamicFieldName,
        );

        my $Parameters = $Definition->{DynamicFields}{$DynamicFieldName} // {};

        for my $Attribute ( keys $Parameters->%* ) {
            $Self->{DynamicField}{$DynamicFieldName}{$Attribute} = $Parameters->{$Attribute};
        }
    }

    $Self->_ServiceExtensionDynamicFieldsLoad(
        DynamicFieldObject        => $DynamicFieldObject,
        DynamicFieldBackendObject => $BackendObject,
    );

    # get form id
    $Self->{FormID} = $Kernel::OM->Get('Kernel::System::Web::FormCache')->PrepareFormID(
        ParamObject  => $Kernel::OM->Get('Kernel::System::Web::Request'),
        LayoutObject => $Kernel::OM->Get('Kernel::Output::HTML::Layout'),
    );

    # methods which are used to determine the possible values of the standard fields
    $Self->{FieldMethods} = [
        {
            FieldID => 'Dest',
            Method  => \&_GetTos
        },
        {
            FieldID => 'PriorityID',
            Method  => \&_GetPriorities
        },
        {
            FieldID => 'ServiceID',
            Method  => \&_GetServices
        },
        {
            FieldID => 'SLAID',
            Method  => \&_GetSLAs
        },
        {
            FieldID => 'TypeID',
            Method  => \&_GetTypes
        },
    ];

    # dependencies of standard fields which are not defined via ACLs
    $Self->{InternalDependancy} = {
        ServiceID => {
            SLAID => 1,
        },
    };

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get params
    my %GetParam;
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    for my $Key (qw( Subject Body PriorityID TypeID ServiceID SLAID Dest FromChatID)) {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    # get Dynamic fields from ParamObject
    my %DynamicFieldValues;

    my $LayoutObject            = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $BackendObject           = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $FieldRestrictionsObject = $Kernel::OM->Get('Kernel::System::Ticket::FieldRestrictions');

    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( values $Self->{DynamicField}->%* ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # extract the dynamic field value from the web request
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } =
            $BackendObject->EditFieldValueGet(
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
    $Self->_ServiceExtensionDynamicFieldValuesSync(
        GetParam => \%GetParam,
    );
    $Self->_ZTSMRequestDefaultsHydrate(
        DynamicFieldValues => \%DynamicFieldValues,
        GetParam           => \%GetParam,
    );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Config = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

# Rother OSS / ITSMCore - calculate Priority via CIP matrix
    my $CIPCalculate = $Config->{PriorityByCIP} // $ConfigObject->Get('ITSM::Frontend::CIPAllocationDefault');
    my $ServiceObject;
    my $CIPAllocateObject;
    if ( $CIPCalculate ) {
        $ServiceObject     = $Kernel::OM->Get('Kernel::System::Service');
        $CIPAllocateObject = $Kernel::OM->Get('Kernel::System::ITSMCIPAllocate');

        $Self->{InternalDependancy}{ServiceID}{PriorityID}                    = 1;
        $Self->{InternalDependancy}{DynamicField_ITSMImpact}{PriorityID}      = 1;
        $Self->{InternalDependancy}{DynamicField_ITSMCriticality}{PriorityID} = 1;
    }
# EO ITSMCore

    if ( $Self->{Subaction} && $Self->{Subaction} eq 'ZTSMServicePayloadReferenceResolve' ) {
        my $ReferenceResult = $Self->_ZTSMServicePayloadReferenceResolve(
            LayoutObject => $LayoutObject,
            ParamObject  => $ParamObject,
        );

        return $LayoutObject->JSONReply(
            Data => $ReferenceResult,
        );
    }

    if ( $Self->{Subaction} && $Self->{Subaction} eq 'ZTSMServiceExtensionDynamicFields' ) {
        my %Visibility;
        $Self->_ServiceExtensionVisibilityApply(
            ServiceID  => $GetParam{ServiceID},
            Visibility => \%Visibility,
        );

        my $DynamicFieldHTML = $Self->_ServiceExtensionDynamicFieldHTMLBuild(
            DynamicFieldValues => $GetParam{DynamicField},
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            ServiceID          => $GetParam{ServiceID},
            Visibility         => \%Visibility,
        );

        return $LayoutObject->Attachment(
            ContentType => 'text/html; charset=utf-8',
            Content     => $DynamicFieldHTML || '',
            Type        => 'inline',
            NoCache     => 1,
        );
    }

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

    if ( !$Self->{Subaction} ) {

# Rother OSS / ServiceCatalog
        my %ServiceData;
        if ( $GetParam{ServiceID} ) {
            my %Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
                ServiceID => $GetParam{ServiceID},
                UserID    => 1,
            );

            # check if we really should use ServiceCatalog functionality
            if ( exists $Service{DestQueueID} ) {
                $ServiceData{ServiceID} = $GetParam{ServiceID};
                $ServiceData{TypeID}    = $GetParam{TypeID};
            }
        }
# EO ServiceCatalog

        # Get default Queue ID if none is set
        my $QueueDefaultID;
        if ( !$GetParam{Dest} ) {
            my $QueueDefault = $Config->{'QueueDefault'} || '';
            if ($QueueDefault) {
                $QueueDefaultID = $QueueObject->QueueLookup( Queue => $QueueDefault );
                if ($QueueDefaultID) {
                    $GetParam{Dest} = $QueueDefaultID . '||' . $QueueDefault;
                }
                $GetParam{QueueID} = $QueueDefaultID;
            }

            # warn if there is no (valid) default queue and the customer can't select one
            elsif ( !$Config->{'Queue'} ) {
                $LayoutObject->CustomerFatalError(
                    Message => $LayoutObject->{LanguageObject}->Translate( 'Check SysConfig setting for %s::QueueDefault.', $Self->{Action} ),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }
        }
        elsif ( $GetParam{Dest} ) {
            my ( $QueueIDParam, $QueueParam ) = split( /\|\|/, $GetParam{Dest} );
            my $QueueIDLookup = $QueueObject->QueueLookup( Queue => $QueueParam );
            if ( $QueueIDLookup && $QueueIDLookup eq $QueueIDParam ) {
                my $CustomerPanelOwnSelection = $Kernel::OM->Get('Kernel::Config')->Get('CustomerPanelOwnSelection');
                if ( %{ $CustomerPanelOwnSelection // {} } ) {
                    $GetParam{Dest} = $QueueIDParam . '||' . $CustomerPanelOwnSelection->{$QueueParam};
                }
                $GetParam{QueueID} = $QueueIDLookup;
            }
        }

        my $Autoselect = $ConfigObject->Get('TicketACL::Autoselect') || undef;

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
        my %ChangedElements;
        my %ChangedElementsDFStart;
        my %ChangedStdFields;

# Rother OSS / ITSMCore - calculate Priority via CIP matrix
        if ( $CIPCalculate && $GetParam{DynamicField}{DynamicField_ITSMImpact}
            && ( $GetParam{DynamicField}{DynamicField_ITSMCriticality} || $GetParam{ServiceID} ) ) {

            # if we have an initial criticality and impact, trigger priority calculation
            $ChangedElements{DynamicField_ITSMImpact} = 1;
        }
# EO ITSMCore

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
                    Dest       => 'QueueID',
                    PriorityID => 'PriorityID',
                    ServiceID  => 'ServiceID',
                    SLAID      => 'SLAID',
                    TypeID     => 'TypeID',
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
                        CustomerUserID => $Self->{UserID},
                        QueueID        => $GetParam{QueueID},
                        Services       => $StdFieldValues{ServiceID} || undef,    # needed for SLAID
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

# Rother OSS / ITSMCore - calculate Priority via CIP matrix
                    elsif ( $Field->{FieldID} eq 'PriorityID' && $CIPCalculate && $GetParam{DynamicField}{DynamicField_ITSMImpact} ) {

                        # get the criticality either from the manually set dynamic field, or the service
                        my $Criticality = $GetParam{DynamicField_ITSMCriticality};

                        if ( !$Criticality && $GetParam{ServiceID} ) {
                            my %Service = $ServiceObject->ServiceGet(
                                ServiceID => $GetParam{ServiceID},
                                UserID    => 1,
                            );

                            $Criticality = $Service{Criticality};
                        }

                        if ( $Criticality ) {

                            # recalculate the priority if any of the impacting elements changed
                            if ( $ChangedElements{DynamicField_ITSMImpact} || $ChangedElements{ServiceID} || $ChangedElements{DynamicField_ITSMCriticality} ) {
                                my $PriorityID = $CIPAllocateObject->PriorityAllocationGet(
                                    Criticality => $Criticality,
                                    Impact      => $GetParam{DynamicField}{DynamicField_ITSMImpact},
                                );

                                if ( $StdFieldValues{PriorityID}{ $PriorityID } && $PriorityID ne $GetParam{PriorityID} ) {
                                    $GetParam{PriorityID}           = $PriorityID;
                                    $NewChangedElements{PriorityID} = 1;
                                    $ChangedStdFields{PriorityID}   = 1;
                                }
                            }

                            # if we enforce CIPAllocation in any case delete all other priority options
                            if ( $GetParam{PriorityID} && $CIPCalculate == 2 ) {
                                $StdFieldValues{PriorityID} = {
                                    $GetParam{PriorityID} => $StdFieldValues{PriorityID}{ $GetParam{PriorityID} },
                                };
                            }
                        }
                    }
# EO ITSMCore

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
                    DynamicFields             => $Self->{DynamicField},
                    DynamicFieldBackendObject => $BackendObject,
                    ChangedElements           => \%ChangedElements,       # optional to reduce ACL evaluation
                    Action                    => $Self->{Action},
                    FormID                    => $Self->{FormID},
                    CustomerUser              => $Self->{UserID},
                    GetParam                  => {
                        %GetParam,
                    },
                    Autoselect      => $Autoselect,
                    ACLPreselection => $ACLPreselection,
                    LoopProtection  => \$LoopProtection,
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

        my %DynamicFieldPossibleValues = map {
            'DynamicField_' . $_ => defined $DynFieldStates{Fields}{$_}
                ? $DynFieldStates{Fields}{$_}{PossibleValues}
                : undef
        } ( keys $Self->{DynamicField}->%* );
        $Self->_ServiceExtensionVisibilityApply(
            ServiceID  => $GetParam{ServiceID},
            Visibility => $DynFieldStates{Visibility},
        );

        my $ACLResultStd = $TicketObject->TicketAcl(
            %GetParam,
            CustomerUserID => $Self->{UserID},
            Action         => $Self->{Action},
            ReturnType     => 'FormStd',
            ReturnSubType  => '-',
            Data           => {
                Article => 'Article',
            },
        );

        my %VisibilityStd;

        if ($ACLResultStd) {
            my %AclData = $TicketObject->TicketAclData();
            for my $Field ( sort keys %AclData ) {
                $VisibilityStd{$Field} = 1;
            }
        }

        else {
            $VisibilityStd{Article} = 1;
        }

        # print form ...
        my $Output = $LayoutObject->CustomerHeader();
        $Output .= $Self->_MaskNew(
            %GetParam,
            ToSelected       => $GetParam{Dest},
            FromChatID       => $GetParam{FromChatID} || '',
            HideAutoselected => $HideAutoselectedJSON,
            Visibility       => $DynFieldStates{Visibility},
            VisibilityStd    => \%VisibilityStd,
            DFPossibleValues => \%DynamicFieldPossibleValues,
# Rother OSS / ServiceCatalog
            ServiceData      => \%ServiceData,
# EO ServiceCatalog
        );
        $Output .= $LayoutObject->CustomerNavigationBar();
        $Output .= $LayoutObject->CustomerFooter();

        return $Output;
    }
    elsif ( $Self->{Subaction} eq 'StoreNew' ) {

        my $ArticleObject        = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my $ArticleBackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Internal' );

        my $NextScreen = $Config->{NextScreenAfterNewTicket};
        my %Error;

        # get destination queue
        my $Dest = $ParamObject->GetParam( Param => 'Dest' ) || '';
        my ( $NewQueueID, $To ) = split( /\|\|/, $Dest );
        if ( !$To ) {
            $NewQueueID = $ParamObject->GetParam( Param => 'NewQueueID' ) || '';
            $To         = 'System';
        }

        # fallback, if no destination is given
        if ( !$NewQueueID ) {
            my $Queue = $ParamObject->GetParam( Param => 'Queue' )
                || $Config->{'QueueDefault'}
                || '';
            if ($Queue) {
                my $QueueID = $QueueObject->QueueLookup( Queue => $Queue );
                $NewQueueID = $QueueID;
                $To         = $Queue;
            }
        }

        $GetParam{NewQueueID} = $NewQueueID;

        # use default if ticket type is not available in screen but activated on system
        if ( $ConfigObject->Get('Ticket::Type') && !$Config->{'TicketType'} ) {
            my %TypeList = $TicketObject->TicketTypeList(
                %Param,
                Action         => $Self->{Action},
                CustomerUserID => $Self->{UserID},
            );
            $Self->_ZTSMRequestTypesFilter( Type => \%TypeList );

            my %ReverseTypeList = reverse %TypeList;
            $GetParam{TypeID} = $ReverseTypeList{ $Config->{'TicketTypeDefault'} };
            if ( !$GetParam{TypeID} ) {
                $LayoutObject->CustomerFatalError(
                    Message =>
                        $LayoutObject->{LanguageObject}->Translate( 'Check SysConfig setting for %s::TicketTypeDefault.', $Self->{Action} ),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }
        }

        my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

        # get all attachments meta data
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
            FormID => $Self->{FormID},
        );

# Rother OSS / ITSMCore - calculate Priority via CIP matrix
        if ( $CIPCalculate && $CIPCalculate == 2 && $GetParam{DynamicField}{DynamicField_ITSMImpact} && $Config->{Priority} ) {

            # get the criticality either from the manually set dynamic field, or the service
            my $Criticality = $GetParam{DynamicField_ITSMCriticality};

            if ( !$Criticality && $GetParam{ServiceID} ) {
                my %Service = $ServiceObject->ServiceGet(
                    ServiceID => $GetParam{ServiceID},
                    UserID    => 1,
                );

                $Criticality = $Service{Criticality};
            }

            if ( $Criticality ) {
                my $PriorityID = $CIPAllocateObject->PriorityAllocationGet(
                    Criticality => $Criticality,
                    Impact      => $GetParam{DynamicField}{DynamicField_ITSMImpact},
                );

                if ( $PriorityID ne $GetParam{PriorityID} ) {

                    # this should never happen; we just enforce the prio and write an error to the log file here
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'error',
                        Message  => "Got PriorityID '$GetParam{PriorityID}', but CIP enforces '$PriorityID' - overriding the frontend value.",
                    );

                    $GetParam{PriorityID} = $PriorityID;
                }
            }
        }
# EO ITSMCore

        # skip validation of hidden fields
        my %Visibility;

        # transform dynamic field data into DFName => DFName pair
        my %DynamicFieldAcl = map { $_ => $_ } keys $Self->{DynamicField}->%*;

        # call ticket ACLs for DynamicFields to check field visibility
        my $ACLResult = $TicketObject->TicketAcl(
            %GetParam,
            CustomerUserID => $Self->{UserID},
            Action         => $Self->{Action},
            TicketID       => $Self->{TicketID},
            ReturnType     => 'Form',
            ReturnSubType  => '-',
            Data           => \%DynamicFieldAcl,
        );
        if ($ACLResult) {
            %Visibility = map { 'DynamicField_' . $_ => 0 } keys $Self->{DynamicField}->%*;
            my %AclData = $TicketObject->TicketAclData();
            for my $Field ( sort keys %AclData ) {
                $Visibility{ 'DynamicField_' . $Field } = 1;
            }
        }
        else {
            %Visibility = map { 'DynamicField_' . $_ => 1 } keys $Self->{DynamicField}->%*;
        }
        $Self->_ServiceExtensionVisibilityApply(
            ServiceID  => $GetParam{ServiceID},
            Visibility => \%Visibility,
        );
        $Self->_ServiceExtensionMandatoryApply(
            ServiceID => $GetParam{ServiceID},
        );

        # remember dynamic field validation results if erroneous
        my %DynamicFieldValidationResult;
        my %DynamicFieldPossibleValues;

        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Self->{DynamicField}->%* ) {
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

            # do not validate on insisible fields
            if ( $Visibility{ 'DynamicField_' . $DynamicFieldConfig->{Name} } ) {

                my $ValidationResult = $BackendObject->EditFieldValueValidate(
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
                        Message =>
                            $LayoutObject->{LanguageObject}->Translate( 'Could not perform validation on field %s!', $DynamicFieldConfig->{Label} ),
                        Comment => Translatable('Please contact the administrator.'),
                    );
                    $Output .= $LayoutObject->CustomerFooter();

                    return $Output;
                }

                # propagate validation error to the Error variable to be detected by the frontend
                if ( $ValidationResult->{ServerError} ) {
                    $Error{ $DynamicFieldConfig->{Name} }                        = ' ServerError';
                    $DynamicFieldValidationResult{ $DynamicFieldConfig->{Name} } = $ValidationResult;
                }
            }
        }

        # rewrap body if no rich text is used
        if ( $GetParam{Body} && !$LayoutObject->{BrowserRichText} ) {
            $GetParam{Body} = $LayoutObject->WrapPlainText(
                MaxCharacters => $ConfigObject->Get('Ticket::Frontend::TextAreaNote'),
                PlainText     => $GetParam{Body},
            );
        }

        # if there is FromChatID, get related messages and prepend them to body
        if ( $GetParam{FromChatID} ) {
            my @ChatMessages = $Kernel::OM->Get('Kernel::System::Chat')->ChatMessageList(
                ChatID => $GetParam{FromChatID},
            );

            for my $Message (@ChatMessages) {
                $Message->{MessageText} = $LayoutObject->Ascii2Html(
                    Text        => $Message->{MessageText},
                    LinkFeature => 1,
                );
            }
        }

        # check queue
        if ( !$NewQueueID ) {
            $Error{QueueInvalid} = 'ServerError';
        }

        # prevent tamper with (Queue/Dest), see bug#9408
        if ($NewQueueID) {

            # get the original list of queues to display
            my $Tos = $Self->_GetTos(
                %GetParam,
                QueueID => $NewQueueID,
            );

            # check if current selected QueueID exists in the list of queues,\
            # otherwise rise an error
            if ( !$Tos->{$NewQueueID} ) {

                # Check if queue is accessible by customer user (see bug#14886).
                if ( $ConfigObject->Get('Ticket::Frontend::CustomerTicketMessage')->{Queue} == 0 ) {
                    $Error{QueueDisabled} = 'ServerError';
                }
                else {
                    $Error{QueueInvalid} = 'ServerError';
                }
            }

            # set the correct queue name in $To if it was altered
            if ( $To ne $Tos->{$NewQueueID} ) {
                $To = $Tos->{$NewQueueID};
            }
        }

        my $ACLResultStd = $TicketObject->TicketAcl(
            %GetParam,
            CustomerUserID => $Self->{UserID},
            Action         => $Self->{Action},
            ReturnType     => 'FormStd',
            ReturnSubType  => '-',
            Data           => {
                Article => 'Article',
            },
        );

        my %VisibilityStd;

        if ($ACLResultStd) {
            my %AclData = $TicketObject->TicketAclData();
            for my $Field ( sort keys %AclData ) {
                $VisibilityStd{$Field} = 1;
            }
        }

        else {
            $VisibilityStd{Article} = 1;
        }

        if ( $VisibilityStd{Article} ) {

            # check subject
            if ( !$GetParam{Subject} ) {
                $Error{SubjectInvalid} = 'ServerError';
            }

            # check body
            if ( !$GetParam{Body} ) {
                $Error{BodyInvalid} = 'ServerError';
            }
        }

        # check mandatory service
        if (
            $ConfigObject->Get('Ticket::Service')
            && $Config->{Service}
            && $Config->{ServiceMandatory}
            && !$GetParam{ServiceID}
            )
        {
            $Error{'ServiceIDInvalid'} = 'ServerError';
        }

        # check mandatory sla
        if (
            $ConfigObject->Get('Ticket::Service')
            && $Config->{SLA}
            && $Config->{SLAMandatory}
            && !$GetParam{SLAID}
            )
        {
            $Error{'SLAIDInvalid'} = 'ServerError';
        }

        # check type
        if ( $ConfigObject->Get('Ticket::Type') && !$GetParam{TypeID} ) {
            $Error{TypeIDInvalid} = 'ServerError';
        }
        elsif ( $ConfigObject->Get('Ticket::Type') && $GetParam{TypeID} ) {
            my $AllowedType = $Self->_GetTypes(
                %GetParam,
                QueueID => $NewQueueID || 1,
            );

            if ( !$AllowedType->{ $GetParam{TypeID} } ) {
                $Error{TypeIDInvalid} = 'ServerError';
            }
        }

        if (%Error) {

            # html output
            my $Output = $LayoutObject->CustomerHeader();

            if ( $Error{QueueDisabled} ) {
                $Output .= $LayoutObject->Notify(
                    Priority => 'Error',
                    Info     => Translatable("You don't have sufficient permissions for ticket creation in default queue."),
                );
            }

            $Output .= $Self->_MaskNew(
                Attachments => \@Attachments,
                %GetParam,
                ToSelected       => $Dest,
                QueueID          => $NewQueueID,
                Errors           => \%Error,
                Visibility       => \%Visibility,
                VisibilityStd    => \%VisibilityStd,
                DFPossibleValues => \%DynamicFieldPossibleValues,
                DFErrors         => \%DynamicFieldValidationResult,
            );
            $Output .= $LayoutObject->CustomerNavigationBar();
            $Output .= $LayoutObject->CustomerFooter();

            return $Output;
        }

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck( Type => 'Customer' );

        # if customer is not allowed to set priority, set it to default
        if ( !$Config->{Priority} ) {
            $GetParam{PriorityID} = '';
            $GetParam{Priority}   = $Config->{PriorityDefault};
        }

# Rother OSS / ServiceCatalog Move ticket in queue based on service information
        if ( $GetParam{ServiceID} ) {
            my %ServiceData = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
                ServiceID => $GetParam{ServiceID},
                UserID    => 1,
            );

            if ( $ServiceData{DestQueueID} ) {
                $NewQueueID = $ServiceData{DestQueueID};
            }
        }
# EO ServiceCatalog

        # create new ticket, do db insert
        my $TicketID = $TicketObject->TicketCreate(
            QueueID      => $NewQueueID,
            TypeID       => $GetParam{TypeID},
            ServiceID    => $GetParam{ServiceID},
            SLAID        => $GetParam{SLAID},
            Title        => $GetParam{Subject},
            PriorityID   => $GetParam{PriorityID},
            Priority     => $GetParam{Priority},
            Lock         => 'unlock',
            State        => $Config->{StateDefault},
            CustomerID   => $Self->{UserCustomerID},
            CustomerUser => $Self->{UserLogin},
            OwnerID      => $ConfigObject->Get('CustomerPanelUserID'),
            UserID       => $ConfigObject->Get('CustomerPanelUserID'),
        );

        # set ticket dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Self->{DynamicField}->%* ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{ObjectType} ne 'Ticket';
            next DYNAMICFIELD if !$Visibility{"DynamicField_$DynamicFieldConfig->{Name}"};
            next DYNAMICFIELD if $DynamicFieldConfig->{Readonly};

            # set the value
            my $Success = $BackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $TicketID,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        $Self->_ZTSMRequesterOwnerSnapshotSet(
            TicketID => $TicketID,
            UserID   => $ConfigObject->Get('CustomerPanelUserID'),
        );

        # if no article has to be created clean up and return
        if ( !$VisibilityStd{Article} ) {

            # remove all form data
            $Kernel::OM->Get('Kernel::System::Web::FormCache')->FormIDRemove( FormID => $Self->{FormID} );

            # delete hidden fields cache
            $Kernel::OM->Get('Kernel::System::Cache')->Delete(
                Type => 'HiddenFields',
                Key  => $Self->{FormID},
            );

            # redirect
            return $LayoutObject->Redirect(
                OP => "Action=$NextScreen;TicketID=$TicketID",
            );
        }

        my $MimeType = 'text/plain';
        if ( $LayoutObject->{BrowserRichText} ) {
            $MimeType = 'text/html';
        }

        my $ServiceExtensionSnapshot = $Self->_ServiceExtensionArticleSnapshotBuild(
            DynamicFieldValues => \%DynamicFieldValues,
            HTMLOutput         => $LayoutObject->{BrowserRichText} ? 1 : 0,
            LayoutObject       => $LayoutObject,
            ServiceID          => $GetParam{ServiceID},
            Visibility         => \%Visibility,
        );

        if ($ServiceExtensionSnapshot) {
            if ( $LayoutObject->{BrowserRichText} ) {
                $GetParam{Body} .= '<br/><br/>' . $ServiceExtensionSnapshot;
            }
            else {
                $GetParam{Body} .= "\n\n" . $ServiceExtensionSnapshot;
            }
        }

        if ( $LayoutObject->{BrowserRichText} ) {
            # verify html document
            $GetParam{Body} = $LayoutObject->RichTextDocumentComplete(
                String => $GetParam{Body},
            );
        }

        my $PlainBody = $GetParam{Body};

        if ( $LayoutObject->{BrowserRichText} ) {
            $PlainBody = $LayoutObject->RichText2Ascii( String => $GetParam{Body} );
        }

        # create article
        my $FullName = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
            UserLogin => $Self->{UserLogin},
        );
        my $From      = "\"$FullName\" <$Self->{UserEmail}>";
        my $ArticleID = $ArticleBackendObject->ArticleCreate(
            TicketID             => $TicketID,
            IsVisibleForCustomer => 1,
            SenderType           => $Config->{SenderType},
            From                 => $From,
            To                   => $To,
            Subject              => $GetParam{Subject},
            Body                 => $GetParam{Body},
            MimeType             => $MimeType,
            Charset              => $LayoutObject->{UserCharset},
            UserID               => $ConfigObject->Get('CustomerPanelUserID'),
            HistoryType          => $Config->{HistoryType},
            HistoryComment       => $Config->{HistoryComment} || '%%',
            AutoResponseType     => ( $ConfigObject->Get('AutoResponseForWebTickets') )
            ? 'auto reply'
            : '',
            OrigHeader => {
                From    => $From,
                To      => $Self->{UserLogin},
                Subject => $GetParam{Subject},
                Body    => $PlainBody,
            },
            Queue => $QueueObject->QueueLookup( QueueID => $NewQueueID ),
        );

        if ( !$ArticleID ) {
            my $Output = $LayoutObject->CustomerHeader(
                Title => Translatable('Error'),
            );
            $Output .= $LayoutObject->CustomerError();
            $Output .= $LayoutObject->CustomerFooter();

            return $Output;
        }

        # set article dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Self->{DynamicField}->%* ) {
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

        # Permissions check were done earlier
        if ( $GetParam{FromChatID} ) {
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
                    TicketID             => $TicketID,
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

        # get pre loaded attachment
        my @AttachmentData = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $Self->{FormID},
        );

        # get submitted attachment
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'file_upload',
        );
        if (%UploadStuff) {
            push @AttachmentData, \%UploadStuff;
        }

        # write attachments
        ATTACHMENT:
        for my $Attachment (@AttachmentData) {

            # skip, deleted not used inline images
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
                next ATTACHMENT if $GetParam{Body} !~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i;
            }

            # write existing file to backend
            $ArticleBackendObject->ArticleWriteAttachment(
                %{$Attachment},
                ArticleID => $ArticleID,
                UserID    => $ConfigObject->Get('CustomerPanelUserID'),
            );
        }

        # remove pre submitted attachments
        $UploadCacheObject->FormIDRemove( FormID => $Self->{FormID} );

        # delete hidden fields cache
        $Kernel::OM->Get('Kernel::System::Cache')->Delete(
            Type => 'HiddenFields',
            Key  => $Self->{FormID},
        );

        # redirect
        return $LayoutObject->Redirect(
            OP => "Action=$NextScreen;TicketID=$TicketID",
        );
    }

    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {

        if ( $Config->{'Queue'} ) {
            $GetParam{QueueID} = '';
            if ( $GetParam{Dest} =~ /^(\d{1,100})\|\|.+?$/ ) {
                $GetParam{QueueID} = $1;
            }
        }

        # use QueueDefault as fallback if Queue selection is disabled
        else {
            my $QueueDefault = $Config->{'QueueDefault'} || '';
            if ($QueueDefault) {
                my $QueueDefaultID = $QueueObject->QueueLookup( Queue => $QueueDefault );
                if ($QueueDefaultID) {
                    $GetParam{Dest} = $QueueDefaultID . '||' . $QueueDefault;
                }
                $GetParam{QueueID} = $QueueDefaultID;
            }
        }

        my $CustomerUser   = $Self->{UserID};
        my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';

        # get list type
        my $TreeView = 0;
        if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
            $TreeView = 1;
        }

        my $Autoselect = $ConfigObject->Get('TicketACL::Autoselect') || undef;

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
                    Dest       => 'QueueID',
                    PriorityID => 'PriorityID',
                    ServiceID  => 'ServiceID',
                    SLAID      => 'SLAID',
                    TypeID     => 'TypeID',
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
                        CustomerUserID => $CustomerUser || '',
                        QueueID        => $GetParam{QueueID},
                        Services       => $StdFieldValues{ServiceID} || undef,    # needed for SLAID
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

# Rother OSS / ITSMCore - calculate Priority via CIP matrix
                    elsif ( $Field->{FieldID} eq 'PriorityID' && $CIPCalculate && $GetParam{DynamicField}{DynamicField_ITSMImpact} ) {

                        # get the criticality either from the manually set dynamic field, or the service
                        my $Criticality = $GetParam{DynamicField_ITSMCriticality};

                        if ( !$Criticality && $GetParam{ServiceID} ) {
                            my %Service = $ServiceObject->ServiceGet(
                                ServiceID => $GetParam{ServiceID},
                                UserID    => 1,
                            );

                            $Criticality = $Service{Criticality};
                        }

                        if ( $Criticality ) {

                            # recalculate the priority if any of the impacting elements changed
                            if ( $ChangedElements{DynamicField_ITSMImpact} || $ChangedElements{ServiceID} || $ChangedElements{DynamicField_ITSMCriticality} ) {
                                my $PriorityID = $CIPAllocateObject->PriorityAllocationGet(
                                    Criticality => $Criticality,
                                    Impact      => $GetParam{DynamicField}{DynamicField_ITSMImpact},
                                );

                                if ( $StdFieldValues{PriorityID}{ $PriorityID } && $PriorityID ne $GetParam{PriorityID} ) {
                                    $GetParam{PriorityID}           = $PriorityID;
                                    $NewChangedElements{PriorityID} = 1;
                                    $ChangedStdFields{PriorityID}   = 1;
                                }
                            }

                            # if we enforce CIPAllocation in any case delete all other priority options
                            if ( $GetParam{PriorityID} && $CIPCalculate == 2 ) {
                                $StdFieldValues{PriorityID} = {
                                    $GetParam{PriorityID} => $StdFieldValues{PriorityID}{ $GetParam{PriorityID} },
                                };
                            }
                        }
                    }
# EO ITSMCore

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
                    DynamicFields             => $Self->{DynamicField},
                    DynamicFieldBackendObject => $BackendObject,
                    ChangedElements           => \%ChangedElements,       # optional to reduce ACL evaluation
                    Action                    => $Self->{Action},
                    FormID                    => $Self->{FormID},
                    CustomerUser              => $Self->{UserID},
                    GetParam                  => {
                        %GetParam,
                    },
                    Autoselect      => $Autoselect,
                    ACLPreselection => $ACLPreselection,
                    LoopProtection  => \$LoopProtection,
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
            my $DynamicFieldConfig = $Self->{DynamicField}{$Name};

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

        $Self->_ServiceExtensionVisibilityApply(
            ServiceID  => $GetParam{ServiceID},
            Visibility => $DynFieldStates{Visibility},
        );
        $Self->_ServiceExtensionMandatoryApply(
            ServiceID => $GetParam{ServiceID},
        );
        my %DynamicFieldPossibleValues = map {
            'DynamicField_' . $_ => defined $DynFieldStates{Fields}{$_}
                ? $DynFieldStates{Fields}{$_}{PossibleValues}
                : undef
        } ( keys $Self->{DynamicField}->%* );
        my $ServiceExtensionDynamicFieldHTML = $Self->_ServiceExtensionDynamicFieldHTMLBuild(
            DynamicFieldValues   => $GetParam{DynamicField},
            LayoutObject         => $LayoutObject,
            ParamObject          => $ParamObject,
            PossibleValuesFilter => \%DynamicFieldPossibleValues,
            ServiceID            => $GetParam{ServiceID},
            Visibility           => $DynFieldStates{Visibility},
        );
        if ( IsHashRefWithData( $DynFieldStates{Visibility} ) ) {
            push @DynamicFieldAJAX, {
                Name => 'Restrictions_Visibility',
                Data => $DynFieldStates{Visibility},
            };
        }

        my $ACLResultStd = $TicketObject->TicketAcl(
            %GetParam,
            CustomerUserID => $Self->{UserID},
            Action         => $Self->{Action},
            ReturnType     => 'FormStd',
            ReturnSubType  => '-',
            Data           => {
                Article => 'Article',
            },
        );

        my %VisibilityStd = (
            Article => 0,
        );

        if ($ACLResultStd) {
            my %AclData = $TicketObject->TicketAclData();
            for my $Field ( sort keys %AclData ) {
                $VisibilityStd{$Field} = 1;
            }
        }

        else {
            $VisibilityStd{Article} = 1;
        }

        push @DynamicFieldAJAX, {
            Name => 'Restrictions_Visibility_Std',
            Data => \%VisibilityStd,
        };
        push @DynamicFieldAJAX, {
            Name => 'ZTSMServiceExtensionDynamicFieldHTML',
            Data => $ServiceExtensionDynamicFieldHTML || '',
        };

        # build AJAX return for the standard fields
        my @StdFieldAJAX;
        my %Attributes = (
            Dest => {
                Translation  => $TreeView,
                PossibleNone => 1,
                TreeView     => $TreeView,
                Max          => 100,
            },
            PriorityID => {
                Translation => 1,
                Max         => 100,
            },
            ServiceID => {
                PossibleNone => 1,
                Translation  => $TreeView,
                TreeView     => $TreeView,
                Max          => 100,
            },
            SLAID => {
                PossibleNone => 1,
                Translation  => 1,
                Max          => 100,
            },
            TypeID => {
                PossibleNone => 1,
                Translation  => 1,
                Max          => 100,
            }
        );
        delete $StdFieldValues{QueueID};
        for my $Field ( sort keys %StdFieldValues ) {
            push @StdFieldAJAX, {
                Name       => $Field,
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
    else {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No Subaction!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }
}

sub _ZTSMServicePayloadReferenceResolve {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Param{LayoutObject} || $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Param{ParamObject}  || $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Field        = $ParamObject->GetParam( Param => 'Field' ) || '';
    my $Value        = $ParamObject->GetParam( Param => 'Value' ) // '';
    my $FieldName;

    if ( $Field =~ m{\A(?:Autocomplete(?:_Search)?_)?DynamicField_([A-Za-z0-9\-]*?)(?:_[0-9]+){0,2}\z}xms ) {
        $FieldName = $1;
    }

    return {
        Success => 0,
        Message => 'Need reference field.',
    } if !$FieldName;

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $DynamicFieldConfig        = $DynamicFieldObject->DynamicFieldGet(
        Name => $FieldName,
    );

    if (
        !IsHashRefWithData($DynamicFieldConfig)
        || !$DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsReferenceField',
        )
        )
    {
        return {
            Success => 0,
            Message => "Dynamic field '$FieldName' is not a reference field.",
        };
    }

    my $SearchValue = $Self->_ZTSMServicePayloadReferenceImportValue($Value);
    return {
        Success => 1,
        Key     => '',
        Value   => '',
    } if !$SearchValue;

    if ( $SearchValue =~ s{::\s*(\d+)\s*\z}{} ) {
        my $ObjectID = $1;
        return $Self->_ZTSMServicePayloadReferenceResult(
            DynamicFieldBackendObject => $DynamicFieldBackendObject,
            DynamicFieldConfig        => $DynamicFieldConfig,
            LayoutObject              => $LayoutObject,
            ObjectID                  => $ObjectID,
            SearchValues              => [ $Value, $SearchValue ],
        );
    }

    my @SearchTerms = ($SearchValue);
    if ( $Value && $Value ne $SearchValue ) {
        push @SearchTerms, $Value;
    }

    my %CandidateSeen;
    TERM:
    for my $Term (@SearchTerms) {
        next TERM if !defined $Term || $Term eq '';

        my @ObjectIDs = $DynamicFieldBackendObject->SearchObjects(
            DynamicFieldConfig => $DynamicFieldConfig,
            Term               => $Term,
            MaxResults         => 50,
            ExternalSource     => 1,
            UserID             => 1,
        );

        OBJECTID:
        for my $ObjectID (@ObjectIDs) {
            next OBJECTID if !$ObjectID;
            next OBJECTID if $CandidateSeen{$ObjectID}++;

            my $Result = $Self->_ZTSMServicePayloadReferenceResult(
                DynamicFieldBackendObject => $DynamicFieldBackendObject,
                DynamicFieldConfig        => $DynamicFieldConfig,
                LayoutObject              => $LayoutObject,
                ObjectID                  => $ObjectID,
                SearchValues              => [ $Value, $SearchValue, $Term ],
            );
            return $Result if $Result->{Success};
        }
    }

    return {
        Success => 0,
        Message => "Could not resolve '$Value' for $FieldName.",
    };
}

sub _ZTSMServicePayloadReferenceResult {
    my ( $Self, %Param ) = @_;

    return { Success => 0 } if !$Param{ObjectID};
    return { Success => 0 } if !$Self->_ZTSMServicePayloadReferenceClassAllowed(%Param);

    my $Description = $Param{DynamicFieldBackendObject}->ObjectDescriptionGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        LayoutObject       => $Param{LayoutObject},
        ObjectID           => $Param{ObjectID},
    ) || {};

    my @Labels = grep { defined $_ && $_ ne '' } (
        $Description->{Long},
        $Description->{Normal},
        $Description->{Short},
    );

    my $ObjectData = $Self->_ZTSMServicePayloadReferenceObjectGet(%Param);
    if ( IsHashRefWithData($ObjectData) ) {
        push @Labels, grep { defined $_ && $_ ne '' } (
            $ObjectData->{Name},
            $ObjectData->{Number},
        );
    }

    my %Wanted;
    for my $SearchValue ( @{ $Param{SearchValues} || [] } ) {
        my $Normalized = $Self->_ZTSMServicePayloadReferenceNormalize($SearchValue);
        $Wanted{$Normalized} = 1 if $Normalized;
    }

    LABEL:
    for my $Label (@Labels) {
        my $NormalizedLabel = $Self->_ZTSMServicePayloadReferenceNormalize($Label);
        next LABEL if !$NormalizedLabel;
        next LABEL if !$Wanted{$NormalizedLabel};

        return {
            Success => 1,
            Key     => "$Param{ObjectID}",
            Value   => $Description->{Long} || $Description->{Normal} || $Label,
        };
    }

    return {
        Success => 0,
        Message => "Object '$Param{ObjectID}' does not match the requested value.",
    };
}

sub _ZTSMServicePayloadReferenceClassAllowed {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig} || {};
    return 1 if ( $DynamicFieldConfig->{FieldType} || '' ) ne 'GovernanceObject';

    my $ClassValues = $DynamicFieldConfig->{Config}{ClassIDs};
    return 1 if !IsArrayRefWithData($ClassValues);

    my $ObjectData = $Self->_ZTSMServicePayloadReferenceObjectGet(%Param);
    return if !IsHashRefWithData($ObjectData);

    my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
    ) || {};
    my %ClassName2ID = reverse %{$ClassList};
    my %AllowedClassID;

    VALUE:
    for my $Value ( @{$ClassValues} ) {
        next VALUE if !defined $Value || $Value eq '';

        my $ClassID = $Value =~ m{\A\d+\z} ? $Value : $ClassName2ID{$Value};
        next VALUE if !$ClassID;

        $AllowedClassID{$ClassID} = 1;
    }

    return 1 if !%AllowedClassID;
    return $AllowedClassID{ $ObjectData->{ClassID} } ? 1 : 0;
}

sub _ZTSMServicePayloadReferenceObjectGet {
    my ( $Self, %Param ) = @_;

    return if !$Param{ObjectID};
    return if ( $Param{DynamicFieldConfig}{FieldType} || '' ) ne 'GovernanceObject';

    return $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $Param{ObjectID},
        DynamicFields      => 0,
        UserID             => 1,
        Silent             => 1,
    );
}

sub _ZTSMServicePayloadReferenceImportValue {
    my ( $Self, $Value ) = @_;

    $Value //= '';
    $Value =~ s{\A\s+|\s+\z}{}g;
    return '' if $Value eq '-';

    my $ExplicitID = '';
    if ( $Value =~ s{::\s*(\d+)\s*\z}{} ) {
        $ExplicitID = $1;
    }

    $Value =~ s{\A[A-Za-z][A-Za-z0-9 _-]{1,40}:\s*}{};
    $Value =~ s{\A\s+|\s+\z}{}g;

    return $ExplicitID ? "$Value::$ExplicitID" : $Value;
}

sub _ZTSMServicePayloadReferenceNormalize {
    my ( $Self, $Value ) = @_;

    $Value = $Self->_ZTSMServicePayloadReferenceImportValue($Value);
    $Value =~ s{::\s*\d+\s*\z}{};
    $Value =~ s{\s+}{ }g;
    $Value =~ s{\A\s+|\s+\z}{}g;

    return lc $Value;
}

sub _GetPriorities {
    my ( $Self, %Param ) = @_;

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || 1;

    # get priority
    my %Priorities;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %Priorities = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );
    }

    return \%Priorities;
}

sub _GetTypes {
    my ( $Self, %Param ) = @_;

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || 1;

    # get type
    my %Type;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %Type = $Kernel::OM->Get('Kernel::System::Ticket')->TicketTypeList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );
    }

    $Self->_ZTSMRequestTypesFilter( Type => \%Type );

    return \%Type;
}

sub _ZTSMRequestTypeNameAllowList {
    my ($Self) = @_;

    my $RequestType = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::RequestType',
        Valid => 1,
    );

    return if !IsHashRefWithData($RequestType);

    my %AllowedName = map { $_ => 1 } values %{$RequestType};

    return \%AllowedName;
}

sub _ZTSMRequestTypesFilter {
    my ( $Self, %Param ) = @_;

    my $Type = $Param{Type};
    return if !IsHashRefWithData($Type);

    my $AllowedName = $Self->_ZTSMRequestTypeNameAllowList();
    return if !IsHashRefWithData($AllowedName);

    TYPEID:
    for my $TypeID ( sort keys %{$Type} ) {
        next TYPEID if $AllowedName->{ $Type->{$TypeID} };
        delete $Type->{$TypeID};
    }

    return;
}

sub _ServiceExtensionDynamicFieldsLoad {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject        = $Param{DynamicFieldObject};
    my $DynamicFieldBackendObject = $Param{DynamicFieldBackendObject};

    return if !$DynamicFieldObject || !$DynamicFieldBackendObject;

    my $ServiceFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZService-Field',
    );

    return if !IsHashRefWithData($ServiceFieldConfig);
    return if $ServiceFieldConfig->{ObjectType} ne 'Service';

    my %ServiceList = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
        Valid  => 1,
        UserID => 1,
    );

    my %FieldNamesByService;
    my %FieldSpecsByService;
    my %FieldMandatoryByService;
    my %FieldNameSeen;

    SERVICEID:
    for my $ServiceID ( sort keys %ServiceList ) {
        my $Value = $DynamicFieldBackendObject->ValueGet(
            DynamicFieldConfig => $ServiceFieldConfig,
            ObjectID           => $ServiceID,
            UserID             => 1,
        );

        my @FieldSpecs = $Self->_ServiceExtensionFieldSpecsParse( Value => $Value );
        next SERVICEID if !@FieldSpecs;

        my @FieldNames = map { $_->{Name} } @FieldSpecs;
        $FieldNamesByService{$ServiceID} = \@FieldNames;
        $FieldSpecsByService{$ServiceID} = \@FieldSpecs;
        $FieldMandatoryByService{$ServiceID} = {
            map { $_->{Name} => $_->{Mandatory} ? 1 : 0 } @FieldSpecs
        };
        @FieldNameSeen{@FieldNames} = (1) x @FieldNames;
    }

    return if !%FieldNameSeen;

    my %DefinitionField;
    my $DefinitionFieldCollect;
    $DefinitionFieldCollect = sub {
        my ($Element) = @_;

        return if !IsHashRefWithData($Element);

        if ( $Element->{DF} ) {
            $DefinitionField{ $Element->{DF} } = 1;
            return;
        }

        return if !IsHashRefWithData( $Element->{Grid} ) || !IsArrayRefWithData( $Element->{Grid}{Rows} );

        for my $Row ( $Element->{Grid}{Rows}->@* ) {
            next if ref $Row ne 'ARRAY';

            for my $Field ( $Row->@* ) {
                $DefinitionFieldCollect->($Field);
            }
        }

        return;
    };
    $DefinitionFieldCollect->($_) for $Self->{MaskDefinition}->@*;

    FIELDNAME:
    for my $FieldName ( sort keys %FieldNameSeen ) {
        my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
            Name => $FieldName,
        );

        if (
            !IsHashRefWithData($DynamicField)
            || ( $DynamicField->{ObjectType} ne 'Ticket' && $DynamicField->{ObjectType} ne 'Article' )
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Service dynamic field ZService-Field references unknown or unsupported field '$FieldName'.",
            );
            next FIELDNAME;
        }

        my $IsCustomerInterfaceCapable = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicField,
            Behavior           => 'IsCustomerInterfaceCapable',
        );
        next FIELDNAME if !$IsCustomerInterfaceCapable;

        $Self->{DynamicField}{$FieldName} ||= $DynamicField;

        if ( !$DefinitionField{$FieldName} ) {
            push $Self->{MaskDefinition}->@*, {
                DF        => $FieldName,
                Mandatory => 0,
            };
            $DefinitionField{$FieldName} = 1;
        }
    }

    $Self->{ZTSMServiceExtensionFields}              = \%FieldNameSeen;
    $Self->{ZTSMServiceExtensionFieldsByService}     = \%FieldNamesByService;
    $Self->{ZTSMServiceExtensionFieldSpecsByService} = \%FieldSpecsByService;
    $Self->{ZTSMServiceExtensionMandatoryByService}  = \%FieldMandatoryByService;

    return 1;
}

sub _ServiceExtensionFieldSpecsParse {
    my ( $Self, %Param ) = @_;

    my $Value  = $Param{Value};
    my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);

    my @FieldSpecs;
    my %Seen;
    VALUE:
    for my $Item (@Values) {
        next VALUE if !defined $Item;

        PART:
        for my $Part ( split m{\s*[|,;\r\n]\s*}, $Item ) {
            next PART if !$Part;

            $Part =~ s{\A\s+|\s+\z}{}g;

            my ( $FieldName, $Mandatory, $RenderLayout ) = split m{\s*:\s*}, $Part, 3;
            $FieldName //= '';
            $FieldName =~ s{\A\s+|\s+\z}{}g;
            $FieldName =~ s{\ADynamicField_}{};
            $RenderLayout //= '';
            $RenderLayout =~ s{\A\s+|\s+\z}{}g;

            next PART if !$FieldName;
            next PART if $Seen{$FieldName}++;

            push @FieldSpecs, {
                Name         => $FieldName,
                Mandatory    => $Mandatory && $Mandatory =~ m{\A1\z} ? 1 : 0,
                RenderLayout => $RenderLayout =~ m{\A(?:Horizontal|Vertical)\z}i ? ucfirst lc $RenderLayout : undef,
            };
        }
    }

    return @FieldSpecs;
}

sub _ServiceExtensionFieldNamesParse {
    my ( $Self, %Param ) = @_;

    return map { $_->{Name} } $Self->_ServiceExtensionFieldSpecsParse(%Param);
}

sub _ZTSMRequestDefaultsHydrate {
    my ( $Self, %Param ) = @_;

    return if !IsHashRefWithData( $Param{DynamicFieldValues} );
    return if !IsHashRefWithData( $Param{GetParam} );
    return if !$Self->{UserID};

    my %FieldMap = (
        'ZUser-Application'  => 'ZTicket-Application',
        'ZUser-Environment' => 'ZTicket-Env',
        'ZUser-Location'    => 'ZTicket-Location',
    );

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my %CustomerUser       = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
        User => $Self->{UserID},
    );

    SOURCEFIELD:
    for my $SourceField ( sort keys %FieldMap ) {
        my $TargetField = $FieldMap{$SourceField};

        next SOURCEFIELD if $Self->_ZTSMValueHasData( $Param{DynamicFieldValues}->{$TargetField} );

        my $TargetFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $TargetField,
        );
        next SOURCEFIELD if !IsHashRefWithData($TargetFieldConfig);
        next SOURCEFIELD if $TargetFieldConfig->{ObjectType} ne 'Ticket';

        my $SourceValue = $Self->_ZTSMNormalizeValue( $CustomerUser{"DynamicField_$SourceField"} );
        if ( !$SourceValue ) {
            my $SourceFieldConfig = $DynamicFieldObject->DynamicFieldGet(
                Name => $SourceField,
            );
            next SOURCEFIELD if !IsHashRefWithData($SourceFieldConfig);

            $SourceValue = $Self->_ZTSMNormalizeValue(
                $BackendObject->ValueGet(
                    DynamicFieldConfig => $SourceFieldConfig,
                    ObjectName         => $Self->{UserID},
                )
            );
        }
        next SOURCEFIELD if !$SourceValue;

        my $IsMultiValue = IsHashRefWithData( $TargetFieldConfig->{Config} )
            && $TargetFieldConfig->{Config}->{MultiValue};
        my $Value = $IsMultiValue ? [$SourceValue] : $SourceValue;

        $Param{DynamicFieldValues}->{$TargetField} = $Value;
        $Param{GetParam}->{DynamicField}{"DynamicField_$TargetField"} = $Value;
    }

    return 1;
}

sub _ZTSMValueHasData {
    my ( $Self, $Value ) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        ITEM:
        for my $Item ( @{$Value} ) {
            next ITEM if !defined $Item;
            return 1 if "$Item" ne '';
        }
        return;
    }

    return 1 if ref $Value;
    return 1 if "$Value" ne '';

    return;
}

sub _ZTSMNormalizeValue {
    my ( $Self, $Value ) = @_;

    if ( ref $Value eq 'ARRAY' ) {
        $Value = $Value->[0];
    }

    return if !defined $Value;
    return if ref $Value;

    $Value =~ s{\A\s+|\s+\z}{}g;
    return $Value;
}

sub _ZTSMRequesterOwnerSnapshotSet {
    my ( $Self, %Param ) = @_;

    return if !$Param{TicketID};
    return if !$Self->{UserID};

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZTicket-Owner',
    );
    return if !IsHashRefWithData($DynamicFieldConfig);
    return if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

    my $ExistingValue = $BackendObject->ValueGet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
    );
    return if $Self->_ZTSMValueHasData($ExistingValue);

    return $BackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
        Value              => $Self->{UserID},
        UserID             => $Param{UserID} || 1,
    );
}

sub _ServiceExtensionDynamicFieldValuesSync {
    my ( $Self, %Param ) = @_;

    return if !IsHashRefWithData( $Self->{ZTSMServiceExtensionFields} );
    return if !IsHashRefWithData( $Param{GetParam} );

    FIELDNAME:
    for my $FieldName ( sort keys $Self->{ZTSMServiceExtensionFields}->%* ) {
        next FIELDNAME if !exists $Param{GetParam}->{$FieldName};

        $Param{GetParam}->{DynamicField}{"DynamicField_$FieldName"} = $Param{GetParam}->{$FieldName};
    }

    return 1;
}

sub _ServiceExtensionVisibilityApply {
    my ( $Self, %Param ) = @_;

    return if !IsHashRefWithData( $Self->{ZTSMServiceExtensionFields} );
    return if ref $Param{Visibility} ne 'HASH';

    my %VisibleForService;
    if ( $Param{ServiceID} && IsArrayRefWithData( $Self->{ZTSMServiceExtensionFieldsByService}{ $Param{ServiceID} } ) ) {
        %VisibleForService = map { $_ => 1 } $Self->{ZTSMServiceExtensionFieldsByService}{ $Param{ServiceID} }->@*;
    }

    for my $FieldName ( sort keys $Self->{DynamicField}->%* ) {
        $Param{Visibility}{"DynamicField_$FieldName"} = 1 if !exists $Param{Visibility}{"DynamicField_$FieldName"};
    }

    FIELDNAME:
    for my $FieldName ( sort keys $Self->{ZTSMServiceExtensionFields}->%* ) {
        my $Key = "DynamicField_$FieldName";

        if ( !$VisibleForService{$FieldName} ) {
            $Param{Visibility}{$Key} = 0;
            next FIELDNAME;
        }

        $Param{Visibility}{$Key} = 1 if !exists $Param{Visibility}{$Key};
    }

    return 1;
}

sub _ServiceExtensionMandatoryApply {
    my ( $Self, %Param ) = @_;

    return if !IsHashRefWithData( $Self->{ZTSMServiceExtensionFields} );

    my $MandatoryForService = $Param{ServiceID}
        ? $Self->{ZTSMServiceExtensionMandatoryByService}{ $Param{ServiceID} } || {}
        : {};

    FIELDNAME:
    for my $FieldName ( sort keys $Self->{ZTSMServiceExtensionFields}->%* ) {
        next FIELDNAME if !IsHashRefWithData( $Self->{DynamicField}{$FieldName} );

        $Self->{DynamicField}{$FieldName}{Mandatory} = $MandatoryForService->{$FieldName} ? 1 : 0;
    }

    return 1;
}

sub _ServiceExtensionMaskDefinitionBuild {
    my ( $Self, %Param ) = @_;

    my $Content = $Param{Content} || [];
    return $Content if !IsArrayRefWithData($Content);
    return $Content if !IsHashRefWithData( $Self->{ZTSMServiceExtensionFields} );

    my $StripExtensionFields;
    $StripExtensionFields = sub {
        my ($Element) = @_;
        return if !IsHashRefWithData($Element);

        if ( $Element->{DF} ) {
            return if $Self->{ZTSMServiceExtensionFields}{ $Element->{DF} };
            return { %{$Element} };
        }

        if ( IsHashRefWithData( $Element->{Grid} ) && IsArrayRefWithData( $Element->{Grid}{Rows} ) ) {
            my @Rows;
            ROW:
            for my $Row ( $Element->{Grid}{Rows}->@* ) {
                next ROW if ref $Row ne 'ARRAY';

                my @Fields = grep { IsHashRefWithData($_) } map { $StripExtensionFields->($_) } $Row->@*;
                push @Rows, \@Fields if @Fields;
            }

            return if !@Rows;

            my %Grid = %{ $Element->{Grid} };
            $Grid{Rows} = \@Rows;
            return {
                %{$Element},
                Grid => \%Grid,
            };
        }

        return { %{$Element} };
    };

    my @MaskDefinition = grep { IsHashRefWithData($_) } map { $StripExtensionFields->($_) } $Content->@*;

    my $FieldSpecs = $Param{ServiceID}
        ? $Self->{ZTSMServiceExtensionFieldSpecsByService}{ $Param{ServiceID} }
        : undef;

    if ( IsArrayRefWithData($FieldSpecs) ) {
        FIELD:
        for my $FieldSpec ( @{$FieldSpecs} ) {
            next FIELD if !IsHashRefWithData($FieldSpec);
            next FIELD if !$FieldSpec->{Name};

            if (
                $FieldSpec->{RenderLayout}
                && IsHashRefWithData( $Self->{DynamicField}{ $FieldSpec->{Name} } )
                && ( $Self->{DynamicField}{ $FieldSpec->{Name} }{FieldType} || '' ) eq 'Set'
                )
            {
                $Self->{DynamicField}{ $FieldSpec->{Name} }{Config}{RenderLayout} = $FieldSpec->{RenderLayout};
            }

            push @MaskDefinition, {
                DF        => $FieldSpec->{Name},
                Mandatory => $FieldSpec->{Mandatory} ? 1 : 0,
            };
        }
    }

    return \@MaskDefinition;
}

sub _ServiceExtensionDynamicFieldHTMLBuild {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Param{LayoutObject} || $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Param{ParamObject}  || $Kernel::OM->Get('Kernel::System::Web::Request');

    $Self->_ServiceExtensionMandatoryApply(
        ServiceID => $Param{ServiceID},
    );
    my $MaskDefinition = $Self->_ServiceExtensionMaskDefinitionBuild(
        Content   => $Self->{MaskDefinition},
        ServiceID => $Param{ServiceID},
    );

    return $Kernel::OM->Get('Kernel::Output::HTML::DynamicField::Mask')->EditSectionRender(
        Content              => $MaskDefinition,
        DynamicFields        => $Self->{DynamicField},
        LayoutObject         => $LayoutObject,
        ParamObject          => $ParamObject,
        DynamicFieldValues   => $Param{DynamicFieldValues} || {},
        PossibleValuesFilter => $Param{PossibleValuesFilter},
        Errors               => $Param{Errors},
        Visibility           => $Param{Visibility},
        CustomerInterface    => 1,
        Object               => {
            CustomerID     => $Self->{UserCustomerID},
            CustomerUserID => $Self->{UserID},
            %{ $Param{DynamicFieldValues} || {} },
        },
    );
}

sub _ServiceExtensionArticleSnapshotBuild {
    my ( $Self, %Param ) = @_;

    return if !IsHashRefWithData( $Self->{ZTSMServiceExtensionFields} );
    return if !IsHashRefWithData( $Param{DynamicFieldValues} );
    return if !$Param{ServiceID};

    my $ServiceFieldNames = $Self->{ZTSMServiceExtensionFieldsByService}{ $Param{ServiceID} };
    return if !IsArrayRefWithData($ServiceFieldNames);

    my $LayoutObject = $Param{LayoutObject} || $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my @Rows;
    FIELDNAME:
    for my $FieldName ( @{$ServiceFieldNames} ) {
        my $DynamicFieldConfig = $Self->{DynamicField}{$FieldName};
        next FIELDNAME if !IsHashRefWithData($DynamicFieldConfig);
        next FIELDNAME if $Param{Visibility} && !$Param{Visibility}{"DynamicField_$FieldName"};

        my $Value = $Param{DynamicFieldValues}->{ $DynamicFieldConfig->{Name} };
        next FIELDNAME if !defined $Value;
        next FIELDNAME if ref $Value eq 'ARRAY' && !@{$Value};
        next FIELDNAME if !ref $Value && $Value eq '';

        if ( ( $DynamicFieldConfig->{FieldType} || '' ) eq 'Set' ) {
            my $SetSnapshot = $Self->_ServiceExtensionSetSnapshotBuild(
                DynamicFieldConfig  => $DynamicFieldConfig,
                DynamicFieldObject  => $DynamicFieldObject,
                BackendObject       => $BackendObject,
                LayoutObject        => $LayoutObject,
                HTMLOutput          => $Param{HTMLOutput} ? 1 : 0,
                Value               => $Value,
            );
            next FIELDNAME if !$SetSnapshot;

            push @Rows, {
                Label => $DynamicFieldConfig->{Label} || $FieldName,
                Value => $SetSnapshot,
                IsSet => 1,
            };
            next FIELDNAME;
        }

        my $RenderedValue = $Self->_ServiceExtensionDisplayValueRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            BackendObject      => $BackendObject,
            LayoutObject       => $LayoutObject,
            HTMLOutput         => $Param{HTMLOutput} ? 1 : 0,
        );
        next FIELDNAME if !defined $RenderedValue || $RenderedValue eq '';

        push @Rows, {
            Label => $DynamicFieldConfig->{Label} || $FieldName,
            Value => $RenderedValue,
        };
    }

    return if !@Rows;

    my $Title = $LayoutObject->{LanguageObject}->Translate('Submitted Details');

    if ( $Param{HTMLOutput} ) {
        my $TitleHTML = $LayoutObject->Ascii2Html( Text => $Title );
        my $Snapshot  = '<div class="ZTSMSubmissionSnapshot"><h3>' . $TitleHTML . '</h3>';

        ROW:
        for my $Row (@Rows) {
            if ( $Row->{IsSet} ) {
                my $Label = $LayoutObject->Ascii2Html( Text => $LayoutObject->{LanguageObject}->Translate( $Row->{Label} ) );
                $Snapshot .= '<h4>' . $Label . '</h4>' . $Row->{Value};
                next ROW;
            }

            my $Label = $LayoutObject->Ascii2Html( Text => $LayoutObject->{LanguageObject}->Translate( $Row->{Label} ) );
            $Snapshot .= '<table><tr><th style="text-align:left;vertical-align:top;padding-right:1em;">'
                . $Label
                . '</th><td>'
                . $Row->{Value}
                . '</td></tr></table>';
        }

        $Snapshot .= '</div>';
        return $Snapshot;
    }

    my $Snapshot = $Title . "\n" . ( '-' x length $Title ) . "\n";
    ROW:
    for my $Row (@Rows) {
        $Snapshot .= $LayoutObject->{LanguageObject}->Translate( $Row->{Label} ) . ': ' . $Row->{Value} . "\n";
    }

    return $Snapshot;
}

sub _ServiceExtensionDisplayValueRender {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $Value              = $Param{Value};
    my $LayoutObject       = $Param{LayoutObject};
    my $HTMLOutput         = $Param{HTMLOutput} ? 1 : 0;

    if ( ( $DynamicFieldConfig->{FieldType} || '' ) eq 'ConfigItem'
        || ( $DynamicFieldConfig->{FieldType} || '' ) eq 'GovernanceObject' )
    {
        my $ConfigItemValue = $Self->_ServiceExtensionGovernanceObjectValueRender(
            Value        => $Value,
            LayoutObject => $LayoutObject,
            HTMLOutput   => $HTMLOutput,
        );
        return $ConfigItemValue if defined $ConfigItemValue && $ConfigItemValue ne '';
    }

    my $Rendered = $Param{BackendObject}->DisplayValueRender(
        DynamicFieldConfig => $DynamicFieldConfig,
        Value              => $Value,
        LayoutObject       => $LayoutObject,
        HTMLOutput         => $HTMLOutput,
    );
    return if !IsHashRefWithData($Rendered);
    return if !defined $Rendered->{Value} || $Rendered->{Value} eq '';

    return $Rendered->{Value};
}

sub _ServiceExtensionGovernanceObjectValueRender {
    my ( $Self, %Param ) = @_;

    my @Values = ref $Param{Value} eq 'ARRAY' ? @{ $Param{Value} } : ( $Param{Value} );
    my @Display;

    VALUE:
    for my $Value (@Values) {
        next VALUE if !defined $Value || $Value eq '';

        my $Display = $Self->_ServiceExtensionGovernanceObjectDisplayName(
            Value => $Value,
        );
        next VALUE if !$Display;

        if ( $Param{HTMLOutput} ) {
            $Display = $Param{LayoutObject}->Ascii2Html( Text => $Display );
        }

        push @Display, $Display;
    }

    return if !@Display;
    return join( $Param{HTMLOutput} ? '<br />' : "\n", @Display );
}

sub _ServiceExtensionGovernanceObjectDisplayName {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    return if !defined $Value || $Value eq '';

    return $Value if $Value !~ m{\A\d+\z};

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    for my $GetParam (
        { GovernanceObjectID => $Value },
        { VersionID    => $Value },
        )
    {
        my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
            %{$GetParam},
            DynamicFields => 0,
            Silent        => 1,
        );

        next if !IsHashRefWithData($GovernanceObject);
        next if !$GovernanceObject->{Name};

        return $Value . ' - ' . $GovernanceObject->{Name};
    }

    return $Value;
}

sub _ServiceExtensionSetSnapshotBuild {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $Value              = $Param{Value};
    return if ref $Value ne 'ARRAY' || !@{$Value};

    my @FieldOrder = $Self->_ServiceExtensionSetFieldOrder(
        Include => $DynamicFieldConfig->{Config}{Include},
    );
    return if !@FieldOrder;

    my @FieldConfig;
    FIELD:
    for my $FieldName (@FieldOrder) {
        my $IncludedFieldConfig = $Self->{DynamicField}{$FieldName}
            || $Param{DynamicFieldObject}->DynamicFieldGet(
                Name => $FieldName,
            );
        next FIELD if !IsHashRefWithData($IncludedFieldConfig);

        push @FieldConfig, {
            Name   => $FieldName,
            Config => $IncludedFieldConfig,
            Label  => $IncludedFieldConfig->{Label} || $FieldName,
        };
    }
    return if !@FieldConfig;

    my @Rows;
    SETROW:
    for my $SetRow ( @{$Value} ) {
        next SETROW if ref $SetRow ne 'HASH';

        my @Cells;
        my $HasValue;
        FIELD:
        for my $Field (@FieldConfig) {
            my $CellValue = $SetRow->{ $Field->{Name} };
            my $RenderedValue = '';

            if ( defined $CellValue && !( ref $CellValue eq 'ARRAY' && !@{$CellValue} ) && !( !ref $CellValue && $CellValue eq '' ) ) {
                $RenderedValue = $Self->_ServiceExtensionDisplayValueRender(
                    DynamicFieldConfig => $Field->{Config},
                    Value              => $CellValue,
                    BackendObject      => $Param{BackendObject},
                    LayoutObject       => $Param{LayoutObject},
                    HTMLOutput         => $Param{HTMLOutput} ? 1 : 0,
                ) || '';
            }

            $HasValue ||= $RenderedValue ne '';
            push @Cells, $RenderedValue;
        }

        next SETROW if !$HasValue;
        push @Rows, \@Cells;
    }
    return if !@Rows;

    if ( $Param{HTMLOutput} ) {
        my $HTML = '<table style="border-collapse:collapse;width:100%;margin-bottom:1em;"><thead><tr>';
        for my $Field (@FieldConfig) {
            $HTML .= '<th style="text-align:left;vertical-align:top;border:1px solid #d9d9d9;padding:6px 8px;">'
                . $Param{LayoutObject}->Ascii2Html( Text => $Param{LayoutObject}->{LanguageObject}->Translate( $Field->{Label} ) )
                . '</th>';
        }
        $HTML .= '</tr></thead><tbody>';

        for my $Row (@Rows) {
            $HTML .= '<tr>';
            for my $Cell (@{$Row}) {
                $HTML .= '<td style="vertical-align:top;border:1px solid #d9d9d9;padding:6px 8px;">'
                    . ( $Cell || '&nbsp;' )
                    . '</td>';
            }
            $HTML .= '</tr>';
        }

        $HTML .= '</tbody></table>';
        return $HTML;
    }

    my $Text = join( "\t", map { $Param{LayoutObject}->{LanguageObject}->Translate( $_->{Label} ) } @FieldConfig ) . "\n";
    for my $Row (@Rows) {
        $Text .= join( "\t", @{$Row} ) . "\n";
    }

    return $Text;
}

sub _ServiceExtensionSetFieldOrder {
    my ( $Self, %Param ) = @_;

    my $Include = $Param{Include};
    return if ref $Include ne 'ARRAY';

    my @FieldOrder;
    ITEM:
    for my $IncludeItem ( @{$Include} ) {
        next ITEM if ref $IncludeItem ne 'HASH';

        if ( IsHashRefWithData( $IncludeItem->{Grid} ) && IsArrayRefWithData( $IncludeItem->{Grid}{Rows} ) ) {
            ROW:
            for my $Row ( @{ $IncludeItem->{Grid}{Rows} } ) {
                next ROW if ref $Row ne 'ARRAY';

                FIELD:
                for my $Field (@{$Row}) {
                    next FIELD if ref $Field ne 'HASH' || !$Field->{DF};
                    push @FieldOrder, $Field->{DF};
                }
            }
        }
        elsif ( $IncludeItem->{DF} ) {
            push @FieldOrder, $IncludeItem->{DF};
        }
    }

    return @FieldOrder;
}

sub _GetServices {
    my ( $Self, %Param ) = @_;

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || 1;

    # get service
    my %Service;

    # check needed
    return \%Service if !$Param{QueueID} && !$Param{TicketID};

    # get options for default services for unknown customers
    my $DefaultServiceUnknownCustomer = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::Default::UnknownCustomer');

    # get service list
    if ( $Param{CustomerUserID} || $DefaultServiceUnknownCustomer ) {
        %Service = $Kernel::OM->Get('Kernel::System::Ticket')->TicketServiceList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );
    }
    return \%Service;
}

sub _GetSLAs {
    my ( $Self, %Param ) = @_;

    # use default Queue if none is provided
    $Param{QueueID} = $Param{QueueID} || 1;

    # get services if they were not determined in an AJAX call
    if ( !defined $Param{Services} ) {
        $Param{Services} = $Self->_GetServices(%Param);
    }

    # get sla
    my %SLA;
    if ( $Param{ServiceID} && $Param{Services} && %{ $Param{Services} } ) {
        if ( $Param{Services}->{ $Param{ServiceID} } ) {
            %SLA = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSLAList(
                %Param,
                Action         => $Self->{Action},
                CustomerUserID => $Self->{UserID},
            );
        }
    }
    return \%SLA;
}

sub _GetTos {
    my ( $Self, %Param ) = @_;

    # check own selection
    my %NewTos = ( '', '-' );
    my $Module = $Kernel::OM->Get('Kernel::Config')->Get('CustomerPanel::NewTicketQueueSelectionModule')
        || 'Kernel::Output::HTML::CustomerNewTicket::QueueSelectionGeneric';
    if ( $Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
        my $Object = $Module->new(
            %{$Self},
            SystemAddress => $Kernel::OM->Get('Kernel::System::SystemAddress'),
            Debug         => $Self->{Debug},
        );

        # log loaded module
        if ( $Self->{Debug} && $Self->{Debug} > 1 ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'debug',
                Message  => "Module: $Module loaded!",
            );
        }
        %NewTos = (
            $Object->Run(
                Env       => $Self,
                ACLParams => \%Param
            ),
            ( '', => '-' )
        );
    }
    else {
        return $Kernel::OM->Get('Kernel::Output::HTML::Layout')->FatalDie(
            Message => "Could not load $Module!",
        );
    }

    return \%NewTos;
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    $Param{FormID} = $Self->{FormID};
    $Param{Errors}->{QueueInvalid} = $Param{Errors}->{QueueInvalid} || '';

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get list type
    my $TreeView = 0;
    if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
        $TreeView = 1;
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Config       = $ConfigObject->Get("Ticket::Frontend::$Self->{Action}");

    if ( $Config->{Queue} ) {

        # check own selection
        my %NewTos = ( '', '-' );
        my $Module = $ConfigObject->Get('CustomerPanel::NewTicketQueueSelectionModule')
            || 'Kernel::Output::HTML::CustomerNewTicket::QueueSelectionGeneric';
        if ( $Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
            my $Object = $Module->new(
                %{$Self},
                SystemAddress => $Kernel::OM->Get('Kernel::System::SystemAddress'),
                Debug         => $Self->{Debug},
            );

            # log loaded module
            if ( $Self->{Debug} && $Self->{Debug} > 1 ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'debug',
                    Message  => "Module: $Module loaded!",
                );
            }
            %NewTos = (
                $Object->Run(
                    Env       => $Self,
                    ACLParams => \%Param
                ),
                ( '', => '-' )
            );
        }
        else {
            return $LayoutObject->FatalError();
        }

        # build to string
        if (%NewTos) {
            for ( sort keys %NewTos ) {
                $NewTos{"$_||$NewTos{$_}"} = $NewTos{$_};
                delete $NewTos{$_};
            }
        }

        $Param{ToStrg} = $LayoutObject->AgentQueueListOption(
            Data       => \%NewTos,
            Multiple   => 0,
            Size       => 0,
            Name       => 'Dest',
            Class      => "Validate_Required Modernize FormUpdate " . $Param{Errors}->{QueueInvalid},
            SelectedID => $Param{ToSelected} || $Param{QueueID},
            TreeView   => $TreeView,
        );

        $LayoutObject->Block(
            Name => 'Queue',
            Data => {
                %Param,
                QueueInvalid => $Param{Errors}->{QueueInvalid},
            },
        );

    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get priority
    if ( $Config->{Priority} ) {
        my %Priorities = $TicketObject->TicketPriorityList(
            %Param,
            CustomerUserID => $Self->{UserID},
            Action         => $Self->{Action},
        );

        # build priority string
        my %PrioritySelected;
        if ( $Param{PriorityID} ) {
            $PrioritySelected{SelectedID} = $Param{PriorityID};
        }
        else {
            $PrioritySelected{SelectedValue} = $Config->{PriorityDefault} || '3 normal';
        }
        $Param{PriorityStrg} = $LayoutObject->BuildSelection(
            Data  => \%Priorities,
            Name  => 'PriorityID',
            Class => 'Modernize FormUpdate',
            %PrioritySelected,
        );
        $LayoutObject->Block(
            Name => 'Priority',
            Data => \%Param,
        );
    }

    # types
    if ( $ConfigObject->Get('Ticket::Type') && $Config->{'TicketType'} ) {
        my %Type = $TicketObject->TicketTypeList(
            %Param,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );

        $Self->_ZTSMRequestTypesFilter( Type => \%Type );

        if ( $Config->{'TicketTypeDefault'} && !$Param{TypeID} ) {
            my %ReverseType = reverse %Type;
            $Param{TypeID} = $ReverseType{ $Config->{'TicketTypeDefault'} };
        }

# Rother OSS / ServiceCatalog
        elsif ( $Param{ServiceData}{TypeID} && $Param{TypeID} && $Type{ $Param{TypeID} }
            && ( $Param{TypeID} eq $Param{ServiceData}{TypeID} ) ) {

            %Type = (
                $Param{TypeID} => $Type{ $Param{TypeID} },
            );
        }
# EO ServiceCatalog

        $Param{TypeStrg} = $LayoutObject->BuildSelection(
            Data         => \%Type,
            Name         => 'TypeID',
            SelectedID   => $Param{TypeID},
            PossibleNone => 1,
            Sort         => 'AlphanumericValue',
            Translation  => 1,
            Class        => "Validate_Required Modernize FormUpdate " . ( $Param{Errors}->{TypeIDInvalid} || '' ),
        );
        $LayoutObject->Block(
            Name => 'TicketType',
            Data => {
                %Param,
                TypeIDInvalid => $Param{Errors}->{TypeIDInvalid},
            }
        );
    }

    # services
    if ( $ConfigObject->Get('Ticket::Service') && $Config->{Service} ) {

        # use either the real QueueID, or the TicketID, or 1 as QueueID
        my $TmpQueueID = $Param{QueueID} ? $Param{QueueID} :
            $Param{TicketID} ? undef : 1;

        my %Services = $TicketObject->TicketServiceList(
            %Param,
            QueueID        => $TmpQueueID,
            Action         => $Self->{Action},
            CustomerUserID => $Self->{UserID},
        );

# Rother OSS / ServiceCatalog
        if ( $Param{ServiceData}{ServiceID} && $Param{ServiceID} && $Services{ $Param{ServiceID} }
            && ( $Param{ServiceID} eq $Param{ServiceData}{ServiceID} ) ) {

            %Services = (
                $Param{ServiceID} => $Services{ $Param{ServiceID} },
            );
        }
# EO ServiceCatalog

        $Param{ServiceStrg} = $LayoutObject->BuildSelection(
            Data       => \%Services,
            Name       => 'ServiceID',
            SelectedID => $Param{ServiceID},
            Class      => 'Modernize FormUpdate '
                . ( $Config->{ServiceMandatory} ? 'Validate_Required ' : '' )
                . ( $Param{Errors}->{ServiceIDInvalid} || '' ),
            PossibleNone => 1,
            TreeView     => $TreeView,
            Sort         => 'TreeView',
            Translation  => $TreeView,
            Max          => 200,
        );
        $LayoutObject->Block(
            Name => 'TicketService',
            Data => {
                ServiceMandatory => $Config->{ServiceMandatory} || 0,
                %Param,
            },
        );

        # reset previous ServiceID to reset SLA-List if no service is selected
        if ( !$Services{ $Param{ServiceID} || '' } ) {
            $Param{ServiceID} = '';
        }
        my %SLA;
        if ( $Config->{SLA} ) {
            if ( $Param{ServiceID} ) {
                %SLA = $TicketObject->TicketSLAList(
                    QueueID => 1,    # use default QueueID if none is provided in %Param
                    %Param,
                    Action         => $Self->{Action},
                    CustomerUserID => $Self->{UserID},
                );
            }

            $Param{SLAStrg} = $LayoutObject->BuildSelection(
                Data       => \%SLA,
                Name       => 'SLAID',
                SelectedID => $Param{SLAID},
                Class      => 'Modernize FormUpdate '
                    . ( $Config->{SLAMandatory} ? 'Validate_Required ' : '' )
                    . ( $Param{Errors}->{SLAInvalid} || '' ),
                PossibleNone => 1,
                Sort         => 'AlphanumericValue',
                Translation  => 1,
                Max          => 200,
            );
            $LayoutObject->Block(
                Name => 'TicketSLA',
                Data => {
                    SLAMandatory => $Config->{SLAMandatory} || 0,
                    %Param,
                }
            );
        }
    }

    # prepare errors
    if ( $Param{Errors} ) {
        for ( sort keys %{ $Param{Errors} } ) {
            $Param{$_} = $Param{Errors}->{$_};
        }
    }

    # render dynamic fields
    $Param{DynamicFieldHTML} = $Self->_ServiceExtensionDynamicFieldHTMLBuild(
        LayoutObject         => $LayoutObject,
        ParamObject          => $Kernel::OM->Get('Kernel::System::Web::Request'),
        DynamicFieldValues   => $Param{DynamicField},
        PossibleValuesFilter => $Param{DFPossibleValues},
        Errors               => $Param{DFErrors},
        Visibility           => $Param{Visibility},
        ServiceID            => $Param{ServiceID},
    );

    if ( !$Param{VisibilityStd}{Article} ) {
        $Param{SubjectValidate}        = 'Validate_Required_IfVisible';
        $Param{BodyValidate}           = 'Validate_Required_IfVisible';
        $Param{SubjectHiddenClass}     = ' oooACLHidden';
        $Param{BodyHiddenClass}        = ' oooACLHidden';
        $Param{AttachmentsHiddenClass} = ' oooACLHidden';
    }

    else {
        $Param{SubjectValidate} = 'Validate_Required_IfVisible';
        $Param{BodyValidate}    = 'Validate_Required_IfVisible';
    }

    # show attachments
    ATTACHMENT:
    for my $Attachment ( @{ $Param{Attachments} } ) {
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

    # Permissions have been checked before in Run()
    if ( $Param{FromChatID} ) {
        my @ChatMessages = $Kernel::OM->Get('Kernel::System::Chat')->ChatMessageList(
            ChatID => $Param{FromChatID},
        );

        for my $Message (@ChatMessages) {
            $Message->{MessageText} = $LayoutObject->Ascii2Html(
                Text        => $Message->{MessageText},
                LinkFeature => 1,
            );
        }

        $LayoutObject->Block(
            Name => 'ChatArticlePreview',
            Data => {
                ChatMessages => \@ChatMessages,
            },
        );
    }

    if ( $Param{HideAutoselected} ) {

        # add Autoselect JS
        $LayoutObject->AddJSOnDocumentComplete(
            Code => "Core.Form.InitHideAutoselected({ FieldIDs: $Param{HideAutoselected} });",
        );
    }

    # explanatory message about asterisk
    if ( $ConfigObject->Get('Ticket::Frontend::AsteriskExplanation') ) {
        $LayoutObject->Block(
            Name => 'AsteriskExplanation',
        );
    }

    if ( IsHashRefWithData( $Self->{ZTSMServiceExtensionFields} ) ) {
        $LayoutObject->{HasDatepicker} = 1;
    }

    # get output back
    return $LayoutObject->Output(
        TemplateFile => 'CustomerTicketMessage',
        Data         => \%Param,
    );
}

1;
