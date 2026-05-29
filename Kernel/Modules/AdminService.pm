# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://ncs.com.sg
# --
# $origin: otobo - 6efdc7bf2a3325277cd79a60f0f2407f8ad59e87 - Kernel/Modules/AdminService.pm
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

package Kernel::Modules::AdminService;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;
# ---
# ITSMCore
# ---
use Kernel::System::VariableCheck qw(:all);
# ---

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # set pref for columns key
    $Self->{PrefKeyIncludeInvalid} = 'IncludeInvalid' . '-' . $Self->{Action};

    my %Preferences = $Kernel::OM->Get('Kernel::System::User')->GetPreferences(
        UserID => $Self->{UserID},
    );

    $Self->{IncludeInvalid} = $Preferences{ $Self->{PrefKeyIncludeInvalid} };

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    $Param{IncludeInvalid} = $ParamObject->GetParam( Param => 'IncludeInvalid' );

    if ( defined $Param{IncludeInvalid} ) {
        $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
            UserID => $Self->{UserID},
            Key    => $Self->{PrefKeyIncludeInvalid},
            Value  => $Param{IncludeInvalid},
        );

        $Self->{IncludeInvalid} = $Param{IncludeInvalid};
    }

# ---
# ITSMCore
# ---
    my $DynamicFieldObject   = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $ServiceDynamicFields = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Service'],
    ) || [];

    # get the dynamic field for ITSMCriticality
    my $DynamicFieldConfigArrayRef = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Ticket' ],
        FieldFilter => {
            ITSMCriticality => 1,
        },
    );

    # get the dynamic field value for ITSMCriticality
    my %PossibleValues;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $DynamicFieldConfigArrayRef } ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # get PossibleValues
        $PossibleValues{ $DynamicFieldConfig->{Name} } = $DynamicFieldConfig->{Config}->{PossibleValues} || {};
    }

    # set the criticality list
    $Self->{CriticalityList} = $PossibleValues{ITSMCriticality};
