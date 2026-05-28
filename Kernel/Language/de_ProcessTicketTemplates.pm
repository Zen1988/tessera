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

package Kernel::Language::de_ProcessTicketTemplates;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AdminProcessManagementActivityDialog
    $Self->{Translation}->{'Standard Templates'} = 'Standardvorlagen';

    # SysConfig
    $Self->{Translation}->{'Process dialog'} = 'Prozess-Dialog';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'An unconnected transition is already placed on the canvas. Please connect this transition first before placing another transition.',
    'As soon as you use this button or link, you will leave this screen and its current state will be saved automatically. Do you want to continue?',
    'Cancel',
    'Customer interface does not support articles not visible for customers.',
    'Delete',
    'Delete Entity',
    'Edit Field Details',
    'Error during AJAX communication',
    'Hide EntityIDs',
    'Save',
    'Show EntityIDs',
    'Sorry, the only existing condition can\'t be removed.',
    'Sorry, the only existing field can\'t be removed.',
    'Sorry, the only existing parameter can\'t be removed.',
    'This Activity is already used in the Process. You cannot add it twice!',
    'This Transition is already used for this Activity. You cannot use it twice!',
    'This TransitionAction is already used in this Path. You cannot use it twice!',
    );

}

1;
