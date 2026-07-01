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

package Kernel::System::MELTObject::VersionString::Incremental;

use strict;
use warnings;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::System::MELTObject',
);

=head1 NAME

Kernel::System::MELTObject::VersionString::Incremental - Using a counter for the version string

=head1 PUBLIC INTERFACE

=head2 new()

create an object. Do not use it directly, instead use:

my $VersionStringModuleObject = $Kernel::OM->Get('Kernel::System::MELTObject::VersionString::Incremental');

=cut

sub new {
    my ($Type) = @_;

    # allocate new hash for object
    return bless( {}, $Type );
}

sub VersionStringGet {
    my ( $Self, %Param ) = @_;

    return $Param{Version}{VersionString} if ( $Param{Version}{VersionString} && !$Param{VersionAdd} );

    # expected params: Version
    my $VersionListRef = $Kernel::OM->Get('Kernel::System::MELTObject')->VersionListAll(
        MELTObjectIDs => [ $Param{Version}{MELTObjectID} ],
    );

    return 1 unless IsHashRefWithData($VersionListRef);

    my $InitialVersionString = ( scalar keys $VersionListRef->{ $Param{Version}{MELTObjectID} }->%* ) + 1;
    my $VersionString;
    while ( !defined $VersionString ) {
        if ( grep { $_->{VersionString} eq $InitialVersionString } values $VersionListRef->{ $Param{Version}{MELTObjectID} }->%* ) {
            $InitialVersionString++;
        }
        else {
            $VersionString = $InitialVersionString;
        }
    }

    return $VersionString;
}

1;

