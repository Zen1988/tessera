# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Modules::AgentGovernanceObjectAdd;

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

    my $Subaction = $Self->{Subaction} || '';

    my %GetParam;
    for my $Name (qw(Class ZTSMCode ZTSMStatus Name Description Definition)) {
        $GetParam{$Name} = $ParamObject->GetParam( Param => $Name ) || '';
    }
    $GetParam{ZTSMStatus} ||= 'Draft';

    if ( $Subaction eq 'Create' ) {
        my @Errors;
        for my $Needed (qw(ZTSMCode Name)) {
            push @Errors, $Needed if !$GetParam{$Needed};
        }

        if (!@Errors) {
            my $ObjectID = $GovernanceDBObject->ObjectAdd(
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($ObjectID) {
                return $LayoutObject->Redirect(
                    OP => "Action=AgentGovernanceObjectZoom;ObjectID=$ObjectID",
                );
            }

            $GetParam{ErrorMessage} = 'Could not create governance object.';
        }
        else {
            $GetParam{ErrorMessage} = 'Missing required fields: ' . join ', ', @Errors;
        }
    }

    my $Classes = $GovernanceDBObject->ClassList( Valid => 1 ) || {};
    for my $ClassID ( sort { $Classes->{$a} cmp $Classes->{$b} } keys %{$Classes} ) {
        my $Class = $Classes->{$ClassID};
        $LayoutObject->Block(
            Name => 'ClassOption',
            Data => {
                Key      => $Class,
                Value    => $Class,
                Selected => $GetParam{Class} eq $Class ? ' selected="selected"' : '',
            },
        );
    }

    my $Statuses = $GovernanceDBObject->StatusList( Valid => 1 ) || {};
    for my $StatusID ( sort { $Statuses->{$a} cmp $Statuses->{$b} } keys %{$Statuses} ) {
        my $Status = $Statuses->{$StatusID};
        $LayoutObject->Block(
            Name => 'StatusOption',
            Data => {
                Key      => $Status,
                Value    => $Status,
                Selected => $GetParam{ZTSMStatus} eq $Status ? ' selected="selected"' : '',
            },
        );
    }

    return join '',
        $LayoutObject->Header( Title => 'Add Governance Object' ),
        $LayoutObject->NavigationBar(),
        $LayoutObject->Output(
            TemplateFile => 'AgentGovernanceObjectAdd',
            Data         => \%GetParam,
        ),
        $LayoutObject->Footer();
}

1;
