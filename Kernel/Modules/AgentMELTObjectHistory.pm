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

package Kernel::Modules::AgentMELTObjectHistory;

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

    # get and check MELT Object ID
    my $MELTObjectID = $ParamObject->GetParam( Param => 'MELTObjectID' );

    return $LayoutObject->ErrorScreen(
        Message => Translatable('Can\'t show history, no MELTObjectID is given!'),
        Comment => Translatable('Please contact the administrator.'),
    ) unless $MELTObjectID;

    # get needed objects
    my $MELTObjectObject     = $Kernel::OM->Get('Kernel::System::MELTObject');
    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # check for access rights
    my $HasAccess = $MELTObjectObject->Permission(
        Scope  => 'Item',
        ItemID => $MELTObjectID,
        UserID => $Self->{UserID},
        Type   => $ConfigObject->Get("MELTObject::Frontend::$Self->{Action}")->{Permission},
    );

    return $LayoutObject->ErrorScreen(
        Message => Translatable('Can\'t show history, no access rights given!'),
        Comment => Translatable('Please contact the administrator.'),
    ) unless $HasAccess;

    # Define translatable history strings.
    my %HistoryStrings = (
        'CIHistory::MELTObjectCreate'      => Translatable('New MELT Object (ID=%s)'),
        'CIHistory::VersionCreate'         => Translatable('New version (ID=%s)'),
        'CIHistory::DeploymentStateUpdate' => Translatable('ZTSM Status updated (new=%s, old=%s)'),
        'CIHistory::IncidentStateUpdate'   => Translatable('ZTSM Status updated (new=%s, old=%s)'),
        'CIHistory::MELTObjectDelete'      => Translatable('MELT Object (ID=%s) deleted'),
        'CIHistory::LinkAdd'               => Translatable('Link to %s (type=%s) added'),
        'CIHistory::LinkDelete'            => Translatable('Link to %s (type=%s) deleted'),
        'CIHistory::DefinitionUpdate'      => Translatable('MELT Object definition updated (ID=%s)'),
        'CIHistory::NameUpdate'            => Translatable('Name updated (new=%s, old=%s)'),
        'CIHistory::ValueUpdate'           => Translatable('Attribute %s updated from "%s" to "%s"'),
        'CIHistory::VersionDelete'         => Translatable('Version %s deleted'),
        'CIHistory::AttachmentAdd'         => Translatable('File "%s" uploaded'),
        'CIHistory::AttachmentDelete'      => Translatable('File "%s" removed'),
    );

    # get all information about the MELT Object
    my $MELTObject = $MELTObjectObject->MELTObjectGet(
        MELTObjectID => $MELTObjectID,
    );
    my $MELTObjectName = $MELTObject->{Number};

    # get all entries in the history for this MELT Object
    my $Lines = $MELTObjectObject->HistoryGet(
        MELTObjectID => $MELTObjectID,
    );

    # get shown user info
    my @NewLines = @{$Lines};
    if ( $ConfigObject->Get('MELTObject::Frontend::HistoryOrder') eq 'reverse' ) {
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
                Class => 'ZTSM::MELT::Status',
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
                Class => 'ZTSM::MELT::Status',
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
            Value => $MELTObjectName,
            Type  => 'Small'
        ),
        $LayoutObject->Output(
            TemplateFile => 'AgentMELTObjectHistory',
            Data         => {
                Name         => $MELTObjectName,
                MELTObjectID => $MELTObjectID,
                VersionID    => $ParamObject->GetParam( Param => 'VersionID' ),
            },
        ),
        $LayoutObject->Footer( Type => 'Small' );
}

1;

