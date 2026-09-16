# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Modules::AgentMELTObjectTransform;

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
    my $MELTObject = $Kernel::OM->Get('Kernel::System::MELT');

    my %GetParam;
    for my $Name (qw(ConfigItemID Class MELTID ZTSMCode ZTSMStatus Name Description)) {
        $GetParam{$Name} = $ParamObject->GetParam( Param => $Name ) || '';
    }

    if ( ( $Self->{Subaction} || '' ) eq 'Copy' ) {
        if ( !$GetParam{ConfigItemID} ) {
            $GetParam{ErrorMessage} = 'Missing required field: ConfigItemID';
        }
        else {
            my $ObjectID = $MELTObject->ObjectCopyFromConfigItem(
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($ObjectID) {
                return $LayoutObject->Redirect(
                    OP => "Action=AgentMELTObjectZoom;ObjectID=$ObjectID",
                );
            }

            $GetParam{ErrorMessage} = 'Could not copy ConfigItem into MELT.';
        }
    }

    return join '',
        $LayoutObject->Header( Title => 'Transform ConfigItem' ),
        $LayoutObject->NavigationBar(),
        $LayoutObject->Output(
            TemplateFile => 'AgentMELTObjectTransform',
            Data         => \%GetParam,
        ),
        $LayoutObject->Footer();
}

1;

