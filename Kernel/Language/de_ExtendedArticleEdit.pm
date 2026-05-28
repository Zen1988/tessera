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

package Kernel::Language::de_ExtendedArticleEdit;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AgentTicketArticleEdit
    $Self->{Translation}->{'Edit Article'} = 'Artikel bearbeiten';

    # Perl Module: Kernel/Modules/AgentTicketArticleEdit.pm
    $Self->{Translation}->{'This article is not editable!'} = 'Dieser Artikel kann nicht bearbeitet werden!';

    # SysConfig
    $Self->{Translation}->{'Adds customer visibility of the article to the article edit screen of the agent interface.'} =
        'Fügt die Kundensichtbarkeit im Artikel-bearbeiten-Bildschirm von Tickets im Agentenbereich hinzu.';
    $Self->{Translation}->{'Both'} = 'Beides';
    $Self->{Translation}->{'Defines for which article types the editing of subject, body and attachment is enabled. "Both" includes "Phone" and "Internal".'} =
        'Definiert, für welche Artikel-Typen der Betreff, der Text und die Anhänge geändert werden können. "Beides" beinhaltet "Telefon" und "Intern".';
    $Self->{Translation}->{'Defines if articles written by the customer are editable.'} = 'Definiert, ob Artikel, die ein Kundenbenutzer geschrieben hat, bearbeitet werden können.';
    $Self->{Translation}->{'Enables or disables the editing of articles which are visible for the customer in general.'} =
        'Aktiviert oder deaktiviert das Bearbeiten von Artikeln, die für den Kunden sichtbar sind.';
    $Self->{Translation}->{'Internal'} = 'Intern';
    $Self->{Translation}->{'Sets the time units in the ticket note screen of the agent interface.'} =
        'Setzt die Zeitbuchung im Artikel-ändern-Bildschirm von Tickets im Agentenbereich.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
