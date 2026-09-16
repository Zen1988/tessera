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

package Kernel::Output::HTML::FilterElementPost::FAQCustomerRelatedArticles;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::FAQ',
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

    my $TemplateName = $Param{TemplateFile} || '';

    return 1 if !$TemplateName;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    return 1 if !$ConfigObject->Get('FAQ::Customer::RelatedArticles::Enabled');

    my $OutputFilterPostConfigs = $ConfigObject->Get('Frontend::Output::FilterElementPost');

    return if !$OutputFilterPostConfigs;
    return if ref $OutputFilterPostConfigs ne 'HASH';

    # Extract the output filter config.
    my $OutputFilterConfig = $OutputFilterPostConfigs->{OutputFilterPostFAQCustomerRelatedArticles};

    return if !$OutputFilterConfig;
    return if ref $OutputFilterConfig ne 'HASH';

    my $ValidTemplates = $OutputFilterConfig->{Templates};

    return if !$ValidTemplates;
    return if ref $ValidTemplates ne 'HASH';

    # Apply only if template is valid in config.
    return 1 if !$ValidTemplates->{$TemplateName};

    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');

    my %FAQSearchParameter;

    # Set interface setting to 'external', to search only for approved faq article.
    $FAQSearchParameter{Interface} = $FAQObject->StateTypeGet(
        Name   => 'external',
        UserID => 1,
    );

    $FAQSearchParameter{States} = $FAQObject->StateTypeList(
        Types  => $ConfigObject->Get('FAQ::Customer::StateTypes'),
        UserID => 1,
    );

    # Test if customer/public FAQ article exists, because we don't show the widget
    #   if no relevant article exists.
    my @FAQArticleIDs = $FAQObject->FAQSearch(
        %FAQSearchParameter,
        Limit  => 1,
        UserID => 1,
    );

    return 1 if !@FAQArticleIDs;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Render the empty related FAQ article list and add the initial wdiget html code to the page.
    my $CustomerRelatedFAQArticlesHTMLString = $LayoutObject->Output(
        TemplateFile => 'CustomerFAQRelatedArticles',
        Data         => {},
    );

    my $Search = '(<textarea id="RichText")';
    ${ $Param{Data} }
        =~ s{$Search}{<div id="FAQRelatedArticles" class="Hidden">$CustomerRelatedFAQArticlesHTMLString</div>$1}msg;

    my $FrontendCustomerTicketMessageConfig      = $ConfigObject->Get("Ticket::Frontend::CustomerTicketMessage");
    my $FrontendCustomerFAQRelatedArticlesConfig = $ConfigObject->Get("FAQ::Frontend::CustomerFAQRelatedArticles");

    my $QueuesEnabled     = $FrontendCustomerFAQRelatedArticlesConfig->{'QueuesEnabled'} || '';
    my $QueuesEnabledStrg = '';
    if ( IsArrayRefWithData($QueuesEnabled) ) {

        # Don't show the functionality, if the queue selection is disabled
        #   and the default queue is not in the enabled queues.
        if ( !$FrontendCustomerTicketMessageConfig->{Queue} ) {
            my %LookupQuquesEnabled = map { $_ => 1 } @{$QueuesEnabled};

            return
                if !$FrontendCustomerTicketMessageConfig->{QueueDefault}
                || !$LookupQuquesEnabled{ $FrontendCustomerTicketMessageConfig->{QueueDefault} };
        }
        else {
            $QueuesEnabledStrg = join( "','", @{$QueuesEnabled} );
            $QueuesEnabledStrg = "'$QueuesEnabledStrg'";
        }
    }

    # Add a hidden input containing the enabled queues.
    my $SearchStrg = '(\s+<input type="hidden" name="Action")';
    my $Replace    = <<"END";
\n<input type="hidden" name="QueuesEnabled" id="QueuesEnabled" value="[$QueuesEnabledStrg]" />
END

    # For process management we need to add the hidden input before the closure of the field set.
    if ( $TemplateName =~ m{ProcessManagement/(?: Customer)? ActivityDialogFooter}msx ) {
        $SearchStrg = '(\s+</fieldset>)';
    }

    # Update the source.
    ${ $Param{Data} } =~ s{$SearchStrg}{$Replace $1};
    return 1;
}

1;
