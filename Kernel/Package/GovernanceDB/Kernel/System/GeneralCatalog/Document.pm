# --
# OTOBO is a web-based ticketing system for service organisations.
# --
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

package Kernel::System::GeneralCatalog::Document;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

our @ObjectDependencies = (
    'Kernel::System::GeneralCatalog',
    'Kernel::System::JSON',
    'Kernel::System::Log',
    'Kernel::System::Valid',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::GeneralCatalog::Document - YAML/JSON document codec for General Catalog classes.

=cut

sub new {
    my ($Type) = @_;

    return bless {}, $Type;
}

sub Export {
    my ( $Self, %Param ) = @_;

    my @Classes = $Self->_ClassesNormalize( Classes => $Param{Classes} );

    if ( !@Classes ) {
        @Classes = @{ $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ClassList() || [] };
    }

    my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

    my @DocumentClasses;
    CLASS:
    for my $Class ( sort @Classes ) {
        next CLASS if !IsStringWithData($Class);

        my $ItemList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
            Class => $Class,
            Valid => 0,
        );

        next CLASS if !IsHashRefWithData($ItemList);

        my @Items;
        ITEMID:
        for my $ItemID ( sort { lc $ItemList->{$a} cmp lc $ItemList->{$b} } keys %{$ItemList} ) {
            my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
                ItemID => $ItemID,
            );

            next ITEMID if !IsHashRefWithData($Item);

            my %Preferences = map { $_ => $Item->{$_} }
                grep {
                !m{\A(?:ItemID|Class|Name|ValidID|Comment|CreateTime|CreateBy|ChangeTime|ChangeBy)\z}xms
                } keys %{$Item};

            push @Items, {
                name        => $Item->{Name},
                valid       => $ValidList{ $Item->{ValidID} } || $Item->{ValidID},
                comment     => $Item->{Comment} // '',
                preferences => \%Preferences,
            };
        }

        push @DocumentClasses, {
            class => $Class,
            items => \@Items,
        };
    }

    my $Document = {
        object_type => 'GeneralCatalog',
        classes     => \@DocumentClasses,
    };

    return $Self->Serialize(
        Data   => $Document,
        Format => $Param{Format},
    ) if $Param{Format};

    return $Document;
}

