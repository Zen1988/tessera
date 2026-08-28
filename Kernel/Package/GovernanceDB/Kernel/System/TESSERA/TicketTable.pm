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

package Kernel::System::TESSERA::TicketTable;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::System::CSV',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GovernanceObject::Document',
    'Kernel::System::HTMLUtils',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Service',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
    'Kernel::System::User',
);

my @HEADERS = qw(
    ticket_id
    type
    parent
    title
    description
    application
    environment
    location
    created_date
    created_by
    customer_data
    ownergroup
    owner
    state
    service
    service_payload
);

my %HEADER_TO_DF = (
    parent      => 'ZTicket-Parent',
    application => 'ZTicket-Application',
    environment => 'ZTicket-Env',
    location    => 'ZTicket-Location',
    ownergroup  => 'ZTicket-OwnerGroup',
    owner       => 'ZTicket-Owner',
);

sub new {
    my ($Type) = @_;

    return bless {}, $Type;
}

sub Headers {
    return [@HEADERS];
}

sub Export {
    my ( $Self, %Param ) = @_;

    my $Rows = $Self->RowsExport(%Param);
    return if !defined $Rows;

    my @Data;
    for my $Row ( @{$Rows} ) {
        push @Data, [ map { $Row->{$_} // '' } @HEADERS ];
    }

    return $Kernel::OM->Get('Kernel::System::CSV')->Array2CSV(
        Head      => [@HEADERS],
        Data      => \@Data,
        Separator => ',',
        Format    => ( lc( $Param{Format} || 'csv' ) eq 'xlsx' ? 'Excel' : 'CSV' ),
    );
}

sub RowsExport {
    my ( $Self, %Param ) = @_;

    my $TicketIDs = $Param{TicketIDs};
    if ( !IsArrayRefWithData($TicketIDs) ) {
        $TicketIDs = $Self->_TicketIDsParse( Text => $Param{TicketIDText} );
    }
    if ( !IsArrayRefWithData($TicketIDs) ) {
        $TicketIDs = $Self->_ReadableTicketIDsSearch(
            UserID => $Param{UserID} || 1,
            Limit  => $Param{Limit}  || 10000,
        );
    }

    return [] if !IsArrayRefWithData($TicketIDs);

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my @Rows;

    TICKETID:
    for my $TicketID ( @{$TicketIDs} ) {
        next TICKETID if !$TicketID;
        next TICKETID if !$TicketObject->TicketPermission(
            Type     => 'ro',
            TicketID => $TicketID,
            UserID   => $Param{UserID} || 1,
            LogNo    => 1,
        );

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $Param{UserID} || 1,
        );
        next TICKETID if !%Ticket;

        push @Rows, $Self->_RowFromTicket(
            Ticket => \%Ticket,
            UserID => $Param{UserID} || 1,
        );
    }

    return \@Rows;
}

sub ImportCSV {
    my ( $Self, %Param ) = @_;

    my $Array = $Kernel::OM->Get('Kernel::System::CSV')->CSV2Array(
        String    => $Param{Content} // '',
        Separator => ',',
        Quote     => '"',
    );

    if ( !IsArrayRefWithData($Array) || !IsArrayRefWithData( $Array->[0] ) ) {
        return {
            Success => 0,
            Message => 'CSV import did not contain a header row.',
        };
    }

    my @Header = map { $Self->_NormalizeHeader($_) } @{ shift @{$Array} };
    my %Known  = map { $_ => 1 } @HEADERS;

    my $Updated = 0;
    my @Errors;

    ROW:
    for my $Index ( 0 .. $#{$Array} ) {
        my $RawRow = $Array->[$Index];
        next ROW if !IsArrayRefWithData($RawRow);

        my %Row;
        for my $Column ( 0 .. $#Header ) {
            next if !$Known{ $Header[$Column] };
            $Row{ $Header[$Column] } = $RawRow->[$Column];
        }

        my $Result = $Self->RowImport(
            Row    => \%Row,
            UserID => $Param{UserID} || 1,
        );

        if ( IsHashRefWithData($Result) && $Result->{Success} ) {
            $Updated++;
            next ROW;
        }

        push @Errors, 'Row ' . ( $Index + 2 ) . ': ' . ( $Result->{Message} || 'Import failed.' );
    }

    return {
        Success => @Errors ? 0 : 1,
        Message => @Errors ? join( "\n", @Errors ) : "Updated $Updated ticket(s).",
        Updated => $Updated,
        Errors  => \@Errors,
    };
}

sub RowImport {
    my ( $Self, %Param ) = @_;

    my $Row = $Param{Row};
    return { Success => 0, Message => 'Row is empty.' } if !IsHashRefWithData($Row);

    my $TicketID = $Row->{ticket_id} || '';
    $TicketID =~ s{\A\s+|\s+\z}{}g;
    return { Success => 0, Message => 'ticket_id is required for CSV ticket import updates.' } if !$TicketID;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Ticket       = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $Param{UserID} || 1,
    );
    return { Success => 0, Message => "TicketID $TicketID could not be loaded." } if !%Ticket;

    my $UserID = $Param{UserID} || 1;
    return { Success => 0, Message => "TicketID $TicketID is not writable by this user." }
        if !$TicketObject->TicketPermission(
            Type     => 'rw',
            TicketID => $TicketID,
            UserID   => $UserID,
            LogNo    => 1,
        );

    if ( defined $Row->{title} && $Row->{title} ne '' ) {
        $TicketObject->TicketTitleUpdate(
            TicketID => $TicketID,
            Title    => $Row->{title},
            UserID   => $UserID,
        );
    }

    if ( defined $Row->{type} && $Row->{type} ne '' ) {
        $TicketObject->TicketTypeSet(
            TicketID => $TicketID,
            Type     => $Row->{type},
            UserID   => $UserID,
        );
    }

    if ( defined $Row->{state} && $Row->{state} ne '' ) {
        $TicketObject->TicketStateSet(
            TicketID => $TicketID,
            State    => $Row->{state},
            UserID   => $UserID,
        );
    }

    if ( defined $Row->{service} && $Row->{service} ne '' ) {
        $TicketObject->TicketServiceSet(
            TicketID => $TicketID,
            Service  => $Row->{service},
            UserID   => $UserID,
        );
    }

    if ( defined $Row->{customer_data} && $Row->{customer_data} ne '' ) {
        my $CustomerData = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Row->{customer_data},
        );
        if ( !IsHashRefWithData($CustomerData) ) {
            return { Success => 0, Message => "TicketID $TicketID customer_data is not a JSON object." };
        }

        $TicketObject->TicketCustomerSet(
            TicketID => $TicketID,
            No       => $CustomerData->{customer_id},
            User     => $CustomerData->{customer_user_id},
            UserID   => $UserID,
        );
    }

    for my $Header ( sort keys %HEADER_TO_DF ) {
        next if !exists $Row->{$Header};
        $Self->_TicketDynamicFieldSet(
            TicketID  => $TicketID,
            FieldName => $HEADER_TO_DF{$Header},
            Value     => $Self->_ScalarValueNormalize( $Row->{$Header} ),
            UserID    => $UserID,
        );
    }

    if ( defined $Row->{service_payload} && $Row->{service_payload} ne '' ) {
        my $Payload = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Row->{service_payload},
        );
        if ( !IsHashRefWithData($Payload) ) {
            return { Success => 0, Message => "TicketID $TicketID service_payload is not a JSON object." };
        }

        %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $UserID,
        );
        my $AllowedFields = $Self->_ServiceFieldNames( ServiceID => $Ticket{ServiceID} );
        my %Allowed = IsArrayRefWithData($AllowedFields) ? map { $_ => 1 } @{$AllowedFields} : ();

        FIELD:
        for my $FieldName ( sort keys %{$Payload} ) {
            next FIELD if $FieldName !~ m{\AZ[A-Za-z0-9]+-[A-Za-z0-9-]+\z};
            next FIELD if %Allowed && !$Allowed{$FieldName};

            $Self->_TicketDynamicFieldSet(
                TicketID  => $TicketID,
                FieldName => $FieldName,
                Value     => $Payload->{$FieldName},
                UserID    => $UserID,
            );
        }
    }

    $TicketObject->HistoryAdd(
        TicketID     => $TicketID,
        HistoryType  => 'Misc',
        Name         => 'TESSERA CSV ticket import update',
        CreateUserID => $UserID,
    );

    return {
        Success  => 1,
        TicketID => $TicketID,
        Message  => "TicketID $TicketID updated.",
    };
}

