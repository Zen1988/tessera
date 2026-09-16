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

package Kernel::System::GovernanceObject::GovernanceObjectACL;

use v5.24;
use strict;
use warnings;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::GovernanceObject::GovernanceObjectACL - Governance Object ACL lib

=head1 DESCRIPTION

All Governance Object ACL functions.

=head2 GovernanceObjectAcl()

Restricts the Data parameter sent to a subset of it, depending on a group of user defied rules
called ACLs. The reduced subset can be access from GovernanceObjectACLData() if ReturnType parameter is set
to: GovernanceObject, or in GovernanceObjectACLActionData(), if ReturnType Action is used.

Each ACL can contain different restrictions for different objects the ReturnType parameter defines
which object is considered for this restrictions, in the case of the Governance Object object a second
parameter called ReturnSubtype is needed, to specify the Governance Object attribute to be restricted, like:
C<"TBD">, etc. While for the rest of the objects a "-" value must be set. The ReturnType
and ReturnSubType must be set according to the Data parameter sent.

The rest of the attributes define the matching options for the ACL rules.

Example to restrict Governance Object actions:

    my $Success = $GovernanceObjectObject->GovernanceObjectAcl(
        Data => {                            # Values to restrict
            1 => AgentGovernanceObjectEdit,
            # ...
        },

        Action        => 'AgentGovernanceObjectEdit',   # Optional
        GovernanceObjectID  => 123,                         # Optional
        DynamicField  => {                            # Optional
            DynamicField_NameX => 123,
            DynamicField_NameZ => 'some value',
        },

        ReturnType     => 'Action',                   # To match Possible, PossibleAdd or
                                                      #   PossibleNot key in ACL
        ReturnSubType  => '-',                        # To match Possible, PossibleAdd or
                                                      #   PossibleNot sub-key in ACL

        UserID         => 123,                        # UserID => 1 is not affected by this function
    );

or to restrict Governance Object states:

    $Success = $GovernanceObjectObject->GovernanceObjectAcl(
        Data => {
            1 => 'new',
            2 => 'open',
            # ...
        },
        ReturnType    => 'GovernanceObject',
        ReturnSubType => 'State',
        UserID        => 123,
    );

returns:
    $Success = 1,                                     # if an ACL matches, or false otherwise.

If ACL modules are configured in the C<GovernanceObject::Acl::Module> config key, they are invoked
during the call to C<GovernanceObjectAcl>. The configuration of a module looks like this:

     $ConfigObject->{'GovernanceObject::Acl::Module'}->{'TheName'} = {
         Module => 'Kernel::System::GovernanceObject::Acl::TheAclModule',
         Checks => ['TBD'],
         ReturnType => 'GovernanceObject',
         ReturnSubType => ['TBD'],
     };

Each time the C<ReturnType> and one of the C<ReturnSubType> entries is identical to the same
arguments passed to C<GovernanceObjectAcl>, the module of the name in C<Module> is loaded, the C<new> method
is called on it, and then the C<Run> method is called.

The C<Checks> array reference in the configuration controls what arguments are passed. to the
C<Run> method.
Valid keys are C<Frontend> and C<GovernanceObject>.
If any of those are present, the C<Checks> argument passed to C<Run> contains an entry with the same
name, and as a value the associated data.

The C<Run> method can add entries to the C<Acl> param hash, which are then evaluated along with all
other ACL. It should only add entries whose conditionals can be checked with the data specified in
the C<Checks> configuration entry.

The return value of the C<Run> method is ignored.

=cut

