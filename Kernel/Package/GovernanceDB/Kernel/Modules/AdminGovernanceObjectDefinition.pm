# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Modules::AdminGovernanceObjectDefinition;

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
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');

    my $ClassList = $GovernanceDBObject->ClassList( Valid => 1 ) || {};

    my $ClassID = $ParamObject->GetParam( Param => 'ClassID' )
        || ( sort keys %{$ClassList} )[0];

    if ( $Self->{Subaction} && $Self->{Subaction} eq 'DefinitionSave' ) {
        my $Definition = $ParamObject->GetParam( Param => 'Definition' ) || '';

        if ( !$ClassID || !$Definition ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate('Need class and definition.'),
            );
        }

        my $DefinitionID = $GovernanceDBObject->DefinitionAdd(
            ClassID    => $ClassID,
            Definition => $Definition,
            UserID     => $Self->{UserID},
        );

        return $LayoutObject->ErrorScreen(
            Message => $LayoutObject->{LanguageObject}->Translate('Could not save GovernanceObject definition.'),
        ) if !$DefinitionID;

        return $LayoutObject->Redirect(
            OP => "Action=$Self->{Action};ClassID=$ClassID",
        );
    }

    my $Definition = $GovernanceDBObject->DefinitionGet( ClassID => $ClassID )
        || {
        ClassID    => $ClassID,
        Class      => $ClassList->{$ClassID} || '',
        Definition => "---\nFields: []\n",
        Version    => 0,
        };

    my $DefinitionList = $GovernanceDBObject->DefinitionList( ClassID => $ClassID ) || [];

    for my $DefinitionRow ( reverse @{$DefinitionList} ) {
        my $FullName = $UserObject->UserName(
            UserID => $DefinitionRow->{CreateBy},
        );

        $LayoutObject->Block(
            Name => 'DefinitionRow',
            Data => {
                %{$DefinitionRow},
                CreateByUser => $FullName,
            },
        );
    }

    my $ClassOptionStrg = $LayoutObject->BuildSelection(
        Data        => $ClassList,
        Name        => 'ClassID',
        SelectedID  => $ClassID,
        Translation => 0,
        Class       => 'Modernize',
    );

    my $EditorConfig = $Kernel::OM->Get('Kernel::Config')->Get('GovernanceDB::Frontend::AdminGovernanceObjectDefinition') || {};
    my $EditorRows   = $EditorConfig->{EditorRows} || 30;

    return join '',
        $LayoutObject->Header,
        $LayoutObject->NavigationBar,
        $LayoutObject->Output(
            TemplateFile => 'AdminGovernanceObjectDefinition',
            Data         => {
                %Param,
                ClassID         => $ClassID,
                Class           => $ClassList->{$ClassID} || '',
                ClassOptionStrg => $ClassOptionStrg,
                Definition      => $Definition->{Definition},
                Version         => $Definition->{Version},
                Rows            => $EditorRows,
            },
        ),
        $LayoutObject->Footer;
}

1;
