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

package Kernel::System::FAQ::RelatedArticle;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::HTMLUtils',
);

=head1 NAME

Kernel::System::FAQ::RelatedArticle - sub module of Kernel::System::FAQ

=head1 DESCRIPTION

All related faq article functions.

=head1 PUBLIC INTERFACE

=head2 RelatedAgentArticleList()

Get the related faq article list for the given subject and body.

    my @RelatedAgentArticleList = $FAQObject->RelatedAgentArticleList(
        Subject   => 'Title Example',
        Body      => 'Text Example',  # possible with html tags (will be removed for the search)
        Languages =>[ 'en' ],         # optional
        Limit     => 10,              # optional
        UserID    => 1,
    );

Returns

    my @RelatedAgentArticleList = (
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
    );

=cut

sub RelatedAgentArticleList {
    my ( $Self, %Param ) = @_;

    return $Self->_RelatedArticleList(%Param);
}

=head2 RelatedCustomerArticleList()

Get the related faq article list for the given subject and body.

    my @RelatedCustomerArticleList = $FAQObject->RelatedCustomerArticleList(
        Subject   => 'Title Example',
        Body      => 'Text Example',  # possible with html tags (will be removed for the search)
        ServiceID => $ServiceID,      # optional
        Languages => [ 'en' ],        # optional
        Limit     => 10,              # optional
        UserID    => 1,
    );

Returns

    my @RelatedCustomerArticleList = (
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
    );

=cut

sub RelatedCustomerArticleList {
    my ( $Self, %Param ) = @_;

    return $Self->_RelatedArticleList(
        %Param,
        CustomerUser => $Param{UserID},
        UserID       => 1,
    );
}

# FAQ Service

=head2 RelatedCustomerServiceArticleList()

Get the service related faq article list for the given subject and body.

    my @RelatedCustomerArticleList = $FAQObject->RelatedCustomerServiceArticleList(
        Languages =>[ 'en' ],         # optional # TODO
        Limit     => 10,              # optional
        UserID    => 1,
        ServiceID => 1,
    );

Returns

    my @RelatedCustomerServiceArticleList = (
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
    );

=cut

