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

package Kernel::System::Console::Command::Maint::SystemMonitoring::NagiosCheckTicketCount;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Main',
    'Kernel::System::Ticket',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('OTOBO Nagios checker.');
    $Self->AddOption(
        Name        => 'config-file',
        Description => "Path to configuration file.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );
    $Self->AddOption(
        Name        => 'as-checker',
        Description => "Runs the script as Nagioschecker.",
        Required    => 0,
        HasValue    => 0,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    $Self->{ConfigFile} = $Self->GetOption('config-file') || '';

    if ( !$Self->{ConfigFile} ) {
        die "ERROR: Need --config-file CONFIGFILE\n";
    }
    elsif ( !-e $Self->{ConfigFile} ) {
        die "ERROR: No such file $Self->{ConfigFile}\n";
    }

    my %Config = do $Self->{ConfigFile};
    if ( !%Config ) {
        die "ERROR: Invalid config file $Self->{ConfigFile}: $@\n";
    }

    # store config for use it later
    $Self->{Config} = \%Config;

    return 1;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Starting ticket count check...</yellow>\n");

    # read configuration
    my %Config = %{ $Self->{Config} || {} };

    # search tickets
    my $TicketCount = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        %{ $Config{Search} },
        Limit  => 100_000,
        Result => 'COUNT',
        UserID => 1,
    );

    # no checker mode
    if ( !$Self->GetOption('as-checker') ) {
        $Self->Print("$TicketCount\n");

        $Self->ExitCodeOk();
    }

    # cleanup config file
    my %Map = (
        max_crit_treshhold => 'max_crit_treshold',
        max_warn_treshhold => 'max_warn_treshold',
        min_crit_treshhold => 'min_crit_treshold',
        min_warn_treshhold => 'min_warn_treshold',
    );
    for my $Type ( sort keys %Map ) {
        if ( defined $Config{$Type} ) {
            $Self->PrintError("NOTICE: Typo in config name, use $Map{$Type} instead of $Type\n");
            $Config{ $Map{$Type} } = $Config{$Type};
            delete $Config{$Type};
        }
    }

    # do critical and warning check
    for my $Type (qw(crit_treshold warn_treshold)) {
        if ( defined $Config{ 'min_' . $Type } ) {
            if ( $Config{ 'min_' . $Type } >= $TicketCount ) {
                if ( $Type =~ /^crit_/ ) {
                    $Self->Print(
                        "$Config{checkname} CRITICAL $Config{CRIT_TXT} $TicketCount|tickets=$TicketCount;$Config{min_warn_treshold}:$Config{max_warn_treshold};$Config{min_crit_treshold}:$Config{max_crit_treshold}\n"
                    );

                    $Self->ExitCodeError(2);
                }
                elsif ( $Type =~ /^warn_/ ) {
                    $Self->Print(
                        "$Config{checkname} WARNING $Config{WARN_TXT} $TicketCount|tickets=$TicketCount;$Config{min_warn_treshold}:$Config{max_warn_treshold};$Config{min_crit_treshold}:$Config{max_crit_treshold}\n"
                    );

                    $Self->ExitCodeError();
                }
            }
        }
        if ( defined $Config{ 'max_' . $Type } ) {
            if ( $Config{ 'max_' . $Type } <= $TicketCount ) {
                if ( $Type =~ /^crit_/ ) {
                    $Self->Print(
                        "$Config{checkname} CRITICAL $Config{CRIT_TXT} $TicketCount|tickets=$TicketCount;$Config{min_warn_treshold}:$Config{max_warn_treshold};$Config{min_crit_treshold}:$Config{max_crit_treshold}\n"
                    );

                    $Self->ExitCodeError(2);
                }
                elsif ( $Type =~ /^warn_/ ) {
                    $Self->Print(
                        "$Config{checkname} WARNING $Config{WARN_TXT} $TicketCount|tickets=$TicketCount;$Config{min_warn_treshold}:$Config{max_warn_treshold};$Config{min_crit_treshold}:$Config{max_crit_treshold}\n"
                    );

                    $Self->ExitCodeError();
                }
            }
        }
    }

    # return OK
    $Self->Print(
        "$Config{checkname} OK $Config{OK_TXT} $TicketCount|tickets=$TicketCount;$Config{min_warn_treshold}:$Config{max_warn_treshold};$Config{min_crit_treshold}:$Config{max_crit_treshold}\n"
    );

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTOBO project (L<https://otobo.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
