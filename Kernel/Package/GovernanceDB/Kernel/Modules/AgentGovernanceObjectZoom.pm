# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Modules::AgentGovernanceObjectZoom;

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
    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $GovernanceDBObject = $Kernel::OM->Get('Kernel::System::GovernanceDB');

    my $ObjectID = $ParamObject->GetParam( Param => 'ObjectID' );
    my $Object   = $GovernanceDBObject->ObjectGet( ObjectID => $ObjectID );

    if ( !$Object ) {
        return join '',
            $LayoutObject->Header( Title => 'Governance Object' ),
            $LayoutObject->NavigationBar(),
            $LayoutObject->Notify( Priority => 'Error', Info => 'Governance object not found.' ),
            $LayoutObject->Footer();
    }

    return join '',
        $LayoutObject->Header( Title => $Object->{Name} || 'Governance Object' ),
        $LayoutObject->NavigationBar(),
        $LayoutObject->Output(
            TemplateFile => 'AgentGovernanceObjectZoom',
            Data         => $Object,
        ),
        $LayoutObject->Footer();
}

1;
