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

package Kernel::System::GovernanceObject::Permission;

use strict;
use warnings;

use List::Util qw(any none);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::GovernanceObject::Permission - module for GovernanceObject.pm with Permission functions

=head1 DESCRIPTION

All Permission functions.

=head1 PUBLIC INTERFACE

=head2 Permission()

returns whether the user has permissions or not

    my $Access = $GovernanceObjectObject->Permission(
        Type     => 'ro',
        Scope    => 'Class', # Class || Item
        ClassID  => 123,     # if Scope is 'Class'
        ItemID   => 123,     # if Scope is 'Item'
        UserID   => 123,
    );

or without logging, for example for to check if a link/action should be shown

    my $Access = $GovernanceObjectObject->Permission(
        Type     => 'ro',
        Scope    => 'Class', # Class || Item
        ClassID  => 123,     # if Scope is 'Class'
        ItemID   => 123,     # if Scope is 'Item'
        LogNo    => 1,
        UserID   => 123,
    );

=cut

sub Permission {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Type Scope UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # check for existence of ItemID or ClassID dependent
    # on the Scope
    if (
        ( $Param{Scope} eq 'Class' && !$Param{ClassID} )
        ||
        ( $Param{Scope} eq 'Item' && !$Param{ItemID} )
        )
    {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need ClassID if Scope is 'Class' or ItemID if Scope is 'Item'!",
        );

        return;
    }

    # Run all Governance Object Permission modules.
    #
    # The idea is the the permission modules are ordered and can be divided into two phases.
    # In the first phase 'Required' is on and 'Granted' is off. This assures that all required
    # preconditions are met. In the second phase 'Required' is off and 'Granted' is on. It suffices
    # when only on second phase module grants access.
    #
    # Other combinations are possible but might bring surprising results.
    if (
        ref $Kernel::OM->Get('Kernel::Config')->Get( 'GovernanceObject::Permission::' . $Param{Scope} ) eq 'HASH'
        )
    {
        my %Modules = %{
            $Kernel::OM->Get('Kernel::Config')->Get( 'GovernanceObject::Permission::' . $Param{Scope} )
        };
        MODULE:
        for my $Module ( sort keys %Modules ) {

            # load module
            next MODULE unless $Kernel::OM->Get('Kernel::System::Main')->Require( $Modules{$Module}->{Module} );

            # create object
            my $ModuleObject = $Modules{$Module}->{Module}->new;

            # execute Run()
            my $AccessOk = $ModuleObject->Run(%Param);

            # check granted option (should I say ok)
            if ( $AccessOk && $Modules{$Module}->{Granted} ) {

                # access ok
                return 1;
            }

            # refuse access  because access is false but it's required
            if ( !$AccessOk && $Modules{$Module}->{Required} ) {
                if ( !$Param{LogNo} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'notice',
                        Message  => "Permission denied because module "
                            . "($Modules{$Module}->{Module}) is required "
                            . "(UserID: $Param{UserID} '$Param{Type}' "
                            . "on $Param{Scope}: " . $Param{ $Param{Scope} . 'ID' } . ")!",
                    );
                }

                # refuse access
                return;
            }
        }
    }

    # don't grant access
    if ( !$Param{LogNo} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied (UserID: $Param{UserID} '$Param{Type}' "
                . "on $Param{Scope}: " . $Param{ $Param{Scope} . 'ID' } . ")!",
        );
    }

    return;
}

=head2 CustomerPermission()

returns whether the user has permissions or not

    my $Access = $GovernanceObjectObject->CustomerPermission(
        GovernanceObjectID => 123,
        UserID       => 123,
        LogNo        => 1,    # optional, do not log, default: 0
    );

=cut

