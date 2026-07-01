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

package Kernel::Modules::AgentMELTObjectEdit;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules
use List::Util qw(any);

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(:all);
use Kernel::Language              qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {%Param}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # my param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get MELT Object id and class id
    my $MELTObject  = {};
    my $DuplicateID = $ParamObject->GetParam( Param => 'DuplicateID' ) || 0;
    $MELTObject->{MELTObjectID} = $ParamObject->GetParam( Param => 'MELTObjectID' ) || 0;
    $MELTObject->{ClassID}      = $ParamObject->GetParam( Param => 'ClassID' )      || 0;

    my $HasAccess;

    # get needed objects
    my $MELTObjectObject          = $Kernel::OM->Get('Kernel::System::MELTObject');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $GeneralCatalogObject      = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ConfigObject              = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get config of frontend module
    $Self->{Config} = $ConfigObject->Get("MELTObject::Frontend::$Self->{Action}");

    # get needed data
    if ( $MELTObject->{MELTObjectID} && $MELTObject->{MELTObjectID} ne 'NEW' ) {

        # check access for MELT Object
        $HasAccess = $MELTObjectObject->Permission(
            Scope  => 'Item',
            ItemID => $MELTObject->{MELTObjectID},
            UserID => $Self->{UserID},
            Type   => $Self->{Config}->{Permission},
        );

        # get MELT Object
        $MELTObject = $MELTObjectObject->MELTObjectGet(
            MELTObjectID  => $MELTObject->{MELTObjectID},
            DynamicFields => 1,
        );
    }
    elsif ($DuplicateID) {

        my $VersionID = $ParamObject->GetParam( Param => 'VersionID' );

        # TODO: Check duplication
        # get MELT Object to duplicate
        $MELTObject = $MELTObjectObject->MELTObjectGet(
            MELTObjectID  => $DuplicateID,
            VersionID     => $VersionID,
            DynamicFields => 1,
        );

        # check access for MELT Object
        $HasAccess = $MELTObjectObject->Permission(
            Scope  => 'Item',
            ItemID => $MELTObject->{MELTObjectID},
            UserID => $Self->{UserID},
            Type   => $Self->{Config}->{Permission},
        );

        # set MELT Object id and number
        $MELTObject->{MELTObjectID} = 'NEW';
        $MELTObject->{Number}       = Translatable('New');
    }
    elsif ( $MELTObject->{ClassID} ) {

        # set MELT Object id and number
        $MELTObject->{MELTObjectID} = 'NEW';
        $MELTObject->{Number}       = Translatable('New');

        # check access for MELT Object
        $HasAccess = $MELTObjectObject->Permission(
            Scope   => 'Class',
            ClassID => $MELTObject->{ClassID},
            UserID  => $Self->{UserID},
            Type    => $Self->{Config}->{Permission},
        );

        # get class list
        my $ClassList = $GeneralCatalogObject->ItemList(
            Class => 'ZTSM::MELT::Class',
        );
        $MELTObject->{Class} = $ClassList->{ $MELTObject->{ClassID} };
    }
    else {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No MELTObjectID, DuplicateID or ClassID is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # if user has no access rights show error page
    if ( !$HasAccess ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No access is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # Edit the MELT Object with the newest MELT Object definition of the relevant class
    my $Definition = $MELTObjectObject->DefinitionGet(
        ClassID => $MELTObject->{ClassID},
    );

    # abort, if no definition is defined
    if ( !$Definition->{DefinitionID} ) {
        return $LayoutObject->ErrorScreen(
            Message => $LayoutObject->{LanguageObject}->Translate( 'No definition was defined for class %s!', $MELTObject->{Class} ),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get form id
    my $FormCacheObject = $Kernel::OM->Get('Kernel::System::Web::FormCache');

    $Self->{FormID} = $FormCacheObject->PrepareFormID(
        ParamObject  => $ParamObject,
        LayoutObject => $LayoutObject,
    );

    my %GetParam;
    my %DynamicFieldValues;
    my %ACLReducibleDynamicFields;
    my $DynamicFieldList;

    # get initial values for the MELTObject
    if ( !$Self->{Subaction} ) {
        $DynamicFieldList = $Definition->{DynamicFieldRef} ? [ values $Definition->{DynamicFieldRef}->%* ] : [];

        if ( $MELTObject->{MELTObjectID} eq 'NEW' ) {
            my $MELTObjectName;

            if ($DuplicateID) {

                # get Data from duplicate CI
                for my $Param (qw(Name VersionString ZTSMStatusID Description)) {
                    $GetParam{$Param} = $MELTObject->{$Param};
                }

                $MELTObjectName = $GetParam{Name} . ' (Copy)';

                DYNAMICFIELD:
                for my $DynamicFieldConfig ( $DynamicFieldList->@* ) {
                    next DYNAMICFIELD unless IsHashRefWithData($DynamicFieldConfig);

                    $DynamicFieldValues{ $DynamicFieldConfig->{Name} } = $MELTObject->{ 'DynamicField_' . $DynamicFieldConfig->{Name} };

                    # perform ACLs on values
                    my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        Behavior           => 'IsACLReducible'
                    );

                    if ($IsACLReducible) {
                        $ACLReducibleDynamicFields{ $DynamicFieldConfig->{Name} } = 1;
                    }
                }
            }

            else {
                %GetParam = (
                    %GetParam,
                    $MELTObject->%*,
                );
                delete $GetParam{MELTObjectID};
            }
        }

        else {
            # get general form data
            for my $Param (qw(Name VersionString ZTSMStatusID Description)) {
                $GetParam{$Param} = $MELTObject->{$Param};
            }

            DYNAMICFIELD:
            for my $DynamicFieldConfig ( $DynamicFieldList->@* ) {
                next DYNAMICFIELD unless IsHashRefWithData($DynamicFieldConfig);

                $DynamicFieldValues{ $DynamicFieldConfig->{Name} } = $MELTObject->{ 'DynamicField_' . $DynamicFieldConfig->{Name} };

                # perform ACLs on values
                my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    Behavior           => 'IsACLReducible'
                );

                if ($IsACLReducible) {
                    $ACLReducibleDynamicFields{ $DynamicFieldConfig->{Name} } = 1;
                }
            }
        }
    }

    else {
        my $ActiveFields = $FormCacheObject->GetFormData(
            FormID       => $Self->{FormID},
            LayoutObject => $LayoutObject,
            Key          => 'ActiveDynamicFields',
        ) // [];

        for my $FieldName ( $ActiveFields->@* ) {
            push @{$DynamicFieldList}, $Definition->{DynamicFieldRef}{$FieldName};
        }

        # get general form data
        for my $Param (qw(Name VersionString ZTSMStatusID Description)) {
            $GetParam{$Param} = $ParamObject->GetParam( Param => $Param );
        }

        # special case for class
        $GetParam{ClassID} = $MELTObject->{ClassID};

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( $DynamicFieldList->@* ) {
            next DYNAMICFIELD unless IsHashRefWithData($DynamicFieldConfig);
            next DYNAMICFIELD if $DynamicFieldConfig->{Readonly};

            # extract the dynamic field value from the web request
            $DynamicFieldValues{ $DynamicFieldConfig->{Name} } = $DynamicFieldBackendObject->EditFieldValueGet(
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
    }

    my @UpdatableFields = qw(ZTSMStatusID Description);
    push @UpdatableFields, keys %ACLReducibleDynamicFields;

    # convert dynamic field values into a structure for ACLs
    my %DynamicFieldACLParameters;
    DYNAMICFIELD:
    for my $DynamicField ( sort keys %DynamicFieldValues ) {
        next DYNAMICFIELD unless $DynamicField;
        next DYNAMICFIELD unless $DynamicFieldValues{$DynamicField};

        $DynamicFieldACLParameters{ 'DynamicField_' . $DynamicField } = $DynamicFieldValues{$DynamicField};
    }
    $GetParam{DynamicField} = \%DynamicFieldACLParameters;

    # get upload cache object
    my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

    # attachments of existing MELT Object needs to be loaded in two cases:
    #   1. an existing MELT Object is edited - no class id present in GetParam
    #   2. an existing MELT Object is duplicated
    if ( !$ParamObject->GetParam( Param => 'ClassID' ) || $DuplicateID ) {

        # get all attachments meta data
        my @ExistingAttachments = $MELTObjectObject->MELTObjectAttachmentList(
            MELTObjectID => $DuplicateID || $MELTObject->{MELTObjectID},
        );

        # copy all existing attachments to upload cache
        FILENAME:
        for my $Filename (@ExistingAttachments) {

            # get the existing attachment data
            my $AttachmentData = $MELTObjectObject->MELTObjectAttachmentGet(
                MELTObjectID => $DuplicateID || $MELTObject->{MELTObjectID},
                Filename     => $Filename,
                UserID       => $Self->{UserID},
            );

            # add attachment to the upload cache
            $UploadCacheObject->FormIDAddFile(
                FormID      => $Self->{FormID},
                Filename    => $AttachmentData->{Filename},
                Content     => $AttachmentData->{Content},
                ContentType => $AttachmentData->{ContentType},
            );
        }
    }

    # get log object
    my $LogObject               = $Kernel::OM->Get('Kernel::System::Log');
    my $FieldRestrictionsObject = $Kernel::OM->Get('Kernel::System::MELTObject::FieldRestrictions');

    my $Autoselect = $ConfigObject->Get('MELTObjectACL::Autoselect') || undef;
    my $ACLPreselection;
    if ( $ConfigObject->Get('MELTObjectACL::ACLPreselection') ) {

        # get cached preselection rules
        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
        $ACLPreselection = $CacheObject->Get(
            Type => 'MELTObjectACL',
            Key  => 'Preselection',
        );
        if ( !$ACLPreselection ) {
            $ACLPreselection = $FieldRestrictionsObject->SetACLPreselectionCache();
        }
    }

    my %Error;
    my $NameDuplicates;
    my $CINameRegexErrorMessage;
    my %DynamicFieldValidationResult;
    my %DynamicFieldPossibleValues;
    my %DynamicFieldVisibility;

    my %ClassPreferences = $GeneralCatalogObject->GeneralCatalogPreferencesGet(
        ItemID => $MELTObject->{ClassID},
    );

    my $NameModule = $ClassPreferences{NameModule} ? $ClassPreferences{NameModule}[0] : '';
    if ($NameModule) {

        # check if name module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::MELTObject::Name::$NameModule") ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load name module for class $MELTObject->{Class}!",
            );
            $NameModule = undef;
        }
    }

    my $VersionStringModule = $ClassPreferences{VersionStringModule} ? $ClassPreferences{VersionStringModule}[0] : '';
    if ($VersionStringModule) {

        # check if name module exists
        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require("Kernel::System::MELTObject::VersionString::$VersionStringModule") ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load version string module for class $MELTObject->{Class}!",
            );
            $VersionStringModule = undef;
        }
    }

    if ( $Self->{Subaction} eq 'Save' ) {

        # get the uploaded attachment
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param  => 'FileUpload',
            Source => 'string',
        );

        if (%UploadStuff) {

            # add attachment to the upload cache
            $UploadCacheObject->FormIDAddFile(
                FormID => $Self->{FormID},
                %UploadStuff,
            );
        }

        my $AllRequired = 1;

        # get general form data
        for my $Param (qw(ZTSMStatusID Description)) {
            $MELTObject->{$Param} = $GetParam{$Param};

            if ( !$MELTObject->{$Param} ) {
                $AllRequired = 0;
            }
        }

        $GetParam{Description} //= '';

        # get name only if it is not filled by a module
        if ( !$NameModule ) {
            $MELTObject->{Name} = $GetParam{Name};

            if ( !$MELTObject->{Name} ) {
                $AllRequired = 0;
            }
        }

        # get version string only if it is not filled by a module
        if ( !$VersionStringModule ) {
            $MELTObject->{VersionString} = $GetParam{VersionString};

            if ( !$MELTObject->{VersionString} ) {
                $AllRequired = 0;
            }
        }

        # check, whether the feature to check for a unique name is enabled
        if (
            IsStringWithData( $MELTObject->{Name} )
            && $ConfigObject->Get('UniqueCIName::EnableUniquenessCheck')
            )
        {

            if ( $ConfigObject->{Debug} > 0 ) {
                $LogObject->Log(
                    Priority => 'debug',
                    Message  => "Checking for duplicate names (ClassID: $MELTObject->{ClassID}, "
                        . "Name: $MELTObject->{Name}, MELTObjectID: $MELTObject->{MELTObjectID})",
                );
            }

            $NameDuplicates = $MELTObjectObject->UniqueNameCheck(
                MELTObjectID => $MELTObject->{MELTObjectID},
                ClassID      => $MELTObject->{ClassID},
                Name         => $MELTObject->{Name},
            );

            # stop processing if the name is not unique
            if ( IsArrayRefWithData($NameDuplicates) ) {

                $AllRequired = 0;

                # build a string of all duplicate IDs
                my $NameDuplicatesString = join ', ', @{$NameDuplicates};

                $LogObject->Log(
                    Priority => 'error',
                    Message  =>
                        "The name $MELTObject->{Name} is already in use by the MELTObjectID(s): "
                        . $NameDuplicatesString,
                );
            }
        }

        # get the config option for the name regex checks
        my $CINameRegexConfig = $ConfigObject->Get("MELTObject::CINameRegex");

        # check if the CI name is given and should be checked with a regular expression
        if ( IsStringWithData( $MELTObject->{Name} ) && $CINameRegexConfig ) {

            # get class list
            my $ClassList = $GeneralCatalogObject->ItemList(
                Class => 'ZTSM::MELT::Class',
            );

            # get the class name
            my $ClassName = $ClassList->{ $MELTObject->{ClassID} } || '';

            # get the regex for this class
            my $CINameRegex = $CINameRegexConfig->{ $ClassName . '::' . 'CINameRegex' } || '';

            # if a regex is defined and the CI name does not match the regular expression
            if ( $CINameRegex && $MELTObject->{Name} !~ m{ $CINameRegex }xms ) {

                $AllRequired = 0;

                # get the error message for this class
                $CINameRegexErrorMessage = $CINameRegexConfig->{ $ClassName . '::' . 'CINameRegexErrorMessage' } || '';
            }
        }

        # transform dynamic field data into DFName => DFName pair
        my %DynamicFieldAcl = map { $_->{Name} => $_->{Name} } $DynamicFieldList->@*;

        # call ticket ACLs for DynamicFields to check field visibility
        my $ACLResult = $MELTObjectObject->MELTObjectAcl(
            %GetParam,
            Action        => $Self->{Action},
            ReturnType    => 'Form',
            ReturnSubType => '-',
            Data          => \%DynamicFieldAcl,
            UserID        => $Self->{UserID},
        );
        if ($ACLResult) {
            %DynamicFieldVisibility = map { 'DynamicField_' . $_->{Name} => 0 } $DynamicFieldList->@*;
            my %AclData = $MELTObjectObject->MELTObjectAclData();
            for my $Field ( sort keys %AclData ) {
                $DynamicFieldVisibility{ 'DynamicField_' . $Field } = 1;
            }
        }
        else {
            %DynamicFieldVisibility = map { 'DynamicField_' . $_->{Name} => 1 } $DynamicFieldList->@*;
        }

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( $DynamicFieldList->@* ) {
            next DYNAMICFIELD unless IsHashRefWithData($DynamicFieldConfig);

            my $PossibleValuesFilter;

            if ( $ACLReducibleDynamicFields{ $DynamicFieldConfig->{Name} } ) {

                # get PossibleValues
                my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                );

                # check if field has PossibleValues property in its configuration
                if ( IsHashRefWithData($PossibleValues) ) {

                    # convert possible values key => value to key => key for ACLs using a Hash slice
                    my %AclData = %{$PossibleValues};
                    @AclData{ keys %AclData } = keys %AclData;

                    # set possible values filter from ACLs
                    my $ACL = $MELTObjectObject->MELTObjectAcl(
                        %GetParam,
                        Action        => $Self->{Action},
                        ReturnType    => 'MELTObject',
                        ReturnSubType => 'DynamicField_' . $DynamicFieldConfig->{Name},
                        Data          => \%AclData,
                        UserID        => $Self->{UserID},
                    );
                    if ($ACL) {
                        my %Filter = $MELTObjectObject->MELTObjectAclData();

                        # convert Filter key => key back to key => value using map
                        %{$PossibleValuesFilter} = map { $_ => $PossibleValues->{$_} } keys %Filter;
                    }
                }
            }

            $DynamicFieldPossibleValues{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $PossibleValuesFilter;

            # perform validation
            my $ValidationResult = $DynamicFieldBackendObject->EditFieldValueValidate(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $PossibleValuesFilter,
                ParamObject          => $ParamObject,
                GetParam             => {
                    MELTObjectID => $MELTObject->{MELTObjectID},
                    %GetParam,
                }
            );

            if ( !IsHashRefWithData($ValidationResult) ) {
                return $LayoutObject->ErrorScreen(
                    Message => $LayoutObject->{LanguageObject}->Translate("Could not perform validation on field $DynamicFieldConfig->{Label}!"),
                    Comment => Translatable('Please contact the administrator.'),
                );
            }

            # propagate validation error to the Error variable to be detected by the frontend
            if ( $ValidationResult->{ServerError} ) {
                $Error{ $DynamicFieldConfig->{Name} }                        = ' ServerError';
                $DynamicFieldValidationResult{ $DynamicFieldConfig->{Name} } = $ValidationResult;
            }
        }

        $AllRequired = %Error ? 0 : 1;

        # save version to database
        if ($AllRequired) {

            # get all attachments from upload cache
            my @Attachments = $UploadCacheObject->FormIDGetAllFilesData(
                FormID => $Self->{FormID},
            );

            # build a lookup lookup hash of the new attachments
            my %NewAttachment;
            ATTACHMENT:
            for my $Attachment (@Attachments) {

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
                    $GetParam{Description} =~ s/(ContentID=)$ContentIDLinkEncode/$1$ContentID/g;

                    # ignore attachment if not linked in body
                    next ATTACHMENT
                        if $GetParam{Description} !~ /(\Q$ContentIDHTMLQuote\E|\Q$ContentID\E)/i;
                }

                # the key is the filename + filesize + content type
                my $Key = $Attachment->{Filename}
                    . $Attachment->{Filesize}
                    . $Attachment->{ContentType};

                # store all of the new attachment data
                $NewAttachment{$Key} = $Attachment;
            }

            # verify html document
            $MELTObject->{Description} = $LayoutObject->RichTextDocumentComplete(
                String => $GetParam{Description},
            );

            # for existing MELTObjects compare with the current data
            if ( $MELTObject->{MELTObjectID} ne 'NEW' ) {

                # get MELT Object attachments meta data
                my @ExistingAttachments = $MELTObjectObject->MELTObjectAttachmentList(
                    MELTObjectID => $MELTObject->{MELTObjectID},
                );

                # check the existing attachments
                FILENAME:
                for my $Filename (@ExistingAttachments) {

                    # get the existing attachment data
                    my $AttachmentData = $MELTObjectObject->MELTObjectAttachmentGet(
                        MELTObjectID => $MELTObject->{MELTObjectID},
                        Filename     => $Filename,
                        UserID       => $Self->{UserID},
                    );

                    # the key is the filename + filesize + content type
                    # (no content id, as existing attachments don't have it)
                    my $Key = $AttachmentData->{Filename}
                        . $AttachmentData->{Filesize}
                        . $AttachmentData->{ContentType};

                    # attachment is already existing, we can delete it from the new attachment hash
                    if ( $NewAttachment{$Key} ) {
                        delete $NewAttachment{$Key};
                    }

                    # existing attachment is no longer in new attachments hash
                    else {

                        # delete the existing attachment
                        my $DeleteSuccessful = $MELTObjectObject->MELTObjectAttachmentDelete(
                            MELTObjectID => $MELTObject->{MELTObjectID},
                            Filename     => $Filename,
                            UserID       => $Self->{UserID},
                        );

                        # check error
                        if ( !$DeleteSuccessful ) {
                            return $LayoutObject->FatalError();
                        }
                    }
                }

                # get version attachments meta data
                my @ExistingVersionAttachments = $MELTObjectObject->VersionAttachmentList(
                    VersionID => $MELTObject->{VersionID},
                );

                # check the existing attachments
                FILENAME:
                for my $Filename (@ExistingVersionAttachments) {

                    # get the existing attachment data
                    my $AttachmentData = $MELTObjectObject->VersionAttachmentGet(
                        VersionID => $MELTObject->{VersionID},
                        Filename  => $Filename,
                        UserID    => $Self->{UserID},
                    );

                    # the key is the filename + filesize + content type
                    # (no content id, as existing attachments don't have it)
                    my $Key = $AttachmentData->{Filename}
                        . $AttachmentData->{Filesize}
                        . $AttachmentData->{ContentType};

                    # attachment is already existing, we can delete it from the new attachment hash
                    if ( $NewAttachment{$Key} ) {
                        delete $NewAttachment{$Key};
                    }

                    # existing attachment is no longer in new attachments hash
                    else {

                        # delete the existing attachment
                        my $DeleteSuccessful = $MELTObjectObject->VersionAttachmentDelete(
                            VersionID => $MELTObject->{VersionID},
                            Filename  => $Filename,
                            UserID    => $Self->{UserID},
                        );

                        # check error
                        if ( !$DeleteSuccessful ) {
                            return $LayoutObject->FatalError();
                        }
                    }
                }
            }

            # TODO: better align with the initial EditFieldValueGet?
            # TODO: Visibility
            # prepare dynamic field values
            DYNAMICFIELD:
            for my $DynamicField ( $DynamicFieldList->@* ) {
                next DYNAMICFIELD if !IsHashRefWithData($DynamicField);
                next DYNAMICFIELD if $DynamicField->{Readonly};

                $MELTObject->{ 'DynamicField_' . $DynamicField->{Name} } = $DynamicFieldValues{ $DynamicField->{Name} };
            }

            if ( $MELTObject->{MELTObjectID} eq 'NEW' ) {

                # delete temporary number # TODO: check, whether setting new as number is necessary in the first place
                delete $MELTObject->{Number};

                $MELTObject->{MELTObjectID} = $MELTObjectObject->MELTObjectAdd(
                    $MELTObject->%*,
                    UserID => $Self->{UserID},

                    # DefinitionID => $Definition->{DefinitionID}, # TODO: this is not used yet
                );

                # check error
                if ( !$MELTObject->{MELTObjectID} ) {
                    return $LayoutObject->FatalError();
                }
            }
            else {
                $MELTObjectObject->MELTObjectUpdate(
                    $MELTObject->%*,
                    DefinitionID => $Definition->{DefinitionID},
                    UserID       => $Self->{UserID},
                );
            }

            # fetch updated MELT Object data to secure version id being present
            my $NewMELTObjectData = $MELTObjectObject->MELTObjectGet(
                MELTObjectID  => $MELTObject->{MELTObjectID},
                DynamicFields => 0,
            );

            # write the new attachments
            ATTACHMENT:
            for my $Attachment ( values %NewAttachment ) {

                # add attachment
                if ( $Attachment->{Disposition} && $Attachment->{Disposition} eq 'inline' ) {
                    my $Success = $MELTObjectObject->VersionAttachmentAdd(
                        %{$Attachment},
                        VersionID => $NewMELTObjectData->{VersionID},
                        UserID    => $Self->{UserID},
                    );

                    # check error
                    if ( !$Success ) {
                        return $LayoutObject->FatalError();
                    }

                    # also write attachments to last version if it differs because we deleted them previously
                    if ( $MELTObject->{VersionID} && $MELTObject->{VersionID} != $NewMELTObjectData->{VersionID} ) {
                        my $Success = $MELTObjectObject->VersionAttachmentAdd(
                            %{$Attachment},
                            VersionID => $MELTObject->{VersionID},
                            UserID    => $Self->{UserID},
                        );

                        # check error
                        if ( !$Success ) {
                            return $LayoutObject->FatalError();
                        }
                    }
                }
                else {
                    my $Success = $MELTObjectObject->MELTObjectAttachmentAdd(
                        %{$Attachment},
                        MELTObjectID => $MELTObject->{MELTObjectID},
                        UserID       => $Self->{UserID},
                    );

                    # check error
                    if ( !$Success ) {
                        return $LayoutObject->FatalError();
                    }
                }
            }

            # remove all form data
            $FormCacheObject->FormIDRemove( FormID => $Self->{FormID} );

            # redirect to zoom mask
            my $ScreenType = $ParamObject->GetParam( Param => 'ScreenType' ) || 0;
            if ($ScreenType) {

                my $URL = "Action=AgentMELTObjectZoom;MELTObjectID=$MELTObject->{MELTObjectID}";

                # return to overview or search results instead if called Duplicate from row action
                if (
                    $Self->{Session}{LastScreenView} eq 'Action=AgentMELTObject'
                    || $Self->{Session}{LastScreenView} =~ m{\A Action=AgentMELTObject(?: Search)?;}msx
                    )
                {
                    $URL = $Self->{Session}{LastScreenView};
                }

                return $LayoutObject->PopupClose(
                    URL => $URL,
                );
            }
            else {
                return $LayoutObject->Redirect(
                    OP => "Action=AgentMELTObjectZoom;MELTObjectID=$MELTObject->{MELTObjectID}",
                );
            }
        }
    }
    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {
        my $ElementChanged  = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';
        my %ChangedElements = $ElementChanged ? ( $ElementChanged => 1 ) : ();
        my $LoopProtection  = 100;

        # get values and visibility of dynamic fields
        my %DynFieldStates = $FieldRestrictionsObject->GetFieldStates(
            MELTObjectObject          => $MELTObjectObject,
            DynamicFields             => $Definition->{DynamicFieldRef},
            DynamicFieldBackendObject => $DynamicFieldBackendObject,
            ChangedElements           => \%ChangedElements,                # optional to reduce ACL evaluation
            Action                    => $Self->{Action},
            UserID                    => $Self->{UserID},
            MELTObjectID              => $MELTObject->{MELTObjectID},
            FormID                    => $Self->{FormID},
            GetParam                  => {%GetParam},
            Autoselect                => $Autoselect,
            ACLPreselection           => $ACLPreselection,
            LoopProtection            => \$LoopProtection,
        );

        # store new values
        $GetParam{DynamicField} = {
            %{ $GetParam{DynamicField} },
            %{ $DynFieldStates{NewValues} },
        };

        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $Name ( keys %{ $DynFieldStates{Fields} } ) {
            my $DynamicFieldConfig = $Definition->{DynamicFieldRef}{$Name};

            if ( $DynamicFieldConfig->{Config}{MultiValue} && ref $GetParam{DynamicField}{"DynamicField_$Name"} eq 'ARRAY' ) {
                for my $i ( 0 .. $#{ $GetParam{DynamicField}{"DynamicField_$Name"} } ) {
                    my $DataValues = $DynFieldStates{Fields}{$Name}{NotACLReducible}
                        ? $GetParam{DynamicField}{"DynamicField_$Name"}[$i]
                        :
                        (
                            $DynamicFieldBackendObject->BuildSelectionDataGet(
                                DynamicFieldConfig => $DynamicFieldConfig,
                                PossibleValues     => $DynFieldStates{Fields}{$Name}{PossibleValues},
                                Value              => [ $GetParam{DynamicField}{"DynamicField_$Name"}[$i] ],
                            )
                            || $DynFieldStates{Fields}{$Name}{PossibleValues}
                        );

                    # add dynamic field to the list of fields to update
                    push @DynamicFieldAJAX, {
                        Name        => $Name . '_' . $i,
                        Data        => $DataValues,
                        SelectedID  => $GetParam{DynamicField}{"DynamicField_$Name"}[$i],
                        Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                        Max         => 100,
                    };
                }

                next DYNAMICFIELD;
            }

            my $DataValues = $DynFieldStates{Fields}{$Name}{NotACLReducible}
                ? $GetParam{DynamicField}{"DynamicField_$Name"}
                :
                (
                    $DynamicFieldBackendObject->BuildSelectionDataGet(
                        DynamicFieldConfig => $DynamicFieldConfig,
                        PossibleValues     => $DynFieldStates{Fields}{$Name}{PossibleValues},
                        Value              => $GetParam{DynamicField}{"DynamicField_$Name"},
                    )
                    || $DynFieldStates{Fields}{$Name}{PossibleValues}
                );

            # add dynamic field to the list of fields to update
            push @DynamicFieldAJAX, {
                Name        => 'DynamicField_' . $Name,
                Data        => $DataValues,
                SelectedID  => $GetParam{DynamicField}{"DynamicField_$Name"},
                Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
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
                            ? $SetField->{Values}{$FrontendName}[$i]
                            :
                            (
                                $DynamicFieldBackendObject->BuildSelectionDataGet(
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
                            Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                            Max         => 100,
                        };
                    }

                    next DYNAMICFIELD;
                }

                my $DataValues = $SetField->{FieldStates}{$FrontendName}{NotACLReducible}
                    ? $SetField->{Values}{$FrontendName}
                    :
                    (
                        $DynamicFieldBackendObject->BuildSelectionDataGet(
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
                    Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
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

        my $JSON = $LayoutObject->BuildSelectionJSON(
            [
                @DynamicFieldAJAX,
            ],
        );

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    else {

        my $LoopProtection = 100;

        # get values and visibility of dynamic fields
        my %DynFieldStates = $FieldRestrictionsObject->GetFieldStates(
            MELTObjectObject          => $MELTObjectObject,
            DynamicFields             => $Definition->{DynamicFieldRef},
            DynamicFieldBackendObject => $DynamicFieldBackendObject,
            Action                    => $Self->{Action},
            UserID                    => $Self->{UserID},
            MELTObjectID              => $MELTObject->{MELTObjectID},
            FormID                    => $Self->{FormID},
            GetParam                  => {%GetParam},
            Autoselect                => $Autoselect,
            ACLPreselection           => $ACLPreselection,
            LoopProtection            => \$LoopProtection,
        );

        # store new values
        $GetParam{DynamicField} = {
            %{ $GetParam{DynamicField} },
            %{ $DynFieldStates{NewValues} },
        };

        %DynamicFieldVisibility     = $DynFieldStates{Visibility}->%*;
        %DynamicFieldPossibleValues = map { 'DynamicField_' . $_ => $DynFieldStates{Fields}{$_}{PossibleValues} } keys $DynFieldStates{Fields}->%*;
    }

    my $NameEditable   = $NameModule ? 0 : 1;
    my $RowNameInvalid = $MELTObject->{Name}

        # If a name exists then mark regex and duplicate errors.
        ? ( ( $CINameRegexErrorMessage || IsArrayRefWithData($NameDuplicates) ) ? 'ServerError' : undef )

        # If the name does not exist but should exist then mark it.
        : ( ( $Self->{Subaction} eq 'Save' && $NameEditable ) ? 'ServerError' : undef );

    # output name block
    if ( $MELTObject->{Name} || $NameEditable ) {

        # output name block
        $LayoutObject->Block(
            Name => 'RowName',
            Data => {
                %GetParam,
                RowNameInvalid => $RowNameInvalid,
                Readonly       => !$NameEditable,
            },
        );
    }

    # show specific errors
    if ( IsArrayRefWithData($NameDuplicates) ) {

        # build array with CI-Numbers
        my @NameDuplicatesByCINumber;
        for my $MELTObjectID ( @{$NameDuplicates} ) {

            # lookup the CI number
            my $CINumber = $MELTObjectObject->MELTObjectLookup(
                MELTObjectID => $MELTObjectID,
            );

            push @NameDuplicatesByCINumber, $CINumber;
        }

        my $DuplicateString = join ', ', @NameDuplicatesByCINumber;

        if ( $ConfigObject->{Debug} > 0 ) {
            $LogObject->Log(
                Priority => 'debug',
                Message  =>
                    "Rendering block for duplicates (CI-Numbers: $DuplicateString) error message",
            );
        }

        $LayoutObject->Block(
            Name => 'RowNameErrorDuplicates',
            Data => {
                Duplicates => $DuplicateString,
            },
        );
    }
    elsif ($CINameRegexErrorMessage) {
        $LayoutObject->Block(
            Name => 'RowNameErrorRegEx',
            Data => {
                RegExErrorMessage => $CINameRegexErrorMessage,
            },
        );
    }
    elsif ($RowNameInvalid) {
        if ( $ConfigObject->{Debug} > 0 ) {
            $LogObject->Log(
                Priority => 'debug',
                Message  => "Rendering default error block",
            );
        }

        $LayoutObject->Block(
            Name => 'RowNameErrorDefault',
        );
    }

    my $VersionStringEditable   = $VersionStringModule ? 0 : 1;
    my $VersionStringDuplicates = [];
    my $RowVersionStringInvalid = $MELTObject->{VersionString}

        # If a version string exists then mark duplicate errors.
        ? ( IsArrayRefWithData($VersionStringDuplicates) ? 'ServerError' : undef )

        # If the version string does not exist but should exist then mark it.
        : ( ( $Self->{Subaction} eq 'Save' && $VersionStringEditable ) ? 'ServerError' : undef );

    # output version string block
    if ($VersionStringEditable) {

        # output version string block
        $LayoutObject->Block(
            Name => 'RowVersionString',
            Data => {
                %GetParam,
                RowVersionStringInvalid => $RowVersionStringInvalid,
            },
        );
    }

    # show specific errors
    if ( IsArrayRefWithData($VersionStringDuplicates) ) {

        # build array with CI-Numbers
        my @VersionStringDuplicatesByCINumber;
        for my $MELTObjectID ( @{$VersionStringDuplicates} ) {

            # lookup the CI number
            my $CINumber = $MELTObjectObject->MELTObjectLookup(
                MELTObjectID => $MELTObjectID,
            );

            push @VersionStringDuplicatesByCINumber, $CINumber;
        }

        my $DuplicateString = join ', ', @VersionStringDuplicatesByCINumber;

        if ( $ConfigObject->{Debug} > 0 ) {
            $LogObject->Log(
                Priority => 'debug',
                Message  =>
                    "Rendering block for duplicates (CI-Numbers: $DuplicateString) error message",
            );
        }

        $LayoutObject->Block(
            Name => 'RowVersionStringErrorDuplicates',
            Data => {
                Duplicates => $DuplicateString,
            },
        );
    }
    elsif ($RowVersionStringInvalid) {
        if ( $ConfigObject->{Debug} > 0 ) {
            $LogObject->Log(
                Priority => 'debug',
                Message  => "Rendering default error block",
            );
        }

        $LayoutObject->Block(
            Name => 'RowVersionStringErrorDefault',
        );
    }

    # get ZTSM Status list
    my $ZTSMStatusList = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::MELT::Status',
    );

    # output ZTSM Status invalid block
    my $RowZTSMStatusInvalid = '';
    if ( !$MELTObject->{ZTSMStatusID} && $Self->{Subaction} eq 'Save' ) {
        $RowZTSMStatusInvalid = ' ServerError';
    }

    # generate ZTSMStatusOptionStrg
    my $ZTSMStatusOptionStrg = $LayoutObject->BuildSelection(
        Data         => $ZTSMStatusList,
        Name         => 'ZTSMStatusID',
        PossibleNone => 1,
        Class        => 'FormUpdate Validate_Required Modernize' . $RowZTSMStatusInvalid,
        SelectedID   => $GetParam{ZTSMStatusID},
    );

    # output ZTSM Status block
    $LayoutObject->Block(
        Name => 'RowZTSMStatus',
        Data => {
            ZTSMStatusOptionStrg => $ZTSMStatusOptionStrg,
        },
    );

    # generate base url
    my $URL = "Action=PictureUpload;FormID=$Self->{FormID};ContentID=";

    # replace links to inline images in html content
    my @InlineAttachmentList;
    if ( $MELTObject->{MELTObjectID} ne 'NEW' ) {
        @InlineAttachmentList = $MELTObjectObject->VersionAttachmentList(
            VersionID => $MELTObject->{VersionID},
        );
    }

    # fetch attachment data and store in hash for RichTextDocumentServe
    my %InlineAttachments;
    FILENAME:
    for my $Filename (@InlineAttachmentList) {
        my $FileData = $MELTObjectObject->VersionAttachmentGet(
            VersionID => $MELTObject->{VersionID},
            Filename  => $Filename,
        );

        $InlineAttachments{ $FileData->{Preferences}{ContentID} } = $FileData;
        $InlineAttachments{ $FileData->{Preferences}{ContentID} }->{ContentID} = $FileData->{Preferences}{ContentID};

        # add uploaded file to upload cache
        $UploadCacheObject->FormIDAddFile(
            FormID      => $Self->{FormID},
            Filename    => $FileData->{Filename},
            Content     => $FileData->{Content},
            ContentID   => $FileData->{Preferences}{ContentID},
            ContentType => $FileData->{ContentType},

            # currently, only inline images for description are stored at the MELT Object version
            #   so we can rely upon dealing with inline images here
            Disposition => 'inline',
        );
    }

    # needed to provide necessary params for RichTextDocumentServe
    my $FieldContent = $MELTObject->{Description};
    my %Data         = (
        Content     => $FieldContent // '',
        ContentType => 'text/html; charset="utf-8"',
        Disposition => 'inline',
    );

    # reformat rich text document to have correct charset and links to
    # inline documents
    %Data = $LayoutObject->RichTextDocumentServe(
        Data               => \%Data,
        URL                => $URL,
        Attachments        => \%InlineAttachments,
        LoadExternalImages => 1,
    );

    $FieldContent = $Data{Content};

    # remove active html content (scripts, applets, etc...)
    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');
    my %SafeContent     = $HTMLUtilsObject->Safety(
        String       => $FieldContent,
        NoApplet     => 1,
        NoObject     => 1,
        NoEmbed      => 1,
        NoIntSrcLoad => 0,
        NoExtSrcLoad => 0,
        NoJavaScript => 1,
    );

    # take the safe content if necessary
    if ( $SafeContent{Replace} ) {
        $FieldContent = $SafeContent{String};
    }

    # detect all plain text links and put them into an HTML <a> tag
    $FieldContent = $HTMLUtilsObject->LinkQuote(
        String => $FieldContent,
    );

    # set target="_blank" attribute to all HTML <a> tags
    # the LinkQuote function needs to be called again
    $FieldContent = $HTMLUtilsObject->LinkQuote(
        String    => $FieldContent,
        TargetAdd => 1,
    );

    # add needed HTML headers
    $FieldContent = $HTMLUtilsObject->DocumentComplete(
        String  => $FieldContent,
        Charset => 'utf-8',
    );

    # escape single quotes
    $FieldContent =~ s/'/&#39;/g;

    # render dynamic fields
    my $DynamicFieldHTML;
    my %GroupLookup;
    if ( IsHashRefWithData( $Definition->{DefinitionRef} ) && $Definition->{DefinitionRef}{Sections} ) {

        # TODO: look what this was/is about
        #        $Self->{CustomerSearchItemIDs} = [];

        # TODO: It would be nice to switch between pages for the edit mask, too. Keeping the fields in sync
        #       while editing needs a bit more preparation though
        # Thus for now make sure to show dynamic fields only once, even if present on multiple pages/sections
        my $FieldsSeen = {};
        my $ShowDescription;
        my @PageHTML;
        my $SectionHeaderTemplate = '<div class="Row Row_SectionHeader"><h3>[% Translate(Data.Name) | html %]</h3></div>';

        PAGE:
        for my $Page ( $Definition->{DefinitionRef}{Pages}->@* ) {

            # Interfaces is optional, effectively default to [ 'Agent' ]
            if ( $Page->{Interfaces} ) {
                next PAGE unless any { $_ eq 'Agent' } $Page->{Interfaces}->@*;
            }

            if ( $Page->{Groups} ) {
                if ( !%GroupLookup ) {
                    %GroupLookup = reverse $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
                        UserID => $Self->{UserID},
                        Type   => 'ro',
                    );
                }

                # grant access to the page only when the user is in one of the specified groups
                next PAGE unless any { $GroupLookup{$_} } $Page->{Groups}->@*;
            }

            my $PageDynamicFieldHTML;

            SECTION:
            for my $SectionConfig ( $Page->{Content}->@* ) {
                my $Section = $Definition->{DefinitionRef}{Sections}{ $SectionConfig->{Section} };

                next SECTION unless $Section;
                if ( $Section->{Type} ) {
                    if ( $Section->{Type} eq 'Description' ) {
                        $ShowDescription = 1;

                        next SECTION;
                    }
                    elsif ( $Section->{Type} ne 'DynamicFields' ) {
                        next SECTION;
                    }
                }

                # weed out multiple occurrences of dynamic fields - see comment above
                $Section->{Content} = $Self->_DiscardFieldsSeen(
                    Content => $Section->{Content},
                    Seen    => $FieldsSeen,
                );

                # do not proceed if content is empty
                next SECTION unless $Section->{Content}->@*;

                my $HTML = $Kernel::OM->Get('Kernel::Output::HTML::DynamicField::Mask')->EditSectionRender(
                    Content              => $Section->{Content},
                    DynamicFields        => $Definition->{DynamicFieldRef},
                    UpdatableFields      => \@UpdatableFields,
                    LayoutObject         => $LayoutObject,
                    ParamObject          => $ParamObject,
                    DynamicFieldValues   => $GetParam{DynamicField},
                    PossibleValuesFilter => \%DynamicFieldPossibleValues,
                    Errors               => \%DynamicFieldValidationResult,
                    Visibility           => \%DynamicFieldVisibility,
                    Object               => {
                        Class => $MELTObject->{Class},
                        $GetParam{DynamicField}->%*,
                    },
                );

                next SECTION unless $HTML =~ /\w/;

                my ($SectionHeader) = grep { $_->{Header} } $Section->{Content}->@*;
                if ($SectionHeader) {
                    $PageDynamicFieldHTML .= $LayoutObject->Output(
                        Template => $SectionHeaderTemplate,
                        Data     => {
                            Name => $SectionHeader->{Header},
                        },
                    );
                }

                $PageDynamicFieldHTML .= $HTML;
            }

            next PAGE unless $PageDynamicFieldHTML;

            push @PageHTML, {
                HTML => $PageDynamicFieldHTML,
                Name => $Page->{Name},
            };
        }

        my @ActiveDynamicFields = ( keys $FieldsSeen->%* );

        # store the active dynamic fields, to only validate those
        $FormCacheObject->SetFormData(
            LayoutObject => $LayoutObject,
            Key          => 'ActiveDynamicFields',
            Value        => \@ActiveDynamicFields,
        );

        if ( scalar @PageHTML > 1 ) {
            my $HeaderTemplate =
                '<summary>
                <div class="Row Row_PageHeader">
                    <div class="Toggle">
                        <i class="fa fa-caret-right"></i>
                        <i class="fa fa-caret-down"></i>
                    </div>
                    <h2>[% Translate(Data.Name) | html %]</h2>
                    <hr/>
                </div>
            </summary>';

            for my $Page (@PageHTML) {
                $DynamicFieldHTML .= '<details class="PageContent">';
                $DynamicFieldHTML .= $LayoutObject->Output(
                    Template => $HeaderTemplate,
                    Data     => {
                        Name => $Page->{Name},
                    },
                );
                $DynamicFieldHTML .= $Page->{HTML};
                $DynamicFieldHTML .= '</details>';
            }

            if ($ShowDescription) {
                $DynamicFieldHTML .= '<details class="PageContent">';
                $DynamicFieldHTML .= $LayoutObject->Output(
                    Template => $HeaderTemplate,
                    Data     => {
                        Name => 'Description',
                    },
                );
            }
        }
        elsif (@PageHTML) {
            $DynamicFieldHTML .= $PageHTML[0]{HTML};
        }

        if ($ShowDescription) {
            $LayoutObject->Block(
                Name => 'RowDescription',
                Data => {
                    Description => $FieldContent // '',
                },
            );
        }
    }

    # get all attachments meta data
    my @AllAttachmentsList = $UploadCacheObject->FormIDGetAllFilesMeta(
        FormID => $Self->{FormID},
    );

    # exclude inline attachments as they are handled separately
    $Param{AttachmentList} = [ grep { $_->{Disposition} ne 'inline' } @AllAttachmentsList ];

    # TODO maybe restrict this to only if df richtext are to be displayed
    # add rich text editor
    if ( $LayoutObject->{BrowserRichText} ) {

        # use height/width defined for this screen
        $Param{RichTextHeight} = $Self->{Config}{RichTextHeight} || 0;
        $Param{RichTextWidth}  = $Self->{Config}{RichTextWidth}  || 0;

        # set up rich text editor
        $LayoutObject->SetRichTextParameters(
            Data => \%Param,
        );
    }

    if ( ( $MELTObject->{MELTObjectID} && $MELTObject->{MELTObjectID} ne 'NEW' ) || $DuplicateID ) {

        # output block
        $LayoutObject->Block(
            Name => 'StartSmall',
            Data => {
                %Param,
                %{$MELTObject},
            },
        );
        $LayoutObject->Block( Name => 'EndSmall' );

        # output header
        return join '',
            $LayoutObject->Header(
                Title => Translatable('Edit'),
                Type  => 'Small',
            ),
            $LayoutObject->Output(
                TemplateFile => 'AgentMELTObjectEdit',
                Data         => {
                    %Param,
                    %{$MELTObject},
                    DynamicFieldHTML => $DynamicFieldHTML,
                    DuplicateID      => $DuplicateID,
                    FormID           => $Self->{FormID},
                },
            ),
            $LayoutObject->Footer( Type => 'Small' );
    }
    else {

        # Necessary stuff for Add New
        # get class list
        my $ClassList = $GeneralCatalogObject->ItemList(
            Class => 'ZTSM::MELT::Class',
        );

        # check for access rights
        for my $ClassID ( sort keys %{$ClassList} ) {
            my $HasAccess = $MELTObjectObject->Permission(
                Type    => $Self->{Config}->{Permission},
                Scope   => 'Class',
                ClassID => $ClassID,
                UserID  => $Self->{UserID},
            );

            delete $ClassList->{$ClassID} if !$HasAccess;
        }

        # generate ClassOptionStrg
        my $ClassOptionStrg = $LayoutObject->BuildSelection(
            Data         => $ClassList,
            Name         => 'ClassID',
            PossibleNone => 1,
            Translation  => 0,
            Class        => 'W100pc',
            SelectedID   => $MELTObject->{ClassID},
        );

        # End Necessary stuff for Add New

        # output block
        $LayoutObject->Block(
            Name => 'StartNormal',
            Data => {
                ClassOptionStrg => $ClassOptionStrg,
                %Param,
                %{$MELTObject},
            },
        );

        $LayoutObject->Block( Name => 'EndNormal' );

        # output header
        return join '',
            $LayoutObject->Header(
                Title => Translatable('Edit'),
            ),
            $LayoutObject->NavigationBar,
            $LayoutObject->Output(
                TemplateFile => 'AgentMELTObjectEdit',
                Data         => {
                    %Param,
                    %{$MELTObject},
                    DynamicFieldHTML => $DynamicFieldHTML,
                    DuplicateID      => $DuplicateID,
                    FormID           => $Self->{FormID},
                },
            ),
            $LayoutObject->Footer;
    }
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

                if ( $Param{Seen}{ $Element->{DF} }++ ) {
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

