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

package Kernel::Language::pl_SystemMonitoring;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # SysConfig
    $Self->{Translation}->{'Basic mail interface to System Monitoring Suites. Use this block if the filter should run AFTER PostMasterFilter.'} =
        'Podstawowy interfejs e-mailowy dla Systemów Monitorujących. Użyj tego bloku, jeśli filtr powinien się wykonać PO PostMasterFilter.';
    $Self->{Translation}->{'Basic mail interface to System Monitoring Suites. Use this block if the filter should run BEFORE PostMasterFilter.'} =
        'Podstawowy interfejs e-mailowy dla Systemów Monitorujących. Użyj tego bloku, jeśli filtr powinien się wykonać PRZED PostMasterFilter.';
    $Self->{Translation}->{'Define Nagios acknowledge type.'}  = 'Określ typ potwierdzenia Nagiosa.';
    $Self->{Translation}->{'HTTP'}                             = 'HTTP';
    $Self->{Translation}->{'Icinga API URL.'}                  = 'URL do API Ininga';
    $Self->{Translation}->{'Icinga2 acknowledgement author.'}  = 'Autor potwierdzenia Icinga2.';
    $Self->{Translation}->{'Icinga2 acknowledgement comment.'} = 'Komentarz do potwierdzenia Icinga2.';
    $Self->{Translation}->{'Icinga2 acknowledgement enabled?'} = 'Czy potwierdzenia Icinga2 są włączone?';
    $Self->{Translation}->{'Icinga2 acknowledgement notify.'}  = 'Powiadomienie potwierdzenia Icinga2.';
    $Self->{Translation}->{'Icinga2 acknowledgement sticky.'}  = 'Przyklejone potwierdzenie Icinga2.';
    $Self->{Translation}->{'Link an already opened incident ticket with the affected CI. This is only possible when a subsequent system monitoring email arrives.'}
        =
        'Połącz już otwarte zgłoszenie zdarzenia z dotyczącym go CI. Jest to możliwe wtedy, gdy nadejdzie kolejny email z systemu monitorującego.';
    $Self->{Translation}->{'Name of the Dynamic Field for Host.'}        = 'Nazwa pola dynamicznego dla hosta.';
    $Self->{Translation}->{'Name of the Dynamic Field for Service.'}     = 'Nazwa pola dynamicznego dla Usługi';
    $Self->{Translation}->{'Named pipe acknowledge command.'}            = 'Komenda do przesyłania potwierdzeń nazwanym potokiem.';
    $Self->{Translation}->{'Named pipe acknowledge format for host.'}    = 'Format przesyłania potwierdzeń nazwanym potokiem dla hosta.';
    $Self->{Translation}->{'Named pipe acknowledge format for service.'} = 'Format przesyłania potwierdzeń nazwanym potokiem dla usługi.';
    $Self->{Translation}->{'Set the incident state of a CI automatically when a system monitoring email arrives.'} =
        'Ustaw automatycznie stan zdarzenia dla CI, gdy nadejdzie e-mail z monitoringu.';
    $Self->{Translation}->{'The HTTP acknowledge URL.'}      = 'URL HTTP dlo potwierdzeń.';
    $Self->{Translation}->{'The HTTP acknowledge password.'} = 'Hasło HTTP dla potwierdzeń.';
    $Self->{Translation}->{'The HTTP acknowledge user.'}     = 'Użytkownik HTTP dla potwierdzeń.';
    $Self->{Translation}->{'Ticket event module to send an acknowledge to Icinga2.'}
        = 'Nazwa modułu obsługi zdarzeń zgłoszenia do wysyłki potwierdzeń Icinga2.';
    $Self->{Translation}->{'Ticket event module to send an acknowledge to Nagios.'} = 'Nazwa modułu obsługi zgłoszenia do wysyłki potwierdzeń do Nagiosa.';
    $Self->{Translation}->{'pipe'}                                                  = 'potok';

    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