sub _RowFromTicket {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $UserID = $Param{UserID} || 1;

    my $CreatedBy = $Ticket->{CreateBy}
        ? $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserID  => $Ticket->{CreateBy},
            Silent  => 1,
        ) || $Ticket->{CreateBy}
        : '';

    my %CustomerData = (
        customer_id      => $Ticket->{CustomerID}     // '',
        customer_user_id => $Ticket->{CustomerUserID} // '',
    );

    my $Service = '';
    if ( $Ticket->{ServiceID} ) {
        $Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceLookup(
            ServiceID => $Ticket->{ServiceID},
        ) || '';
    }

    return {
        ticket_id       => $Ticket->{TicketID} // '',
        type            => $Ticket->{Type} // '',
        parent          => $Self->_PortableDynamicFieldValue( Ticket => $Ticket, Name => 'ZTicket-Parent', UserID => $UserID ),
        title           => $Ticket->{Title} // '',
        description     => $Self->_DescriptionGet( TicketID => $Ticket->{TicketID} ),
        application     => $Self->_PortableDynamicFieldValue( Ticket => $Ticket, Name => 'ZTicket-Application', UserID => $UserID ),
        environment     => $Self->_PortableDynamicFieldValue( Ticket => $Ticket, Name => 'ZTicket-Env', UserID => $UserID ),
        location        => $Self->_PortableDynamicFieldValue( Ticket => $Ticket, Name => 'ZTicket-Location', UserID => $UserID ),
        created_date    => $Ticket->{Created} // $Ticket->{CreateTime} // '',
        created_by      => $CreatedBy,
        customer_data   => $Kernel::OM->Get('Kernel::System::JSON')->Encode( Data => \%CustomerData ) || '',
        ownergroup      => $Self->_PortableDynamicFieldValue( Ticket => $Ticket, Name => 'ZTicket-OwnerGroup', UserID => $UserID ),
        owner           => $Self->_PortableDynamicFieldValue( Ticket => $Ticket, Name => 'ZTicket-Owner', UserID => $UserID ),
        state           => $Ticket->{State} // '',
        service         => $Service,
        service_payload => $Self->_ServicePayloadJSON(
            Ticket => $Ticket,
            UserID => $UserID,
        ),
    };
}

