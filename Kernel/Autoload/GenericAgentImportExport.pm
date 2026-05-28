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

use Kernel::System::GenericAgent ();    ## no perlimports

package Kernel::System::GenericAgent;   ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;
use warnings;
use v5.24;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData);

our @ObjectDependencies = (
    'Kernel::System::GenericAgent',
    'Kernel::System::Lock',
    'Kernel::System::Priority',
    'Kernel::System::Queue',
    'Kernel::System::SLA',
    'Kernel::System::Service',
    'Kernel::System::State',
    'Kernel::System::Type',
    'Kernel::System::User',
);

sub ExportGenericAgents {
    my ( $Self, %Param ) = @_;

    my %GenericAgentFilter;
    if ( IsArrayRefWithData( $Param{GenericAgents} ) ) {
        %GenericAgentFilter = map { $_ => 1 } $Param{GenericAgents}->@*;
    }

    # get necessary objects
    my $GenericAgentObject = $Kernel::OM->Get('Kernel::System::GenericAgent');
    my $LockObject         = $Kernel::OM->Get('Kernel::System::Lock');
    my $PriorityObject     = $Kernel::OM->Get('Kernel::System::Priority');
    my $QueueObject        = $Kernel::OM->Get('Kernel::System::Queue');
    my $ServiceObject      = $Kernel::OM->Get('Kernel::System::Service');
    my $SLAObject          = $Kernel::OM->Get('Kernel::System::SLA');
    my $StateObject        = $Kernel::OM->Get('Kernel::System::State');
    my $TypeObject         = $Kernel::OM->Get('Kernel::System::Type');
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');

    # fetch lookup lists
    my %GenericAgentList = $GenericAgentObject->JobList();

    my %ExportData;
    GENERICAGENTNAME:
    for my $GenericAgentName ( sort keys %GenericAgentList ) {

        my %GenericAgentData = $GenericAgentObject->JobGet(
            Name => $GenericAgentName,
        );

        if (%GenericAgentFilter) {
            next GENERICAGENTNAME unless $GenericAgentFilter{ $GenericAgentData{Name} };
        }

        # translate IDs into names or name-like identifiers
        ATTRIBUTE:
        for my $Attribute ( keys %GenericAgentData ) {

            # single-value attributes
            if ( $Attribute eq 'NewLockID' ) {
                if ( $GenericAgentData{NewLockID} ) {
                    $GenericAgentData{NewLock} = $LockObject->LockLookup(
                        LockID => $GenericAgentData{NewLockID},
                    );
                    delete $GenericAgentData{NewLockID};
                }
            }
            elsif ( $Attribute eq 'NewOwnerID' ) {
                if ( $GenericAgentData{NewOwnerID} ) {
                    $GenericAgentData{NewOwner} = $UserObject->UserLookup(
                        UserID => $GenericAgentData{NewOwnerID},
                    );
                    delete $GenericAgentData{NewOwnerID};
                }
            }
            elsif ( $Attribute eq 'NewPriorityID' ) {
                if ( $GenericAgentData{NewPriorityID} ) {
                    $GenericAgentData{NewPriority} = $PriorityObject->PriorityLookup(
                        PriorityID => $GenericAgentData{NewPriorityID},
                    );
                    delete $GenericAgentData{NewPriorityID};
                }
            }
            elsif ( $Attribute eq 'NewQueueID' ) {
                if ( $GenericAgentData{NewQueueID} ) {
                    $GenericAgentData{NewQueue} = $QueueObject->QueueLookup(
                        QueueID => $GenericAgentData{NewQueueID},
                    );
                    delete $GenericAgentData{NewQueueID};
                }
            }
            elsif ( $Attribute eq 'NewServiceID' ) {
                if ( $GenericAgentData{NewServiceID} ) {
                    $GenericAgentData{NewService} = $ServiceObject->ServiceLookup(
                        ServiceID => $GenericAgentData{NewServiceID},
                    );
                    delete $GenericAgentData{NewServiceID};
                }
            }
            elsif ( $Attribute eq 'NewSLAID' ) {
                if ( $GenericAgentData{NewSLAID} ) {
                    $GenericAgentData{NewSLA} = $SLAObject->SLALookup(
                        SLAID => $GenericAgentData{NewSLAID},
                    );
                    delete $GenericAgentData{NewSLAID};
                }
            }
            elsif ( $Attribute eq 'NewStateID' ) {
                if ( $GenericAgentData{NewStateID} ) {
                    $GenericAgentData{NewState} = $StateObject->StateLookup(
                        StateID => $GenericAgentData{NewStateID},
                    );
                    delete $GenericAgentData{NewStateID};
                }
            }
            elsif ( $Attribute eq 'NewTypeID' ) {
                if ( $GenericAgentData{NewTypeID} ) {
                    $GenericAgentData{NewType} = $TypeObject->TypeLookup(
                        TypeID => $GenericAgentData{NewTypeID},
                    );
                    delete $GenericAgentData{NewTypeID};
                }
            }

            # array attributes
            elsif ( $Attribute eq 'LockIDs' ) {
                if ( IsArrayRefWithData( $GenericAgentData{LockIDs} ) ) {
                    my @Locks;
                    for my $LockID ( $GenericAgentData{LockIDs}->@* ) {
                        push @Locks, $LockObject->LockLookup(
                            LockID => $LockID,
                        );
                    }
                    $GenericAgentData{Locks} = \@Locks;
                    delete $GenericAgentData{LockIDs};
                }
            }
            elsif ( $Attribute eq 'OwnerIDs' ) {
                if ( IsArrayRefWithData( $GenericAgentData{OwnerIDs} ) ) {
                    my @Owners;
                    for my $OwnerID ( $GenericAgentData{OwnerIDs}->@* ) {
                        push @Owners, $UserObject->UserLookup(
                            UserID => $OwnerID,
                        );
                    }
                    $GenericAgentData{Owners} = \@Owners;
                    delete $GenericAgentData{OwnerIDs};
                }
            }
            elsif ( $Attribute eq 'PriorityIDs' ) {
                if ( IsArrayRefWithData( $GenericAgentData{PriorityIDs} ) ) {
                    my @Priorities;
                    for my $PriorityID ( $GenericAgentData{PriorityIDs}->@* ) {
                        push @Priorities, $PriorityObject->PriorityLookup(
                            PriorityID => $PriorityID,
                        );
                    }
                    $GenericAgentData{Priorities} = \@Priorities;
                    delete $GenericAgentData{PriorityIDs};
                }
            }
            elsif ( $Attribute eq 'QueueIDs' ) {
                if ( IsArrayRefWithData( $GenericAgentData{QueueIDs} ) ) {
                    my @Queues;
                    for my $QueueID ( $GenericAgentData{QueueIDs}->@* ) {
                        push @Queues, $QueueObject->QueueLookup(
                            QueueID => $QueueID,
                        );
                    }
                    $GenericAgentData{Queues} = \@Queues;
                    delete $GenericAgentData{QueueIDs};
                }
            }
            elsif ( $Attribute eq 'ServiceIDs' ) {
                if ( IsArrayRefWithData( $GenericAgentData{ServiceIDs} ) ) {
                    my @Services;
                    for my $ServiceID ( $GenericAgentData{ServiceIDs}->@* ) {
                        push @Services, $ServiceObject->ServiceLookup(
                            ServiceID => $ServiceID,
                        );
                    }
                    $GenericAgentData{Services} = \@Services;
                    delete $GenericAgentData{ServiceIDs};
                }
            }
            elsif ( $Attribute eq 'SLAIDs' ) {
                if ( IsArrayRefWithData( $GenericAgentData{SLAIDs} ) ) {
                    my @SLAs;
                    for my $SLAID ( $GenericAgentData{SLAIDs}->@* ) {
                        push @SLAs, $SLAObject->SLALookup(
                            SLAID => $SLAID,
                        );
                    }
                    $GenericAgentData{SLAs} = \@SLAs;
                    delete $GenericAgentData{SLAIDs};
                }
            }
            elsif ( $Attribute eq 'StateIDs' ) {
                if ( IsArrayRefWithData( $GenericAgentData{StateIDs} ) ) {
                    my @States;
                    for my $StateID ( $GenericAgentData{StateIDs}->@* ) {
                        push @States, $StateObject->StateLookup(
                            StateID => $StateID,
                        );
                    }
                    $GenericAgentData{States} = \@States;
                    delete $GenericAgentData{StateIDs};
                }
            }
            elsif ( $Attribute eq 'TypeIDs' ) {
                if ( IsArrayRefWithData( $GenericAgentData{TypeIDs} ) ) {
                    my @Types;
                    for my $TypeID ( $GenericAgentData{TypeIDs}->@* ) {
                        push @Types, $TypeObject->TypeLookup(
                            TypeID => $TypeID,
                        );
                    }
                    $GenericAgentData{Types} = \@Types;
                    delete $GenericAgentData{TypeIDs};
                }
            }
        }

        $ExportData{ $GenericAgentData{Name} } = \%GenericAgentData;
    }

    return \%ExportData;
}