# ---

    # ------------------------------------------------------------ #
    # service edit
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ServiceEdit' ) {

        # header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # html output
        $Output .= $Self->_MaskNew(
            %Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # service save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ServiceSave' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        # get params
        my %GetParam;
# ---
# ITSMCore
# ---
#        for (qw(ServiceID ParentID Name ValidID Comment)) {
        for (qw(ServiceID ParentID Name ValidID Comment TypeID Criticality)) {
# ---
            $GetParam{$_} = $ParamObject->GetParam( Param => $_ ) || '';
        }

        my %Error;
        my %DynamicFieldValues;
        my %DynamicFieldErrors;

        if ( !$GetParam{Name} ) {
            $Error{'NameInvalid'} = 'ServerError';
        }
        if ( !$GetParam{TypeID} ) {
            $Error{'TypeIDInvalid'} = 'ServerError';
        }

        my $ServiceName = '';
        if ( $GetParam{ParentID} ) {
            my $Prefix = $ServiceObject->ServiceLookup(
                ServiceID => $GetParam{ParentID},
            );

            if ($Prefix) {
                $ServiceName = $Prefix . "::";
            }
        }
        $ServiceName .= $GetParam{Name};

        if ( length $ServiceName > 200 ) {
            $Error{'NameInvalid'} = 'ServerError';
            $Error{LongName}      = 1;
        }

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$ServiceDynamicFields} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $ValidationResult = $DynamicFieldBackendObject->EditFieldValueValidate(
                DynamicFieldConfig => $DynamicFieldConfig,
                ParamObject        => $ParamObject,
                Mandatory          => 0,
            );

            if ( $ValidationResult->{ServerError} ) {
                $DynamicFieldErrors{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $ValidationResult;
                next DYNAMICFIELD;
            }

            $DynamicFieldValues{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldValueGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ParamObject        => $ParamObject,
                LayoutObject       => $LayoutObject,
            );
        }
        if (%DynamicFieldErrors) {
            $Error{DynamicFieldErrors} = \%DynamicFieldErrors;
        }

        if ( !%Error ) {

            my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

            # save to database
            if ( $GetParam{ServiceID} eq 'NEW' ) {
                $GetParam{ServiceID} = $ServiceObject->ServiceAdd(
                    %GetParam,
                    UserID => $Self->{UserID},
                );
                if ( !$GetParam{ServiceID} ) {
                    $Error{Message} = $LogObject->GetLogEntry(
                        Type => 'Error',
                        What => 'Message',
                    );
                }
            }
            else {
                my $Success = $ServiceObject->ServiceUpdate(
                    %GetParam,
                    UserID => $Self->{UserID},
                );
                if ( !$Success ) {
                    $Error{Message} = $LogObject->GetLogEntry(
                        Type => 'Error',
                        What => 'Message',
                    );
                }
            }

            if ( !%Error ) {
                DYNAMICFIELD:
                for my $DynamicFieldConfig ( @{$ServiceDynamicFields} ) {
                    next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

                    my $ValueSet = $DynamicFieldBackendObject->ValueSet(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        ObjectID           => $GetParam{ServiceID},
                        Value              => $DynamicFieldValues{ 'DynamicField_' . $DynamicFieldConfig->{Name} },
                        UserID             => $Self->{UserID},
                    );

                    if ( !$ValueSet ) {
                        $Error{Message} = $LayoutObject->{LanguageObject}->Translate(
                            'Unable to set value for dynamic field %s!',
                            $DynamicFieldConfig->{Name},
                        );
                        last DYNAMICFIELD;
                    }
                }

                if ( !$Error{Message} ) {

                    # update preferences
                    my %ServiceData = $ServiceObject->ServiceGet(
                        ServiceID => $GetParam{ServiceID},
                        UserID    => $Self->{UserID},
                    );
                    my %Preferences = ();
                    if ( $ConfigObject->Get('ServicePreferences') ) {
                        %Preferences = %{ $ConfigObject->Get('ServicePreferences') };
                    }
                    for my $Item ( sort keys %Preferences ) {
                        my $Module = $Preferences{$Item}->{Module}
                            || 'Kernel::Output::HTML::ServicePreferences::Generic';

                        # load module
                        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
                            return $LayoutObject->FatalError();
                        }

                        my $Object = $Module->new(
                            %{$Self},
                            ConfigItem => $Preferences{$Item},
                            Debug      => $Self->{Debug},
                        );
                        my $Note;
                        my @Params = $Object->Param( ServiceData => \%ServiceData );
                        if (@Params) {
                            my %GetParam = ();
                            for my $ParamItem (@Params) {
                                my @Array = $ParamObject->GetArray( Param => $ParamItem->{Name} );
                                $GetParam{ $ParamItem->{Name} } = \@Array;
                            }
                            if (
                                !$Object->Run(
                                    GetParam    => \%GetParam,
                                    ServiceData => \%ServiceData
                                )
                            )
                            {
                                $Note .= $LayoutObject->Notify( Info => $Object->Error() );
                            }
                        }
                    }

                    # if the user would like to continue editing the service, just redirect to the edit screen
                    if (
                        defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                        && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                        )
                    {
                        my $ID = $ParamObject->GetParam( Param => 'ServiceID' ) || '';
                        return $LayoutObject->Redirect(
                            OP => "Action=$Self->{Action};Subaction=ServiceEdit;ServiceID=$ID"
                        );
                    }
                    else {

                        # otherwise return to overview
                        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
                    }
                }
            }
        }

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Error{Message}
            ? $LayoutObject->Notify(
                Priority => 'Error',
                Info     => $Error{Message},
            )
            : '';

        # html output
        $Output .= $Self->_MaskNew(
            %Error,
            %GetParam,
            %DynamicFieldValues,
            DynamicFieldErrors => \%DynamicFieldErrors,
            %Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------ #
    # service overview
    # ------------------------------------------------------------ #
    else {

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # check if service is enabled to use it here
        if ( !$ConfigObject->Get('Ticket::Service') ) {
            $Output .= $LayoutObject->Notify(
                Priority => 'Error',
                Data     => $LayoutObject->{LanguageObject}->Translate( "Please activate %s first!", "Service" ),
                Link     =>
                    $LayoutObject->{Baselink}
                    . 'Action=AdminSystemConfiguration;Subaction=View;Setting=Ticket%3A%3AService;',
            );
        }

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => { %Param, },
        );

        $LayoutObject->Block( Name => 'ActionList' );
        $LayoutObject->Block( Name => 'ActionAdd' );
        $LayoutObject->Block(
            Name => 'IncludeInvalid',
            Data => {
                IncludeInvalid        => $Self->{IncludeInvalid},
                IncludeInvalidChecked => $Self->{IncludeInvalid} ? 'checked' : '',
            },
        );
        $LayoutObject->Block( Name => 'Filter' );

        # output overview result
        $LayoutObject->Block(
            Name => 'OverviewList',
            Data => { %Param, },
        );

        # get service list
        my $ServiceList = $ServiceObject->ServiceListGet(
            Valid  => $Self->{IncludeInvalid} ? 0 : 1,
            UserID => $Self->{UserID},
        );

        # if there are any services defined, they are shown
        if ( @{$ServiceList} ) {

            # get valid list
            my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

            # sort the service list by long service name
            @{$ServiceList} = sort { $a->{Name} . '::' cmp $b->{Name} . '::' } @{$ServiceList};

            for my $ServiceData ( @{$ServiceList} ) {

                # output row
                $LayoutObject->Block(
                    Name => 'OverviewListRow',
                    Data => {
                        %{$ServiceData},
                        Valid => $ValidList{ $ServiceData->{ValidID} },
                    },
                );
            }

        }

        # otherwise a no data found msg is displayed
        else {
            $LayoutObject->Block(
                Name => 'NoDataFoundMsg',
                Data => {},
            );
        }

        # generate output
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminService',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
    return;
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
    my %ServiceData;

    # get params
    $ServiceData{ServiceID} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => "ServiceID" );
    if ( $ServiceData{ServiceID} ne 'NEW' ) {
        %ServiceData = $ServiceObject->ServiceGet(
            ServiceID => $ServiceData{ServiceID},
            UserID    => $Self->{UserID},
        );
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # output overview
    $LayoutObject->Block(
        Name => 'Overview',
        Data => {
            ServiceID   => $ServiceData{ServiceID},
            ServiceName => $ServiceData{Name},
            %Param,
        },
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get list type
    my $ListType = $ConfigObject->Get('Ticket::Frontend::ListType');

    # generate ParentOptionStrg
    my $KeepChildren = $ConfigObject->Get('Ticket::Service::KeepChildren') // 0;
    my %ServiceList  = $ServiceObject->ServiceList(
        Valid        => !$KeepChildren,
        KeepChildren => $KeepChildren,
        UserID       => $Self->{UserID},
    );
    $ServiceData{ParentOptionStrg} = $LayoutObject->BuildSelection(
        Data           => \%ServiceList,
        Name           => 'ParentID',
        SelectedID     => $Param{ParentID} || $ServiceData{ParentID},
        PossibleNone   => 1,
        TreeView       => ( $ListType eq 'tree' ) ? 1 : 0,
        DisabledBranch => $ServiceData{Name},
        Translation    => 0,
        Class          => 'Modernize',
    );
# ---
# ITSMCore
# ---
    # generate TypeOptionStrg
    my $TypeList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ITSM::Service::Type',
    );

    # build the type dropdown
    $ServiceData{TypeOptionStrg} = $LayoutObject->BuildSelection(
        Data       => $TypeList,
        Name       => 'TypeID',
        SelectedID => $Param{TypeID} || $ServiceData{TypeID},
        Class      => 'Modernize Validate_Required ' . ( $Param{TypeIDInvalid} || '' ),
    );

    # build the criticality dropdown
    $ServiceData{CriticalityOptionStrg} = $LayoutObject->BuildSelection(
        Data       => $Self->{CriticalityList},
        Name       => 'Criticality',
        SelectedID => $Param{Criticality} || $ServiceData{Criticality},
        Class      => 'Modernize',
    );
# ---

    # get valid list
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $ServiceData{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $ServiceData{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize',
    );

    # output service edit
    $LayoutObject->Block(
        Name => 'ServiceEdit',
        Data => { %Param, %ServiceData, },
    );

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ParamObject               = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ServiceDynamicFields      = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Service'],
    ) || [];
    my $DynamicFieldErrors = $Param{DynamicFieldErrors} || {};

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$ServiceDynamicFields} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $ParamName = 'DynamicField_' . $DynamicFieldConfig->{Name};

        my $Value;
        if ( exists $Param{$ParamName} ) {
            $Value = $Param{$ParamName};
        }
        elsif ( $ServiceData{ServiceID} && $ServiceData{ServiceID} ne 'NEW' ) {
            $Value = $DynamicFieldBackendObject->ValueGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ServiceData{ServiceID},
                UserID             => $Self->{UserID},
            );
        }

        my $DynamicFieldHTML = $DynamicFieldBackendObject->EditFieldRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            Mandatory          => 0,
            LayoutObject       => $LayoutObject,
            ParamObject        => $ParamObject,
            %{ $DynamicFieldErrors->{$ParamName} || {} },
        );

        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldHTML);

        my $FieldHTML = $DynamicFieldHTML->{Field};
        if ( !$FieldHTML && IsArrayRefWithData( $DynamicFieldHTML->{MultiValue} ) ) {
            $FieldHTML = join "\n", @{ $DynamicFieldHTML->{MultiValue} };
            $FieldHTML .= "\n" . ( $DynamicFieldHTML->{MultiValueTemplate} || '' );
        }

        if ( !$FieldHTML && ( $DynamicFieldConfig->{FieldType} || '' ) eq 'Text' ) {
            my $FieldName = 'DynamicField_' . $DynamicFieldConfig->{Name};
            my @Values    = ref $Value eq 'ARRAY' ? @{$Value} : ( $Value // '' );

            @Values = ('') if !@Values;
            push @Values, '' if $DynamicFieldConfig->{Config}->{MultiValue};

            my $Index = 0;
            $FieldHTML = join "\n", map {
                my $FieldID = $DynamicFieldConfig->{Config}->{MultiValue} ? $FieldName . '_' . $Index++ : $FieldName;
                my $Escaped = $LayoutObject->Ascii2Html( Text => $_ // '' );
                '<input type="text" class="DynamicFieldText W50pc" id="' . $FieldID . '" name="' . $FieldName . '" value="' . $Escaped . '" />'
            } @Values;
        }

        $LayoutObject->Block(
            Name => 'AdminServiceDynamicField',
            Data => {
                Name  => $DynamicFieldConfig->{Name},
                Label => $DynamicFieldHTML->{Label},
                Field => $FieldHTML,
            },
        );
    }

    # show each preferences setting
    my %Preferences = ();
    if ( $ConfigObject->Get('ServicePreferences') ) {
        %Preferences = %{ $ConfigObject->Get('ServicePreferences') };
    }
    for my $Item ( sort keys %Preferences ) {
        my $Module = $Preferences{$Item}->{Module}
            || 'Kernel::Output::HTML::ServicePreferences::Generic';

        # load module
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
            return $LayoutObject->FatalError();
        }
        my $Object = $Module->new(
            %{$Self},
            ConfigItem => $Preferences{$Item},
            Debug      => $Self->{Debug},
        );
        my @Params = $Object->Param( ServiceData => \%ServiceData );
        if (@Params) {
            for my $ParamItem (@Params) {
                $LayoutObject->Block(
                    Name => 'Item',
                    Data => { %Param, },
                );
                if (
                    ref( $ParamItem->{Data} ) eq 'HASH'
                    || ref( $Preferences{$Item}->{Data} ) eq 'HASH'
                    )
                {
                    my %BuildSelectionParams = (
                        %{ $Preferences{$Item} },
                        %{$ParamItem},
                    );
                    $BuildSelectionParams{Class} = join( ' ', $BuildSelectionParams{Class} // '', 'Modernize' );

                    $ParamItem->{'Option'} = $LayoutObject->BuildSelection(
                        %BuildSelectionParams,
                    );
                }
                $LayoutObject->Block(
                    Name => $ParamItem->{Block} || $Preferences{$Item}->{Block} || 'Option',
                    Data => {
                        %{ $Preferences{$Item} },
                        %{$ParamItem},
                    },
                );
            }
        }
    }

    # generate output
    return $LayoutObject->Output(
        TemplateFile => 'AdminService',
        Data         => \%Param
    );
}

1;