sub _DescriptionGet {
    my ( $Self, %Param ) = @_;

    return '' if !$Param{TicketID};

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my @Articles      = $ArticleObject->ArticleList(
        TicketID  => $Param{TicketID},
        OnlyFirst => 1,
    );
    return '' if !IsArrayRefWithData(\@Articles);

    my %Article = $ArticleObject->BackendForArticle( %{ $Articles[0] } )->ArticleGet( %{ $Articles[0] } );

    my $Body = $Article{Body} // '';
    $Body =~ s{\r\n}{\n}g;

    return $Self->_RichTextToText($Body);
}

sub _ServicePayloadJSON {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return '{}' if !IsHashRefWithData($Ticket) || !$Ticket->{ServiceID};

    my $FieldNames = $Self->_ServiceFieldNames( ServiceID => $Ticket->{ServiceID} );
    return '{}' if !IsArrayRefWithData($FieldNames);

    my %Payload;
    FIELD:
    for my $FieldName ( @{$FieldNames} ) {
        my $Key = 'DynamicField_' . $FieldName;
        next FIELD if !exists $Ticket->{$Key};
        next FIELD if !defined $Ticket->{$Key};

        my $Value = $Ticket->{$Key};
        my $Config = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $FieldName );
        if ( IsHashRefWithData($Config) ) {
            $Value = $Kernel::OM->Get('Kernel::System::GovernanceObject::Document')->ValueForExport(
                DynamicFieldConfig => $Config,
                Value              => $Value,
                UserID             => $Param{UserID} || 1,
            );
        }
        $Payload{$FieldName} = $Value;
    }

    return $Kernel::OM->Get('Kernel::System::JSON')->Encode( Data => \%Payload ) || '{}';
}

