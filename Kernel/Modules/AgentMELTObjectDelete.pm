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
package Kernel::Modules::AgentMELTObjectDelete;

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

    # get needed MELTObjectID
    my $RequestObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $MELTObjectID = $RequestObject->GetParam( Param => 'MELTObjectID' );
    my $AJAX = $RequestObject->GetParam( Param => 'AJAX' );

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check needed stuff
    if ( !$MELTObjectID ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No MELTObjectID is given!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # get MELT Object object
    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    # get config of frontend module
    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get("MELTObject::Frontend::$Self->{Action}");

    # check permissions
    my $Access = $MELTObjectObject->Permission(
        Type   => $Self->{Config}->{Permission},
        Scope  => 'Item',
        Action => $Self->{Action},
        ItemID => $MELTObjectID,
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

    # get MELT Object data
    my $MELTObject = $MELTObjectObject->MELTObjectGet(
        MELTObjectID => $MELTObjectID,
    );

    # check if MELT Object is found
    if ( !$MELTObject ) {
        return $LayoutObject->ErrorScreen(
            Message =>
                $LayoutObject->{LanguageObject}->Translate( 'MELT Object "%s" not found in database!', $MELTObjectID ),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # delete the MELT Object
    if ( $Self->{Subaction} eq 'MELTObjectDelete' ) {

        # delete the MELT Object
        my $CouldDeleteMELTObject = $MELTObjectObject->MELTObjectDelete(
            MELTObjectID => $MELTObjectID,
            UserID       => $Self->{UserID},
        );

        if ($CouldDeleteMELTObject) {

            # redirect to MELT Object overview, when the deletion was successful
            return $LayoutObject->Redirect(
                OP => "Action=AgentMELTObject",
            );
        }
        else {

            # show error message, when delete failed
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Was not able to delete the MELT Object ID %s!', $MELTObjectID ),
                Comment => Translatable('Please contact the administrator.'),
            );
        }
    }

    if ( !$MELTObject->{VersionID} ) {
        return $LayoutObject->ErrorScreen(
            Message =>
                $LayoutObject->{LanguageObject}->Translate( 'No version found for MELTObjectID %s!', $MELTObjectID ),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    # set the dialog type. As default, the dialog will have 2 buttons: Yes and No
    my $DialogType = 'Confirmation';

    # output content
    my $Output = $LayoutObject->Output(
        TemplateFile => 'AgentMELTObjectDelete',
        Data         => {
            %Param,
            %{$MELTObject},
            FullPage => $AJAX ? 0 : 1,
        },
    );

    # The delete link must also work when the confirmation JavaScript is
    # unavailable, instead of displaying an AJAX JSON response as a page.
    if ( !$AJAX ) {
        return join '',
            $LayoutObject->Header( Title => Translatable('Delete MELT Object') ),
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

