# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Modules::AgentFAQAdd;

use strict;
use warnings;

use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {%Param};
    bless( $Self, $Type );

    # Get config of frontend module.
    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get("FAQ::Frontend::$Self->{Action}") || '';

    # Get the dynamic fields for this screen.
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => 'FAQ',
        FieldFilter => $Self->{Config}->{DynamicField} || {},
    );

    $Self->{DynamicField} = {};

    # create dynamic field hash and definition
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $DynamicFieldList // [] } ) {
        next DYNAMICFIELD unless IsHashRefWithData($DynamicFieldConfig);

        push $Self->{MaskDefinition}->@*, {
            DF        => $DynamicFieldConfig->{Name},
            Mandatory => $Self->{Config}->{DynamicField}{ $DynamicFieldConfig->{Name} } == 2 ? 1 : 0,
        };

        if ( $Self->{Config}->{DynamicField}{ $DynamicFieldConfig->{Name} } == 2 ) {
            $DynamicFieldConfig->{Mandatory} = 1;
        }

        $Self->{DynamicField}{ $DynamicFieldConfig->{Name} } = $DynamicFieldConfig;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Permission check.
    if ( !$Self->{AccessRw} ) {
        return $LayoutObject->NoPermission(
            Message    => Translatable('You need rw permission!'),
            WithHeader => 'yes',
        );
    }

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # Get parameters from web request.
    my %GetParam;
    for my $ParamName (
        qw(Title CategoryID StateID LanguageID ValidID Keywords Approved Field1 Field2 Field3 Field4 Field5 Field6)
        )
    {
        $GetParam{$ParamName} = $ParamObject->GetParam( Param => $ParamName );
    }

    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');

    # Get categories (with category long names) where user has rights.
    my $UserCategoriesLongNames = $FAQObject->GetUserCategoriesLongNames(
        Type   => 'rw',
        UserID => $Self->{UserID},
    );

    # Check that there are categories available for this user.
    if (
        !$UserCategoriesLongNames
        || ref $UserCategoriesLongNames ne 'HASH'
        || !%{$UserCategoriesLongNames}
        )
    {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No categories found where user has read/write permissions!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # Get dynamic field values form http request.
    my %DynamicFieldValues;

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( values $Self->{DynamicField}->%* ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # Extract the dynamic field value form the web request.
        $DynamicFieldValues{ $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
        );
    }

    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    # get form id
    my $FormID = $Kernel::OM->Get('Kernel::System::Web::FormCache')->PrepareFormID(
        ParamObject  => $ParamObject,
        LayoutObject => $LayoutObject,
    );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # set content type
    my $ContentType = 'text/plain';
    if ( $LayoutObject->{BrowserRichText} && $ConfigObject->Get('FAQ::Item::HTML') ) {
        $ContentType = 'text/html';
    }

    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # ------------------------------------------------------------ #
    # Show the FAQ add screen.
    # ------------------------------------------------------------ #
    if ( !$Self->{Subaction} ) {

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        if ( $ConfigObject->Get('FAQ::ApprovalRequired') ) {

            # Get Approval queue name.
            my $ApprovalQueue = $ConfigObject->Get('FAQ::ApprovalQueue') || '';

            # Check if Approval queue exists.
            my $ApprovalQueueID = $QueueObject->QueueLookup(
                Queue => $ApprovalQueue,
            );

            # Show notification if Approval queue does not exists.
            if ( !$ApprovalQueueID ) {
                $Output .= $LayoutObject->Notify(
                    Priority => 'Error',
                    Info     => "FAQ Approval is enabled but queue '$ApprovalQueue' does not exists",
                    Link     => $LayoutObject->{Baselink}
                        . 'Action=AdminSystemConfiguration;Subaction=ViewCustomGroup;Names=FAQ::ApprovalQueue',
                );
            }
        }

        $Output .= $Self->_MaskNew(
            FormID                  => $FormID,
            UserCategoriesLongNames => $UserCategoriesLongNames,
            DynamicField            => \%DynamicFieldValues,

            # Last viewed category from session (written by FAQ explorer).
            CategoryID  => $Self->{Session}{LastViewedCategory},
            ContentType => $ContentType,
        );

        # footer
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # Save the FAQ.
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Save' ) {

        # Challenge token check for write action.
        $LayoutObject->ChallengeTokenCheck();

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        my %Error;
        for my $ParamName (qw(Title CategoryID)) {

            # If required field is not given, add server error class.
            if ( !$GetParam{$ParamName} ) {
                $Error{ $ParamName . 'ServerError' } = 'ServerError';
            }
        }

        if ( $ConfigObject->Get('FAQ::Service') ) {
            my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

            # get all services
            my %ServiceList = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
                KeepChildren => $ConfigObject->Get('Ticket::Service::KeepChildren') // 0,
                Valid        => 1,
                UserID       => $Self->{UserID},
            );

            my @ServiceIDs;
            if ( $ParamObject->GetArray( Param => 'ServiceID' ) ) {
                @ServiceIDs = $ParamObject->GetArray( Param => 'ServiceID' );
            }
            $GetParam{ServiceID}   = \@ServiceIDs;
            $GetParam{ServiceList} = \%ServiceList;
        }

        # store dynamic field validation results
        my %DynamicFieldValidationResult;

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Self->{DynamicField}->%* ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $ValidationResult = $DynamicFieldBackendObject->EditFieldValueValidate(
                DynamicFieldConfig => $DynamicFieldConfig,
                ParamObject        => $ParamObject,
                Mandatory          =>
                    $Self->{Config}->{DynamicField}->{ $DynamicFieldConfig->{Name} } == 2,
            );

            if ( !IsHashRefWithData($ValidationResult) ) {
                return $LayoutObject->ErrorScreen(
                    Message => $LayoutObject->{LanguageObject}->Translate(
                        'Could not perform validation on field %s!',
                        $DynamicFieldConfig->{Label},
                    ),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }

            # Propagate validation error to the Error variable to be detected by the frontend.
            if ( $ValidationResult->{ServerError} ) {
                $Error{ $DynamicFieldConfig->{Name} }                        = ' ServerError';
                $DynamicFieldValidationResult{ $DynamicFieldConfig->{Name} } = $ValidationResult;
            }
        }

        # Send server error if any required parameter is missing.
        if (%Error) {

            # Get all attachments meta data.
            my @Attachments = $UploadCacheObject->FormIDGetAllFilesMeta(
                FormID => $FormID,
            );

            if ( $ConfigObject->Get('FAQ::ApprovalRequired') ) {

                my $ApprovalQueue = $ConfigObject->Get('FAQ::ApprovalQueue') || '';

                # Check if Approval queue exists.
                my $ApprovalQueueID = $QueueObject->QueueLookup(
                    Queue => $ApprovalQueue,
                );

                # Show notification if Approval queue does not exists.
                if ( !$ApprovalQueueID ) {
                    $Output .= $LayoutObject->Notify(
                        Priority => 'Error',
                        Info     =>
                            "FAQ Approval is enabled but queue '$ApprovalQueue' does not exists",
                        Link => $LayoutObject->{Baselink}
                            . 'Action=AdminSystemConfiguration;Subaction=ViewCustomGroup;Names=FAQ::ApprovalQueue',
                    );
                }
            }

            $Output .= $Self->_MaskNew(
                UserCategoriesLongNames => $UserCategoriesLongNames,
                Attachments             => \@Attachments,
                %GetParam,
                %Error,
                FormID       => $FormID,
                DynamicField => \%DynamicFieldValues,
                DFErrors     => \%DynamicFieldValidationResult,
                ContentType  => $ContentType,
            );

            $Output .= $LayoutObject->Footer();

            return $Output;
        }

        # Add the new FAQ item.
        my $ItemID = $FAQObject->FAQAdd(
            %GetParam,
            ContentType => $ContentType,
            UserID      => $Self->{UserID},
        );

        # Show error if FAQ item could not be added.
        if ( !$ItemID ) {
            return $LayoutObject->ErrorScreen();
        }

        # Get all attachments from upload cache.
        my @Attachments = $UploadCacheObject->FormIDGetAllFilesData(
            FormID => $FormID,
        );

        # Write attachments
        ATTACHMENT:
        for my $Attachment (@Attachments) {

            # Check if attachment is an inline attachment.
            my $Inline = 0;
            if ( $Attachment->{ContentID} ) {

                # Remember that it is inline.
                $Inline = 1;

                # Remember if this inline attachment is used in any FAQ article.
                my $ContentIDFound;

                # Check all fields for content-id.
                FIELD:
                for my $Number ( 1 .. 6 ) {

                    my $Field = $GetParam{ 'Field' . $Number };

                    # Skip empty fields.
                    next FIELD if !$Field;

                    # Skip fields that do not contain the content-id.
                    next FIELD if $Field !~ m{ $Attachment->{ContentID} }xms;

                    $ContentIDFound = 1;
                    last FIELD;
                }

                # We do not want to keep this attachment, because it was deleted in the rich-text editor
                next ATTACHMENT if !$ContentIDFound;
            }

            my $FileID = $FAQObject->AttachmentAdd(
                %{$Attachment},
                ItemID => $ItemID,
                Inline => $Inline,
                UserID => $Self->{UserID},
            );
            if ( !$FileID ) {
                return $LayoutObject->FatalError();
            }

            next ATTACHMENT if !$Inline;
            next ATTACHMENT if !$LayoutObject->{BrowserRichText};

            # Rewrite the URLs of the inline images for the uploaded pictures.
            my $Success = $FAQObject->FAQInlineAttachmentURLUpdate(
                Attachment => $Attachment,
                FormID     => $FormID,
                ItemID     => $ItemID,
                FileID     => $FileID,
                UserID     => $Self->{UserID},
            );
            if ( !$Success ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Could not update the inline image URLs for FAQ Item# '$ItemID'!",
                );
            }
        }

        # remove all form data
        $Kernel::OM->Get('Kernel::System::Web::FormCache')->FormIDRemove( FormID => $FormID );

        # Set dynamic fields.
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( values $Self->{DynamicField}->%* ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $Success = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ItemID,
                Value              => $DynamicFieldValues{ $DynamicFieldConfig->{Name} },
                UserID             => $Self->{UserID},
            );
        }

        # Redirect to FAQ zoom.
        return $LayoutObject->Redirect( OP => 'Action=AgentFAQZoom;ItemID=' . $ItemID );
    }
}