sub _PortableDynamicFieldValue {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Ticket}->{ 'DynamicField_' . $Param{Name} };
    return '' if !defined $Value;

    my $Config = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $Param{Name} );
    return $Value if !IsHashRefWithData($Config);

    my $PortableValue = $Kernel::OM->Get('Kernel::System::GovernanceObject::Document')->ValueForExport(
        DynamicFieldConfig => $Config,
        Value              => $Value,
        UserID             => $Param{UserID} || 1,
    );
    return defined $PortableValue ? $PortableValue : '';
}

sub _ServiceFieldNames {
    my ( $Self, %Param ) = @_;

    return if !$Param{ServiceID};

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $ServiceFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZService-Field',
    );
    return if !IsHashRefWithData($ServiceFieldConfig);
    return if ( $ServiceFieldConfig->{ObjectType} || '' ) ne 'Service';

    my $Value = $BackendObject->ValueGet(
        DynamicFieldConfig => $ServiceFieldConfig,
        ObjectID           => $Param{ServiceID},
        UserID             => 1,
    );
    return if !defined $Value;

    my @RawValues = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);
    my @FieldNames;
    my %Seen;

    VALUE:
    for my $RawValue (@RawValues) {
        next VALUE if !defined $RawValue || $RawValue eq '';

        PART:
        for my $Part ( split m{\s*[|,;\r\n]\s*}, $RawValue ) {
            $Part =~ s{\A\s+|\s+\z}{}g;
            next PART if !$Part;

            my ($FieldName) = split m{\s*:\s*}, $Part, 2;
            $FieldName =~ s{\A\s+|\s+\z}{}g;
            $FieldName =~ s{\ADynamicField_}{};
            next PART if !$FieldName || $Seen{$FieldName}++;

            push @FieldNames, $FieldName;
        }
    }

    return \@FieldNames if @FieldNames;
    return;
}

sub _TicketDynamicFieldSet {
    my ( $Self, %Param ) = @_;

    return if !$Param{TicketID} || !$Param{FieldName};

    my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        Name => $Param{FieldName},
    );
    return if !IsHashRefWithData($DynamicFieldConfig);
    return if ( $DynamicFieldConfig->{ObjectType} || '' ) ne 'Ticket';

    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
        Value              => $Param{Value},
        UserID             => $Param{UserID} || 1,
    );
}

sub _TicketIDsParse {
    my ( $Self, %Param ) = @_;

    my $Text = $Param{Text} // '';
    my @IDs;
    my %Seen;

    for my $Part ( split m{[\s,;]+}, $Text ) {
        $Part =~ s{\A\s+|\s+\z}{}g;
        next if !$Part;
        next if $Part !~ m{\A\d+\z};
        next if $Seen{$Part}++;
        push @IDs, $Part;
    }

    return \@IDs;
}

sub _ReadableTicketIDsSearch {
    my ( $Self, %Param ) = @_;

    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        Result       => 'ARRAY',
        UserID       => $Param{UserID} || 1,
        Permission   => 'ro',
        ArchiveFlags => [ 'y', 'n' ],
        SortBy       => 'Age',
        OrderBy      => 'Down',
        Limit        => $Param{Limit} || 10000,
    );

    return \@TicketIDs;
}

sub _NormalizeHeader {
    my ( $Self, $Header ) = @_;

    $Header //= '';
    $Header =~ s{\A\s+|\s+\z}{}g;
    $Header = lc $Header;
    $Header =~ s{[^a-z0-9]+}{_}g;
    $Header =~ s{\A_+|_+\z}{}g;

    return $Header;
}

sub _ScalarValueNormalize {
    my ( $Self, $Value ) = @_;

    return if !defined $Value;
    return $Value if ref $Value;

    $Value =~ s{\A\s+|\s+\z}{}g;
    return $Value;
}

sub _RichTextToText {
    my ( $Self, $Value ) = @_;
    return '' if !defined $Value;
    return $Value if ref $Value;
    my $Text = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii( String => $Value );
    $Text //= '';
    $Text =~ s{\x{00a0}}{ }g;
    $Text =~ s{\r\n}{\n}g;
    $Text =~ s{[ \t]+\n}{\n}g;
    $Text =~ s{\n{3,}}{\n\n}g;
    $Text =~ s{\A\s+|\s+\z}{}g;
    return $Text;
}

1;
