# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2019-2026 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::Modules::AgentGovernanceObjectDocument;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    return bless {%Param}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject              = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject             = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject             = $Kernel::OM->Get('Kernel::Config');
    my $GovernanceObjectObject   = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $DocumentObject           = $Kernel::OM->Get('Kernel::System::GovernanceObject::Document');

    my $GovernanceObjectID = $ParamObject->GetParam( Param => 'GovernanceObjectID' ) || 0;
    my $VersionID          = $ParamObject->GetParam( Param => 'VersionID' ) || 0;
    my $Format             = lc( $ParamObject->GetParam( Param => 'Format' ) || 'yaml' );
    $Format = $Format eq 'json' ? 'json' : 'yaml';

    my $Subaction = $Self->{Subaction} || '';

    my $GovernanceObject = $GovernanceObjectID ? $GovernanceObjectObject->GovernanceObjectGet(
        GovernanceObjectID => $GovernanceObjectID,
        VersionID          => $VersionID,
        DynamicFields      => 0,
    ) : undef;

    if ( $GovernanceObjectID && !IsHashRefWithData($GovernanceObject) ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No Governance Object found!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    if ($GovernanceObjectID) {
        my $Permission = $Subaction eq 'Import' ? 'rw' : 'ro';
        my $Access     = $GovernanceObjectObject->Permission(
            Scope  => 'Item',
            ItemID => $GovernanceObjectID,
            UserID => $Self->{UserID},
            Type   => $Permission,
        );

        if ( !$Access ) {
            return $LayoutObject->ErrorScreen(
                Message => Translatable('No access is given!'),
                Comment => Translatable('Please contact the administrator.'),
            );
        }
    }

    my $DocumentText = '';
    my $Message      = '';
    my $MessageClass = '';

    if ( $Subaction eq 'Import' ) {
        $DocumentText = $ParamObject->GetParam( Param => 'Document' ) || '';

        my $Result = $DocumentObject->Import(
            Content => $DocumentText,
            Format  => $Format,
            UserID  => $Self->{UserID},
        );

        if ( IsHashRefWithData($Result) && $Result->{Success} ) {
            $Message      = $Result->{Message};
            $MessageClass = 'Success';
            $GovernanceObjectID = $Result->{GovernanceObjectID};
            $GovernanceObject   = $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $GovernanceObjectID,
                DynamicFields      => 0,
            );
            $DocumentText = $DocumentObject->Export(
                GovernanceObjectID => $GovernanceObjectID,
                Format             => $Format,
                UserID             => $Self->{UserID},
            );
        }
        else {
            $Message      = IsHashRefWithData($Result) ? $Result->{Message} : Translatable('Import failed.');
            $MessageClass = 'Error';
        }
    }
    elsif ($GovernanceObjectID) {
        $DocumentText = $DocumentObject->Export(
            GovernanceObjectID => $GovernanceObjectID,
            VersionID          => $VersionID,
            Format             => $Format,
            UserID             => $Self->{UserID},
        );
    }

    $GovernanceObject ||= {};

    return join '',
        $LayoutObject->Header(
            Type  => 'Small',
            Title => Translatable('Governance as Code'),
        ),
        $LayoutObject->Output(
            TemplateFile => 'AgentGovernanceObjectDocument',
            Data         => {
                %Param,
                GovernanceObjectID => $GovernanceObjectID,
                VersionID          => $VersionID,
                Number             => $GovernanceObject->{Number} || '',
                Name               => $GovernanceObject->{Name} || '',
                Format             => $Format,
                Document           => $DocumentText,
                Message            => $Message,
                MessageClass       => $MessageClass,
                ImportEnabled      => $ConfigObject->Get('Frontend::Module')->{AgentGovernanceObjectDocument}->{Group} ? 1 : 1,
            },
        ),
        $LayoutObject->Footer(
            Type => 'Small',
        );
}

1;