sub Import {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $Document = $Param{Data};
    if ( !ref $Document ) {
        $Document = $Self->Parse(
            Data   => $Param{Content},
            Format => $Param{Format},
        );
    }

    if ( !IsHashRefWithData($Document) ) {
        return {
            Success => 0,
            Message => 'Document must be a YAML or JSON object.',
        };
    }

    my $Classes = $Document->{classes} || $Document->{Classes};
    if ( !IsArrayRefWithData($Classes) ) {
        return {
            Success => 0,
            Message => 'classes must be a non-empty array.',
        };
    }

    my $Created = 0;
    my $Updated = 0;
    my $Skipped = 0;

    CLASS:
    for my $ClassEntry ( @{$Classes} ) {
        if ( !IsHashRefWithData($ClassEntry) ) {
            $Skipped++;
            next CLASS;
        }

        my $Class = $ClassEntry->{class} || $ClassEntry->{Class};
        my $Items = $ClassEntry->{items} || $ClassEntry->{Items};

        if ( !IsStringWithData($Class) || !IsArrayRefWithData($Items) ) {
            $Skipped++;
            next CLASS;
        }

        ITEM:
        for my $Item ( @{$Items} ) {
            if ( !IsHashRefWithData($Item) || !defined $Item->{name} && !defined $Item->{Name} ) {
                $Skipped++;
                next ITEM;
            }

            my $Name    = defined $Item->{name} ? $Item->{name} : $Item->{Name};
            my $Comment = defined $Item->{comment} ? $Item->{comment} : $Item->{Comment};
            my $ValidID = $Self->_ValidIDResolve( Value => $Item->{valid} // $Item->{Valid} // $Item->{ValidID} );

            if ( !defined $Name || !length $Name || !$ValidID ) {
                $Skipped++;
                next ITEM;
            }

            my $Existing;
            my $ExistingItemList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
                Class => $Class,
                Valid => 0,
            );
            if ( IsHashRefWithData($ExistingItemList) ) {
                EXISTINGITEMID:
                for my $ExistingItemID ( sort keys %{$ExistingItemList} ) {
                    next EXISTINGITEMID if ( $ExistingItemList->{$ExistingItemID} // '' ) ne $Name;

                    $Existing = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
                        ItemID => $ExistingItemID,
                    );
                    last EXISTINGITEMID;
                }
            }

            my $ItemID;
            if ( IsHashRefWithData($Existing) ) {
                my $Success = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemUpdate(
                    ItemID  => $Existing->{ItemID},
                    Name    => $Name,
                    ValidID => $ValidID,
                    Comment => $Comment // '',
                    UserID  => $Param{UserID},
                );

                if (!$Success) {
                    $Skipped++;
                    next ITEM;
                }

                $ItemID = $Existing->{ItemID};
                $Updated++;
            }
            else {
                $ItemID = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemAdd(
                    Class   => $Class,
                    Name    => $Name,
                    ValidID => $ValidID,
                    Comment => $Comment // '',
                    UserID  => $Param{UserID},
                );

                if (!$ItemID) {
                    $Skipped++;
                    next ITEM;
                }

                $Created++;
            }

            my $Preferences = $Item->{preferences} || $Item->{Preferences} || {};
            next ITEM if ref $Preferences ne 'HASH';

            PREFERENCE:
            for my $Key ( sort keys %{$Preferences} ) {
                my $Value = $Preferences->{$Key};
                my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);

                next PREFERENCE if !defined $Key || $Key eq '';

                $Kernel::OM->Get('Kernel::System::GeneralCatalog')->GeneralCatalogPreferencesSet(
                    ItemID => $ItemID,
                    Key    => $Key,
                    Value  => [ grep { defined $_ } @Values ],
                );
            }
        }
    }

    return {
        Success => 1,
        Created => $Created,
        Updated => $Updated,
        Skipped => $Skipped,
        Message => "General Catalog import completed. Created: $Created, updated: $Updated, skipped: $Skipped.",
    };
}

sub Parse {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{Data} && !defined $Param{Content};

    my $Data   = defined $Param{Data} ? $Param{Data} : $Param{Content};
    my $Format = lc( $Param{Format} || '' );

    if ( !$Format ) {
        $Format = $Data =~ m{\A\s*[\{\[]}xms ? 'json' : 'yaml';
    }

    if ( $Format eq 'json' ) {
        return $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Data,
        );
    }

    return $Kernel::OM->Get('Kernel::System::YAML')->Load(
        Data => $Data,
    );
}

sub Serialize {
    my ( $Self, %Param ) = @_;

    my $Format = lc( $Param{Format} || 'yaml' );

    if ( $Format eq 'json' ) {
        return $Kernel::OM->Get('Kernel::System::JSON')->Encode(
            Data     => $Param{Data},
            SortKeys => 1,
            Pretty   => 1,
        );
    }

    return $Kernel::OM->Get('Kernel::System::YAML')->Dump(
        Data => $Param{Data},
    );
}

sub _ClassesNormalize {
    my ( $Self, %Param ) = @_;

    my $Classes = $Param{Classes};
    return if !defined $Classes;

    if ( ref $Classes eq 'ARRAY' ) {
        return grep { IsStringWithData($_) } @{$Classes};
    }

    return grep { IsStringWithData($_) } split /\s*,\s*/xms, $Classes;
}

sub _ValidIDResolve {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    $Value = 'valid' if !defined $Value || $Value eq '';

    return $Value if $Value =~ m{\A\d+\z}xms;

    return $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => $Value,
    );
}

1;
