# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.de/
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
package Kernel::Modules::AgentITSMIncidentProblemManagement;

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

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $JSON;

    # Show the service incident state and signal.
    if ( $Self->{Subaction} eq 'GetServiceIncidentState' ) {

        # get the selected service id
        my $ServiceID = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'ServiceID' ) || '';

        # get service
        my %Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
            ServiceID     => $ServiceID,
            IncidentState => 1,
            UserID        => $Self->{UserID},
        );

        # build empty response hash
        my %Response = (
            CurInciSignal => '',
            CurInciState  => '&nbsp',
        );

        # only if service id is selected and incident state should be shown in this screen
        if ( $Service{CurInciStateType} && $Service{CurInciState} ) {

            # set incident signal
            my %InciSignals = (
                operational => 'greenled',
                warning     => 'yellowled',
                incident    => 'redled',
            );

            # build the response
            %Response = (
                CurInciSignal => $InciSignals{ $Service{CurInciStateType} },
                CurInciState  => $LayoutObject->{LanguageObject}->Translate( $Service{CurInciState} ),
            );
        }

        # encode response to JSON
        $JSON = $LayoutObject->JSONEncode(
            Data => \%Response,
        );
    }

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

1;
