# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::Modules::AdminMELTObjectDefinition;

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
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');

    my $Scope = $ParamObject->GetParam( Param => 'Scope' ) || 'Class';
    $Scope = $Scope eq 'Role' ? 'Role' : 'Class';

    my $TargetList = $Scope eq 'Role'
        ? ( $MELTObject->RoleList( Valid => 1 ) || {} )
        : ( $MELTObject->ClassList( Valid => 1 ) || {} );

    my $TargetIDParam = $Scope . 'ID';
    my $TargetID = $ParamObject->GetParam( Param => $TargetIDParam )
        || ( sort keys %{$TargetList} )[0];

    if ( $Self->{Subaction} && $Self->{Subaction} eq 'DefinitionSave' ) {
        my $Definition = $ParamObject->GetParam( Param => 'Definition' ) || '';

        if ( !$TargetID || !$Definition ) {
            return $LayoutObject->ErrorScreen(
                Message => $LayoutObject->{LanguageObject}->Translate('Need target and definition.'),
            );
        }

        my $DefinitionID = $MELTObject->DefinitionAdd(
            ( $Scope eq 'Role' ? ( RoleID => $TargetID ) : ( ClassID => $TargetID ) ),
            Definition => $Definition,
            UserID     => $Self->{UserID},
        );

        return $LayoutObject->ErrorScreen(
            Message => $LayoutObject->{LanguageObject}->Translate('Could not save MELT Object definition.'),
        ) if !$DefinitionID;

        return $LayoutObject->Redirect(
            OP => "Action=$Self->{Action};Scope=$Scope;$TargetIDParam=$TargetID",
        );
    }

    my $Definition = $MELTObject->DefinitionGet(
        $Scope eq 'Role' ? ( RoleID => $TargetID ) : ( ClassID => $TargetID )
        )
        || {
        ( $Scope eq 'Role'
            ? ( RoleID => $TargetID, Role => $TargetList->{$TargetID} || '' )
            : ( ClassID => $TargetID, Class => $TargetList->{$TargetID} || '' ) ),
        Definition => "---\nFields: []\n",
        Version    => 0,
        };

    my $DefinitionList = $MELTObject->DefinitionList(
        $Scope eq 'Role' ? ( RoleID => $TargetID ) : ( ClassID => $TargetID )
    ) || [];

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
        Data        => {
            Class => 'Class',
            Role  => 'Role',
        },
        Name        => 'Scope',
        SelectedID  => $Scope,
        Translation => 0,
        Class       => 'Modernize',
    );

    my $TargetOptionStrg = $LayoutObject->BuildSelection(
        Data        => $TargetList,
        Name        => $TargetIDParam,
        SelectedID  => $TargetID,
        Translation => 0,
        Class       => 'Modernize',
    );

    my $EditorConfig = $Kernel::OM->Get('Kernel::Config')->Get('MELT::Frontend::AdminMELTObjectDefinition') || {};
    my $EditorRows   = $EditorConfig->{EditorRows} || 30;

    return join '',
        $LayoutObject->Header,
        $LayoutObject->NavigationBar,
        $LayoutObject->Output(
            TemplateFile => 'AdminMELTObjectDefinition',
            Data         => {
                %Param,
                Scope           => $Scope,
                ScopeOptionStrg => $ClassOptionStrg,
                TargetID        => $TargetID,
                TargetIDParam   => $TargetIDParam,
                Target          => $TargetList->{$TargetID} || '',
                ClassOptionStrg => $ClassOptionStrg,
                TargetOptionStrg => $TargetOptionStrg,
                Definition      => $Definition->{Definition},
                Version         => $Definition->{Version},
                Rows            => $EditorRows,
            },
        ),
        $LayoutObject->Footer;
}

1;

