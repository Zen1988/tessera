# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::System::DynamicField::Driver::GovernanceObjectVersion;

use strict;
use warnings;

use parent qw(Kernel::System::DynamicField::Driver::GovernanceObject);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::GovernanceDB',
    'Kernel::System::Log',
);

sub new {
    my ($Type) = @_;

    my $Self = $Type->SUPER::new();
    $Self->{ReferencedObjectType} = 'GovernanceObjectVersion';

    return $Self;
}

sub ObjectDescriptionGet {
    my ( $Self, %Param ) = @_;

    return if !$Param{ObjectID};

    my $Version = $Self->_VersionGet( VersionID => $Param{ObjectID} );
    if ( !$Version ) {
        return (
            Normal => "$Param{ObjectID} (deleted)",
            Long   => "$Param{ObjectID} (deleted)",
        );
    }

    my $Normal = "$Version->{GOID} v$Version->{VersionString}";
    my $Long   = join ' - ', grep {$_} $Normal, $Version->{ZTSMCode}, $Version->{Name};

    my $Link;
    if ( $Param{Link} && $Param{LayoutObject} && $Param{LayoutObject}{SessionSource} eq 'AgentInterface' ) {
        $Link = $Param{LayoutObject}{Baselink} . "Action=AgentGovernanceObjectZoom;ObjectID=$Version->{ObjectID}";
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
        my $Version = $Self->_VersionGet( VersionID => $Param{ObjectID} );
        return $Version ? ( $Version->{VersionID} ) : ();
    }

    my $Term    = $Param{Term} // '';
    my $Max     = $Param{MaxResults} || 20;
    my $Objects = $Kernel::OM->Get('Kernel::System::GovernanceDB')->ObjectList() || [];

    my @VersionIDs;
    OBJECT:
    for my $Object ( @{$Objects} ) {
        my $Haystack = join "\n", grep { defined } @{$Object}{qw(ObjectID GOID ZTSMCode ZTSMStatus Name Description)};
        next OBJECT if $Term && index( lc $Haystack, lc $Term ) == -1;
        next OBJECT if !$Object->{LastVersionID};

        push @VersionIDs, $Object->{LastVersionID};
        last OBJECT if @VersionIDs >= $Max;
    }

    return @VersionIDs;
}

sub _VersionGet {
    my ( $Self, %Param ) = @_;

    return if !$Param{VersionID};

    my @Row = $Kernel::OM->Get('Kernel::System::DB')->SelectRowArray(
        SQL => '
            SELECT gov.id, gov.governance_object_id, gov.name, gov.description, gov.version_string,
                go.goid, go.ztsm_code, go.ztsm_status
            FROM governance_object_version gov
            INNER JOIN governance_object go
                ON gov.governance_object_id = go.id
            WHERE gov.id = ?',
        Bind  => [ \$Param{VersionID} ],
        Limit => 1,
    );

    return if !@Row;

    return {
        VersionID     => $Row[0],
        ObjectID      => $Row[1],
        Name          => $Row[2],
        Description   => $Row[3],
        VersionString => $Row[4],
        GOID          => $Row[5],
        ZTSMCode      => $Row[6],
        ZTSMStatus    => $Row[7],
    };
}

1;
