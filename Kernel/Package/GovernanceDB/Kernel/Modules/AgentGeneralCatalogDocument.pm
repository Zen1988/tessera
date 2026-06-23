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

package Kernel::Modules::AgentGeneralCatalogDocument;

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

    my $ParamObject    = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $DocumentObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog::Document');

    my $Format = lc( $ParamObject->GetParam( Param => 'Format' ) || 'yaml' );
    $Format = $Format eq 'json' ? 'json' : 'yaml';

    my $Subaction = $Self->{Subaction} || '';
    my $Classes   = $ParamObject->GetParam( Param => 'Classes' ) || '';
    my $ReturnAction = $ParamObject->GetParam( Param => 'ReturnAction' ) || 'AgentGovernanceObject';
    $ReturnAction = 'AdminGeneralCatalog' if $ReturnAction eq 'AdminGeneralCatalog';
    $ReturnAction = 'AgentGovernanceObject' if $ReturnAction ne 'AdminGeneralCatalog';

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
        }
        else {
            $Message      = IsHashRefWithData($Result) ? $Result->{Message} : Translatable('Import failed.');
            $MessageClass = 'Error';
        }
    }
    elsif ( $Subaction eq 'Export' ) {
        $DocumentText = $DocumentObject->Export(
            Classes => $Classes,
            Format  => $Format,
            UserID  => $Self->{UserID},
        );
    }

    return join '',
        $LayoutObject->Header(
            Type  => 'Small',
            Title => Translatable('General Catalog as Code'),
        ),
        $LayoutObject->Output(
            TemplateFile => 'AgentGeneralCatalogDocument',
            Data         => {
                %Param,
                Classes      => $Classes,
                Format       => $Format,
                ReturnAction => $ReturnAction,
                Document     => $DocumentText,
                Message      => $Message,
                MessageClass => $MessageClass,
            },
        ),
        $LayoutObject->Footer(
            Type => 'Small',
        );
}

1;
