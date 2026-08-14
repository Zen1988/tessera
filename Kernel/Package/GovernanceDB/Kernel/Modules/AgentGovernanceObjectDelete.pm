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
package Kernel::Modules::AgentGovernanceObjectDelete;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed GovernanceObjectID
    my $RequestObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $GovernanceObjectID = $RequestObject->GetParam( Param => 'GovernanceObjectID' );
    my $AJAX = $RequestObject->GetParam( Param => 'AJAX' );

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check needed stuff
    if ( !$GovernanceObjectID ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No GovernanceObjectID is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get Governance Object object
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    # get config of frontend module
    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get("GovernanceObject::Frontend::$Self->{Action}");

    # check permissions
    my $Access = $GovernanceObjectObject->Permission(
        Type   => $Self->{Config}->{Permission},
        Scope  => 'Item',
        Action => $Self->{Action},
        ItemID => $GovernanceObjectID,
        UserID => $Self->{UserID},
    );

    # error screen
    if ( !$Access ) {
        return $LayoutObject->NoPermission(
            Message =>
                $LayoutObject->{LanguageObject}->Translate( 'You need %s permissions!', $Self->{Config}->{Permission} ),
            WithHeader => 'yes',
        );
    }

    # get Governance Object data
    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        GovernanceObjectID => $GovernanceObjectID,
    );

    # check if Governance Object is found
    if ( !$GovernanceObject ) {
        return $LayoutObject->ErrorScreen(
            Message =>
                $LayoutObject->{LanguageObject}->Translate( 'Governance Object "%s" not found in database!', $GovernanceObjectID ),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # delete the Governance Object
    if ( $Self->{Subaction} eq 'GovernanceObjectDelete' ) {

        # delete the Governance Object
        my $CouldDeleteGovernanceObject = $GovernanceObjectObject->GovernanceObjectDelete(
            GovernanceObjectID => $GovernanceObjectID,
            UserID       => $Self->{UserID},
        );

        if ($CouldDeleteGovernanceObject) {

            # redirect to Governance Object overview, when the deletion was successful
            return $LayoutObject->Redirect(
                OP => "Action=AgentGovernanceObject",
            );
        }
        else {

            # show error message, when delete failed
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Was not able to delete the Governance Object ID %s!', $GovernanceObjectID ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }
    }

    if ( !$GovernanceObject->{VersionID} ) {
        return $LayoutObject->ErrorScreen(
            Message =>
                $LayoutObject->{LanguageObject}->Translate( 'No version found for GovernanceObjectID %s!', $GovernanceObjectID ),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # set the dialog type. As default, the dialog will have 2 buttons: Yes and No
    my $DialogType = 'Confirmation';

    # output content
    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentGovernanceObjectDelete',
        Data         => {
            %Param,
            %{$GovernanceObject},
            FullPage => $AJAX ? 0 : 1,
        },
    );

    # ConfirmDialog normally requests this action through AJAX. Keep a complete
    # accessible fallback page for missing/stale JavaScript so JSON is never
    # exposed as a raw browser document.
    if ( !$AJAX ) {
        return join '',
            $LayoutObject->Header( Title => Translatable('Delete Governance Object') ),
            $Output,
            $LayoutObject->Footer();
    }

    # build the returned data structure
    my %Data = (
        HTML       => $Output,
        DialogType => $DialogType,
    );

    # return JSON-String because of AJAX-Mode
    my $OutputJSON = $LayoutObject->JSONEncode( Data => \%Data );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $OutputJSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

1;
