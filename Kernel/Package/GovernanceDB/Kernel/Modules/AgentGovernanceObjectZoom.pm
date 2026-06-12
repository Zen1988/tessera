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

package Kernel::Modules::AgentGovernanceObjectZoom;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules
use List::Util qw(any);

# CPAN modules

# OTOBO modules
use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {%Param}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get param object
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get params
    my $GovernanceObjectID      = $ParamObject->GetParam( Param => 'GovernanceObjectID' );
    my $GetParamVersionID = $ParamObject->GetParam( Param => 'VersionID' );

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check needed stuff
    if ( !$GovernanceObjectID ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No GovernanceObjectID is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get needed object
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');

    # check for access rights
    my $HasAccess = $GovernanceObjectObject->Permission(
        Scope  => 'Item',
        ItemID => $GovernanceObjectID,
        UserID => $Self->{UserID},
        Type   => $ConfigObject->Get("GovernanceObject::Frontend::$Self->{Action}")->{Permission},
    );

    if ( !$HasAccess ) {

        # error page
        return $LayoutObject->ErrorScreen(
            Message => Translatable('Can\'t show item, no access rights for Governance Object are given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get content
    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        GovernanceObjectID  => $GovernanceObjectID,
        VersionID     => $GetParamVersionID,
        DynamicFields => 1,
    );
    if ( !$GovernanceObject->{GovernanceObjectID} ) {
        return $LayoutObject->ErrorScreen(
            Message =>
                $LayoutObject->{LanguageObject}->Translate('Governance Object not found!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get version list
    my $VersionList = $GovernanceObjectObject->VersionZoomList(
        GovernanceObjectID => $GovernanceObjectID,
    );

    if ( !IsArrayRefWithData($VersionList) ) {
        return $LayoutObject->ErrorScreen(
            Message =>
                $LayoutObject->{LanguageObject}->Translate('No versions found!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # TODO: Compare with legacy code to check whether this is a good place. Line 256 throws an error if not set, else
    my $VersionID = $GovernanceObject->{VersionID};

    # run Governance Object menu modules
    if ( ref $ConfigObject->Get('GovernanceObject::Frontend::MenuModule') eq 'HASH' ) {
        my %Menus   = %{ $ConfigObject->Get('GovernanceObject::Frontend::MenuModule') };
        my $Counter = 0;
        for my $Menu ( sort keys %Menus ) {

            # load module
            if ( $Kernel::OM->Get('Kernel::System::Main')->Require( $Menus{$Menu}->{Module} ) ) {

                my $Object = $Menus{$Menu}->{Module}->new(
                    %{$Self},
                    GovernanceObjectID => $Self->{GovernanceObjectID},
                );

                # set classes
                if ( $Menus{$Menu}->{Target} ) {

                    if ( $Menus{$Menu}->{Target} eq 'PopUp' ) {
                        $Menus{$Menu}->{MenuClass} = 'AsPopup';
                    }
                    elsif ( $Menus{$Menu}->{Target} eq 'Back' ) {
                        $Menus{$Menu}->{MenuClass} = 'HistoryBack';
                    }

                }

                # run module
                $Counter = $Object->Run(
                    %Param,
                    GovernanceObject => $GovernanceObject,
                    Counter    => $Counter,
                    Config     => $Menus{$Menu},
                    MenuID     => $Menu,
                );
            }
            else {
                return $LayoutObject->FatalError();
            }
        }
    }

    # set incident signal
    my %InciSignals = (
        Translatable('operational') => 'greenled',
        Translatable('warning')     => 'yellowled',
        Translatable('incident')    => 'redled',
    );

    # to store the color for the ZTSM Statuss
    my %DeplSignals;

    # get general catalog object
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # get list of ZTSM Statuss
    my $DeploymentStatesList = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::GovernanceObject::Status',
    );

    # set deployment style colors
    my $StyleClasses = '';

    ITEMID:
    for my $ItemID ( sort keys %{$DeploymentStatesList} ) {

        # get ZTSM Status preferences
        my %Preferences = $GeneralCatalogObject->GeneralCatalogPreferencesGet(
            ItemID => $ItemID,
        );

        # check if a color is defined in preferences
        next ITEMID unless $Preferences{Color};
        my ($Color) = $Preferences{Color}->@*;
        next ITEMID unless $Color;

        # get ZTSM Status
        my $ZTSMStatus = $DeploymentStatesList->{$ItemID};

        # remove any non ascii word characters
        $ZTSMStatus =~ s{ [^a-zA-Z0-9] }{_}msxg;

        # store the original ZTSM Status as key
        # and the ss safe coverted ZTSM Status as value
        $DeplSignals{ $DeploymentStatesList->{$ItemID} } = $ZTSMStatus;

        # covert to lower case
        my $ZTSMStatusColor = lc($Color) =~ s/[^0-9a-f]//msgr;

        # add to style classes string
        $StyleClasses .= "
            .Flag span.$ZTSMStatus {
                background-color: #$ZTSMStatusColor;
            }
        ";
    }

    # wrap into style tags
    if ($StyleClasses) {
        $StyleClasses = "<style>$StyleClasses</style>";
    }

    # build version selection
    my $BaseLink = $LayoutObject->Output(
        Template => '[% Env("Baselink") %]Action=AgentGovernanceObjectZoom;'
            . "GovernanceObjectID=$GovernanceObject->{GovernanceObjectID};"
    );

    my @VersionSelectionData = map {
        {
            Key   => ( $BaseLink . "VersionID=$_->{VersionID}" ),
            Value => (
                "Version " . ( $_->{VersionString} || $_->{VersionID} )
            ),
        }
    } $VersionList->@*;

    my $VersionSelection = $LayoutObject->BuildSelection(
        Data         => \@VersionSelectionData,
        Name         => 'VersionSelection',
        Class        => 'Modernize',
        SelectedID   => $VersionID ? $BaseLink . "VersionID=$VersionID" : undef,
        PossibleNone => 1,
    );

    $LayoutObject->Block(
        Name => 'SelectionRow',
        Data => {
            VersionSelection => $VersionSelection,
        },
    );

    # output header
    my $Output = $LayoutObject->Header( Value => "GO#$GovernanceObject->{Number}" );
    $Output .= $LayoutObject->NavigationBar();

    # if a version already exists (TODO: When does it not?)
    if ( $GovernanceObject->{Name} ) {

        # transform ascii to html
        my $GovernanceObjectName = $LayoutObject->Ascii2Html(
            Text           => $GovernanceObject->{Name},
            HTMLResultMode => 1,
            LinkFeature    => 1,
        );

        # output name
        $LayoutObject->Block(
            Name => 'Data',
            Data => {
                Name        => Translatable('Name'),
                Description => Translatable('The name of this Governance Object'),
                Value       => $GovernanceObjectName,
                Identation  => 10,
            },
        );

        # output ZTSM Status
        $LayoutObject->Block(
            Name => 'Data',
            Data => {
                Name        => Translatable('ZTSM Status'),
                Description => Translatable('The ZTSM Status of this Governance Object'),
                Value       => $LayoutObject->{LanguageObject}->Translate(
                    $GovernanceObject->{ZTSMStatus},
                ),
                Identation => 10,
            },
        );

        my $Definition = $GovernanceObjectObject->DefinitionGet(
            DefinitionID => $GovernanceObject->{DefinitionID},
        );

        my %GroupLookup;
        my @Pages;
        my $PageShown;
        my $PageRequested = $ParamObject->GetParam( Param => 'Page' );
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

            push @Pages, $Page;

            if ( $PageRequested && $Page->{Name} eq $PageRequested ) {
                $PageShown = $Page;
            }

        }

        $PageShown //= @Pages ? $Pages[0] : undef;

        if ( scalar @Pages == 1 ) {

            $LayoutObject->Block(
                Name => 'PageName',
                Data => {
                    PageName => $Pages[0]{Name},
                },
            );
        }
        else {
            for my $Page (@Pages) {

                $LayoutObject->Block(
                    Name => 'PageLink',
                    Data => {
                        PageName     => $Page->{Name},
                        GovernanceObjectID => $GovernanceObject->{GovernanceObjectID},
                        VersionID    => $GetParamVersionID,
                        Selected     => $Page->{Name} eq $PageShown->{Name},
                    },
                );
            }
        }

        if (@Pages) {
            $GovernanceObject->{DynamicFieldHTML} = $Kernel::OM->Get('Kernel::Output::HTML::GovernanceObject::DynamicField')->PageRender(
                GovernanceObject => $GovernanceObject,
                Definition => $Definition,
                PageRef    => $PageShown // $Pages[0],
            );
        }

    }

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # get create & change user data
    for my $Key (qw(Create Change)) {
        $GovernanceObject->{ $Key . 'ByUserFullName' } = $UserObject->UserName(
            UserID => $GovernanceObject->{ $Key . 'By' },
        );
    }

    # output meta block
    $LayoutObject->Block(
        Name => 'Meta',
        Data => {
            %{$GovernanceObject},
            CurInciSignal => $InciSignals{ $GovernanceObject->{ZTSMStatusType} },
            CurDeplSignal => $DeplSignals{ $GovernanceObject->{ZTSMStatus} },
        },
    );

    # get linked objects
    my $LinkListWithData = $Kernel::OM->Get('Kernel::System::LinkObject')->LinkListWithData(
        Object => 'GovernanceObject',
        Key    => $GovernanceObjectID,
        State  => 'Valid',
        UserID => $Self->{UserID},
    );

    # get link table view mode
    my $LinkTableViewMode = $ConfigObject->Get('LinkObject::ViewMode');

    # create the link table
    my $LinkTableStrg = $LayoutObject->LinkObjectTableCreate(
        LinkListWithData => $LinkListWithData,
        ViewMode         => $LinkTableViewMode,
        Object           => 'GovernanceObject',
        Key              => $GovernanceObjectID,
    );

    # output the link table
    if ($LinkTableStrg) {
        $LayoutObject->Block(
            Name => 'LinkTable' . $LinkTableViewMode,
            Data => {
                LinkTableStrg => $LinkTableStrg,
            },
        );
    }

    my @Attachments = $GovernanceObjectObject->GovernanceObjectAttachmentList(
        GovernanceObjectID => $GovernanceObjectID,
    );

    my @NonInlineAttachments;

    ATTACHMENT:
    for my $Attachment (@Attachments) {

        # get the metadata of the current attachment
        my $AttachmentData = $GovernanceObjectObject->GovernanceObjectAttachmentGet(
            GovernanceObjectID => $GovernanceObjectID,
            Filename     => $Attachment,
        );
        push @NonInlineAttachments, $AttachmentData;
    }

    if (@NonInlineAttachments) {

        $LayoutObject->Block(
            Name => 'Attachments',
        );

        ATTACHMENT:
        for my $AttachmentData (@NonInlineAttachments) {

            $LayoutObject->Block(
                Name => 'AttachmentRow',
                Data => {
                    GovernanceObjectID => $GovernanceObjectID,
                    Filename     => $AttachmentData->{Filename},
                    Filesize     => $AttachmentData->{Filesize},
                },
            );
        }
    }

    # handle DownloadAttachment
    if ( $Self->{Subaction} eq 'DownloadAttachment' ) {

        # get data for attachment
        my $Filename       = $ParamObject->GetParam( Param => 'Filename' );
        my $AttachmentData = $GovernanceObjectObject->GovernanceObjectAttachmentGet(
            GovernanceObjectID => $GovernanceObjectID,
            Filename     => $Filename,
        );

        # return error if file does not exist
        if ( !$AttachmentData ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Message  => "No such attachment ($Filename)!",
                Priority => 'error',
            );
            return $LayoutObject->ErrorScreen();
        }

        return $LayoutObject->Attachment(
            %{$AttachmentData},
            Type => 'attachment',
        );
    }

    # store last screen
    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenView',
        Value     => $Self->{RequestedURL},
    );

    $LayoutObject->AddJSData(
        Key   => 'UserGovernanceObjectZoomTableHeight',
        Value => $Self->{Session}{UserGovernanceObjectZoomTableHeight},
    );

    # start template output
    return join '',
        $Output,
        $LayoutObject->Output(
            TemplateFile => 'AgentGovernanceObjectZoom',
            Data         => {
                $GovernanceObject->%*,
                CurInciSignal => $InciSignals{ $GovernanceObject->{ZTSMStatusType} },
                CurDeplSignal => $DeplSignals{ $GovernanceObject->{ZTSMStatus} },
                StyleClasses  => $StyleClasses,
            },
        ),
        $LayoutObject->Footer;
}

1;
