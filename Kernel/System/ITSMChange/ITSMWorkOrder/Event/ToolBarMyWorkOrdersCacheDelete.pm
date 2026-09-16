# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2021 Rother OSS GmbH, https://otobo.de/
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

package Kernel::System::ITSMChange::ITSMWorkOrder::Event::ToolBarMyWorkOrdersCacheDelete;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Data Event Config UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # set the cache type prefix
    my $CacheTypePrefix = 'ITSMChangeManagementToolBarMyWorkOrders';

    # handle adding of a workorder
    if ( $Param{Event} eq 'WorkOrderAddPost' ) {

        # do nothing if the WorkOrderAgentID was not set
        return 1 if !$Param{Data}->{WorkOrderAgentID};

        # set the cache type
        my $CacheType = $CacheTypePrefix . $Param{Data}->{WorkOrderAgentID};

        # delete the cache
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
            Type => $CacheType,
        );

        return 1;
    }

    # handle update of a workorder
    elsif ( $Param{Event} eq 'WorkOrderUpdatePost' ) {

        # make sure the data is initialized
        $Param{Data}->{WorkOrderAgentID} ||= '';
        $Param{Data}->{OldWorkOrderData}->{WorkOrderAgentID} ||= '';

        # do nothing if the WorkOrderAgentID did not change
        return 1
            if $Param{Data}->{WorkOrderAgentID} eq
            $Param{Data}->{OldWorkOrderData}->{WorkOrderAgentID};

        # set the cache type postfix
        my @CacheTypePostfixes = (
            $Param{Data}->{WorkOrderAgentID},
            $Param{Data}->{OldWorkOrderData}->{WorkOrderAgentID},
        );

        # delete the cache for the old and the current workorder agent
        CACHETYPEPOSTFIX:
        for my $CacheTypePostfix (@CacheTypePostfixes) {

            # do nothing if the WorkOrderAgentID was not set
            next CACHETYPEPOSTFIX if !$CacheTypePostfix;

            # set the cache type
            my $CacheType = $CacheTypePrefix . $CacheTypePostfix;

            # delete the cache
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
                Type => $CacheType,
            );
        }

        return 1;
    }

    # handle deleting a workorder
    elsif ( $Param{Event} eq 'WorkOrderDeletePost' ) {

        # do nothing if the WorkOrderAgentID was not set
        return 1 if !$Param{Data}->{OldWorkOrderData}->{WorkOrderAgentID};

        # set the cache type
        my $CacheType = $CacheTypePrefix . $Param{Data}->{OldWorkOrderData}->{WorkOrderAgentID};

        # delete the cache
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
            Type => $CacheType,
        );

        return 1;
    }

    return 1;
}

1;
