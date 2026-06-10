# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Output::HTML::GeneralCatalogPreferences::GovernanceObjectGeneric;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceDB',
    'Kernel::System::Group',
    'Kernel::System::Web::Request',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless $Self, $Type;

    for my $Needed (qw(UserID ConfigItem)) {
        die "Got no $Needed!" if !$Self->{$Needed};
    }

    return $Self;
}

sub Param {
    my ( $Self, %Param ) = @_;

    my @Params;

    my $GetParam = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam(
        Param => $Self->{ConfigItem}{PrefKey},
    );

    if ( !defined $GetParam ) {
        $GetParam = defined $Param{GeneralCatalogData}{ $Self->{ConfigItem}{PrefKey} }
            ? $Param{GeneralCatalogData}{ $Self->{ConfigItem}{PrefKey} }
            : $Self->{ConfigItem}{DataSelected};
    }

    for my $SelectOption (qw(Mandatory Multiple)) {
        $Param{$SelectOption} = $Self->{ConfigItem}{$SelectOption};
    }

    my $Block = $Self->{ConfigItem}{Block} || 'Input';

    if ( $Block eq 'Permission' ) {
        $Param{Data}  = { $Kernel::OM->Get('Kernel::System::Group')->GroupList( Valid => 1 ) };
        $Param{Block} = 'Option';
    }
    elsif ( $Block eq 'GovernanceObjectNumberModule' ) {
        $Param{Data}  = { GOID => 'GOID' };
        $Param{Block} = 'Option';
    }
    elsif ( $Block eq 'GovernanceObjectVersionStringModule' ) {
        $Param{Data}  = { Incremental => 'Incremental' };
        $Param{Block} = 'Option';
    }
    elsif ( $Block eq 'GovernanceObjectVersionTrigger' ) {
        my %Data = %{ $Self->{ConfigItem}{Data} || {} };

        if ( $Param{GeneralCatalogData}{ItemID} && $Param{GeneralCatalogData}{ItemID} ne 'NEW' ) {
            my $Definition = $Kernel::OM->Get('Kernel::System::GovernanceDB')->DefinitionGet(
                ClassID => $Param{GeneralCatalogData}{ItemID},
            );

            if ( $Definition && $Definition->{Definition} ) {
                my @DynamicFields = $Definition->{Definition} =~ m{ DF:\s*([A-Za-z0-9-]+) }gxms;
                for my $DynamicField (@DynamicFields) {
                    $Data{"DynamicField_$DynamicField"} = "DynamicField_$DynamicField";
                }
            }
        }

        $Param{Data}  = \%Data;
        $Param{Block} = 'Option';
    }
    elsif ( $Block eq 'GovernanceObjectClassCategories' ) {
        my $Classes = $Kernel::OM->Get('Kernel::Config')->Get('GovernanceDB::GeneralCatalogClasses') || {};
        my $CategoryClass = $Classes->{Category} || $Classes->{ClassCategory} || 'ZTSM::GovernanceObject::Category';

        my @Categories = values %{
            $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
                Class => $CategoryClass,
                Valid => 1,
            ) || {}
        };

        $Param{Data}  = { map { $_ => $_ } @Categories };
        $Param{Block} = 'Option';
    }
    else {
        $Param{Block} = $Block;
    }

    push @Params, {
        %Param,
        Name       => $Self->{ConfigItem}{PrefKey},
        SelectedID => $GetParam,
    };

    return @Params;
}

sub Run {
    my ( $Self, %Param ) = @_;

    for my $Key ( sort keys %{ $Param{GetParam} || {} } ) {
        my @Array = @{ $Param{GetParam}{$Key} || [] };

        $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesSet(
            ItemID => $Param{ItemID},
            Key    => $Key,
            Value  => \@Array,
        );
    }

    $Self->{Message} = 'Preferences updated successfully!';
    return 1;
}

sub Error {
    my ( $Self, %Param ) = @_;

    return $Self->{Error} || '';
}

sub Message {
    my ( $Self, %Param ) = @_;

    return $Self->{Message} || '';
}

1;
