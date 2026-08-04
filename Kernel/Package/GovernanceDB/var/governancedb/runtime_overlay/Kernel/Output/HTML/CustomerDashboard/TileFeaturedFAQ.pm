# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
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

package Kernel::Output::HTML::CustomerDashboard::TileFeaturedFAQ;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::DateTime',
    'Kernel::System::FAQ',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config} || {};
    my @Announcements = $Self->_AnnouncementsGet(
        CategoryName => $Config->{CategoryName} || 'Announcement',
        StartField   => $Config->{StartField}   || 'ZFAQ-Start',
        ExpiryField  => $Config->{ExpiryField}  || 'ZFAQ-Expiry',
        Limit        => $Config->{Limit}        || 5,
        UserID       => $Param{UserID}          || 1,
        UserLogin    => $Param{UserLogin}       || $Param{UserID},
    );

    return $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Output(
        TemplateFile => $Param{Template} || 'Dashboard/TileFeaturedFAQ',
        Data         => {
            TileID            => $Param{TileID},
            EmptyText         => $Config->{EmptyText} || 'No current announcements.',
            AnnouncementCount => scalar @Announcements,
            Announcements     => \@Announcements,
        },
    );
}

sub _AnnouncementsGet {
    my ( $Self, %Param ) = @_;

    my $FAQObject    = $Kernel::OM->Get('Kernel::System::FAQ');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $CategoryIDs = $Self->_AnnouncementCategoryIDsGet(
        CategoryName => $Param{CategoryName},
        UserID       => $Param{UserID},
    );
    return if !IsArrayRefWithData($CategoryIDs);

    my $AllowedCategoryIDs = $FAQObject->CustomerCategorySearch(
        CustomerUser     => $Param{UserLogin},
        Mode             => 'Customer',
        UserID           => $Param{UserID},
        GetSubCategories => 1,
    );
    return if !IsArrayRefWithData($AllowedCategoryIDs);

    my %AllowedCategoryID = map { $_ => 1 } @{$AllowedCategoryIDs};
    my @ViewableCategoryIDs = grep { $AllowedCategoryID{$_} } @{$CategoryIDs};
    return if !@ViewableCategoryIDs;

    my $Now = time;
    my @ItemIDs = $FAQObject->FAQSearch(
        CategoryIDs      => \@ViewableCategoryIDs,
        States           => $FAQObject->StateTypeList(
            Types  => $ConfigObject->Get('FAQ::Customer::StateTypes'),
            UserID => $Param{UserID},
        ),
        Interface        => $FAQObject->StateTypeGet(
            Name   => 'external',
            UserID => $Param{UserID},
        ),
        OrderBy          => ['Changed'],
        OrderByDirection => ['Down'],
        Limit            => 100,
        UserID           => $Param{UserID},
    );

    my @Announcements;
    ITEMID:
    for my $ItemID (@ItemIDs) {

        my %FAQ = $FAQObject->FAQGet(
            ItemID        => $ItemID,
            ItemFields    => 1,
            DynamicFields => 1,
            UserID        => $Param{UserID},
        );
        next ITEMID if !%FAQ;

        my $StartValue  = $FAQ{ 'DynamicField_' . $Param{StartField} }  || '';
        my $ExpiryValue = $FAQ{ 'DynamicField_' . $Param{ExpiryField} } || '';
        my $StartTime   = $Self->_TimestampToEpoch( Value => $StartValue );
        my $ExpiryTime  = $Self->_TimestampToEpoch( Value => $ExpiryValue, EndOfDay => 1 );

        next ITEMID if $StartTime  && $StartTime > $Now;
        next ITEMID if $ExpiryTime && $ExpiryTime < $Now;

        my $ChangedTime = $Self->_TimestampToEpoch( Value => $FAQ{Changed} ) || 0;
        my $SortTime    = $StartTime || $ExpiryTime || $ChangedTime;

        push @Announcements, {
            ItemID      => $FAQ{ItemID},
            Title       => $FAQ{Title},
            Summary     => $Self->_SummaryGet(FAQ => \%FAQ),
            DisplayDate => $Self->_DisplayDateGet(
                StartValue  => $StartValue,
                ExpiryValue => $ExpiryValue,
                Changed     => $FAQ{Changed},
            ),
            SortTime    => $SortTime,
            ChangedTime => $ChangedTime,
        };
    }

    @Announcements = sort {
        ( $b->{SortTime} || 0 ) <=> ( $a->{SortTime} || 0 )
            ||
            ( $b->{ChangedTime} || 0 ) <=> ( $a->{ChangedTime} || 0 )
            ||
            ( $b->{ItemID} || 0 ) <=> ( $a->{ItemID} || 0 )
    } @Announcements;

    if ( @Announcements > $Param{Limit} ) {
        splice @Announcements, $Param{Limit};
    }

    return @Announcements;
}

sub _AnnouncementCategoryIDsGet {
    my ( $Self, %Param ) = @_;

    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');
    my $CategoryIDs = $FAQObject->CategorySearch(
        Name   => $Param{CategoryName},
        UserID => $Param{UserID},
    );
    return if !IsArrayRefWithData($CategoryIDs);

    my @ExactCategoryIDs;
    CATEGORYID:
    for my $CategoryID ( @{$CategoryIDs} ) {

        my %Category = $FAQObject->CategoryGet(
            CategoryID => $CategoryID,
            UserID     => $Param{UserID},
        );
        next CATEGORYID if !%Category;
        next CATEGORYID if ( $Category{Name} || '' ) ne $Param{CategoryName};

        push @ExactCategoryIDs, $CategoryID;
    }

    return \@ExactCategoryIDs;
}

sub _TimestampToEpoch {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Value};
    return if ref $Param{Value};

    my $Value = $Param{Value};
    $Value =~ s{\A\s+|\s+\z}{}g;
    return if $Value eq '';

    return $Value if $Value =~ m{\A \d{9,} \z}xms;

    my $SystemTime = $Kernel::OM->Get('Kernel::System::DateTime')->TimeStamp2SystemTime(
        String => $Value,
    );
    return if !$SystemTime;

    if ( $Param{EndOfDay} && $Value =~ m{\A \d{4}-\d{2}-\d{2} \z}xms ) {
        $SystemTime += 86399;
    }

    return $SystemTime;
}

sub _DisplayDateGet {
    my ( $Self, %Param ) = @_;

    return 'From ' . $Param{StartValue} if $Param{StartValue};
    return 'Until ' . $Param{ExpiryValue} if $Param{ExpiryValue};
    return $Param{Changed} || '';
}

sub _SummaryGet {
    my ( $Self, %Param ) = @_;

    my $Summary = $Param{FAQ}->{Field1} || $Param{FAQ}->{Keywords} || '';
    $Summary =~ s{<[^>]+>}{}g;
    $Summary =~ s{\s+}{ }g;
    $Summary =~ s{\A\s+|\s+\z}{}g;

    if ( length $Summary > 120 ) {
        $Summary = substr( $Summary, 0, 117 ) . '...';
    }

    return $Summary;
}

1;

