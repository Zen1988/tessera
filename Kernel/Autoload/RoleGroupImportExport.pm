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

## no critic (Modules::RequireExplicitPackage)

use Kernel::System::Group ();    ## no perlimports

package Kernel::System::Group;   ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;
use warnings;
use v5.24;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Group',
    'Kernel::System::Valid',
);

sub ExportRoleGroups {
    my ( $Self, %Param ) = @_;

    my %RoleFilter;
    if ( IsArrayRefWithData( $Param{Roles} ) ) {
        %RoleFilter = map { $_ => 1 } $Param{Roles}->@*;
    }

    # get necessary objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    # fetch lookup lists
    my $PermissionTypes = $ConfigObject->Get('System::Permission');
    my %RoleList        = $GroupObject->RoleList(
        Valid => 0,
    );

    my %ExportData;
    ROLEID:
    for my $RoleID ( sort keys %RoleList ) {

        my %RoleData = $GroupObject->RoleGet(
            ID => $RoleID,
        );

        if (%RoleFilter) {
            next ROLEID unless $RoleFilter{ $RoleData{Name} };
        }

        my %Types;
        for my $Type ( $PermissionTypes->@* ) {
            my %Data = $GroupObject->PermissionRoleGroupGet(
                RoleID => $RoleID,
                Type   => $Type,
            );

            # use values as array to prevent exporting group ids
            my @GroupNames = values %Data;
            $Types{$Type} = \@GroupNames;
        }

        $ExportData{ $RoleData{Name} } = \%Types;
    }

    return \%ExportData;
}

sub ImportRoleGroups {
    my ( $Self, %Param ) = @_;

    my $UserID = $Self->{UserID} || $Param{UserID};

    # get necessary objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $GroupObject  = $Kernel::OM->Get('Kernel::System::Group');

    # fetch lookup lists
    my $PermissionTypes = $ConfigObject->Get('System::Permission');
    my %GroupList       = $GroupObject->GroupList(
        Valid => 0,
    );
    my %GroupLookup = reverse %GroupList;
    my %RoleList    = $GroupObject->RoleList(
        Valid => 0,
    );
    my %RoleLookup = reverse %RoleList;

    ROLENAME:
    for my $RoleName ( keys $Param{RoleGroups}->%* ) {

        my $RoleData = $Param{RoleGroups}{$RoleName};

        next ROLENAME unless IsHashRefWithData($RoleData);

        my $RoleID = $RoleLookup{$RoleName};

        # skip roles which do not exist on the system
        next ROLENAME unless $RoleID;

        # traverse permission-group structure to be able to set new values
        my %PermissionsForGroup;
        PERMISSIONTYPE:
        for my $PermissionType ( $PermissionTypes->@* ) {

            next PERMISSIONTYPE unless IsArrayRefWithData( $RoleData->{$PermissionType} );

            GROUPNAME:
            for my $GroupName ( $RoleData->{$PermissionType}->@* ) {

                my $GroupID = $GroupLookup{$GroupName};

                next GROUPNAME unless $GroupID;

                $PermissionsForGroup{$GroupName} //= {};
                $PermissionsForGroup{$GroupName}{$PermissionType} = 1;
            }
        }

        for my $CurrentGroup ( keys %PermissionsForGroup ) {

            my $GroupID     = $GroupLookup{$CurrentGroup};
            my $Permissions = $PermissionsForGroup{$CurrentGroup};

            my $Success = $GroupObject->PermissionGroupRoleAdd(
                GID        => $GroupID,
                RID        => $RoleID,
                Permission => $Permissions,
                UserID     => $UserID,
            );

            next ROLENAME unless $Success;
        }

        # skip if role with same name exists and overwrite is not set
        next ROLENAME if ( !$Param{OverwriteExistingEntities} && $RoleID );
    }

    return 1;
}

1;