sub ImportGenericAgents {
    my ( $Self, %Param ) = @_;

    my $UserID = $Self->{UserID} || $Param{UserID};

    # get necessary objects
    my $GenericAgentObject = $Kernel::OM->Get('Kernel::System::GenericAgent');
    my $LockObject         = $Kernel::OM->Get('Kernel::System::Lock');
    my $PriorityObject     = $Kernel::OM->Get('Kernel::System::Priority');
    my $QueueObject        = $Kernel::OM->Get('Kernel::System::Queue');
    my $ServiceObject      = $Kernel::OM->Get('Kernel::System::Service');
    my $SLAObject          = $Kernel::OM->Get('Kernel::System::SLA');
    my $StateObject        = $Kernel::OM->Get('Kernel::System::State');
    my $TypeObject         = $Kernel::OM->Get('Kernel::System::Type');
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');

    # fetch lookup lists
    my %GenericAgentList = $GenericAgentObject->JobList();

    GENERICAGENTNAME:
    for my $GenericAgentName ( keys $Param{GenericAgents}->%* ) {
        my $GenericAgentData = $Param{GenericAgents}{$GenericAgentName};

        # check if there exists a generic agent with same name in the system
        #   NOTE GenericAgentList has format { Name => 'Name' }, therefor using a lookup is unnecessary
        my $GenericAgentCheckName = $GenericAgentList{ $GenericAgentData->{Name} };

        # skip if generic agent with same name exists and overwrite is not set
        next GENERICAGENTNAME if ( !$Param{OverwriteExistingEntities} && $GenericAgentCheckName );

        # translate named data back to IDs
        # single-value attributes
        if ( $GenericAgentData->{NewLock} ) {
            $GenericAgentData->{NewLockID} = $LockObject->LockLookup(
                Lock => $GenericAgentData->{NewLock},
            );
        }
        if ( $GenericAgentData->{NewOwner} ) {
            $GenericAgentData->{NewOwnerID} = $UserObject->UserLookup(
                UserLogin => $GenericAgentData->{NewOwner},
            );
        }
        if ( $GenericAgentData->{NewPriority} ) {
            $GenericAgentData->{NewPriorityID} = $PriorityObject->PriorityLookup(
                Priority => $GenericAgentData->{NewPriority},
            );
        }
        if ( $GenericAgentData->{NewQueue} ) {
            $GenericAgentData->{NewQueueID} = $QueueObject->QueueLookup(
                Queue => $GenericAgentData->{NewQueue},
            );
        }
        if ( $GenericAgentData->{NewService} ) {
            $GenericAgentData->{NewServiceID} = $ServiceObject->ServiceLookup(
                Name => $GenericAgentData->{NewService},
            );
        }
        if ( $GenericAgentData->{NewSLA} ) {
            $GenericAgentData->{NewSLAID} = $SLAObject->SLALookup(
                Name => $GenericAgentData->{NewSLA},
            );
        }
        if ( $GenericAgentData->{NewState} ) {
            $GenericAgentData->{NewStateID} = $StateObject->StateLookup(
                State => $GenericAgentData->{NewState},
            );
        }
        if ( $GenericAgentData->{NewType} ) {
            $GenericAgentData->{NewTypeID} = $TypeObject->TypeLookup(
                Type => $GenericAgentData->{NewType},
            );
        }

        # array attributes
        if ( IsArrayRefWithData( $GenericAgentData->{Locks} ) ) {
            my @LockIDs;
            for my $Lock ( $GenericAgentData->{Locks}->@* ) {
                push @LockIDs, $LockObject->LockLookup(
                    Lock => $Lock,
                );
            }
            $GenericAgentData->{LockIDs} = \@LockIDs;
        }
        if ( IsArrayRefWithData( $GenericAgentData->{Owners} ) ) {
            my @OwnerIDs;
            for my $Owner ( $GenericAgentData->{Owners}->@* ) {
                push @OwnerIDs, $UserObject->UserLookup(
                    UserLogin => $Owner,
                );
            }
            $GenericAgentData->{OwnerIDs} = \@OwnerIDs;
        }
        if ( IsArrayRefWithData( $GenericAgentData->{Priorities} ) ) {
            my @PriorityIDs;
            for my $Priority ( $GenericAgentData->{Priorities}->@* ) {
                push @PriorityIDs, $PriorityObject->PriorityLookup(
                    Priority => $Priority,
                );
            }
            $GenericAgentData->{PriorityIDs} = \@PriorityIDs;
        }
        if ( IsArrayRefWithData( $GenericAgentData->{Queues} ) ) {
            my @QueueIDs;
            for my $Queue ( $GenericAgentData->{Queues}->@* ) {
                push @QueueIDs, $QueueObject->QueueLookup(
                    Queue => $Queue,
                );
            }
            $GenericAgentData->{QueueIDs} = \@QueueIDs;
        }
        if ( IsArrayRefWithData( $GenericAgentData->{Services} ) ) {
            my @ServiceIDs;
            for my $Service ( $GenericAgentData->{Services}->@* ) {
                push @ServiceIDs, $ServiceObject->ServiceLookup(
                    Name => $Service,
                );
            }
            $GenericAgentData->{ServiceIDs} = \@ServiceIDs;
        }
        if ( IsArrayRefWithData( $GenericAgentData->{SLAs} ) ) {
            my @SLAIDs;
            for my $SLA ( $GenericAgentData->{SLAs}->@* ) {
                push @SLAIDs, $SLAObject->SLALookup(
                    Name => $SLA,
                );
            }
            $GenericAgentData->{SLAIDs} = \@SLAIDs;
        }
        if ( IsArrayRefWithData( $GenericAgentData->{States} ) ) {
            my @StateIDs;
            for my $State ( $GenericAgentData->{States}->@* ) {
                push @StateIDs, $StateObject->StateLookup(
                    State => $State,
                );
            }
            $GenericAgentData->{StateIDs} = \@StateIDs;
        }
        if ( IsArrayRefWithData( $GenericAgentData->{Types} ) ) {
            my @TypeIDs;
            for my $Type ( $GenericAgentData->{Types}->@* ) {
                push @TypeIDs, $TypeObject->TypeLookup(
                    Type => $Type,
                );
            }
            $GenericAgentData->{TypeIDs} = \@TypeIDs;
        }

        # update
        if ($GenericAgentCheckName) {

            # remove/clean up old profile stuff
            $GenericAgentObject->JobDelete(
                Name   => $GenericAgentCheckName,
                UserID => $UserID,
            );

            # insert new profile params
            my $Success = $GenericAgentObject->JobAdd(
                Name   => $GenericAgentCheckName,
                Data   => $GenericAgentData,
                UserID => $UserID,
            );
            return unless $Success;
        }

        # create
        else {
            my $GenericAgentID = $GenericAgentObject->JobAdd(
                Name   => $GenericAgentData->{Name},
                Data   => $GenericAgentData,
                UserID => $UserID,
            );
            return unless $GenericAgentID;
        }
    }

    return 1;
}

1;
