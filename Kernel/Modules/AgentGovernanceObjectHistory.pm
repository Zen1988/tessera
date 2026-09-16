# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::Modules::AgentGovernanceObjectHistory;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {%Param}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # get and check Governance Object ID
    my $GovernanceObjectID = $ParamObject->GetParam( Param => 'GovernanceObjectID' );

    return $LayoutObject->ErrorScreen(
        Message => Translatable('Can\'t show history, no GovernanceObjectID is given!'),
        Comment => Translatable('Please contact the administrator.'),
    ) unless $GovernanceObjectID;

    # get needed objects
    my $GovernanceObjectObject     = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # check for access rights
    my $HasAccess = $GovernanceObjectObject->Permission(
        Scope  => 'Item',
        ItemID => $GovernanceObjectID,
        UserID => $Self->{UserID},
        Type   => $ConfigObject->Get("GovernanceObject::Frontend::$Self->{Action}")->{Permission},
    );

    return $LayoutObject->ErrorScreen(
        Message => Translatable('Can\'t show history, no access rights given!'),
        Comment => Translatable('Please contact the administrator.'),
    ) unless $HasAccess;

    # Define translatable history strings.
    my %HistoryStrings = (
        'CIHistory::GovernanceObjectCreate'      => Translatable('New Governance Object (ID=%s)'),
        'CIHistory::VersionCreate'         => Translatable('New version (ID=%s)'),
        'CIHistory::DeploymentStateUpdate' => Translatable('ZTSM Status updated (new=%s, old=%s)'),
        'CIHistory::IncidentStateUpdate'   => Translatable('ZTSM Status updated (new=%s, old=%s)'),
        'CIHistory::GovernanceObjectDelete'      => Translatable('Governance Object (ID=%s) deleted'),
        'CIHistory::LinkAdd'               => Translatable('Link to %s (type=%s) added'),
        'CIHistory::LinkDelete'            => Translatable('Link to %s (type=%s) deleted'),
        'CIHistory::DefinitionUpdate'      => Translatable('Governance Object definition updated (ID=%s)'),
        'CIHistory::NameUpdate'            => Translatable('Name updated (new=%s, old=%s)'),
        'CIHistory::ValueUpdate'           => Translatable('Attribute %s updated from "%s" to "%s"'),
        'CIHistory::VersionDelete'         => Translatable('Version %s deleted'),
        'CIHistory::AttachmentAdd'         => Translatable('File "%s" uploaded'),
        'CIHistory::AttachmentDelete'      => Translatable('File "%s" removed'),
    );

    # get all information about the Governance Object
    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        GovernanceObjectID => $GovernanceObjectID,
    );
    my $GovernanceObjectName = $GovernanceObject->{Number};

    # get all entries in the history for this Governance Object
    my $Lines = $GovernanceObjectObject->HistoryGet(
        GovernanceObjectID => $GovernanceObjectID,
    );

    # get shown user info
    my @NewLines = @{$Lines};
    if ( $ConfigObject->Get('GovernanceObject::Frontend::HistoryOrder') eq 'reverse' ) {
        @NewLines = reverse @{$Lines};
    }

    my $Version = 0;
    for my $DataTmp (@NewLines) {
        my %Data = (
            %{$DataTmp},
            VersionID => $Version,
        );

        # trim the comment to only show version number
        if ( $Data{HistoryType} eq 'VersionCreate' ) {
            $Data{Comment} =~ s/\D//g;
            $Data{VersionID} = $Data{Comment};
            $Version = $Data{Comment};
        }
        elsif ( $Data{HistoryType} eq 'DeploymentStateUpdate' ) {

            # get ZTSM Status list
            my $ZTSMStatusList = $GeneralCatalogObject->ItemList(
                Class => 'ZTSM::GovernanceObject::Status',
            );

            # show names, first split the reassemble
            $Data{Comment} =
                join '%%',
                map { $ZTSMStatusList->{$_} || '' }
                split m/%%/, $Data{Comment};
        }
        elsif ( $Data{HistoryType} eq 'IncidentStateUpdate' ) {

            # get ZTSM Status list
            my $ZTSMStatusList = $GeneralCatalogObject->ItemList(
                Class => 'ZTSM::GovernanceObject::Status',
            );

            # show names, first split the reassemble
            $Data{Comment} =
                join '%%',
                map { $ZTSMStatusList->{$_} || '' }
                split m/%%/, $Data{Comment};
        }

        # replace text
        if ( $Data{Comment} ) {
            $Data{Comment} =~ s{ \A %% }{}xmsg;
            my @Values = split /%%/, $Data{Comment};

            $Data{Comment} = $LayoutObject->{LanguageObject}->Translate(
                $HistoryStrings{ 'CIHistory::' . $Data{HistoryType} },
                @Values,
            );

            # remove not needed place holder
            $Data{Comment} =~ s/\%s//g;
        }

        $LayoutObject->Block(
            Name => 'Row',
            Data => {%Data},
        );
    }

    # build page
    return join '',
        $LayoutObject->Header(
            Value => $GovernanceObjectName,
            Type  => 'Small'
        ),
        $LayoutObject->Output(
            TemplateFile => 'AgentGovernanceObjectHistory',
            Data         => {
                Name         => $GovernanceObjectName,
                GovernanceObjectID => $GovernanceObjectID,
                VersionID    => $ParamObject->GetParam( Param => 'VersionID' ),
            },
        ),
        $LayoutObject->Footer( Type => 'Small' );
}

1;