sub _MaskNew {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Get list type.
    my $TreeView = 0;
    if ( $ConfigObject->Get('Ticket::Frontend::ListType') eq 'tree' ) {
        $TreeView = 1;
    }

    # Get valid list.
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    my %Data;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Build valid selection.
    $Data{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize',
    );

    # Set no server error class as default.
    $Param{CategoryIDServerError} ||= '';

    # Build category selection.
    $Data{CategoryOption} = $LayoutObject->BuildSelection(
        Data         => $Param{UserCategoriesLongNames},
        Name         => 'CategoryID',
        SelectedID   => $Param{CategoryID},
        PossibleNone => 1,
        Class        => 'Validate_Required Modernize ' . $Param{CategoryIDServerError},
        Translation  => 0,
        TreeView     => 1,
    );

    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');

    my %Languages = $FAQObject->LanguageList(
        UserID => $Self->{UserID},
    );

    # Get the selected language.
    my $SelectedLanguage;
    if ( $Param{LanguageID} && $Languages{ $Param{LanguageID} } ) {

        # Get language from given LanguageID.
        $SelectedLanguage = $Languages{ $Param{LanguageID} };
    }
    else {

        # Use the user language, or if not found 'en'
        $SelectedLanguage = $LayoutObject->{UserLanguage} || 'en';

        # Get user LanguageID
        my $SelectedLanguageID = $FAQObject->LanguageLookup(
            Name => $SelectedLanguage,
        );

        # Check if LanduageID does not exists
        if ( !$SelectedLanguageID ) {

            # Get the lowest languageID from the FAQ languages list
            my @LanguageIDs = sort keys %Languages;
            $SelectedLanguageID = $LanguageIDs[0];

            # Set the language with lowest LanguageID as selected language,
            #   as this is the first and (we assumed) the most used language
            $SelectedLanguage = $Languages{$SelectedLanguageID};
        }
    }

    # Build the language selection.
    $Data{LanguageOption} = $LayoutObject->BuildSelection(
        Data          => \%Languages,
        Name          => 'LanguageID',
        SelectedValue => $SelectedLanguage,
        Translation   => 0,
        Class         => 'Modernize',
    );

    my @StateTypes = $ConfigObject->Get('FAQ::Agent::StateTypes');
    my %States     = $FAQObject->StateList(
        Types  => @StateTypes,
        UserID => $Self->{UserID},
    );

    # Get the selected state.
    my $SelectedState;
    if ( $Param{StateID} && $States{ $Param{StateID} } ) {

        # Get state from given StateID.
        $SelectedState = $States{ $Param{StateID} };
    }
    else {

        # Get default state.
        $SelectedState = $ConfigObject->Get('FAQ::Default::State') || 'internal (agent)';
    }

    # Build the state selection.
    $Data{StateOption} = $LayoutObject->BuildSelection(
        Data          => \%States,
        Name          => 'StateID',
        SelectedValue => $SelectedState,
        Translation   => 1,
        Class         => 'Modernize',
    );

    # Show attachments.
    ATTACHMENT:
    for my $Attachment ( @{ $Param{Attachments} } ) {

        # Do not show inline images as attachments (they have a ContentID).
        if ( $Attachment->{ContentID} && $LayoutObject->{BrowserRichText} ) {
            next ATTACHMENT;
        }

        push @{ $Param{AttachmentList} }, $Attachment;
    }

    # render dynamic fields
    $Param{DynamicFieldHTML} = $Kernel::OM->Get('Kernel::Output::HTML::DynamicField::Mask')->EditSectionRender(
        Content            => $Self->{MaskDefinition},
        DynamicFields      => $Self->{DynamicField},
        LayoutObject       => $LayoutObject,
        ParamObject        => $Kernel::OM->Get('Kernel::System::Web::Request'),
        DynamicFieldValues => $Param{DynamicField},
        Errors             => $Param{DFErrors},
        Object             => {
            UserID => $Self->{UserID},
            $Param{DynamicField}->%*,
        },
        AJAXUpdate => 0,
    );

    $LayoutObject->Block(
        Name => 'FAQAdd',
        Data => {
            %Param,
            %Data,
        },
    );

    # show services
    if ( $ConfigObject->Get('FAQ::Service') ) {

        # get all services
        my %ServiceList = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
            KeepChildren => $ConfigObject->Get('Ticket::Service::KeepChildren') // 0,
            Valid        => 1,
            UserID       => 1,
        );

        # get param object
        my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

        my @ServiceIDs;
        if ( $ParamObject->GetArray( Param => 'ServiceID' ) ) {
            @ServiceIDs = $ParamObject->GetArray( Param => 'ServiceID' );
        }

        # Build the state selection.
        my $ServiceHTML = $LayoutObject->BuildSelection(
            Data        => \%ServiceList,
            Name        => 'ServiceID',
            Class       => 'Modernize',
            Multiple    => 1,
            Size        => 10,
            SelectedID  => \@ServiceIDs,
            Sort        => 'AlphanumericValue',
            Translation => 0,
            TreeView    => 1,
        );
        $LayoutObject->Block(
            Name => 'Service',
            Data => {
                ServiceOption => $ServiceHTML,
            },
        );
    }

    # Show languages field.
    my $MultiLanguage = $ConfigObject->Get('FAQ::MultiLanguage');
    if ($MultiLanguage) {
        $LayoutObject->Block(
            Name => 'Language',
            Data => {
                %Param,
                %Data,
            },
        );
    }
    else {

        # Get default language.
        my $DefaultLanguage = $ConfigObject->Get('FAQ::Default::Language') || 'en';

        # Get default LanguageID
        my $LanguageID = $FAQObject->LanguageLookup(
            Name => $DefaultLanguage,
        );

        # Create default language if it was deleted or does not exists.
        if ( !$LanguageID ) {
            my $InsertLanguage = $FAQObject->LanguageAdd(
                Name   => $DefaultLanguage,
                UserID => 1,
            );

            if ( !$InsertLanguage ) {

                # Return with error screen.
                return $LayoutObject->ErrorScreen(
                    Message => Translatable('No default language found and can\'t create a new one.'),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }

            # Get default LanguageID.
            $LanguageID = $FAQObject->LanguageLookup(
                Name => $DefaultLanguage,
            );
        }

        $Param{LanguageID} = $LanguageID;

        $LayoutObject->Block(
            Name => 'NoLanguage',
            Data => {
                %Param,
                %Data,
            },
        );
    }

    # Show approval field.
    if ( $ConfigObject->Get('FAQ::ApprovalRequired') ) {

        my $ApprovalRequired        = 1;
        my $ApprovalIncludeInternal = $ConfigObject->Get('FAQ::Approval::IncludeInternal');

        if ( !$ApprovalIncludeInternal ) {
            my %InternalState = $FAQObject->StateList(
                Types  => ['internal'],
                UserID => 1,
            );

            if ( $InternalState{ $Param{StateID} } ) {
                $ApprovalRequired = 0;
            }
        }

        if ( $ApprovalRequired ) {

            # Check permission.
            my %Groups = reverse $Kernel::OM->Get('Kernel::System::Group')->GroupMemberList(
                UserID => $Self->{UserID},
                Type   => 'ro',
                Result => 'HASH',
            );

            # Get the FAQ approval group from config.
            my $ApprovalGroup = $ConfigObject->Get('FAQ::ApprovalGroup') || '';

            # Build the approval selection if user is in the approval group.
            if ( $Groups{$ApprovalGroup} ) {

                $Data{ApprovalOption} = $LayoutObject->BuildSelection(
                    Name => 'Approved',
                    Data => {
                        0 => Translatable('No'),
                        1 => Translatable('Yes'),
                    },
                    SelectedID => $Param{Approved} || 0,
                    Class      => 'Modernize',
                );
                $LayoutObject->Block(
                    Name => 'Approval',
                    Data => {
                        %Data,
                    },
                );
            }
        }
    }

    # Get config of frontend module.
    my $Config = $ConfigObject->Get("FAQ::Frontend::$Self->{Action}") || '';

    # Add rich text editor JavaScript only if activated and the browser can handle it
    #   otherwise just a text-area is shown
    if ( $LayoutObject->{BrowserRichText} && $ConfigObject->Get('FAQ::Item::HTML') ) {

        # Use height/width defined for this screen.
        $Param{RichTextHeight} = $Config->{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Config->{RichTextWidth}  || 0;

        # Set up rich text editor.
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    # Set default interface settings.
    my $InterfaceStates = $FAQObject->StateTypeList(
        Types  => @StateTypes,
        UserID => $Self->{UserID},
    );

    # Show FAQ Content.
    $LayoutObject->FAQContentShow(
        FAQObject       => $FAQObject,
        InterfaceStates => $InterfaceStates,
        FAQData         => {
            %Param,
        },
        UserID => $Self->{UserID},
    );

    return $LayoutObject->Output(
        TemplateFile => 'AgentFAQAdd',
        Data         => \%Param,
    );
}

1;
