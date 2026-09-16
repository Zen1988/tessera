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

package Kernel::System::SysConfig::ValueType::Entity::GovernanceObjectClass;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::SysConfig::ValueType::Entity);

our @ObjectDependencies = (
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::System::SysConfig::ValueType::Entity::GovernanceObjectClass - System configuration Governance Object class entity type backend.

=head1 PUBLIC INTERFACE

=head2 new()

Create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $EntityTypeObject = $Kernel::OM->Get('Kernel::System::SysConfig::ValueType::Entity::GovernanceObjectClass');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub EntityValueList {
    my ( $Self, %Param ) = @_;

    my $GovernanceObjectClasses = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
        Valid => 1,
    );

    my @Result;

    for my $ID ( sort keys $GovernanceObjectClasses->%* ) {
        push @Result, $GovernanceObjectClasses->{$ID};
    }

    return @Result;
}

sub EntityLookupFromWebRequest {
    my ( $Self, %Param ) = @_;

    my $ClassID = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'GovernanceObjectClassID' ) // '';

    return if !$ClassID;

    my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
        ItemID => $ClassID,
    );

    return $Item->{Name};
}

1;
