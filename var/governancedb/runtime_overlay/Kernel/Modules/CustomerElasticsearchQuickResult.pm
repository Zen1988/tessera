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

package Kernel::Modules::CustomerElasticsearchQuickResult;

## nofilter(TidyAll::Plugin::OTOBO::Perl::DBObject)

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::Modules::CustomerElasticsearchQuickResult - ticket search via Elasticsearch

=head1 DESCRIPTION

CustomerElasticsearchQuickResult returns n-number of tickets (defined by the sysconfig) from the ES-query sorted by descending age

=head2 new()

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

=head2 Run()

Quicksearch result is updated via AJAX.

=cut

sub _TicketPageSearch {
    my (%P) = @_;
    my $ES = $P{ES};
    my %Search = %{ $P{Search} };
    my $Size = $P{PageSize};
    $Size = 10 if !defined $Size || $Size !~ /\A[1-9][0-9]*\z/;
    my $Page = $P{Page};
    $Page = 1 if !defined $Page || $Page !~ /\A[1-9][0-9]{0,8}\z/;
    my $Total = $ES->TicketSearch(%Search, Result => 'COUNT', Limit => 1, From => 0);
    $Total = 0 if !defined $Total || ref $Total || $Total !~ /\A[0-9]+\z/;
    my $Pages = $Total ? int(($Total - 1) / $Size) + 1 : 1;
    $Page = $Pages if $Page > $Pages;
    my $Result = {Total => 0, Data => []};
    if ($Total) {
        my $Fetch = sub {
            return $ES->TicketSearch(%Search, Result => 'FULL', Limit => $Size,
                From => ($Page - 1) * $Size,
                SortBy => ['Score', 'Age', 'TicketID'],
                OrderBy => ['Down', 'Down', 'Down']) || {Total => 0, Data => []};
        };
        $Result = $Fetch->();
        $Total = $Result->{Total} || 0;
        $Total = 0 if ref $Total || $Total !~ /\A[0-9]+\z/;
        $Pages = $Total ? int(($Total - 1) / $Size) + 1 : 1;
        # The index/permissions may shrink between count and page retrieval.
        # Refill at most once; never ask ES for an unbounded result set.
        if ($Page > $Pages) {
            $Page = $Pages;
            $Result = $Total ? $Fetch->() : {Total => 0, Data => []};
            $Total = $Result->{Total} || 0;
            $Total = 0 if ref $Total || $Total !~ /\A[0-9]+\z/;
            $Pages = $Total ? int(($Total - 1) / $Size) + 1 : 1;
            $Page = $Pages if $Page > $Pages;
        }
    }
    my $Shown = scalar @{ $Result->{Data} || [] };
    return { %$Result, TicketMatchCount => $Total, TicketShownCount => $Shown,
        TicketPage => $Page, TicketPages => $Pages,
        TicketPageStart => $Shown ? ($Page - 1) * $Size + 1 : 0,
        TicketPageEnd => $Shown ? ($Page - 1) * $Size + $Shown : 0,
        TicketPreviousPage => $Page > 1 ? $Page - 1 : 0,
        TicketNextPage => $Page < $Pages ? $Page + 1 : 0,
    };
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject           = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject          = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject          = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ESObject              = $Kernel::OM->Get('Kernel::System::Elasticsearch');
    my $DisableCompanyTickets = $ConfigObject->Get('Ticket::Frontend::CustomerDisableCompanyTicketAccess');

    my $SearchObjects = $ConfigObject->Get('Elasticsearch::QuickSearchShow');
    my $Count         = $SearchObjects->{Ticket} ? $SearchObjects->{Ticket}{Count} : 0;
    $Count = 0 if !defined $Count || $Count !~ /\A[1-9][0-9]*\z/;
    my $ESStrLength   = length $ParamObject->GetParam( Param => 'FulltextES' );

    # Subaction eq SearchUpdate is returned by on click and on input events of the ESfulltext-field. See Core.UI.Elasticsearch.js
    if ( $Self->{Subaction} eq 'SearchUpdate' && $ESStrLength > 1 && $Count ) {

        my $Url = $ParamObject->GetParam(
            Param => 'URL'
        );

        # check whether FAQ is installed
        my $PackageObject  = $Kernel::OM->Get('Kernel::System::Package');
        my $FAQIsInstalled = $PackageObject->PackageIsInstalled(
            Name => 'FAQ',
        );

        if ( $FAQIsInstalled && $Url =~ /Action=CustomerFAQ/ ) {

            # Search FAQ by ES sort by Number. Show $Size results.
            my $SearchResult = $ESObject->FAQSearch(
                Fulltext       => $ParamObject->GetParam( Param => 'FulltextES' ),
                UserID         => $Self->{UserID},
                UserLogin      => $Self->{UserLogin},
                Limit          => $Count,
                Result         => 'FULL',
                ExtendedSearch => 0,
            );
            my @FAQIDs = $SearchResult->{Data}->@*;

            $LayoutObject->Block(
                Name => 'FAQHeader',
            );
            for my $FAQ (@FAQIDs) {
                my ( $FAQID, $FAQParam ) = ( %{$FAQ} );

                $LayoutObject->Block(
                    Name => 'FAQRecord',
                    Data => {
                        FAQID => $FAQID,
                    },
                );

                $LayoutObject->Block(
                    Name => 'RecordFAQNumber',
                    Data => {
                        FAQID     => $FAQID,
                        FAQNumber => $FAQParam->{Number},
                    },
                );
                $LayoutObject->Block(
                    Name => 'RecordFAQTitle',
                    Data => {
                        FAQID    => $FAQID,
                        FAQTitle => $FAQParam->{Title},
                    },
                );
            }

            # Create output
            my $Output = $LayoutObject->Output(
                TemplateFile => 'CustomerElasticsearchQuickResult',
                Data         => \%Param,
            );

            #Return HTML-output back to callback function in Core.UI.Elasticsearch.js
            return $LayoutObject->Attachment(
                NoCache     => 1,
                ContentType => 'text/html',
                Charset     => $LayoutObject->{UserCharset},
                Content     => $Output || '',
                Type        => 'inline',
            );

        }

        # Add filter for customer company if the company tickets are not disabled.
        my %Selection;
        my $GlobalRead = $ESObject->CustomerGlobalTicketRead(CustomerUserID => $Self->{UserID}, Permission => 'ro');
        if ( !$GlobalRead && !$DisableCompanyTickets ) {
            my %AccessibleCustomers = $Kernel::OM->Get('Kernel::System::CustomerGroup')->GroupContextCustomers(
                CustomerUserID => $Self->{UserID},
            );
            $Selection{CustomerIDRaw} = [ keys %AccessibleCustomers ];
        }
        elsif (!$GlobalRead) {
            $Selection{CustomerUserLoginRaw} = $Self->{UserID};
        }

        # Search ticket by ES sort by age. Show $Size results.
        # Block ticket data
        my $SearchText = $ParamObject->GetParam(Param => 'FulltextES');
        my $SearchResult = _TicketPageSearch(
            ES => $ESObject,
            PageSize => $Count,
            Page => $ParamObject->GetParam(Param => 'SearchPage'),
            Search => {
            %Selection,
            Fulltext       => $SearchText,
            CustomerUserID => $Self->{UserID},
            Permission     => 'ro',
            ExtendedSearch => 0,
            },
        );
        my @TicketIDs = @{ $SearchResult->{Data} || [] };
        $LayoutObject->Block(
            Name => 'TicketHeader',
        );

        # Block ticket data
        for my $Ticket (@TicketIDs) {

            # we only have one key and one value in each array element
            my ( $TicketID, $TicketParam ) = ( %{$Ticket} );

            $LayoutObject->Block(
                Name => 'Record',
                Data => {
                    TicketID => $TicketID,
                },
            );

            my $Age = $LayoutObject->CustomerAge(
                Age   => $TicketParam->{Age},
                Space => ' ',
                Date  => $TicketParam->{Created},
            );

            $LayoutObject->Block(
                Name => 'RecordTicketAge',
                Data => {
                    TicketID  => $TicketID,
                    TicketAge => $Age,
                },
            );

            $LayoutObject->Block(
                Name => 'RecordTicketNumber',
                Data => {
                    TicketID     => $TicketID,
                    TicketNumber => $TicketParam->{TicketNumber},
                },
            );
            $LayoutObject->Block(
                Name => 'RecordTicketTitle',
                Data => {
                    TicketID    => $TicketID,
                    TicketTitle => $TicketParam->{Title},
                },
            );
        }

        # Create output
        my %PageData = map { $_ => $SearchResult->{$_} } qw(
            TicketMatchCount TicketShownCount TicketPage TicketPages
            TicketPageStart TicketPageEnd TicketPreviousPage TicketNextPage
        );
        my $Output = $LayoutObject->Output(
            TemplateFile => 'CustomerElasticsearchQuickResult',
            Data         => { %Param, %PageData, TicketSummary => 1, SearchQuery => $SearchText },
        );

        #Return HTML-output back to callback function in Core.UI.Elasticsearch.js
        return $LayoutObject->Attachment(
            NoCache     => 1,
            ContentType => 'text/html',
            Charset     => $LayoutObject->{UserCharset},
            Content     => $Output || '',
            Type        => 'inline',
        );
    }

    return $LayoutObject->Attachment(
        NoCache     => 1,
        ContentType => 'text/html',
        Charset     => $LayoutObject->{UserCharset},
        Content     => '<div/>',
        Type        => 'inline',
    );
}

1;
