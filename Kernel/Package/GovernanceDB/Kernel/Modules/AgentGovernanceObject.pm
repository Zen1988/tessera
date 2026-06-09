# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Modules::AgentGovernanceObject;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    return bless {%Param}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GovernanceDBObject = $Kernel::OM->Get('Kernel::System::GovernanceDB');

    my $Objects = $GovernanceDBObject->ObjectList() || [];

    for my $Object ( @{$Objects} ) {
        $LayoutObject->Block(
            Name => 'ObjectRow',
            Data => $Object,
        );
    }

    return join '',
        $LayoutObject->Header( Title => 'GovernanceDB' ),
        $LayoutObject->NavigationBar(),
        $LayoutObject->Output(
            TemplateFile => 'AgentGovernanceObject',
            Data         => {
                ObjectCount => scalar @{$Objects},
            },
        ),
        $LayoutObject->Footer();
}

1;
