# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
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

## no critic (Modules::RequireExplicitPackage)

use Kernel::System::Queue ();    ## no perlimports

package Kernel::System::Queue;   ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;
use warnings;
use v5.24;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Queue',
    'Kernel::System::StandardTemplate',
    'Kernel::System::Valid',
);

sub ExportQueueTemplates {
    my ( $Self, %Param ) = @_;

    my %QueueFilter;
    if ( IsArrayRefWithData( $Param{Queues} ) ) {
        %QueueFilter = map { $_ => 1 } $Param{Queues}->@*;
    }

    # get necessary objects
    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');

    # fetch lookup lists
    my %QueueList = $QueueObject->QueueList(
        Valid => 0,
    );

    my %ExportData;
    QUEUEID:
    for my $QueueID ( sort keys %QueueList ) {

        my %QueueData = $QueueObject->QueueGet(
            ID => $QueueID,
        );

        if (%QueueFilter) {
            next QUEUEID unless $QueueFilter{ $QueueData{Name} };
        }

        # get assigned templates
        my %QueueTemplates = $QueueObject->QueueStandardTemplateMemberList(
            QueueID => $QueueID,
        );

        my @QueueTemplates = values %QueueTemplates;

        $ExportData{ $QueueData{Name} } = \@QueueTemplates;
    }

    return \%ExportData;
}

sub ImportQueueTemplates {
    my ( $Self, %Param ) = @_;

    my $UserID = $Self->{UserID} || $Param{UserID};

    # get necessary objects
    my $QueueObject            = $Kernel::OM->Get('Kernel::System::Queue');
    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');

    # fetch lookup lists
    my %QueueList = $QueueObject->QueueList(
        Valid => 0,
    );
    my %QueueLookup          = reverse %QueueList;
    my %StandardTemplateList = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
    );
    my %StandardTemplateLookup = reverse %StandardTemplateList;

    QUEUENAME:
    for my $QueueName ( keys $Param{QueueTemplates}->%* ) {
        my $QueueTemplates = $Param{QueueTemplates}{$QueueName};

        my $QueueID = $QueueLookup{$QueueName};

        # skip queues which do not exist on the system
        next QUEUENAME unless $QueueID;

        TEMPLATENAME:
        for my $TemplateName ( $QueueTemplates->@* ) {

            # my $Active = $TemplatesSelected{$TemplateID} ? 1 : 0;

            my $StandardTemplateID = $StandardTemplateLookup{$TemplateName};

            next TEMPLATE unless $StandardTemplateID;

            # set customer user service member
            $QueueObject->QueueStandardTemplateMemberAdd(
                QueueID            => $QueueID,
                StandardTemplateID => $StandardTemplateID,
                Active             => 1,
                UserID             => $UserID,
            );
        }
    }

    return 1;
}

1;
