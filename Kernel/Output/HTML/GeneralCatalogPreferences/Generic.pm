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

package Kernel::Output::HTML::GeneralCatalogPreferences::Generic;

use strict;
use warnings;

use File::Basename qw(fileparse);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Group',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Web::Request',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # get needed params
    for my $Needed (qw( UserID ConfigItem )) {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    return $Self;
}

sub Param {
    my ( $Self, %Param ) = @_;

    my @Params   = ();
    my $GetParam = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => $Self->{ConfigItem}->{PrefKey} );

    if ( !defined($GetParam) ) {
        $GetParam = defined( $Param{GeneralCatalogData}->{ $Self->{ConfigItem}->{PrefKey} } )
            ? $Param{GeneralCatalogData}->{ $Self->{ConfigItem}->{PrefKey} }
            : $Self->{ConfigItem}->{DataSelected};
    }

    for my $SelectOption (qw(Mandatory Multiple)) {
        $Param{$SelectOption} = $Self->{ConfigItem}{$SelectOption};
    }

    if ( !( defined $Self->{ConfigItem}->{Block} && $Self->{ConfigItem}->{Block} ) ) {
        $Self->{ConfigItem}->{Block} = 'Input';
    }

    if ( $Self->{ConfigItem}->{Block} eq 'Permission' ) {
        $Param{Data}  = { $Kernel::OM->Get('Kernel::System::Group')->GroupList( Valid => 1 ) };
        $Param{Block} = 'Option';
    }

    if ( $Self->{ConfigItem}->{Block} eq 'NameModule' ) {

        # get main object
        my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

        # iterate on name module files
        my $NameModuleDir = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/Kernel/System/ITSMConfigItem/Name';
        my @NameModules;
        if ( -d $NameModuleDir ) {
            my @AllNameModuleFiles = $MainObject->DirectoryRead(
                Directory => $NameModuleDir,
                Filter    => '*.pm',
            );
            NAME_MODULE_FILE:
            for my $NameModuleFile (@AllNameModuleFiles) {
                my $ClassNameFinalPart = fileparse( $NameModuleFile, '.pm' );
                my $ClassName          = "Kernel::System::ITSMConfigItem::Name::$ClassNameFinalPart";

                if ( !$MainObject->RequireBaseClass($ClassName) ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'notice',
                        Message  => "ConfigItem name module $ClassName could not be loaded!",
                    );
                    next NAME_MODULE_FILE;
                }

                push @NameModules, $ClassNameFinalPart;
            }
        }

        $Param{Data}->%* = map { $_ => $_ } @NameModules;
        $Param{Block} = 'Option';
    }

    if ( $Self->{ConfigItem}->{Block} eq 'NumberModule' ) {

        # get main object
        my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

        # iterate on number module files
        my $NumberModuleDir = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/Kernel/System/ITSMConfigItem/Number';
        my @NumberModules;
        if ( -d $NumberModuleDir ) {
            my @AllNumberModuleFiles = $MainObject->DirectoryRead(
                Directory => $NumberModuleDir,
                Filter    => '*.pm',
            );
            NUMBER_MODULE_FILE:
            for my $NumberModuleFile (@AllNumberModuleFiles) {
                my $ClassNameFinalPart = fileparse( $NumberModuleFile, '.pm' );
                my $ClassName          = "Kernel::System::ITSMConfigItem::Number::$ClassNameFinalPart";

                if ( !$MainObject->RequireBaseClass($ClassName) ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'notice',
                        Message  => "ConfigItem number module $ClassName could not be loaded!",
                    );
                    next NUMBER_MODULE_FILE;
                }

                push @NumberModules, $ClassNameFinalPart;
            }
        }

        $Param{Data}->%* = map { $_ => $_ } @NumberModules;
        $Param{Block} = 'Option';
    }

    if ( $Self->{ConfigItem}->{Block} eq 'VersionStringModule' ) {

        # get main object
        my $MainObject = $Kernel::OM->Get('Kernel::System::Main');

        # iterate on version string module files
        my $VersionStringModuleDir = $Kernel::OM->Get('Kernel::Config')->Get('Home') . '/Kernel/System/ITSMConfigItem/VersionString';
        my @VersionStringModules;
        if ( -d $VersionStringModuleDir ) {
            my @AllVersionStringModuleFiles = $MainObject->DirectoryRead(
                Directory => $VersionStringModuleDir,
                Filter    => '*.pm',
            );

            VERSION_STRING_MODULE_FILE:
            for my $VersionStringModuleFile (@AllVersionStringModuleFiles) {
                my $ClassNameFinalPart = fileparse( $VersionStringModuleFile, '.pm' );
                my $ClassName          = "Kernel::System::ITSMConfigItem::VersionString::$ClassNameFinalPart";

                if ( !$MainObject->RequireBaseClass($ClassName) ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'notice',
                        Message  => "ConfigItem version string module $ClassName could not be loaded!",
                    );
                    next VERSION_STRING_MODULE_FILE;
                }

                push @VersionStringModules, $ClassNameFinalPart;
            }
        }
        $Param{Data}->%* = map { $_ => $_ } @VersionStringModules;
        $Param{Block} = 'Option';
    }

    if ( $Self->{ConfigItem}->{Block} eq 'ConfigItemVersionTrigger' ) {
        if ( $Param{GeneralCatalogData}{ItemID} ne 'NEW' ) {
            my $ClassDefinition = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->DefinitionGet(
                ClassID => $Param{GeneralCatalogData}{ItemID},
            );
            my %DynamicFieldNames = map { 'DynamicField_' . $_ => 'DynamicField_' . $_ } keys $ClassDefinition->{DynamicFieldRef}->%*;

            $Param{Data} = {
                $Self->{ConfigItem}->{Data}->%*,
                %DynamicFieldNames,
            };
        }

        $Param{Block} = 'Option';
    }

    if ( $Self->{ConfigItem}->{Block} eq 'ConfigItemClassCategories' ) {
        my @Categories = values %{
            $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
                Class => 'ITSM::ConfigItem::Class::Category',
                Valid => 1,
            )
        };
        $Param{Data}->%* = map { $_ => $_ } @Categories;
        $Param{Block} = 'Option';
    }

    push(
        @Params,
        {
            %Param,
            Name       => $Self->{ConfigItem}->{PrefKey},
            SelectedID => $GetParam,
        },
    );

    return @Params;
}

sub Run {
    my ( $Self, %Param ) = @_;

    for my $Key ( sort keys %{ $Param{GetParam} } ) {
        my @Array = @{ $Param{GetParam}->{$Key} };

        # pref update db
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
