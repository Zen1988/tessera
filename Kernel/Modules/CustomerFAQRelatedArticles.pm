# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Modules::CustomerFAQRelatedArticles;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $JSON = '';

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $Subject   = $ParamObject->GetParam( Param => 'Subject' );
    my $Body      = $ParamObject->GetParam( Param => 'Body' );
    my $ServiceID = $ParamObject->GetParam( Param => 'ServiceID' );

    my @RelatedFAQArticleList;
    my $RelatedFAQArticleFoundNothing;

    my $Config       = $Kernel::OM->Get('Kernel::Config')->Get("FAQ::Frontend::$Self->{Action}");
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get FAQs by service only, if FAQ::Customer::RelatedArticlesOnServiceOnly
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $FAQServicesEnabled = $ConfigObject->Get('FAQ::Service');
    my $ShowOnServiceOnly  = $ConfigObject->Get('FAQ::Customer::RelatedArticlesOnServiceOnly');
    my %ServiceID          = $FAQServicesEnabled ? ( ServiceID => $ServiceID ) : ();

    if ( $FAQServicesEnabled && !$ServiceID ) {
        $RelatedFAQArticleFoundNothing = 1;
    }
    elsif ( $FAQServicesEnabled && $ShowOnServiceOnly && $ServiceID ) {

        # Get the language from the user and add the default languages from the config.
        my $RelatedArticleLanguages = $Config->{'DefaultLanguages'} || [];

        # Check if the user language already exists.
        my %LookupRelatedFAQArticlesLanguage = map { $_ => 1 } @{$RelatedArticleLanguages};
        if ( !$LookupRelatedFAQArticlesLanguage{ $LayoutObject->{UserLanguage} } ) {
            push @{$RelatedArticleLanguages}, $LayoutObject->{UserLanguage};
        }

        @RelatedFAQArticleList = $Kernel::OM->Get('Kernel::System::FAQ')->RelatedCustomerServiceArticleList(
            %ServiceID,
            Languages => $RelatedArticleLanguages,
            Limit     => $Config->{ShowLimit} || 10,
            UserID    => $Self->{UserID},
        );

        if ( !@RelatedFAQArticleList ) {
            $RelatedFAQArticleFoundNothing = 1;
        }
    }
    elsif ( $Subject || $Body ) {

        # Get the language from the user and add the default languages from the config.
        my $RelatedArticleLanguages = $Config->{'DefaultLanguages'} || [];

        # Check if the user language already exists.
        my %LookupRelatedFAQArticlesLanguage = map { $_ => 1 } @{$RelatedArticleLanguages};
        if ( !$LookupRelatedFAQArticlesLanguage{ $LayoutObject->{UserLanguage} } ) {
            push @{$RelatedArticleLanguages}, $LayoutObject->{UserLanguage};
        }

        @RelatedFAQArticleList = $Kernel::OM->Get('Kernel::System::FAQ')->RelatedCustomerArticleList(
            %ServiceID,
            Subject   => $Subject,
            Body      => $Body,
            Languages => $RelatedArticleLanguages,
            Limit     => $Config->{ShowLimit} || 10,
            UserID    => $Self->{UserID},
        );

        if ( !@RelatedFAQArticleList ) {
            $RelatedFAQArticleFoundNothing = 1;
        }
    }

    # Generate the html for the widget.
    my $CustomerRelatedFAQArticlesHTMLString = $LayoutObject->Output(
        TemplateFile => 'CustomerFAQRelatedArticles',
        Data         => {
            RelatedFAQArticleList         => \@RelatedFAQArticleList,
            RelatedFAQArticleFoundNothing => $RelatedFAQArticleFoundNothing,
            VoteStarsVisible              => $Config->{VoteStarsVisible},
        },
    );

    $JSON = $LayoutObject->JSONEncode(
        Data => {
            CustomerRelatedFAQArticlesHTMLString => $CustomerRelatedFAQArticlesHTMLString,
        },
    );

    # build empty JSON output if JSON is empty
    if ( !$JSON ) {
        $JSON = $LayoutObject->JSONEncode(
            Data => {},
        );
    }

    # send JSON response
    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

1;
