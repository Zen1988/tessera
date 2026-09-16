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

# TODO: when merging to Core, adapt handling to be the same as with "MarkAsImportant"(found in AgentTicketZoom)

package Kernel::Output::HTML::ArticleAction::ArticlePin;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub CheckAccess {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Needed (qw(Ticket Article ChannelName UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Define action and get its frontend module registration.
    my $Action       = 'AgentTicketArticlePin';
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Config       = $ConfigObject->Get('Frontend::Module')->{$Action};
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $Permission = 0;

    # check if module is registered
    return if !$Config;

    # check Acl
    return if !$Param{AclActionLookup}->{$Action};

    # Get group names from config.
    my @GroupNames   = @{ $Config->{Group}   || [] };
    my @GroupRoNames = @{ $Config->{GroupRo} || [] };

    push( @GroupNames, @GroupRoNames );

    # If access is restricted, allow access only if user has appropriate permissions in configured group(s).
    if (@GroupNames) {
        my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

        # Get user groups, where the user has the appropriate permissions.
        my %Groups = $GroupObject->GroupMemberList(
            UserID => $Param{UserID},
            Type   => 'rw',
            Result => 'HASH',
        );

        GROUP:
        for my $GroupName (@GroupNames) {
            next GROUP if !$GroupName;

            # Get the group ID.
            my $GroupID = $GroupObject->GroupLookup(
                Group => $GroupName,
            );
            next GROUP if !$GroupID;

            # Stop checking if membership in at least one group is found.
            if ( $Groups{$GroupID} ) {
                $Permission = 1;
                last GROUP;
            }
        }
    }

    # Otherwise, always allow access.
    else {
        $Permission = 1;
    }

    if ( $Permission == 1 ) {

        my $PinConfig = $ConfigObject->Get('Ticket::Frontend::AgentTicketArticlePin');

        if ( $PinConfig->{Permission} ) {
            my $Ok = $TicketObject->TicketPermission(
                Type     => $PinConfig->{Permission},
                TicketID => $Param{Ticket}->{TicketID},
                UserID   => $Param{UserID},
                LogNo    => 1,
            );
            return if !$Ok;
        }

        if ( $PinConfig->{RequiredLock} ) {
            my $Locked = $TicketObject->TicketLockGet(
                TicketID => $Param{Ticket}->{TicketID}
            );
            if ($Locked) {
                my $AccessOk = $TicketObject->OwnerCheck(
                    TicketID => $Param{Ticket}->{TicketID},
                    OwnerID  => $Param{UserID},
                );
                return if !$AccessOk;
            }
            else {
                return;
            }
        }
    }
    else {
        return;
    }
    return 1;
}

sub GetConfig {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Needed (qw(Ticket Article UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # use user id 1 because articles are pinned for all users
    my %ArticleFlags = $Kernel::OM->Get('Kernel::System::Ticket::Article')->ArticleFlagGet(
        ArticleID => $Param{Article}->{ArticleID},
        UserID    => 1,
    );

    my $ArticleIsPinned = $ArticleFlags{Pinned};

    my $Link        = "Action=AgentTicketArticlePin;TicketID=$Param{Ticket}->{TicketID};ArticleID=$Param{Article}->{ArticleID}";
    my $Description = Translatable('Pin');
    if ($ArticleIsPinned) {
        $Description = Translatable('Unpin');
    }

    # set important menu item
    my %MenuItem = (
        ItemType    => 'Link',
        Description => $Description,
        Name        => $Description,
        Link        => $Link,
    );

    return ( \%MenuItem );
}

1;