sub GovernanceObjectAcl {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} && !$Param{CustomerUserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID or CustomerUserID!',
        );
        return;
    }

    # check needed stuff
    for my $Needed (qw(ReturnSubType ReturnType Data)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );

            return;
        }
    }

    # do not execute ACLs if UserID 1 is used
    return if $Param{UserID} && $Param{UserID} == 1;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $ACLs       = $ConfigObject->Get('GovernanceObjectAcl');
    my $AclModules = $ConfigObject->Get('GovernanceObject::Acl::Module');

    # do not execute ACLs if neither GovernanceObjectAcl nor GovernanceObject::Acl::Module is configured
    if ( !$ACLs && !$AclModules ) {
        return;
    }

    # find out which data we actually need
    my %ApplicableAclModules;
    my %RequiredChecks;
    my $CheckAll = 0;

    MODULENAME:
    for my $ModuleName ( sort keys %{ $AclModules // {} } ) {
        my $Module = $AclModules->{$ModuleName};

        if ( $Module->{ReturnType} && $Module->{ReturnType} ne $Param{ReturnType} ) {
            next MODULENAME;
        }

        if ( $Module->{ReturnSubType} ) {

            # TODO: this looks broken. $Module->{ReturnSubType} is a hashref, yet the value is dereferenced as an array
            if ( ref( $Module->{ReturnSubType} ) eq 'HASH' ) {
                next MODULENAME if !grep { $Param{ReturnSubType} eq $_ }
                    @{ $Module->{ReturnSubType} };
            }
            else {

                # a scalar, we hope, but it could also be an array
                # TODO: this filter looks broken
                # !$Module->{ReturnSubType} is either q{} or 1, (or !!0, and !!1)
                # so it is unlikely that a string comparison would give a true value
                next MODULENAME if ( !$Module->{ReturnSubType} ) eq $Param{ReturnSubType};
            }
        }

        # here only modules applicable to this ACL invocation remain
        $ApplicableAclModules{$ModuleName} = $Module;

        if ( $Module->{Checks} && ref( $Module->{Checks} ) eq 'ARRAY' ) {
            $RequiredChecks{$_} = 1 for @{ $Module->{Checks} };
        }
        elsif ( $Module->{Checks} ) {
            $RequiredChecks{ $Module->{Checks} } = 1;
        }
        else {
            $CheckAll = 1;
        }
    }

    return if !%ApplicableAclModules && !$ACLs && !$CheckAll;

    for my $ACL ( values %{ $ACLs // {} } ) {
        for my $Source (qw/ Properties PropertiesDatabase/) {
            for my $Check ( sort keys %{ $ACL->{$Source} } ) {
                my $CleanedUp = $Check;
                $CleanedUp =~ s/(?:ID|Name|Login)$//;
                $CleanedUp =~ s/^(?:Next|New|Old)//;
                $RequiredChecks{$CleanedUp} = 1;
                if ( $Check eq 'GovernanceObject' ) {
                    if ( ref( $ACL->{Properties}{$Check} ) eq 'HASH' ) {
                        for my $InnerCheck ( sort keys %{ $ACL->{$Source}{$Check} } ) {
                            $InnerCheck =~ s/(?:ID|Name|Login)$//;
                            $InnerCheck =~ s/^(?:Next|New|Old)//;
                            $RequiredChecks{$InnerCheck} = 1;
                        }
                    }
                }
            }
        }
    }

    # gather all required data to be compared against the ACLs
    my $CheckResult = $Self->_GetChecks(
        %Param,
        CheckAll       => $CheckAll,
        RequiredChecks => \%RequiredChecks,
    );
    my %Checks         = %{ $CheckResult->{Checks}         || {} };
    my %ChecksDatabase = %{ $CheckResult->{ChecksDatabase} || {} };

    # note that %Acls is just the dereferenced $ACLs
    my %Acls;
    if ( $ConfigObject->Get('GovernanceObjectAcl') ) {
        %Acls = %{ $ConfigObject->Get('GovernanceObjectAcl') };
    }

    # check ACL module
    MODULE:
    for my $ModuleName ( sort keys %ApplicableAclModules ) {

        my $Module = $ApplicableAclModules{$ModuleName};

        next MODULE if !$Kernel::OM->Get('Kernel::System::Main')->Require( $Module->{Module} );

        my $Generic = $Module->{Module}->new();

        $Generic->Run(
            %Param,
            Acl    => \%Acls,
            Checks => \%Checks,
            Config => $Module,
        );
    }

    # get used data
    my %Data;
    if ( ref $Param{Data} ) {
        %Data = %{ $Param{Data} };
    }

    my %NewData;
    my $UseNewMasterParams = 0;

    if ( $Param{ReturnType} eq 'Action' ) {

        if ( !IsHashRefWithData( $Param{Data} ) ) {

            # use Data if is a string and it is not '-'
            if ( IsStringWithData( $Param{Data} ) && $Param{Data} ne '-' ) {
                %Data = ( 1 => $Param{Data} );
            }

            # otherwise use the param Action
            elsif ( IsStringWithData( $Param{Action} ) ) {
                %Data = ( 1 => $Param{Action} );
            }
        }

        my %NewActionData = %Data;

        # calculate default Governance Object action ACL data
        my @ActionsToDelete;
        my $DefaultActionData = $ConfigObject->Get('GovernanceObjectACL::Default::Action') || {};

        if ( IsHashRefWithData($DefaultActionData) ) {

            for my $Index ( sort keys %NewActionData ) {

                my $Action = $NewActionData{$Index};
                if ( !$DefaultActionData->{$Index} ) {
                    push @ActionsToDelete, $Action;
                }
            }
        }

        $Self->{DefaultGovernanceObjectAclActionData} = \%NewActionData;

        for my $Action (@ActionsToDelete) {
            delete $Self->{DefaultGovernanceObjectAclActionData}->{$Action};
        }
    }

    # set NewTmpData after Possible Data recalculation on ReturnType Action
    my %NewTmpData = %Data;

    # get the debug parameters
    $Self->{ACLDebug}            = $ConfigObject->Get('GovernanceObjectACL::Debug::Enabled')     || 0;
    $Self->{ACLDebugLogPriority} = $ConfigObject->Get('GovernanceObjectACL::Debug::LogPriority') || 'debug';

    my $ACLDebugConfigFilters = $ConfigObject->Get('GovernanceObjectACL::Debug::Filter') || {};
    for my $FilterName ( sort keys %{$ACLDebugConfigFilters} ) {
        my %Filter = %{ $ACLDebugConfigFilters->{$FilterName} };
        for my $FilterItem ( sort keys %Filter ) {
            $Self->{ACLDebugFilters}->{$FilterItem} = $Filter{$FilterItem};
        }
    }

    # check if debug filters apply (Governance Object)
    if ( $Self->{ACLDebug} ) {

        DEBUGFILTER:
        for my $DebugFilter ( sort keys %{ $Self->{ACLDebugFilters} } ) {
            next DEBUGFILTER if $DebugFilter eq 'ACLName';
            next DEBUGFILTER if !$Self->{ACLDebugFilters}->{$DebugFilter};

            if ( $DebugFilter =~ m{<OTOBO_GovernanceObject_([^>]+)>}msx ) {
                my $GovernanceObjectParam = $1;

                if (
                    defined $ChecksDatabase{GovernanceObject}->{$GovernanceObjectParam}
                    && $ChecksDatabase{GovernanceObject}->{$GovernanceObjectParam}
                    && $Self->{ACLDebugFilters}->{$DebugFilter} ne
                    $ChecksDatabase{GovernanceObject}->{$GovernanceObjectParam}
                    )
                {
                    $Self->{ACLDebug} = 0;
                    last DEBUGFILTER;
                }
            }
        }
    }

    # remember last ACLDebug state (before ACLs loop)
    $Self->{ACLDebugRecovery} = $Self->{ACLDebug};

    ACLRULES:
    for my $Acl ( sort keys %Acls ) {

        # check if debug filters apply (ACL) (only if ACLDebug is active)
        if (
            $Self->{ACLDebugRecovery}
            && defined $Self->{ACLDebugFilters}->{'ACLName'}
            && $Self->{ACLDebugFilters}->{'ACLName'}
            )
        {
            # if not match current ACL disable ACLDebug
            if ( $Self->{ACLDebugFilters}->{'ACLName'} ne $Acl ) {
                $Self->{ACLDebug} = 0;
            }

            # reenable otherwise (we are sure it was enabled before)
            else {
                $Self->{ACLDebug} = 1;
            }
        }

        my %Step = %{ $Acls{$Acl} };

        # check force match
        my $ForceMatch;
        if (
            !IsHashRefWithData( $Step{Properties} )
            && !IsHashRefWithData( $Step{PropertiesDatabase} )
            )
        {
            $ForceMatch = 1;
        }

        my $PropertiesMatch;
        my $PropertiesMatchTry;
        my $PropertiesDatabaseMatch;
        my $PropertiesDatabaseMatchTry;
        my $UseNewParams = 0;

        for my $PropertiesHash (qw(Properties PropertiesDatabase)) {

            my %UsedChecks = %Checks;
            if ( $PropertiesHash eq 'PropertiesDatabase' ) {
                %UsedChecks = %ChecksDatabase;
            }

            # set match params
            my $Match    = 1;
            my $MatchTry = 0;
            for my $Key ( sort keys %{ $Step{$PropertiesHash} } ) {
                for my $Data ( sort keys %{ $Step{$PropertiesHash}->{$Key} } ) {
                    my $MatchProperty = 0;
                    for my $Item ( @{ $Step{$PropertiesHash}->{$Key}->{$Data} } ) {
                        if ( ref $UsedChecks{$Key}->{$Data} eq 'ARRAY' ) {
                            my $MatchItem = 0;
                            if ( substr( $Item, 0, length '[Not' ) eq '[Not' ) {
                                $MatchItem = 1;
                            }
                            my $MatchedArrayDataItem;
                            ARRAYDATAITEM:
                            for my $ArrayDataItem ( @{ $UsedChecks{$Key}->{$Data} } ) {
                                $MatchedArrayDataItem = $ArrayDataItem;
                                my $LoopMatchResult = $Self->_CompareMatchWithData(
                                    Match      => $Item,
                                    Data       => $ArrayDataItem,
                                    SingleItem => 0,
                                );
                                if ( !$LoopMatchResult->{Skip} )
                                {
                                    $MatchItem = $LoopMatchResult->{Match};
                                    last ARRAYDATAITEM;
                                }
                            }
                            if ($MatchItem) {
                                $MatchProperty = 1;

                                # debug log
                                if ( $Self->{ACLDebug} ) {
                                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                                        Priority => $Self->{ACLDebugLogPriority},
                                        Message  =>
                                            "GovernanceObjectACL '$Acl' $PropertiesHash:'$Key->$Data' MatchedARRAY ($Item eq $MatchedArrayDataItem)",
                                    );
                                }
                            }
                        }
                        elsif ( defined $UsedChecks{$Key}->{$Data} ) {

                            my $DataItem    = $UsedChecks{$Key}->{$Data};
                            my $MatchResult = $Self->_CompareMatchWithData(
                                Match      => $Item,
                                Data       => $DataItem,
                                SingleItem => 1
                            );

                            if ( $MatchResult->{Match} ) {
                                $MatchProperty = 1;

                                # debug
                                if ( $Self->{ACLDebug} ) {
                                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                                        Priority => $Self->{ACLDebugLogPriority},
                                        Message  =>
                                            "GovernanceObjectACL '$Acl' $PropertiesHash:'$Key->$Data' Matched ($Item eq $UsedChecks{$Key}->{$Data})",
                                    );
                                }
                            }
                        }
                    }
                    if ( !$MatchProperty ) {
                        $Match = 0;
                    }
                    $MatchTry = 1;
                }
            }

            # check force option
            if ($ForceMatch) {
                $Match    = 1;
                $MatchTry = 1;
            }

            if ( $PropertiesHash eq 'Properties' ) {
                $PropertiesMatch    = $Match;
                $PropertiesMatchTry = $MatchTry;
            }
            else {
                $PropertiesDatabaseMatch    = $Match;
                $PropertiesDatabaseMatchTry = $MatchTry;
            }

            # check if properties is missing
            if ( !IsHashRefWithData( $Step{Properties} ) ) {
                $PropertiesMatch    = $PropertiesDatabaseMatch;
                $PropertiesMatchTry = $PropertiesDatabaseMatchTry;
            }

            # check if properties database is missing
            if ( !IsHashRefWithData( $Step{PropertiesDatabase} ) ) {
                $PropertiesDatabaseMatch    = $PropertiesMatch;
                $PropertiesDatabaseMatchTry = $PropertiesMatchTry;
            }
        }

        # the following logic should be applied to calculate if an ACL matches:
        # if both Properties and PropertiesDatabase match => match
        # if Properties matches, and PropertiesDatabase does not match => no match
        # if PropertiesDatabase matches, but Properties does not match => no match
        # if PropertiesDatabase matches, and Properties is missing => match
        # if Properties matches, and PropertiesDatabase is missing => match.
        my $Match;
        if ( $PropertiesMatch && $PropertiesDatabaseMatch ) {
            $Match = 1;
        }

        my $MatchTry;
        if ( $PropertiesMatchTry && $PropertiesDatabaseMatchTry ) {
            $MatchTry = 1;
        }

        # debug log
        if ( $Match && $MatchTry ) {
            if ( $Self->{ACLDebug} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => $Self->{ACLDebugLogPriority},
                    Message  =>
                        "GovernanceObjectACL '$Acl' Matched for return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                );
            }
        }

        my %SpecialReturnTypes = (
            Action         => 1,
            Process        => 1,
            ActivityDialog => 1,
            Form           => 1,
            FormStd        => 1,
        );

        if ( $SpecialReturnTypes{ $Param{ReturnType} } ) {

            # build new Special ReturnType data hash (ProcessManagement)
            # for Special ReturnType Step{Possible}
            if (
                ( %Checks || %ChecksDatabase )
                && $Match
                && $MatchTry
                && $Step{Possible}->{ $Param{ReturnType} }
                && IsArrayRefWithData( $Step{Possible}->{ $Param{ReturnType} } )
                )
            {
                $UseNewParams = 1;

                # reset return data as it will be filled with just the Possible Items excluded the
                #    ones that are not in the possible section, this is the same as remove all
                #    missing items from the original data
                %NewTmpData = ();

                # debug log
                if ( $Self->{ACLDebug} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => $Self->{ACLDebugLogPriority},
                        Message  =>
                            "GovernanceObjectACL '$Acl' Used with Possible:'$Param{ReturnType}:$Param{ReturnSubType}'",
                    );
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => $Self->{ACLDebugLogPriority},
                        Message  =>
                            "GovernanceObjectACL '$Acl' Reset return data:'$Param{ReturnType}:$Param{ReturnSubType}''",
                    );
                }

                # possible list
                for my $ID ( sort keys %Data ) {

                    for my $New ( @{ $Step{Possible}->{ $Param{ReturnType} } } ) {
                        my $MatchResult = $Self->_CompareMatchWithData(
                            Match      => $New,
                            Data       => $Data{$ID},
                            SingleItem => 1
                        );
                        if ( $MatchResult->{Match} ) {
                            $NewTmpData{$ID} = $Data{$ID};
                            if ( $Self->{ACLDebug} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => $Self->{ACLDebugLogPriority},
                                    Message  =>
                                        "GovernanceObjectACL '$Acl' Possible param '$Data{$ID}' added to return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                                );
                            }
                        }
                        else {
                            if ( $Self->{ACLDebug} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => $Self->{ACLDebugLogPriority},
                                    Message  =>
                                        "GovernanceObjectACL '$Acl' Possible param '$Data{$ID}' skipped from return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                                );
                            }
                        }
                    }
                }
            }

            # for Special ReturnType Step{PossibleAdd}
            if (
                ( %Checks || %ChecksDatabase )
                && $Match
                && $MatchTry
                && $Step{PossibleAdd}->{ $Param{ReturnType} }
                && IsArrayRefWithData( $Step{PossibleAdd}->{ $Param{ReturnType} } )
                )
            {

                $UseNewParams = 1;

                # debug log
                if ( $Self->{ACLDebug} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => $Self->{ACLDebugLogPriority},
                        Message  =>
                            "GovernanceObjectACL '$Acl' Used with PossibleAdd:'$Param{ReturnType}:$Param{ReturnSubType}'",
                    );
                }

                # possible add list
                for my $ID ( sort keys %Data ) {

                    for my $New ( @{ $Step{PossibleAdd}->{ $Param{ReturnType} } } ) {
                        my $MatchResult = $Self->_CompareMatchWithData(
                            Match      => $New,
                            Data       => $Data{$ID},
                            SingleItem => 1
                        );
                        if ( $MatchResult->{Match} ) {
                            $NewTmpData{$ID} = $Data{$ID};
                            if ( $Self->{ACLDebug} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => $Self->{ACLDebugLogPriority},
                                    Message  =>
                                        "GovernanceObjectACL '$Acl' PossibleAdd param '$Data{$ID}' added to return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                                );
                            }
                        }
                        else {
                            if ( $Self->{ACLDebug} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => $Self->{ACLDebugLogPriority},
                                    Message  =>
                                        "GovernanceObjectACL '$Acl' PossibleAdd param '$Data{$ID}' skipped from return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                                );
                            }
                        }
                    }
                }
            }

            # for Special Step{PossibleNot}
            if (
                ( %Checks || %ChecksDatabase )
                && $Match
                && $MatchTry
                && $Step{PossibleNot}->{ $Param{ReturnType} }
                && IsArrayRefWithData( $Step{PossibleNot}->{ $Param{ReturnType} } )
                )
            {

                $UseNewParams = 1;

                # debug log
                if ( $Self->{ACLDebug} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => $Self->{ACLDebugLogPriority},
                        Message  =>
                            "GovernanceObjectACL '$Acl' Used with PossibleNot:'$Param{ReturnType}:$Param{ReturnSubType}'",
                    );
                }

                # not possible list
                for my $ID ( sort keys %Data ) {
                    my $Match = 1;
                    for my $New ( @{ $Step{PossibleNot}->{ $Param{ReturnType} } } ) {
                        my $LoopMatchResult = $Self->_CompareMatchWithData(
                            Match      => $New,
                            Data       => $Data{$ID},
                            SingleItem => 1
                        );
                        if ( $LoopMatchResult->{Match} ) {
                            $Match = 0;
                        }
                    }
                    if ( !$Match ) {
                        if ( $Self->{ACLDebug} ) {
                            $Kernel::OM->Get('Kernel::System::Log')->Log(
                                Priority => $Self->{ACLDebugLogPriority},
                                Message  =>
                                    "GovernanceObjectACL '$Acl' PossibleNot param '$Data{$ID}' removed from return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                            );
                        }
                        if ( $NewTmpData{$ID} ) {
                            delete $NewTmpData{$ID};
                        }
                    }
                    else {
                        if ( $Self->{ACLDebug} ) {
                            $Kernel::OM->Get('Kernel::System::Log')->Log(
                                Priority => $Self->{ACLDebugLogPriority},
                                Message  =>
                                    "GovernanceObjectACL '$Acl' PossibleNot param '$Data{$ID}' leaved for return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                            );
                        }
                    }
                }
            }
        }

        elsif ( $Param{ReturnType} eq 'GovernanceObject' ) {

            # build new Governance Object data hash
            # Step Governance Object Possible (Resets White list)
            if (
                ( %Checks || %ChecksDatabase )
                && $Match
                && $MatchTry
                && $Step{Possible}->{GovernanceObject}->{ $Param{ReturnSubType} }
                )
            {
                $UseNewParams = 1;

                # reset return data as it will be filled with just the Possible Items excluded the ones
                # that are not in the possible section, this is the same as remove all missing items from
                # the original data
                %NewTmpData = ();

                # debug log
                if ( $Self->{ACLDebug} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => $Self->{ACLDebugLogPriority},
                        Message  =>
                            "GovernanceObjectACL '$Acl' Used with Possible:'$Param{ReturnType}:$Param{ReturnSubType}'",
                    );
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => $Self->{ACLDebugLogPriority},
                        Message  =>
                            "GovernanceObjectACL '$Acl' Reset return data:'$Param{ReturnType}:$Param{ReturnSubType}''",
                    );
                }

                # possible list
                for my $ID ( sort keys %Data ) {

                    for my $New ( @{ $Step{Possible}->{GovernanceObject}->{ $Param{ReturnSubType} } } ) {
                        my $MatchResult = $Self->_CompareMatchWithData(
                            Match      => $New,
                            Data       => $Data{$ID},
                            SingleItem => 1
                        );
                        if ( $MatchResult->{Match} ) {
                            $NewTmpData{$ID} = $Data{$ID};
                            if ( $Self->{ACLDebug} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => $Self->{ACLDebugLogPriority},
                                    Message  =>
                                        "GovernanceObjectACL '$Acl' Possible param '$Data{$ID}' added to return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                                );
                            }
                        }
                        else {
                            if ( $Self->{ACLDebug} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => $Self->{ACLDebugLogPriority},
                                    Message  =>
                                        "GovernanceObjectACL '$Acl' Possible param '$Data{$ID}' skipped from return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                                );
                            }
                        }
                    }
                }
            }

            # Step Governance Object PossibleAdd (Add new options to the white list)
            if (
                ( %Checks || %ChecksDatabase )
                && $Match
                && $MatchTry
                && $Step{PossibleAdd}->{GovernanceObject}->{ $Param{ReturnSubType} }
                )
            {
                $UseNewParams = 1;

                # debug log
                if ( $Self->{ACLDebug} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => $Self->{ACLDebugLogPriority},
                        Message  =>
                            "GovernanceObjectACL '$Acl' Used with PossibleAdd:'$Param{ReturnType}:$Param{ReturnSubType}'",
                    );
                }

                # possible add list
                for my $ID ( sort keys %Data ) {

                    for my $New ( @{ $Step{PossibleAdd}->{GovernanceObject}->{ $Param{ReturnSubType} } } ) {
                        my $MatchResult = $Self->_CompareMatchWithData(
                            Match      => $New,
                            Data       => $Data{$ID},
                            SingleItem => 1
                        );
                        if ( $MatchResult->{Match} ) {
                            $NewTmpData{$ID} = $Data{$ID};
                            if ( $Self->{ACLDebug} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => $Self->{ACLDebugLogPriority},
                                    Message  =>
                                        "GovernanceObjectACL '$Acl' PossibleAdd param '$Data{$ID}' added to return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                                );
                            }
                        }
                        else {
                            if ( $Self->{ACLDebug} ) {
                                $Kernel::OM->Get('Kernel::System::Log')->Log(
                                    Priority => $Self->{ACLDebugLogPriority},
                                    Message  =>
                                        "GovernanceObjectACL '$Acl' PossibleAdd param '$Data{$ID}' skipped from return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                                );
                            }
                        }
                    }
                }
            }

            # Step Governance Object PossibleNot (removes options from white list)
            if (
                ( %Checks || %ChecksDatabase )
                && $Match
                && $MatchTry
                && $Step{PossibleNot}->{GovernanceObject}->{ $Param{ReturnSubType} }
                )
            {
                $UseNewParams = 1;

                # debug log
                if ( $Self->{ACLDebug} ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => $Self->{ACLDebugLogPriority},
                        Message  =>
                            "GovernanceObjectACL '$Acl' Used with PossibleNot:'$Param{ReturnType}:$Param{ReturnSubType}'",
                    );
                }

                # not possible list
                for my $ID ( sort keys %Data ) {
                    my $Match = 1;
                    for my $New ( @{ $Step{PossibleNot}->{GovernanceObject}->{ $Param{ReturnSubType} } } ) {
                        my $LoopMatchResult = $Self->_CompareMatchWithData(
                            Match      => $New,
                            Data       => $Data{$ID},
                            SingleItem => 1
                        );
                        if ( $LoopMatchResult->{Match} ) {
                            $Match = 0;
                        }
                    }
                    if ( !$Match ) {
                        if ( $Self->{ACLDebug} ) {
                            $Kernel::OM->Get('Kernel::System::Log')->Log(
                                Priority => $Self->{ACLDebugLogPriority},
                                Message  =>
                                    "GovernanceObjectACL '$Acl' PossibleNot param '$Data{$ID}' removed from return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                            );
                        }
                        if ( $NewTmpData{$ID} ) {
                            delete $NewTmpData{$ID};
                        }
                    }
                    else {
                        if ( $Self->{ACLDebug} ) {
                            $Kernel::OM->Get('Kernel::System::Log')->Log(
                                Priority => $Self->{ACLDebugLogPriority},
                                Message  =>
                                    "GovernanceObjectACL '$Acl' PossibleNot param '$Data{$ID}' leaved for return data:'$Param{ReturnType}:$Param{ReturnSubType}'",
                            );
                        }
                    }
                }
            }
        }

        # remember to new params if given
        if ($UseNewParams) {
            %NewData            = %NewTmpData;
            $UseNewMasterParams = 1;
        }

        # return new params if stop after this step
        if ( $UseNewParams && $Step{StopAfterMatch} ) {
            $Self->{GovernanceObjectAclData} = \%NewData;

            # if we stop after the first match
            # exit the ACLRULES loop
            last ACLRULES;
        }
    }

    # return if no new param exists
    return if !$UseNewMasterParams;

    $Self->{GovernanceObjectAclData} = \%NewData;

    return 1;
}

