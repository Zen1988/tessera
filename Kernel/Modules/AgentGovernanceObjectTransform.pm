# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Modules::AgentGovernanceObjectTransform;

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

    my %GetParam;
    for my $Name (qw(ConfigItemID Class GOID ZTSMCode ZTSMStatus Name Description)) {
        $GetParam{$Name} = $ParamObject->GetParam( Param => $Name ) || '';
    }

    if ( ( $Self->{Subaction} || '' ) eq 'Copy' ) {
        if ( !$GetParam{ConfigItemID} ) {
            $GetParam{ErrorMessage} = 'Missing required field: ConfigItemID';
        }
        else {
            my $ObjectID = $GovernanceDBObject->ObjectCopyFromConfigItem(
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($ObjectID) {
                return $LayoutObject->Redirect(
                    OP => "Action=AgentGovernanceObjectZoom;ObjectID=$ObjectID",
                );
            }

            $GetParam{ErrorMessage} = 'Could not copy ConfigItem into GovernanceDB.';
        }
    }

    return join '',
        $LayoutObject->Header( Title => 'Transform ConfigItem' ),
        $LayoutObject->NavigationBar(),
        $LayoutObject->Output(
            TemplateFile => 'AgentGovernanceObjectTransform',
            Data         => \%GetParam,
        ),
        $LayoutObject->Footer();
}

1;
