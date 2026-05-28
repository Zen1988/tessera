# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.de/
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

package Kernel::Output::HTML::FilterElementPost::ITSMIncidentProblemManagement;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Web::Request',
    'Kernel::System::Group',
    'Kernel::System::Ticket',
    'Kernel::System::Service',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check data
    return if !$Param{Data};
    return if ref $Param{Data} ne 'SCALAR';
    return if !${ $Param{Data} };
    return if !$Param{TemplateFile};

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # get allowed template names
    my $ValidTemplates = $ConfigObject->Get('Frontend::Output::FilterElementPost')->{ITSMIncidentProblemManagement}->{Templates};

    # check template name
    return if !$ValidTemplates->{ $Param{TemplateFile} };

    # handling of AgentTicketZoom related ITSM changes
    if ( $Param{TemplateFile} eq 'AgentTicketZoom' ) {

        # get ticket id
        my $TicketID = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => 'TicketID' );

        # Get ticket attributes.
        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
        );

        # Move Criticality Impact Priority and other ITSM Dynamic Fields before the CustomerID field
        for my $FieldName (
            'Criticality',
            'Impact',
            'Priority',
            'Review Required',
            'Decision Result',
            'Decision Date',
            'Repair Start Time',
            'Recovery Start Time',
            'Due Date',
            )
        {

            my $TranslatedFieldLabel = $LayoutObject->{LanguageObject}->Translate($FieldName);
            my $FieldPattern         = '<label>' . $TranslatedFieldLabel . ':</label>.+?<div class="Clear"></div>';
            if ( ${ $Param{Data} } =~ m{($FieldPattern)}ms ) {

                my $Field = $1;

                # remove field from the old position
                ${ $Param{Data} } =~ s{$FieldPattern}{}ms;

                my $TranslatedCustomerIDLabel = $LayoutObject->{LanguageObject}->Translate('Customer ID');

                # add before the Customer ID field
                ${ $Param{Data} } =~ s{(<label>$TranslatedCustomerIDLabel:</label>)}{$Field\n$1}ms;
            }
        }

        return 1;
    }

    # Define Priority field name for all AgentTicketActionCommon based templates.
    my $PriorityFieldName = 'NewPriorityID';

    if ( $Param{TemplateFile} eq 'AgentTicketPhone' || $Param{TemplateFile} eq 'AgentTicketEmail' ) {

        # Use another field name (will be used later)
        $PriorityFieldName = 'PriorityID';
    }

    # For all AgentTicketActionCommon based templates
    else {

        # get Ticket Number
        my $TicketNumber;
        if ( ${ $Param{Data} } =~ m{<input type="hidden" name="TicketID" value="([^<>]+)"/>}ms ) {
            my $TicketID = $1;
            $TicketNumber = $TicketObject->TicketNumberLookup(
                TicketID => $TicketID,
            );
        }

        # add headline for AgentTicketDecision
        if ( $Param{TemplateFile} eq 'AgentTicketDecision' ) {

            # Translate the string
            my $TranslatedString = $LayoutObject->{LanguageObject}->Translate(
                'Change Decision of %s%s%s',
                $ConfigObject->Get('Ticket::Hook'),
                $ConfigObject->Get('Ticket::HookDivider'),
                $TicketNumber,
            );

            ${ $Param{Data} } =~ s{(<h1>)}{$1\n$TranslatedString}ms;
        }

        # add headline for AgentTicketAddtlITSMField
        elsif ( $Param{TemplateFile} eq 'AgentTicketAddtlITSMField' ) {

            # Translate the string
            my $TranslatedString = $LayoutObject->{LanguageObject}->Translate(
                'Change ITSM fields of %s%s%s',
                $ConfigObject->Get('Ticket::Hook'),
                $ConfigObject->Get('Ticket::HookDivider'),
                $TicketNumber,
            );

            ${ $Param{Data} } =~ s{(<h1>)}{$1\n$TranslatedString}ms;
        }
    }

    # Define criticality field search pattern, use without the x modifier and non greedy match (.+?)
    my $CriticalityFieldPattern = '<div class="Row Row_DynamicField_ITSMCriticality">.+?<div class="Clear"></div>\s*</div>';

    # Find criticality field and move before the priority field
    if ( ${ $Param{Data} } =~ m{($CriticalityFieldPattern)}ms ) {

        my $CriticalityField = $1;

        # Only if priority is visible on the screen
        if ( ${ $Param{Data} } =~ m{<label for="$PriorityFieldName">.+?</label>}ms ) {

            # remove criticality from the old position
            ${ $Param{Data} } =~ s{$CriticalityFieldPattern}{}ms;

            # add before the priority field
            ${ $Param{Data} } =~ s{(<label for="$PriorityFieldName">.+?</label>)}{$CriticalityField\n$1}ms;
        }
    }

    # Define impact field search pattern, use without the x modifier and non greedy match (.+?)
    my $ImpactFieldPattern = '<div class="Row Row_DynamicField_ITSMImpact">.+?<div class="Clear"></div>\s*</div>';

    # Find Impact field and move before the priority field
    if ( ${ $Param{Data} } =~ m{($ImpactFieldPattern)}ms ) {

        my $ImpactField = $1;

        # Only if priority is visible on the screen
        if ( ${ $Param{Data} } =~ m{<label for="$PriorityFieldName">.+?</label>}ms ) {

            # remove impact from the old position
            ${ $Param{Data} } =~ s{$ImpactFieldPattern}{}ms;

            # add before the priority field
            ${ $Param{Data} } =~ s{(<label for="$PriorityFieldName">.+?</label>)}{$ImpactField\n$1}ms;
        }
    }

    return 1;
}

1;
