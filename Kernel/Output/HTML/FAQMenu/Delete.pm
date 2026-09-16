# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Output::HTML::FAQMenu::Delete;

use strict;
use warnings;

# Prevent used only once warning
use Kernel::System::ObjectManager;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
);

sub new {
    my ( $Type, %Param ) = @_;

    # Allocate new hash for object.
    my $Self = {};
    bless( $Self, $Type );

    # Get UserID param.
    $Self->{UserID} = $Param{UserID} || die "Got no UserID!";

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # Run Kernel::Output::HTML::FAQMenu::Generic.
    my $GenericObject = Kernel::Output::HTML::FAQMenu::Generic->new( UserID => $Self->{UserID} );
    $GenericObject->Run(
        %Param,
    );

    # Create structure for JS.
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my %JSData;
    $JSData{ $Param{MenuID} } = {
        ElementID                  => $Param{MenuID},
        ElementSelector            => '#' . $Param{MenuID},
        DialogContentQueryString   => 'Action=AgentFAQDelete;ItemID=' . $Param{FAQItem}->{ItemID},
        ConfirmedActionQueryString => 'Action=AgentFAQDelete;Subaction=Delete;ItemID=' . $Param{FAQItem}->{ItemID},
        DialogTitle                => $LayoutObject->{LanguageObject}->Translate('Delete'),
    };

    # Send data to JS.
    $LayoutObject->AddJSData(
        Key   => 'FAQData',
        Value => \%JSData,
    );

    $Param{Counter}++;

    return $Param{Counter};
}

1;