=head2 GovernanceObjectAclData()

return the current ACL data hash after GovernanceObjectAcl()

    my %Acl = $GovernanceObjectObject->GovernanceObjectAclData();

=cut

sub GovernanceObjectAclData {
    my ( $Self, %Param ) = @_;

    return %{ $Self->{GovernanceObjectAclData} || {} };
}

=head2 GovernanceObjectAclActionData()

return the current ACL action data hash after GovernanceObjectAcl()

    my %AclAction = $GovernanceObjectObject->GovernanceObjectAclActionData();

=cut

sub GovernanceObjectAclActionData {
    my ( $Self, %Param ) = @_;

    if ( $Self->{GovernanceObjectAclData} ) {
        return %{ $Self->{GovernanceObjectAclData} };
    }
    return %{ $Self->{DefaultGovernanceObjectActionData} || {} };
}

=begin Internal:

=cut

=head2 _GetChecks()

creates two check hashes (one for current data updatable via AJAX refreshes and another for
static Governance Object data stored in the DB) with the required data to use as a basis to match the ACLs

    my $ChecskResult = $GovernanceObjectObject->_GetChecks(
        CheckAll => '1',                              # Optional
        RequiredChecks => $RequiredCheckHashRef,      # Optional a hash reference with the
                                                      #    attributes to gather:
                                                      #    e. g. User => 1, will fetch all user
                                                      #    information from the database, this data
                                                      #    will be tried to match with current ACLs
        Action        => 'AgentGovernanceObjectZoom',           # Optional
        GovernanceObjectID      => 123,                         # Optional
        DynamicField  => {                            # Optional
            DynamicField_NameX => 123,
            DynamicField_NameZ => 'some value',
        },

        ResponsibleID    => 123,                      # Optional
        NewResponsibleID => 123,                      # Optional, ResponsibleID or NewResponsibleID
                                                      #   can be used and they both refers to
                                                      #     ResponsibleID
        Responsible      => 'some user login'         # Optional

        UserID         => 123,                        # UserID => 1 is not affected by this function
    );

