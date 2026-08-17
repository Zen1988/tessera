# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::Modules::AgentMELTObject;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = bless {%Param}, $Type;

    # set debug
    $Self->{Debug} = 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $Config = $ConfigObject->Get("MELTObject::Frontend::$Self->{Action}");

    my $SortBy = $ParamObject->GetParam( Param => 'SortBy' )
        || $Config->{'SortBy::Default'}
        || 'Age';

    if ( $SortBy eq 'LastChanged' ) {
        $SortBy = 'Changed';
    }

    # Determine the default ordering to be used.
    my $DefaultOrderBy = $Config->{'Order::Default'}
        || 'Up';

    # Set the sort order from the request parameters, or take the default.
    my $OrderBy = $ParamObject->GetParam( Param => 'OrderBy' )
        || $DefaultOrderBy;

    # get session object
    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    # store last queue screen
    $SessionObject->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenOverview',
        Value     => $Self->{RequestedURL},
    );

    # store last screen
    $SessionObject->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenView',
        Value     => $Self->{RequestedURL},
    );

    # get user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # get filter from web request
    my $Filter         = $ParamObject->GetParam( Param => 'Filter' ) || '';
    my $CategoryFilter = $ParamObject->GetParam( Param => 'Category' );

    # get general catalog object
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get class list
    my $CategoryList = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::MELT::Class::Category',
    );
    my %TranslatedCategoryList = map { ( $_ => $LayoutObject->{LanguageObject}->Translate( $CategoryList->{$_} ) ) } keys $CategoryList->%*;
    my %ReverseCategoryList    = reverse %TranslatedCategoryList;
    my $DefaultCategory        = $Config->{DefaultCategory};
    my $DefaultCategoryID;
    if ( $DefaultCategory && $ReverseCategoryList{ $LayoutObject->{LanguageObject}->Translate($DefaultCategory) } ) {
        $DefaultCategoryID = $ReverseCategoryList{ $LayoutObject->{LanguageObject}->Translate( $Config->{DefaultCategory} ) };
        $CategoryFilter ||= $DefaultCategoryID;
    }

    # get filters stored in the user preferences
    my %Preferences = $UserObject->GetPreferences(
        UserID => $Self->{UserID},
    );
    my $StoredFiltersKey = 'UserStoredFilterColumns-' . $Self->{Action} . '-' . $Filter;
    my $JSONObject       = $Kernel::OM->Get('Kernel::System::JSON');
    my $StoredFilters    = $JSONObject->Decode(
        Data => $Preferences{$StoredFiltersKey},
    );

    # delete stored filters if needed
    if ( $ParamObject->GetParam( Param => 'DeleteFilters' ) ) {
        $StoredFilters = {};
    }

    # get the column filters from the web request or user preferences
    my %ColumnFilter;
    my %GetColumnFilter;
    COLUMNNAME:
    for my $ColumnName (
        qw(ZTSMStatus ZTSMStatus ZTSMStatus ZTSMStatus Class)
        )
    {
        # get column filter from web request
        my $FilterValue = $ParamObject->GetParam( Param => 'ColumnFilter' . $ColumnName )
            || '';

        # if filter is not present in the web request, try with the user preferences
        if ( $FilterValue eq '' ) {
            $FilterValue = $StoredFilters->{ $ColumnName . 'IDs' }->[0] || '';
        }
        next COLUMNNAME if $FilterValue eq '';
        next COLUMNNAME if $FilterValue eq 'DeleteFilter';

        push @{ $ColumnFilter{ $ColumnName . 'IDs' } }, $FilterValue;
        $GetColumnFilter{$ColumnName} = $FilterValue;
    }

    # get all dynamic fields
    $Self->{DynamicField} = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['MELTObject'],
    );

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{ $Self->{DynamicField} } ) {

        next DYNAMICFIELD unless IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD unless $DynamicFieldConfig->{Name};

        # get filter from web request
        my $FilterValue = $ParamObject->GetParam(
            Param => 'ColumnFilterDynamicField_' . $DynamicFieldConfig->{Name}
        );

        # if no filter from web request, try from user preferences
        if ( !defined $FilterValue || $FilterValue eq '' ) {
            $FilterValue = $StoredFilters->{ 'DynamicField_' . $DynamicFieldConfig->{Name} }->{Equals};
        }

        next DYNAMICFIELD unless defined $FilterValue;
        next DYNAMICFIELD if $FilterValue eq '';
        next DYNAMICFIELD if $FilterValue eq 'DeleteFilter';

        $ColumnFilter{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = {
            Equals => $FilterValue,
        };
        $GetColumnFilter{ 'DynamicField_' . $DynamicFieldConfig->{Name} } = $FilterValue;
    }

    # build NavigationBar & to get the output faster!
    my $Refresh = '';
    if ( $Self->{UserRefreshTime} ) {
        $Refresh = 60 * $Self->{UserRefreshTime};
    }

    my $Output;
    if ( $Self->{Subaction} ne 'AJAXFilterUpdate' ) {
        $Output = $LayoutObject->Header(
            Refresh => $Refresh,
        );
        $Output .= $LayoutObject->NavigationBar();
    }

    # get class list
    my $ClassList = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::MELT::Class',
    );
    my %TranslatedClassList = map { ( $_ => $LayoutObject->{LanguageObject}->Translate( $ClassList->{$_} ) ) } keys $ClassList->%*;

    # get possible ZTSM Status list for MELT Objects to be shown
    my $StateList = $GeneralCatalogObject->ItemList(
        Class       => 'ZTSM::MELT::Status',
        Preferences => {
            Functionality => [ 'preproductive', 'productive' ],
        },
    );

    # set the ZTSM Status IDs parameter for the search
    my $ZTSMStatusIDs;
    for my $ZTSMStatusKey ( sort keys %{$StateList} ) {
        push @{$ZTSMStatusIDs}, $ZTSMStatusKey;
    }

    # viewable ZTSM Statuss
    my @ViewableZTSMStatusIDs = keys %{
        $GeneralCatalogObject->ItemList(
            Class => 'ZTSM::MELT::Status',
            Valid => 1,
        )
    };

    # get permissions
    my $Permission = 'rw';

    # sort on default by using both (Priority, Age) else use only one sort argument
    my %Sort;

    # get if search result should be pre-sorted by priority
    my $PreSortByPriority = $Config->{'PreSort::ByPriority'};
    if ( !$PreSortByPriority ) {
        %Sort = (
            SortBy  => $SortBy,
            OrderBy => $OrderBy,
        );
    }
    else {
        %Sort = (
            SortBy  => [ 'Priority', $SortBy ],
            OrderBy => [ 'Down',     $OrderBy ],
        );
    }

    # my MELT Object object
    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    # to store the NavBar filters
    my %Filters;
    my %Category2ClassID;

    CLASSID:
    for my $ClassID ( sort { $TranslatedClassList{$a} cmp $TranslatedClassList{$b} } keys %TranslatedClassList ) {

        # show menu link only if user has access rights
        my $HasAccess = $MELTObjectObject->Permission(
            Scope   => 'Class',
            ClassID => $ClassID,
            UserID  => $Self->{UserID},
            Type    => $Config->{Permission},
        );

        next CLASSID if !$HasAccess;

        # fetch class preferences to retrieve categories for class
        my %ClassPreferences = $GeneralCatalogObject->GeneralCatalogPreferencesGet(
            ItemID => $ClassID,
        );

        next CLASSID if !IsArrayRefWithData( $ClassPreferences{Categories} );

        for my $Category ( $ClassPreferences{Categories}->@* ) {
            my $CategoryID = $ReverseCategoryList{ $LayoutObject->{LanguageObject}->Translate($Category) };
            next if !defined $CategoryID;
            push @{ $Category2ClassID{$CategoryID} }, $ClassID;
        }
    }

    # order the category filters and - if not yet set - select the categpry shown
    my %CategoryFilters;
    {
        my @SortedCategories = sort { $TranslatedCategoryList{$a} cmp $TranslatedCategoryList{$b} } keys %Category2ClassID;

        my $Prio = 2;
        %CategoryFilters = map {
            $_ => {
                Name => $TranslatedCategoryList{$_},
                Prio => $Prio++,
            }
        } @SortedCategories;

        if ( $DefaultCategoryID && $CategoryFilters{$DefaultCategoryID} ) {
            $CategoryFilters{$DefaultCategoryID}{Prio} = 1;
        }
    }

    # get the class filters for the selected category
    my $CountTotal = 0;
    my @AllCurrentClasses;
    if ($CategoryFilter) {

        my $Prio = 2;
        for my $ClassID ( sort { $TranslatedClassList{$a} cmp $TranslatedClassList{$b} } $Category2ClassID{$CategoryFilter}->@* ) {
            my $CountClass = $MELTObjectObject->MELTObjectSearch(
                %ColumnFilter,
                ClassIDs     => [$ClassID],
                ZTSMStatusIDs => $ZTSMStatusIDs,
                Limit        => $Self->{SearchLimit},
                Permission   => $Permission,
                UserID       => $Self->{UserID},
                Result       => 'COUNT',
            );
            $CountTotal += $CountClass;

            push @AllCurrentClasses, $ClassID;

            # add filter with params for the search method
            $Filters{$ClassID} = {
                Name   => $TranslatedClassList{$ClassID},
                Prio   => $Prio++,
                Count  => $CountClass,
                Search => {
                    ClassIDs     => [$ClassID],
                    ZTSMStatusIDs => $ZTSMStatusIDs,
                    %Sort,
                    Limit      => $Self->{SearchLimit},
                    Permission => $Permission,
                    UserID     => $Self->{UserID},
                },
            };
        }
    }

    # add "all" filter if there is not only one current filter, set the filter if not provided
    if ( scalar keys %Filters == 1 ) {
        ($Filter) = keys %Filters;
    }
    else {
        $Filters{All} = {
            Name   => $LayoutObject->{LanguageObject}->Translate('All'),
            Prio   => 1,
            Count  => $CountTotal,
            Search => {
                ClassIDs     => \@AllCurrentClasses,
                ZTSMStatusIDs => $ZTSMStatusIDs,
                %Sort,
                Limit      => $Self->{SearchLimit},
                Permission => $Permission,
                UserID     => $Self->{UserID},
            },
        };

        if ( !$Filter || !$Filters{$Filter} ) {
            $Filter = 'All';
        }
    }

    my $View = $ParamObject->GetParam( Param => 'View' ) || '';

    # lookup latest used view mode
    if ( !$View && $Self->{ 'UserMELTObjectOverview' . $Self->{Action} } ) {
        $View = $Self->{ 'UserMELTObjectOverview' . $Self->{Action} };
    }

    # otherwise use Preview as default as in LayoutMELTObject
    $View ||= 'Small';

    # Check if selected view is available.
    my $Backends = $ConfigObject->Get('MELTObject::Frontend::Overview');
    if ( !$Backends->{$View} ) {

        # Try to find fallback, take first configured view mode.
        KEY:
        for my $Key ( sort keys %{$Backends} ) {
            $View = $Key;
            last KEY;
        }
    }

    # get personal page shown count
    my $PageShownPreferencesKey = 'UserMELTObjectOverview' . $View . 'PageShown';
    my $PageShown               = $Self->{Session}{$PageShownPreferencesKey} || 10;

    # do shown MELT Object lookup
    my $Limit = 1_000;

    my $ElementChanged = $ParamObject->GetParam( Param => 'ElementChanged' ) || '';
    my $HeaderColumn   = $ElementChanged;
    $HeaderColumn =~ s{\A ColumnFilter }{}msxg;

    # get data (viewable MELT Objects...)
    # search all MELT Objects
    my @ViewableMELTObjects;
    my @OriginalViewableMELTObjects;

    if ( @ViewableZTSMStatusIDs && @AllCurrentClasses ) {

        # get MELT Object values
        if (
            !IsStringWithData($HeaderColumn)
            || (
                IsStringWithData($HeaderColumn)
                && (
                    $ConfigObject->Get('OnlyValuesOnMELTObject')
                )
            )
            )
        {
            @OriginalViewableMELTObjects = $MELTObjectObject->MELTObjectSearch(
                %{ $Filters{$Filter}->{Search} },
                %ColumnFilter,
                Limit  => $Limit,
                Result => 'ARRAY',
            );

            my $Start = $ParamObject->GetParam( Param => 'StartHit' ) || 1;

            @ViewableMELTObjects = $MELTObjectObject->MELTObjectSearch(
                %{ $Filters{$Filter}->{Search} },
                %ColumnFilter,
                Limit  => $Start + $PageShown - 1,
                Result => 'ARRAY',
            );
        }

    }

    # TODO Maybe there is a more elegant way to do this?
    $Self->{Filter}          = $Filter;
    $Self->{Filters}         = \%Filters;
    $Self->{CategoryFilters} = \%CategoryFilters;
    $Self->{CategoryFilter}  = $CategoryFilter;

    if ( $Self->{Subaction} eq 'AJAXFilterUpdate' ) {

        my $FilterContent = $LayoutObject->MELTObjectListShow(
            FilterContentOnly     => 1,
            HeaderColumn          => $HeaderColumn,
            ElementChanged        => $ElementChanged,
            OriginalMELTObjectIDs => \@OriginalViewableMELTObjects,
            Action                => 'AgentMELTObject',
            Env                   => $Self,
            View                  => $View,
            EnableColumnFilters   => 1,
        );

        if ( !$FilterContent ) {
            $LayoutObject->FatalError(
                Message => $LayoutObject->{LanguageObject}->Translate( 'Can\'t get filter content data of %s!', $HeaderColumn ),
            );
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json',
            Content     => $FilterContent,
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    else {

        # store column filters
        my $StoredFilters = \%ColumnFilter;

        my $StoredFiltersKey = 'UserStoredFilterColumns-' . $Self->{Action} . '-' . $Self->{Filter};
        $UserObject->SetPreferences(
            UserID => $Self->{UserID},
            Key    => $StoredFiltersKey,
            Value  => $JSONObject->Encode( Data => $StoredFilters ),
        );
    }

    my %NavBarFilter = map {
        $CategoryFilters{$_}{Prio} => {
            CategoryFilter => $_,
            $CategoryFilters{$_}->%*,
        }
    } keys %CategoryFilters;

    my %ClassFilter = map {
        $Filters{$_}{Prio} => {
            Filter => $_,
            $Filters{$_}->%*,
        }
    } keys %Filters;

    my $ColumnFilterLink = '';
    COLUMNNAME:
    for my $ColumnName ( sort keys %GetColumnFilter ) {

        next COLUMNNAME unless $ColumnName;
        next COLUMNNAME unless defined $GetColumnFilter{$ColumnName};
        next COLUMNNAME if $GetColumnFilter{$ColumnName} eq '';

        $ColumnFilterLink
            .= ';' . $LayoutObject->Ascii2Html( Text => 'ColumnFilter' . $ColumnName )
            . '=' . $LayoutObject->LinkEncode( $GetColumnFilter{$ColumnName} );
    }

    my $CategoryFilterURI = $LayoutObject->Output(
        Template => '[% Data.CategoryFilter | uri %]',
        Data     => {
            CategoryFilter => $CategoryFilter,
        },
    );
    my $LinkPage = 'Filter='
        . $LayoutObject->Ascii2Html( Text => $Filter )
        . ';Category=' . $LayoutObject->Ascii2Html( Text => $CategoryFilterURI )
        . ';View=' . $LayoutObject->Ascii2Html( Text => $View )
        . ';SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
        . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderBy )
        . $ColumnFilterLink
        . ';';

    my $LinkSort = 'View=' . $LayoutObject->Ascii2Html( Text => $View )
        . ';Category=' . $LayoutObject->Ascii2Html( Text => $CategoryFilterURI )
        . ';Filter=' . $LayoutObject->Ascii2Html( Text => $Filter )
        . $ColumnFilterLink
        . ';';

    my $LinkFilter = 'SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
        . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderBy )
        . ';View=' . $LayoutObject->Ascii2Html( Text => $View )
        . ';';

    my $LastColumnFilter = $ParamObject->GetParam( Param => 'LastColumnFilter' ) || '';

    if ( !$LastColumnFilter && $ColumnFilterLink ) {

        # is planned to have a link to go back here
        $LastColumnFilter = 1;
    }

    # show MELT Objects
    $Output .= $LayoutObject->MELTObjectListShow(
        Filter                => $Filter,
        CategoryFilter        => $CategoryFilter,
        Filters               => \%ClassFilter,
        CategoryFilters       => \%NavBarFilter,
        MELTObjectIDs         => \@ViewableMELTObjects,
        OriginalMELTObjectIDs => \@OriginalViewableMELTObjects,
        GetColumnFilter       => \%GetColumnFilter,
        LastColumnFilter      => $LastColumnFilter,
        Action                => 'AgentMELTObject',
        Total                 => scalar @OriginalViewableMELTObjects,
        RequestedURL          => $Self->{RequestedURL},
        View                  => $View,
        Bulk                  => 1,
        TitleName             => $LayoutObject->{LanguageObject}->Translate('Overview: MELT Object'),
        TitleValue            => $Filter && $Self->{Filters}{$Filter} ? $Self->{Filters}{$Filter}{Name} : '',
        Env                   => $Self,
        LinkPage              => $LinkPage,
        LinkSort              => $LinkSort,
        LinkFilter            => $LinkFilter,
        OrderBy               => $OrderBy,
        SortBy                => $SortBy,
        EnableColumnFilters   => 1,
        ColumnFilterForm      => {
            Filter   => $Filter         || '',
            Category => $CategoryFilter || '',
        },

        # do not print the result earlier, but return complete content
        Output => 1,
    );

    # get page footer
    $Output .= $LayoutObject->Footer() if $Self->{Subaction} ne 'AJAXFilterUpdate';

    return $Output;
}

1;

