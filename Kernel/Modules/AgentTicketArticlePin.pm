# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Modules::AgentTicketArticlePin;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language              qw(Translatable);

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

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');

    # Check needed stuff.
    for my $Needed (qw(TicketID ArticleID)) {
        if ( !$ParamObject->GetParam( Param => $Needed ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
        else {
            $Self->{$Needed} = $ParamObject->GetParam( Param => $Needed );
        }
    }

    # use user id 1 because articles are pinned for all users
    my %ArticleFlags = $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleFlagGet(
        ArticleID => $Self->{ArticleID},
        UserID    => 1,
    );

    my $ArticleIsPinned = $ArticleFlags{Pinned};

    if ($ArticleIsPinned) {

        # use user id 1 because articles are pinned for all users
        $ArticleObject->ArticleFlagDelete(
            TicketID  => $Self->{TicketID},
            ArticleID => $Self->{ArticleID},
            Key       => 'Pinned',
            UserID    => 1,
        );
    }
    else {

        # use user id 1 because articles are pinned for all users
        $ArticleObject->ArticleFlagSet(
            TicketID  => $Self->{TicketID},
            ArticleID => $Self->{ArticleID},
            Key       => 'Pinned',
            Value     => 1,
            UserID    => 1,
        );
    }

    return $LayoutObject->Redirect(
        OP => "Action=AgentTicketZoom;TicketID=$Self->{TicketID};ArticleID=$Self->{ArticleID}",
    );
}

1;
