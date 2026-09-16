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

package Kernel::System::MELTObject::Event::DefinitionMELTObjectUpdate;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules
use List::Util qw(uniq);

# CPAN modules

# OTOBO modules

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::MELTObject',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::MELTObject::Event::DefinitionMELTObjectUpdate - Event handler that updates MELT Objects on definition changes

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    use Kernel::System::ObjectManager;

    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $EventObject = $Kernel::OM->Get('Kernel::System::MELTObject::Event::DefinitionMELTObjectUpdate');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {}, $Type;
}

=head2 Run()

This method handles the event.

    $EventObject->Run(
        Event => 'DefinitionCreate',
        Data  => {
            DefinitionID     => $DefinitionID,
            LastDefinitionID => $LastDefinitionID,
            ClassID          => $Param{ClassID},
        },
        UserID => 1,
    );

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Data Event UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    return if $Param{Event} ne 'DefinitionCreate';

    # check needed stuff
    for my $Needed (qw(DefinitionID ClassID)) {
        if ( !$Param{Data}{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed in Data!",
            );
            return;
        }
    }

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');
    my $DBObject         = $Kernel::OM->Get('Kernel::System::DB');

    # only consider productive and preproductive CIs
    my $StateList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class       => 'ZTSM::MELT::Status',
        Preferences => {
            Functionality => [ 'preproductive', 'productive' ],
        },
    );

    my $ZTSMStatusString = join q{, }, keys %{$StateList};

    # only consider productive and preproductive CIs
    my %AffectedCIs = $DBObject->SelectMapping(
        SQL => 'SELECT ci.id, ci.last_version_id FROM melt_object_item ci'
            . " WHERE ci.class_id = ? AND ci.ztsm_status_id IN ( $ZTSMStatusString )",
        Bind => [ \$Param{Data}{ClassID} ],
    );

    return if !%AffectedCIs;

    # add history entries
    for my $ID ( keys %AffectedCIs ) {
        $MELTObjectObject->HistoryAdd(
            MELTObjectID => $ID,
            HistoryType  => 'DefinitionUpdate',
            UserID       => $Param{UserID},
            Comment      => "$Param{Data}{DefinitionID}",
        );
    }

    my %ClassPreferences = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesGet(
        ItemID => $Param{Data}{ClassID},
    );

    # if we are changing reference dynamic fields, we need to synchronise the link table accordingly
    # this is done before VersionAdd, which will inevitably write the links, too, with the new Config already
    if ( $Param{Data}{OldDefinition} && $Param{Data}{OldDefinition}{DynamicFieldRef} ) {
        my $OldDynamicFieldRef = $Param{Data}{OldDefinition}{DynamicFieldRef} // {};
        my $DefinitionRef      = $MELTObjectObject->DefinitionGet(
            ClassID      => $Param{Data}->{ClassID},
            DefinitionID => $Param{Data}->{DefinitionID},
        );

        my @DynamicFieldNames = uniq( keys $DefinitionRef->{DynamicFieldRef}->%*, keys $OldDynamicFieldRef->%* );
        my %MELTObject;

        DYNAMICFIELD:
        for my $DynamicFieldName (@DynamicFieldNames) {
            my $NewDF = $DefinitionRef->{DynamicFieldRef}{$DynamicFieldName};
            my $OldDF = $OldDynamicFieldRef->{$DynamicFieldName};
            my $DF    = $NewDF // $OldDF;

            next DYNAMICFIELD unless $DF->{Config}{ReferencedObjectType};
            next DYNAMICFIELD unless $DF->{Config}{ReferencedObjectType} =~ '^MELTObject';

            my $Skip = 1;
            if ( $NewDF && $OldDF ) {
                for my $Config (qw/LinkType LinkReferencingType LinkDirection/) {
                    if ( ( $NewDF->{Config}{$Config} // '' ) ne ( $OldDF->{Config}{$Config} // '' ) ) {
                        $Skip = 0;
                    }
                }
            }
            else {
                $Skip = 0;
            }

            next DYNAMICFIELD if $Skip;

            IDS:
            for my $ID ( keys %AffectedCIs ) {
                $MELTObject{$ID} //= $MELTObjectObject->MELTObjectGet(
                    MELTObjectID  => $ID,
                    DynamicFields => 1,
                );

                my $Value = $MELTObject{$ID}{"DynamicField_$DynamicFieldName"};

                next IDS unless $Value && $Value->[0];

                $MELTObjectObject->SyncLinkTable(
                    DynamicFieldConfig      => $NewDF,
                    OldDynamicFieldConfig   => $OldDF,
                    MELTObjectID            => $ID,
                    MELTObjectVersionID     => $MELTObject{$ID}{VersionID},
                    MELTObjectLastVersionID => $MELTObject{$ID}{VersionID},
                    Value                   => $Value,
                );
            }
        }
    }

    # if definition updates should trigger the creation of a new version, call VersionAdd
    if ( grep { $_ eq 'DefinitionUpdate' } @{ $ClassPreferences{VersionTrigger} // [] } ) {
        for my $ID ( keys %AffectedCIs ) {
            $MELTObjectObject->VersionAdd(
                MELTObjectID => $ID,
                UserID       => $Param{UserID},
            );
        }
    }

    # if we do not need to add a new version, update all affected versions and clear the cache
    else {
        $DBObject->Do(
            SQL => 'UPDATE melt_object_item_version'
                . ' SET definition_id = ?'
                . ' WHERE id IN ('
                . ' SELECT last_version_id'
                . ' FROM melt_object_item'
                . ' WHERE class_id = ?'
                . " AND ztsm_status_id IN ( $ZTSMStatusString )"
                . ' )',
            Bind => [ \$Param{Data}{DefinitionID}, \$Param{Data}{ClassID} ],
        );

        # clear the cache
        my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');

        for my $ID ( keys %AffectedCIs ) {
            for my $DFData ( 0, 1 ) {
                $CacheObject->Delete(
                    Type => $MELTObjectObject->{CacheType},
                    Key  => join(
                        '::', 'MELTObjectGet',
                        MELTObjectID => $ID,
                        DFData       => $DFData,
                    ),
                );
                $CacheObject->Delete(
                    Type => $MELTObjectObject->{CacheType},
                    Key  => join(
                        '::', 'MELTObjectGet',
                        VersionID => $AffectedCIs{$ID},
                        DFData    => $DFData,
                    ),
                );
            }
        }
    }

    return 1;
}

1;

