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

package Kernel::Modules::AgentMELTObjectDocument;

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
    my $MELTObjectObject   = $Kernel::OM->Get('Kernel::System::MELTObject');
    my $DocumentObject           = $Kernel::OM->Get('Kernel::System::MELTObject::Document');

    my $MELTObjectID = $ParamObject->GetParam( Param => 'MELTObjectID' ) || 0;
    my $VersionID          = $ParamObject->GetParam( Param => 'VersionID' ) || 0;
    my $Format             = lc( $ParamObject->GetParam( Param => 'Format' ) || 'yaml' );
    $Format = $Format eq 'json' ? 'json' : 'yaml';

    my $Subaction = $Self->{Subaction} || '';

    my $MELTObject = $MELTObjectID ? $MELTObjectObject->MELTObjectGet(
        MELTObjectID => $MELTObjectID,
        VersionID          => $VersionID,
        DynamicFields      => 0,
    ) : undef;

    if ( $MELTObjectID && !IsHashRefWithData($MELTObject) ) {
        return $LayoutObject->ErrorScreen(
            Message => Translatable('No MELT Object found!'),
            Comment => Translatable('Please contact the administrator.'),
        );
    }

    if ($MELTObjectID) {
        my $Permission = $Subaction eq 'Import' ? 'rw' : 'ro';
        my $Access     = $MELTObjectObject->Permission(
            Scope  => 'Item',
            ItemID => $MELTObjectID,
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
            $MELTObjectID = $Result->{MELTObjectID};
            $MELTObject   = $MELTObjectObject->MELTObjectGet(
                MELTObjectID => $MELTObjectID,
                DynamicFields      => 0,
            );
            $DocumentText = $DocumentObject->Export(
                MELTObjectID => $MELTObjectID,
                Format             => $Format,
                UserID             => $Self->{UserID},
            );
        }
        else {
            $Message      = IsHashRefWithData($Result) ? $Result->{Message} : Translatable('Import failed.');
            $MessageClass = 'Error';
        }
    }
    elsif ($MELTObjectID) {
        $DocumentText = $DocumentObject->Export(
            MELTObjectID => $MELTObjectID,
            VersionID          => $VersionID,
            Format             => $Format,
            UserID             => $Self->{UserID},
        );
    }

    $MELTObject ||= {};

    return join '',
        $LayoutObject->Header(
            Type  => 'Small',
            Title => Translatable('Governance as Code'),
        ),
        $LayoutObject->Output(
            TemplateFile => 'AgentMELTObjectDocument',
            Data         => {
                %Param,
                MELTObjectID => $MELTObjectID,
                VersionID          => $VersionID,
                Number             => $MELTObject->{Number} || '',
                Name               => $MELTObject->{Name} || '',
                Format             => $Format,
                Document           => $DocumentText,
                Message            => $Message,
                MessageClass       => $MessageClass,
                ImportEnabled      => $ConfigObject->Get('Frontend::Module')->{AgentMELTObjectDocument}->{Group} ? 1 : 1,
            },
        ),
        $LayoutObject->Footer(
            Type => 'Small',
        );
}

1;

