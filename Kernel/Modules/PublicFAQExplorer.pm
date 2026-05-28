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

package Kernel::Modules::PublicFAQExplorer;

use strict;
use warnings;
use Kernel::Language qw(Translatable);

use MIME::Base64 qw();

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # set UserID to root because in public interface there is no user
    $Self->{UserID} = 1;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config of frontend module
    my $Config = $ConfigObject->Get("FAQ::Frontend::$Self->{Action}");

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get config data
    my $StartHit        = int( $ParamObject->GetParam( Param => 'StartHit' ) || 1 );
    my $SearchLimit     = $Config->{SearchLimit}     || 200;
    my $SearchPageShown = $Config->{SearchPageShown} || 3;
    my $SortBy          = $ParamObject->GetParam( Param => 'SortBy' )
        || $Config->{'SortBy::Default'}
        || 'FAQID';
    my $OrderBy = $ParamObject->GetParam( Param => 'Order' )
        || $Config->{'Order::Default'}
        || 'Down';

    # get Item ID
    my $ItemID = $ParamObject->GetParam( Param => 'ItemID' ) || 0;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check if ItemID parameter was sent and redirect to FAQ article zoom screen
    if ($ItemID) {

        # redirect to FAQ zoom
        return $LayoutObject->Redirect( OP => 'Action=PublicFAQZoom;ItemID=' . $ItemID );
    }

    my $CategoryID = $ParamObject->GetParam( Param => 'CategoryID' ) || 0;

    # check for non numeric CategoryID
    if ( $CategoryID !~ /\d+/ ) {
        $CategoryID = 0;
    }

    # get category by name
    my $Category = $ParamObject->GetParam( Param => 'Category' ) || '';

    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');

    # try to get the category ID from category name if no category ID
    if ( $Category && !$CategoryID ) {

        # get the category tree
        my $CategoryTree = $FAQObject->CategoryTreeList(
            UserID => 1,
        );

        # reverse the has for easy lookup
        my %ReverseCategoryTree = reverse %{$CategoryTree};

        $CategoryID = $ReverseCategoryTree{$Category} || 0;
    }

    # try to get the category data
    my %CategoryData;
    if ($CategoryID) {

        # get category data
        %CategoryData = $FAQObject->CategoryGet(
            CategoryID => $CategoryID,
            UserID     => $Self->{UserID},
        );
        if ( !%CategoryData ) {

            return $LayoutObject->CustomerNoPermission(
                WithHeader => 'yes',
            );
        }
    }

    # add RSS feed link for new FAQ articles in the browser URL bar
    $LayoutObject->Block(
        Name => 'MetaLink',
        Data => {
            Rel   => 'alternate',
            Type  => 'application/rss+xml',
            Title =>
                $LayoutObject->{LanguageObject}->Translate('FAQ Articles (new created)'),
            Href => $LayoutObject->{Baselink} . 'Action=PublicFAQRSS;Type=Created',
        },
    );

    # add RSS feed link for changed FAQ articles in the browser URL bar
    $LayoutObject->Block(
        Name => 'MetaLink',
        Data => {
            Rel   => 'alternate',
            Type  => 'application/rss+xml',
            Title =>
                $LayoutObject->{LanguageObject}->Translate('FAQ Articles (recently changed)'),
            Href => $LayoutObject->{Baselink} . 'Action=PublicFAQRSS;Type=Changed',
        },
    );

    # add RSS feed link for Top-10 FAQ articles in the browser URL bar
    $LayoutObject->Block(
        Name => 'MetaLink',
        Data => {
            Rel   => 'alternate',
            Type  => 'application/rss+xml',
            Title => $LayoutObject->{LanguageObject}->Translate('FAQ Articles (Top 10)'),
            Href  => $LayoutObject->{Baselink} . 'Action=PublicFAQRSS;Type=Top10',
        },
    );

    my $Output = $LayoutObject->CustomerHeader();

    my $CategoryIDsRef;
    my %Search;
    my %FAQSearch;

    # show search results
    if ( $Self->{Subaction} && $Self->{Subaction} eq 'Search' ) {
        my $SearchName = Translatable("Search") . ":";
        for my $Mode (qw/Keyword What/) {
            my $String = $ParamObject->GetParam( Param => $Mode );
            if ($String) {
                $Search{$Mode}    = $String;
                $FAQSearch{$Mode} = "*$String*";
                my $ModeName = $Mode eq 'What' ? 'Fulltext' : $Mode;
                $SearchName .= " " . Translatable($ModeName) . " \"$String\";";
            }
        }

        # output category root ( done in LayoutObject for non searches )
        $LayoutObject->Block(
            Name => 'FAQPathCategoryElement',
            Data => {
                Name       => $ConfigObject->Get('FAQ::Default::RootCategoryName'),
                CategoryID => 0,
            },
        );

        # output search information
        $LayoutObject->Block(
            Name => 'FAQPathCategoryElementNoLink',
            Data => {
                Name => $SearchName,
            },
        );

        # disable category specific stuff
        $CategoryID = -1;
    }

    # no search ( standard mode )
    else {
        # show FAQ path
        $LayoutObject->FAQPathShow(
            FAQObject  => $FAQObject,
            CategoryID => $CategoryID,
            UserID     => $Self->{UserID},
        );

        # get all direct subcategories of the selected category
        $CategoryIDsRef = $FAQObject->PublicCategorySearch(
            ParentID => $CategoryID,
            Mode     => 'Public',
            UserID   => $Self->{UserID},
        );
    }

    # get interface state list
    my $InterfaceStates = $FAQObject->StateTypeList(
        Types  => $ConfigObject->Get('FAQ::Public::StateTypes'),
        UserID => $Self->{UserID},
    );

    # check if there are subcategories
    if ( $CategoryIDsRef && ref $CategoryIDsRef eq 'ARRAY' && @{$CategoryIDsRef} ) {

        # show subcategories list
        $LayoutObject->Block(
            Name => 'Subcategories',
            Data => {},
        );
        $LayoutObject->Block(
            Name => 'OverviewResult',
            Data => {},
        );

        # show data for each subcategory
        for my $SubCategoryID ( @{$CategoryIDsRef} ) {

            my %SubCategoryData = $FAQObject->CategoryGet(
                CategoryID => $SubCategoryID,
                UserID     => $Self->{UserID},
            );

            # get the number of subcategories of this subcategory
            $SubCategoryData{SubCategoryCount} = $FAQObject->CategoryCount(
                ParentIDs => [$SubCategoryID],
                UserID    => $Self->{UserID},
            );

            # get the number of FAQ articles in this category
            $SubCategoryData{ArticleCount} = $FAQObject->FAQCount(
                CategoryIDs  => [$SubCategoryID],
                ItemStates   => $InterfaceStates,
                OnlyApproved => 1,
                Valid        => 1,
                UserID       => $Self->{UserID},
            );

            # output the category data
            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {%SubCategoryData},
            );
        }
    }

    # set default interface settings
    my $Interface = $FAQObject->StateTypeGet(
        Name   => 'public',
        UserID => $Self->{UserID},
    );

    # include Category if not in base Category (0), or search mode
    if ( $CategoryID > 0 ) {
        $FAQSearch{CategoryIDs} = [$CategoryID];
    }

    # get the latest articles for the root category (else empty)
    elsif ( !%Search ) {
        $SortBy      = 'Changed';
        $OrderBy     = 'Down';
        $SearchLimit = 10;
    }

    # search all FAQ articles within the given category
    my @ViewableItemIDs = $FAQObject->FAQSearch(
        OrderBy          => [$SortBy],
        OrderByDirection => [$OrderBy],
        Limit            => $SearchLimit,
        UserID           => $Self->{UserID},
        States           => $InterfaceStates,
        Interface        => $Interface,
        %FAQSearch,
    );

    # set the SortBy Class
    my $SortClass;

    # this sets the opposite to the OrderBy parameter
    if ( $OrderBy eq 'Down' ) {
        $SortClass = 'SortAscending';
    }
    elsif ( $OrderBy eq 'Up' ) {
        $SortClass = 'SortDescending';
    }

    # set the SortBy Class to the correct field
    my %CSSSort;
    my $CSSSortBy = $SortBy . 'Sort';
    $CSSSort{$CSSSortBy} = $SortClass;

    my %NewOrder = (
        Down => 'Up',
        Up   => 'Down',
    );

    # show the FAQ article list
    $LayoutObject->Block(
        Name => 'FAQItemList',
        Data => {
            CategoryID => $CategoryID,
            %CSSSort,
            Order => $NewOrder{$OrderBy},
        },
    );

    # get multi language default option
    my $MultiLanguage = $ConfigObject->Get('FAQ::MultiLanguage');

    # show language header
    if ($MultiLanguage) {
        $LayoutObject->Block(
            Name => 'HeaderLanguage',
            Data => {
                CategoryID => $CategoryID,
                %CSSSort,
                Order => $NewOrder{$OrderBy},
            },
        );
    }

    my $Counter = 0;
    if (@ViewableItemIDs) {

        # create back link for FAQ Zoom screen
        my $ZoomBackLink = "Action=PublicFAQExplorer;CategoryID=$CategoryID;"
            . "SortBy=$SortBy;Order=$OrderBy;StartHit=$StartHit";

        # encode back link to Base64 for easy HTML transport
        $ZoomBackLink = MIME::Base64::encode_base64($ZoomBackLink);

        for my $ItemID (@ViewableItemIDs) {

            $Counter++;

            # build search result
            if (
                $Counter >= $StartHit
                && $Counter < ( $SearchPageShown + $StartHit )
                )
            {

                my %FAQData = $FAQObject->FAQGet(
                    ItemID     => $ItemID,
                    ItemFields => 0,
                    UserID     => $Self->{UserID},
                );

                $FAQData{CleanTitle} = $FAQObject->FAQArticleTitleClean(
                    Title => $FAQData{Title},
                    Size  => $Config->{TitleSize},
                );

                # add blocks to template
                $LayoutObject->Block(
                    Name => 'Record',
                    Data => {
                        %FAQData,
                        ZoomBackLink => $ZoomBackLink,
                    },
                );

                # add language data
                if ($MultiLanguage) {
                    $LayoutObject->Block(
                        Name => 'RecordLanguage',
                        Data => {
                            %FAQData,
                        },
                    );
                }
            }
        }
    }

    # otherwise a no data found message is displayed
    else {
        $LayoutObject->Block(
            Name => 'NoFAQDataFoundMsg',
        );
    }

    my $Link = 'SortBy=' . $LayoutObject->LinkEncode($SortBy) . ';';
    $Link .= 'Order=' . $LayoutObject->LinkEncode($OrderBy) . ';';

    my $ActionString;
    if (%Search) {
        $ActionString = "Action=PublicFAQExplorer;Subaction=Search;";
        if ( $FAQSearch{CategoryIDs} ) {
            $ActionString .= "CategoryID=$CategoryID;";
        }
        for my $Mode ( keys %Search ) {
            $ActionString .= "$Mode=$Search{ $Mode };";
        }
    }
    else {
        $ActionString = "Action=PublicFAQExplorer;CategoryID=$CategoryID";
    }

    # build search navigation bar
    my %PageNav = $LayoutObject->PageNavBar(
        Limit     => $SearchLimit,
        StartHit  => $StartHit,
        PageShown => $SearchPageShown,
        AllHits   => $Counter,
        Action    => "Action=PublicFAQExplorer;CategoryID=$CategoryID",
        Link      => $Link,
        IDPrefix  => "PublicFAQExplorer",
    );

    # show footer filter - show only if more the one page is available
    if ( defined $PageNav{TotalHits} && ( $PageNav{TotalHits} > $SearchPageShown ) ) {
        $LayoutObject->Block(
            Name => 'Pagination',
            Data => {
                %Param,
                %PageNav,
            },
        );
    }

    my $SearchBackLink = "Action=PublicFAQExplorer;CategoryID=$CategoryID";

    # encode back link to Base64 for easy HTML transport
    $SearchBackLink = MIME::Base64::encode_base64($SearchBackLink);

    # show QuickSearch
    $LayoutObject->FAQShowQuickSearch(
        Mode            => 'Public',
        Interface       => $Interface,
        InterfaceStates => $InterfaceStates,
        SearchBackLink  => $SearchBackLink,
        UserID          => $Self->{UserID},
    );

    # show last added and last updated articles
    for my $Type (qw(LastCreate LastChange)) {

        my $ShowOk = $LayoutObject->FAQShowLatestNewsBox(
            FAQObject       => $FAQObject,
            Type            => $Type,
            Mode            => 'Public',
            CategoryID      => $CategoryID,
            Interface       => $Interface,
            InterfaceStates => $InterfaceStates,
            UserID          => $Self->{UserID},
        );
        if ( !$ShowOk ) {
            return $LayoutObject->ErrorScreen();
        }
    }

    # show top ten articles
    my $ShowOk = $LayoutObject->FAQShowTop10(
        FAQObject       => $FAQObject,
        Mode            => 'Public',
        CategoryID      => $CategoryID,
        Interface       => $Interface,
        InterfaceStates => $InterfaceStates,
        UserID          => $Self->{UserID},
    );
    if ( !$ShowOk ) {
        return $LayoutObject->ErrorScreen();
    }

    $Output .= $LayoutObject->Output(
        TemplateFile => 'PublicFAQExplorer',
        Data         => {
            %Param,
            CategoryID => $CategoryID,
            %CategoryData,
        },
    );
    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

1;
