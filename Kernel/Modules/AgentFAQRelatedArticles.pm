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

package Kernel::Modules::AgentFAQRelatedArticles;

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

    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("FAQ::Frontend::$Self->{Action}");

    my $JSON = '';

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $Subject = $ParamObject->GetParam( Param => 'Subject' );
    my $Body    = $ParamObject->GetParam( Param => 'Body' );

    my @RelatedFAQArticleList;
    my $RelatedFAQArticleFoundNothing;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $Subject || $Body ) {

        # Get the language from the user and add the default languages from the config.
        my $RelatedArticleLanguages = $Config->{'DefaultLanguages'} || [];

        # Check if the user language already exists.
        my %LookupRelatedFAQArticlesLanguage = map { $_ => 1 } @{$RelatedArticleLanguages};
        if ( !$LookupRelatedFAQArticlesLanguage{ $LayoutObject->{UserLanguage} } ) {
            push @{$RelatedArticleLanguages}, $LayoutObject->{UserLanguage};
        }

        @RelatedFAQArticleList = $Kernel::OM->Get('Kernel::System::FAQ')->RelatedAgentArticleList(
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

    if (@RelatedFAQArticleList) {

        # Generate the html for the widget.
        my $AgentRelatedFAQArticlesHTMLString = $LayoutObject->Output(
            TemplateFile => 'AgentFAQRelatedArticles',
            Data         => {
                RelatedFAQArticleList         => \@RelatedFAQArticleList,
                RelatedFAQArticleFoundNothing => $RelatedFAQArticleFoundNothing,
                VoteStarsVisible              => $Config->{VoteStarsVisible},
            },
        );

        $JSON = $LayoutObject->JSONEncode(
            Data => {
                AgentRelatedFAQArticlesHTMLString => $AgentRelatedFAQArticlesHTMLString,
                Success                           => 1,
            },
        );
    }
    else {

        $JSON = $LayoutObject->JSONEncode(
            Data => {
                Success => 0,
            },
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