sub CustomerPermission {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(GovernanceObjectID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $CustomerGroupObject = $Kernel::OM->Get('Kernel::System::CustomerGroup');
    my %GroupLookup;

    my %Conditions = %{ $Kernel::OM->Get('Kernel::Config')->Get('Customer::GovernanceObject::PermissionConditions') // {} };
    my $GovernanceObject = $Self->GovernanceObjectGet(
        GovernanceObjectID  => $Param{GovernanceObjectID},
        DynamicFields => 1,
    );

    CONDITION:
    for my $ConditionSet ( values %Conditions ) {
        if ( $ConditionSet->{Groups} && $ConditionSet->{Groups}->@* ) {
            if ( !%GroupLookup ) {
                %GroupLookup = reverse $CustomerGroupObject->GroupMemberList(
                    UserID => $Param{UserID},
                    Type   => 'ro',
                    Result => 'HASH',
                );
            }

            next CONDITION if none { $GroupLookup{$_} } $ConditionSet->{Groups}->@*;
        }

        if ( $ConditionSet->{Classes} ) {
            my @Classes = ref $ConditionSet->{Classes} ? $ConditionSet->{Classes}->@* : ( $ConditionSet->{Classes} );

            next CONDITION if @Classes && !grep { $_ eq $GovernanceObject->{Class} } @Classes;
        }

        if ( $ConditionSet->{DeploymentStates} ) {
            my @ZTSMStatuss = ref $ConditionSet->{DeploymentStates} ? $ConditionSet->{DeploymentStates}->@* : ( $ConditionSet->{DeploymentStates} );

            next CONDITION if @ZTSMStatuss && !grep { $_ eq $GovernanceObject->{ZTSMStatus} } @ZTSMStatuss;
        }

        if ( $ConditionSet->{DynamicFieldValues} ) {
            for my $FieldName ( keys $ConditionSet->{DynamicFieldValues}->%* ) {
                my $ConditionValue = $ConditionSet->{DynamicFieldValues}{$FieldName} // '';

                if ( !defined $GovernanceObject->{"DynamicField_$FieldName"} ) {
                    next CONDITION if $ConditionValue ne '';
                }
                elsif ( !ref $GovernanceObject->{"DynamicField_$FieldName"} ) {
                    next CONDITION if $ConditionValue ne $GovernanceObject->{"DynamicField_$FieldName"};
                }
                elsif ( $ConditionValue eq '' ) {
                    next CONDITION if $GovernanceObject->{"DynamicField_$FieldName"}->@*;
                }
                else {
                    next CONDITION if none { $_ eq $ConditionValue } $GovernanceObject->{"DynamicField_$FieldName"}->@*;
                }
            }
        }

        if ( $ConditionSet->{CustomerUserDynamicField} ) {
            next CONDITION if !$GovernanceObject->{ 'DynamicField_' . $ConditionSet->{CustomerUserDynamicField} };

            my @CustomerUsers = ref $GovernanceObject->{ 'DynamicField_' . $ConditionSet->{CustomerUserDynamicField} }
                ? $GovernanceObject->{ 'DynamicField_' . $ConditionSet->{CustomerUserDynamicField} }->@*
                : ( $GovernanceObject->{ 'DynamicField_' . $ConditionSet->{CustomerUserDynamicField} } );

            next CONDITION if none { $_ eq $Param{UserID} } @CustomerUsers;
        }

        if ( $ConditionSet->{CustomerCompanyDynamicField} ) {
            next CONDITION if !$GovernanceObject->{ 'DynamicField_' . $ConditionSet->{CustomerCompanyDynamicField} };

            my @CustomerCompanies = ref $GovernanceObject->{ 'DynamicField_' . $ConditionSet->{CustomerCompanyDynamicField} }
                ? $GovernanceObject->{ 'DynamicField_' . $ConditionSet->{CustomerCompanyDynamicField} }->@*
                : ( $GovernanceObject->{ 'DynamicField_' . $ConditionSet->{CustomerCompanyDynamicField} } );

            my %AccessibleCustomers = $Kernel::OM->Get('Kernel::System::CustomerGroup')->GroupContextCustomers(
                CustomerUserID => $Param{UserID},
            );

            next CONDITION if none { $AccessibleCustomers{$_} } @CustomerCompanies;
        }

        # grant access
        return 1;
    }

    if ( !$Param{LogNo} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Permission denied (CustomerUserID: $Param{UserID} "
                . "on GovernanceObject: " . $Param{GovernanceObjectID} . ")!",
        );
    }

    # don't grant access
    return;
}

1;
