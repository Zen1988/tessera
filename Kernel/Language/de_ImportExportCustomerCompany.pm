# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2012-2023 Znuny GmbH, http://znuny.com/
# Copyright (C) 2022-2024 Rother OSS GmbH, https://otobo.de/
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

package Kernel::Language::de_ImportExportCustomerCompany;

use strict;
use warnings;
use utf8;

# --
sub Data {
    my $Self = shift;
    my $Lang = $Self->{Translation};
    return if ref $Lang ne 'HASH';

    # possible charsets
    $Self->{Charset} = [ 'utf-8', ];

    # $$START$$

    # translations missing in ImportExport...
    $Lang->{'CustomerCompany'}            = 'Kunden-Firma';
    $Lang->{'Column Seperator'}           = 'Spaltentrenner';
    $Lang->{'Charset'}                    = 'Zeichensatz';
    $Lang->{'Restrict export per search'} = 'Export mittels Suche einschränken';
    $Lang->{'Object backend module registration for the import/export module.'}
        = 'Objekt-Backend Modul Registration des Import/Export Moduls.';
    $Lang->{
        'Defines which customer ID to use if no company defined - only relevant for new customer users.'
        }
        = 'Definiert welche Kunden-ID genutzt wird, falls nicht in Mapping definiert - nur fuer neue Kundennutzereintraege relevant.';

    return 0;

    # $$STOP$$
}

# --
1;
