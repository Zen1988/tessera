# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::System::DynamicField::Driver::GovernanceObject;

use strict;
use warnings;

use parent qw(Kernel::System::DynamicField::Driver::BaseReference);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::GovernanceDB',
    'Kernel::System::Log',
);

sub new {
    my ($Type) = @_;

    my $Self = bless {}, $Type;

    $Self->{ValueType}      = 'Integer';
    $Self->{ValueKey}       = 'ValueInt';
    $Self->{TableAttribute} = 'value_int';
    $Self->{FieldCSSClass}  = 'DynamicFieldReference';

    $Self->{Behaviors} = {
        IsACLReducible               => 0,
        IsNotificationEventCondition => 0,
        IsSortable                   => 1,
        IsFiltrable                  => 1,
        IsStatsCondition             => 0,
        IsCustomerInterfaceCapable   => 1,
        IsHiddenInTicketInformation  => 0,
        IsReferenceField             => 1,
        IsSetCapable                 => 1,
        SetsDynamicContent           => 1,
    };

    $Self->{ReferencedObjectType} = 'GovernanceObject';

    return $Self;
}

sub ObjectDescriptionGet {
    my ( $Self, %Param ) = @_;

    return if !$Param{ObjectID};

    my $Object = $Kernel::OM->Get('Kernel::System::GovernanceDB')->ObjectGet(
        ObjectID => $Param{ObjectID},
    );

    if ( !$Object ) {
        return (
            Normal => "$Param{ObjectID} (deleted)",
            Long   => "$Param{ObjectID} (deleted)",
        );
    }

    my $Normal = $Object->{GOID} || $Object->{ZTSMCode} || $Object->{ObjectID};
    my $Long   = join ' - ', grep {$_} $Object->{GOID}, $Object->{ZTSMCode}, $Object->{Name};

    my $Link;
    if ( $Param{Link} && $Param{LayoutObject} && $Param{LayoutObject}{SessionSource} eq 'AgentInterface' ) {
        $Link = $Param{LayoutObject}{Baselink} . "Action=AgentGovernanceObjectZoom;ObjectID=$Object->{ObjectID}";
    }

    return (
        Normal => $Normal,
        Long   => $Long || $Normal,
        Link   => $Link,
    );
}

sub SearchObjects {
    my ( $Self, %Param ) = @_;

    if ( $Param{ObjectID} ) {
        my $Object = $Kernel::OM->Get('Kernel::System::GovernanceDB')->ObjectGet(
            ObjectID => $Param{ObjectID},
        );
        return $Object ? ( $Object->{ObjectID} ) : ();
    }

    my $Term    = $Param{Term} // '';
    my $Max     = $Param{MaxResults} || 20;
    my $Objects = $Kernel::OM->Get('Kernel::System::GovernanceDB')->ObjectList() || [];

    my @ObjectIDs;
    OBJECT:
    for my $Object ( @{$Objects} ) {
        my $Haystack = join "\n", grep { defined } @{$Object}{qw(ObjectID GOID ZTSMCode ZTSMStatus Name Description)};
        next OBJECT if $Term && index( lc $Haystack, lc $Term ) == -1;

        push @ObjectIDs, $Object->{ObjectID};
        last OBJECT if @ObjectIDs >= $Max;
    }

    return @ObjectIDs;
}

1;