sub RelatedCustomerServiceArticleList {
    my ( $Self, %Param ) = @_;

    for my $Argument (qw(UserID ServiceID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    my $FAQServiceArticles = $Self->FAQServiceArticlesGet(
        ServiceID => $Param{ServiceID},
        Limit     => $Param{Limit},
    );

    my %LookupRelatedFAQArticles;

    for my $FAQArticleID ( @{$FAQServiceArticles} ) {

        my %FAQArticleData = $Self->FAQGet(
            ItemID => $FAQArticleID,
            UserID => $Param{UserID},
        );

        # $FAQArticleData{Votes}
        $LookupRelatedFAQArticles{$FAQArticleID} = {
            %FAQArticleData,
        };

    }

    # To save the related faq article from the lookup hash.
    my @RelatedFAQArticleList = map { $LookupRelatedFAQArticles{$_} } sort keys %LookupRelatedFAQArticles;

    return @RelatedFAQArticleList;
}

# eo FAQ Service

=head1 PRIVATE FUNCTIONS

=head2 _RelatedArticleList()

Get the related faq article list for the given subject and body.

    my @RelatedArticleList = $FAQObject->_RelatedArticleList(
        Subject      => 'Title Example',
        Body         => 'Text Example',  # possible with html tags (will be removed for the search)
        ServiceID    => $ServiceID,      # optional
        Languages    =>[ 'en' ],         # optional
        Limit        => 10,              # optional
        CustomerUser => 'joe'            # optional
        UserID       => 1,
    );

Returns

    my @RelatedArticleList = (
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
    );

=cut

sub _RelatedArticleList {
    my ( $Self, %Param ) = @_;

    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my @Content;

    FIELD:
    for my $Field (qw(Subject Body)) {

        # Get ASCII content form the given body, to have no html tags for the check.
        if ( $Field eq 'Body' ) {
            $Param{$Field} = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
                String => $Param{$Field},
            );
        }

        next FIELD if !$Param{$Field};

        push @Content, $Param{$Field};
    }

    return if !@Content;

    # To save the keywords and the counter for the different keywords.
    my %ContentKeywords = $Self->_BuildKeywordCounterFromContent(
        Content => \@Content
    );

    return if !%ContentKeywords;

    # Get the keyword article list for the given languages.
    my %FAQKeywordArticleList = $Self->FAQKeywordArticleList(%Param);

    return if !%FAQKeywordArticleList;

    return $Self->_BuildRelatedFAQArticleList(
        ContentKeywords    => \%ContentKeywords,
        KeywordArticleList => \%FAQKeywordArticleList,
        Limit              => $Param{Limit},
        UserID             => $Param{UserID},
    );
}

=head2 _BuildRelatedFAQArticleList()

Build the related faq article list from the given content keywords and article keyword relation.

    my @RelatedArticleList = $FAQObject->_BuildRelatedFAQArticleList(
        ContentKeywords => {
            example => 1,
            test    => 3,
            faq     => 6,
        },
        KeywordArticleList => {
            'ExampleKeyword' => [
                12,
                13,
            ],
            'TestKeyword' => [
                876,
            ],
        },
        Limit  => 10, # optional
        UserID => 1,
    );

Returns

    my @RelatedArticleList = (
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
        {
            ItemID       => 123,
            Title        => 'FAQ Title',
            CategoryName => 'Misc',
            Created      => '2014-10-10 10:10:00',
        },
    );

=cut

sub _BuildRelatedFAQArticleList {
    my ( $Self, %Param ) = @_;

    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    return if !IsHashRefWithData( $Param{ContentKeywords} );
    return if !IsHashRefWithData( $Param{KeywordArticleList} );

    # Save given parameters in own variables for better usage.
    my %ContentKeywords    = %{ $Param{ContentKeywords} };
    my %KeywordArticleList = %{ $Param{KeywordArticleList} };

    # Build the related faq articles and save a quantifier for the different articles with the relevance
    #   from the keyword, which is related to the faq article.
    # E.g.
    #   - FAQArticle 1 with keywords:  'itsm', 'changemanagement', 'ticket'
    #   - FAQArticle 2 with keywords: 'itsm', 'changemangement'
    #   - FAQArticle 3 with keywords: 'ticket'
    # Given Keyword from text (with counter):
    #   - changemanagement (5)
    #   - ticket (4)
    #   - itsm (1)
    # Result (FAQArticleID => Calculated Quantifier):
    #   - FAQArticle 1 => 11
    #   - FAQArticle 2 => 6
    #   - FAQArticle 3 => 4
    my %LookupRelatedFAQArticles;

    CONTENTKEYWORD:
    for my $ContentKeyword ( sort keys %ContentKeywords ) {

        next CONTENTKEYWORD if !IsArrayRefWithData( $KeywordArticleList{$ContentKeyword} );

        FAQARTICLEID:
        for my $FAQArticleID ( @{ $KeywordArticleList{$ContentKeyword} } ) {

            if ( !$LookupRelatedFAQArticles{$FAQArticleID} ) {

                my %FAQArticleData = $Self->FAQGet(
                    ItemID => $FAQArticleID,
                    UserID => $Param{UserID},
                );

                if ( $FAQArticleData{Votes} ) {
                    $FAQArticleData{StarCounter} = int( $FAQArticleData{VoteResult} * 0.05 );

                    # Add 1 because lowest value should be always 1.
                    if ( $FAQArticleData{StarCounter} < 5 ) {
                        $FAQArticleData{StarCounter}++;
                    }
                }

                # Add the FAQ article data to the related FAQ articles.
                $LookupRelatedFAQArticles{$FAQArticleID} = {
                    %FAQArticleData,
                    KeywordCounter => $ContentKeywords{$ContentKeyword},
                };
            }
            else {

                # Increase the quantifier, if the article has more then one relevant keyword.
                $LookupRelatedFAQArticles{$FAQArticleID}->{KeywordCounter} += $ContentKeywords{$ContentKeyword};
            }
        }
    }

    # To save the related faq article from the lookup hash.
    my @RelatedFAQArticleList = map { $LookupRelatedFAQArticles{$_} } sort keys %LookupRelatedFAQArticles;

    # Sort the results from the plug-ins by 'keyword quantifier', 'change time' and 'id (create time)'.
    @RelatedFAQArticleList = sort {
        $b->{KeywordCounter} <=> $a->{KeywordCounter}
            || $b->{Changed} cmp $a->{Changed}
            || int $b->{ID} <=> int $a->{ID}
    } @RelatedFAQArticleList;

    # Cut the not needed articles from the array, if a limit is given.
    if ( $Param{Limit} && scalar @RelatedFAQArticleList > $Param{Limit} ) {
        splice @RelatedFAQArticleList, $Param{Limit};
    }

    return @RelatedFAQArticleList;
}

=head2 _BuildKeywordCounterFromContent()

Build the keywords for the given content.

    my $Content = $FAQObject->_BuildKeywordCounterFromContent(
        Content => 'Some Text with a link. More text. [1] https://otobo.de/',
    );

Returns

    %ContentKeywords = (
        example => 1,
        test    => 3,
        faq     => 6,
        ...
    );

=cut

sub _BuildKeywordCounterFromContent {
    my ( $Self, %Param ) = @_;

    return if !IsArrayRefWithData( $Param{Content} );

    my %ContentKeywords;

    # Strip not wanted stuff from the given subject and body.
    for my $Content ( @{ $Param{Content} } ) {

        $Content ||= '';

        # Remove the links from the content.
        $Content = $Self->_RemoveLinksFromContent(
            Content => $Content,
        );

        # Split the text in word and save the word as the given keywords (separator is a whitespace).
        $Content =~ s{[\.\,\;\:](\s|\s? \Z )}{ }xmsg;
        my @FieldKeywords = ( $Content =~ m{ [\w\x{0980}-\x{09FF}\-]+\.?[\w\x{0980}-\x{09FF}\-]* }xmsg );

        KEYWORD:
        for my $Keyword (@FieldKeywords) {

            # Save the keywords always as lower case.
            $Keyword = lc $Keyword;

            # Increase the keyword counter from the text content, to increase the relevance for this keyword.
            $ContentKeywords{$Keyword}++;
        }
    }

    return %ContentKeywords;
}

=head2 _RemoveLinksFromContent()

Remove links from the given content.

    my $Content = $FAQObject->_RemoveLinksFromContent(
        Content => 'Some Text with a link. More text. [1] https://otobo.de/',
    );

Returns

    $Content = 'Some Text with a link. More text.';

=cut

sub _RemoveLinksFromContent {
    my ( $Self, %Param ) = @_;

    $Param{Content} =~ s{ \[\d*\] }{}xmsg;
    $Param{Content} =~ s{ https://[^\s]* }{}xmsg;

    return $Param{Content};
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTOBO project (L<https://otobo.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
