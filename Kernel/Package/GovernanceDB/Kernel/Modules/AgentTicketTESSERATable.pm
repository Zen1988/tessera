# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2019-2026 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::Modules::AgentTicketTESSERATable;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    return bless {%Param}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject       = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject      = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketTableObject = $Kernel::OM->Get('Kernel::System::TESSERA::TicketTable');

    my $Subaction = $Self->{Subaction} || '';
    my $TicketID  = $ParamObject->GetParam( Param => 'TicketID' ) || '';
    my $CanImport = $Self->_CanImport();

    if ( $Subaction eq 'Export' ) {
        my $Format = lc( $ParamObject->GetParam( Param => 'Format' ) || 'csv' );
        $Format = $Format eq 'xlsx' ? 'xlsx' : 'csv';

        my $TicketIDText = $ParamObject->GetParam( Param => 'TicketIDs' );
        $TicketIDText = $TicketID if !defined $TicketIDText;
        my $Content      = $TicketTableObject->Export(
            TicketIDText => $TicketIDText,
            Format       => $Format,
            UserID       => $Self->{UserID},
            Limit        => 10000,
        );

        return $LayoutObject->ErrorScreen(
            Message => Translatable('No ticket rows were available for export.'),
        ) if !defined $Content;

        my $Timestamp   = $Kernel::OM->Create('Kernel::System::DateTime')->ToString();
        my $ContentType = $Format eq 'xlsx'
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'text/csv; charset=' . $LayoutObject->{Charset};

        return $LayoutObject->Attachment(
            ContentType => $ContentType,
            Content     => $Content,
            Type        => 'attachment',
            Filename    => "TESSERA_Tickets_$Timestamp.$Format",
            NoCache     => 1,
        );
    }

    my $Message      = '';
    my $MessageClass = '';

    if ( $Subaction eq 'Import' && !$CanImport ) {
        $Message      = Translatable('Only IPC users can import ticket CSV files.');
        $MessageClass = 'Error';
    }
    elsif ( $Subaction eq 'Import' ) {
        $LayoutObject->ChallengeTokenCheck();

        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'FileUpload',
        );

        my $Result = $TicketTableObject->ImportCSV(
            Content => $UploadStuff{Content},
            UserID  => $Self->{UserID},
        );

        $Message      = IsHashRefWithData($Result) ? $Result->{Message} : Translatable('CSV import failed.');
        $MessageClass = IsHashRefWithData($Result) && $Result->{Success} ? 'Success' : 'Error';
    }

    return join '',
        $LayoutObject->Header(
            Title => Translatable('TESSERA Ticket Import/Export'),
        ),
        $LayoutObject->NavigationBar(),
        $LayoutObject->Output(
            TemplateFile => 'AgentTicketTESSERATable',
            Data         => {
                %Param,
                TicketID     => $TicketID,
                TicketIDs    => $TicketID,
                ExportScope  => $TicketID ? 'CurrentTicket' : 'ReadableTickets',
                Headers      => join( ', ', @{ $TicketTableObject->Headers() } ),
                Message      => $Message,
                MessageClass => $MessageClass,
                CanImport    => $CanImport,
            },
        ),
        $LayoutObject->Footer();
}

sub _CanImport {
    my ($Self) = @_;

    return if !$Self->{UserID};

    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

    return 1 if $GroupObject->PermissionCheck(
        UserID    => $Self->{UserID},
        GroupName => 'IPC',
        Type      => 'rw',
    );

    my %Roles = $GroupObject->PermissionUserRoleGet(
        UserID => $Self->{UserID},
    );

    return 1 if grep { $_ && $_ eq 'IPC' } values %Roles;

    return;
}

1;
