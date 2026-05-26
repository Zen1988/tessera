# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
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

## no critic (Modules::RequireExplicitPackage)

use Kernel::System::StandardTemplate ();    ## no perlimports

package Kernel::System::StandardTemplate;   ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;
use warnings;
use v5.24;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData);

our @ObjectDependencies = (
    'Kernel::System::StandardTemplate',
    'Kernel::System::Valid',
);

sub ExportTemplates {
    my ( $Self, %Param ) = @_;

    my %TemplateFilter;
    if ( IsArrayRefWithData( $Param{Templates} ) ) {
        %TemplateFilter = map { $_ => 1 } $Param{Templates}->@*;
    }

    # get necessary objects
    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');
    my $ValidObject            = $Kernel::OM->Get('Kernel::System::Valid');

    # fetch lookup lists
    my %TemplateList = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
    );

    my %ExportData;
    TEMPLATEID:
    for my $TemplateID ( sort keys %TemplateList ) {

        my %TemplateData = $StandardTemplateObject->StandardTemplateGet(
            ID => $TemplateID,
        );

        if (%TemplateFilter) {
            next TEMPLATEID unless $TemplateFilter{ $TemplateData{Name} };
        }

        # translate IDs into names or name-like identifiers
        ATTRIBUTE:
        for my $Attribute ( keys %TemplateData ) {

            next ATTRIBUTE unless $Attribute =~ /ID/;

            if ( $Attribute eq 'ValidID' ) {
                my $Valid = $ValidObject->ValidLookup(
                    ValidID => $TemplateData{ValidID},
                );
                $TemplateData{Valid} = $Valid;
                delete $TemplateData{ValidID};
            }
        }

        # delete unneeded attributes to avoid bloating the export
        delete $TemplateData{ChangeBy};
        delete $TemplateData{ChangeTime};
        delete $TemplateData{CreateBy};
        delete $TemplateData{CreateTime};
        delete $TemplateData{ID};

        $ExportData{ $TemplateData{Name} } = \%TemplateData;
    }

    return \%ExportData;
}

sub ImportTemplates {
    my ( $Self, %Param ) = @_;

    my $UserID = $Self->{UserID} || $Param{UserID};

    # get necessary objects
    my $StandardTemplateObject = $Kernel::OM->Get('Kernel::System::StandardTemplate');
    my $ValidObject            = $Kernel::OM->Get('Kernel::System::Valid');

    # fetch lookup lists
    my %TemplateList = $StandardTemplateObject->StandardTemplateList(
        Valid => 0,
    );
    my %TemplateLookup = reverse %TemplateList;

    TEMPLATENAME:
    for my $TemplateName ( keys $Param{Templates}->%* ) {
        my $TemplateData = $Param{Templates}{$TemplateName};

        my $TemplateID = $TemplateLookup{ $TemplateData->{Name} };

        # skip if template with same name exists and overwrite is not set
        next TEMPLATENAME if ( !$Param{OverwriteExistingEntities} && $TemplateID );

        # translate named data back to IDs
        $TemplateData->{ValidID} = $ValidObject->ValidLookup(
            Valid => $TemplateData->{Valid},
        );

        # update
        if ($TemplateID) {
            my $Success = $StandardTemplateObject->StandardTemplateUpdate(
                $TemplateData->%*,
                ID     => $TemplateID,
                UserID => $UserID,
            );
            return unless $Success;
        }

        # create
        else {
            my $TemplateID = $StandardTemplateObject->StandardTemplateAdd(
                $TemplateData->%*,
                UserID => $UserID,
            );
            return unless $TemplateID;
        }
    }

    return 1;
}

1;