returns:
    $ChecksResult = {
        Checks => {
            # ...
            GovernanceObject => {
                GovernanceObjectID => 123,
                # ...
            },
            # ...
        },
        ChecksDatabase =>
            # ...
            GovernanceObject => {
                GovernanceObjectID => 123,
                # ...
            },
            # ...
        },
    };

=cut

sub _GetChecks {
    my ( $Self, %Param ) = @_;

    my $CheckAll       = $Param{CheckAll};
    my %RequiredChecks = %{ $Param{RequiredChecks} };

    # get used interface for process management checks
    my $Interface = 'AgentInterface';
    if ( !$Param{UserID} ) {
        $Interface = 'CustomerInterface';
    }

    my %Checks;
    my %ChecksDatabase;

    if ( $Param{Action} ) {
        $Checks{Frontend} = {
            Action => $Param{Action},
        };
        $ChecksDatabase{Frontend} = {
            Action => $Param{Action},
        };
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # use Governance Object data if Governance Object id is given
    # do that always, even if $RequiredChecks{GovernanceObject} is not that
    # (because too much stuff depends on it)
    if ( $Param{GovernanceObjectID} ) {
        my $GovernanceObject = $Self->GovernanceObjectGet(
            %Param,
            DynamicFields => 1,
        );
        $Checks{GovernanceObject} = $GovernanceObject;

        # keep database Governance Object data separated since the reference is affected below
        $ChecksDatabase{GovernanceObject} = \%{$GovernanceObject};
    }
    else {
        $Checks{GovernanceObject} = {
            Class   => $Param{Class},
            ClassID => $Param{ClassID},
        };
    }

    # check for dynamic fields
    if ( IsHashRefWithData( $Param{DynamicField} ) ) {
        $Checks{DynamicField} = $Param{DynamicField};

        # update or add dynamic fields information to the Governance Object check
        for my $DynamicFieldName ( sort keys %{ $Param{DynamicField} } ) {
            $Checks{GovernanceObject}->{$DynamicFieldName} = $Param{DynamicField}->{$DynamicFieldName};
        }
    }

    # always get info FROM governance_object_item too and set it to the Dynamic Field check hash if the info is
    # different. this can be done because in the previous step Governance Object info was updated. but maybe
    # Governance Object has more information stored than in the DynamicField parameter.
    GovernanceObjectATTRIBUTE:
    for my $GovernanceObjectAttribute ( sort keys %{ $Checks{GovernanceObject} // {} } ) {
        next GovernanceObjectATTRIBUTE if !$GovernanceObjectAttribute;

        # check if is a dynamic field with data
        next GovernanceObjectATTRIBUTE if $GovernanceObjectAttribute !~ m{ \A DynamicField_ }smx;
        next GovernanceObjectATTRIBUTE if !defined $Checks{GovernanceObject}->{$GovernanceObjectAttribute};
        next GovernanceObjectATTRIBUTE if !length $Checks{GovernanceObject}->{$GovernanceObjectAttribute};

        if (
            ref $Checks{GovernanceObject}->{$GovernanceObjectAttribute} eq 'ARRAY'
            && !IsArrayRefWithData( $Checks{GovernanceObject}->{$GovernanceObjectAttribute} )
            )
        {
            next GovernanceObjectATTRIBUTE;
        }

        # compare if data is different and skip on same data
        if (
            $Checks{DynamicField}->{$GovernanceObjectAttribute}
            && !DataIsDifferent(
                Data1 => $Checks{GovernanceObject}->{$GovernanceObjectAttribute},
                Data2 => $Checks{DynamicField}->{$GovernanceObjectAttribute},
            )
            )
        {
            next GovernanceObjectATTRIBUTE;
        }

        $Checks{DynamicField}->{$GovernanceObjectAttribute} = $Checks{GovernanceObject}->{$GovernanceObjectAttribute};
    }

    # also copy the database information to the appropriate hash
    GovernanceObjectATTRIBUTE:
    for my $GovernanceObjectAttribute ( sort keys %{ $ChecksDatabase{GovernanceObject} } ) {
        next GovernanceObjectATTRIBUTE if !$GovernanceObjectAttribute;

        # check if is a dynamic field with data
        next GovernanceObjectATTRIBUTE if $GovernanceObjectAttribute !~ m{ \A DynamicField_ }smx;
        next GovernanceObjectATTRIBUTE if !defined $ChecksDatabase{GovernanceObject}->{$GovernanceObjectAttribute};
        next GovernanceObjectATTRIBUTE if !length $ChecksDatabase{GovernanceObject}->{$GovernanceObjectAttribute};

        if (
            ref $ChecksDatabase{GovernanceObject}->{$GovernanceObjectAttribute} eq 'ARRAY'
            && !IsArrayRefWithData( $ChecksDatabase{GovernanceObject}->{$GovernanceObjectAttribute} )
            )
        {
            next GovernanceObjectATTRIBUTE;
        }

        $ChecksDatabase{DynamicField}->{$GovernanceObjectAttribute} = $ChecksDatabase{GovernanceObject}->{$GovernanceObjectAttribute};
    }

    # use user data
    if ( ( $CheckAll || $RequiredChecks{User} ) && $Param{UserID} ) {

        my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
            UserID => $Param{UserID},
        );

        # get group object
        my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

        for my $Type ( @{ $ConfigObject->Get('System::Permission') } ) {

            my %Groups = $GroupObject->PermissionUserGet(
                UserID => $Param{UserID},
                Type   => $Type,
            );

            my @GroupNames = sort values %Groups;

            $User{"Group_$Type"} = \@GroupNames;
        }

        my %RoleIDs = $GroupObject->PermissionUserRoleGet(
            UserID => $Param{UserID},
        );

        my @RoleNames = sort values %RoleIDs;

        $User{Role}           = \@RoleNames;
        $Checks{User}         = \%User;
        $ChecksDatabase{User} = \%User;
    }

    # use type data (if given)
    if ( $CheckAll || $RequiredChecks{Type} ) {

        # get type object
        my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

        if ( $Param{TypeID} ) {
            my %Type = $TypeObject->TypeGet(
                ID     => $Param{TypeID},
                UserID => 1,
            );
            $Checks{Type} = \%Type;

            # update or add Governance Object type information to the Governance Object check
            $Checks{GovernanceObject}->{Type}   = $Checks{Type}->{Name};
            $Checks{GovernanceObject}->{TypeID} = $Checks{Type}->{ID};
        }
        elsif ( $Param{Type} ) {

            # TODO Attention!
            #
            # The parameter type can contain not only the wanted Governance Object type, because also
            # some other functions in Kernel/System/GovernanceObject.pm use a type parameter, for example
            # MoveList() etc... These functions could be rewritten to not
            # use a Type parameter, or the functions that call GovernanceObjectAcl() could be modified to
            # not just pass the complete Param-Hash, but instead a new parameter, like FrontEndParameter.
            #
            # As a workaround we lookup the TypeList first, and compare if the type parameter
            # is found in the list, so we can be more sure that it is the type that we want here.

            # lookup the type list (workaround for described problem)
            my %TypeList = reverse $TypeObject->TypeList();

            # check if type is in the type list (workaround for described problem)
            if ( $TypeList{ $Param{Type} } ) {
                my %Type = $TypeObject->TypeGet(
                    Name   => $Param{Type},
                    UserID => 1,
                );
                $Checks{Type} = \%Type;

                # update or add Governance Object type information to the Governance Object check
                $Checks{GovernanceObject}->{Type}   = $Checks{Type}->{Name};
                $Checks{GovernanceObject}->{TypeID} = $Checks{Type}->{ID};
            }
        }
        elsif ( !$Param{TypeID} && !$Param{Type} ) {
            if ( IsPositiveInteger( $Checks{GovernanceObject}->{TypeID} ) ) {

                # get type data from the Governance Object
                my %Type = $TypeObject->TypeGet(
                    ID     => $Checks{GovernanceObject}->{TypeID},
                    UserID => 1,
                );
                $Checks{Type} = \%Type;
            }
        }

        # create hash with the Governance Object information stored in the database
        if ( IsPositiveInteger( $ChecksDatabase{GovernanceObject}->{TypeID} ) ) {

            # check if database data matches current data (performance)
            if (
                defined $Checks{Type}->{ID}
                && $ChecksDatabase{GovernanceObject}->{TypeID} eq $Checks{Type}->{ID}
                )
            {
                $ChecksDatabase{Type} = $Checks{Type};
            }

            # otherwise complete the data querying the database again
            else {
                my %Type = $TypeObject->TypeGet(
                    ID     => $ChecksDatabase{GovernanceObject}->{TypeID},
                    UserID => 1,
                );
                $ChecksDatabase{Type} = \%Type;
            }
        }
    }

    # within this function %Param is modified by replacements like:
    #    $Param{PriorityID} = $Param{NewPriorityID}
    #    apparently this changes are not longer needed outside this function and it is not necessary
    #    to return such replacements

    return {
        Checks         => \%Checks,
        ChecksDatabase => \%ChecksDatabase,
    };
}

=head2 _CompareMatchWithData()

Compares a properties element with the data sent to the ACL, the compare results varies on how the
ACL properties where defined including normal, negated, regular expression and negated regular
expression comparisons.

    my $Result = $GovernanceObjectObject->_CompareMatchWithData(
        Match => 'a value',         # or '[Not]a value', or '[RegExp]val' or '[NotRegExp]val'
                                    #    or '[Notregexp]val' or '[Notregexp]'
        Data => 'a value',
        SingleItem => 1,            # or 0, optional, default 0
    );

Returns:

    $Result = {
        Success => 1,               # or false
        Match   => 1,               # or false
        Skip    => 1,               # or false (in certain cases where SingleItem is set)
    };

=cut

sub _CompareMatchWithData {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Match Data)) {
        if ( !defined $Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return {
                Success => 0,
            };
        }
    }

    my $Match = $Param{Match};
    my $Data  = $Param{Data};

    # Negated matches requires a different logic.
    if ( substr( $Match, 0, length '[Not' ) eq '[Not' ) {

        # Not equal match
        if ( substr( $Match, 0, length '[Not]' ) eq '[Not]' ) {
            my $NotValue = substr $Match, length '[Not]';
            if ( $NotValue eq $Data ) {
                return {
                    Success => 1,
                    Match   => 0,
                };
            }
        }

        # Not reg-exp match case-sensitive.
        elsif ( substr( $Match, 0, length '[NotRegExp]' ) eq '[NotRegExp]' ) {
            my $RegExp = substr $Match, length '[NotRegExp]';
            if ( $Data =~ /$RegExp/ ) {
                return {
                    Success => 1,
                    Match   => 0,
                };
            }
        }

        # Not reg-exp match case-insensitive.
        elsif ( substr( $Match, 0, length '[Notregexp]' ) eq '[Notregexp]' ) {
            my $RegExp = substr $Match, length '[Notregexp]';
            if ( $Data =~ /$RegExp/i ) {
                return {
                    Success => 1,
                    Match   => 0,
                };
            }
        }

        if ( $Param{SingleItem} ) {
            return {
                Success => 1,
                Match   => 1,
                Skip    => 0,
            };
        }
        else {
            return {
                Success => 1,
                Match   => 1,
                Skip    => 1,
            };
        }
    }
    else {

        # Equal match.
        if ( $Match eq $Data ) {
            return {
                Success => 1,
                Match   => 1,
            };
        }

        # Reg-exp match case-sensitive.
        elsif ( substr( $Match, 0, length '[RegExp]' ) eq '[RegExp]' ) {
            my $RegExp = substr $Match, length '[RegExp]';
            if ( $Data =~ /$RegExp/ ) {
                return {
                    Success => 1,
                    Match   => 1,
                };
            }
        }

        # Reg-exp match case-insensitive.
        elsif ( substr( $Match, 0, length '[regexp]' ) eq '[regexp]' ) {
            my $RegExp = substr $Match, length '[regexp]';
            if ( $Data =~ /$RegExp/i ) {
                return {
                    Success => 1,
                    Match   => 1,
                };
            }
        }

        if ( $Param{SingleItem} ) {
            return {
                Success => 1,
                Match   => 0,
                Skip    => 0,
            };
        }
        else {
            return {
                Success => 1,
                Match   => 0,
                Skip    => 1,
            };
        }
    }
}

=end Internal:

=cut

1;
