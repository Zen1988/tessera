# OTOBO config file (automatically generated)
# VERSION:2.0
package Kernel::Config::Files::ZZZAAuto;
use strict;
use warnings;
no warnings 'redefine'; ## no critic qw(TestingAndDebugging::ProhibitNoWarnings)
use utf8;
sub Load {
    my ($File, $Self) = @_;
$Self->{'CurrentDeploymentID'} = '81';
$Self->{'ACL::CacheTTL'} =  '3600';
$Self->{'ACLKeysLevel1Change'} =  {
  'Possible' => 'Possible',
  'PossibleAdd' => 'PossibleAdd',
  'PossibleNot' => 'PossibleNot'
};
$Self->{'ACLKeysLevel1Match'} =  {
  'Properties' => 'Properties',
  'PropertiesDatabase' => 'PropertiesDatabase'
};
$Self->{'ACLKeysLevel2::Possible'} =  {
  'Action' => 'Action',
  'ActivityDialog' => 'ActivityDialog',
  'Form' => 'Form',
  'FormStd' => 'FormStd',
  'Process' => 'Process',
  'Ticket' => 'Ticket'
};
$Self->{'ACLKeysLevel2::PossibleAdd'} =  {
  'Action' => 'Action',
  'ActivityDialog' => 'ActivityDialog',
  'Form' => 'Form',
  'FormStd' => 'FormStd',
  'Process' => 'Process',
  'Ticket' => 'Ticket'
};
$Self->{'ACLKeysLevel2::PossibleNot'} =  {
  'Action' => 'Action',
  'ActivityDialog' => 'ActivityDialog',
  'Form' => 'Form',
  'FormStd' => 'FormStd',
  'Process' => 'Process',
  'Ticket' => 'Ticket'
};
$Self->{'ACLKeysLevel2::Properties'} =  {
  'CustomerUser' => 'CustomerUser',
  'DynamicField' => 'DynamicField',
  'Frontend' => 'Frontend',
  'Owner' => 'Owner',
  'Priority' => 'Priority',
  'Process' => 'Process',
  'Queue' => 'Queue',
  'Responsible' => 'Responsible',
  'SLA' => 'SLA',
  'Service' => 'Service',
  'State' => 'State',
  'Ticket' => 'Ticket',
  'Type' => 'Type',
  'User' => 'User'
};
$Self->{'ACLKeysLevel2::PropertiesDatabase'} =  {
  'CustomerUser' => 'CustomerUser',
  'DynamicField' => 'DynamicField',
  'Owner' => 'Owner',
  'Priority' => 'Priority',
  'Process' => 'Process',
  'Queue' => 'Queue',
  'Responsible' => 'Responsible',
  'SLA' => 'SLA',
  'Service' => 'Service',
  'State' => 'State',
  'Ticket' => 'Ticket',
  'Type' => 'Type',
  'User' => 'User'
};
$Self->{'ACLKeysLevel3::Actions'}->{'100-AgentTicketQuickClose'} =  [
  'AgentTicketQuickClose'
];
$Self->{'ACLKeysLevel3::Actions'}->{'100-Default'} =  [
  'AgentAppointmentCalendarOverview',
  'AgentTicketArticleDelete',
  'AgentTicketArticleEdit',
  'AgentTicketArticleRestore',
  'AgentTicketArticleVersion',
  'AgentTicketBounce',
  'AgentTicketBulk',
  'AgentTicketClose',
  'AgentTicketCompose',
  'AgentTicketCustomer',
  'AgentTicketForward',
  'AgentTicketEmail',
  'AgentTicketEmailOutbound',
  'AgentTicketEmailResend',
  'AgentTicketFreeText',
  'AgentTicketHistory',
  'AgentTicketLink',
  'AgentTicketLock',
  'AgentTicketMarkSeenUnseen',
  'AgentTicketMerge',
  'AgentTicketMove',
  'AgentTicketNote',
  'AgentTicketOwner',
  'AgentTicketPending',
  'AgentTicketPhone',
  'AgentTicketPhoneInbound',
  'AgentTicketPhoneOutbound',
  'AgentTicketPlain',
  'AgentTicketPrint',
  'AgentTicketPriority',
  'AgentTicketProcess',
  'AgentTicketResponsible',
  'AgentTicketSearch',
  'AgentTicketWatcher',
  'AgentTicketZoom',
  'AgentLinkObject',
  'AgentSplitSelection',
  'CustomerTicketMessage',
  'CustomerTicketPrint',
  'CustomerTicketProcess',
  'CustomerTicketZTSMAction',
  'CustomerTicketZoom',
  'CustomerTicketZoomReply'
];
$Self->{'ACLKeysLevel3::Actions'}->{'100-Default-ITSM'} =  [
  'AgentTicketAddtlITSMField',
  'AgentTicketDecision'
];
$Self->{'ACLKeysLevel3::Actions'}->{'888-MasterSlave'} =  [
  'AgentTicketMasterSlave'
];
$Self->{'AdminContactWD::RunInitialWildcardSearch'} =  '1';
$Self->{'AdminCustomerCompany::RunInitialWildcardSearch'} =  '1';
$Self->{'AdminCustomerUser::RunInitialWildcardSearch'} =  '1';
$Self->{'AdminCustomerUser::UseAutoComplete'} =  '1';
$Self->{'AdminDynamicFieldTitle::Templates'}->{'001-Template'} =  {
  'Bold' => '0',
  'Color' => '#000000',
  'Italic' => '0',
  'Name' => 'Template1',
  'Size' => '12',
  'UnderLine' => '0'
};
$Self->{'AdminDynamicFieldTitle::Templates'}->{'002-Template'} =  {
  'Bold' => '0',
  'Color' => '#000000',
  'Italic' => '0',
  'Name' => 'Template2',
  'Size' => '12',
  'UnderLine' => '1'
};
$Self->{'AdminEmail'} =  'zen.chan@ncs.com.sg';
$Self->{'AdminSelectBox::AllowDatabaseModification'} =  '0';
$Self->{'AgentAppointmentEdit::Location::Link'}->{'1-GoogleMaps'} =  {
  'CSSClass' => 'GoogleMaps',
  'IconName' => 'fa-globe fa-lg',
  'Target' => '_blank',
  'Text' => 'Location',
  'URL' => 'http://maps.google.com/maps?z=7&q='
};
$Self->{'AgentColorDefinitions'} =  {
  'BGDark' => '#bfc0ce',
  'BGElement' => '#fff',
  'BGLight' => '#f7f7f9',
  'BGLightMedium' => '#eeeef2',
  'BGMedium' => '#e5e5eb',
  'BGMediumDark' => '#cdcdd8',
  'Highlight' => '#fef235',
  'HoverDark' => '#fef235',
  'HoverLight' => '#fffccc',
  'MainDark' => '#00023c',
  'MainHover' => '#001bff',
  'MainLight' => '#000099',
  'NotifyErr' => '#f9bcb2',
  'NotifyOK' => '#c4cdfa',
  'NotifyWarn' => '#fffccc',
  'ShadowDark' => 'rgba(0,2,71,0.16)',
  'TextDark' => '#00023c',
  'TextErr' => '#ea2400',
  'TextLight' => '#7f809d',
  'TextLink' => '#001bff',
  'TextMedium' => '#54557c',
  'TextWarn' => '#f5af36'
};
$Self->{'AgentCustomerInformationCenter::Backend'}->{'0050-CIC-CustomerUserList'} =  {
  'Attributes' => '',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'Description' => 'All customer users of a CustomerID',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::CustomerUserList',
  'Permission' => 'ro',
  'Title' => 'Customer Users'
};
$Self->{'AgentCustomerInformationCenter::Backend'}->{'0060-CIC-ITSMConfigItemCustomerCompany'} =  {
  'Attributes' => 'CustomerCompany',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'ConfigItemKey' => {},
  'Default' => '1',
  'DefaultColumns' => {
    'Class' => '2',
    'CurDeplState' => '1',
    'CurDeplStateType' => '1',
    'CurInciState' => '1',
    'CurInciStateType' => '1',
    'LastChanged' => '2',
    'Name' => '2',
    'Number' => '2'
  },
  'Description' => 'CIs assigned to customer company',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::ITSMConfigItemGeneric',
  'Permission' => 'ro',
  'Title' => 'Assigned CIs'
};
$Self->{'AgentCustomerInformationCenter::Backend'}->{'0100-CIC-TicketPendingReminder'} =  {
  'Attributes' => 'TicketPendingTimeOlderMinutes=1;StateType=pending reminder;SortBy=PendingTime;OrderBy=Down;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All tickets with a reminder set where the reminder date has been reached',
  'Filter' => 'Locked',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'UntilTime',
  'Title' => 'Reminder Tickets'
};
$Self->{'AgentCustomerInformationCenter::Backend'}->{'0110-CIC-TicketEscalation'} =  {
  'Attributes' => 'TicketEscalationTimeOlderMinutes=1;SortBy=EscalationTime;OrderBy=Down;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All escalated tickets',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'EscalationTime',
  'Title' => 'Escalated Tickets'
};
$Self->{'AgentCustomerInformationCenter::Backend'}->{'0120-CIC-TicketNew'} =  {
  'Attributes' => 'StateType=new;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All new tickets, these tickets have not been worked on yet',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'Age',
  'Title' => 'New Tickets'
};
$Self->{'AgentCustomerInformationCenter::Backend'}->{'0130-CIC-TicketOpen'} =  {
  'Attributes' => 'StateType=open;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All open tickets, these tickets have already been worked on.',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'Age',
  'Title' => 'Open Tickets'
};
$Self->{'AgentCustomerInformationCenter::Backend'}->{'0500-CIC-CustomerIDStatus'} =  {
  'Attributes' => '',
  'Block' => 'ContentSmall',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'Description' => 'Company Status',
  'Group' => '',
  'Module' => 'Kernel::Output::HTML::Dashboard::CustomerIDStatus',
  'Permission' => 'ro',
  'Title' => 'Company Status'
};
$Self->{'AgentCustomerInformationCenter::Backend'}->{'0600-CIC-CustomerCompanyInformation'} =  {
  'Attributes' => '',
  'Block' => 'ContentSmall',
  'Default' => '1',
  'Description' => 'Customer Information',
  'Group' => '',
  'Module' => 'Kernel::Output::HTML::Dashboard::CustomerCompanyInformation',
  'Title' => 'Customer Information'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0050-CUIC-CustomerIDList'} =  {
  'Attributes' => '',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'Description' => 'All CustomerIDs of a customer user.',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::CustomerIDList',
  'Permission' => 'ro',
  'Title' => 'Customer IDs'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0060-CUIC-ITSMConfigItemCustomerUser'} =  {
  'Attributes' => 'Customer',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'ConfigItemKey' => {
    'Appliance' => 'Contact-User',
    'Client' => 'Contact-User',
    'Client (virtual)' => 'Contact-User',
    'Device (unidentified)' => 'Contact-User',
    'Display' => 'Contact-User',
    'Mobile Device' => 'Contact-User',
    'Other Accessories' => 'Contact-User',
    'Phone' => 'Contact-User',
    'Printer' => 'Contact-User',
    'Projector' => 'Contact-User',
    'Router (Firewall)' => 'Contact-User',
    'Server' => 'Contact-User',
    'Server (virtual)' => 'Contact-User',
    'Smartboard' => 'Contact-User',
    'Storage' => 'Contact-User',
    'Switch' => 'Contact-User',
    'UPS' => 'Contact-User',
    'WLAN access point' => 'Contact-User'
  },
  'Default' => '1',
  'DefaultColumns' => {
    'Class' => '2',
    'CurDeplState' => '1',
    'CurDeplStateType' => '1',
    'CurInciState' => '1',
    'CurInciStateType' => '1',
    'LastChanged' => '2',
    'Name' => '2',
    'Number' => '2'
  },
  'Description' => 'CIs assigned to customer user',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::ITSMConfigItemGeneric',
  'Permission' => 'ro',
  'Title' => 'Assigned CIs'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0100-CUIC-CustomerUserInformation'} =  {
  'Attributes' => '',
  'Block' => 'ContentSmall',
  'Default' => '1',
  'Description' => 'Customer User Information',
  'Group' => '',
  'Module' => 'Kernel::Output::HTML::Dashboard::CustomerUserInformation',
  'Title' => 'Customer User Information'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0100-CUIC-TicketPendingReminder'} =  {
  'Attributes' => 'TicketPendingTimeOlderMinutes=1;StateType=pending reminder;SortBy=PendingTime;OrderBy=Down;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All tickets with a reminder set where the reminder date has been reached',
  'Filter' => 'Locked',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'UntilTime',
  'Title' => 'Reminder Tickets'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0110-CUIC-TicketEscalation'} =  {
  'Attributes' => 'TicketEscalationTimeOlderMinutes=1;SortBy=EscalationTime;OrderBy=Down;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All escalated tickets',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'EscalationTime',
  'Title' => 'Escalated Tickets'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0120-CUIC-TicketNew'} =  {
  'Attributes' => 'StateType=new;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All new tickets, these tickets have not been worked on yet',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'Age',
  'Title' => 'New Tickets'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0130-CUIC-TicketOpen'} =  {
  'Attributes' => 'StateType=open;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All open tickets, these tickets have already been worked on.',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'Age',
  'Title' => 'Open Tickets'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0140-CUIC-TicketClosed'} =  {
  'Attributes' => 'StateType=closed;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All closed tickets.',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'ro',
  'Time' => 'Age',
  'Title' => 'Closed Tickets'
};
$Self->{'AgentCustomerUserInformationCenter::Backend'}->{'0600-CUIC-CustomerCompanyInformation'} =  {
  'Attributes' => '',
  'Block' => 'ContentSmall',
  'Default' => '1',
  'Description' => 'Customer Information',
  'Group' => '',
  'Module' => 'Kernel::Output::HTML::Dashboard::CustomerCompanyInformation',
  'Title' => 'Customer Information'
};
$Self->{'AgentLoginLogo'} =  {
  'StyleHeight' => '150px',
  'URL' => 'common/img/tessera-wordmark.svg'
};
$Self->{'AgentLogo'} =  {
  'StyleHeight' => '95px',
  'StyleRight' => '50px',
  'StyleTop' => '0px',
  'StyleWidth' => '100px',
  'URL' => 'common/img/tessera-p-font_h100.png'
};
$Self->{'AgentPreferencesGroups'} =  [
  {
    'Description' => 'Change your password and more.',
    'Icon' => 'fa-user',
    'Key' => 'UserProfile',
    'Name' => 'User Profile',
    'Prio' => '1000'
  },
  {
    'Description' => 'Choose which notifications you\'d like to receive.',
    'Icon' => 'fa-envelope',
    'Key' => 'NotificationSettings',
    'Name' => 'Notification Settings',
    'Prio' => '1001'
  },
  {
    'Description' => 'Tweak the system as you wish.',
    'Icon' => 'fa-cog',
    'Key' => 'Miscellaneous',
    'Name' => 'Miscellaneous',
    'Prio' => '1002'
  }
];
$Self->{'AgentSelfNotifyOnAction'} =  '0';
$Self->{'AgentSessionLimit'} =  '100';
$Self->{'AgentSessionPerUserLimit'} =  '20';
$Self->{'AppointmentCalendar::CalendarColors'} =  [
  '#000000',
  '#1E1E1E',
  '#3A3A3A',
  '#545453',
  '#6E6E6E',
  '#878687',
  '#888787',
  '#A09FA0',
  '#B8B8B8',
  '#D0D0D0',
  '#E8E8E8',
  '#FFFFFF',
  '#891100',
  '#894800',
  '#888501',
  '#458401',
  '#028401',
  '#018448',
  '#008688',
  '#004A88',
  '#001888',
  '#491A88',
  '#891E88',
  '#891648',
  '#FF2101',
  '#FF8802',
  '#FFFA03',
  '#83F902',
  '#05F802',
  '#03F987',
  '#00FDFF',
  '#008CFF',
  '#002EFF',
  '#8931FF',
  '#FF39FF',
  '#FF2987',
  '#FF726E',
  '#FFCE6E',
  '#FFFB6D',
  '#CEFA6E',
  '#68F96E',
  '#68FDFF',
  '#68FBD0',
  '#6ACFFF',
  '#6E76FF',
  '#D278FF',
  '#FF7AFF',
  '#FF7FD3'
];
$Self->{'AppointmentCalendar::CalendarLimitOverview'} =  '10';
$Self->{'AppointmentCalendar::EventModulePost'}->{'100-Notification'} =  {
  'Event' => '(AppointmentCreate|AppointmentUpdate|AppointmentDelete|AppointmentNotification|CalendarCreate|CalendarUpdate)',
  'Module' => 'Kernel::System::Calendar::Event::Notification'
};
$Self->{'AppointmentCalendar::EventModulePost'}->{'200-TicketAppointments'} =  {
  'Event' => 'AppointmentUpdate',
  'Module' => 'Kernel::System::Calendar::Event::TicketAppointments'
};
$Self->{'AppointmentCalendar::Import::RecurringMonthsLimit'} =  '120';
$Self->{'AppointmentCalendar::Plugin'}->{'0100-Ticket'} =  {
  'Module' => 'Kernel::System::Calendar::Plugin::Ticket',
  'Name' => 'Ticket',
  'URL' => '<OTOBO_CONFIG_HttpType>://<OTOBO_CONFIG_FQDN>/<OTOBO_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=%s'
};
$Self->{'AppointmentCalendar::TicketAppointmentSearchParam'} =  {
  'CustomerID' => 'CustomerID',
  'CustomerUserLogin' => 'Customer user',
  'Locks' => 'Lock state',
  'MIMEBase_AttachmentName' => 'Attachment Name',
  'MIMEBase_Body' => 'Body',
  'MIMEBase_Cc' => 'Cc',
  'MIMEBase_From' => 'From',
  'MIMEBase_Subject' => 'Subject',
  'MIMEBase_To' => 'To',
  'OwnerIDs' => 'Owner',
  'Priorities' => 'Priority',
  'ResponsibleIDs' => 'Responsible',
  'SLAs' => 'SLA',
  'Services' => 'Service',
  'StateType' => 'State type',
  'States' => 'State',
  'Title' => 'Title',
  'Types' => 'Type'
};
$Self->{'AppointmentCalendar::TicketAppointmentType'}->{'0100-FirstResponseTime'} =  {
  'Event' => 'TicketSLAUpdate|TicketQueueUpdate|TicketStateUpdate|TicketCreate|ArticleCreate',
  'Key' => 'FirstResponseTime',
  'Mark' => 'E',
  'Module' => 'Kernel::System::Calendar::Ticket::EscalationTime',
  'Name' => 'First response time'
};
$Self->{'AppointmentCalendar::TicketAppointmentType'}->{'0200-UpdateTime'} =  {
  'Event' => 'TicketSLAUpdate|TicketQueueUpdate|TicketStateUpdate|TicketCreate|ArticleCreate',
  'Key' => 'UpdateTime',
  'Mark' => 'E',
  'Module' => 'Kernel::System::Calendar::Ticket::EscalationTime',
  'Name' => 'Update time'
};
$Self->{'AppointmentCalendar::TicketAppointmentType'}->{'0300-SolutionTime'} =  {
  'Event' => 'TicketSLAUpdate|TicketQueueUpdate|TicketStateUpdate|TicketCreate|ArticleCreate',
  'Key' => 'SolutionTime',
  'Mark' => 'E',
  'Module' => 'Kernel::System::Calendar::Ticket::EscalationTime',
  'Name' => 'Solution time'
};
$Self->{'AppointmentCalendar::TicketAppointmentType'}->{'0400-PendingTime'} =  {
  'Event' => 'TicketPendingTimeUpdate',
  'Key' => 'PendingTime',
  'Mark' => 'P',
  'Module' => 'Kernel::System::Calendar::Ticket::PendingTime',
  'Name' => 'Pending time'
};
$Self->{'AppointmentCalendar::TicketAppointmentType'}->{'0500-DynamicField'} =  {
  'Event' => 'TicketDynamicFieldUpdate_.*',
  'Key' => 'DynamicField_%s',
  'Mark' => 'D',
  'Module' => 'Kernel::System::Calendar::Ticket::DynamicField',
  'Name' => 'DynamicField_%s'
};
$Self->{'AppointmentNotification::Transport'}->{'Email'} =  {
  'AgentEnabledByDefault' => '1',
  'Icon' => 'fa fa-envelope',
  'Module' => 'Kernel::System::Calendar::Event::Transport::Email',
  'Name' => 'Email',
  'Prio' => '100'
};
$Self->{'AttachmentDownloadType'} =  'attachment';
$Self->{'AuthTwoFactorModule::AllowEmptySecret'} =  '1';
$Self->{'AuthTwoFactorModule::AllowPreviousToken'} =  '1';
$Self->{'AuthTwoFactorModule::SecretPreferencesKey'} =  'UserGoogleAuthenticatorSecretKey';
$Self->{'AutoComplete::Agent'}->{'CustomerSearch'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search Tenant',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoComplete::Agent'}->{'Default'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoComplete::Agent'}->{'DynamicFieldContactWD'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoComplete::Agent'}->{'DynamicFieldDBSearch'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search Customer',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoComplete::Agent'}->{'DynamicFieldReference'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoComplete::Agent'}->{'UserSearch'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search User',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoComplete::Customer'}->{'Default'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoComplete::Customer'}->{'DynamicFieldDBSearch'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search Tenant',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoComplete::Customer'}->{'DynamicFieldReference'} =  {
  'AutoCompleteActive' => '1',
  'ButtonText' => 'Search',
  'MaxResultsDisplayed' => '20',
  'MinQueryLength' => '2',
  'QueryDelay' => '100'
};
$Self->{'AutoResponseForWebTickets'} =  '1';
$Self->{'AutoloadPerlPackages'}->{'002-SLAImportExport'} =  [
  'Kernel::Autoload::SLAImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'002-ServiceImportExport'} =  [
  'Kernel::Autoload::ServiceImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'003-GenericAgentImportExport'} =  [
  'Kernel::Autoload::GenericAgentImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'003-GroupImportExport'} =  [
  'Kernel::Autoload::GroupImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'003-QueueImportExport'} =  [
  'Kernel::Autoload::QueueImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'003-QueueTemplatesImportExport'} =  [
  'Kernel::Autoload::QueueTemplatesImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'003-RoleGroupImportExport'} =  [
  'Kernel::Autoload::RoleGroupImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'003-RoleImportExport'} =  [
  'Kernel::Autoload::RoleImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'003-TemplateImportExport'} =  [
  'Kernel::Autoload::TemplateImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'003-TypeImportExport'} =  [
  'Kernel::Autoload::TypeImportExport'
];
$Self->{'AutoloadPerlPackages'}->{'200-DownloadAttachment'} =  [
  'Kernel::Autoload::RepoArticle'
];
$Self->{'CGILogPrefix'} =  'OTOBO-CGI';
$Self->{'CMDBTreeView::DefaultDepth'} =  '3';
$Self->{'CMDBTreeView::ShowLinkLabels'} =  'Yes';
$Self->{'Cache::InBackend'} =  '1';
$Self->{'Cache::InMemory'} =  '1';
$Self->{'Cache::Module'} =  'Kernel::System::Cache::FileStorable';
$Self->{'Cache::Redis'}->{'DatabaseNumber'} =  '0';
$Self->{'Cache::Redis'}->{'RedisFast'} =  '0';
$Self->{'Cache::Redis'}->{'Server'} =  '127.0.0.1:6379';
$Self->{'Cache::SubdirLevels'} =  '2';
$Self->{'CalendarWeekDayStart'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar1'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar2'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar3'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar4'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar5'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar6'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar7'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar8'} =  '1';
$Self->{'CalendarWeekDayStart::Calendar9'} =  '1';
$Self->{'CheckEmailAddresses'} =  '1';
$Self->{'CheckEmailInvalidAddress'} =  '@(example)\\.(..|...)$';
$Self->{'CheckEmailValidAddress'} =  '^(root@localhost|admin@localhost)$';
$Self->{'CheckMXRecord'} =  '0';
$Self->{'CloudService::Admin::Module'}->{'100-SupportDataCollector'} =  {
  'ConfigDialog' => 'AdminCloudServiceSupportDataCollector',
  'Description' => 'Configure sending of support data to OTOBO Team for improved support.',
  'Icon' => 'fa fa-compass',
  'Name' => 'Support data collector'
};
$Self->{'CloudServices::Disabled'} =  '0';
$Self->{'CommunicationChannel'}->{'Chat'} =  {
  'Description' => 'Chat communication channel.',
  'Icon' => 'fa-comment',
  'Module' => 'Kernel::System::CommunicationChannel::Chat',
  'Name' => 'Chat'
};
$Self->{'CommunicationChannel'}->{'Email'} =  {
  'Description' => 'Email communication channel.',
  'Icon' => 'fa-envelope',
  'Module' => 'Kernel::System::CommunicationChannel::Email',
  'Name' => 'Email'
};
$Self->{'CommunicationChannel'}->{'Internal'} =  {
  'Description' => 'Internal communication channel.',
  'Icon' => 'fa-cloud',
  'Module' => 'Kernel::System::CommunicationChannel::Internal',
  'Name' => 'OTOBO'
};
$Self->{'CommunicationChannel'}->{'Phone'} =  {
  'Description' => 'Phone communication channel.',
  'Icon' => 'fa-phone',
  'Module' => 'Kernel::System::CommunicationChannel::Phone',
  'Name' => 'Phone'
};
$Self->{'CommunicationLog::PurgeAfterHours::AllCommunications'} =  '744';
$Self->{'CommunicationLog::PurgeAfterHours::SuccessfulCommunications'} =  '168';
$Self->{'CommunicationLog::Transport'}->{'Email'} =  {
  'Module' => 'Kernel::System::CommunicationLog::Transport::Email',
  'Name' => 'Email'
};
$Self->{'ConfigImportAllowed'} =  '1';
$Self->{'ConfigItemACL::ACLPreselection'} =  '1';
$Self->{'ConfigLevel'} =  '100';
$Self->{'Customer::AuthModule'} =  'Kernel::System::CustomerAuth::DB';
$Self->{'Customer::AuthModule::DB::CryptType'} =  'sha2';
$Self->{'Customer::AuthModule::DB::CustomerKey'} =  'login';
$Self->{'Customer::AuthModule::DB::CustomerPassword'} =  'pw';
$Self->{'Customer::AuthModule::DB::Table'} =  'customer_user';
$Self->{'Customer::AuthModule::DB::bcryptCost'} =  '12';
$Self->{'Customer::AuthModule::LDAP::Die'} =  '1';
$Self->{'Customer::AuthModule::Radius::Die'} =  '1';
$Self->{'Customer::AuthTwoFactorModule::AllowEmptySecret'} =  '1';
$Self->{'Customer::AuthTwoFactorModule::AllowPreviousToken'} =  '1';
$Self->{'Customer::AuthTwoFactorModule::SecretPreferencesKey'} =  'UserGoogleAuthenticatorSecretKey';
$Self->{'Customer::ConfigItem::PermissionConditionColumns'}->{'Default'} =  [
  'Number',
  'Name',
  'Class',
  'InciState',
  'DeplState',
  'Created'
];
$Self->{'Customer::TicketSearch::AllServices'} =  '0';
$Self->{'CustomerColorDefinitions'} =  {
  'BGDark' => '#bfbfce',
  'BGLight' => '#f7f7f9',
  'Highlight' => '#fef235',
  'HoverDark' => '#6d83f2',
  'HoverLight' => '#c4cdfa',
  'MainDark' => '#00023c',
  'MainHover' => '#000099',
  'MainLight' => '#001bff',
  'NotifyErr' => '#f9bcb2',
  'NotifyOK' => '#c4cdfa',
  'NotifyWarn' => '#fffccc',
  'ShadowDark' => 'rgba(4,0,71,0.16)',
  'ShadowMain' => 'rgba(0,27,255,0.24)',
  'TextDark' => '#00023c',
  'TextLight' => '#7f809d'
};
$Self->{'CustomerCompany::EventModulePost'}->{'2000-UpdateCustomerUsers'} =  {
  'Event' => 'CustomerCompanyUpdate',
  'Module' => 'Kernel::System::CustomerCompany::Event::CustomerUserUpdate',
  'Transaction' => '0'
};
$Self->{'CustomerCompany::EventModulePost'}->{'2100-UpdateDynamicFieldObjectName'} =  {
  'Event' => 'CustomerCompanyUpdate',
  'Module' => 'Kernel::System::CustomerCompany::Event::DynamicFieldObjectNameUpdate',
  'Transaction' => '0'
};
$Self->{'CustomerCompany::EventModulePost'}->{'2300-UpdateTickets'} =  {
  'Event' => 'CustomerCompanyUpdate',
  'Module' => 'Kernel::System::CustomerCompany::Event::TicketUpdate',
  'Transaction' => '0'
};
$Self->{'CustomerCompany::EventModulePost'}->{'8000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'CustomerDBLink'} =  '[% Env("CGIHandle") %]?Action=AgentCustomerInformationCenter;CustomerID=[% Data.CustomerID | uri %]';
$Self->{'CustomerDBLinkClass'} =  '';
$Self->{'CustomerDBLinkTarget'} =  '';
$Self->{'CustomerDashboard::Configuration::ServiceCatalog'} =  {
  'Incident' => 'ooofo-bang oooColor-Red',
  'Incident::Major' => 'ooofo-bang oooColor-Red',
  'Problem' => '',
  'RfC' => '',
  'ServiceRequest' => ''
};
$Self->{'CustomerDashboard::Configuration::ServiceCatalog'}->{'DynamicField'} =  {};
$Self->{'CustomerDashboard::Configuration::ServiceCatalog'}->{'FAQDescriptionField'} =  'Field1';
$Self->{'CustomerDashboard::Configuration::Text'} =  {
  'Name' => 'UserFirstname',
  'SubText' => 'This service portal is available to you all day every day.',
  'WelcomeText' => 'Welcome %s, to your OTOBO.'
};
$Self->{'CustomerDashboard::Tiles'}->{'FeaturedLink-01'} =  {
  'Config' => {
    'BackgroundImage' => '<OTOBO_CONFIG_Frontend::WebPath>common/img/Dashboard/dashboard_bgfl.png',
    'FooterText' => 'Learn more >',
    'HeaderText' => 'OTOBO 11.0 | Service Management',
    'Link' => 'https://ncs.com.sg',
    'MainText' => 'OTOBO 11.0 takes your service management to the next level with enhanced flexibility. And, with the simultaneous release of CMDB 11.0, you\'ll get seamless integration between your asset management and service management workflows.',
    'NewTab' => '0',
    'TextColor' => '#ffffff'
  },
  'Order' => '2',
  'Template' => 'Dashboard/TileFeaturedLink'
};
$Self->{'CustomerDashboard::Tiles'}->{'InfoTile-01'} =  {
  'Config' => {
    'BackgroundColor' => '#fff',
    'Order' => {},
    'TextColor' => '#00023c'
  },
  'Module' => 'Kernel::Output::HTML::CustomerDashboard::InfoTile',
  'Order' => '7',
  'Template' => 'Dashboard/TileInfoEntries'
};
$Self->{'CustomerDashboard::Tiles'}->{'NewTicket'} =  {
  'Config' => {
    'Color' => '#001bff'
  },
  'Order' => '1',
  'Template' => 'Dashboard/TileNewTicket'
};
$Self->{'CustomerDashboard::Tiles'}->{'ServiceCatalog-01'} =  {
  'Config' => {
    'HeaderText' => 'Find the right service for your ticket'
  },
  'Module' => 'Kernel::Output::HTML::CustomerDashboard::TileServiceCatalog',
  'Order' => '7'
};
$Self->{'CustomerDashboard::Tiles'}->{'TicketList-01'} =  {
  'Config' => {
    'CompanyTickets' => '0',
    'MaxTickets' => '9',
    'OrderBy' => 'Down',
    'SortBy' => 'Age',
    'StateType' => '',
    'Text' => 'Your last tickets'
  },
  'Module' => 'Kernel::Output::HTML::CustomerDashboard::TileTicketList',
  'Order' => '3'
};
$Self->{'CustomerDashboard::Tiles'}->{'ToolBox-01'} =  {
  'Config' => {
    'Images' => {
      '/otobo-web/skins/Customer/default/img/sample_openstreetmap.png' => '2',
      '/otobo-web/skins/Customer/default/img/sample_otobo.png' => '1',
      '/otobo-web/skins/Customer/default/img/sample_wikipedia.png' => '3'
    },
    'Links' => {
      'https://www.openstreetmap.org' => '2',
      'https://ncs.com.sg' => '1',
      'https://www.wikipedia.org' => '3'
    },
    'Text' => 'Your external tools',
    'TextColor' => '#00023c',
    'Titles' => {
      'OTOBO' => '1',
      'OpenStreetMap' => '2',
      'Wikipedia' => '3'
    }
  },
  'Module' => 'Kernel::Output::HTML::CustomerDashboard::TileToolBox',
  'Order' => '5'
};
$Self->{'CustomerFrontend::Active'} =  '1';
$Self->{'CustomerFrontend::CKEditorPlugins'} =  [
  'Alignment',
  'Autoformat',
  'BlockQuote',
  'Bold',
  'CodeBlock',
  'DataFilter',
  'DataSchema',
  'FindAndReplace',
  'FontColor',
  'FontFamily',
  'FontSize',
  'FontBackgroundColor',
  'GeneralHtmlSupport',
  'Heading',
  'HorizontalLine',
  'Image',
  'ImageResize',
  'ImageStyle',
  'ImageUpload',
  'ImageToolbar',
  'ImageInsert',
  'Indent',
  'Italic',
  'Link',
  'List',
  'Paragraph',
  'RemoveFormat',
  'SelectAll',
  'SimpleUploadAdapter',
  'SourceEditing',
  'SpecialCharacters',
  'SpecialCharactersEssentials',
  'Strikethrough',
  'Table',
  'TableCellProperties',
  'TableColumnResize',
  'TableProperties',
  'TableToolbar',
  'Underline',
  'Undo',
  'PasteFromOffice',
  'Fullscreen'
];
$Self->{'CustomerFrontend::CommonParam'}->{'Action'} =  'CustomerDashboard';
$Self->{'CustomerFrontend::CommonParam'}->{'TicketID'} =  '';
$Self->{'CustomerFrontend::EnhancedCKEditorToolbar'} =  [
  [
    'heading',
    'bold',
    'italic',
    'underline',
    'strikethrough'
  ],
  [
    'bulletedList',
    'numberedList'
  ],
  [
    'insertTable'
  ],
  [
    'indent',
    'outdent',
    'alignment'
  ],
  [
    'link',
    'undo',
    'redo'
  ],
  [
    'insertImage',
    'horizontalLine',
    'blockQuote'
  ],
  [
    'findAndReplace',
    'fontColor'
  ],
  [
    'fontBackgroundColor',
    'removeFormat'
  ],
  [
    'sourceEditing',
    'specialCharacters'
  ],
  [
    'fontFamily',
    'fontSize'
  ],
  [
    'codeBlock'
  ],
  [
    'fullscreen'
  ]
];
$Self->{'CustomerFrontend::HeaderMetaModule'}->{'1-Refresh'} =  {
  'Module' => 'Kernel::Output::HTML::HeaderMeta::Refresh'
};
$Self->{'CustomerFrontend::HeaderMetaModule'}->{'2-TicketSearch'} =  {
  'Action' => 'CustomerTicketSearch',
  'Module' => 'Kernel::Output::HTML::HeaderMeta::CustomerTicketSearch'
};
$Self->{'CustomerFrontend::HeaderMetaModule'}->{'3-FAQSearch'} =  {
  'Action' => 'CustomerFAQSearch',
  'Module' => 'Kernel::Output::HTML::HeaderMeta::CustomerFAQSearch'
};
$Self->{'CustomerFrontend::Module'}->{'AgentReferenceSearch'} =  {
  'Description' => 'Customer reference dynamic field with data search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Customer Reference Dynamic Field With Data Search'
};
$Self->{'CustomerFrontend::Module'}->{'AjaxAttachment'} =  {
  'Description' => 'AjaxAttachment',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'CustomerAccept'} =  {
  'Description' => 'To accept login information, such as an EULA or license.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Info'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerDashboard'} =  {
  'Description' => 'Customer Dashboard',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Dashboard',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'CustomerDashboardContent'} =  {
  'Description' => 'Create tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'New Ticket'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerDynamicFieldAttachment'} =  {
  'Description' => 'Customer',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Dynamic Fields Attachment download frontend'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerDynamicFieldDBDetailedSearch'} =  {
  'Description' => 'Customer dynamic field database detailed search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Customer Dynamic Field Database Detailed Search'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerDynamicFieldDBDetails'} =  {
  'Description' => 'Customer dynamic field database details.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Customer Dynamic Field Database Details'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerDynamicFieldDBSearch'} =  {
  'Description' => 'Customer dynamic field database search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Customer Dynamic Field Database Search'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerElasticsearchQuickResult'} =  {
  'Description' => 'Elasticsearch quick result module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'ElasticsearchQuickResult'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerFAQExplorer'} =  {
  'Description' => 'Customer FAQ.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'CustomerFAQPrint'} =  {
  'Description' => 'Customer FAQ Print.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'CustomerFAQRelatedArticles'} =  {
  'Description' => 'Customer FAQ Related Articles.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Customer FAQ Related Articles'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerFAQSearch'} =  {
  'Description' => 'Customer FAQ search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'Search FAQ'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerFAQZoom'} =  {
  'Description' => 'Customer FAQ Zoom.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'CustomerGenericContent'} =  {
  'Description' => 'Show various content.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Info'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerITSMConfigItemAttachment'} =  {
  'Description' => 'To download attachments.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Config Item',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'CustomerPassword'} =  {
  'Description' => 'Customer Password.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Password Policy'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerPreferences'} =  {
  'Description' => 'Customer preferences.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Preferences'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTicketArticleContent'} =  {
  'Description' => 'To view HTML attachments.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTicketAttachment'} =  {
  'Description' => 'To download attachments.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTicketMessage'} =  {
  'Description' => 'Create tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'New Ticket'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTicketOverview'} =  {
  'Description' => 'Overview of customer tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Overview'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTicketPrint'} =  {
  'Description' => 'Customer Ticket Print Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Print'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTicketSearch'} =  {
  'Description' => 'Customer ticket search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Search'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTicketZoom'} =  {
  'Description' => 'Ticket zoom view.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Zoom'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTicketZTSMAction'} =  {
  'Description' => 'TESSERA runtime action.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Runtime Action'
};
$Self->{'CustomerFrontend::Module'}->{'CustomerTileServiceCatalog'} =  {
  'Description' => 'CustomerTileServiceCatalog AJAX Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Service Catalog',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'Logout'} =  {
  'Description' => 'Logout of customer panel.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'CustomerFrontend::Module'}->{'PictureUpload'} =  {
  'Description' => 'Picture upload module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Picture-Upload'
};
$Self->{'CustomerFrontend::Navigation'}->{'CustomerDashboard'}->{'002-CustomerDashboard'} =  [
  {
    'AccessKey' => 'd',
    'Block' => '',
    'Description' => 'Customer Dashboard',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerDashboard',
    'LinkOption' => '',
    'Name' => 'Dashboard',
    'NavBar' => 'Dashboard',
    'Prio' => '10',
    'Type' => 'Menu',
    'svgIcon' => 'var/httpd/htdocs/skins/Customer/default/img/dashboard.svg'
  }
];
$Self->{'CustomerFrontend::Navigation'}->{'CustomerFAQExplorer'}->{'002-FAQ'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'FAQ',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerFAQExplorer',
    'LinkOption' => '',
    'Name' => 'FAQ',
    'NavBar' => 'FAQ',
    'Prio' => '700',
    'Type' => 'Menu',
    'svgIcon' => 'var/httpd/htdocs/skins/Customer/default/img/faq.svg'
  },
  {
    'AccessKey' => 'x',
    'Block' => '',
    'Description' => 'FAQ Explorer',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerFAQExplorer',
    'LinkOption' => '',
    'Name' => 'FAQ Explorer',
    'NavBar' => 'FAQ',
    'Prio' => '710',
    'Type' => 'Submenu'
  }
];
$Self->{'CustomerFrontend::Navigation'}->{'CustomerFAQSearch'}->{'002-FAQ'} =  [
  {
    'AccessKey' => 'f',
    'Block' => '',
    'Description' => 'Search',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerFAQSearch',
    'LinkOption' => '',
    'Name' => 'Search',
    'NavBar' => 'FAQ',
    'Prio' => '780',
    'Type' => 'Submenu'
  }
];
$Self->{'CustomerFrontend::Navigation'}->{'CustomerITSMConfigItem'}->{'003-ITSMConfigItem'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Configuration Management Database.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerITSMConfigItem',
    'LinkOption' => '',
    'Name' => 'CMDB',
    'NavBar' => 'Ticket',
    'Prio' => '310',
    'Type' => 'Menu',
    'svgIcon' => 'var/httpd/htdocs/skins/Customer/default/img/devices_black_24dp.svg'
  }
];
$Self->{'CustomerFrontend::Navigation'}->{'CustomerTicketMessage'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 'n',
    'Block' => '',
    'Description' => 'Create new Ticket.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerTicketMessage',
    'LinkOption' => '',
    'Name' => 'New Ticket',
    'NavBar' => 'Ticket',
    'Prio' => '100',
    'Type' => 'Submenu'
  }
];
$Self->{'CustomerFrontend::Navigation'}->{'CustomerTicketOverview'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 'm',
    'Block' => '',
    'Description' => 'Tickets.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerTicketOverview;Subaction=MyTickets',
    'LinkOption' => '',
    'Name' => 'Tickets',
    'NavBar' => 'Ticket',
    'Prio' => '100',
    'Type' => 'Menu',
    'svgIcon' => 'var/httpd/htdocs/skins/Customer/default/img/mytickets.svg'
  },
  {
    'AccessKey' => 't',
    'Block' => '',
    'Description' => 'Company Tickets.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerTicketOverview;Subaction=CompanyTickets',
    'LinkOption' => '',
    'Name' => 'Company Tickets',
    'NavBar' => 'Ticket',
    'Prio' => '120',
    'Type' => 'Menu',
    'svgIcon' => 'var/httpd/htdocs/skins/Customer/default/img/companytickets.svg'
  }
];
$Self->{'CustomerFrontend::Navigation'}->{'CustomerTicketSearch'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 's',
    'Block' => '',
    'Description' => 'Search.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerTicketSearch',
    'LinkOption' => '',
    'Name' => 'Search',
    'NavBar' => 'Ticket',
    'Prio' => '300',
    'Type' => 'Submenu'
  }
];
$Self->{'CustomerFrontend::Navigation'}->{'CustomerTicketSearch'}->{'003-CustomerTickerSearch'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Search Tickets.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=CustomerTicketSearch',
    'LinkOption' => '',
    'Name' => 'Ticket Search.',
    'NavBar' => 'Ticket',
    'Prio' => '100',
    'Type' => 'Menu',
    'svgIcon' => 'var/httpd/htdocs/skins/Customer/default/img/magnifying-glass-solid.svg'
  }
];
$Self->{'CustomerFrontend::NotifyModule'}->{'6-CustomerSystemMaintenance-Check'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::CustomerSystemMaintenanceCheck'
};
$Self->{'CustomerFrontend::NotifyModule'}->{'8-CustomerAnnouncement-Check'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::CustomerAnnouncementCheck',
  'NotifyPriority' => 'Error',
  'Segregation' => '###',
  'UseMarquee' => '1'
};
$Self->{'CustomerFrontend::RichText::DefaultCSS'} =  '';
$Self->{'CustomerFrontend::RichTextArticleStyles'} =  'common/css/ckeditor5-47.6.1-content.css';
$Self->{'CustomerFrontend::RichTextEditorStyles'} =  'common/css/ckeditor5-47.6.1-editor.css';
$Self->{'CustomerGenericHTMLContent::HeaderMap'}->{'01-Framework'} =  {
  'About' => 'About'
};
$Self->{'CustomerGenericHTMLContent::ModuleMap'}->{'01-Framework'} =  {
  'About' => 'About',
  'Accept' => 'Accept'
};
$Self->{'CustomerGroupAlwaysGroups'} =  [
  'users'
];
$Self->{'CustomerGroupCompanyAlwaysGroups'} =  [
  'users'
];
$Self->{'CustomerGroupPermissionContext'}->{'001-CustomerID-same'} =  {
  'Description' => 'Gives customer users group based access to tickets from customer users of the same customer (ticket CustomerID is a CustomerID of the customer user).',
  'Name' => 'Same Customer',
  'Value' => 'Ticket::CustomerID::Same'
};
$Self->{'CustomerGroupSupport'} =  '1';
$Self->{'CustomerHeadline'} =  'Example Company';
$Self->{'CustomerLogin::Settings'} =  {
  'Background' => '<OTOBO_CONFIG_Frontend::WebPath>common/img/LoginBG.jpg',
  'LoginText' => 'Your Tickets. Your OTOBO.'
};
$Self->{'CustomerLogo'} =  {
  'URLLogo' => 'common/img/tessera-vertical.svg',
  'URLSignet' => 'common/img/tessera-wordmark.svg'
};
$Self->{'CustomerNotifyJustToRealCustomer'} =  '0';
$Self->{'CustomerPanel::InfoFile'} =  'CustomerAccept';
$Self->{'CustomerPanel::InfoKey'} =  'CustomerAccept1';
$Self->{'CustomerPanel::NewTicketQueueSelectionModule'} =  'Kernel::Output::HTML::CustomerNewTicket::QueueSelectionGeneric';
$Self->{'CustomerPanelBodyLostPassword'} =  'Hi <OTOBO_USERFIRSTNAME>,


New password: <OTOBO_NEWPW>

<OTOBO_CONFIG_HttpType>://<OTOBO_CONFIG_FQDN>/<OTOBO_CONFIG_ScriptAlias>customer.pl
            ';
$Self->{'CustomerPanelBodyLostPasswordToken'} =  'Hi <OTOBO_USERFIRSTNAME>,

You or someone impersonating you has requested to change your OTOBO
password.

If you want to do this, click on this link. You will receive another email containing the password.

<OTOBO_CONFIG_HttpType>://<OTOBO_CONFIG_FQDN>/<OTOBO_CONFIG_ScriptAlias>customer.pl?Action=CustomerLostPassword;Token=<OTOBO_TOKEN>

If you did not request a new password, please ignore this email.
            ';
$Self->{'CustomerPanelBodyNewAccount'} =  'Hi <OTOBO_USERFIRSTNAME>,

You or someone impersonating you has created a new OTOBO account for
you.

Full name: <OTOBO_USERFIRSTNAME> <OTOBO_USERLASTNAME>
User name: <OTOBO_USERLOGIN>
Password : <OTOBO_USERPASSWORD>

You can log in via the following URL. We encourage you to change your password
via the Preferences button after logging in.

<OTOBO_CONFIG_HttpType>://<OTOBO_CONFIG_FQDN>/<OTOBO_CONFIG_ScriptAlias>customer.pl
            ';
$Self->{'CustomerPanelCreateAccount'} =  '1';
$Self->{'CustomerPanelLostPassword'} =  '1';
$Self->{'CustomerPanelPreApplicationModule'}->{'CustomerAccept'} =  'Kernel::Modules::CustomerAccept';
$Self->{'CustomerPanelPreApplicationModule'}->{'CustomerPassword'} =  'Kernel::Modules::CustomerPassword';
$Self->{'CustomerPanelSelectionString'} =  '<Queue>';
$Self->{'CustomerPanelSelectionType'} =  'Queue';
$Self->{'CustomerPanelSessionName'} =  'OTOBOCustomerInterface';
$Self->{'CustomerPanelSubjectLostPassword'} =  'New OTOBO password';
$Self->{'CustomerPanelSubjectLostPasswordToken'} =  'New OTOBO password request';
$Self->{'CustomerPanelSubjectNewAccount'} =  'New OTOBO Account!';
$Self->{'CustomerPanelUserID'} =  '1';
$Self->{'CustomerPreferences'} =  {
  'Module' => 'Kernel::System::CustomerUser::Preferences::DB',
  'Params' => {
    'Table' => 'customer_preferences',
    'TableKey' => 'preferences_key',
    'TableUserID' => 'user_id',
    'TableValue' => 'preferences_value'
  }
};
$Self->{'CustomerPreferencesGroups'}->{'GoogleAuthenticatorSecretKey'} =  {
  'Active' => '0',
  'Block' => 'Input',
  'Desc' => 'Enter your shared secret to enable two factor authentication. WARNING: Make sure that you add the shared secret to your generator application and the application works well. Otherwise you will be not able to login anymore without the two factor token.',
  'Key' => 'Shared Secret',
  'Label' => 'Google Authenticator',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserGoogleAuthenticatorSecretKey',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '1100',
  'ValidateRegex' => '^([A-Z2-7]{16}|)$',
  'ValidateRegexMessage' => 'The secret you supplied is invalid. The secret must only contain letters (A-Z, uppercase) and numbers (2-7) and must consist of 16 characters.'
};
$Self->{'CustomerPreferencesGroups'}->{'Language'} =  {
  'Active' => '1',
  'Desc' => 'Select the main interface language.',
  'Key' => 'Language',
  'Label' => 'Interface language',
  'Module' => 'Kernel::Output::HTML::Preferences::Language',
  'PrefKey' => 'UserLanguage',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '2000'
};
$Self->{'CustomerPreferencesGroups'}->{'PGP'} =  {
  'Active' => '1',
  'Desc' => 'Upload your PGP key.',
  'Key' => 'PGP Key',
  'Label' => 'PGP Key',
  'Module' => 'Kernel::Output::HTML::Preferences::PGP',
  'PrefKey' => 'UserPGPKey',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '10000'
};
$Self->{'CustomerPreferencesGroups'}->{'Password'} =  {
  'Active' => '1',
  'Area' => 'Customer',
  'Desc' => 'Set a new password by filling in your current password and a new one.',
  'Label' => 'Change password',
  'Module' => 'Kernel::Output::HTML::Preferences::Password',
  'PasswordHistory' => '3',
  'PasswordMaxLoginFailed' => '',
  'PasswordMaxValidTimeInDays' => '',
  'PasswordMin2Characters' => '0',
  'PasswordMin2Lower2UpperCharacters' => '0',
  'PasswordMinSize' => '8',
  'PasswordNeedDigit' => '1',
  'PasswordRegExp' => '',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '1000'
};
$Self->{'CustomerPreferencesGroups'}->{'RefreshTime'} =  {
  'Active' => '1',
  'Data' => {
    '0' => 'off',
    '10' => '10 minutes',
    '15' => '15 minutes',
    '2' => ' 2 minutes',
    '5' => ' 5 minutes',
    '7' => ' 7 minutes'
  },
  'DataSelected' => '0',
  'Desc' => 'Select after which period ticket overviews should refresh automatically.',
  'Key' => 'Refresh interval',
  'Label' => 'Ticket overview',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserRefreshTime',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '4000'
};
$Self->{'CustomerPreferencesGroups'}->{'SMIME'} =  {
  'Active' => '1',
  'Desc' => 'Upload your S/MIME certificate.',
  'Key' => 'S/MIME Certificate',
  'Label' => 'S/MIME Certificate',
  'Module' => 'Kernel::Output::HTML::Preferences::SMIME',
  'PrefKey' => 'UserSMIMEKey',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '11000'
};
$Self->{'CustomerPreferencesGroups'}->{'ShownTickets'} =  {
  'Active' => '1',
  'Data' => {
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30'
  },
  'DataSelected' => '25',
  'Desc' => 'Select how many tickets should be shown in overviews by default.',
  'Key' => 'Tickets per page',
  'Label' => 'Number of displayed tickets',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserShowTickets',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '4000'
};
$Self->{'CustomerPreferencesGroups'}->{'Skin'} =  {
  'Active' => '1',
  'Desc' => 'Select your preferred layout for the software.',
  'Key' => 'Skin',
  'Label' => 'Skin',
  'Module' => 'Kernel::Output::HTML::Preferences::Skin',
  'PrefKey' => 'UserSkin',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '500'
};
$Self->{'CustomerPreferencesGroups'}->{'TimeZone'} =  {
  'Active' => '1',
  'Desc' => 'Select your personal time zone. All times will be displayed relative to this time zone.',
  'Key' => 'Time Zone',
  'Label' => 'Time Zone',
  'Module' => 'Kernel::Output::HTML::Preferences::TimeZone',
  'PrefKey' => 'UserTimeZone',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '2500'
};
$Self->{'CustomerSessionLimit'} =  '100';
$Self->{'CustomerSessionPerUserLimit'} =  '20';
$Self->{'CustomerSkinColorDefinition::highcontrast'} =  {
  'BGDark' => '#000000',
  'BGLight' => '#ffffff',
  'Highlight' => '#ffffff',
  'HoverDark' => '#b5b5b5',
  'HoverLight' => '#e0e0e0',
  'MainDark' => '#333',
  'MainLight' => '#001bff',
  'NotifyErr' => '#f9bcb2',
  'NotifyOK' => '#e0e0e0',
  'NotifyWarn' => '#fffccc',
  'ShadowDark' => 'rgba(4,0,71,0.16)',
  'ShadowMain' => 'rgba(0,27,255,0.24)',
  'TextDark' => '#000000',
  'TextLight' => '#ffffff'
};
$Self->{'CustomerTicket::Permission'}->{'1-GroupCheck'} =  {
  'Granted' => '0',
  'Module' => 'Kernel::System::Ticket::CustomerPermission::GroupCheck',
  'Required' => '1'
};
$Self->{'CustomerTicket::Permission'}->{'2-CustomerUserIDCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::Ticket::CustomerPermission::CustomerUserIDCheck',
  'Required' => '0'
};
$Self->{'CustomerTicket::Permission'}->{'3-CustomerIDCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::Ticket::CustomerPermission::CustomerIDCheck',
  'Required' => '0'
};
$Self->{'CustomerTicket::Permission'}->{'4-CustomerGroupCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::Ticket::CustomerPermission::CustomerGroupCheck',
  'Required' => '0'
};
$Self->{'CustomerTicket::Permission'}->{'5-ZTSMUserIDCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck',
  'Required' => '0'
};
$Self->{'CustomerUser::EventModulePost'}->{'2000-UpdateDynamicFieldObjectName'} =  {
  'Event' => 'CustomerUserUpdate',
  'Module' => 'Kernel::System::CustomerUser::Event::DynamicFieldObjectNameUpdate',
  'Transaction' => '0'
};
$Self->{'CustomerUser::EventModulePost'}->{'2100-UpdateSearchProfiles'} =  {
  'Event' => 'CustomerUserUpdate',
  'Module' => 'Kernel::System::CustomerUser::Event::SearchProfileUpdate',
  'Transaction' => '0'
};
$Self->{'CustomerUser::EventModulePost'}->{'2200-UpdateServiceMembership'} =  {
  'Event' => 'CustomerUserUpdate',
  'Module' => 'Kernel::System::CustomerUser::Event::ServiceMemberUpdate',
  'Transaction' => '0'
};
$Self->{'CustomerUser::EventModulePost'}->{'2300-UpdateTickets'} =  {
  'Event' => 'CustomerUserUpdate',
  'Module' => 'Kernel::System::CustomerUser::Event::TicketUpdate',
  'Transaction' => '0'
};
$Self->{'CustomerUser::EventModulePost'}->{'8000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'CustomerUser::Frontend::AgentCustomerUserAddressBook'}->{'DefaultFields'} =  {
  'Email' => [
    'UserLogin',
    'UserFirstname',
    'UserLastname',
    'UserEmail',
    'UserCustomerID'
  ]
};
$Self->{'CustomerUser::Frontend::AgentCustomerUserAddressBook'}->{'SearchParameters'} =  {
  'Email' => {
    'CustomerTicketTextField' => 'UserMailString',
    'Order::Default' => 'Up',
    'PageShown' => '50',
    'SearchLimit' => '10000',
    'SortBy::Default' => 'UserLogin'
  }
};
$Self->{'CustomerUser::Frontend::AgentCustomerUserAddressBook'}->{'ShowColumns'} =  {
  'Email' => [
    'UserFirstname',
    'UserLastname',
    'UserLogin',
    'UserEmail',
    'UserCustomerID'
  ]
};
$Self->{'CustomerUser::Frontend::Overview'}->{'AddressBook'} =  {
  'Module' => 'Kernel::Output::HTML::CustomerUser::OverviewAddressBook',
  'Name' => 'AddressBook'
};
$Self->{'Daemon::Log::RotationType'} =  'otobo';
$Self->{'Daemon::Log::STDERR'} =  '1';
$Self->{'Daemon::Log::STDOUT'} =  '0';
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'ArticleSearchIndexRebuild'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Ticket::FulltextIndexRebuildWorker',
  'Params' => [
    '--children',
    '4',
    '--limit',
    '20000'
  ],
  'Schedule' => '* * * * *',
  'TaskName' => 'ArticleSearchIndexRebuild'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'CommunicationLogDelete'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Log::CommunicationLog',
  'Params' => [
    '--purge'
  ],
  'Schedule' => '00 03 * * *',
  'TaskName' => 'CommunicationLogDelete'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'ConfigurationDeploymentCleanup'} =  {
  'Function' => 'ConfigurationDeployCleanup',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::SysConfig',
  'Params' => [],
  'Schedule' => '40 0 * * 0',
  'TaskName' => 'ConfigurationDeploymentCleanup'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'CoreCacheCleanup'} =  {
  'Function' => 'CleanUp',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Cache',
  'Params' => [
    'Expired',
    '1'
  ],
  'Schedule' => '20 0 * * 0',
  'TaskName' => 'CoreCacheCleanup'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'EscalationCheck'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Ticket::EscalationCheck',
  'Params' => [],
  'Schedule' => '*/5 * * * *',
  'TaskName' => 'EscalationCheck'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'FormCacheCleanup'} =  {
  'Function' => 'CleanUpExpired',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Web::FormCache',
  'Params' => [],
  'Schedule' => '52 * * * *',
  'TaskName' => 'FormCacheCleanup'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'GenerateDashboardStats'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Stats::Dashboard::Generate',
  'Params' => [],
  'Schedule' => '5 * * * *',
  'TaskName' => 'GenerateDashboardStats'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'GeneticInterfaceDebugLogCleanup'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::GenericInterface::DebugLog::Cleanup',
  'Params' => [
    '--created-before-days',
    '14'
  ],
  'Schedule' => '02 03 * * *',
  'TaskName' => 'GeneticInterfaceDebugLogCleanup'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'ITSMChangesCheck'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Admin::ITSM::Change::Check',
  'Params' => [],
  'Schedule' => '*/10 * * * *',
  'TaskName' => 'ITSMChangesCheck'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'LoaderCacheDelete'} =  {
  'Function' => 'CacheDelete',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Loader',
  'Params' => [],
  'Schedule' => '30 0 * * 0',
  'TaskName' => 'LoaderCacheDelete'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'MailAccountFetch'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::PostMaster::MailAccountFetch',
  'Params' => [],
  'Schedule' => '*/10 * * * *',
  'TaskName' => 'MailAccountFetch'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'MailQueueSend'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Email::MailQueue',
  'Params' => [
    '--send'
  ],
  'Schedule' => '* * * * *',
  'TaskName' => 'MailQueueSend'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'RebuildEscalationIndex'} =  {
  'Function' => 'RebuildEscalationIndex',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Ticket',
  'Params' => [],
  'Schedule' => '*/4 * * * *',
  'TaskName' => 'RebuildEscalationIndex'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'RegistrationUpdateSend'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Registration::UpdateSend',
  'Params' => [],
  'Schedule' => '30 * * * *',
  'TaskName' => 'RegistrationUpdateSend'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'RenewCustomerSMIMECertificates'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::SMIME::CustomerCertificate::Renew',
  'Params' => [],
  'Schedule' => '02 02 * * *',
  'TaskName' => 'RenewCustomerSMIMECertificates'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'SessionDeleteExpired'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Session::DeleteExpired',
  'Params' => [],
  'Schedule' => '55 */2 * * *',
  'TaskName' => 'SessionDeleteExpired'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'SpoolMailsReprocess'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::PostMaster::SpoolMailsReprocess',
  'Params' => [],
  'Schedule' => '10 0 * * *',
  'TaskName' => 'SpoolMailsReprocess'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'StatsReportsGenerateCron'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Stats::Reports::GenerateCron',
  'Params' => [],
  'Schedule' => '*/10 * * * *',
  'TaskName' => 'StatsReportsGenerateCron'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'SupportDataCollectAsynchronous'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::SupportData::CollectAsynchronous',
  'Params' => [],
  'Schedule' => '1 * * * *',
  'TaskName' => 'SupportDataCollectAsynchronous'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'TicketAcceleratorRebuild'} =  {
  'Function' => 'TicketAcceleratorRebuild',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Ticket',
  'Params' => [],
  'Schedule' => '01 01 * * *',
  'TaskName' => 'TicketAcceleratorRebuild'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'TicketDraftDeleteExpired'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::FormDraft::Delete',
  'Params' => [
    '--object-type',
    'Ticket',
    '--expired'
  ],
  'Schedule' => '55 * * * *',
  'TaskName' => 'TicketDraftDeleteExpired'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'TicketNumberCounterCleanup'} =  {
  'Function' => 'TicketNumberCounterCleanup',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Ticket::Number::AutoIncrement',
  'Params' => [],
  'Schedule' => '*/10 * * * *',
  'TaskName' => 'TicketNumberCounterCleanup'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'TicketPendingCheck'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Ticket::PendingCheck',
  'Params' => [],
  'Schedule' => '45 */2 * * *',
  'TaskName' => 'TicketPendingCheck'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'TicketUnlockTimeout'} =  {
  'Function' => 'Execute',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Console::Command::Maint::Ticket::UnlockTimeout',
  'Params' => [],
  'Schedule' => '35 * * * *',
  'TaskName' => 'TicketUnlockTimeout'
};
$Self->{'Daemon::SchedulerCronTaskManager::Task'}->{'WebUploadCacheCleanup'} =  {
  'Function' => 'FormIDCleanUp',
  'MaximumParallelInstances' => '1',
  'Module' => 'Kernel::System::Web::UploadCache',
  'Params' => [],
  'Schedule' => '46 * * * *',
  'TaskName' => 'WebUploadCacheCleanup'
};
$Self->{'Daemon::SchedulerGenericAgentTaskManager::SleepTime'} =  '0';
$Self->{'Daemon::SchedulerGenericAgentTaskManager::TicketLimit'} =  '4000';
$Self->{'Daemon::SchedulerGenericInterfaceTaskManager::FutureTaskTimeDiff'} =  '300';
$Self->{'Daemon::SchedulerTaskWorker::MaximumWorkers'} =  '5';
$Self->{'Daemon::SchedulerTaskWorker::NotificationRecipientEmail'} =  'root@localhost';
$Self->{'DaemonModules'}->{'SchedulerCronTaskManager'} =  {
  'Module' => 'Kernel::System::Daemon::DaemonModules::SchedulerCronTaskManager'
};
$Self->{'DaemonModules'}->{'SchedulerFutureTaskManager'} =  {
  'Module' => 'Kernel::System::Daemon::DaemonModules::SchedulerFutureTaskManager'
};
$Self->{'DaemonModules'}->{'SchedulerGenericAgentTaskManager'} =  {
  'Module' => 'Kernel::System::Daemon::DaemonModules::SchedulerGenericAgentTaskManager'
};
$Self->{'DaemonModules'}->{'SchedulerTaskWorker'} =  {
  'Module' => 'Kernel::System::Daemon::DaemonModules::SchedulerTaskWorker'
};
$Self->{'DaemonModules'}->{'SystemConfigurationSyncManager'} =  {
  'Module' => 'Kernel::System::Daemon::DaemonModules::SystemConfigurationSyncManager'
};
$Self->{'DashboardBackend'}->{'0100-TicketPendingReminder'} =  {
  'Attributes' => 'TicketPendingTimeOlderMinutes=1;StateType=pending reminder;SortBy=PendingTime;OrderBy=Down;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All tickets with a reminder set where the reminder date has been reached',
  'Filter' => 'Locked',
  'Group' => '',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'rw',
  'Time' => 'UntilTime',
  'Title' => 'Reminder Tickets'
};
$Self->{'DashboardBackend'}->{'0110-TicketEscalation'} =  {
  'Attributes' => 'TicketEscalationTimeOlderMinutes=1;SortBy=EscalationTime;OrderBy=Down;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All escalated tickets',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'rw',
  'Time' => 'EscalationTime',
  'Title' => 'Escalated Tickets'
};
$Self->{'DashboardBackend'}->{'0120-TicketNew'} =  {
  'Attributes' => 'StateType=new;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All new tickets, these tickets have not been worked on yet',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'rw',
  'Time' => 'Age',
  'Title' => 'New Tickets'
};
$Self->{'DashboardBackend'}->{'0130-TicketOpen'} =  {
  'Attributes' => 'StateType=open;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'Created' => '1',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All open tickets, these tickets have already been worked on.',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'rw',
  'Time' => 'Age',
  'Title' => 'Open Tickets'
};
$Self->{'DashboardBackend'}->{'0140-RunningTicketProcess'} =  {
  'Attributes' => 'StateType=new;StateType=open;StateType=pending reminder;StateType=pending auto',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '0',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'DynamicField_ProcessManagementActivityID' => '2',
    'DynamicField_ProcessManagementProcessID' => '2',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All tickets with a reminder set where the reminder date has been reached',
  'Group' => '',
  'IsProcessWidget' => '1',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'rw',
  'Time' => 'UntilTime',
  'Title' => 'Running Process Tickets'
};
$Self->{'DashboardBackend'}->{'0210-MOTD'} =  {
  'Block' => 'ContentLarge',
  'Default' => '1',
  'Group' => '',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::MOTD',
  'Title' => 'This is ICA system, only applicable user '
};
$Self->{'DashboardBackend'}->{'0250-TicketStats'} =  {
  'Block' => 'ContentSmall',
  'CacheTTLLocal' => '30',
  'Changed' => '1',
  'Closed' => '1',
  'Default' => '1',
  'Group' => '',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketStatsGeneric',
  'Permission' => 'rw',
  'Title' => '7 Day Stats'
};
$Self->{'DashboardBackend'}->{'0260-TicketCalendar'} =  {
  'Block' => 'ContentSmall',
  'CacheTTL' => '2',
  'Default' => '1',
  'Group' => '',
  'Limit' => '6',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::Calendar',
  'OwnerOnly' => '',
  'Permission' => 'rw',
  'Title' => 'Upcoming Events'
};
$Self->{'DashboardBackend'}->{'0270-TicketQueueOverview'} =  {
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '2',
  'Default' => '1',
  'Description' => 'Provides a matrix overview of the tickets per state per queue',
  'Group' => '',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketQueueOverview',
  'Permission' => 'rw',
  'QueuePermissionGroup' => '',
  'Sort' => 'SortBy=Age;OrderBy=Up',
  'States' => {
    '1' => 'new',
    '4' => 'open',
    '6' => 'pending reminder'
  },
  'Title' => 'Ticket Queue Overview'
};
$Self->{'DashboardBackend'}->{'0280-DashboardEventsTicketCalendar'} =  {
  'Block' => 'ContentLarge',
  'CacheTTL' => '0',
  'Default' => '0',
  'Group' => '',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::EventsTicketCalendar',
  'Title' => 'Events Ticket Calendar'
};
$Self->{'DashboardBackend'}->{'0322-MyLastChangedTickets'} =  {
  'Block' => 'ContentSmall',
  'CacheTTL' => '2',
  'Default' => '1',
  'Group' => '',
  'Limit' => '6',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::MyLastChangedTickets',
  'OwnerOnly' => '',
  'Permission' => 'rw',
  'Title' => 'My last changed tickets'
};
$Self->{'DashboardBackend'}->{'0390-UserOutOfOffice'} =  {
  'Block' => 'ContentSmall',
  'CacheTTLLocal' => '5',
  'Default' => '1',
  'Description' => 'Out of Office users.',
  'Group' => '',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::UserOutOfOffice',
  'SortBy' => 'UserFullname',
  'Title' => 'Out Of Office'
};
$Self->{'DashboardBackend'}->{'0398-FAQ-LastChange'} =  {
  'Block' => 'ContentSmall',
  'Default' => '1',
  'Description' => '',
  'Group' => '',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::FAQ',
  'Title' => 'Latest updated FAQ articles',
  'Type' => 'LastChange'
};
$Self->{'DashboardBackend'}->{'0399-FAQ-LastCreate'} =  {
  'Block' => 'ContentSmall',
  'Default' => '1',
  'Description' => '',
  'Group' => '',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::FAQ',
  'Title' => 'Latest created FAQ articles',
  'Type' => 'LastCreate'
};
$Self->{'DashboardBackend'}->{'0400-UserOnline'} =  {
  'Block' => 'ContentSmall',
  'CacheTTLLocal' => '5',
  'Default' => '0',
  'Description' => 'Logged in users.',
  'Filter' => 'Agent',
  'Group' => '',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::UserOnline',
  'ShowEmail' => '0',
  'SortBy' => 'UserFullname',
  'Title' => 'Logged-In Users'
};
$Self->{'DashboardBackend'}->{'0405-News'} =  {
  'Block' => 'ContentSmall',
  'CacheTTL' => '360',
  'Default' => '1',
  'Description' => 'News about OTOBO.',
  'Group' => 'admin',
  'Limit' => '6',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::News',
  'Title' => 'OTOBO News'
};
$Self->{'DashboardBackend'}->{'0500-AppointmentCalendar'} =  {
  'Block' => 'ContentSmall',
  'CacheTTLLocal' => '5',
  'Default' => '0',
  'Description' => 'Appointments',
  'Filter' => 'Today',
  'Group' => '',
  'IdleMinutes' => '60',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::AppointmentCalendar',
  'ShowEmail' => '0',
  'SortBy' => 'UserFullname',
  'Title' => 'Appointments'
};
$Self->{'DashboardBackend'}->{'0900-TicketMaster'} =  {
  'Attributes' => 'DynamicField_MasterSlave_Equals=Master;StateType=open;StateType=new;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All master tickets',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'rw',
  'Time' => 'Age',
  'Title' => 'Master Tickets'
};
$Self->{'DashboardBackend'}->{'0910-TicketSlave'} =  {
  'Attributes' => 'DynamicField_MasterSlave_Like=Slave*;StateType=open;StateType=new;',
  'Block' => 'ContentLarge',
  'CacheTTLLocal' => '0.5',
  'Default' => '1',
  'DefaultColumns' => {
    'Age' => '2',
    'Changed' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '1',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '1',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Description' => 'All slave tickets',
  'Filter' => 'All',
  'Group' => '',
  'Limit' => '10',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::Dashboard::TicketGeneric',
  'Permission' => 'rw',
  'Time' => 'Age',
  'Title' => 'Slave Tickets'
};
$Self->{'DashboardEventsTicketCalendar'}->{'CalendarWidth'} =  '95';
$Self->{'DashboardEventsTicketCalendar'}->{'Queues'} =  [
  'Raw'
];
$Self->{'DashboardEventsTicketCalendar::DynamicFieldEndTime'} =  'TicketCalendarEndTime';
$Self->{'DashboardEventsTicketCalendar::DynamicFieldStartTime'} =  'TicketCalendarStartTime';
$Self->{'DashboardEventsTicketCalendar::DynamicFieldsForEvents'} =  [
  'TicketCalendarStartTime',
  'TicketCalendarEndTime'
];
$Self->{'DashboardEventsTicketCalendar::TicketFieldsForEvents'} =  {
  'CustomerID' => 'Customer ID',
  'CustomerUserID' => 'Customer user',
  'Priority' => 'Priority',
  'Queue' => 'Queue',
  'SLA' => 'SLA',
  'Service' => 'Service',
  'State' => 'State',
  'Title' => 'Title',
  'Type' => 'Type'
};
$Self->{'DashboardMyLastChangedTickets::Limit'} =  '10';
$Self->{'DefaultColumnsScreens'}->{'CustomerTicketSearch'} =  {
  'Ticket::Frontend::CustomerTicketSearch###SearchOverviewDynamicField' => 'CustomerTicketSearch'
};
$Self->{'DefaultColumnsScreens'}->{'Framework'} =  {
  'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 'DashboardWidget CIC-TicketPendingReminder',
  'AgentCustomerInformationCenter::Backend###0110-CIC-TicketEscalation' => 'DashboardWidget CIC-TicketEscalation',
  'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew' => 'DashboardWidget CIC-TicketNew',
  'AgentCustomerInformationCenter::Backend###0130-CIC-TicketOpen' => 'DashboardWidget CIC-TicketOpen',
  'AgentCustomerUserInformationCenter::Backend###0100-CUIC-TicketPendingReminder' => 'DashboardWidget CUIC-TicketPendingReminder',
  'AgentCustomerUserInformationCenter::Backend###0110-CUIC-TicketEscalation' => 'DashboardWidget CUIC-TicketEscalation',
  'AgentCustomerUserInformationCenter::Backend###0120-CUIC-TicketNew' => 'DashboardWidget CUIC-TicketNew',
  'AgentCustomerUserInformationCenter::Backend###0130-CUIC-TicketOpen' => 'DashboardWidget CUIC-TicketOpen',
  'DashboardBackend###0100-TicketPendingReminder' => 'DashboardWidget TicketPendingReminder',
  'DashboardBackend###0110-TicketEscalation' => 'DashboardWidget TicketEscalation',
  'DashboardBackend###0120-TicketNew' => 'DashboardWidget TicketNew',
  'DashboardBackend###0130-TicketOpen' => 'DashboardWidget TicketOpen',
  'DashboardBackend###0140-RunningTicketProcess' => 'DashboardWidget RunningTicketProcess',
  'Ticket::Frontend::AgentTicketEscalationView###DefaultColumns' => 'AgentTicketEscalationView',
  'Ticket::Frontend::AgentTicketLockedView###DefaultColumns' => 'AgentTicketLockedView',
  'Ticket::Frontend::AgentTicketQueue###DefaultColumns' => 'AgentTicketQueue',
  'Ticket::Frontend::AgentTicketResponsibleView###DefaultColumns' => 'AgentTicketResponsibleView',
  'Ticket::Frontend::AgentTicketSearch###DefaultColumns' => 'AgentTicketSearch',
  'Ticket::Frontend::AgentTicketService###DefaultColumns' => 'AgentTicketService',
  'Ticket::Frontend::AgentTicketStatusView###DefaultColumns' => 'AgentTicketStatusView',
  'Ticket::Frontend::AgentTicketWatchView###DefaultColumns' => 'AgentTicketWatchView'
};
$Self->{'DefaultColumnsScreens'}->{'ITSMConfigurationManagement'} =  {
  'AgentCustomerInformationCenter::Backend###0060-CIC-ITSMConfigItemCustomerCompany' => 'DashboardWidget CIC-ITSMConfigItemCustomerCompany',
  'AgentCustomerUserInformationCenter::Backend###0060-CUIC-ITSMConfigItemCustomerUser' => 'DashboardWidget CUIC-ITSMConfigItemCustomerUser',
  'ITSMConfigItem::Frontend::AgentITSMConfigItem###DefaultColumns' => 'AgentITSMConfigItem',
  'ITSMConfigItem::Frontend::CustomerITSMConfigItem###DefaultColumns' => 'CustomerITSMConfigItem'
};
$Self->{'DefaultLanguage'} =  'en';
$Self->{'DefaultOverviewColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '1',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '1',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'DefaultTheme'} =  'Standard';
$Self->{'DefaultUsedLanguages'} =  {
  'ar_SA' => 'Arabic (Saudi Arabia)',
  'bg' => 'Bulgarian',
  'ca' => 'Catalan',
  'cs' => 'Czech',
  'da' => 'Danish',
  'de' => 'German',
  'el' => 'Greek',
  'en' => 'English (United States)',
  'en_CA' => 'English (Canada)',
  'en_GB' => 'English (United Kingdom)',
  'es' => 'Spanish',
  'es_CO' => 'Spanish (Colombia)',
  'es_MX' => 'Spanish (Mexico)',
  'et' => 'Estonian',
  'fa' => 'Persian',
  'fi' => 'Finnish',
  'fr' => 'French',
  'fr_CA' => 'French (Canada)',
  'gl' => 'Galician',
  'he' => 'Hebrew',
  'hi' => 'Hindi',
  'hr' => 'Croatian',
  'hu' => 'Hungarian',
  'id' => 'Indonesian',
  'it' => 'Italian',
  'ja' => 'Japanese',
  'ko' => 'Korean',
  'lt' => 'Lithuanian',
  'lv' => 'Latvian',
  'mk' => 'Macedonian',
  'ms' => 'Malay',
  'nb_NO' => 'Norwegian',
  'nl' => 'Dutch',
  'pl' => 'Polish',
  'pt' => 'Portuguese',
  'pt_BR' => 'Portuguese (Brasil)',
  'ro' => 'Romanian',
  'ru' => 'Russian',
  'sk_SK' => 'Slovak',
  'sl' => 'Slovenian',
  'sr_Cyrl' => 'Serbian Cyrillic',
  'sr_Latn' => 'Serbian Latin',
  'sv' => 'Swedish',
  'sw' => 'Swahili',
  'th_TH' => 'Thai',
  'tr' => 'Turkish',
  'uk' => 'Ukrainian',
  'vi_VN' => 'Vietnam',
  'zh_CN' => 'Chinese (Simplified)',
  'zh_TW' => 'Chinese (Traditional)'
};
$Self->{'DefaultUsedLanguagesNative'} =  {
  'ar_SA' => 'العَرَبِية‎',
  'bg' => 'Български',
  'ca' => 'Català',
  'cs' => 'Česky',
  'da' => 'Dansk',
  'de' => 'Deutsch',
  'el' => 'Ελληνικά',
  'en' => 'English (United States)',
  'en_CA' => 'English (Canada)',
  'en_GB' => 'English (United Kingdom)',
  'es' => 'Español',
  'es_CO' => 'Español (Colombia)',
  'es_MX' => 'Español (México)',
  'et' => 'Eesti',
  'fa' => 'فارسى',
  'fi' => 'Suomi',
  'fr' => 'Français',
  'fr_CA' => 'Français (Canada)',
  'gl' => 'Galego',
  'he' => 'עברית',
  'hi' => 'हिन्दी',
  'hr' => 'Hrvatski',
  'hu' => 'Magyar',
  'id' => 'Bahasa Indonesia',
  'it' => 'Italiano',
  'ja' => '日本語',
  'ko' => '한국어',
  'lt' => 'Lietuvių kalba',
  'lv' => 'Latvijas',
  'mk' => 'Mакедонски',
  'ms' => 'Melayu',
  'nb_NO' => 'Norsk bokmål',
  'nl' => 'Nederlandse',
  'pl' => 'Polski',
  'pt' => 'Português',
  'pt_BR' => 'Português Brasileiro',
  'ro' => 'Română',
  'ru' => 'Русский',
  'sk_SK' => 'Slovenčina',
  'sl' => 'Slovenščina',
  'sr_Cyrl' => 'Српски',
  'sr_Latn' => 'Srpski',
  'sv' => 'Svenska',
  'sw' => 'Kiswahili',
  'th_TH' => 'ภาษาไทย',
  'tr' => 'Türkçe',
  'uk' => 'Українська',
  'vi_VN' => 'ViɆt Nam',
  'zh_CN' => '简体中文',
  'zh_TW' => '正體中文'
};
$Self->{'DefaultViewLines'} =  '6000';
$Self->{'DefaultViewNewLine'} =  '90';
$Self->{'DemoSystem'} =  '0';
$Self->{'DisableContentSecurityPolicy'} =  '0';
$Self->{'DisableIFrameOriginRestricted'} =  '0';
$Self->{'DisableLoginAutocomplete'} =  '0';
$Self->{'DynamicField::EventModulePost'}->{'100-UpdateITSMChangeConditions'} =  {
  'Event' => '(DynamicFieldAdd|DynamicFieldUpdate|DynamicFieldDelete)',
  'Module' => 'Kernel::System::DynamicField::Event::UpdateITSMChangeConditions',
  'Transaction' => '0'
};
$Self->{'DynamicField::EventModulePost'}->{'200-DynamicFieldSync'} =  {
  'Event' => 'DynamicFieldUpdate',
  'Module' => 'Kernel::System::DynamicField::Event::ITSMConfigItemDefinitionSync',
  'Transaction' => '1'
};
$Self->{'DynamicField::EventModulePost'}->{'2400-RebuildACLPreselectionCache'} =  {
  'Event' => 'DefinitionCreate',
  'Module' => 'Kernel::System::ITSMConfigItem::Event::RebuildACLPreselectionCache'
};
$Self->{'DynamicField::EventModulePost'}->{'300-DeleteScriptFieldEvents'} =  {
  'Event' => 'DynamicFieldDelete',
  'Module' => 'Kernel::System::DynamicField::Event::DeleteScriptFieldEvents',
  'Transaction' => '1'
};
$Self->{'DynamicField::EventModulePost'}->{'400-UpdateSetFieldInclusions'} =  {
  'Event' => 'DynamicFieldAdd|DynamicFieldDelete|DynamicFieldUpdate',
  'Module' => 'Kernel::System::DynamicField::Event::UpdateSetFieldIncludedFields',
  'Transaction' => '1'
};
$Self->{'DynamicField::EventModulePost'}->{'8000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'DynamicField::Namespaces'} =  [
  'ITSMUPS',
  'ITSM',
  'ITSMNetworkInfo',
  'CPU',
  'ITSMIPNetwork',
  'ITSMStorage',
  'ITSMMemory',
  'ITSMSoftware',
  'Contract',
  'Contact',
  'ITSMStoragePartition',
  'ITSMServerSoftware',
  'ITSMDisplay',
  'ITSMClientSoftware',
  'ITSMCertificate',
  'ITSMAccounting',
  'ITSMLicense',
  'ITSMAppliance',
  'ITSMClient',
  'ITSMSIM',
  'ITSMPhone',
  'ITSMGraphicsCard',
  'ITSMOtherAccessories',
  'ITSMModel',
  'ITSMFormFactor',
  'Location',
  'ZTSM',
  'ZTSMOrganization',
  'ZTSMAppSystem',
  'ZTSMApprovalModel',
  'ZTSMSupportProfile',
  'ZTSMSupportAssignment',
  'ZTSMTechnologyProfile',
  'ZTSMServiceProfile',
  'ZTSMServiceSupportMap',
  'ZTSMSupportModel',
  'ZTSMSLAPolicy',
  'ZTSMPlatform',
  'ZTSMEnvironment',
  'ZTSMLocation',
  'ZTSMGovernanceRole',
  'ZFirewall',
  'ZTicket',
  'ZState',
  'ZBlue'
];
$Self->{'DynamicFieldDB::DisplayfieldHeaders'} =  [];
$Self->{'DynamicFieldDB::ExtendedValueStructure'} =  '1';
$Self->{'DynamicFieldScreens'}->{'Framework'} =  {
  'Ticket::Frontend::AgentTicketArticleEdit###DynamicField' => 'AgentTicketArticleEdit',
  'Ticket::Frontend::AgentTicketClose###DynamicField' => 'AgentTicketClose',
  'Ticket::Frontend::AgentTicketCompose###DynamicField' => 'AgentTicketCompose',
  'Ticket::Frontend::AgentTicketEmail###DynamicField' => 'AgentTicketEmail',
  'Ticket::Frontend::AgentTicketEmailOutbound###DynamicField' => 'AgentTicketEmailOutbound',
  'Ticket::Frontend::AgentTicketForward###DynamicField' => 'AgentTicketForward',
  'Ticket::Frontend::AgentTicketFreeText###DynamicField' => 'AgentTicketFreeText',
  'Ticket::Frontend::AgentTicketMove###DynamicField' => 'AgentTicketMove',
  'Ticket::Frontend::AgentTicketNote###DynamicField' => 'AgentTicketNote',
  'Ticket::Frontend::AgentTicketOwner###DynamicField' => 'AgentTicketOwner',
  'Ticket::Frontend::AgentTicketPending###DynamicField' => 'AgentTicketPending',
  'Ticket::Frontend::AgentTicketPhone###DynamicField' => 'AgentTicketPhone',
  'Ticket::Frontend::AgentTicketPhoneInbound###DynamicField' => 'AgentTicketPhoneInbound',
  'Ticket::Frontend::AgentTicketPhoneOutbound###DynamicField' => 'AgentTicketPhoneOutbound',
  'Ticket::Frontend::AgentTicketPrint###DynamicField' => 'AgentTicketPrint',
  'Ticket::Frontend::AgentTicketPriority###DynamicField' => 'AgentTicketPriority',
  'Ticket::Frontend::AgentTicketResponsible###DynamicField' => 'AgentTicketResponsible',
  'Ticket::Frontend::AgentTicketSearch###DynamicField' => 'AgentTicketSearch',
  'Ticket::Frontend::AgentTicketZoom###DynamicField' => 'AgentTicketZoom',
  'Ticket::Frontend::AgentTicketZoom###DynamicFieldWidgetDynamicField' => 'DynamicFieldWidgetDynamicField',
  'Ticket::Frontend::AgentTicketZoom###ProcessWidgetDynamicField' => 'ProcessWidgetDynamicField',
  'Ticket::Frontend::CustomerTicketMessage###DynamicField' => 'CustomerTicketMessage',
  'Ticket::Frontend::CustomerTicketOverview###DynamicField' => 'CustomerTicketOverview',
  'Ticket::Frontend::CustomerTicketPrint###DynamicField' => 'CustomerTicketPrint',
  'Ticket::Frontend::CustomerTicketSearch###DynamicField' => 'CustomerTicketSearch',
  'Ticket::Frontend::CustomerTicketZoom###DynamicField' => 'CustomerTicketZoom',
  'Ticket::Frontend::OverviewMedium###DynamicField' => 'OverviewMedium',
  'Ticket::Frontend::OverviewPreview###DynamicField' => 'OverviewPreview',
  'Ticket::Frontend::OverviewSmall###DynamicField' => 'OverviewSmall'
};
$Self->{'DynamicFieldScreens'}->{'ITSMChangeManagement'} =  {
  'ITSMChange::Frontend::AgentITSMChangeAdd###DynamicField' => 'AgentITSMChangeAdd',
  'ITSMChange::Frontend::AgentITSMChangeEdit###DynamicField' => 'AgentITSMChangeEdit',
  'ITSMChange::Frontend::AgentITSMChangePrint###DynamicField' => 'AgentITSMChangePrint',
  'ITSMChange::Frontend::AgentITSMChangeSearch###DynamicField' => 'AgentITSMChangeSearch',
  'ITSMChange::Frontend::AgentITSMChangeZoom###DynamicField' => 'AgentITSMChangeZoom',
  'ITSMChange::Frontend::AgentITSMWorkOrderAdd###DynamicField' => 'AgentITSMWorkOrderAdd',
  'ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit###DynamicField' => 'AgentITSMWorkOrderEdit',
  'ITSMWorkOrder::Frontend::AgentITSMWorkOrderReport###DynamicField' => 'AgentITSMWorkOrderReport',
  'ITSMWorkOrder::Frontend::AgentITSMWorkOrderZoom###DynamicField' => 'AgentITSMWorkOrderZoom'
};
$Self->{'DynamicFieldScreens'}->{'ITSMConfigurationManagement'} =  {
  'ITSMConfigItem::Frontend::AgentITSMConfigItemEdit###DynamicField' => 'AgentITSMConfigItemEdit',
  'ITSMConfigItem::Frontend::AgentITSMConfigItemPrint###DynamicField' => 'AgentITSMConfigItemPrint',
  'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch###DynamicField' => 'AgentITSMConfigItemSearch',
  'ITSMConfigItem::Frontend::AgentITSMConfigItemZoom###DynamicField' => 'AgentITSMConfigItemZoom',
  'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch###DynamicField' => 'CustomerITSMConfigItemSearch'
};
$Self->{'DynamicFieldScreens'}->{'ITSMIncidentProblemManagement'} =  {
  'Ticket::Frontend::AgentTicketAddtlITSMField###DynamicField' => 'AgentTicketAddtlITSMField',
  'Ticket::Frontend::AgentTicketDecision###DynamicField' => 'AgentTicketDecision'
};
$Self->{'DynamicFieldScreens'}->{'ServiceCatalog'} =  {
  'CustomerDashboard::Configuration::ServiceCatalog###DynamicField' => 'CustomerDashboardTile ServiceCatalog'
};
$Self->{'DynamicFieldScreens::ObjectTypes'}->{'ITSMConfigurationManagement'} =  [
  'ITSMConfigItem'
];
$Self->{'DynamicFields::Driver'}->{'ActivityID'} =  {
  'ConfigDialog' => 'AdminDynamicFieldText',
  'DisabledAdd' => '1',
  'DisplayName' => 'ActivityID',
  'Module' => 'Kernel::System::DynamicField::Driver::ProcessManagement::ActivityID'
};
$Self->{'DynamicFields::Driver'}->{'Agent'} =  {
  'ConfigDialog' => 'AdminDynamicFieldReference',
  'DisplayName' => 'Agent',
  'Module' => 'Kernel::System::DynamicField::Driver::Agent',
  'ObjectTypes' => [
    'Article',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'Attachment'} =  {
  'ConfigDialog' => 'AdminDynamicFieldAttachment',
  'DisplayName' => 'Attachment',
  'ItemSeparator' => ', ',
  'Module' => 'Kernel::System::DynamicField::Driver::Attachment',
  'ObjectTypes' => [
    'Article',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'Checkbox'} =  {
  'ConfigDialog' => 'AdminDynamicFieldCheckbox',
  'DisplayName' => 'Checkbox',
  'Module' => 'Kernel::System::DynamicField::Driver::Checkbox',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'ConfigItem'} =  {
  'ConfigDialog' => 'AdminDynamicFieldReference',
  'DisplayName' => 'ConfigItem',
  'Module' => 'Kernel::System::DynamicField::Driver::ConfigItem'
};
$Self->{'DynamicFields::Driver'}->{'ConfigItemVersion'} =  {
  'ConfigDialog' => 'AdminDynamicFieldReference',
  'DisplayName' => 'ConfigItem Version',
  'Module' => 'Kernel::System::DynamicField::Driver::ConfigItemVersion'
};
$Self->{'DynamicFields::Driver'}->{'ContactWD'} =  {
  'ConfigDialog' => 'AdminDynamicFieldContactWD',
  'DisplayName' => 'Contact with data',
  'Module' => 'Kernel::System::DynamicField::Driver::ContactWD',
  'ObjectTypes' => [
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'CustomerCompany'} =  {
  'ConfigDialog' => 'AdminDynamicFieldReference',
  'DisplayName' => 'CustomerCompany',
  'Module' => 'Kernel::System::DynamicField::Driver::CustomerCompany',
  'ObjectTypes' => [
    'Article',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'CustomerUser'} =  {
  'ConfigDialog' => 'AdminDynamicFieldReference',
  'DisplayName' => 'CustomerUser',
  'Module' => 'Kernel::System::DynamicField::Driver::CustomerUser',
  'ObjectTypes' => [
    'Article',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'Database'} =  {
  'ConfigDialog' => 'AdminDynamicFieldDB',
  'DisplayName' => 'Database',
  'Module' => 'Kernel::System::DynamicField::Driver::Database',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'Date'} =  {
  'ConfigDialog' => 'AdminDynamicFieldDateTime',
  'DisplayName' => 'Date',
  'Module' => 'Kernel::System::DynamicField::Driver::Date',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'DateTime'} =  {
  'ConfigDialog' => 'AdminDynamicFieldDateTime',
  'DisplayName' => 'Date / Time',
  'Module' => 'Kernel::System::DynamicField::Driver::DateTime',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'Dropdown'} =  {
  'ConfigDialog' => 'AdminDynamicFieldDropdown',
  'DisplayName' => 'Dropdown',
  'Module' => 'Kernel::System::DynamicField::Driver::Dropdown',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'FAQ'} =  {
  'ConfigDialog' => 'AdminDynamicFieldReference',
  'DisplayName' => 'FAQ',
  'Module' => 'Kernel::System::DynamicField::Driver::FAQ',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'GeneralCatalog'} =  {
  'ConfigDialog' => 'AdminDynamicFieldGeneralCatalog',
  'DisplayName' => 'GeneralCatalog',
  'Module' => 'Kernel::System::DynamicField::Driver::GeneralCatalog'
};
$Self->{'DynamicFields::Driver'}->{'Lens'} =  {
  'ConfigDialog' => 'AdminDynamicFieldLens',
  'DisplayName' => 'Lens',
  'Module' => 'Kernel::System::DynamicField::Driver::Lens',
  'ObjectTypes' => [
    'Article',
    'CustomerCompany',
    'CustomerUser',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'MasterSlave'} =  {
  'ConfigDialog' => 'AdminDynamicFieldMasterSlave',
  'DisabledAdd' => '1',
  'DisplayName' => 'Master / Slave',
  'Module' => 'Kernel::System::DynamicField::Driver::MasterSlave'
};
$Self->{'DynamicFields::Driver'}->{'Multiselect'} =  {
  'ConfigDialog' => 'AdminDynamicFieldMultiselect',
  'DisplayName' => 'Multiselect',
  'ItemSeparator' => ', ',
  'Module' => 'Kernel::System::DynamicField::Driver::Multiselect',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'ProcessID'} =  {
  'ConfigDialog' => 'AdminDynamicFieldText',
  'DisabledAdd' => '1',
  'DisplayName' => 'ProcessID',
  'Module' => 'Kernel::System::DynamicField::Driver::ProcessManagement::ProcessID'
};
$Self->{'DynamicFields::Driver'}->{'Queue'} =  {
  'ConfigDialog' => 'AdminDynamicFieldQueue',
  'DisplayName' => 'Queue',
  'Module' => 'Kernel::System::DynamicField::Driver::Queue'
};
$Self->{'DynamicFields::Driver'}->{'RichText'} =  {
  'ConfigDialog' => 'AdminDynamicFieldText',
  'DisplayName' => 'Richtext',
  'Module' => 'Kernel::System::DynamicField::Driver::RichText',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'SLA'} =  {
  'ConfigDialog' => 'AdminDynamicFieldSLA',
  'DisplayName' => 'SLA',
  'Module' => 'Kernel::System::DynamicField::Driver::SLA'
};
$Self->{'DynamicFields::Driver'}->{'ScriptTemplateToolkit'} =  {
  'ConfigDialog' => 'AdminDynamicFieldScript',
  'DisplayName' => 'Script (Template Toolkit)',
  'Module' => 'Kernel::System::DynamicField::Driver::ScriptTemplateToolkit',
  'ObjectTypes' => [
    'Article',
    'CustomerCompany',
    'CustomerUser',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'Service'} =  {
  'ConfigDialog' => 'AdminDynamicFieldReference',
  'DisplayName' => 'Service',
  'Module' => 'Kernel::System::DynamicField::Driver::Service',
  'ObjectTypes' => [
    'Article',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'Set'} =  {
  'ConfigDialog' => 'AdminDynamicFieldSet',
  'DisplayName' => 'Dynamic Field Set',
  'Module' => 'Kernel::System::DynamicField::Driver::Set',
  'ObjectTypes' => [
    'Article',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'Text'} =  {
  'ConfigDialog' => 'AdminDynamicFieldText',
  'DisplayName' => 'Text',
  'Module' => 'Kernel::System::DynamicField::Driver::Text',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'TextArea'} =  {
  'ConfigDialog' => 'AdminDynamicFieldText',
  'DisplayName' => 'Textarea',
  'Module' => 'Kernel::System::DynamicField::Driver::TextArea',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'Ticket'} =  {
  'ConfigDialog' => 'AdminDynamicFieldReference',
  'DisplayName' => 'Ticket',
  'Module' => 'Kernel::System::DynamicField::Driver::Ticket',
  'ObjectTypes' => [
    'Article',
    'ITSMConfigItem',
    'Ticket'
  ]
};
$Self->{'DynamicFields::Driver'}->{'Title'} =  {
  'ConfigDialog' => 'AdminDynamicFieldTitle',
  'DisplayName' => 'Title',
  'Module' => 'Kernel::System::DynamicField::Driver::Title',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Driver'}->{'Type'} =  {
  'ConfigDialog' => 'AdminDynamicFieldType',
  'DisplayName' => 'Type',
  'Module' => 'Kernel::System::DynamicField::Driver::Type'
};
$Self->{'DynamicFields::Driver'}->{'WebService'} =  {
  'ConfigDialog' => 'AdminDynamicFieldWebService',
  'DisplayName' => 'Web Service',
  'Module' => 'Kernel::System::DynamicField::Driver::WebService',
  'ObjectTypes' => []
};
$Self->{'DynamicFields::Extension::Backend'}->{'107-Attachment'} =  {
  'Module' => 'Kernel::System::DynamicField::AttachmentBackend'
};
$Self->{'DynamicFields::ObjectType'}->{'Article'} =  {
  'DisplayName' => 'Article',
  'Module' => 'Kernel::System::DynamicField::ObjectType::Article',
  'Prio' => '110'
};
$Self->{'DynamicFields::ObjectType'}->{'CustomerCompany'} =  {
  'DisplayName' => 'Customer',
  'Module' => 'Kernel::System::DynamicField::ObjectType::CustomerCompany',
  'Prio' => '120',
  'UseObjectName' => '1'
};
$Self->{'DynamicFields::ObjectType'}->{'CustomerUser'} =  {
  'DisplayName' => 'Customer User',
  'Module' => 'Kernel::System::DynamicField::ObjectType::CustomerUser',
  'Prio' => '130',
  'UseObjectName' => '1'
};
$Self->{'DynamicFields::ObjectType'}->{'FAQ'} =  {
  'DisplayName' => 'FAQ',
  'Module' => 'Kernel::System::DynamicField::ObjectType::FAQ',
  'Prio' => '200'
};
$Self->{'DynamicFields::ObjectType'}->{'ITSMChange'} =  {
  'DisplayName' => 'ITSMChange',
  'Module' => 'Kernel::System::DynamicField::ObjectType::ITSMChange',
  'Prio' => '450'
};
$Self->{'DynamicFields::ObjectType'}->{'ITSMConfigItem'} =  {
  'DisplayName' => 'ITSM ConfigItem',
  'Module' => 'Kernel::System::DynamicField::ObjectType::ITSMConfigItem',
  'Prio' => '115'
};
$Self->{'DynamicFields::ObjectType'}->{'ITSMWorkOrder'} =  {
  'DisplayName' => 'ITSMWorkOrder',
  'Module' => 'Kernel::System::DynamicField::ObjectType::ITSMWorkOrder',
  'Prio' => '460'
};
$Self->{'DynamicFields::ObjectType'}->{'Service'} =  {
  'DisplayName' => 'Service',
  'Module' => 'Kernel::System::DynamicField::ObjectType::Service',
  'Prio' => '140',
  'UseObjectName' => '1'
};
$Self->{'DynamicFields::ObjectType'}->{'Ticket'} =  {
  'DisplayName' => 'Ticket',
  'Module' => 'Kernel::System::DynamicField::ObjectType::Ticket',
  'Prio' => '100'
};
$Self->{'EditAnotherUsersPreferencesGroup'} =  'admin';
$Self->{'Elasticsearch::ArticleIndexCreationSettings'} =  {
  'NR' => '0',
  'NS' => '1'
};
$Self->{'Elasticsearch::CustomerCompanySearchFields'} =  [
  'CustomerCompanyURL',
  'CustomerCompanyName',
  'CustomerCompanyStreet',
  'CustomerID',
  'CustomerCompanyZIP',
  'CustomerCompanyCity',
  'CustomerCompanyCountry',
  'CustomerCompanyComment'
];
$Self->{'Elasticsearch::CustomerCompanyStoreFields'} =  [
  'CustomerID'
];
$Self->{'Elasticsearch::CustomerUserSearchFields'} =  [
  'UserFirstname',
  'UserLastname',
  'UserEmail',
  'UserLogin',
  'UserCustomerID'
];
$Self->{'Elasticsearch::CustomerUserStoreFields'} =  [
  'UserLogin',
  'UserCustomerID'
];
$Self->{'Elasticsearch::ExcludedQueues'} =  [
  'Junk'
];
$Self->{'Elasticsearch::IngestAttachmentFormat'} =  [
  'pdf',
  'txt',
  'rtf',
  'csv',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'odt',
  'ods',
  'odp'
];
$Self->{'Elasticsearch::IngestMaxFilesize'} =  '50000000';
$Self->{'Elasticsearch::MaxArticleSearch'} =  '10000';
$Self->{'Elasticsearch::QuickSearchShow'}->{'CustomerCompany'} =  {
  'AttributeHeader' => {
    'CustomerCompanyComment' => 'Comment',
    'CustomerCompanyName' => 'Customer Name',
    'CustomerID' => 'Customer ID'
  },
  'Attributes' => [
    'CustomerCompanyName',
    'CustomerID',
    'CustomerCompanyComment'
  ],
  'Count' => '5'
};
$Self->{'Elasticsearch::QuickSearchShow'}->{'CustomerUser'} =  {
  'AttributeHeader' => {
    'UserEmail' => 'Email',
    'UserFirstname' => 'Firstname',
    'UserLastname' => 'Lastname',
    'UserLogin' => 'Login'
  },
  'Attributes' => [
    'UserLogin',
    'UserFirstname',
    'UserLastname',
    'UserEmail'
  ],
  'Count' => '5'
};
$Self->{'Elasticsearch::QuickSearchShow'}->{'Ticket'} =  {
  'AttributeHeader' => {
    'Age' => 'Age',
    'Queue' => 'Queue',
    'TicketNumber' => 'Ticket Number',
    'Title' => 'Ticket Title'
  },
  'Attributes' => [
    'TicketNumber',
    'Title',
    'Queue',
    'Age'
  ],
  'Count' => '10'
};
$Self->{'Elasticsearch::TicketSearchFields'} =  {
  'Article' => [
    'From',
    'To',
    'Body',
    'Subject'
  ],
  'Attachment' => [
    'Content',
    'Filename'
  ],
  'DynamicField' => [],
  'Ticket' => [
    'Title',
    'TicketNumber'
  ]
};
$Self->{'Elasticsearch::TicketStoreFields'} =  {
  'Article' => [],
  'DynamicField' => [],
  'Ticket' => [
    'TicketID',
    'TicketNumber',
    'Created',
    'Age',
    'GroupID',
    'QueueID',
    'Title',
    'CustomerID',
    'CustomerUserID'
  ]
};
$Self->{'EscalationSuspendCancelEscalation'} =  '0';
$Self->{'EscalationSuspendLoopProtection'} =  '500';
$Self->{'Events'}->{'Appointment'} =  [
  'AppointmentCreate',
  'AppointmentUpdate',
  'AppointmentDelete',
  'AppointmentNotification'
];
$Self->{'Events'}->{'Article'} =  [
  'ArticleCreate',
  'ArticleUpdate',
  'ArticleSend',
  'ArticleBounce',
  'ArticleAgentNotification',
  'ArticleCustomerNotification',
  'ArticleAutoResponse',
  'ArticleFlagSet',
  'ArticleFlagDelete',
  'ArticleEmailSendingQueued',
  'ArticleEmailSendingSent',
  'ArticleEmailSendingError',
  'ArticleTransmissionErrorCreate',
  'ArticleTransmissionErrorUpdate'
];
$Self->{'Events'}->{'Calendar'} =  [
  'CalendarCreate',
  'CalendarUpdate'
];
$Self->{'Events'}->{'CustomerCompany'} =  [
  'CustomerCompanyAdd',
  'CustomerCompanyUpdate'
];
$Self->{'Events'}->{'CustomerUser'} =  [
  'CustomerUserAdd',
  'CustomerUserUpdate'
];
$Self->{'Events'}->{'DynamicField'} =  [
  'DynamicFieldAdd',
  'DynamicFieldUpdate',
  'DynamicFieldDelete'
];
$Self->{'Events'}->{'ITSMChange'} =  [
  'ChangeAddPre',
  'ChangeAddPost',
  'ChangeUpdatePre',
  'ChangeUpdatePost',
  'ChangeCABUpdatePre',
  'ChangeCABUpdatePost',
  'ChangeCABDeletePre',
  'ChangeCABDeletePost',
  'ChangeDeletePre',
  'ChangeDeletePost',
  'ChangeAttachmentAddPost',
  'ChangeAttachmentDeletePost'
];
$Self->{'Events'}->{'ITSMConfigItem'} =  [
  'ConfigItemCreate',
  'ConfigItemUpdate',
  'VersionCreate',
  'DeploymentStateUpdate',
  'IncidentStateUpdate',
  'ConfigItemDelete',
  'NameUpdate',
  'AttachmentAddPost',
  'AttachmentDeletePost',
  'VersionDelete',
  'VersionUpdate',
  'GroupUpdate'
];
$Self->{'Events'}->{'ITSMWorkOrder'} =  [
  'WorkOrderAddPre',
  'WorkOrderAddPost',
  'WorkOrderUpdatePre',
  'WorkOrderUpdatePost',
  'WorkOrderDeletePre',
  'WorkOrderDeletePost',
  'WorkOrderAttachmentAddPost',
  'WorkOrderAttachmentDeletePost',
  'WorkOrderReportAttachmentAddPost',
  'WorkOrderReportAttachmentDeletePost'
];
$Self->{'Events'}->{'LinkObject'} =  [
  'LinkObjectLinkAdd',
  'LinkObjectLinkDelete'
];
$Self->{'Events'}->{'Package'} =  [
  'PackageInstall',
  'PackageReinstall',
  'PackageUpgrade',
  'PackageUninstall'
];
$Self->{'Events'}->{'Queue'} =  [
  'QueueCreate',
  'QueueUpdate'
];
$Self->{'Events'}->{'Ticket'} =  [
  'TicketCreate',
  'TicketDelete',
  'TicketTitleUpdate',
  'TicketUnlockTimeoutUpdate',
  'TicketQueueUpdate',
  'TicketTypeUpdate',
  'TicketServiceUpdate',
  'TicketSLAUpdate',
  'TicketCustomerUpdate',
  'TicketPendingTimeUpdate',
  'TicketLockUpdate',
  'TicketArchiveFlagUpdate',
  'TicketStateUpdate',
  'TicketOwnerUpdate',
  'TicketResponsibleUpdate',
  'TicketPriorityUpdate',
  'HistoryAdd',
  'HistoryDelete',
  'TicketAccountTime',
  'TicketMerge',
  'TicketSubscribe',
  'TicketUnsubscribe',
  'TicketFlagSet',
  'TicketFlagDelete',
  'EscalationResponseTimeNotifyBefore',
  'EscalationUpdateTimeNotifyBefore',
  'EscalationSolutionTimeNotifyBefore',
  'EscalationResponseTimeStart',
  'EscalationUpdateTimeStart',
  'EscalationSolutionTimeStart',
  'EscalationResponseTimeStop',
  'EscalationUpdateTimeStop',
  'EscalationSolutionTimeStop',
  'NotificationNewTicket',
  'NotificationFollowUp',
  'NotificationLockTimeout',
  'NotificationOwnerUpdate',
  'NotificationResponsibleUpdate',
  'NotificationAddNote',
  'NotificationMove',
  'NotificationPendingReminder',
  'NotificationEscalation',
  'NotificationEscalationNotifyBefore',
  'NotificationServiceUpdate',
  'ArticleEdit'
];
$Self->{'FAQ::Agent::StateTypes'} =  [
  'internal',
  'external',
  'public'
];
$Self->{'FAQ::Approval::IncludeInternal'} =  '1';
$Self->{'FAQ::ApprovalGroup'} =  'users';
$Self->{'FAQ::ApprovalQueue'} =  'FAQ_Approval';
$Self->{'FAQ::ApprovalRequired'} =  '0';
$Self->{'FAQ::ApprovalTicketBody'} =  'Hi,

a new FAQ article needs your approval before it can be published.

  FAQ#   : <OTOBO_FAQ_NUMBER>
  Title  : <OTOBO_FAQ_TITLE>
  Author : <OTOBO_FAQ_AUTHOR>
  State  : <OTOBO_FAQ_STATE>

If you want to do this, click on this link:

<OTOBO_CONFIG_HttpType>://<OTOBO_CONFIG_FQDN>/<OTOBO_CONFIG_ScriptAlias>index.pl?Action=AgentFAQEdit;ItemID=<OTOBO_FAQ_ITEMID>

Your OTOBO Notification Master
            ';
$Self->{'FAQ::ApprovalTicketDefaultState'} =  'new';
$Self->{'FAQ::ApprovalTicketPriority'} =  '3 normal';
$Self->{'FAQ::ApprovalTicketSubject'} =  'FAQ approval required for FAQ# <OTOBO_FAQ_NUMBER>';
$Self->{'FAQ::ApprovalTicketType'} =  'Unclassified';
$Self->{'FAQ::CacheTTL'} =  '172800';
$Self->{'FAQ::Customer::RelatedArticles::Enabled'} =  '1';
$Self->{'FAQ::Customer::RelatedArticlesOnServiceOnly'} =  '0';
$Self->{'FAQ::Customer::StateTypes'} =  [
  'external',
  'public'
];
$Self->{'FAQ::Default::RootCategoryComment'} =  'default comment';
$Self->{'FAQ::Default::RootCategoryName'} =  'FAQ';
$Self->{'FAQ::Default::State'} =  'internal (agent)';
$Self->{'FAQ::Explorer::ItemList::VotingResultColors'} =  {
  '100' => 'green',
  '30' => 'red',
  '70' => 'orange'
};
$Self->{'FAQ::Explorer::ItemList::VotingResultDecimalPlaces'} =  '2';
$Self->{'FAQ::Explorer::LastChange::Limit'} =  '3';
$Self->{'FAQ::Explorer::LastChange::Show'} =  {
  'external' => 'external (customer)',
  'internal' => 'internal (agent)',
  'public' => 'public (public)'
};
$Self->{'FAQ::Explorer::LastChange::ShowSubCategoryItems'} =  '1';
$Self->{'FAQ::Explorer::LastCreate::Limit'} =  '3';
$Self->{'FAQ::Explorer::LastCreate::Show'} =  {
  'external' => 'external (customer)',
  'internal' => 'internal (agent)',
  'public' => 'public (public)'
};
$Self->{'FAQ::Explorer::LastCreate::ShowSubCategoryItems'} =  '1';
$Self->{'FAQ::Explorer::Path::Show'} =  '1';
$Self->{'FAQ::Explorer::QuickSearch::Show'} =  {
  'public' => 'public (public)'
};
$Self->{'FAQ::Explorer::Top10::Limit'} =  '10';
$Self->{'FAQ::Explorer::Top10::Show'} =  {
  'external' => 'external (customer)',
  'internal' => 'internal (agent)',
  'public' => 'public (public)'
};
$Self->{'FAQ::Explorer::Top10::ShowSubCategoryItems'} =  '1';
$Self->{'FAQ::FAQHook'} =  'FAQ#';
$Self->{'FAQ::Frontend::AgentFAQAdd'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::AgentFAQAdd'}->{'RichTextHeight'} =  '320';
$Self->{'FAQ::Frontend::AgentFAQAdd'}->{'RichTextWidth'} =  '620';
$Self->{'FAQ::Frontend::AgentFAQEdit'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::AgentFAQEdit'}->{'RichTextHeight'} =  '320';
$Self->{'FAQ::Frontend::AgentFAQEdit'}->{'RichTextWidth'} =  '620';
$Self->{'FAQ::Frontend::AgentFAQExplorer'}->{'Order::Default'} =  'Down';
$Self->{'FAQ::Frontend::AgentFAQExplorer'}->{'SearchLimit'} =  '200';
$Self->{'FAQ::Frontend::AgentFAQExplorer'}->{'ShowColumns'} =  {
  'Category' => '0',
  'Changed' => '0',
  'Language' => '1',
  'State' => '1',
  'Title' => '1',
  'Valid' => '1'
};
$Self->{'FAQ::Frontend::AgentFAQExplorer'}->{'ShowInvalidFAQItems'} =  '0';
$Self->{'FAQ::Frontend::AgentFAQExplorer'}->{'SortBy::Default'} =  'FAQID';
$Self->{'FAQ::Frontend::AgentFAQJournal'}->{'JournalLimit'} =  '200';
$Self->{'FAQ::Frontend::AgentFAQJournal'}->{'ShowColumns'} =  {
  'Category' => '1',
  'Name' => '1',
  'Time' => '1',
  'Title' => '1',
  'Valid' => '1'
};
$Self->{'FAQ::Frontend::AgentFAQPrint'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::AgentFAQSearch'}->{'Defaults'}->{'Fulltext'} =  '';
$Self->{'FAQ::Frontend::AgentFAQSearch'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::AgentFAQSearch'}->{'Order::Default'} =  'Down';
$Self->{'FAQ::Frontend::AgentFAQSearch'}->{'SearchCSVDynamicField'} =  {};
$Self->{'FAQ::Frontend::AgentFAQSearch'}->{'SearchLimit'} =  '200';
$Self->{'FAQ::Frontend::AgentFAQSearch'}->{'ShowColumns'} =  {
  'Category' => '1',
  'Changed' => '1',
  'Language' => '1',
  'State' => '1',
  'Title' => '1',
  'Valid' => '1'
};
$Self->{'FAQ::Frontend::AgentFAQSearch'}->{'SortBy::Default'} =  'FAQID';
$Self->{'FAQ::Frontend::AgentFAQZoom'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::AgentHTMLFieldHeightDefault'} =  '100';
$Self->{'FAQ::Frontend::AgentHTMLFieldHeightMax'} =  '2500';
$Self->{'FAQ::Frontend::CustomerFAQExplorer'}->{'Order::Default'} =  'Down';
$Self->{'FAQ::Frontend::CustomerFAQExplorer'}->{'SearchLimit'} =  '200';
$Self->{'FAQ::Frontend::CustomerFAQExplorer'}->{'SearchPageShown'} =  '20';
$Self->{'FAQ::Frontend::CustomerFAQExplorer'}->{'SortBy::Default'} =  'FAQID';
$Self->{'FAQ::Frontend::CustomerFAQOverview'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::CustomerFAQPrint'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::CustomerFAQRelatedArticles'}->{'DefaultLanguages'} =  [
  'en'
];
$Self->{'FAQ::Frontend::CustomerFAQRelatedArticles'}->{'ShowLimit'} =  '10';
$Self->{'FAQ::Frontend::CustomerFAQRelatedArticles'}->{'VoteStarsVisible'} =  '4';
$Self->{'FAQ::Frontend::CustomerFAQSearch'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::CustomerFAQSearch'}->{'Order::Default'} =  'Down';
$Self->{'FAQ::Frontend::CustomerFAQSearch'}->{'SearchCSVDynamicField'} =  {};
$Self->{'FAQ::Frontend::CustomerFAQSearch'}->{'SearchLimit'} =  '200';
$Self->{'FAQ::Frontend::CustomerFAQSearch'}->{'SearchPageShown'} =  '40';
$Self->{'FAQ::Frontend::CustomerFAQSearch'}->{'SortBy::Default'} =  'FAQID';
$Self->{'FAQ::Frontend::CustomerFAQZoom'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::CustomerHTMLFieldHeightDefault'} =  '100';
$Self->{'FAQ::Frontend::CustomerHTMLFieldHeightMax'} =  '2500';
$Self->{'FAQ::Frontend::JournalOverview'}->{'Small'} =  {
  'Module' => 'Kernel::Output::HTML::FAQJournalOverview::Small',
  'Name' => 'Small',
  'NameShort' => 'S'
};
$Self->{'FAQ::Frontend::MenuModule'}->{'000-Back'} =  {
  'Action' => '',
  'Description' => 'Back',
  'Link' => '[% Env("LastScreenOverview") %]',
  'Module' => 'Kernel::Output::HTML::FAQMenu::Generic',
  'Name' => 'Back',
  'Target' => 'Back'
};
$Self->{'FAQ::Frontend::MenuModule'}->{'010-Edit'} =  {
  'Action' => 'AgentFAQEdit',
  'Description' => 'Edit this FAQ',
  'Link' => 'Action=AgentFAQEdit;ItemID=[% Data.ItemID | html %];ScreenType=Popup',
  'Module' => 'Kernel::Output::HTML::FAQMenu::Generic',
  'Name' => 'Edit',
  'Target' => 'PopUp'
};
$Self->{'FAQ::Frontend::MenuModule'}->{'020-History'} =  {
  'Action' => 'AgentFAQHistory',
  'Description' => 'History of this FAQ',
  'Link' => 'Action=AgentFAQHistory;ItemID=[% Data.ItemID | html %]',
  'Module' => 'Kernel::Output::HTML::FAQMenu::Generic',
  'Name' => 'History',
  'Target' => 'PopUp'
};
$Self->{'FAQ::Frontend::MenuModule'}->{'030-Print'} =  {
  'Action' => 'AgentFAQPrint',
  'Description' => 'Print this FAQ',
  'Link' => 'Action=AgentFAQPrint;ItemID=[% Data.ItemID | html %]',
  'LinkParam' => 'target="print_FAQ"',
  'Module' => 'Kernel::Output::HTML::FAQMenu::Generic',
  'Name' => 'Print',
  'Target' => 'PopUp'
};
$Self->{'FAQ::Frontend::MenuModule'}->{'040-Link'} =  {
  'Action' => 'AgentLinkObject',
  'Description' => 'Link another object to this FAQ item',
  'Link' => 'Action=AgentLinkObject;SourceObject=FAQ;SourceKey=[% Data.ItemID | html %]',
  'Module' => 'Kernel::Output::HTML::FAQMenu::Generic',
  'Name' => 'Link',
  'Target' => 'PopUp'
};
$Self->{'FAQ::Frontend::MenuModule'}->{'050-Delete'} =  {
  'Action' => 'AgentFAQDelete',
  'Description' => 'Delete this FAQ',
  'Link' => 'Action=AgentFAQDelete;ItemID=[% Data.ItemID | html %]',
  'Module' => 'Kernel::Output::HTML::FAQMenu::Delete',
  'Name' => 'Delete',
  'Target' => 'ConfirmationDialog'
};
$Self->{'FAQ::Frontend::Overview'}->{'Small'} =  {
  'Module' => 'Kernel::Output::HTML::FAQOverview::Small',
  'Name' => 'Small',
  'NameShort' => 'S'
};
$Self->{'FAQ::Frontend::OverviewSmall'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::PublicFAQExplorer'}->{'Order::Default'} =  'Down';
$Self->{'FAQ::Frontend::PublicFAQExplorer'}->{'SearchLimit'} =  '200';
$Self->{'FAQ::Frontend::PublicFAQExplorer'}->{'SearchPageShown'} =  '40';
$Self->{'FAQ::Frontend::PublicFAQExplorer'}->{'SortBy::Default'} =  'FAQID';
$Self->{'FAQ::Frontend::PublicFAQOverview'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::PublicFAQPrint'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::PublicFAQSearch'}->{'DynamicField'} =  {};
$Self->{'FAQ::Frontend::PublicFAQSearch'}->{'Order::Default'} =  'Down';
$Self->{'FAQ::Frontend::PublicFAQSearch'}->{'SearchCSVDynamicField'} =  {};
$Self->{'FAQ::Frontend::PublicFAQSearch'}->{'SearchLimit'} =  '200';
$Self->{'FAQ::Frontend::PublicFAQSearch'}->{'SearchPageShown'} =  '40';
$Self->{'FAQ::Frontend::PublicFAQSearch'}->{'SortBy::Default'} =  'FAQID';
$Self->{'FAQ::Frontend::PublicFAQZoom'}->{'DynamicField'} =  {};
$Self->{'FAQ::Item::Field1'} =  {
  'Caption' => 'Symptom',
  'Prio' => '100',
  'Show' => 'public'
};
$Self->{'FAQ::Item::Field2'} =  {
  'Caption' => 'Problem',
  'Prio' => '200',
  'Show' => 'public'
};
$Self->{'FAQ::Item::Field3'} =  {
  'Caption' => 'Solution',
  'Prio' => '300',
  'Show' => 'public'
};
$Self->{'FAQ::Item::Field4'} =  {
  'Caption' => 'Field4',
  'Prio' => '400',
  'Show' => ''
};
$Self->{'FAQ::Item::Field5'} =  {
  'Caption' => 'Field5',
  'Prio' => '500',
  'Show' => ''
};
$Self->{'FAQ::Item::Field6'} =  {
  'Caption' => 'Comment',
  'Prio' => '600',
  'Show' => 'internal'
};
$Self->{'FAQ::Item::HTML'} =  '1';
$Self->{'FAQ::Item::Voting::Rates'} =  {
  '0' => '1',
  '100' => '5',
  '25' => '2',
  '50' => '3',
  '75' => '4'
};
$Self->{'FAQ::Item::Voting::Show'} =  {
  'external' => 'external (customer)',
  'internal' => 'internal (agent)'
};
$Self->{'FAQ::KeywordArticeList::SearchLimit'} =  '5000';
$Self->{'FAQ::MultiLanguage'} =  '1';
$Self->{'FAQ::Public::StateTypes'} =  [
  'public'
];
$Self->{'FAQ::Service'} =  '0';
$Self->{'FAQ::TicketCompose'}->{'IncludeInternal'} =  '0';
$Self->{'FAQ::TicketCompose'}->{'InsertMethod'} =  'Full';
$Self->{'FAQ::TicketCompose'}->{'ShowFieldNames'} =  '1';
$Self->{'FAQ::TicketCompose'}->{'ShowInsertLinkButton'} =  '1';
$Self->{'FAQ::TicketCompose'}->{'ShowInsertTextAndLinkButton'} =  '1';
$Self->{'FAQ::TicketCompose'}->{'ShowInsertTextButton'} =  '1';
$Self->{'FAQ::TicketCompose'}->{'UpdateArticleSubject'} =  '1';
$Self->{'FAQ::TitleSize'} =  '50';
$Self->{'FAQ::Voting'} =  '1';
$Self->{'FQDN'} =  'tessera.ncs.local';
$Self->{'FirstnameLastnameOrder'} =  '0';
$Self->{'FormDraftTTL'}->{'Ticket'} =  '10080';
$Self->{'Frontend::Admin::AdminAppointmentNotificationEvent'}->{'EventObjectTypes'} =  [
  'Calendar',
  'Appointment'
];
$Self->{'Frontend::Admin::AdminAppointmentNotificationEvent'}->{'RichText'} =  '1';
$Self->{'Frontend::Admin::AdminAppointmentNotificationEvent'}->{'RichTextHeight'} =  '320';
$Self->{'Frontend::Admin::AdminAppointmentNotificationEvent'}->{'RichTextWidth'} =  '620';
$Self->{'Frontend::Admin::AdminNotificationEvent'}->{'RichText'} =  '1';
$Self->{'Frontend::Admin::AdminNotificationEvent'}->{'RichTextHeight'} =  '320';
$Self->{'Frontend::Admin::AdminNotificationEvent'}->{'RichTextWidth'} =  '620';
$Self->{'Frontend::AdminModuleGroups'}->{'001-Framework'} =  {
  'Administration' => {
    'Order' => '6000',
    'Title' => 'Administration'
  },
  'Automation' => {
    'Order' => '4000',
    'Title' => 'Processes & Automation'
  },
  'Communication' => {
    'Order' => '2000',
    'Title' => 'Communication & Notifications'
  },
  'Miscellaneous' => {
    'Order' => '7000',
    'Title' => 'Miscellaneous'
  },
  'OTOBOTeamServices' => {
    'Order' => '5000',
    'Title' => 'OTOBO Team Services'
  },
  'Ticket' => {
    'Order' => '1000',
    'Title' => 'Ticket Settings'
  },
  'Users' => {
    'Order' => '3000',
    'Title' => 'Users, Groups & Roles'
  }
};
$Self->{'Frontend::AdminModuleGroups'}->{'002-Translations'} =  {
  'Translations' => {
    'Order' => '4500',
    'Title' => 'Languages'
  }
};
$Self->{'Frontend::AdminModuleGroups'}->{'200-ITSMChangeManagement'} =  {
  'ChangeSettings' => {
    'Order' => '9000',
    'Title' => 'Change Settings'
  }
};
$Self->{'Frontend::AdminModuleGroups'}->{'200-ITSMConfigurationManagement'} =  {
  'CMDBSettings' => {
    'Order' => '8000',
    'Title' => 'CMDB Settings'
  }
};
$Self->{'Frontend::AgentLinkObject::WildcardSearch'} =  '0';
$Self->{'Frontend::AjaxDebug'} =  '0';
$Self->{'Frontend::AvatarEngine'} =  'None';
$Self->{'Frontend::CKEditorPlugins'} =  [
  'Alignment',
  'Autoformat',
  'BlockQuote',
  'Bold',
  'CodeBlock',
  'DataFilter',
  'DataSchema',
  'FindAndReplace',
  'FontColor',
  'FontFamily',
  'FontSize',
  'FontBackgroundColor',
  'GeneralHtmlSupport',
  'Heading',
  'HorizontalLine',
  'Image',
  'ImageResize',
  'ImageStyle',
  'ImageUpload',
  'ImageToolbar',
  'ImageInsert',
  'Indent',
  'Italic',
  'Link',
  'List',
  'Paragraph',
  'RemoveFormat',
  'SelectAll',
  'SimpleUploadAdapter',
  'SourceEditing',
  'SpecialCharacters',
  'SpecialCharactersEssentials',
  'Strikethrough',
  'Table',
  'TableCellProperties',
  'TableColumnResize',
  'TableProperties',
  'TableToolbar',
  'Underline',
  'Undo',
  'PasteFromOffice',
  'Fullscreen'
];
$Self->{'Frontend::CSSPath'} =  '<OTOBO_CONFIG_Frontend::WebPath>css/';
$Self->{'Frontend::CommonParam'}->{'Action'} =  'AgentDashboard';
$Self->{'Frontend::CommonParam'}->{'QueueID'} =  '0';
$Self->{'Frontend::CommonParam'}->{'TicketID'} =  '';
$Self->{'Frontend::CustomerUser::Item'}->{'1-GoogleMaps'} =  {
  'Attributes' => 'UserStreet;UserCity;UserCountry;',
  'CSS' => 'Core.Agent.CustomerUser.GoogleMaps.css',
  'CSSClass' => 'GoogleMaps',
  'IconName' => 'fa-globe',
  'Module' => 'Kernel::Output::HTML::CustomerUser::Generic',
  'Required' => 'UserStreet;UserCity;',
  'Target' => '_blank',
  'Text' => 'Location',
  'URL' => 'https://maps.google.com/maps?z=7&q='
};
$Self->{'Frontend::CustomerUser::Item'}->{'15-OpenTickets'} =  {
  'Action' => 'AgentTicketSearch',
  'Attributes' => 'StateType=Open;',
  'CSS' => 'Core.Agent.CustomerUser.OpenTicket.css',
  'CSSClassNoOpenTicket' => 'NoOpenTicket',
  'CSSClassOpenTicket' => 'OpenTicket',
  'CustomerUserLogin' => '0',
  'IconNameNoOpenTicket' => 'fa-check-circle',
  'IconNameOpenTicket' => 'fa-exclamation-circle',
  'Module' => 'Kernel::Output::HTML::CustomerUser::GenericTicket',
  'Subaction' => 'Search',
  'Target' => '_blank',
  'Text' => 'Open tickets (customer)'
};
$Self->{'Frontend::CustomerUser::Item'}->{'16-OpenTicketsForCustomerUserLogin'} =  {
  'Action' => 'AgentTicketSearch',
  'Attributes' => 'StateType=Open;',
  'CSS' => 'Core.Agent.CustomerUser.OpenTicket.css',
  'CSSClassNoOpenTicket' => 'NoOpenTicket',
  'CSSClassOpenTicket' => 'OpenTicket',
  'CustomerUserLogin' => '1',
  'IconNameNoOpenTicket' => 'fa-check-circle',
  'IconNameOpenTicket' => 'fa-exclamation-circle',
  'Module' => 'Kernel::Output::HTML::CustomerUser::GenericTicket',
  'Subaction' => 'Search',
  'Target' => '_blank',
  'Text' => 'Open tickets (customer user)'
};
$Self->{'Frontend::CustomerUser::Item'}->{'17-ClosedTickets'} =  {
  'Action' => 'AgentTicketSearch',
  'Attributes' => 'StateType=Closed;',
  'CSS' => 'Core.Agent.CustomerUser.OpenTicket.css',
  'CSSClassNoOpenTicket' => 'NoOpenTicket',
  'CSSClassOpenTicket' => 'OpenTicket',
  'CustomerUserLogin' => '0',
  'IconNameNoOpenTicket' => 'fa-power-off',
  'IconNameOpenTicket' => 'fa-power-off',
  'Module' => 'Kernel::Output::HTML::CustomerUser::GenericTicket',
  'Subaction' => 'Search',
  'Target' => '_blank',
  'Text' => 'Closed tickets (customer)'
};
$Self->{'Frontend::CustomerUser::Item'}->{'18-ClosedTicketsForCustomerUserLogin'} =  {
  'Action' => 'AgentTicketSearch',
  'Attributes' => 'StateType=Closed;',
  'CSS' => 'Core.Agent.CustomerUser.OpenTicket.css',
  'CSSClassNoOpenTicket' => 'NoOpenTicket',
  'CSSClassOpenTicket' => 'OpenTicket',
  'CustomerUserLogin' => '1',
  'IconNameNoOpenTicket' => 'fa-power-off',
  'IconNameOpenTicket' => 'fa-power-off',
  'Module' => 'Kernel::Output::HTML::CustomerUser::GenericTicket',
  'Subaction' => 'Search',
  'Target' => '_blank',
  'Text' => 'Closed tickets (customer user)'
};
$Self->{'Frontend::DebugMode'} =  '0';
$Self->{'Frontend::DefaultInterface'} =  'index.pl';
$Self->{'Frontend::EnhancedCKEditorToolbar'} =  [
  [
    'heading',
    'bold',
    'italic',
    'underline',
    'strikethrough'
  ],
  [
    'bulletedList',
    'numberedList'
  ],
  [
    'insertTable'
  ],
  [
    'indent',
    'outdent',
    'alignment'
  ],
  [
    'link',
    'undo',
    'redo'
  ],
  [
    'insertImage',
    'horizontalLine',
    'blockQuote'
  ],
  [
    'findAndReplace',
    'fontColor'
  ],
  [
    'fontBackgroundColor',
    'removeFormat'
  ],
  [
    'sourceEditing',
    'specialCharacters'
  ],
  [
    'fontFamily',
    'fontSize'
  ],
  [
    'codeBlock'
  ],
  [
    'fullscreen'
  ]
];
$Self->{'Frontend::Gravatar::ArticleDefaultImage'} =  'mp';
$Self->{'Frontend::Gravatar::DefaultImage'} =  'mp';
$Self->{'Frontend::HeaderMetaModule'}->{'100-Refresh'} =  {
  'Module' => 'Kernel::Output::HTML::HeaderMeta::Refresh'
};
$Self->{'Frontend::HeaderMetaModule'}->{'2-TicketSearch'} =  {
  'Action' => 'AgentTicketSearch',
  'Module' => 'Kernel::Output::HTML::HeaderMeta::AgentTicketSearch'
};
$Self->{'Frontend::HeaderMetaModule'}->{'3-FAQSearch'} =  {
  'Action' => 'AgentFAQSearch',
  'Module' => 'Kernel::Output::HTML::HeaderMeta::AgentFAQSearch'
};
$Self->{'Frontend::ImagePath'} =  '<OTOBO_CONFIG_Frontend::WebPath>skins/Agent/default/img/';
$Self->{'Frontend::JavaScriptPath'} =  '<OTOBO_CONFIG_Frontend::WebPath>js/';
$Self->{'Frontend::MenuDragDropEnabled'} =  '1';
$Self->{'Frontend::Module'}->{'Admin'} =  {
  'Description' => 'Admin Area.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AdminACL'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Access Control Lists (ACL)'
};
$Self->{'Frontend::Module'}->{'AdminAbout'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'About'
};
$Self->{'Frontend::Module'}->{'AdminAppointmentCalendarManage'} =  {
  'Description' => 'Calendar manage screen.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Calendar',
  'Title' => 'Manage Calendars'
};
$Self->{'Frontend::Module'}->{'AdminAppointmentImport'} =  {
  'Description' => 'Import appointments screen.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Import Appointments'
};
$Self->{'Frontend::Module'}->{'AdminAppointmentNotificationEvent'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Appointment Notifications'
};
$Self->{'Frontend::Module'}->{'AdminAttachment'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Attachments'
};
$Self->{'Frontend::Module'}->{'AdminAutoResponse'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Auto Responses'
};
$Self->{'Frontend::Module'}->{'AdminCloudServiceSupportDataCollector'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Support data collector'
};
$Self->{'Frontend::Module'}->{'AdminCloudServices'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Cloud Services'
};
$Self->{'Frontend::Module'}->{'AdminCommunicationLog'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Communication Log GUI'
};
$Self->{'Frontend::Module'}->{'AdminContactWD'} =  {
  'Description' => 'Admin contact with data.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Admin Contact With Data'
};
$Self->{'Frontend::Module'}->{'AdminCustomerAccept'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Privacy Policy'
};
$Self->{'Frontend::Module'}->{'AdminCustomerCompany'} =  {
  'Description' => 'Edit Customer Companies.',
  'Group' => [
    'admin',
    'users'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Customers',
  'Title' => 'Customer Companies'
};
$Self->{'Frontend::Module'}->{'AdminCustomerDashboardInfoTile'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Customer Info'
};
$Self->{'Frontend::Module'}->{'AdminCustomerGroup'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Customers ↔ Groups'
};
$Self->{'Frontend::Module'}->{'AdminCustomerUser'} =  {
  'Description' => 'Edit Customer Users.',
  'Group' => [
    'admin',
    'users'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Customers',
  'Title' => 'Customer Users'
};
$Self->{'Frontend::Module'}->{'AdminCustomerUserCustomer'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Customer Users ↔ Customers'
};
$Self->{'Frontend::Module'}->{'AdminCustomerUserGroup'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Customer Users ↔ Groups'
};
$Self->{'Frontend::Module'}->{'AdminCustomerUserService'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Customer Users ↔ Services'
};
$Self->{'Frontend::Module'}->{'AdminDynamicField'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldAttachment'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Dynamic Fields Attachment Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldCheckbox'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Checkbox Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldContactWD'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Contact Data Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldDB'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Database Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldDateTime'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Date Time Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldDropdown'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Drop-down Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldGeneralCatalog'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields GeneralCatalog Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldImportExport'} =  {
  'Description' => 'DynamicField Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'DynamicFieldImportExport'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldLens'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Lens Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldMasterSlave'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Dynamic Fields Drop-down Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldMultiselect'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Multiselect Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldQueue'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Queue Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldReference'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Reference Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldSLA'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields SLA Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldScreen'} =  {
  'Description' => 'Manage dynamic field in screens.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'DynamicFieldScreen'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldScript'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Text Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldSet'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Field Set Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldText'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Text Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldTitle'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Text Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldType'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Type Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminDynamicFieldWebService'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Dynamic Fields Web Service Backend GUI'
};
$Self->{'Frontend::Module'}->{'AdminEmail'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Admin Notification'
};
$Self->{'Frontend::Module'}->{'AdminGeneralCatalog'} =  {
  'Description' => 'Admin.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'General Catalog'
};
$Self->{'Frontend::Module'}->{'AdminGenericAgent'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'GenericAgent'
};
$Self->{'Frontend::Module'}->{'AdminGenericAgentImportExport'} =  {
  'Description' => 'GenericAgent Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'GenericAgentImportExport'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceDebugger'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Debugger GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceErrorHandlingDefault'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface ErrorHandling GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceErrorHandlingRequestRetry'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface ErrorHandling GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceInvokerConfigItem'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Invoker GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceInvokerDefault'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Invoker GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceInvokerEvent'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Invoker Event GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceInvokerTicket'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Invoker GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceMappingSimple'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Web Service Mapping GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceMappingXSLT'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Web Service Mapping GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceOperationConfigItem'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Operation GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceOperationDefault'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Operation GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceTransportHTTPREST'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface TransportHTTPREST GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceTransportHTTPSOAP'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface TransportHTTPSOAP GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceWebservice'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'GenericInterface Web Service GUI'
};
$Self->{'Frontend::Module'}->{'AdminGenericInterfaceWebserviceHistory'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'GenericInterface Web Service History GUI'
};
$Self->{'Frontend::Module'}->{'AdminGroup'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Groups'
};
$Self->{'Frontend::Module'}->{'AdminGroupImportExport'} =  {
  'Description' => 'Group Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'GroupImportExport'
};
$Self->{'Frontend::Module'}->{'AdminITSMCIPAllocate'} =  {
  'Description' => 'Manage priority matrix.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Criticality ↔ Impact ↔ Priority'
};
$Self->{'Frontend::Module'}->{'AdminITSMChangeCIPAllocate'} =  {
  'Description' => 'Admin of the CIP matrix.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Category ↔ Impact ↔ Priority'
};
$Self->{'Frontend::Module'}->{'AdminITSMChangeNotification'} =  {
  'Description' => 'Create and manage ITSM Change Management notifications.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'ITSM Change notification rules'
};
$Self->{'Frontend::Module'}->{'AdminITSMConfigItem'} =  {
  'Description' => 'Admin.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Config Item'
};
$Self->{'Frontend::Module'}->{'AdminITSMStateMachine'} =  {
  'Description' => 'Admin of the state machine.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'State Machine'
};
$Self->{'Frontend::Module'}->{'AdminImportExport'} =  {
  'Description' => 'Import and export object information.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Import/Export'
};
$Self->{'Frontend::Module'}->{'AdminInit'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Init'
};
$Self->{'Frontend::Module'}->{'AdminLog'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'System Log'
};
$Self->{'Frontend::Module'}->{'AdminMailAccount'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Mail Accounts'
};
$Self->{'Frontend::Module'}->{'AdminNotificationEvent'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Ticket Notifications'
};
$Self->{'Frontend::Module'}->{'AdminPGP'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'PGP Key Management'
};
$Self->{'Frontend::Module'}->{'AdminPackageManager'} =  {
  'Description' => 'Software Package Manager.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Package Manager'
};
$Self->{'Frontend::Module'}->{'AdminPerformanceLog'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Performance Log'
};
$Self->{'Frontend::Module'}->{'AdminPostMasterFilter'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'PostMaster Filters'
};
$Self->{'Frontend::Module'}->{'AdminPriority'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Priorities'
};
$Self->{'Frontend::Module'}->{'AdminProcessManagement'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Process Management'
};
$Self->{'Frontend::Module'}->{'AdminProcessManagementActivity'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Process Management Activity GUI'
};
$Self->{'Frontend::Module'}->{'AdminProcessManagementActivityDialog'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Process Management Activity Dialog GUI'
};
$Self->{'Frontend::Module'}->{'AdminProcessManagementPath'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Process Management Path GUI'
};
$Self->{'Frontend::Module'}->{'AdminProcessManagementTransition'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Process Management Transition GUI'
};
$Self->{'Frontend::Module'}->{'AdminProcessManagementTransitionAction'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Process Management Transition Action GUI'
};
$Self->{'Frontend::Module'}->{'AdminQueue'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Queues'
};
$Self->{'Frontend::Module'}->{'AdminQueueAutoResponse'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Queues ↔ Auto Responses'
};
$Self->{'Frontend::Module'}->{'AdminQueueImportExport'} =  {
  'Description' => 'Queue Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'QueueImportExport'
};
$Self->{'Frontend::Module'}->{'AdminQueueTemplates'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Templates ↔ Queues'
};
$Self->{'Frontend::Module'}->{'AdminQueueTemplatesImportExport'} =  {
  'Description' => 'Queue-Template relations Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'QueueTemplatesImportExport'
};
$Self->{'Frontend::Module'}->{'AdminResponseTemplatesStatePreselection'} =  {
  'Description' => 'Manage ticket state pre-selections for response templates.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Ticket state pre-selection for response templates'
};
$Self->{'Frontend::Module'}->{'AdminRole'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Roles'
};
$Self->{'Frontend::Module'}->{'AdminRoleGroup'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Roles ↔ Groups'
};
$Self->{'Frontend::Module'}->{'AdminRoleGroupImportExport'} =  {
  'Description' => 'Role-Group Relations Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'RoleGroupImportExport'
};
$Self->{'Frontend::Module'}->{'AdminRoleImportExport'} =  {
  'Description' => 'Role Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'RoleImportExport'
};
$Self->{'Frontend::Module'}->{'AdminRoleUser'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Agents ↔ Roles'
};
$Self->{'Frontend::Module'}->{'AdminSLA'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Service Level Agreements'
};
$Self->{'Frontend::Module'}->{'AdminSLAImportExport'} =  {
  'Description' => 'SLA Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'SLAImportExport'
};
$Self->{'Frontend::Module'}->{'AdminSMIME'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'S/MIME Management'
};
$Self->{'Frontend::Module'}->{'AdminSalutation'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Salutations'
};
$Self->{'Frontend::Module'}->{'AdminSelectBox'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'SQL Box'
};
$Self->{'Frontend::Module'}->{'AdminService'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Services'
};
$Self->{'Frontend::Module'}->{'AdminServiceImportExport'} =  {
  'Description' => 'Service Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'ServiceImportExport'
};
$Self->{'Frontend::Module'}->{'AdminSession'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Session Management'
};
$Self->{'Frontend::Module'}->{'AdminSignature'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Signatures'
};
$Self->{'Frontend::Module'}->{'AdminState'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'States'
};
$Self->{'Frontend::Module'}->{'AdminSupportDataCollector'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Support Data Collector'
};
$Self->{'Frontend::Module'}->{'AdminSystemAddress'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Email Addresses'
};
$Self->{'Frontend::Module'}->{'AdminSystemConfiguration'} =  {
  'Description' => 'Admin.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'System Configuration'
};
$Self->{'Frontend::Module'}->{'AdminSystemConfigurationDeployment'} =  {
  'Description' => 'Manage System Configuration Deployments.',
  'Group' => [
    'admin',
    'users'
  ],
  'GroupRo' => [],
  'NavBarName' => 'SystemConfiguration',
  'Title' => 'System Configuration Deployment'
};
$Self->{'Frontend::Module'}->{'AdminSystemConfigurationDeploymentHistory'} =  {
  'Description' => 'DeploymentHistory',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'DeploymentHistory',
  'Title' => 'DeploymentHistory'
};
$Self->{'Frontend::Module'}->{'AdminSystemConfigurationGroup'} =  {
  'Description' => 'Admin.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'System Configuration Group'
};
$Self->{'Frontend::Module'}->{'AdminSystemConfigurationSettingHistory'} =  {
  'Description' => 'SettingHistory',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'SettingHistory',
  'Title' => 'System Configuration Setting History'
};
$Self->{'Frontend::Module'}->{'AdminSystemConfigurationUser'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'System Configuration User Settings'
};
$Self->{'Frontend::Module'}->{'AdminSystemMaintenance'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'System Maintenance'
};
$Self->{'Frontend::Module'}->{'AdminTemplate'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Templates'
};
$Self->{'Frontend::Module'}->{'AdminTemplateAttachment'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Templates ↔ Attachments'
};
$Self->{'Frontend::Module'}->{'AdminTemplateImportExport'} =  {
  'Description' => 'Template Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'TemplateImportExport'
};
$Self->{'Frontend::Module'}->{'AdminTicketMask'} =  {
  'Description' => 'Admin.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Ticket Masks'
};
$Self->{'Frontend::Module'}->{'AdminTranslations'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Translations'
};
$Self->{'Frontend::Module'}->{'AdminType'} =  {
  'Description' => 'This module is part of the admin area of OTOBO.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Types'
};
$Self->{'Frontend::Module'}->{'AdminTypeImportExport'} =  {
  'Description' => 'Type Import Export',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'TypeImportExport'
};
$Self->{'Frontend::Module'}->{'AdminUser'} =  {
  'Description' => 'Create and manage agents.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Agents'
};
$Self->{'Frontend::Module'}->{'AdminUserGroup'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Admin',
  'Title' => 'Agents ↔ Groups'
};
$Self->{'Frontend::Module'}->{'AgentAppointmentAgendaOverview'} =  {
  'Description' => 'Overview of all appointments.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Calendar',
  'Title' => 'Agenda Overview'
};
$Self->{'Frontend::Module'}->{'AgentAppointmentCalendarOverview'} =  {
  'Description' => 'Appointment Calendar overview page.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Calendar',
  'Title' => 'Overview'
};
$Self->{'Frontend::Module'}->{'AgentAppointmentEdit'} =  {
  'Description' => 'Appointment edit screen.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Edit appointment'
};
$Self->{'Frontend::Module'}->{'AgentAppointmentList'} =  {
  'Description' => 'Appointment list.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Appointment list'
};
$Self->{'Frontend::Module'}->{'AgentAppointmentPluginSearch'} =  {
  'Description' => 'Plugin search module for autocomplete.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Plugin search'
};
$Self->{'Frontend::Module'}->{'AgentContactWDSearch'} =  {
  'Description' => 'Agent contact with data search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Agent Contact With Data Search'
};
$Self->{'Frontend::Module'}->{'AgentCustomerInformationCenter'} =  {
  'Description' => 'Customer Information Center.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Customers',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentCustomerInformationCenterSearch'} =  {
  'Description' => 'Customer Information Center Search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentCustomerSearch'} =  {
  'Description' => 'Agent Customer Search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Agent Customer Search'
};
$Self->{'Frontend::Module'}->{'AgentCustomerUserAddressBook'} =  {
  'Description' => 'Search Customer User',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Search Customer User'
};
$Self->{'Frontend::Module'}->{'AgentCustomerUserInformationCenter'} =  {
  'Description' => 'Customer User Information Center.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Customer Users',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentCustomerUserInformationCenterSearch'} =  {
  'Description' => 'Customer User Information Center Search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentDaemonInfo'} =  {
  'Description' => 'Admin',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Shows information on how to start OTOBO Daemon'
};
$Self->{'Frontend::Module'}->{'AgentDashboard'} =  {
  'Description' => 'Agent Dashboard',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Dashboard',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentDynamicFieldAttachment'} =  {
  'Description' => 'Agent',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Dynamic Fields Attachment download frontend'
};
$Self->{'Frontend::Module'}->{'AgentDynamicFieldDBDetailedSearch'} =  {
  'Description' => 'Agent dynamic field database detailed search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Agent Dynamic Field Database Detailed Search'
};
$Self->{'Frontend::Module'}->{'AgentDynamicFieldDBDetails'} =  {
  'Description' => 'Agent dynamic field database details.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Agent Dynamic Field Database Details'
};
$Self->{'Frontend::Module'}->{'AgentDynamicFieldDBSearch'} =  {
  'Description' => 'Agent dynamic field database search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Agent Dynamic Field Database Search'
};
$Self->{'Frontend::Module'}->{'AgentElasticsearchQuickResult'} =  {
  'Description' => 'Elasticsearch quick result module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'ElasticsearchQuickResult'
};
$Self->{'Frontend::Module'}->{'AgentFAQAdd'} =  {
  'Description' => 'FAQ Area.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'FAQ'
};
$Self->{'Frontend::Module'}->{'AgentFAQCategory'} =  {
  'Description' => 'FAQ Area.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'FAQ'
};
$Self->{'Frontend::Module'}->{'AgentFAQDelete'} =  {
  'Description' => 'FAQ Delete.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'Delete'
};
$Self->{'Frontend::Module'}->{'AgentFAQEdit'} =  {
  'Description' => 'FAQ Edit.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'Edit'
};
$Self->{'Frontend::Module'}->{'AgentFAQExplorer'} =  {
  'Description' => 'FAQ Area.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'FAQ'
};
$Self->{'Frontend::Module'}->{'AgentFAQHistory'} =  {
  'Description' => 'FAQ History.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'History'
};
$Self->{'Frontend::Module'}->{'AgentFAQJournal'} =  {
  'Description' => 'FAQ Area.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'FAQ'
};
$Self->{'Frontend::Module'}->{'AgentFAQLanguage'} =  {
  'Description' => 'FAQ Area.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'FAQ'
};
$Self->{'Frontend::Module'}->{'AgentFAQPrint'} =  {
  'Description' => 'FAQ Print.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'Print'
};
$Self->{'Frontend::Module'}->{'AgentFAQRichText'} =  {
  'Description' => 'FAQ AJAX Responder for Richtext.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'FAQ AJAX Responder'
};
$Self->{'Frontend::Module'}->{'AgentFAQSearch'} =  {
  'Description' => 'FAQ Area.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'FAQ'
};
$Self->{'Frontend::Module'}->{'AgentFAQSearchSmall'} =  {
  'Description' => 'Search FAQ Small.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'FAQ'
};
$Self->{'Frontend::Module'}->{'AgentFAQZoom'} =  {
  'Description' => 'FAQ Area.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'FAQ'
};
$Self->{'Frontend::Module'}->{'AgentITSMCABMemberSearch'} =  {
  'Description' => 'Lookup of CAB members for autocompletion.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => '',
  'Title' => 'CAB Member Search'
};
$Self->{'Frontend::Module'}->{'AgentITSMChange'} =  {
  'Description' => 'Overview over all Changes.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'ITSM Changes'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeAdd'} =  {
  'Description' => 'Add a change.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-manager'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Add'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeAddFromTemplate'} =  {
  'Description' => 'Add a change from template.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-builder',
    'itsm-change-manager'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Add from template'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeCABTemplate'} =  {
  'Description' => 'ITSM Change CAB Templates.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Change CAB Templates'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeCondition'} =  {
  'Description' => 'ITSM Change Condition Overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Condition Overview'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeConditionEdit'} =  {
  'Description' => 'ITSM Change Condition Edit.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Condition Edit'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeEdit'} =  {
  'Description' => 'Edit a change.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Edit'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeHistory'} =  {
  'Description' => 'Change History.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'History'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeHistoryZoom'} =  {
  'Description' => 'Details of a change history entry.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'History Zoom'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeInvolvedPersons'} =  {
  'Description' => 'Change Involved Persons.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Involved Persons'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeManager'} =  {
  'Description' => 'ITSM Change Manager Overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-manager'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeMyCAB'} =  {
  'Description' => 'ITSM MyCAB Overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeMyChanges'} =  {
  'Description' => 'ITSM MyChanges Overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-builder',
    'itsm-change-manager'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeMyWorkOrders'} =  {
  'Description' => 'ITSM MyWorkorders Overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangePIR'} =  {
  'Description' => 'ITSM Change PIR Overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangePSA'} =  {
  'Description' => 'Projected Service Availability (PSA) of changes. Overview of approved changes and their services.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'PSA'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangePrint'} =  {
  'Description' => 'Change Print.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Print'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeSchedule'} =  {
  'Description' => 'Forward schedule of changes. Overview over approved changes.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Change Schedule'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeSearch'} =  {
  'Description' => 'Search Changes.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Search'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeTemplate'} =  {
  'Description' => 'Template.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Template'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeTimeSlot'} =  {
  'Description' => 'Move Time Slot.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Time Slot'
};
$Self->{'Frontend::Module'}->{'AgentITSMChangeZoom'} =  {
  'Description' => 'Change Zoom.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Zoom'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItem'} =  {
  'Description' => 'ITSM config item overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-configitem'
  ],
  'NavBarName' => 'Config Item',
  'Title' => 'Overview'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemAdd'} =  {
  'Description' => 'Config item add.',
  'Group' => [
    'itsm-configitem'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Config Item',
  'Title' => 'Add'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemAttachment'} =  {
  'Description' => 'To download attachments.',
  'Group' => [],
  'GroupRo' => [
    'itsm-configitem'
  ],
  'NavBarName' => 'Config Item',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemBulk'} =  {
  'Description' => 'Configuration item bulk module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'CMDB',
  'Title' => 'Bulk Action'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemDelete'} =  {
  'Description' => 'Delete a configuration item',
  'Group' => [
    'itsm-configitem'
  ],
  'GroupRo' => [],
  'NavBarName' => 'ITSM ConfigItem',
  'Title' => 'Delete'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemEdit'} =  {
  'Description' => 'Config item edit.',
  'Group' => [
    'itsm-configitem'
  ],
  'GroupRo' => [],
  'NavBarName' => 'Config Item',
  'Title' => 'Edit'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemHistory'} =  {
  'Description' => 'Config item history.',
  'Group' => [],
  'GroupRo' => [
    'itsm-configitem'
  ],
  'NavBarName' => 'Config Item',
  'Title' => 'History'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemLabelPrint'} =  {
  'Description' => 'Config Item Label Print',
  'Group' => [],
  'GroupRo' => [
    'itsm-configitem'
  ],
  'NavBarName' => 'Config Item',
  'Title' => 'Print Label'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemPrint'} =  {
  'Description' => 'Config item print.',
  'Group' => [],
  'GroupRo' => [
    'itsm-configitem'
  ],
  'NavBarName' => 'Config Item',
  'Title' => 'Print'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemSearch'} =  {
  'Description' => 'Search config items.',
  'Group' => [],
  'GroupRo' => [
    'itsm-configitem'
  ],
  'NavBarName' => 'Config Item',
  'Title' => 'Search'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemTreeView'} =  {
  'Description' => 'ConfigItem Tree View',
  'Group' => [
    'itsm-configitem'
  ],
  'GroupRo' => [],
  'NavBarName' => 'ITSM ConfigItem',
  'Title' => 'Tree View'
};
$Self->{'Frontend::Module'}->{'AgentITSMConfigItemZoom'} =  {
  'Description' => 'Config item zoom.',
  'Group' => [],
  'GroupRo' => [
    'itsm-configitem'
  ],
  'NavBarName' => 'Config Item',
  'Title' => 'Zoom'
};
$Self->{'Frontend::Module'}->{'AgentITSMIncidentProblemManagement'} =  {
  'Description' => 'Module to dynamically show the service incident state and to calculate the priority.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Service Incident State and Priority Calculation'
};
$Self->{'Frontend::Module'}->{'AgentITSMSLA'} =  {
  'Description' => 'ITSM SLA Overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-service'
  ],
  'NavBarName' => 'Service',
  'Title' => 'SLA'
};
$Self->{'Frontend::Module'}->{'AgentITSMSLAPrint'} =  {
  'Description' => 'SLA Print.',
  'Group' => [],
  'GroupRo' => [
    'itsm-service'
  ],
  'NavBarName' => 'Service',
  'Title' => 'Print'
};
$Self->{'Frontend::Module'}->{'AgentITSMSLAZoom'} =  {
  'Description' => 'SLA Zoom.',
  'Group' => [],
  'GroupRo' => [
    'itsm-service'
  ],
  'NavBarName' => 'Service',
  'Title' => 'Zoom'
};
$Self->{'Frontend::Module'}->{'AgentITSMService'} =  {
  'Description' => 'ITSM Service Overview.',
  'Group' => [
    'itsm-service'
  ],
  'GroupRo' => [
    'itsm-service'
  ],
  'NavBarName' => 'Service',
  'Title' => 'Service'
};
$Self->{'Frontend::Module'}->{'AgentITSMServicePrint'} =  {
  'Description' => 'Service Print.',
  'Group' => [],
  'GroupRo' => [
    'itsm-service'
  ],
  'NavBarName' => 'Service',
  'Title' => 'Print'
};
$Self->{'Frontend::Module'}->{'AgentITSMServiceZoom'} =  {
  'Description' => 'Service Zoom.',
  'Group' => [],
  'GroupRo' => [
    'itsm-service'
  ],
  'NavBarName' => 'Service',
  'Title' => 'Zoom'
};
$Self->{'Frontend::Module'}->{'AgentITSMTemplateDelete'} =  {
  'Description' => 'ITSM Template Delete.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-builder',
    'itsm-change-manager'
  ],
  'NavBarName' => '',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMTemplateEdit'} =  {
  'Description' => 'ITSM Template Edit.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-builder',
    'itsm-change-manager'
  ],
  'NavBarName' => '',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMTemplateEditCAB'} =  {
  'Description' => 'ITSM Template Edit CAB.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-builder',
    'itsm-change-manager'
  ],
  'NavBarName' => '',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMTemplateEditContent'} =  {
  'Description' => 'ITSM Template Edit Content.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-builder',
    'itsm-change-manager'
  ],
  'NavBarName' => '',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMTemplateOverview'} =  {
  'Description' => 'ITSM Template Overview.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change-builder',
    'itsm-change-manager'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'ITSM Change'
};
$Self->{'Frontend::Module'}->{'AgentITSMUserSearch'} =  {
  'Description' => 'Lookup of agents, used for autocompletion.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'User Search'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderAdd'} =  {
  'Description' => 'Workorder Add.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Add'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderAddFromTemplate'} =  {
  'Description' => 'Workorder Add (from template).',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Add'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderAgent'} =  {
  'Description' => 'Workorder Agent.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Agent'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderDelete'} =  {
  'Description' => 'Workorder Delete.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Delete'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderEdit'} =  {
  'Description' => 'Workorder Edit.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Edit'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderHistory'} =  {
  'Description' => 'Workorder History.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'History'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderHistoryZoom'} =  {
  'Description' => 'Workorder History Zoom.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'History Zoom'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderReport'} =  {
  'Description' => 'Workorder Report.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Report'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderTake'} =  {
  'Description' => 'Take Workorder.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Take Workorder'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderTemplate'} =  {
  'Description' => 'Template.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Template'
};
$Self->{'Frontend::Module'}->{'AgentITSMWorkOrderZoom'} =  {
  'Description' => 'Workorder Zoom.',
  'Group' => [],
  'GroupRo' => [
    'itsm-change'
  ],
  'NavBarName' => 'ITSM Change',
  'Title' => 'Zoom'
};
$Self->{'Frontend::Module'}->{'AgentInfo'} =  {
  'Description' => 'Generic Info module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Info'
};
$Self->{'Frontend::Module'}->{'AgentLinkObject'} =  {
  'Description' => 'Link Object.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Link Object'
};
$Self->{'Frontend::Module'}->{'AgentPassword'} =  {
  'Description' => 'Agent Password.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Password Policy'
};
$Self->{'Frontend::Module'}->{'AgentPreferences'} =  {
  'Description' => 'Agent Preferences.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Preferences',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentReferenceSearch'} =  {
  'Description' => 'Agent reference dynamic field with data search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Agent Reference Dynamic Field With Data Search'
};
$Self->{'Frontend::Module'}->{'AgentSearch'} =  {
  'Description' => 'Global Search Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Search'
};
$Self->{'Frontend::Module'}->{'AgentSplitSelection'} =  {
  'Description' => 'Ticket split dialog.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentStatistics'} =  {
  'Description' => 'Agent Statistics.',
  'Group' => [
    'stats'
  ],
  'GroupRo' => [
    'stats'
  ],
  'NavBarName' => 'Reports',
  'Title' => 'Statistics'
};
$Self->{'Frontend::Module'}->{'AgentStatisticsReports'} =  {
  'Description' => 'Statistics reports.',
  'Group' => [
    'stats'
  ],
  'GroupRo' => [
    'stats'
  ],
  'NavBarName' => 'Statistics Reports',
  'Title' => 'Statistics Reports'
};
$Self->{'Frontend::Module'}->{'AgentSurveyAdd'} =  {
  'Description' => 'Survey Add Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Survey',
  'Title' => 'Survey'
};
$Self->{'Frontend::Module'}->{'AgentSurveyEdit'} =  {
  'Description' => 'Survey Edit Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Survey'
};
$Self->{'Frontend::Module'}->{'AgentSurveyEditQuestions'} =  {
  'Description' => 'A module to edit survey questions.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => ''
};
$Self->{'Frontend::Module'}->{'AgentSurveyOverview'} =  {
  'Description' => 'A Survey Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Survey',
  'Title' => 'Survey'
};
$Self->{'Frontend::Module'}->{'AgentSurveyStats'} =  {
  'Description' => 'Survey Stats Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Survey'
};
$Self->{'Frontend::Module'}->{'AgentSurveyZoom'} =  {
  'Description' => 'Survey Zoom Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Survey'
};
$Self->{'Frontend::Module'}->{'AgentTicketAccountTime'} =  {
  'Description' => 'Time accounting edit.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'TimeAccounting',
  'Title' => 'Edit'
};
$Self->{'Frontend::Module'}->{'AgentTicketAddtlITSMField'} =  {
  'Description' => 'Additional ITSM ticket fields.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Additional ITSM Fields'
};
$Self->{'Frontend::Module'}->{'AgentTicketArticleContent'} =  {
  'Description' => 'To view HTML attachments.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentTicketArticleEdit'} =  {
  'Description' => 'Ticket Note.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Note'
};
$Self->{'Frontend::Module'}->{'AgentTicketArticlePin'} =  {
  'Description' => 'AgentTicketArticlePin',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentTicketArticleStatus'} =  {
  'Description' => 'Switch deleted article status view.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Switch deleted article status view'
};
$Self->{'Frontend::Module'}->{'AgentTicketArticleVersionView'} =  {
  'Description' => 'View stored article version.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Article Version View'
};
$Self->{'Frontend::Module'}->{'AgentTicketAttachment'} =  {
  'Description' => 'To download attachments.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AgentTicketBounce'} =  {
  'Description' => 'Ticket Compose Bounce Email.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Bounce'
};
$Self->{'Frontend::Module'}->{'AgentTicketBulk'} =  {
  'Description' => 'Ticket bulk module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Bulk Action'
};
$Self->{'Frontend::Module'}->{'AgentTicketClose'} =  {
  'Description' => 'Ticket Close.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Close'
};
$Self->{'Frontend::Module'}->{'AgentTicketCompose'} =  {
  'Description' => 'Ticket Compose email Answer.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Compose'
};
$Self->{'Frontend::Module'}->{'AgentTicketCustomer'} =  {
  'Description' => 'Ticket Customer.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Customer'
};
$Self->{'Frontend::Module'}->{'AgentTicketDecision'} =  {
  'Description' => 'Ticket decision.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Decision'
};
$Self->{'Frontend::Module'}->{'AgentTicketDownloadAllAttachments'} =  {
  'Description' => 'Download multiple attachments as one zip file',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Download ticket attachments'
};
$Self->{'Frontend::Module'}->{'AgentTicketEmail'} =  {
  'Description' => 'Create new email ticket.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'New email ticket'
};
$Self->{'Frontend::Module'}->{'AgentTicketEmailOutbound'} =  {
  'Description' => 'Ticket Outbound Email.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Email Outbound'
};
$Self->{'Frontend::Module'}->{'AgentTicketEmailResend'} =  {
  'Description' => 'Resend Ticket Email.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Email Resend'
};
$Self->{'Frontend::Module'}->{'AgentTicketEscalationView'} =  {
  'Description' => 'Overview of all escalated tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Escalation view'
};
$Self->{'Frontend::Module'}->{'AgentTicketForward'} =  {
  'Description' => 'Ticket Forward Email.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Forward'
};
$Self->{'Frontend::Module'}->{'AgentTicketFreeText'} =  {
  'Description' => 'Ticket FreeText.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Change Ticket'
};
$Self->{'Frontend::Module'}->{'AgentTicketHistory'} =  {
  'Description' => 'Ticket History.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'History'
};
$Self->{'Frontend::Module'}->{'AgentTicketLock'} =  {
  'Description' => 'Ticket Lock.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Lock'
};
$Self->{'Frontend::Module'}->{'AgentTicketLockedView'} =  {
  'Description' => 'Locked Tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Locked Tickets'
};
$Self->{'Frontend::Module'}->{'AgentTicketMarkSeenUnseen'} =  {
  'Description' => 'Mark ticket article(s) as (un)seen',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Mark ticket as (un)seen'
};
$Self->{'Frontend::Module'}->{'AgentTicketMasterSlave'} =  {
  'Description' => 'Ticket MasterSlave.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'MasterSlave'
};
$Self->{'Frontend::Module'}->{'AgentTicketMerge'} =  {
  'Description' => 'Ticket Merge.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Merge'
};
$Self->{'Frontend::Module'}->{'AgentTicketMove'} =  {
  'Description' => 'Ticket Move.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Move'
};
$Self->{'Frontend::Module'}->{'AgentTicketNote'} =  {
  'Description' => 'Ticket Note.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Note'
};
$Self->{'Frontend::Module'}->{'AgentTicketOwner'} =  {
  'Description' => 'Ticket Owner.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Owner'
};
$Self->{'Frontend::Module'}->{'AgentTicketPending'} =  {
  'Description' => 'Ticket Pending.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Pending'
};
$Self->{'Frontend::Module'}->{'AgentTicketPhone'} =  {
  'Description' => 'Create new phone ticket.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'New phone ticket'
};
$Self->{'Frontend::Module'}->{'AgentTicketPhoneInbound'} =  {
  'Description' => 'Incoming Phone Call.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Phone-Ticket'
};
$Self->{'Frontend::Module'}->{'AgentTicketPhoneOutbound'} =  {
  'Description' => 'Phone Call.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Phone-Ticket'
};
$Self->{'Frontend::Module'}->{'AgentTicketPlain'} =  {
  'Description' => 'Ticket plain view of an email.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Plain'
};
$Self->{'Frontend::Module'}->{'AgentTicketPrint'} =  {
  'Description' => 'Ticket Print.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Print'
};
$Self->{'Frontend::Module'}->{'AgentTicketPriority'} =  {
  'Description' => 'Ticket Priority.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Priority'
};
$Self->{'Frontend::Module'}->{'AgentTicketProcess'} =  {
  'Description' => 'Create new process ticket.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'New process ticket'
};
$Self->{'Frontend::Module'}->{'AgentTicketQueue'} =  {
  'Description' => 'Overview of all open Tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'QueueView'
};
$Self->{'Frontend::Module'}->{'AgentTicketQuickClose'} =  {
  'Description' => 'Ticket Close',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Close'
};
$Self->{'Frontend::Module'}->{'AgentTicketResponsible'} =  {
  'Description' => 'Ticket Responsible.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Responsible'
};
$Self->{'Frontend::Module'}->{'AgentTicketResponsibleView'} =  {
  'Description' => 'Responsible Tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Responsible Tickets'
};
$Self->{'Frontend::Module'}->{'AgentTicketSearch'} =  {
  'Description' => 'Search Ticket.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Search'
};
$Self->{'Frontend::Module'}->{'AgentTicketService'} =  {
  'Description' => 'Overview of all open Tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'ServiceView'
};
$Self->{'Frontend::Module'}->{'AgentTicketStatusView'} =  {
  'Description' => 'Overview of all open tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Status view'
};
$Self->{'Frontend::Module'}->{'AgentTicketWatchView'} =  {
  'Description' => 'Watched Tickets.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Watched Tickets'
};
$Self->{'Frontend::Module'}->{'AgentTicketWatcher'} =  {
  'Description' => 'A TicketWatcher Module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket-Watcher',
  'Title' => 'Ticket Watcher'
};
$Self->{'Frontend::Module'}->{'AgentTicketZoom'} =  {
  'Description' => 'Ticket Zoom.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Zoom'
};
$Self->{'Frontend::Module'}->{'AgentTimeAccountingEdit'} =  {
  'Description' => 'Time accounting edit.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'TimeAccounting',
  'Title' => 'Edit'
};
$Self->{'Frontend::Module'}->{'AgentTimeAccountingOverview'} =  {
  'Description' => 'Time accounting overview.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'TimeAccounting',
  'Title' => 'Overview'
};
$Self->{'Frontend::Module'}->{'AgentTimeAccountingReporting'} =  {
  'Description' => 'Time accounting reporting.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'TimeAccounting',
  'Title' => 'Reporting'
};
$Self->{'Frontend::Module'}->{'AgentTimeAccountingReportingTicket'} =  {
  'Description' => 'Time accounting ticket report.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Ticket time report'
};
$Self->{'Frontend::Module'}->{'AgentTimeAccountingSetting'} =  {
  'Description' => 'Time accounting settings.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'NavBarName' => 'TimeAccounting',
  'Title' => 'Settings'
};
$Self->{'Frontend::Module'}->{'AgentTimeAccountingView'} =  {
  'Description' => 'Time accounting view.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'TimeAccounting',
  'Title' => 'View'
};
$Self->{'Frontend::Module'}->{'AgentUserSearch'} =  {
  'Description' => 'Agent User Search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Agent User Search'
};
$Self->{'Frontend::Module'}->{'AgentZoom'} =  {
  'Description' => 'Compat module for AgentZoom to AgentTicketZoom.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'AjaxAttachment'} =  {
  'Description' => 'AjaxAttachment',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'Logout'} =  {
  'Description' => 'Logout',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => ''
};
$Self->{'Frontend::Module'}->{'PictureUpload'} =  {
  'Description' => 'Picture upload module.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Ticket',
  'Title' => 'Picture Upload'
};
$Self->{'Frontend::NavBarModule'}->{'000-AdminContactWD'} =  {
  'Module' => 'Kernel::Output::HTML::NavBar::AdminContactWD'
};
$Self->{'Frontend::NavBarModule'}->{'1-TicketProcesses'} =  {
  'Module' => 'Kernel::Output::HTML::NavBar::AgentTicketProcess'
};
$Self->{'Frontend::NavBarModule'}->{'2-AdminFavourites'} =  {
  'Module' => 'Kernel::Output::HTML::NavBar::AdminFavourites'
};
$Self->{'Frontend::NavBarModule'}->{'6-CustomerCompany'} =  {
  'Module' => 'Kernel::Output::HTML::NavBar::CustomerCompany'
};
$Self->{'Frontend::NavBarModule'}->{'7-AgentTicketService'} =  {
  'Module' => 'Kernel::Output::HTML::NavBar::AgentTicketService'
};
$Self->{'Frontend::Navigation'}->{'Admin'}->{'001-Framework'} =  [
  {
    'AccessKey' => 'a',
    'Block' => 'ItemArea',
    'Description' => 'Admin modules overview.',
    'Group' => [
      'admin'
    ],
    'GroupRo' => [],
    'Link' => 'Action=Admin',
    'LinkOption' => '',
    'Name' => 'Admin',
    'NavBar' => 'Admin',
    'Prio' => '10000',
    'Type' => 'Menu'
  }
];
$Self->{'Frontend::Navigation'}->{'AdminAppointmentCalendarManage'}->{'002-Calendar'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Manage different calendars.',
    'Group' => [
      'admin'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AdminAppointmentCalendarManage',
    'LinkOption' => '',
    'Name' => 'Manage Calendars',
    'NavBar' => 'Calendar',
    'Prio' => '9000',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AdminContactWD'}->{'002-DynamicField'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Edit contacts with data.',
    'Group' => [
      'admin'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AdminContactWD',
    'LinkOption' => '',
    'Name' => 'Edit contacts with data',
    'NavBar' => 'Ticket',
    'Prio' => '900',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AdminCustomerCompany'}->{'001-Framework'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Create and manage customers.',
    'Group' => [
      'admin',
      'users'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AdminCustomerCompany;Nav=Agent',
    'LinkOption' => '',
    'Name' => 'Customer Administration',
    'NavBar' => 'Customers',
    'Prio' => '9100',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AdminCustomerUser'}->{'001-Framework'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Create and manage customer users.',
    'Group' => [
      'admin',
      'users'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AdminCustomerUser;Nav=Agent',
    'LinkOption' => '',
    'Name' => 'Customer User Administration',
    'NavBar' => 'Customers',
    'Prio' => '9000',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentAppointmentAgendaOverview'}->{'002-Calendar'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Overview of all appointments.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentAppointmentAgendaOverview',
    'LinkOption' => '',
    'Name' => 'Agenda Overview',
    'NavBar' => 'Calendar',
    'Prio' => '6500',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentAppointmentCalendarOverview'}->{'002-Calendar'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Appointment Calendar overview page.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentAppointmentCalendarOverview',
    'LinkOption' => '',
    'Name' => 'Calendar',
    'NavBar' => 'Calendar',
    'Prio' => '75',
    'Type' => 'Menu'
  },
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Appointment Calendar overview page.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentAppointmentCalendarOverview',
    'LinkOption' => '',
    'Name' => 'Calendar Overview',
    'NavBar' => 'Calendar',
    'Prio' => '6000',
    'Type' => ''
  },
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Create new appointment.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentAppointmentCalendarOverview;Subaction=AppointmentCreate',
    'LinkOption' => '',
    'Name' => 'New Appointment',
    'NavBar' => 'Calendar',
    'Prio' => '8000',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentCustomerInformationCenter'}->{'001-Framework'} =  [
  {
    'AccessKey' => 'c',
    'Block' => 'ItemArea',
    'Description' => 'Customer Information Center search.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentCustomerInformationCenter',
    'LinkOption' => 'onclick="window.setTimeout(function(){Core.Agent.CustomerInformationCenterSearch.OpenSearchDialog();}, 0); return false;"',
    'Name' => 'Customer Information Center',
    'NavBar' => 'Customers',
    'Prio' => '50',
    'Type' => ''
  },
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Customer Information Center search.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentCustomerInformationCenter',
    'LinkOption' => '',
    'Name' => 'Customers',
    'NavBar' => 'Customers',
    'Prio' => '60',
    'Type' => 'Menu'
  }
];
$Self->{'Frontend::Navigation'}->{'AgentCustomerUserInformationCenter'}->{'001-Framework'} =  [
  {
    'AccessKey' => 'y',
    'Block' => 'ItemArea',
    'Description' => 'Customer User Information Center search.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentCustomerUserInformationCenter',
    'LinkOption' => 'onclick="window.setTimeout(function(){Core.Agent.CustomerUserInformationCenterSearch.OpenSearchDialog();}, 0); return false;"',
    'Name' => 'Customer User Information Center',
    'NavBar' => 'Customers',
    'Prio' => '55',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentDashboard'}->{'001-Framework'} =  [
  {
    'AccessKey' => 'd',
    'Block' => 'ItemArea',
    'Description' => 'Dashboard overview.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentDashboard',
    'LinkOption' => '',
    'Name' => 'Dashboard',
    'NavBar' => 'Dashboard',
    'Prio' => '50',
    'Type' => 'Menu'
  }
];
$Self->{'Frontend::Navigation'}->{'AgentFAQAdd'}->{'002-FAQ'} =  [
  {
    'AccessKey' => 'b',
    'Block' => '',
    'Description' => 'New FAQ Article.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentFAQAdd',
    'LinkOption' => '',
    'Name' => 'New',
    'NavBar' => 'FAQ',
    'Prio' => '920',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentFAQCategory'}->{'002-FAQ'} =  [
  {
    'AccessKey' => 'g',
    'Block' => '',
    'Description' => 'Category Management.',
    'Group' => [
      'admin'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AgentFAQCategory',
    'LinkOption' => '',
    'Name' => 'Category Management',
    'NavBar' => 'FAQ',
    'Prio' => '950',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentFAQExplorer'}->{'002-FAQ'} =  [
  {
    'AccessKey' => 'f',
    'Block' => 'ItemArea',
    'Description' => 'FAQ Area',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentFAQExplorer',
    'LinkOption' => '',
    'Name' => 'FAQ',
    'NavBar' => 'FAQ',
    'Prio' => '350',
    'Type' => 'Menu'
  },
  {
    'AccessKey' => 'x',
    'Block' => '',
    'Description' => 'FAQ Explorer',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentFAQExplorer',
    'LinkOption' => '',
    'Name' => 'Explorer',
    'NavBar' => 'FAQ',
    'Prio' => '910',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentFAQJournal'}->{'002-FAQ'} =  [
  {
    'AccessKey' => 'j',
    'Block' => '',
    'Description' => 'FAQ Journal',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentFAQJournal',
    'LinkOption' => '',
    'Name' => 'Journal',
    'NavBar' => 'FAQ',
    'Prio' => '930',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentFAQLanguage'}->{'002-FAQ'} =  [
  {
    'AccessKey' => 'l',
    'Block' => '',
    'Description' => 'Language Management.',
    'Group' => [
      'admin'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AgentFAQLanguage',
    'LinkOption' => '',
    'Name' => 'Language Management',
    'NavBar' => 'FAQ',
    'Prio' => '940',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentFAQSearch'}->{'002-FAQ'} =  [
  {
    'AccessKey' => 'z',
    'Block' => '',
    'Description' => 'Search FAQ.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentFAQSearch',
    'LinkOption' => 'onclick="Core.Agent.Search.OpenSearchDialog(\'AgentFAQSearch\'); if (event.stopPropagation) { event.stopPropagation(); } else { window.event.cancelBubble = true; } return false;"',
    'Name' => 'Search',
    'NavBar' => 'FAQ',
    'Prio' => '960',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMChange'}->{'003-ITSMChangeManagement'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Change area.',
    'Group' => [],
    'GroupRo' => [
      'itsm-change'
    ],
    'Link' => 'Action=AgentITSMChange',
    'LinkOption' => '',
    'Name' => 'ITSM Changes',
    'NavBar' => 'ITSM Change',
    'Prio' => '3400',
    'Type' => 'Menu'
  },
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Change Overview.',
    'Group' => [],
    'GroupRo' => [
      'itsm-change'
    ],
    'Link' => 'Action=AgentITSMChange',
    'LinkOption' => '',
    'Name' => 'Overview',
    'NavBar' => 'ITSM Change',
    'Prio' => '100',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMChangeAdd'}->{'003-ITSMChangeManagement'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'New',
    'Group' => [],
    'GroupRo' => [
      'itsm-change-manager'
    ],
    'Link' => 'Action=AgentITSMChangeAdd',
    'LinkOption' => '',
    'Name' => 'New',
    'NavBar' => 'ITSM Change',
    'Prio' => '200',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMChangeAddFromTemplate'}->{'003-ITSMChangeManagement'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'New (from template)',
    'Group' => [],
    'GroupRo' => [
      'itsm-change-builder',
      'itsm-change-manager'
    ],
    'Link' => 'Action=AgentITSMChangeAddFromTemplate',
    'LinkOption' => '',
    'Name' => 'New (from template)',
    'NavBar' => 'ITSM Change',
    'Prio' => '250',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMChangePIR'}->{'003-ITSMChangeManagement'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'PIR (Post Implementation Review)',
    'Group' => [],
    'GroupRo' => [
      'itsm-change'
    ],
    'Link' => 'Action=AgentITSMChangePIR',
    'LinkOption' => '',
    'Name' => 'PIR',
    'NavBar' => 'ITSM Change',
    'Prio' => '400',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMChangePSA'}->{'003-ITSMChangeManagement'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Projected Service Availability (PSA)',
    'Group' => [],
    'GroupRo' => [
      'itsm-change'
    ],
    'Link' => 'Action=AgentITSMChangePSA',
    'LinkOption' => '',
    'Name' => 'Projected Service Availability',
    'NavBar' => 'ITSM Change',
    'Prio' => '350',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMChangeSchedule'}->{'003-ITSMChangeManagement'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Change Schedule',
    'Group' => [],
    'GroupRo' => [
      'itsm-change'
    ],
    'Link' => 'Action=AgentITSMChangeSchedule',
    'LinkOption' => '',
    'Name' => 'Schedule',
    'NavBar' => 'ITSM Change',
    'Prio' => '300',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMChangeSearch'}->{'003-ITSMChangeManagement'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Search Changes',
    'Group' => [],
    'GroupRo' => [
      'itsm-change'
    ],
    'Link' => 'Action=AgentITSMChangeSearch',
    'LinkOption' => 'onclick="ITSM.Agent.ChangeManagement.Search.OpenSearchDialog(\'AgentITSMChangeSearch\'); if (event.stopPropagation) { event.stopPropagation(); } else { window.event.cancelBubble = true; } return false;"',
    'Name' => 'Search',
    'NavBar' => 'ITSM Change',
    'Prio' => '600',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMConfigItem'}->{'003-ITSMConfigItem'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Configuration Management Database.',
    'Group' => [],
    'GroupRo' => [
      'itsm-configitem'
    ],
    'Link' => 'Action=AgentITSMConfigItem',
    'LinkOption' => '',
    'Name' => 'CMDB',
    'NavBar' => 'Config Item',
    'Prio' => '3200',
    'Type' => 'Menu'
  },
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Overview.',
    'Group' => [],
    'GroupRo' => [
      'itsm-configitem'
    ],
    'Link' => 'Action=AgentITSMConfigItem',
    'LinkOption' => '',
    'Name' => 'Overview',
    'NavBar' => 'Config Item',
    'Prio' => '100',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMConfigItemAdd'}->{'003-ITSMConfigItem'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'New',
    'Group' => [
      'itsm-configitem'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AgentITSMConfigItemAdd',
    'LinkOption' => '',
    'Name' => 'New',
    'NavBar' => 'Config Item',
    'Prio' => '200',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMConfigItemSearch'}->{'003-ITSMConfigItem'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Search config items.',
    'Group' => [],
    'GroupRo' => [
      'itsm-configitem'
    ],
    'Link' => 'Action=AgentITSMConfigItemSearch',
    'LinkOption' => 'onclick="ITSM.Agent.ConfigItem.Search.OpenSearchDialog(\'AgentITSMConfigItemSearch\'); if (event.stopPropagation) { event.stopPropagation(); } else { window.event.cancelBubble = true; } return false;"',
    'Name' => 'Search',
    'NavBar' => 'Config Item',
    'Prio' => '300',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMSLA'}->{'003-ITSMService'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'SLA Overview',
    'Group' => [],
    'GroupRo' => [
      'itsm-service'
    ],
    'Link' => 'Action=AgentITSMSLA',
    'LinkOption' => '',
    'Name' => 'SLA',
    'NavBar' => 'Service',
    'Prio' => '200',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMService'}->{'003-ITSMService'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Service-Area',
    'Group' => [
      'itsm-service'
    ],
    'GroupRo' => [
      'itsm-service'
    ],
    'Link' => 'Action=AgentITSMService',
    'LinkOption' => '',
    'Name' => 'Services',
    'NavBar' => 'Service',
    'Prio' => '3100',
    'Type' => 'Menu'
  },
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Service Overview',
    'Group' => [
      'itsm-service'
    ],
    'GroupRo' => [
      'itsm-service'
    ],
    'Link' => 'Action=AgentITSMService',
    'LinkOption' => '',
    'Name' => 'Service',
    'NavBar' => 'Service',
    'Prio' => '100',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentITSMTemplateOverview'}->{'003-ITSMChangeManagement'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Template Overview',
    'Group' => [],
    'GroupRo' => [
      'itsm-change-builder',
      'itsm-change-manager'
    ],
    'Link' => 'Action=AgentITSMTemplateOverview',
    'LinkOption' => '',
    'Name' => 'Templates',
    'NavBar' => 'ITSM Change',
    'Prio' => '500',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentStatistics'}->{'001-Framework'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Statistics overview.',
    'Group' => [
      'stats'
    ],
    'GroupRo' => [
      'stats'
    ],
    'Link' => 'Action=AgentStatistics;Subaction=Overview',
    'LinkOption' => '',
    'Name' => 'Reports',
    'NavBar' => 'Reports',
    'Prio' => '8500',
    'Type' => 'Menu'
  },
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Statistics overview.',
    'Group' => [
      'stats'
    ],
    'GroupRo' => [
      'stats'
    ],
    'Link' => 'Action=AgentStatistics;Subaction=Overview',
    'LinkOption' => '',
    'Name' => 'Statistics',
    'NavBar' => 'Reports',
    'Prio' => '200',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentStatisticsReports'}->{'004'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => '',
    'Group' => [
      'stats'
    ],
    'GroupRo' => [
      'stats'
    ],
    'Link' => 'Action=AgentStatisticsReports;Subaction=Overview',
    'LinkOption' => '',
    'Name' => 'Reports',
    'NavBar' => 'Reports',
    'Prio' => '100',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentSurveyAdd'}->{'002-Survey'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'New',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentSurveyAdd',
    'LinkOption' => '',
    'Name' => 'New',
    'NavBar' => 'Survey',
    'Prio' => '200',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentSurveyOverview'}->{'002-Survey'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'A Survey Module.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentSurveyOverview',
    'LinkOption' => '',
    'Name' => 'Survey',
    'NavBar' => 'Survey',
    'Prio' => '8000',
    'Type' => 'Menu'
  },
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Overview',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentSurveyOverview',
    'LinkOption' => '',
    'Name' => 'Overview',
    'NavBar' => 'Survey',
    'Prio' => '100',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTicketEmail'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 'm',
    'Block' => '',
    'Description' => 'Create new email ticket and send this out (outbound).',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketEmail',
    'LinkOption' => '',
    'Name' => 'New email ticket',
    'NavBar' => 'Ticket',
    'Prio' => '210',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTicketEscalationView'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 'e',
    'Block' => '',
    'Description' => 'Overview Escalated Tickets.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketEscalationView',
    'LinkOption' => '',
    'Name' => 'Escalation view',
    'NavBar' => 'Ticket',
    'Prio' => '120',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTicketPhone'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 'n',
    'Block' => '',
    'Description' => 'Create new phone ticket (inbound).',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketPhone',
    'LinkOption' => '',
    'Name' => 'New phone ticket',
    'NavBar' => 'Ticket',
    'Prio' => '200',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTicketProcess'}->{'002-ProcessManagement'} =  [
  {
    'AccessKey' => 'p',
    'Block' => '',
    'Description' => 'Create New process ticket.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketProcess',
    'LinkOption' => '',
    'Name' => 'New process ticket',
    'NavBar' => 'Ticket',
    'Prio' => '220',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTicketQueue'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 'o',
    'Block' => '',
    'Description' => 'Overview of all Tickets per assigned Queue.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketQueue',
    'LinkOption' => '',
    'Name' => 'Queue view',
    'NavBar' => 'Ticket',
    'Prio' => '100',
    'Type' => ''
  },
  {
    'AccessKey' => 't',
    'Block' => 'ItemArea',
    'Description' => 'Overview of all Tickets per assigned Queue.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketQueue',
    'LinkOption' => '',
    'Name' => 'Tickets',
    'NavBar' => 'Ticket',
    'Prio' => '200',
    'Type' => 'Menu'
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTicketSearch'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 's',
    'Block' => '',
    'Description' => 'Search Tickets.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketSearch',
    'LinkOption' => 'onclick="window.setTimeout(function(){Core.Agent.Search.OpenSearchDialog(\'AgentTicketSearch\');}, 0); return false;"',
    'Name' => 'Search',
    'NavBar' => 'Ticket',
    'Prio' => '300',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTicketService'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 'i',
    'Block' => '',
    'Description' => 'Overview of all open Tickets.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketService',
    'LinkOption' => '',
    'Name' => 'Service view',
    'NavBar' => 'Ticket',
    'Prio' => '105',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTicketStatusView'}->{'002-Ticket'} =  [
  {
    'AccessKey' => 'v',
    'Block' => '',
    'Description' => 'Overview of all open Tickets.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTicketStatusView',
    'LinkOption' => '',
    'Name' => 'Status view',
    'NavBar' => 'Ticket',
    'Prio' => '110',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTimeAccountingEdit'}->{'002-TimeAccounting'} =  [
  {
    'AccessKey' => '',
    'Block' => 'ItemArea',
    'Description' => 'Time accounting.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTimeAccountingEdit',
    'LinkOption' => '',
    'Name' => 'Time Accounting',
    'NavBar' => 'TimeAccounting',
    'Prio' => '6000',
    'Type' => 'Menu'
  },
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Edit time record.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTimeAccountingEdit',
    'LinkOption' => '',
    'Name' => 'Edit',
    'NavBar' => 'TimeAccounting',
    'Prio' => '200',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTimeAccountingOverview'}->{'002-TimeAccounting'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Overview.',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=AgentTimeAccountingOverview',
    'LinkOption' => '',
    'Name' => 'Overview',
    'NavBar' => 'TimeAccounting',
    'Prio' => '100',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTimeAccountingReporting'}->{'002-TimeAccounting'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Project time reporting.',
    'Group' => [
      'admin'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AgentTimeAccountingReporting',
    'LinkOption' => '',
    'Name' => 'Reporting',
    'NavBar' => 'TimeAccounting',
    'Prio' => '500',
    'Type' => ''
  }
];
$Self->{'Frontend::Navigation'}->{'AgentTimeAccountingSetting'}->{'002-TimeAccounting'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'Edit time accounting settings.',
    'Group' => [
      'admin'
    ],
    'GroupRo' => [],
    'Link' => 'Action=AgentTimeAccountingSetting',
    'LinkOption' => '',
    'Name' => 'Settings',
    'NavBar' => 'TimeAccounting',
    'Prio' => '900',
    'Type' => ''
  }
];
$Self->{'Frontend::NavigationModule'}->{'Admin'} =  {
  'Block' => '',
  'Description' => 'Admin modules overview.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => '',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => ''
};
$Self->{'Frontend::NavigationModule'}->{'AdminACL'} =  {
  'Block' => 'Automation',
  'Description' => 'Configure and manage ACLs.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-check-square-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Access Control Lists (ACL)'
};
$Self->{'Frontend::NavigationModule'}->{'AdminAbout'} =  {
  'Block' => 'Customer Frontend',
  'Description' => 'Configure the About information.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-file-text-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'About'
};
$Self->{'Frontend::NavigationModule'}->{'AdminAppointmentCalendarManage'} =  {
  'Block' => 'Administration',
  'Description' => 'Create and manage calendars.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-calendar',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Calendars'
};
$Self->{'Frontend::NavigationModule'}->{'AdminAppointmentNotificationEvent'} =  {
  'Block' => 'Communication',
  'Description' => 'Create and manage appointment notifications.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-bell-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Appointment Notifications'
};
$Self->{'Frontend::NavigationModule'}->{'AdminAttachment'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage attachments.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-paperclip',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Attachments'
};
$Self->{'Frontend::NavigationModule'}->{'AdminAutoResponse'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage responses that are automatically sent.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-reply',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Auto Responses'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCommunicationLog'} =  {
  'Block' => 'Communication',
  'Description' => 'Display communication log entries.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-table',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Communication Log'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCustomerAccept'} =  {
  'Block' => 'Customer Frontend',
  'Description' => 'Configure the privacy policy.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-file-text-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Privacy Policy'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCustomerCompany'} =  {
  'Block' => 'Users',
  'Description' => 'Create and manage customers.',
  'Group' => [
    'admin',
    'users'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-building-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Customers'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCustomerDashboardInfoTile'} =  {
  'Block' => 'Administration',
  'Description' => 'Manage Customer Dashboard Info Tile Entries',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-wrench',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Customer Info'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCustomerGroup'} =  {
  'Block' => 'Users',
  'Description' => 'Link customers to groups.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-building-o',
  'IconSmall' => 'fa-users',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Customers ↔ Groups'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCustomerUser'} =  {
  'Block' => 'Users',
  'Description' => 'Create and manage customer users.',
  'Group' => [
    'admin',
    'users'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-male',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Customer Users'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCustomerUserCustomer'} =  {
  'Block' => 'Users',
  'Description' => 'Link customer users to customers.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-male',
  'IconSmall' => 'fa-building-o',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Customer Users ↔ Customers'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCustomerUserGroup'} =  {
  'Block' => 'Users',
  'Description' => 'Link customer users to groups.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-male',
  'IconSmall' => 'fa-users',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Customer Users ↔ Groups'
};
$Self->{'Frontend::NavigationModule'}->{'AdminCustomerUserService'} =  {
  'Block' => 'Users',
  'Description' => 'Link customer users to services.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-male',
  'IconSmall' => 'fa-wrench',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Customer Users ↔ Services'
};
$Self->{'Frontend::NavigationModule'}->{'AdminDynamicField'} =  {
  'Block' => 'Automation',
  'Description' => 'Create and manage dynamic fields.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-align-left',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Dynamic Fields'
};
$Self->{'Frontend::NavigationModule'}->{'AdminDynamicFieldScreen'} =  {
  'Block' => 'Automation',
  'Description' => 'Manage dynamic field in screens.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-align-left',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Dynamic Fields Screens'
};
$Self->{'Frontend::NavigationModule'}->{'AdminEmail'} =  {
  'Block' => 'Communication',
  'Description' => 'Send notifications to users.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-quote-right',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Admin Notification'
};
$Self->{'Frontend::NavigationModule'}->{'AdminGeneralCatalog'} =  {
  'Block' => 'Administration',
  'Description' => 'Create and manage the General Catalog.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-book',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'General Catalog'
};
$Self->{'Frontend::NavigationModule'}->{'AdminGenericAgent'} =  {
  'Block' => 'Automation',
  'Description' => 'Manage tasks triggered by event or time based execution.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-database',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'GenericAgent'
};
$Self->{'Frontend::NavigationModule'}->{'AdminGenericInterfaceWebservice'} =  {
  'Block' => 'Automation',
  'Description' => 'Create and manage web services.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => '',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Web Services'
};
$Self->{'Frontend::NavigationModule'}->{'AdminGroup'} =  {
  'Block' => 'Users',
  'Description' => 'Create and manage groups.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-users',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Groups'
};
$Self->{'Frontend::NavigationModule'}->{'AdminITSMCIPAllocate'} =  {
  'Block' => 'Ticket',
  'Description' => 'Manage the criticality - impact - priority matrix.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-table',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Criticality ↔ Impact ↔ Priority'
};
$Self->{'Frontend::NavigationModule'}->{'AdminITSMChangeCIPAllocate'} =  {
  'Block' => 'ChangeSettings',
  'Description' => 'Manage the category ↔ impact ↔ priority matrix.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-table',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Category ↔ Impact ↔ Priority'
};
$Self->{'Frontend::NavigationModule'}->{'AdminITSMChangeNotification'} =  {
  'Block' => 'Communication',
  'Description' => 'Create and manage change notifications.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-bell-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'ITSM Change Notifications'
};
$Self->{'Frontend::NavigationModule'}->{'AdminITSMConfigItem'} =  {
  'Block' => 'CMDBSettings',
  'Description' => 'Create and manage the definitions for Configuration Items.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-laptop',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Config Items'
};
$Self->{'Frontend::NavigationModule'}->{'AdminITSMStateMachine'} =  {
  'Block' => 'ChangeSettings',
  'Description' => 'Manage ITSM Change Management state machine.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-cogs',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'State Machine'
};
$Self->{'Frontend::NavigationModule'}->{'AdminImportExport'} =  {
  'Block' => 'Administration',
  'Description' => 'Manage import and export of objects.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-arrows-h',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Import/Export'
};
$Self->{'Frontend::NavigationModule'}->{'AdminLog'} =  {
  'Block' => 'Administration',
  'Description' => 'View system log messages.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-file-text-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'System Log'
};
$Self->{'Frontend::NavigationModule'}->{'AdminMailAccount'} =  {
  'Block' => 'Communication',
  'Description' => 'Manage POP3 or IMAP accounts to fetch email from.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-envelope-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'PostMaster Mail Accounts'
};
$Self->{'Frontend::NavigationModule'}->{'AdminNotificationEvent'} =  {
  'Block' => 'Communication',
  'Description' => 'Create and manage ticket notifications.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-bell-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Ticket Notifications'
};
$Self->{'Frontend::NavigationModule'}->{'AdminPGP'} =  {
  'Block' => 'Communication',
  'Description' => 'Manage PGP keys for email encryption.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-user-secret',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'PGP Keys'
};
$Self->{'Frontend::NavigationModule'}->{'AdminPackageManager'} =  {
  'Block' => 'Administration',
  'Description' => 'Update and extend your system with software packages.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-plug',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Package Manager'
};
$Self->{'Frontend::NavigationModule'}->{'AdminPerformanceLog'} =  {
  'Block' => 'Administration',
  'Description' => 'View performance benchmark results.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-bar-chart',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Performance Log'
};
$Self->{'Frontend::NavigationModule'}->{'AdminPostMasterFilter'} =  {
  'Block' => 'Communication',
  'Description' => 'Filter incoming emails.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-filter',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'PostMaster Filters'
};
$Self->{'Frontend::NavigationModule'}->{'AdminPriority'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage ticket priorities.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-list-ol',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Priorities'
};
$Self->{'Frontend::NavigationModule'}->{'AdminProcessManagement'} =  {
  'Block' => 'Automation',
  'Description' => 'Configure Processes.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-sitemap',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Process Management'
};
$Self->{'Frontend::NavigationModule'}->{'AdminQueue'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage queues.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-folder',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Queues'
};
$Self->{'Frontend::NavigationModule'}->{'AdminQueueAutoResponse'} =  {
  'Block' => 'Ticket',
  'Description' => 'Link queues to auto responses.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-reply',
  'IconSmall' => 'fa-folder',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Queues ↔ Auto Responses'
};
$Self->{'Frontend::NavigationModule'}->{'AdminQueueTemplates'} =  {
  'Block' => 'Ticket',
  'Description' => 'Link templates to queues.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-file-text-o',
  'IconSmall' => 'fa-folder',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Templates ↔ Queues'
};
$Self->{'Frontend::NavigationModule'}->{'AdminResponseTemplatesStatePreselection'} =  {
  'Block' => 'Ticket',
  'Description' => 'Manage ticket state pre-selections for response templates.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-th-list',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'State pre-selection for Templates'
};
$Self->{'Frontend::NavigationModule'}->{'AdminRole'} =  {
  'Block' => 'Users',
  'Description' => 'Create and manage roles.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-circle-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Roles'
};
$Self->{'Frontend::NavigationModule'}->{'AdminRoleGroup'} =  {
  'Block' => 'Users',
  'Description' => 'Link roles to groups.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-circle-o',
  'IconSmall' => 'fa-users',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Roles ↔ Groups'
};
$Self->{'Frontend::NavigationModule'}->{'AdminRoleUser'} =  {
  'Block' => 'Users',
  'Description' => 'Link agents to roles.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-user',
  'IconSmall' => 'fa-circle-o',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Agents ↔ Roles'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSLA'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage Service Level Agreements (SLAs).',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-ticket',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Service Level Agreements'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSMIME'} =  {
  'Block' => 'Communication',
  'Description' => 'Manage S/MIME certificates for email encryption.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-user-secret',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'S/MIME Certificates'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSalutation'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage salutations.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-comment-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Salutations'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSelectBox'} =  {
  'Block' => 'Administration',
  'Description' => 'Execute SQL statements.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-terminal',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'SQL Box'
};
$Self->{'Frontend::NavigationModule'}->{'AdminService'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage services.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-wrench',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Services'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSession'} =  {
  'Block' => 'Administration',
  'Description' => 'Manage existing sessions.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-clock-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Session Management'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSignature'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage signatures.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-file-text-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Signatures'
};
$Self->{'Frontend::NavigationModule'}->{'AdminState'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage ticket states.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-ticket',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'States'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSupportDataCollector'} =  {
  'Block' => 'OTOBOTeamServices',
  'Description' => 'Manage support data.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-search',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Support Data Collector'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSystemAddress'} =  {
  'Block' => 'Communication',
  'Description' => 'Set sender email addresses for this system.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-at',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Email Addresses'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSystemConfiguration'} =  {
  'Block' => 'Administration',
  'Description' => 'Edit the system configuration settings.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => '',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'System Configuration'
};
$Self->{'Frontend::NavigationModule'}->{'AdminSystemMaintenance'} =  {
  'Block' => 'Administration',
  'Description' => 'Schedule a maintenance period.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-wrench',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'System Maintenance'
};
$Self->{'Frontend::NavigationModule'}->{'AdminTemplate'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage templates.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-file-text-o',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Templates'
};
$Self->{'Frontend::NavigationModule'}->{'AdminTemplateAttachment'} =  {
  'Block' => 'Ticket',
  'Description' => 'Link templates to attachments.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-paperclip',
  'IconSmall' => 'fa-file-text-o',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Templates ↔ Attachments'
};
$Self->{'Frontend::NavigationModule'}->{'AdminTicketMask'} =  {
  'Block' => 'Automation',
  'Description' => 'Create and manage advanced definitions for ticket masks.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-laptop',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Ticket Masks'
};
$Self->{'Frontend::NavigationModule'}->{'AdminTranslations'} =  {
  'Block' => 'Translations',
  'Description' => 'Create and manage custom translations.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-language',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Translations'
};
$Self->{'Frontend::NavigationModule'}->{'AdminType'} =  {
  'Block' => 'Ticket',
  'Description' => 'Create and manage ticket types.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-ticket',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Types'
};
$Self->{'Frontend::NavigationModule'}->{'AdminUser'} =  {
  'Block' => 'Users',
  'Description' => 'Create and manage agents.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-user',
  'IconSmall' => '',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Agents'
};
$Self->{'Frontend::NavigationModule'}->{'AdminUserGroup'} =  {
  'Block' => 'Users',
  'Description' => 'Link agents to groups.',
  'Group' => [
    'admin'
  ],
  'GroupRo' => [],
  'IconBig' => 'fa-user',
  'IconSmall' => 'fa-users',
  'Module' => 'Kernel::Output::HTML::NavBar::ModuleAdmin',
  'Name' => 'Agents ↔ Groups'
};
$Self->{'Frontend::NotifyModule'}->{'2000-UID-Check'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::UIDCheck'
};
$Self->{'Frontend::NotifyModule'}->{'2500-AgentSessionLimit'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::AgentSessionLimit'
};
$Self->{'Frontend::NotifyModule'}->{'5000-SystemConfigurationIsDirty-Check'} =  {
  'Group' => 'admin',
  'Module' => 'Kernel::Output::HTML::Notification::SystemConfigurationIsDirtyCheck'
};
$Self->{'Frontend::NotifyModule'}->{'5200-SystemConfigurationInvalid-Check'} =  {
  'Group' => 'admin',
  'Module' => 'Kernel::Output::HTML::Notification::SystemConfigurationInvalidCheck'
};
$Self->{'Frontend::NotifyModule'}->{'5500-OutofOffice-Check'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::OutofOfficeCheck'
};
$Self->{'Frontend::NotifyModule'}->{'6000-SystemMaintenance-Check'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::SystemMaintenanceCheck'
};
$Self->{'Frontend::NotifyModule'}->{'6050-SystemConfiguration-OutOfSync-Check'} =  {
  'AllowedDelayMinutes' => '5',
  'Module' => 'Kernel::Output::HTML::Notification::SystemConfigurationOutOfSyncCheck'
};
$Self->{'Frontend::NotifyModule'}->{'7000-AgentTimeZone-Check'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::AgentTimeZoneCheck'
};
$Self->{'Frontend::NotifyModule'}->{'8000-Daemon-Check'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::DaemonCheck'
};
$Self->{'Frontend::NotifyModule'}->{'888-TimeAccounting'} =  {
  'Module' => 'Kernel::Output::HTML::Notification::TimeAccounting'
};
$Self->{'Frontend::Output::FilterElementPost'}->{'FAQ'} =  {
  'Debug' => '0',
  'Module' => 'Kernel::Output::HTML::FilterElementPost::FAQ',
  'Templates' => {
    'AgentTicketClose' => '1',
    'AgentTicketCompose' => '1',
    'AgentTicketEmail' => '1',
    'AgentTicketEmailOutbound' => '1',
    'AgentTicketForward' => '1',
    'AgentTicketFreeText' => '1',
    'AgentTicketNote' => '1',
    'AgentTicketOwner' => '1',
    'AgentTicketPending' => '1',
    'AgentTicketPhone' => '1',
    'AgentTicketPriority' => '1',
    'AgentTicketResponsible' => '1'
  }
};
$Self->{'Frontend::Output::FilterElementPost'}->{'ITSMIncidentProblemManagement'} =  {
  'Debug' => '0',
  'Module' => 'Kernel::Output::HTML::FilterElementPost::ITSMIncidentProblemManagement',
  'Templates' => {
    'AgentTicketAddtlITSMField' => '1',
    'AgentTicketClose' => '1',
    'AgentTicketDecision' => '1',
    'AgentTicketEmail' => '1',
    'AgentTicketFreeText' => '1',
    'AgentTicketNote' => '1',
    'AgentTicketOwner' => '1',
    'AgentTicketPending' => '1',
    'AgentTicketPhone' => '1',
    'AgentTicketPriority' => '1',
    'AgentTicketResponsible' => '1',
    'AgentTicketZoom' => '1'
  }
};
$Self->{'Frontend::Output::FilterElementPost'}->{'OutputFilterPostAddDynamicFieldNames'} =  {
  'Module' => 'Kernel::Output::HTML::FilterElementPost::AddDynamicFieldNames',
  'Templates' => {
    'AgentTicketEmail' => '1',
    'AgentTicketPhone' => '1',
    'CustomerTicketMessage' => '1',
    'ProcessManagement/AgentActivityDialogFooter' => '1',
    'ProcessManagement/CustomerActivityDialogFooter' => '1',
    'ProcessManagement/DynamicField' => '1'
  }
};
$Self->{'Frontend::Output::FilterElementPost'}->{'OutputFilterPostFAQCustomerRelatedArticles'} =  {
  'Module' => 'Kernel::Output::HTML::FilterElementPost::FAQCustomerRelatedArticles',
  'Templates' => {
    'CustomerTicketMessage' => '1'
  }
};
$Self->{'Frontend::Output::FilterElementPost'}->{'Znuny4OTOBOAdvancedDynamicFields'} =  {
  'Module' => 'Kernel::Output::HTML::FilterElementPost::Znuny4OTOBOAdvancedDynamicFields',
  'Templates' => {
    'AdminDynamicField' => '1'
  }
};
$Self->{'Frontend::Output::FilterElementPost'}->{'Znuny4OTOBOShowPendingTimeIfNeeded'} =  {
  'Module' => 'Kernel::Output::HTML::FilterElementPost::Znuny4OTOBOShowPendingTimeIfNeeded',
  'Templates' => {
    'AgentTicketActionCommon' => '1',
    'AgentTicketArticleEdit' => '1',
    'AgentTicketBulk' => '1',
    'AgentTicketClose' => '1',
    'AgentTicketCompose' => '1',
    'AgentTicketEmail' => '1',
    'AgentTicketEmailOutbound' => '1',
    'AgentTicketForward' => '1',
    'AgentTicketFreeText' => '1',
    'AgentTicketMove' => '1',
    'AgentTicketNote' => '1',
    'AgentTicketOwner' => '1',
    'AgentTicketPending' => '1',
    'AgentTicketPhone' => '1',
    'AgentTicketPhoneCommon' => '1',
    'AgentTicketPriority' => '1',
    'AgentTicketResponsible' => '1'
  }
};
$Self->{'Frontend::Output::FilterText'}->{'AAAURL'} =  {
  'Module' => 'Kernel::Output::HTML::FilterText::URL',
  'Templates' => {
    'AgentTicketZoom' => '1'
  }
};
$Self->{'Frontend::RichText'} =  '1';
$Self->{'Frontend::RichText::DefaultCSS'} =  '';
$Self->{'Frontend::RichText::EnhancedMode'} =  '0';
$Self->{'Frontend::RichText::EnhancedMode::Customer'} =  '0';
$Self->{'Frontend::RichTextArticleStyles'} =  'common/css/ckeditor5-47.6.1-content.css';
$Self->{'Frontend::RichTextEditorStyles'} =  'common/css/ckeditor5-47.6.1-editor.css';
$Self->{'Frontend::RichTextHeight'} =  '320';
$Self->{'Frontend::RichTextPath'} =  '<OTOBO_CONFIG_Frontend::WebPath>js/thirdparty/ckeditor5-47.6.1/';
$Self->{'Frontend::RichTextWidth'} =  '620';
$Self->{'Frontend::Search'}->{'AdminSystemConfiguration'} =  {
  '^AdminSystemConfiguration' => 'Action=AdminSystemConfiguration;Subaction=SearchDialog'
};
$Self->{'Frontend::Search'}->{'AgentCustomerInformationCenter'} =  {
  '^AgentCustomerInformationCenter' => 'Action=AgentCustomerInformationCenterSearch'
};
$Self->{'Frontend::Search'}->{'AgentCustomerUserInformationCenter'} =  {
  '^AgentCustomerUserInformationCenter' => 'Action=AgentCustomerUserInformationCenterSearch'
};
$Self->{'Frontend::Search'}->{'Change'} =  {
  '^(?:Agent|Admin)ITSM(Change|WorkOrder|TemplateOverview)' => 'Action=AgentITSMChangeSearch;Subaction=AJAX'
};
$Self->{'Frontend::Search'}->{'ConfigItem'} =  {
  '^(?:Agent|Admin)ITSMConfigItem' => 'Action=AgentITSMConfigItemSearch;Subaction=AJAX'
};
$Self->{'Frontend::Search'}->{'FAQ'} =  {
  '^(?:Agent|Admin)FAQ' => 'Action=AgentFAQSearch;Subaction=AJAX'
};
$Self->{'Frontend::Search'}->{'Ticket'} =  {
  '^AgentTicket' => 'Action=AgentTicketSearch;Subaction=AJAX'
};
$Self->{'Frontend::Search::JavaScript'}->{'AdminSystemConfiguration'} =  {
  '^AdminSystemConfiguration' => 'Core.Agent.Admin.SystemConfiguration.OpenSearchDialog()'
};
$Self->{'Frontend::Search::JavaScript'}->{'AgentCustomerInformationCenter'} =  {
  '^AgentCustomerInformationCenter' => 'Core.Agent.CustomerInformationCenterSearch.OpenSearchDialog()'
};
$Self->{'Frontend::Search::JavaScript'}->{'AgentCustomerUserInformationCenter'} =  {
  '^AgentCustomerUserInformationCenter' => 'Core.Agent.CustomerUserInformationCenterSearch.OpenSearchDialog()'
};
$Self->{'Frontend::Search::JavaScript'}->{'Change'} =  {
  '^(?:Agent|Admin)ITSM(Change|WorkOrder|TemplateOverview)' => 'ITSM.Agent.ChangeManagement.Search.OpenSearchDialog(\'AgentITSMChangeSearch\')'
};
$Self->{'Frontend::Search::JavaScript'}->{'ConfigItem'} =  {
  '^(?:Agent|Admin)ITSMConfigItem' => 'ITSM.Agent.ConfigItem.Search.OpenSearchDialog(\'AgentITSMConfigItemSearch\')'
};
$Self->{'Frontend::SearchDefault'} =  'Action=AgentTicketSearch;Subaction=AJAX';
$Self->{'Frontend::Template::GenerateBlockHooks'}->{'100-Znuny4OTOBOAdvancedDynamicFields'} =  {
  'AdminDynamicField' => [
    'Hint'
  ]
};
$Self->{'Frontend::TemplateCache'} =  '1';
$Self->{'Frontend::Themes'} =  {
  'Lite' => '0',
  'Standard' => '1'
};
$Self->{'Frontend::TicketMasks'}->{'002-DynamicField'} =  [
  'AgentTicketClose',
  'AgentTicketCompose',
  'AgentTicketEmailOutbound',
  'AgentTicketEmail',
  'AgentTicketForward',
  'AgentTicketFreeText',
  'AgentTicketMove',
  'AgentTicketNote',
  'AgentTicketOwner',
  'AgentTicketPending',
  'AgentTicketPhone',
  'AgentTicketPhoneInbound',
  'AgentTicketPhoneOutbound',
  'AgentTicketPriority',
  'AgentTicketResponsible',
  'CustomerTicketMessage',
  'CustomerTicketZoom'
];
$Self->{'Frontend::ToolBarModule'}->{'101-ITSMChangeManagement::ChangeManager'} =  {
  'CssClass' => 'ChangeManager',
  'Icon' => 'fa fa-male',
  'Module' => 'Kernel::Output::HTML::ToolBar::ChangeManager',
  'Priority' => '1000610'
};
$Self->{'Frontend::ToolBarModule'}->{'102-ITSMChangeManagement::MyChanges'} =  {
  'CssClass' => 'MyChanges',
  'Icon' => 'fa fa-retweet',
  'Module' => 'Kernel::Output::HTML::ToolBar::MyChanges',
  'Priority' => '1000630'
};
$Self->{'Frontend::ToolBarModule'}->{'103-ITSMChangeManagement::MyWorkOrders'} =  {
  'CssClass' => 'MyWorkOrders',
  'Icon' => 'fa fa-tasks',
  'Module' => 'Kernel::Output::HTML::ToolBar::MyWorkOrders',
  'Priority' => '1000640'
};
$Self->{'Frontend::ToolBarModule'}->{'104-ITSMChangeManagement::MyCAB'} =  {
  'CssClass' => 'MyCABs',
  'Icon' => 'fa fa-group',
  'Module' => 'Kernel::Output::HTML::ToolBar::MyCAB',
  'Priority' => '1000620'
};
$Self->{'Frontend::ToolBarModule'}->{'110-Ticket::AgentTicketQueue'} =  {
  'AccessKey' => 'q',
  'Action' => 'AgentTicketQueue',
  'CssClass' => 'QueueView',
  'Icon' => 'fa fa-folder',
  'Link' => 'Action=AgentTicketQueue',
  'Module' => 'Kernel::Output::HTML::ToolBar::ShortcutLink',
  'Name' => 'Queue view',
  'Priority' => '1010010'
};
$Self->{'Frontend::ToolBarModule'}->{'140-Ticket::AgentTicketPhone'} =  {
  'AccessKey' => '',
  'Action' => 'AgentTicketPhone',
  'CssClass' => 'PhoneTicket',
  'Icon' => 'fa fa-phone',
  'Link' => 'Action=AgentTicketPhone',
  'Module' => 'Kernel::Output::HTML::ToolBar::ShortcutLink',
  'Name' => 'New phone ticket',
  'Priority' => '1020010'
};
$Self->{'Frontend::ToolBarModule'}->{'150-Ticket::AgentTicketEmail'} =  {
  'AccessKey' => '',
  'Action' => 'AgentTicketEmail',
  'CssClass' => 'EmailTicket',
  'Icon' => 'fa fa-envelope',
  'Link' => 'Action=AgentTicketEmail',
  'Module' => 'Kernel::Output::HTML::ToolBar::ShortcutLink',
  'Name' => 'New email ticket',
  'Priority' => '1020020'
};
$Self->{'Frontend::ToolBarModule'}->{'160-Ticket::AgentTicketProcess'} =  {
  'AccessKey' => '',
  'Action' => 'AgentTicketProcess',
  'CssClass' => 'ProcessTicket',
  'Icon' => 'fa fa-sitemap',
  'Link' => 'Action=AgentTicketProcess',
  'Module' => 'Kernel::Output::HTML::ToolBar::ShortcutLink',
  'Name' => 'New process ticket',
  'Priority' => '1020030'
};
$Self->{'Frontend::ToolBarModule'}->{'170-Ticket::TicketResponsible'} =  {
  'AccessKey' => 'r',
  'AccessKeyNew' => '',
  'AccessKeyReached' => '',
  'CssClass' => 'Responsible',
  'CssClassNew' => 'Responsible New',
  'CssClassReached' => 'Responsible Reached',
  'Icon' => 'fa fa-user',
  'IconNew' => 'fa fa-user',
  'IconReached' => 'fa fa-user',
  'Module' => 'Kernel::Output::HTML::ToolBar::TicketResponsible',
  'Priority' => '1030010'
};
$Self->{'Frontend::ToolBarModule'}->{'180-Ticket::TicketWatcher'} =  {
  'AccessKey' => '',
  'AccessKeyNew' => '',
  'AccessKeyReached' => '',
  'CssClass' => 'Watcher',
  'CssClassNew' => 'Watcher New',
  'CssClassReached' => 'Watcher Reached',
  'Icon' => 'fa fa-eye',
  'IconNew' => 'fa fa-eye',
  'IconReached' => 'fa fa-eye',
  'Module' => 'Kernel::Output::HTML::ToolBar::TicketWatcher',
  'Priority' => '1030020'
};
$Self->{'Frontend::ToolBarModule'}->{'190-Ticket::TicketLocked'} =  {
  'AccessKey' => 'k',
  'AccessKeyNew' => '',
  'AccessKeyReached' => '',
  'CssClass' => 'Locked',
  'CssClassNew' => 'Locked New',
  'CssClassReached' => 'Locked Reached',
  'Icon' => 'fa fa-lock',
  'IconNew' => 'fa fa-lock',
  'IconReached' => 'fa fa-lock',
  'Module' => 'Kernel::Output::HTML::ToolBar::TicketLocked',
  'Priority' => '1030030'
};
$Self->{'Frontend::ToolBarModule'}->{'201-TimeAccounting::IncompleteWorkingDays'} =  {
  'CssClass' => 'IncompleteWorkingDays',
  'Icon' => 'fa fa-clock-o',
  'Module' => 'Kernel::Output::HTML::ToolBar::IncompleteWorkingDays'
};
$Self->{'Frontend::TranslationsDebug'} =  '0';
$Self->{'Frontend::WebPath'} =  '/otobo-web/';
$Self->{'GeneralCatalog::Frontend::JSColorPickerPath'} =  '<OTOBO_CONFIG_Frontend::WebPath>js/thirdparty/jscolor_1.4.1/';
$Self->{'GeneralCatalogPreferences'}->{'Categories'} =  {
  'Block' => 'ConfigItemClassCategories',
  'Class' => 'ITSM::ConfigItem::Class',
  'Data' => {},
  'Desc' => 'Choose categories to assign to this config item class.',
  'Label' => 'Categories',
  'Mandatory' => '1',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'Multiple' => '1',
  'PrefKey' => 'Categories',
  'Priority' => '80'
};
$Self->{'GeneralCatalogPreferences'}->{'ConfigitemGroup'} =  {
  'Block' => 'Option',
  'Class' => 'ITSM::ConfigItem::Class',
  'Data' => {
    '0' => 'Disabled',
    '1' => 'Enabled',
    '2' => 'Enabled and required'
  },
  'Desc' => 'Set mode for config item level group restrictions.',
  'Label' => 'Config Item Group',
  'Mandatory' => '1',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'ConfigItemGroup',
  'Priority' => '25'
};
$Self->{'GeneralCatalogPreferences'}->{'DeploymentStates'} =  {
  'Block' => 'Option',
  'Class' => 'ITSM::ConfigItem::DeploymentState',
  'Data' => {
    'postproductive' => 'postproductive',
    'preproductive' => 'preproductive',
    'productive' => 'productive'
  },
  'Desc' => '',
  'Label' => 'Deployment State Type',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'Functionality',
  'Priority' => '20'
};
$Self->{'GeneralCatalogPreferences'}->{'DeploymentStatesColors'} =  {
  'Block' => 'ColorPicker',
  'Class' => 'ITSM::ConfigItem::DeploymentState',
  'Data' => '',
  'Desc' => '',
  'Label' => 'Deployment State Color',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'Color',
  'Priority' => '25'
};
$Self->{'GeneralCatalogPreferences'}->{'IncidentStates'} =  {
  'Block' => 'Option',
  'Class' => 'ITSM::Core::IncidentState',
  'Data' => {
    'incident' => 'Incident',
    'operational' => 'Operational',
    'warning' => 'Warning'
  },
  'Desc' => '',
  'Label' => 'Incident State Type',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'Functionality',
  'Priority' => '10'
};
$Self->{'GeneralCatalogPreferences'}->{'NameModule'} =  {
  'Block' => 'NameModule',
  'Class' => 'ITSM::ConfigItem::Class',
  'Data' => {},
  'Desc' => 'Choose a module to enforce a naming scheme.',
  'Label' => 'Name Module',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'NameModule',
  'Priority' => '30'
};
$Self->{'GeneralCatalogPreferences'}->{'NumberModule'} =  {
  'Block' => 'NumberModule',
  'Class' => 'ITSM::ConfigItem::Class',
  'Data' => {},
  'Desc' => 'Choose a module to enforce a number scheme.',
  'Label' => 'Number Module',
  'Mandatory' => '1',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'NumberModule',
  'Priority' => '40'
};
$Self->{'GeneralCatalogPreferences'}->{'Permissions'} =  {
  'Block' => 'Permission',
  'Class' => 'ITSM::ConfigItem::Class',
  'Label' => 'Permission Group',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'Permission',
  'Priority' => '10'
};
$Self->{'GeneralCatalogPreferences'}->{'VersionStringExpression'} =  {
  'Block' => 'Input',
  'Class' => 'ITSM::ConfigItem::Class',
  'Desc' => 'Define a Template::Toolkit scheme for version strings. Only used if Version String Module is set to TemplateToolkit.',
  'Label' => 'Version String Expression',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'VersionStringExpression',
  'Priority' => '60'
};
$Self->{'GeneralCatalogPreferences'}->{'VersionStringModule'} =  {
  'Block' => 'VersionStringModule',
  'Class' => 'ITSM::ConfigItem::Class',
  'Data' => {},
  'DataSelected' => 'Incremental',
  'Desc' => 'Choose a module to enforce a version string scheme.',
  'Label' => 'Version String Module',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'PrefKey' => 'VersionStringModule',
  'Priority' => '50'
};
$Self->{'GeneralCatalogPreferences'}->{'VersionTrigger'} =  {
  'Block' => 'ConfigItemVersionTrigger',
  'Class' => 'ITSM::ConfigItem::Class',
  'Data' => {
    'DefinitionUpdate' => 'Definition Update',
    'DeplStateID' => 'DeploymentState',
    'Description' => 'Description',
    'InciStateID' => 'IncidentState',
    'Name' => 'Name'
  },
  'Desc' => 'Choose attributes to trigger the creation of a new version.',
  'Label' => 'Version Trigger',
  'Mandatory' => '0',
  'Module' => 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic',
  'Multiple' => '1',
  'PrefKey' => 'VersionTrigger',
  'Priority' => '70'
};
$Self->{'GenericInterface::ErrorHandling::Module'}->{'RequestRetry'} =  {
  'CommunicationTypeFilter' => 'Requester',
  'ConfigDialog' => 'AdminGenericInterfaceErrorHandlingRequestRetry',
  'Name' => 'RequestRetry'
};
$Self->{'GenericInterface::Invoker::Config'}->{'Article'} =  {
  'ArticleTypeID' => '0',
  'Attachment' => '1',
  'Body' => '1',
  'Cc' => '0',
  'ChangeBy' => '0',
  'ChangeTime' => '0',
  'Charset' => '1',
  'CommunicationChannel' => '1',
  'CommunicationChannelID' => '0',
  'ContentType' => '1',
  'CreateBy' => '0',
  'CreateTime' => '0',
  'From' => '1',
  'IsVisibleForCustomer' => '1',
  'MimeType' => '1',
  'SenderType' => '1',
  'SenderTypeID' => '0',
  'Subject' => '1',
  'TicketID' => '0',
  'TimeUnit' => '1',
  'To' => '0'
};
$Self->{'GenericInterface::Invoker::Config'}->{'Ticket'} =  {
  'Age' => '0',
  'ArchiveFlag' => '0',
  'ChangeBy' => '0',
  'Changed' => '0',
  'CreateBy' => '0',
  'Created' => '0',
  'CustomerID' => '0',
  'CustomerUser' => '1',
  'CustomerUserID' => '0',
  'EscalationResponseTime' => '0',
  'EscalationSolutionTime' => '0',
  'EscalationTime' => '0',
  'EscalationUpdateTime' => '0',
  'Lock' => '1',
  'LockID' => '0',
  'Owner' => '1',
  'OwnerID' => '0',
  'PendingTime' => '1',
  'Priority' => '1',
  'PriorityID' => '0',
  'Queue' => '1',
  'QueueID' => '0',
  'Responsible' => '1',
  'ResponsibleID' => '0',
  'SLA' => '1',
  'SLAID' => '0',
  'Service' => '1',
  'ServiceID' => '0',
  'State' => '1',
  'StateID' => '0',
  'TicketID' => '0',
  'TicketNumber' => '0',
  'Title' => '1',
  'Type' => '1',
  'TypeID' => '0',
  'UntilTime' => '0'
};
$Self->{'GenericInterface::Invoker::Module'}->{'ConfigItem::ConfigItemCreate'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'ConfigItem',
  'Name' => 'ConfigItemCreate'
};
$Self->{'GenericInterface::Invoker::Module'}->{'ConfigItem::ConfigItemFetch'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerConfigItem',
  'Controller' => 'ConfigItem',
  'Name' => 'ConfigItemFetch'
};
$Self->{'GenericInterface::Invoker::Module'}->{'ConfigItem::ConfigItemUpdate'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'ConfigItem',
  'Name' => 'ConfigItemUpdate'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Elasticsearch::ConfigItemManagement'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'ConfigItemManagement',
  'Name' => 'ConfigItemManagement'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Elasticsearch::CustomerCompanyManagement'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'CustomerCompanyManagement',
  'Name' => 'CustomerCompanyManagement'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Elasticsearch::CustomerUserManagement'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'CustomerUserManagement',
  'Name' => 'CustomerUserManagement'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Elasticsearch::Search'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'Search',
  'Name' => 'Search'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Elasticsearch::TicketManagement'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'TicketManagement',
  'Name' => 'TicketManagement'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Elasticsearch::Utils'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'Utils',
  'Name' => 'Utils'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Generic::PassThrough'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerDefault',
  'Controller' => 'Generic',
  'Name' => 'PassThrough'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Ticket::TicketCreate'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerTicket',
  'Controller' => 'Ticket',
  'Name' => 'TicketCreate'
};
$Self->{'GenericInterface::Invoker::Module'}->{'Ticket::TicketUpdate'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceInvokerTicket',
  'Controller' => 'Ticket',
  'Name' => 'TicketUpdate'
};
$Self->{'GenericInterface::Invoker::OutboundHeaderBlacklist'} =  [
  'Content-Length',
  'Content-MD5',
  'Host'
];
$Self->{'GenericInterface::Invoker::Settings::ResponseDynamicField'} =  {};
$Self->{'GenericInterface::Mapping::Module'}->{'Simple'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceMappingSimple'
};
$Self->{'GenericInterface::Mapping::Module'}->{'XSLT'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceMappingXSLT'
};
$Self->{'GenericInterface::Operation::Common::CachedAuth::AgentCacheTTL'} =  '300';
$Self->{'GenericInterface::Operation::Common::CachedAuth::CustomerCacheTTL'} =  '300';
$Self->{'GenericInterface::Operation::ConfigItemDelete'}->{'Permission'} =  'rw';
$Self->{'GenericInterface::Operation::ConfigItemGet'}->{'Permission'} =  'ro';
$Self->{'GenericInterface::Operation::ConfigItemSearch'}->{'Order::Default'} =  'Down';
$Self->{'GenericInterface::Operation::ConfigItemSearch'}->{'Permission'} =  'ro';
$Self->{'GenericInterface::Operation::ConfigItemSearch'}->{'SearchLimit'} =  '500';
$Self->{'GenericInterface::Operation::ConfigItemSearch'}->{'SortBy::Default'} =  'Age';
$Self->{'GenericInterface::Operation::ConfigItemUpsert'}->{'Permission'} =  'rw';
$Self->{'GenericInterface::Operation::Module'}->{'ConfigItem::ConfigItemDelete'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'ConfigItem',
  'Name' => 'ConfigItemDelete'
};
$Self->{'GenericInterface::Operation::Module'}->{'ConfigItem::ConfigItemGet'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'ConfigItem',
  'Name' => 'ConfigItemGet'
};
$Self->{'GenericInterface::Operation::Module'}->{'ConfigItem::ConfigItemSearch'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'ConfigItem',
  'Name' => 'ConfigItemSearch'
};
$Self->{'GenericInterface::Operation::Module'}->{'ConfigItem::ConfigItemUpsert'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationConfigItem',
  'Controller' => 'ConfigItem',
  'Name' => 'ConfigItemUpsert'
};
$Self->{'GenericInterface::Operation::Module'}->{'FAQ::LanguageList'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'FAQ',
  'Name' => 'LanguageList'
};
$Self->{'GenericInterface::Operation::Module'}->{'FAQ::PublicCategoryList'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'FAQ',
  'Name' => 'PublicCategoryList'
};
$Self->{'GenericInterface::Operation::Module'}->{'FAQ::PublicFAQGet'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'FAQ',
  'Name' => 'PublicFAQGet'
};
$Self->{'GenericInterface::Operation::Module'}->{'FAQ::PublicFAQSearch'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'FAQ',
  'Name' => 'PublicFAQSearch'
};
$Self->{'GenericInterface::Operation::Module'}->{'Session::SessionCreate'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'Session',
  'Name' => 'SessionCreate'
};
$Self->{'GenericInterface::Operation::Module'}->{'Session::SessionGet'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'Session',
  'Name' => 'SessionGet'
};
$Self->{'GenericInterface::Operation::Module'}->{'Ticket::TicketCreate'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'Ticket',
  'Name' => 'TicketCreate'
};
$Self->{'GenericInterface::Operation::Module'}->{'Ticket::TicketGet'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'Ticket',
  'Name' => 'TicketGet'
};
$Self->{'GenericInterface::Operation::Module'}->{'Ticket::TicketHistoryGet'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'Ticket',
  'Name' => 'TicketHistoryGet'
};
$Self->{'GenericInterface::Operation::Module'}->{'Ticket::TicketSearch'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'Ticket',
  'Name' => 'TicketGet'
};
$Self->{'GenericInterface::Operation::Module'}->{'Ticket::TicketUpdate'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceOperationDefault',
  'Controller' => 'Ticket',
  'Name' => 'TicketUpdate'
};
$Self->{'GenericInterface::Operation::OutboundHeaderBlacklist'} =  [
  'Connection',
  'Content-Disposition',
  'Content-Length',
  'Content-MD5',
  'Status',
  'Transfer-Encoding'
];
$Self->{'GenericInterface::Operation::ResponseLoggingMaxSize'} =  '200';
$Self->{'GenericInterface::Operation::TicketCreate'}->{'AutoResponseType'} =  'auto reply';
$Self->{'GenericInterface::Operation::TicketCreate'}->{'HistoryComment'} =  '%%GenericInterface Create';
$Self->{'GenericInterface::Operation::TicketCreate'}->{'HistoryType'} =  'NewTicket';
$Self->{'GenericInterface::Operation::TicketCreate'}->{'IsVisibleForCustomer'} =  '1';
$Self->{'GenericInterface::Operation::TicketSearch'}->{'Order::Default'} =  'Down';
$Self->{'GenericInterface::Operation::TicketSearch'}->{'SearchLimit'} =  '500';
$Self->{'GenericInterface::Operation::TicketSearch'}->{'SortBy::Default'} =  'Age';
$Self->{'GenericInterface::Operation::TicketUpdate'}->{'AutoResponseType'} =  'auto follow up';
$Self->{'GenericInterface::Operation::TicketUpdate'}->{'HistoryComment'} =  '%%GenericInterface Note';
$Self->{'GenericInterface::Operation::TicketUpdate'}->{'HistoryType'} =  'AddNote';
$Self->{'GenericInterface::Operation::TicketUpdate'}->{'IsVisibleForCustomer'} =  '1';
$Self->{'GenericInterface::Transport::Module'}->{'HTTP::REST'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceTransportHTTPREST',
  'Name' => 'REST',
  'Protocol' => 'HTTP'
};
$Self->{'GenericInterface::Transport::Module'}->{'HTTP::SOAP'} =  {
  'ConfigDialog' => 'AdminGenericInterfaceTransportHTTPSOAP',
  'Name' => 'SOAP',
  'Protocol' => 'HTTP'
};
$Self->{'GenericInterface::WebserviceConfig::CacheTTL'} =  '86400';
$Self->{'HTTPSForceRedirect'} =  '0';
$Self->{'HttpType'} =  'http';
$Self->{'ITSM::Core::IncidentLinkTypeDirection'} =  {
  'DependsOn' => 'Both',
  'LocationOf' => 'Source'
};
$Self->{'ITSM::Frontend::CIPAllocationDefault'} =  '1';
$Self->{'ITSM::Frontend::TextArea'} =  '78';
$Self->{'ITSMChange::AddChangeLinkTicketTypes'} =  [
  'RfC'
];
$Self->{'ITSMChange::Attribute::CompareValue::FieldType'} =  {
  'AccountedTime' => 'Text',
  'ActualEndTime' => 'Date',
  'ActualStartTime' => 'Date',
  'CategoryID' => 'Selection',
  'ChangeBuilderID' => 'Selection',
  'ChangeManagerID' => 'Selection',
  'ChangeStateID' => 'Selection',
  'ChangeTitle' => 'Text',
  'DynamicField' => 'Text',
  'ImpactID' => 'Selection',
  'PlannedEffort' => 'Text',
  'PlannedEndTime' => 'Date',
  'PlannedStartTime' => 'Date',
  'PriorityID' => 'Selection',
  'RequestedTime' => 'Date'
};
$Self->{'ITSMChange::CacheTTL'} =  '7200';
$Self->{'ITSMChange::Category::Default'} =  '3 normal';
$Self->{'ITSMChange::ChangeSearch::MirrorDB'} =  '0';
$Self->{'ITSMChange::EventModule'}->{'01-HistoryAdd'} =  {
  'Event' => '(ChangeAddPost|ChangeUpdatePost|ChangeCABUpdatePost|ChangeCABDeletePost|ChangeLinkAddPost|ChangeLinkDeletePost|ChangeAttachmentAddPost|ChangeAttachmentDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::HistoryAdd',
  'Transaction' => '0'
};
$Self->{'ITSMChange::EventModule'}->{'02-Notification'} =  {
  'Event' => '(ChangeAddPost|ChangeUpdatePost|ChangeCABUpdatePost|ChangeCABDeletePost|ChangeDeletePost|ChangeLinkAddPost|ChangeLinkDeletePost|ChangeAttachmentAddPost|ChangeAttachmentDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::Notification',
  'Transaction' => '0'
};
$Self->{'ITSMChange::EventModule'}->{'03-Condition'} =  {
  'Event' => '(ChangeAddPost|ChangeUpdatePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::Condition',
  'Transaction' => '0'
};
$Self->{'ITSMChange::EventModule'}->{'1000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'ITSMChange::EventModule'}->{'80-ToolBarChangeManagerCacheDelete'} =  {
  'Event' => '(ChangeAddPost|ChangeUpdatePost|ChangeDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::ToolBarChangeManagerCacheDelete',
  'Transaction' => '0'
};
$Self->{'ITSMChange::EventModule'}->{'81-ToolBarMyChangesCacheDelete'} =  {
  'Event' => '(ChangeAddPost|ChangeUpdatePost|ChangeDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::ToolBarMyChangesCacheDelete',
  'Transaction' => '0'
};
$Self->{'ITSMChange::EventModule'}->{'82-ToolBarMyCABCacheDelete'} =  {
  'Event' => '(ChangeCABUpdatePost|ChangeCABDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::ToolBarMyCABCacheDelete',
  'Transaction' => '0'
};
$Self->{'ITSMChange::EventModule'}->{'90-ConditionDelete'} =  {
  'Event' => '(ChangeDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::ConditionDelete',
  'Transaction' => '0'
};
$Self->{'ITSMChange::EventModule'}->{'91-HistoryDelete'} =  {
  'Event' => '(ChangeDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::HistoryDelete',
  'Transaction' => '0'
};
$Self->{'ITSMChange::Frontend::AdminITSMChangeNotification'}->{'RichText'} =  '1';
$Self->{'ITSMChange::Frontend::AdminITSMChangeNotification'}->{'RichTextHeight'} =  '320';
$Self->{'ITSMChange::Frontend::AdminITSMChangeNotification'}->{'RichTextWidth'} =  '620';
$Self->{'ITSMChange::Frontend::AgentHTMLFieldHeightDefault'} =  '100';
$Self->{'ITSMChange::Frontend::AgentHTMLFieldHeightMax'} =  '2500';
$Self->{'ITSMChange::Frontend::AgentITSMChange'}->{'Filter::ChangeStates'} =  [
  'requested',
  'pending approval',
  'rejected',
  'approved',
  'in progress',
  'pending pir',
  'successful',
  'failed',
  'canceled',
  'retracted'
];
$Self->{'ITSMChange::Frontend::AgentITSMChange'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMChange'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChange'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '1',
  'ChangeManager' => '0',
  'ChangeNumber' => '1',
  'ChangeState' => '1',
  'ChangeStateSignal' => '1',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_ChangeFieldName1' => '0',
  'DynamicField_ChangeFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '1',
  'RequestedTime' => '0',
  'Services' => '0',
  'WorkOrderCount' => '1'
};
$Self->{'ITSMChange::Frontend::AgentITSMChange'}->{'SortBy::Default'} =  'ChangeNumber';
$Self->{'ITSMChange::Frontend::AgentITSMChangeAdd'}->{'DynamicField'} =  {};
$Self->{'ITSMChange::Frontend::AgentITSMChangeAdd'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeAdd'}->{'RequestedTime'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangeAddFromTemplate'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeCABTemplate'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeCondition'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeConditionEdit'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeDelete'}->{'ChangeStates'} =  [
  'requested',
  'pending approval'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangeDelete'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeEdit'}->{'ChangeState'} =  '0';
$Self->{'ITSMChange::Frontend::AgentITSMChangeEdit'}->{'DynamicField'} =  {};
$Self->{'ITSMChange::Frontend::AgentITSMChangeEdit'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeEdit'}->{'RequestedTime'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangeHistory'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangeHistoryZoom'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangeInvolvedPersons'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeManager'}->{'Filter::ChangeStates'} =  [
  'requested',
  'pending approval',
  'approved',
  'in progress',
  'pending pir'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangeManager'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMChangeManager'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangeManager'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '1',
  'ChangeManager' => '1',
  'ChangeNumber' => '1',
  'ChangeState' => '1',
  'ChangeStateSignal' => '1',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_ChangeFieldName1' => '0',
  'DynamicField_ChangeFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '1',
  'RequestedTime' => '0',
  'Services' => '0',
  'WorkOrderCount' => '1'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangeManager'}->{'SortBy::Default'} =  'ChangeNumber';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyCAB'}->{'Filter::ChangeStates'} =  [
  'requested',
  'pending approval',
  'approved',
  'in progress',
  'pending pir'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyCAB'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyCAB'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyCAB'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '1',
  'ChangeManager' => '0',
  'ChangeNumber' => '1',
  'ChangeState' => '1',
  'ChangeStateSignal' => '1',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_ChangeFieldName1' => '0',
  'DynamicField_ChangeFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '1',
  'RequestedTime' => '0',
  'Services' => '0',
  'WorkOrderCount' => '1'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyCAB'}->{'SortBy::Default'} =  'ChangeNumber';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyChanges'}->{'Filter::ChangeStates'} =  [
  'requested',
  'pending approval',
  'approved',
  'in progress',
  'pending pir'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyChanges'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyChanges'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyChanges'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '1',
  'ChangeManager' => '0',
  'ChangeNumber' => '1',
  'ChangeState' => '1',
  'ChangeStateSignal' => '1',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_ChangeFieldName1' => '0',
  'DynamicField_ChangeFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '1',
  'RequestedTime' => '0',
  'Services' => '0',
  'WorkOrderCount' => '1'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyChanges'}->{'SortBy::Default'} =  'PlannedStartTime';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyWorkOrders'}->{'Filter::WorkOrderStates'} =  [
  'created',
  'accepted',
  'ready',
  'in progress'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyWorkOrders'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyWorkOrders'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyWorkOrders'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '0',
  'ChangeManager' => '0',
  'ChangeNumber' => '0',
  'ChangeState' => '0',
  'ChangeStateSignal' => '0',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_WorkOrderFieldName1' => '0',
  'DynamicField_WorkOrderFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '0',
  'RequestedTime' => '0',
  'Services' => '0',
  'WorkOrderAgent' => '1',
  'WorkOrderCount' => '0',
  'WorkOrderNumber' => '1',
  'WorkOrderState' => '1',
  'WorkOrderStateSignal' => '1',
  'WorkOrderTitle' => '1',
  'WorkOrderType' => '0'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangeMyWorkOrders'}->{'SortBy::Default'} =  'PlannedStartTime';
$Self->{'ITSMChange::Frontend::AgentITSMChangePIR'}->{'Filter::WorkOrderStates'} =  [
  'accepted',
  'ready',
  'in progress',
  'closed',
  'canceled'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangePIR'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMChangePIR'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangePIR'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '0',
  'ChangeManager' => '0',
  'ChangeNumber' => '0',
  'ChangeState' => '0',
  'ChangeStateSignal' => '0',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_WorkOrderFieldName1' => '0',
  'DynamicField_WorkOrderFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '0',
  'RequestedTime' => '0',
  'Services' => '0',
  'WorkOrderAgent' => '1',
  'WorkOrderCount' => '0',
  'WorkOrderNumber' => '1',
  'WorkOrderState' => '1',
  'WorkOrderStateSignal' => '1',
  'WorkOrderTitle' => '1',
  'WorkOrderType' => '0'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangePIR'}->{'SortBy::Default'} =  'PlannedStartTime';
$Self->{'ITSMChange::Frontend::AgentITSMChangePIR'}->{'WorkOrderTypes'} =  [
  'pir'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangePSA'}->{'Filter::ChangeStates'} =  [
  'approved'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangePSA'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMChangePSA'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangePSA'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '0',
  'ChangeManager' => '0',
  'ChangeNumber' => '1',
  'ChangeState' => '1',
  'ChangeStateSignal' => '1',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_ChangeFieldName1' => '0',
  'DynamicField_ChangeFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '1',
  'RequestedTime' => '0',
  'Services' => '1',
  'WorkOrderCount' => '0'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangePSA'}->{'SortBy::Default'} =  'PlannedStartTime';
$Self->{'ITSMChange::Frontend::AgentITSMChangePrint'}->{'AccountedTime'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangePrint'}->{'DynamicField'} =  {};
$Self->{'ITSMChange::Frontend::AgentITSMChangePrint'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangePrint'}->{'PlannedEffort'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangePrint'}->{'RequestedTime'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangeReset'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeSchedule'}->{'Filter::ChangeStates'} =  [
  'approved'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangeSchedule'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMChangeSchedule'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangeSchedule'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '1',
  'ChangeManager' => '0',
  'ChangeNumber' => '1',
  'ChangeState' => '1',
  'ChangeStateSignal' => '1',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_ChangeFieldName1' => '0',
  'DynamicField_ChangeFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '1',
  'RequestedTime' => '0',
  'Services' => '0',
  'WorkOrderCount' => '1'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangeSchedule'}->{'SortBy::Default'} =  'PlannedStartTime';
$Self->{'ITSMChange::Frontend::AgentITSMChangeSearch'}->{'DynamicField'} =  {};
$Self->{'ITSMChange::Frontend::AgentITSMChangeSearch'}->{'RequestedTime'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangeSearch'}->{'SearchCSVData'} =  [
  'ChangeNumber',
  'ChangeTitle',
  'ChangeBuilder',
  'WorkOrderCount',
  'ChangeState',
  'Priority',
  'PlannedStartTime',
  'PlannedEndTime'
];
$Self->{'ITSMChange::Frontend::AgentITSMChangeSearch'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '1',
  'ChangeManager' => '0',
  'ChangeNumber' => '1',
  'ChangeState' => '1',
  'ChangeStateSignal' => '1',
  'ChangeTime' => '0',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_ChangeFieldName1' => '0',
  'DynamicField_ChangeFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '1',
  'RequestedTime' => '0',
  'Services' => '0',
  'WorkOrderCount' => '1'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangeTemplate'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeTimeSlot'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'AccountedTime'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'DynamicField'} =  {};
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'PlannedEffort'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'RequestedTime'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'Tooltip::WorkOrderAttributes'} =  {
  'AccountedTime' => '0',
  'ActualEndTime' => '1',
  'ActualStartTime' => '1',
  'DynamicField_WorkOrderFieldName1' => '0',
  'DynamicField_WorkOrderFieldName2' => '0',
  'Instruction' => '0',
  'PlannedEffort' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Report' => '0',
  'WorkOrderAgent' => '1',
  'WorkOrderState' => '1',
  'WorkOrderTitle' => '1',
  'WorkOrderType' => '1'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'WorkOrderGraph'} =  {
  'TimeLineColor' => '#DC143C',
  'TimeLineWidth' => '2',
  'approval_actual_color' => '#FF7F50',
  'approval_planned_color' => '#FF4500',
  'backout_actual_color' => '#C0C0C0',
  'backout_planned_color' => '#696969',
  'pir_actual_color' => '#87CEEB',
  'pir_planned_color' => '#4682B4',
  'undefined_actual_color' => '#F08080',
  'undefined_planned_color' => '#B22222',
  'workorder_actual_color' => '#3CB371',
  'workorder_planned_color' => '#006400'
};
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'WorkOrderState'} =  '0';
$Self->{'ITSMChange::Frontend::AgentITSMChangeZoom'}->{'WorkOrderTitle'} =  '0';
$Self->{'ITSMChange::Frontend::AgentITSMTemplateDelete'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMTemplateEdit'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMTemplateEditCAB'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMTemplateEditContent'}->{'DefaultChangeTitle'} =  'Helper dummy change needed for editing a workorder template';
$Self->{'ITSMChange::Frontend::AgentITSMTemplateEditContent'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMTemplateOverview'}->{'Filter::TemplateTypes'} =  [
  'ITSMChange',
  'ITSMWorkOrder',
  'CAB'
];
$Self->{'ITSMChange::Frontend::AgentITSMTemplateOverview'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::AgentITSMTemplateOverview'}->{'Permission'} =  'ro';
$Self->{'ITSMChange::Frontend::AgentITSMTemplateOverview'}->{'ShowColumns'} =  {
  'ChangeBy' => '0',
  'ChangeTime' => '0',
  'Comment' => '1',
  'CreateBy' => '1',
  'CreateTime' => '1',
  'Delete' => '1',
  'EditContent' => '1',
  'Name' => '1',
  'Type' => '1',
  'Valid' => '1'
};
$Self->{'ITSMChange::Frontend::AgentITSMTemplateOverview'}->{'SortBy::Default'} =  'TemplateID';
$Self->{'ITSMChange::Frontend::AgentITSMWorkOrderAdd'}->{'DynamicField'} =  {};
$Self->{'ITSMChange::Frontend::AgentITSMWorkOrderAdd'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::AgentITSMWorkOrderAdd'}->{'PlannedEffort'} =  '1';
$Self->{'ITSMChange::Frontend::AgentITSMWorkOrderAddFromTemplate'}->{'Permission'} =  'rw';
$Self->{'ITSMChange::Frontend::CustomerITSMChangeSchedule'}->{'Filter::ChangeStates'} =  [
  'approved',
  'in progress'
];
$Self->{'ITSMChange::Frontend::CustomerITSMChangeSchedule'}->{'Order::Default'} =  'Up';
$Self->{'ITSMChange::Frontend::CustomerITSMChangeSchedule'}->{'ShowColumns'} =  {
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'Category' => '0',
  'ChangeBuilder' => '0',
  'ChangeManager' => '0',
  'ChangeNumber' => '1',
  'ChangeState' => '1',
  'ChangeStateSignal' => '1',
  'ChangeTitle' => '1',
  'CreateTime' => '0',
  'DynamicField_ChangeFieldName1' => '0',
  'DynamicField_ChangeFieldName2' => '0',
  'Impact' => '0',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'Priority' => '0',
  'RequestedTime' => '0',
  'Services' => '1',
  'WorkOrderCount' => '0'
};
$Self->{'ITSMChange::Frontend::CustomerITSMChangeSchedule'}->{'ShowOnlyChangesWithAllowedServices'} =  '1';
$Self->{'ITSMChange::Frontend::CustomerITSMChangeSchedule'}->{'SortBy::Default'} =  'PlannedStartTime';
$Self->{'ITSMChange::Frontend::HistoryOrder'} =  'normal';
$Self->{'ITSMChange::Frontend::MenuModule'}->{'000-Back'} =  {
  'Action' => '',
  'Description' => 'Back',
  'Link' => '[% Env("LastScreenChanges") %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Back',
  'Target' => 'Back'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'010-History'} =  {
  'Action' => 'AgentITSMChangeHistory',
  'Description' => 'History',
  'Link' => 'Action=AgentITSMChangeHistory;ChangeID=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'History',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'020-Print'} =  {
  'Action' => 'AgentITSMChangePrint',
  'Description' => 'Print the change.',
  'Link' => 'Action=AgentITSMChangePrint;ChangeID=[% Data.ChangeID | html %]',
  'LinkParam' => 'target="print_change"',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Print',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'030-Edit'} =  {
  'Action' => 'AgentITSMChangeEdit',
  'Description' => 'Edit the change.',
  'Link' => 'Action=AgentITSMChangeEdit;ChangeID=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Edit',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'040-InvolvedPersons'} =  {
  'Action' => 'AgentITSMChangeInvolvedPersons',
  'Description' => 'Change involved persons of the change.',
  'Link' => 'Action=AgentITSMChangeInvolvedPersons;ChangeID=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Involved Persons',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'050-WorkOrderAdd'} =  {
  'Action' => 'AgentITSMWorkOrderAdd',
  'Description' => 'Add a workorder to the change.',
  'Link' => 'Action=AgentITSMWorkOrderAdd;ChangeID=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Add Workorder',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'055-WorkOrderAddFromTemplate'} =  {
  'Action' => 'AgentITSMWorkOrderAddFromTemplate',
  'Description' => 'Add a workorder (from template) to the change.',
  'Link' => 'Action=AgentITSMWorkOrderAddFromTemplate;ChangeID=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Add Workorder (from Template)',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'060-Conditions'} =  {
  'Action' => 'AgentITSMChangeCondition',
  'Description' => 'Edit the conditions of the change.',
  'Link' => 'Action=AgentITSMChangeCondition;ChangeID=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Conditions',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'070-Link'} =  {
  'Action' => 'AgentLinkObject',
  'Description' => 'Link another object to the change.',
  'Link' => 'Action=AgentLinkObject;SourceObject=ITSMChange;SourceKey=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Link',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'080-MoveTimeSlot'} =  {
  'Action' => 'AgentITSMChangeTimeSlot',
  'Description' => 'Move all workorders in time.',
  'Link' => 'Action=AgentITSMChangeTimeSlot;ChangeID=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuTimeSlot',
  'Name' => 'Move Time Slot',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::MenuModule'}->{'090-Template'} =  {
  'Action' => 'AgentITSMChangeTemplate',
  'Description' => 'Save change as a template.',
  'Link' => 'Action=AgentITSMChangeTemplate;ChangeID=[% Data.ChangeID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMChange::MenuGeneric',
  'Name' => 'Template',
  'Target' => 'PopUp'
};
$Self->{'ITSMChange::Frontend::Overview'}->{'Small'} =  {
  'Module' => 'Kernel::Output::HTML::ITSMChange::OverviewSmall',
  'Name' => 'Small',
  'NameShort' => 'S',
  'PageShown' => '25'
};
$Self->{'ITSMChange::Frontend::TemplateOverview'}->{'Small'} =  {
  'Module' => 'Kernel::Output::HTML::ITSMTemplate::OverviewSmall',
  'Name' => 'Small',
  'NameShort' => 'S',
  'PageShown' => '25'
};
$Self->{'ITSMChange::Hook'} =  'Change#';
$Self->{'ITSMChange::Impact::Default'} =  '3 normal';
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'AccountedTime'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'ActualEndTime'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'ActualStartTime'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'CategoryID'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'ChangeBuilderID'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'ChangeManagerID'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'ChangeStateID'} =  {
  'lock' => '1',
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'ChangeTitle'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'DynamicField'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'ImpactID'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'PlannedEffort'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'PlannedEndTime'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'PlannedStartTime'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'PriorityID'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Attribute::Operator'}->{'RequestedTime'} =  {
  'set' => '1'
};
$Self->{'ITSMChange::Mapping::Action::Object::Attribute'} =  {
  'AccountedTime' => '0',
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'CategoryID' => '1',
  'ChangeBuilderID' => '0',
  'ChangeManagerID' => '1',
  'ChangeStateID' => '1',
  'ChangeTitle' => '0',
  'DynamicField' => '1',
  'ImpactID' => '1',
  'PlannedEffort' => '0',
  'PlannedEndTime' => '0',
  'PlannedStartTime' => '0',
  'PriorityID' => '1',
  'RequestedTime' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'AccountedTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '1',
  'is less than' => '1',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'ActualEndTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'ActualStartTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'CategoryID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'ChangeBuilderID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'ChangeManagerID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'ChangeStateID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'ChangeTitle'} =  {
  'begins with' => '1',
  'contains' => '1',
  'ends with' => '1',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '1'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'DynamicField'} =  {
  'begins with' => '1',
  'contains' => '1',
  'ends with' => '1',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '1',
  'is less than' => '1',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '1'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'ImpactID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'PlannedEffort'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '1',
  'is less than' => '1',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'PlannedEndTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'PlannedStartTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'PriorityID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Attribute::Operator'}->{'RequestedTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMChange::Mapping::Expression::Object::Attribute'} =  {
  'AccountedTime' => '1',
  'ActualEndTime' => '1',
  'ActualStartTime' => '1',
  'CategoryID' => '1',
  'ChangeBuilderID' => '1',
  'ChangeManagerID' => '1',
  'ChangeStateID' => '1',
  'ChangeTitle' => '1',
  'DynamicField' => '1',
  'ImpactID' => '1',
  'PlannedEffort' => '1',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'PriorityID' => '1',
  'RequestedTime' => '1'
};
$Self->{'ITSMChange::NumberGenerator'} =  'Kernel::System::ITSMChange::Number::DateChecksum';
$Self->{'ITSMChange::NumberGenerator::AutoIncrement::MinCounterSize'} =  '5';
$Self->{'ITSMChange::NumberGenerator::Date::UseFormattedCounter'} =  '1';
$Self->{'ITSMChange::NumberGenerator::MinCounterSize'} =  '5';
$Self->{'ITSMChange::Permission'}->{'06-AddWorkOrderCheck'} =  {
  'Granted' => '0',
  'Module' => 'Kernel::System::ITSMChange::Permission::AddWorkOrderCheck',
  'Required' => '1'
};
$Self->{'ITSMChange::Permission'}->{'10-ChangeManagerCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMChange::Permission::ChangeManagerCheck',
  'Required' => '0'
};
$Self->{'ITSMChange::Permission'}->{'20-ChangeBuilderCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMChange::Permission::ChangeBuilderCheck',
  'Required' => '0'
};
$Self->{'ITSMChange::Permission'}->{'30-ChangeAgentCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMChange::Permission::ChangeAgentCheck',
  'Required' => '0'
};
$Self->{'ITSMChange::Permission'}->{'40-CABCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMChange::Permission::CABCheck',
  'Required' => '0'
};
$Self->{'ITSMChange::RestrictTicketTypes::Groups'} =  [
  'itsm-change',
  'itsm-change-builder',
  'itsm-change-manager'
];
$Self->{'ITSMChange::SendNotifications'} =  '1';
$Self->{'ITSMChange::State::Signal'} =  {
  'approved' => 'greenled',
  'canceled' => 'redled',
  'failed' => 'redled',
  'in progress' => 'yellowled',
  'pending approval' => 'yellowled',
  'pending pir' => 'yellowled',
  'rejected' => 'redled',
  'requested' => 'grayled',
  'retracted' => 'grayled',
  'successful' => 'greenled'
};
$Self->{'ITSMChange::StateLock::AllowEndStates'} =  '1';
$Self->{'ITSMChange::TimeReachedNotifications'}->{'Frequency'} =  'once';
$Self->{'ITSMChange::TimeReachedNotifications'}->{'Hours'} =  '1';
$Self->{'ITSMChange::ToolBar::CacheTTL'} =  '180';
$Self->{'ITSMChangeCronjob::EventModule'}->{'01-HistoryAdd'} =  {
  'Event' => '(ChangePlannedStartTimeReachedPost|ChangePlannedEndTimeReachedPost|ChangeActualStartTimeReachedPost|ChangeActualEndTimeReachedPost|ChangeRequestedTimeReachedPost|WorkOrderPlannedStartTimeReachedPost|WorkOrderPlannedEndTimeReachedPost|WorkOrderActualStartTimeReachedPost|WorkOrderActualEndTimeReachedPost)',
  'Module' => 'Kernel::System::ITSMChange::Event::HistoryAdd',
  'Transaction' => '0'
};
$Self->{'ITSMChangeCronjob::EventModule'}->{'02-Notification'} =  {
  'Event' => '(ChangePlannedStartTimeReachedPost|ChangePlannedEndTimeReachedPost|ChangeActualStartTimeReachedPost|ChangeActualEndTimeReachedPost|ChangeRequestedTimeReachedPost|WorkOrderPlannedStartTimeReachedPost|WorkOrderPlannedEndTimeReachedPost|WorkOrderActualStartTimeReachedPost|WorkOrderActualEndTimeReachedPost)',
  'Module' => 'Kernel::System::ITSMChange::Event::Notification',
  'Transaction' => '0'
};
$Self->{'ITSMChangeCronjob::EventModule'}->{'03-Condition'} =  {
  'Event' => '(ChangePlannedStartTimeReachedPost|ChangePlannedEndTimeReachedPost|ChangeActualStartTimeReachedPost|ChangeActualEndTimeReachedPost|ChangeRequestedTimeReachedPost|WorkOrderPlannedStartTimeReachedPost|WorkOrderPlannedEndTimeReachedPost|WorkOrderActualStartTimeReachedPost|WorkOrderActualEndTimeReachedPost)',
  'Module' => 'Kernel::System::ITSMChange::Event::Condition',
  'Transaction' => '0'
};
$Self->{'ITSMChangeManagementNotification::EventModule'}->{'01-HistoryAdd'} =  {
  'Event' => '(ChangeNotificationSentPost|WorkOrderNotificationSentPost)',
  'Module' => 'Kernel::System::ITSMChange::Event::HistoryAdd',
  'Transaction' => '0'
};
$Self->{'ITSMCondition::EventModule'}->{'01-HistoryAdd'} =  {
  'Event' => '(ConditionAddPost|ConditionUpdatePost|ConditionDeletePost|ConditionDeleteAllPost|ExpressionAddPost|ExpressionUpdatePost|ExpressionDeletePost|ExpressionDeleteAllPost|ActionAddPost|ActionUpdatePost|ActionDeletePost|ActionDeleteAllPost|ActionExecutePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::HistoryAdd',
  'Transaction' => '0'
};
$Self->{'ITSMCondition::EventModule'}->{'02-Notification'} =  {
  'Event' => '(ActionExecutePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::Notification',
  'Transaction' => '0'
};
$Self->{'ITSMConfigItem::EventModulePost'}->{'042-ITSMConfigItemTicketStatusLink'} =  {
  'Event' => '(LinkAdd|LinkDelete)',
  'Module' => 'Kernel::System::Ticket::Event::TicketStatusLink'
};
$Self->{'ITSMConfigItem::EventModulePost'}->{'100-History'} =  {
  'Event' => '(ConfigItemCreate|VersionCreate|DeploymentStateUpdate|IncidentStateUpdate|ConfigItemDelete|LinkAdd|LinkDelete|DefinitionUpdate|NameUpdate|VersionDelete|AttachmentAddPost|AttachmentDeletePost|ConfigItemDynamicField|GroupUpdate|ConfigItemUpdate|VersionUpdate)',
  'Module' => 'Kernel::System::ITSMConfigItem::Event::DoHistory',
  'Transaction' => '0'
};
$Self->{'ITSMConfigItem::EventModulePost'}->{'300-DefinitionConfigItemUpdate'} =  {
  'Event' => 'DefinitionCreate',
  'Module' => 'Kernel::System::ITSMConfigItem::Event::DefinitionConfigItemUpdate',
  'Transaction' => '1'
};
$Self->{'ITSMConfigItem::EventModulePost'}->{'4000-ScriptDynamicFields'} =  {
  'Event' => '',
  'Module' => 'Kernel::System::ITSMConfigItem::Event::EvaluateScriptFields',
  'Transaction' => '1'
};
$Self->{'ITSMConfigItem::EventModulePost'}->{'9700-GenericInterface'} =  {
  'Event' => '(VersionUpdate|NameUpdate|DeploymentStateUpdate|IncidentStateUpdate|ConfigItemCreate|ConfigItemUpdate|VersionCreate|ConfigItemDelete|AttachmentAddPost|AttachmentDeletePost)',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'ITSMConfigItem::Frontend::AdminITSMConfigItem'}->{'EditorRows'} =  '30';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItem'}->{'DefaultCategory'} =  'All';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItem'}->{'DefaultColumns'} =  {
  'Class' => '2',
  'Created' => '1',
  'CurDeplState' => '2',
  'CurDeplStateType' => '1',
  'CurInciState' => '2',
  'CurInciStateType' => '1',
  'DeplState' => '0',
  'InciState' => '0',
  'LastChanged' => '2',
  'Name' => '2',
  'Number' => '2'
};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItem'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItem'}->{'SearchLimit'} =  '10000';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemAdd'}->{'Permission'} =  'rw';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemAttachment'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemBulk'}->{'DeplState'} =  '1';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemBulk'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemBulk'}->{'InciState'} =  '1';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemBulk'}->{'Permission'} =  'rw';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemDelete'}->{'Permission'} =  'rw';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemEdit'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemEdit'}->{'Permission'} =  'rw';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemEdit'}->{'RichTextHeight'} =  '320';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemEdit'}->{'RichTextWidth'} =  '620';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemHistory'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemLabelPrint'}->{'BarcodeSetting'} =  {
  'BarcodeField' => 'Number',
  'BarcodePosition_X' => '4',
  'BarcodePosition_Y' => '4',
  'Caption' => '0',
  'Code' => 'code128',
  'CustomLink' => '',
  'Font' => 'Helvetica',
  'FontSize' => '10',
  'LowerMendingZone' => '15',
  'QRCodeLink' => 'AgentITSMConfigItemZoom',
  'Scale_X' => '0.7',
  'Scale_Y' => '0.7',
  'Zone' => '20'
};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemLabelPrint'}->{'FooterSetting'} =  {
  'Align' => 'right',
  'Color' => '#000000',
  'Font' => 'Proportional',
  'FontSize' => '4',
  'FooterPosition_X' => '0',
  'FooterPosition_Y' => '8',
  'FooterText' => '',
  'Lead' => '1'
};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemLabelPrint'}->{'HLineSetting'} =  {
  'Color' => '#101010',
  'HLinePosition_X' => 'left',
  'HLinePosition_Y' => '20',
  'LineWidth' => '.5'
};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemLabelPrint'}->{'LogoSetting'} =  {
  'DisplayType' => 'Reduce',
  'ImageHeight' => '179',
  'ImagePosition_X' => 'left',
  'ImagePosition_Y' => 'top',
  'ImageWidth' => '142',
  'LogoPath' => 'var/httpd/htdocs/skins/Agent/default/img/LogoLabelPrint.png',
  'MarginBottom' => '4'
};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemLabelPrint'}->{'PageSetting'} =  {
  'MarginBottom' => '4',
  'MarginLeft' => '4',
  'MarginRight' => '4',
  'MarginTop' => '4',
  'PageHeight' => '40.0',
  'PageOrientation' => 'normal',
  'PageWidth' => '76.6'
};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemLabelPrint'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemLabelPrint'}->{'TableSetting'} =  {
  'Border' => '0',
  'Font' => 'ProportionalBold',
  'FontSize' => '9',
  'Padding' => '1',
  'PaddingBottom' => '3',
  'PaddingLeft' => '3',
  'PaddingRight' => '1',
  'PaddingTop' => '1',
  'TablePosition_X' => '40',
  'TablePosition_Y' => 'top',
  'TitleWidth' => '50',
  'Type' => 'Cut',
  'ValueWidth' => '50'
};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemLabelPrint'}->{'Text'} =  [];
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemPrint'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemPrint'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'Defaults'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'Defaults'}->{'Name'} =  '';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'Defaults'}->{'Number'} =  '';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'ExtendedSearchCondition'} =  '1';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'Order::Default'} =  'Down';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'SearchCSVData'} =  [
  'Class',
  'InciState',
  'Name',
  'Number',
  'DeplState',
  'Version',
  'CreateTime'
];
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'SearchCSVDynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'SearchLimit'} =  '10000';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'SearchPageShown'} =  '40';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemSearch'}->{'SortBy::Default'} =  'Age';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemTreeView'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemZoom'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::AgentITSMConfigItemZoom'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::BulkFeature'} =  '1';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItem'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItem'}->{'SearchLimit'} =  '10000';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'Defaults'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'DeploymentState'} =  '0';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'DynamicField'} =  {};
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'ExtendedSearchCondition'} =  '1';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'IncidentState'} =  '0';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'Order::Default'} =  'Down';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'Permission'} =  'ro';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'SearchLimit'} =  '10000';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'SearchPageShown'} =  '40';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemSearch'}->{'SortBy::Default'} =  'Age';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemZoom'}->{'GeneralInfo'} =  {
  'ChangedTime' => '1',
  'Class' => '1',
  'CreatedTime' => '1',
  'DeploymentState' => '1',
  'IncidentState' => '1',
  'Number' => '1'
};
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemZoom'}->{'VersionsEnabled'} =  '1';
$Self->{'ITSMConfigItem::Frontend::CustomerITSMConfigItemZoom'}->{'VersionsSelectable'} =  '1';
$Self->{'ITSMConfigItem::Frontend::CustomerOverview'}->{'Small'} =  {
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::CustomerOverviewSmall',
  'Name' => 'Small',
  'NameShort' => 'S',
  'PageShown' => '25'
};
$Self->{'ITSMConfigItem::Frontend::HistoryOrder'} =  'normal';
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'000-Back'} =  {
  'Action' => '',
  'Description' => 'Back',
  'Link' => '[% Env("LastScreenOverview") %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Back',
  'Target' => ''
};
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'200-History'} =  {
  'Action' => 'AgentITSMConfigItemHistory',
  'Description' => 'History',
  'Link' => 'Action=AgentITSMConfigItemHistory;ConfigItemID=[% Data.ConfigItemID | html %];VersionID=[% Data.VersionID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'History',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'300-Edit'} =  {
  'Action' => 'AgentITSMConfigItemEdit',
  'Description' => 'Edit',
  'Link' => 'Action=AgentITSMConfigItemEdit;ConfigItemID=[% Data.ConfigItemID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Edit',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'400-Print'} =  {
  'Action' => 'AgentITSMConfigItemPrint',
  'Description' => 'Print',
  'Link' => 'Action=AgentITSMConfigItemPrint;ConfigItemID=[% Data.ConfigItemID | html %];VersionID=[% Data.VersionID | html %]',
  'LinkParam' => 'target="print"',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Print',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'450-LabelPrint'} =  {
  'Action' => 'AgentITSMConfigItemLabelPrint',
  'Description' => 'Label Print',
  'Link' => 'Action=AgentITSMConfigItemLabelPrint;ConfigItemID=[% Data.ConfigItemID | html %];VersionID=[% Data.VersionID | html %]',
  'LinkParam' => 'target="print"',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Label Print',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'500-Link'} =  {
  'Action' => 'AgentLinkObject',
  'Description' => 'Link',
  'Link' => 'Action=AgentLinkObject;SourceObject=ITSMConfigItem;SourceKey=[% Data.ConfigItemID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Link',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'550-TreeView'} =  {
  'Action' => 'AgentITSMConfigItemTreeView',
  'Description' => 'ConfigItem Tree View',
  'Link' => 'Action=AgentITSMConfigItemTreeView;VersionID=[% Data.VersionID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Tree View',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'600-Duplicate'} =  {
  'Action' => 'AgentITSMConfigItemEdit',
  'Description' => 'Duplicate',
  'Link' => 'Action=AgentITSMConfigItemEdit;DuplicateID=[% Data.ConfigItemID | html %];VersionID=[% Data.VersionID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Duplicate',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Frontend::MenuModule'}->{'700-ConfigItemDelete'} =  {
  'Action' => 'AgentITSMConfigItemDelete',
  'ConfirmedActionQueryString' => 'Action=AgentITSMConfigItemDelete;Subaction=ConfigItemDelete;ConfigItemID=[% Data.ConfigItemID | html %]',
  'Description' => 'Delete Configuration Item',
  'DialogContentQueryString' => 'Action=AgentITSMConfigItemDelete;ConfigItemID=[% Data.ConfigItemID | html %]',
  'DialogTitle' => '[% Translate("Delete") | html %] [% Config("ITSMConfigItem::Hook") %] [% Data.Number | html %]',
  'ElementSelector' => '#Menu[% Data.MenuID | html %]',
  'Link' => 'Action=AgentITSMConfigItemDelete;ConfigItemID=[% Data.ConfigItemID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Delete',
  'Target' => 'ConfirmDialog'
};
$Self->{'ITSMConfigItem::Frontend::Overview'}->{'Small'} =  {
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::OverviewSmall',
  'Name' => 'Small',
  'NameShort' => 'S',
  'PageShown' => '25'
};
$Self->{'ITSMConfigItem::Frontend::PreMenuModule'}->{'100-Zoom'} =  {
  'Action' => 'AgentITSMConfigItemZoom',
  'Description' => 'Zoom',
  'Link' => 'Action=AgentITSMConfigItemZoom;ConfigItemID=[% Data.ConfigItemID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Zoom',
  'Target' => ''
};
$Self->{'ITSMConfigItem::Frontend::PreMenuModule'}->{'200-History'} =  {
  'Action' => 'AgentITSMConfigItemHistory',
  'Description' => 'History',
  'Link' => 'Action=AgentITSMConfigItemHistory;ConfigItemID=[% Data.ConfigItemID | html %];VersionID=[% Data.VersionID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'History',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Frontend::PreMenuModule'}->{'300-Duplicate'} =  {
  'Action' => 'AgentITSMConfigItemEdit',
  'Description' => 'Duplicate',
  'Link' => 'Action=AgentITSMConfigItemEdit;DuplicateID=[% Data.ConfigItemID | html %];VersionID=[% Data.VersionID | html %];ReturnToLastScreen=1',
  'Module' => 'Kernel::Output::HTML::ITSMConfigItem::MenuGeneric',
  'Name' => 'Duplicate',
  'Target' => 'PopUp'
};
$Self->{'ITSMConfigItem::Hook'} =  'ConfigItem#';
$Self->{'ITSMConfigItem::LinkStatus::IncidentStates'} =  [
  'Incident',
  'Warning',
  'Operational'
];
$Self->{'ITSMConfigItem::LinkStatus::LinkTypes'} =  {
  'RelevantTo' => 'Incident'
};
$Self->{'ITSMConfigItem::Permission::Class'}->{'010-ClassGroupCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMConfigItem::Permission::ClassGroupCheck',
  'Required' => '0'
};
$Self->{'ITSMConfigItem::Permission::Item'}->{'010-ItemClassGroupCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMConfigItem::Permission::ItemClassGroupCheck',
  'Required' => '0'
};
$Self->{'ITSMConfigItem::SetIncidentStateOnLink'} =  '0';
$Self->{'ITSMConfigItemACLKeysLevel1Change'} =  {
  'Possible' => 'Possible',
  'PossibleAdd' => 'PossibleAdd',
  'PossibleNot' => 'PossibleNot'
};
$Self->{'ITSMConfigItemACLKeysLevel1Match'} =  {
  'Properties' => 'Properties',
  'PropertiesDatabase' => 'PropertiesDatabase'
};
$Self->{'ITSMConfigItemACLKeysLevel2::Possible'} =  {
  'ConfigItem' => 'ConfigItem',
  'Form' => 'Form'
};
$Self->{'ITSMConfigItemACLKeysLevel2::PossibleAdd'} =  {
  'ConfigItem' => 'ConfigItem',
  'Form' => 'Form'
};
$Self->{'ITSMConfigItemACLKeysLevel2::PossibleNot'} =  {
  'ConfigItem' => 'ConfigItem',
  'Form' => 'Form'
};
$Self->{'ITSMConfigItemACLKeysLevel2::Properties'} =  {
  'ConfigItem' => 'ConfigItem',
  'Frontend' => 'Frontend',
  'User' => 'User'
};
$Self->{'ITSMConfigItemACLKeysLevel2::PropertiesDatabase'} =  {
  'ConfigItem' => 'ConfigItem',
  'User' => 'User'
};
$Self->{'ITSMConfigItemACLKeysLevel3::Actions'}->{'100-Default'} =  [
  'AgentITSMConfigItemEdit',
  'AgentITSMConfigItem',
  'CustomerITSMConfigItem'
];
$Self->{'ITSMConfigItemManagementGroup'} =  'admin';
$Self->{'ITSMSLA::Frontend::MenuModule'}->{'000-Back'} =  {
  'Action' => '',
  'Description' => 'Back',
  'Link' => 'Action=AgentITSMSLA',
  'Module' => 'Kernel::Output::HTML::ITSMSLAMenu::Generic',
  'Name' => 'Back',
  'Target' => 'Back'
};
$Self->{'ITSMSLA::Frontend::MenuModule'}->{'100-Print'} =  {
  'Action' => 'AgentITSMSLAPrint',
  'Description' => 'Print',
  'Link' => 'Action=AgentITSMSLAPrint;SLAID=[% Data.SLAID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMSLAMenu::Generic',
  'Name' => 'Print'
};
$Self->{'ITSMService::Frontend::MenuModule'}->{'000-Back'} =  {
  'Action' => '',
  'Description' => 'Back',
  'Link' => 'Action=AgentITSMService',
  'Module' => 'Kernel::Output::HTML::ITSMServiceMenu::Generic',
  'Name' => 'Back',
  'Target' => 'Back'
};
$Self->{'ITSMService::Frontend::MenuModule'}->{'100-Print'} =  {
  'Action' => 'AgentITSMServicePrint',
  'Description' => 'Print',
  'Link' => 'Action=AgentITSMServicePrint;ServiceID=[% Data.ServiceID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMServiceMenu::Generic',
  'Name' => 'Print'
};
$Self->{'ITSMService::Frontend::MenuModule'}->{'200-Link'} =  {
  'Action' => 'AgentITSMService',
  'Description' => 'Link',
  'Link' => 'Action=AgentLinkObject;SourceObject=Service;SourceKey=[% Data.ServiceID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMServiceMenu::Link',
  'Name' => 'Link',
  'Target' => 'PopUp'
};
$Self->{'ITSMStateMachine::Object'}->{'Change'} =  {
  'Class' => 'ITSM::ChangeManagement::Change::State',
  'Name' => 'Change'
};
$Self->{'ITSMStateMachine::Object'}->{'WorkOrder'} =  {
  'Class' => 'ITSM::ChangeManagement::WorkOrder::State',
  'Name' => 'WorkOrder'
};
$Self->{'ITSMWorkOrder::ActualStartTimeSet::States'} =  [
  'in progress'
];
$Self->{'ITSMWorkOrder::Attribute::CompareValue::FieldType'} =  {
  'AccountedTime' => 'Text',
  'ActualEndTime' => 'Date',
  'ActualStartTime' => 'Date',
  'DynamicField' => 'Text',
  'PlannedEffort' => 'Text',
  'PlannedEndTime' => 'Date',
  'PlannedStartTime' => 'Date',
  'WorkOrderAgentID' => 'Selection',
  'WorkOrderNumber' => 'Text',
  'WorkOrderStateID' => 'Selection',
  'WorkOrderTitle' => 'Text',
  'WorkOrderTypeID' => 'Selection'
};
$Self->{'ITSMWorkOrder::EventModule'}->{'01-WorkOrderNumberCalc'} =  {
  'Event' => '(WorkOrderUpdatePost|WorkOrderDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::ITSMWorkOrder::Event::WorkOrderNumberCalc',
  'Transaction' => '0'
};
$Self->{'ITSMWorkOrder::EventModule'}->{'02-WorkOrderActualTimesSet'} =  {
  'Event' => 'WorkOrderUpdatePost',
  'Module' => 'Kernel::System::ITSMChange::ITSMWorkOrder::Event::WorkOrderActualTimesSet',
  'Transaction' => '0'
};
$Self->{'ITSMWorkOrder::EventModule'}->{'03-HistoryAdd'} =  {
  'Event' => '(WorkOrderAddPost|WorkOrderUpdatePost|WorkOrderDeletePost|WorkOrderLinkAddPost|WorkOrderLinkDeletePost|WorkOrderAttachmentAddPost|WorkOrderAttachmentDeletePost|WorkOrderReportAttachmentAddPost|WorkOrderReportAttachmentDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::HistoryAdd',
  'Transaction' => '0'
};
$Self->{'ITSMWorkOrder::EventModule'}->{'04-Notification'} =  {
  'Event' => '(WorkOrderAddPost|WorkOrderUpdatePost|WorkOrderDeletePost|WorkOrderLinkAddPost|WorkOrderLinkDeletePost|WorkOrderAttachmentAddPost|WorkOrderAttachmentDeletePost|WorkOrderReportAttachmentAddPost|WorkOrderReportAttachmentDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::Notification',
  'Transaction' => '0'
};
$Self->{'ITSMWorkOrder::EventModule'}->{'05-Condition'} =  {
  'Event' => '(WorkOrderAddPost|WorkOrderUpdatePost)',
  'Module' => 'Kernel::System::ITSMChange::Event::Condition',
  'Transaction' => '0'
};
$Self->{'ITSMWorkOrder::EventModule'}->{'1000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'ITSMWorkOrder::EventModule'}->{'80-ToolBarMyWorkOrdersCacheDelete'} =  {
  'Event' => '(WorkOrderAddPost|WorkOrderUpdatePost|WorkOrderDeletePost)',
  'Module' => 'Kernel::System::ITSMChange::ITSMWorkOrder::Event::ToolBarMyWorkOrdersCacheDelete',
  'Transaction' => '0'
};
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderAgent'}->{'Permission'} =  'rw';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderDelete'}->{'Permission'} =  'rw';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit'}->{'DynamicField'} =  {};
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit'}->{'MoveFollowingWorkOrders'} =  '1';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit'}->{'Permission'} =  'rw';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderEdit'}->{'PlannedEffort'} =  '1';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderHistory'}->{'Permission'} =  'ro';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderHistoryZoom'}->{'Permission'} =  'ro';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderReport'}->{'AccountedTime'} =  '1';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderReport'}->{'ActualTimeSpan'} =  '0';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderReport'}->{'DynamicField'} =  {};
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderReport'}->{'Permission'} =  'rw';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderTake'}->{'Permission'} =  'rw';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderTemplate'}->{'Permission'} =  'rw';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderZoom'}->{'AccountedTime'} =  '1';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderZoom'}->{'DynamicField'} =  {};
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderZoom'}->{'Permission'} =  'ro';
$Self->{'ITSMWorkOrder::Frontend::AgentITSMWorkOrderZoom'}->{'PlannedEffort'} =  '1';
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'000-Back'} =  {
  'Action' => '',
  'Description' => 'Back',
  'Link' => '[% Env("LastScreenWorkOrders") %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuGeneric',
  'Name' => 'Back',
  'Target' => 'Back'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'010-History'} =  {
  'Action' => 'AgentITSMWorkOrderHistory',
  'Description' => 'History',
  'Link' => 'Action=AgentITSMWorkOrderHistory;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuGeneric',
  'Name' => 'History',
  'Target' => 'PopUp'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'020-Print'} =  {
  'Action' => 'AgentITSMChangePrint',
  'Description' => 'Print the workorder.',
  'Link' => 'Action=AgentITSMChangePrint;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuGeneric',
  'Name' => 'Print',
  'Target' => 'PopUp'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'030-Edit'} =  {
  'Action' => 'AgentITSMWorkOrderEdit',
  'Description' => 'Edit the workorder.',
  'Link' => 'Action=AgentITSMWorkOrderEdit;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuWithPermissionFromChange',
  'Name' => 'Edit',
  'Target' => 'PopUp'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'035-Take'} =  {
  'Action' => 'AgentITSMWorkOrderTake',
  'ConfirmedActionQueryString' => 'Action=AgentITSMWorkOrderTake;Subaction=WorkOrderTake;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Description' => 'Take the workorder.',
  'DialogContentQueryString' => 'Action=AgentITSMWorkOrderTake;WorkOrderID=[% Data.WorkOrderID | html %]',
  'DialogTitle' => '[% Translate("Take Workorder") | html %]: [% Config("ITSMWorkOrder::Hook") %] [% Data.ChangeNumber | html %] - [% Data.WorkOrderNumber | html %]',
  'ElementSelector' => '#Menu[% Data.MenuID | html %]',
  'Link' => 'Action=AgentITSMWorkOrderTake;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuWithTakePermission',
  'Name' => 'Take Workorder',
  'Target' => 'ConfirmDialog'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'040-WorkOrderAgent'} =  {
  'Action' => 'AgentITSMWorkOrderAgent',
  'Description' => 'Set the agent for the workorder.',
  'Link' => 'Action=AgentITSMWorkOrderAgent;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuWithPermissionFromChange',
  'Name' => 'Workorder Agent',
  'Target' => 'PopUp'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'050-Report'} =  {
  'Action' => 'AgentITSMWorkOrderReport',
  'Description' => 'Report',
  'Link' => 'Action=AgentITSMWorkOrderReport;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuGeneric',
  'Name' => 'Report',
  'Target' => 'PopUp'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'060-Link'} =  {
  'Action' => 'AgentLinkObject',
  'Description' => 'Link another object to the workorder.',
  'Link' => 'Action=AgentLinkObject;SourceObject=ITSMWorkOrder;SourceKey=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuGeneric',
  'Name' => 'Link',
  'Target' => 'PopUp'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'080-Template'} =  {
  'Action' => 'AgentITSMWorkOrderTemplate',
  'Description' => 'Save workorder as a template.',
  'Link' => 'Action=AgentITSMWorkOrderTemplate;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuWithPermissionFromChange',
  'Name' => 'Template',
  'Target' => 'PopUp'
};
$Self->{'ITSMWorkOrder::Frontend::MenuModule'}->{'090-WorkOrderDelete'} =  {
  'Action' => 'AgentITSMWorkOrderDelete',
  'ConfirmedActionQueryString' => 'Action=AgentITSMWorkOrderDelete;Subaction=WorkOrderDelete;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Description' => 'Delete the workorder.',
  'DialogContentQueryString' => 'Action=AgentITSMWorkOrderDelete;WorkOrderID=[% Data.WorkOrderID | html %]',
  'DialogTitle' => '[% Translate("Delete") | html %] [% Config("ITSMWorkOrder::Hook") %] [% Data.ChangeNumber | html %]-[% Data.WorkOrderNumber | html %]',
  'ElementSelector' => '#Menu[% Data.MenuID | html %]',
  'Link' => 'Action=AgentITSMWorkOrderDelete;WorkOrderID=[% Data.WorkOrderID | html %]',
  'Module' => 'Kernel::Output::HTML::ITSMWorkOrder::MenuWithPermissionFromChange',
  'Name' => 'Delete',
  'Target' => 'ConfirmDialog'
};
$Self->{'ITSMWorkOrder::Hook'} =  'Workorder#';
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'AccountedTime'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'ActualEndTime'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'ActualStartTime'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'DynamicField'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'PlannedEffort'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'PlannedEndTime'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'PlannedStartTime'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'WorkOrderAgentID'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'WorkOrderNumber'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'WorkOrderStateID'} =  {
  'lock' => '1',
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'WorkOrderTitle'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Attribute::Operator'}->{'WorkOrderTypeID'} =  {
  'set' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Action::Object::Attribute'} =  {
  'AccountedTime' => '0',
  'ActualEndTime' => '0',
  'ActualStartTime' => '0',
  'DynamicField' => '1',
  'PlannedEffort' => '0',
  'PlannedEndTime' => '0',
  'PlannedStartTime' => '0',
  'WorkOrderAgentID' => '1',
  'WorkOrderNumber' => '0',
  'WorkOrderStateID' => '1',
  'WorkOrderTitle' => '0',
  'WorkOrderTypeID' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'AccountedTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '1',
  'is less than' => '1',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'ActualEndTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'ActualStartTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'DynamicField'} =  {
  'begins with' => '1',
  'contains' => '1',
  'ends with' => '1',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '1',
  'is less than' => '1',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'PlannedEffort'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '1',
  'is less than' => '1',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'PlannedEndTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'PlannedStartTime'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '1',
  'is before' => '1',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'WorkOrderAgentID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'WorkOrderNumber'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '1',
  'is less than' => '1',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'WorkOrderStateID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'WorkOrderTitle'} =  {
  'begins with' => '1',
  'contains' => '1',
  'ends with' => '1',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '1',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '1',
  'not contains' => '1'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Attribute::Operator'}->{'WorkOrderTypeID'} =  {
  'begins with' => '0',
  'contains' => '0',
  'ends with' => '0',
  'is' => '1',
  'is after' => '0',
  'is before' => '0',
  'is empty' => '0',
  'is greater than' => '0',
  'is less than' => '0',
  'is not' => '1',
  'is not empty' => '0',
  'not contains' => '0'
};
$Self->{'ITSMWorkOrder::Mapping::Expression::Object::Attribute'} =  {
  'AccountedTime' => '1',
  'ActualEndTime' => '1',
  'ActualStartTime' => '1',
  'DynamicField' => '1',
  'PlannedEffort' => '1',
  'PlannedEndTime' => '1',
  'PlannedStartTime' => '1',
  'WorkOrderAgentID' => '1',
  'WorkOrderNumber' => '1',
  'WorkOrderStateID' => '1',
  'WorkOrderTitle' => '1',
  'WorkOrderTypeID' => '1'
};
$Self->{'ITSMWorkOrder::Permission'}->{'10-ChangeManagerCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMChange::ITSMWorkOrder::Permission::ChangeManagerCheck',
  'Required' => '0'
};
$Self->{'ITSMWorkOrder::Permission'}->{'20-ChangeBuilderCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMChange::ITSMWorkOrder::Permission::ChangeBuilderCheck',
  'Required' => '0'
};
$Self->{'ITSMWorkOrder::Permission'}->{'30-WorkOrderAgentCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMChange::ITSMWorkOrder::Permission::WorkOrderAgentCheck',
  'Required' => '0'
};
$Self->{'ITSMWorkOrder::Permission'}->{'40-CABCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::ITSMChange::ITSMWorkOrder::Permission::CABCheck',
  'Required' => '0'
};
$Self->{'ITSMWorkOrder::State::Signal'} =  {
  'accepted' => 'grayled',
  'canceled' => 'redled',
  'closed' => 'greenled',
  'created' => 'grayled',
  'in progress' => 'yellowled',
  'ready' => 'yellowled'
};
$Self->{'ITSMWorkOrder::StateLock::AllowEndStates'} =  '1';
$Self->{'ITSMWorkOrder::TakePermission::List'} =  {
  '' => '1'
};
$Self->{'ITSMWorkOrder::TimePeriod'} =  {
  'YearPeriodFuture' => '5',
  'YearPeriodPast' => '5'
};
$Self->{'ITSMWorkOrder::Type::Default'} =  'workorder';
$Self->{'Icinga2::Acknowledge::Author'} =  '';
$Self->{'Icinga2::Acknowledge::Comment'} =  'Ticket#<TicketNumber>';
$Self->{'Icinga2::Acknowledge::Enabled'} =  '0';
$Self->{'Icinga2::Acknowledge::FreeField::Host'} =  'DynamicField_TicketFreeText1';
$Self->{'Icinga2::Acknowledge::FreeField::Service'} =  'DynamicField_TicketFreeText2';
$Self->{'Icinga2::Acknowledge::HTTP::Password'} =  'some_pass';
$Self->{'Icinga2::Acknowledge::HTTP::URL'} =  'http://icinga2.example.com:5665/v1/actions/acknowledge-problem';
$Self->{'Icinga2::Acknowledge::HTTP::User'} =  'John';
$Self->{'Icinga2::Acknowledge::Notify'} =  '0';
$Self->{'Icinga2::Acknowledge::Sticky'} =  '1';
$Self->{'ImportExport::FormatBackendRegistration'}->{'CSV'} =  {
  'Module' => 'Kernel::System::ImportExport::FormatBackend::CSV',
  'Name' => 'CSV'
};
$Self->{'ImportExport::ImportExportCustomerCompany::ForceCSVMappingRecreation'} =  '0';
$Self->{'ImportExport::ObjectBackendRegistration'}->{'CustomerCompany'} =  {
  'Module' => 'Kernel::System::ImportExport::ObjectBackend::CustomerCompany',
  'Name' => 'CustomerCompany'
};
$Self->{'ImportExport::ObjectBackendRegistration'}->{'ITSMConfigItem'} =  {
  'Module' => 'Kernel::System::ImportExport::ObjectBackend::ITSMConfigItem',
  'Name' => 'Config Item'
};
$Self->{'ImportExport::ObjectBackendRegistration'}->{'Ticket'} =  {
  'Module' => 'Kernel::System::ImportExport::ObjectBackend::Ticket',
  'Name' => 'Ticket'
};
$Self->{'ImportExport::ObjectBackendRegistration'}->{'Translations'} =  {
  'Module' => 'Kernel::System::ImportExport::ObjectBackend::Translations',
  'Name' => 'Translations'
};
$Self->{'ImportExport::TranslationsImportExport::ForceCSVMappingRecreation'} =  '0';
$Self->{'InfoFile'} =  'AgentInfo';
$Self->{'InfoKey'} =  'wpt22';
$Self->{'KeepStateHeader'} =  'X-OTOBO-FollowUp-State-Keep';
$Self->{'LinkObject::ComplexTable'}->{'Appointment'} =  {
  'DefaultColumns' => {
    'CalendarName' => '1',
    'Changed' => '1',
    'Created' => '1',
    'Description' => '2',
    'EndTime' => '2',
    'Location' => '1',
    'NotificationTime' => '1',
    'StartTime' => '2'
  },
  'Priority' => {
    'CalendarName' => '100',
    'Changed' => '160',
    'Created' => '170',
    'Description' => '110',
    'EndTime' => '130',
    'Location' => '140',
    'NotificationTime' => '150',
    'StartTime' => '120'
  }
};
$Self->{'LinkObject::ComplexTable'}->{'FAQ'} =  {
  'DefaultColumns' => {
    'Approved' => '1',
    'CategoryName' => '1',
    'Changed' => '1',
    'ContentType' => '1',
    'Created' => '2',
    'FAQNumber' => '2',
    'Language' => '1',
    'State' => '2',
    'Title' => '2'
  },
  'Module' => 'Kernel::Output::HTML::LinkObject::FAQ.pm',
  'Priority' => {
    'Approved' => '160',
    'CategoryName' => '140',
    'Changed' => '180',
    'ContentType' => '170',
    'Created' => '130',
    'FAQNumber' => '100',
    'Language' => '150',
    'State' => '120',
    'Title' => '110'
  }
};
$Self->{'LinkObject::ComplexTable'}->{'ITSMChange'} =  {
  'DefaultColumns' => {
    'AccountedTime' => '1',
    'ActualEndTime' => '1',
    'ActualStartTime' => '1',
    'Category' => '2',
    'ChangeState' => '2',
    'ChangeTime' => '2',
    'ChangeTitle' => '2',
    'CreateTime' => '1',
    'Impact' => '2',
    'PlannedEffort' => '1',
    'PlannedEndTime' => '1',
    'PlannedStartTime' => '1',
    'Priority' => '2',
    'RequestedTime' => '1'
  },
  'Module' => 'Kernel::Output::HTML::LinkObject::ITSMChange.pm',
  'Priority' => {
    'AccountedTime' => '200',
    'ActualEndTime' => '180',
    'ActualStartTime' => '170',
    'Category' => '120',
    'ChangeState' => '110',
    'ChangeTime' => '230',
    'ChangeTitle' => '100',
    'CreateTime' => '220',
    'Impact' => '130',
    'PlannedEffort' => '190',
    'PlannedEndTime' => '160',
    'PlannedStartTime' => '150',
    'Priority' => '140',
    'RequestedTime' => '210'
  }
};
$Self->{'LinkObject::ComplexTable'}->{'ITSMWorkOrder'} =  {
  'DefaultColumns' => {
    'AccountedTime' => '1',
    'ActualEndTime' => '1',
    'ActualStartTime' => '1',
    'ChangeTime' => '2',
    'CreateTime' => '1',
    'PlannedEffort' => '1',
    'PlannedEndTime' => '1',
    'PlannedStartTime' => '1',
    'WorkOrderState' => '2',
    'WorkOrderTitle' => '2',
    'WorkOrderType' => '2'
  },
  'Module' => 'Kernel::Output::HTML::LinkObject::ITSMWorkOrder.pm',
  'Priority' => {
    'AccountedTime' => '180',
    'ActualEndTime' => '160',
    'ActualStartTime' => '150',
    'ChangeTime' => '200',
    'CreateTime' => '190',
    'PlannedEffort' => '170',
    'PlannedEndTime' => '140',
    'PlannedStartTime' => '130',
    'WorkOrderState' => '110',
    'WorkOrderTitle' => '100',
    'WorkOrderType' => '120'
  }
};
$Self->{'LinkObject::ComplexTable'}->{'Service'} =  {
  'DefaultColumns' => {
    'ChangeTime' => '1',
    'Comment' => '1',
    'CreateTime' => '1',
    'Criticality' => '2',
    'CurInciState' => '2',
    'Type' => '2'
  },
  'Module' => 'Kernel::Output::HTML::LinkObject::Service.pm',
  'Priority' => {
    'ChangeTime' => '160',
    'Comment' => '110',
    'CreateTime' => '150',
    'Criticality' => '130',
    'CurInciState' => '140',
    'Type' => '120'
  }
};
$Self->{'LinkObject::ComplexTable'}->{'Ticket'} =  {
  'DefaultColumns' => {
    'Age' => '1',
    'Changed' => '1',
    'Created' => '2',
    'CustomerCompanyName' => '1',
    'CustomerID' => '1',
    'CustomerName' => '1',
    'CustomerUserID' => '1',
    'EscalationResponseTime' => '1',
    'EscalationSolutionTime' => '1',
    'EscalationTime' => '1',
    'EscalationUpdateTime' => '1',
    'Lock' => '1',
    'Owner' => '1',
    'PendingTime' => '1',
    'Priority' => '1',
    'Queue' => '2',
    'Responsible' => '1',
    'SLA' => '1',
    'Service' => '1',
    'State' => '2',
    'TicketNumber' => '2',
    'Title' => '2',
    'Type' => '1'
  },
  'Priority' => {
    'Age' => '110',
    'Changed' => '120',
    'Created' => '310',
    'CustomerCompanyName' => '320',
    'CustomerID' => '240',
    'CustomerName' => '250',
    'CustomerUserID' => '260',
    'EscalationResponseTime' => '160',
    'EscalationSolutionTime' => '150',
    'EscalationTime' => '140',
    'EscalationUpdateTime' => '170',
    'Lock' => '200',
    'Owner' => '220',
    'PendingTime' => '130',
    'Priority' => '300',
    'Queue' => '210',
    'Responsible' => '230',
    'SLA' => '290',
    'Service' => '280',
    'State' => '190',
    'TicketNumber' => '100',
    'Title' => '180',
    'Type' => '270'
  }
};
$Self->{'LinkObject::ComplexTable::SettingsVisibility'}->{'Appointment'} =  [
  'AgentTicketZoom'
];
$Self->{'LinkObject::ComplexTable::SettingsVisibility'}->{'FAQ'} =  [
  'AgentFAQZoom'
];
$Self->{'LinkObject::ComplexTable::SettingsVisibility'}->{'ITSMChangeManagement'} =  [
  'AgentITSMChangeZoom',
  'AgentITSMWorkOrderZoom'
];
$Self->{'LinkObject::ComplexTable::SettingsVisibility'}->{'ITSMConfigItem'} =  [
  'AgentITSMConfigItemZoom'
];
$Self->{'LinkObject::ComplexTable::SettingsVisibility'}->{'Service'} =  [
  'AgentITSMServiceZoom'
];
$Self->{'LinkObject::ComplexTable::SettingsVisibility'}->{'Ticket'} =  [
  'AgentTicketZoom'
];
$Self->{'LinkObject::DefaultSubObject'}->{'ITSMConfigItem'} =  'Computer';
$Self->{'LinkObject::EventModulePost'}->{'8000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'LinkObject::ITSMConfigItem::ShowColumns'} =  [
  'CurInciSignal',
  'CurDeplSignal'
];
$Self->{'LinkObject::IgnoreLinkedTicketStateTypes'} =  [
  'merged',
  'removed'
];
$Self->{'LinkObject::PossibleLink'}->{'0200'} =  {
  'Object1' => 'Ticket',
  'Object2' => 'Ticket',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'0201'} =  {
  'Object1' => 'Ticket',
  'Object2' => 'Ticket',
  'Type' => 'ParentChild'
};
$Self->{'LinkObject::PossibleLink'}->{'1200'} =  {
  'Object1' => 'Appointment',
  'Object2' => 'Ticket',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'3200'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'ITSMConfigItem',
  'Type' => 'AlternativeTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3201'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'ITSMConfigItem',
  'Type' => 'ConnectedTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3202'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'ITSMConfigItem',
  'Type' => 'DependsOn'
};
$Self->{'LinkObject::PossibleLink'}->{'3203'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'ITSMConfigItem',
  'Type' => 'Includes'
};
$Self->{'LinkObject::PossibleLink'}->{'3204'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'ITSMConfigItem',
  'Type' => 'RelevantTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3205'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'ITSMConfigItem',
  'Type' => 'LocationOf'
};
$Self->{'LinkObject::PossibleLink'}->{'3220'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'Ticket',
  'Type' => 'AlternativeTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3221'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'Ticket',
  'Type' => 'DependsOn'
};
$Self->{'LinkObject::PossibleLink'}->{'3222'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'Ticket',
  'Type' => 'RelevantTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3240'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'Service',
  'Type' => 'AlternativeTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3241'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'Service',
  'Type' => 'DependsOn'
};
$Self->{'LinkObject::PossibleLink'}->{'3242'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'Service',
  'Type' => 'RelevantTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3260'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'FAQ',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'3261'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'FAQ',
  'Type' => 'ParentChild'
};
$Self->{'LinkObject::PossibleLink'}->{'3262'} =  {
  'Object1' => 'ITSMConfigItem',
  'Object2' => 'FAQ',
  'Type' => 'RelevantTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3280'} =  {
  'Object1' => 'Service',
  'Object2' => 'FAQ',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'3281'} =  {
  'Object1' => 'Service',
  'Object2' => 'FAQ',
  'Type' => 'ParentChild'
};
$Self->{'LinkObject::PossibleLink'}->{'3282'} =  {
  'Object1' => 'Service',
  'Object2' => 'FAQ',
  'Type' => 'RelevantTo'
};
$Self->{'LinkObject::PossibleLink'}->{'3400'} =  {
  'Object1' => 'ITSMWorkOrder',
  'Object2' => 'Service',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'3401'} =  {
  'Object1' => 'ITSMWorkOrder',
  'Object2' => 'Service',
  'Type' => 'DependsOn'
};
$Self->{'LinkObject::PossibleLink'}->{'3410'} =  {
  'Object1' => 'ITSMWorkOrder',
  'Object2' => 'ITSMConfigItem',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'3411'} =  {
  'Object1' => 'ITSMWorkOrder',
  'Object2' => 'ITSMConfigItem',
  'Type' => 'DependsOn'
};
$Self->{'LinkObject::PossibleLink'}->{'3412'} =  {
  'Object1' => 'ITSMWorkOrder',
  'Object2' => 'Ticket',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'3420'} =  {
  'Object1' => 'ITSMChange',
  'Object2' => 'Ticket',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'8301'} =  {
  'Object1' => 'FAQ',
  'Object2' => 'FAQ',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'8302'} =  {
  'Object1' => 'FAQ',
  'Object2' => 'FAQ',
  'Type' => 'ParentChild'
};
$Self->{'LinkObject::PossibleLink'}->{'8303'} =  {
  'Object1' => 'FAQ',
  'Object2' => 'Ticket',
  'Type' => 'Normal'
};
$Self->{'LinkObject::PossibleLink'}->{'8304'} =  {
  'Object1' => 'FAQ',
  'Object2' => 'Ticket',
  'Type' => 'ParentChild'
};
$Self->{'LinkObject::ShowDeleteButton'} =  '1';
$Self->{'LinkObject::StrikeThroughLinkedTicketStateTypes'} =  [
  'merged'
];
$Self->{'LinkObject::Type'}->{'AlternativeTo'} =  {
  'SourceName' => 'Alternative to',
  'TargetName' => 'Alternative to'
};
$Self->{'LinkObject::Type'}->{'ConnectedTo'} =  {
  'SourceName' => 'Connected to',
  'TargetName' => 'Connected to'
};
$Self->{'LinkObject::Type'}->{'DependsOn'} =  {
  'SourceName' => 'Depends on',
  'TargetName' => 'Required for'
};
$Self->{'LinkObject::Type'}->{'Includes'} =  {
  'SourceName' => 'Includes',
  'TargetName' => 'Part of'
};
$Self->{'LinkObject::Type'}->{'LocationOf'} =  {
  'SourceName' => 'Location of',
  'TargetName' => 'Located in'
};
$Self->{'LinkObject::Type'}->{'Normal'} =  {
  'SourceName' => 'Normal',
  'TargetName' => 'Normal'
};
$Self->{'LinkObject::Type'}->{'ParentChild'} =  {
  'SourceName' => 'Parent',
  'TargetName' => 'Child'
};
$Self->{'LinkObject::Type'}->{'RelevantTo'} =  {
  'SourceName' => 'Relevant to',
  'TargetName' => 'Relevant to'
};
$Self->{'LinkObject::TypeGroup'}->{'0001'} =  [
  'Normal',
  'ParentChild'
];
$Self->{'LinkObject::ViewMode'} =  'Complex';
$Self->{'Loader::Agent::CommonCSS'}->{'000-DynamicFieldDB'} =  [
  'DynamicFieldDB.css'
];
$Self->{'Loader::Agent::CommonCSS'}->{'000-Framework'} =  [
  'Core.Reset.css',
  'Core.Default.css',
  'Core.Header.css',
  'Core.OverviewControl.css',
  'Core.OverviewSmall.css',
  'Core.OverviewMedium.css',
  'Core.OverviewLarge.css',
  'Core.Footer.css',
  'Core.PageLayout.css',
  'Core.Form.css',
  'Core.Table.css',
  'Core.Login.css',
  'Core.Widget.css',
  'Core.WidgetMenu.css',
  'Core.TicketDetail.css',
  'Core.Tooltip.css',
  'Core.Dialog.css',
  'Core.InputFields.css',
  'Core.Print.css',
  'Core.Animations.css',
  'Core.Icons.css'
];
$Self->{'Loader::Agent::CommonCSS'}->{'001-Daemon'} =  [
  'Core.Agent.Daemon.css'
];
$Self->{'Loader::Agent::CommonCSS'}->{'100-ITSM'} =  [
  'ITSM.Agent.Default.css',
  'ITSM.Agent.Search.css'
];
$Self->{'Loader::Agent::CommonCSS'}->{'200-FAQ'} =  [
  'FAQ.Agent.Default.css'
];
$Self->{'Loader::Agent::CommonJS'}->{'000-Framework'} =  [
  'thirdparty/jquery-3.7.1/jquery.min.js',
  'thirdparty/jquery-browser-detection/jquery-browser-detection.js',
  'thirdparty/jquery-ui-1.14.1/jquery-ui.min.js',
  'thirdparty/jquery-ui-touch-punch-0.2.3/jquery.ui.touch-punch.js',
  'thirdparty/jquery-validate-1.21.0/jquery.validate.min.js',
  'thirdparty/jquery-pubsub/pubsub.js',
  'thirdparty/jquery-jstree-3.3.7/jquery.jstree.js',
  'thirdparty/nunjucks-3.2.4/nunjucks.min.js',
  'Core.Init.js',
  'Core.JavaScriptEnhancements.js',
  'Core.Debug.js',
  'Core.Exception.js',
  'Core.Data.js',
  'Core.Config.js',
  'Core.Language.js',
  'Core.Template.js',
  'Core.JSON.js',
  'Core.App.js',
  'Core.App.Responsive.js',
  'Core.AJAX.js',
  'Core.UI.js',
  'Core.UI.InputFields.js',
  'Core.UI.Accordion.js',
  'Core.UI.Datepicker.js',
  'Core.UI.DnD.js',
  'Core.UI.Floater.js',
  'Core.UI.Resizable.js',
  'Core.UI.Table.js',
  'Core.UI.Accessibility.js',
  'Core.UI.RichTextEditor.js',
  'Core.UI.Dialog.js',
  'Core.UI.ActionRow.js',
  'Core.UI.Popup.js',
  'Core.UI.TreeSelection.js',
  'Core.UI.Autocomplete.js',
  'Core.Form.js',
  'Core.Form.ErrorTooltips.js',
  'Core.Form.Validate.js',
  'Core.Agent.js',
  'Core.Agent.Search.js',
  'Core.Agent.CustomerInformationCenterSearch.js',
  'Core.Agent.CustomerSearch.js',
  'Core.Agent.CustomerUserInformationCenterSearch.js',
  'Core.Agent.Header.js',
  'Core.UI.Notification.js',
  'Core.UI.Elasticsearch.js',
  'Core.Agent.Responsive.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'001-Daemon'} =  [
  'Core.Agent.Daemon.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'100-ConfigurationManagement'} =  [
  'ITSM.Agent.ConfigItem.Search.js',
  'ITSM.UI.ConfigItemActionRow.js',
  'ITSM.Agent.ConfigItem.Dashboard.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'100-Framework'} =  [
  'Core.Agent.DynamicField.Attachment.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'100-GeneralCatalog'} =  [
  'thirdparty/jscolor_1.4.1/jscolor.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'100-ITSM'} =  [
  'ITSM.Agent.CustomerSearch.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'100-ITSMChangeManagement'} =  [
  'ITSM.Agent.ChangeManagement.CABMemberSearch.js',
  'ITSM.Agent.ChangeManagement.Search.js',
  'ITSM.Agent.ChangeManagement.UserSearch.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'100-Queue'} =  [
  'thirdparty/jscolor_1.4.1/jscolor.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'100-SLA'} =  [
  'thirdparty/jscolor_1.4.1/jscolor.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'100-Type'} =  [
  'thirdparty/jscolor_1.4.1/jscolor.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'200-DynamicFieldContactWD'} =  [
  'Core.Agent.DynamicFieldContactWDSearch.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'200-DynamicFieldDB'} =  [
  'Core.Agent.DynamicFieldDBSearch.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'200-DynamicFieldReference'} =  [
  'Core.Agent.DynamicFieldReferenceSearch.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'200-FAQ'} =  [
  'FAQ.Agent.TicketCompose.js'
];
$Self->{'Loader::Agent::CommonJS'}->{'999-Znuny4OTOBOShowPendingTimeIfNeeded'} =  [
  'Core.Agent.Znuny4OTOBOShowPendingTimeIfNeeded.js'
];
$Self->{'Loader::Agent::DefaultSelectedSkin'} =  'default';
$Self->{'Loader::Agent::ResponsiveCSS'}->{'000-Framework'} =  [
  'Core.Responsive.css'
];
$Self->{'Loader::Agent::Skin'}->{'000-default'} =  {
  'Description' => 'This is the default orange - black skin.',
  'HomePage' => 'https://ncs.com.sg',
  'InternalName' => 'default',
  'VisibleName' => 'Default'
};
$Self->{'Loader::Agent::Skin'}->{'002-high-contrast'} =  {
  'Description' => 'High contrast skin for visually impaired users.',
  'HomePage' => 'www.otrs.com',
  'InternalName' => 'highcontrast',
  'VisibleName' => 'High Contrast'
};
$Self->{'Loader::Customer::CommonCSS'}->{'000-DynamicFieldAttachment'} =  [
  'Core.DynamicFieldAttachment.css'
];
$Self->{'Loader::Customer::CommonCSS'}->{'000-DynamicFieldDB'} =  [
  'DynamicFieldDB.css'
];
$Self->{'Loader::Customer::CommonCSS'}->{'000-Framework'} =  [
  'Core.Layout.css',
  'Core.NavigationBar.css',
  'Core.Reset.css',
  'Core.Default.css',
  'Core.Form.css',
  'Core.Dialog.css',
  'Core.Control.css',
  'Core.Table.css',
  'Core.InputFields.css',
  'Core.Print.css',
  'Core.Animations.css',
  'Core.Icons.css',
  'Core.Footer.css',
  'Core.Items.css',
  'ExtendedCDBInfo.Tile.css'
];
$Self->{'Loader::Customer::CommonJS'}->{'000-Framework'} =  [
  'thirdparty/jquery-3.7.1/jquery.min.js',
  'thirdparty/jquery-browser-detection/jquery-browser-detection.js',
  'thirdparty/jquery-validate-1.21.0/jquery.validate.min.js',
  'thirdparty/jquery-ui-1.14.1/jquery-ui.min.js',
  'thirdparty/jquery-pubsub/pubsub.js',
  'thirdparty/jquery-jstree-3.3.7/jquery.jstree.js',
  'thirdparty/nunjucks-3.2.4/nunjucks.min.js',
  'Core.Init.js',
  'Core.Debug.js',
  'Core.Exception.js',
  'Core.Data.js',
  'Core.JSON.js',
  'Core.JavaScriptEnhancements.js',
  'Core.Config.js',
  'Core.Language.js',
  'Core.Template.js',
  'Core.App.js',
  'Core.App.Responsive.js',
  'Core.AJAX.js',
  'Core.UI.js',
  'Core.UI.InputFields.js',
  'Core.UI.Accessibility.js',
  'Core.UI.Dialog.js',
  'Core.UI.Floater.js',
  'Core.UI.RichTextEditor.js',
  'Core.UI.Datepicker.js',
  'Core.UI.Popup.js',
  'Core.UI.TreeSelection.js',
  'Core.UI.Autocomplete.js',
  'Core.Form.js',
  'Core.Form.ErrorTooltips.js',
  'Core.Form.Validate.js',
  'Core.Customer.js',
  'Core.Customer.Responsive.js',
  'Core.UI.NavigationBar.js',
  'Core.UI.Elasticsearch.js',
  'ExtendedCDBInfo.Tile.js'
];
$Self->{'Loader::Customer::CommonJS'}->{'100-Framework'} =  [
  'Core.Agent.DynamicField.Attachment.js'
];
$Self->{'Loader::Customer::CommonJS'}->{'200-DynamicFieldDB'} =  [
  'Core.Agent.DynamicFieldDBSearch.js'
];
$Self->{'Loader::Customer::ResponsiveCSS'}->{'000-Framework'} =  [
  'Core.Responsive.css'
];
$Self->{'Loader::Customer::SelectedSkin'} =  'default';
$Self->{'Loader::Customer::Skin'}->{'000-default'} =  {
  'Description' => 'This is the default orange - black skin for the customer interface.',
  'HomePage' => 'https://ncs.com.sg',
  'InternalName' => 'default',
  'VisibleName' => 'Default'
};
$Self->{'Loader::Customer::Skin'}->{'001-high-contrast'} =  {
  'Description' => 'High contrast skin for visually impaired users.',
  'HomePage' => 'https://ncs.com.sg',
  'InternalName' => 'highcontrast',
  'VisibleName' => 'High Contrast'
};
$Self->{'Loader::Enabled::CSS'} =  '1';
$Self->{'Loader::Enabled::JS'} =  '1';
$Self->{'Loader::Module::Admin'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.js',
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js'
  ]
};
$Self->{'Loader::Module::AdminACL'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.Admin.ACL.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.ACL.js'
  ]
};
$Self->{'Loader::Module::AdminAbout'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.About.js'
  ]
};
$Self->{'Loader::Module::AdminAppointmentCalendarManage'}->{'002-Calendar'} =  {
  'CSS' => [
    'Core.AppointmentCalendar.Manage.css',
    'thirdparty/spectrum-1.8.1/spectrum.css'
  ],
  'JavaScript' => [
    'thirdparty/clipboardjs-1.7.1/clipboard.min.js',
    'thirdparty/spectrum-1.8.1/spectrum.js',
    'Core.Agent.Admin.AppointmentCalendar.Manage.js'
  ]
};
$Self->{'Loader::Module::AdminAppointmentNotificationEvent'}->{'002-Calendar'} =  {
  'CSS' => [
    'Core.Agent.Admin.NotificationEvent.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.NotificationEvent.js'
  ]
};
$Self->{'Loader::Module::AdminAttachment'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Attachment.js'
  ]
};
$Self->{'Loader::Module::AdminAutoResponse'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.AutoResponse.js'
  ]
};
$Self->{'Loader::Module::AdminCloudServiceSupportDataCollector'}->{'002-CloudServices'} =  {
  'CSS' => [
    'Core.Agent.Admin.CloudService.SupportDataCollector.css'
  ]
};
$Self->{'Loader::Module::AdminCloudServices'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.CloudServices.css'
  ]
};
$Self->{'Loader::Module::AdminCommunicationLog'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.CommunicationLog.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.CommunicationLog.js',
    'thirdparty/jquery-tablesorter-2.28.14/jquery.tablesorter.js',
    'Core.UI.Table.Sort.js'
  ]
};
$Self->{'Loader::Module::AdminCustomerAccept'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.CustomerAccept.js'
  ]
};
$Self->{'Loader::Module::AdminCustomerCompany'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.CustomerCompany.js'
  ]
};
$Self->{'Loader::Module::AdminCustomerDashboardInfoTile'}->{'002-ExtendedCustomerDashboardInfoTile'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.CustomerDashboardInfoTile.js'
  ]
};
$Self->{'Loader::Module::AdminCustomerGroup'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.CustomerGroup.js'
  ]
};
$Self->{'Loader::Module::AdminCustomerUser'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.Admin.CustomerUser.js'
  ]
};
$Self->{'Loader::Module::AdminCustomerUserCustomer'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.CustomerUserService.js'
  ]
};
$Self->{'Loader::Module::AdminCustomerUserGroup'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.CustomerGroup.js'
  ]
};
$Self->{'Loader::Module::AdminCustomerUserService'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.CustomerUserService.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicField'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldAttachment'}->{'002-OTOBODynamicFieldAttachment'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicField.Attachment.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldCheckbox'}->{'002-DynamicField'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldCheckbox.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldContactWD'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldDropdown.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldDB'}->{'002-DynamicField'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldDB.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldDateTime'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldDateTime.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldDropdown'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldDropdown.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldGeneralCatalog'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldImportExport'}->{'002-DynamicField'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Znuny4OTOBODynamicFieldImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldLens'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldMasterSlave'}->{'004-MasterSlave'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldMasterSlave.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldMultiselect'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldMultiselect.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldQueue'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldReference'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldReference.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldSLA'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldScreen'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.UI.Table.js',
    'Core.Agent.Admin.Znuny4OTOBODynamicFieldScreen.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldScript'}->{'002-DynamicField'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldText.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldSet'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css',
    'Core.CodeMirrorEditor.css',
    'thirdparty/codemirror-5.65.20/lib/codemirror.css',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.css',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.css',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.css',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.SysConfig.Entity.js',
    'thirdparty/codemirror-5.65.20/lib/codemirror.js',
    'thirdparty/codemirror-5.65.20/mode/yaml/yaml.js',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchtags.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchbrackets.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closetag.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closebrackets.js',
    'thirdparty/codemirror-5.65.20/addon/search/searchcursor.js',
    'thirdparty/codemirror-5.65.20/addon/search/search.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldcode.js',
    'thirdparty/codemirror-5.65.20/addon/edit/trailingspace.js',
    'thirdparty/codemirror-5.65.20/addon/selection/selection-pointer.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.js',
    'thirdparty/codemirror-5.65.20/addon/fold/brace-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/indent-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/comment-fold.js',
    'thirdparty/codemirror-5.65.20/addon/comment/comment.js',
    'thirdparty/codemirror-5.65.20/addon/comment/continuecomment.js',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.js',
    'thirdparty/codemirror-5.65.20/addon/search/jump-to-line.js',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.js',
    'Core.UI.CodeMirrorEditor.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldText'}->{'002-DynamicField'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldText.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldTitle'}->{'002-DynamicField'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldTitle.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldType'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminDynamicFieldWebService'}->{'002-DynamicField'} =  {
  'CSS' => [
    'Core.Agent.Admin.DynamicField.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js',
    'Core.Agent.Admin.DynamicFieldWebService.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminGeneralCatalog'}->{'001-GeneralCatalog'} =  {
  'JavaScript' => [
    'ITSM.GeneralCatalog.JSColorPicker.js',
    'ITSM.GeneralCatalog.js'
  ]
};
$Self->{'Loader::Module::AdminGenericAgent'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.GenericAgent.js'
  ]
};
$Self->{'Loader::Module::AdminGenericAgentImportExport'}->{'003-ImportExportStandardObjects'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.GenericAgentImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceDebugger'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceDebugger.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceErrorHandlingDefault'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceErrorHandling.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceErrorHandlingRequestRetry'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceErrorHandling.js',
    'Core.Agent.Admin.GenericInterfaceErrorHandlingRequestRetry.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceInvokerConfigItem'}->{'007-ITSMConfigurationManagement'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceInvoker.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceInvokerDefault'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceInvoker.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceInvokerEvent'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceInvokerEvent.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceInvokerTicket'}->{'004-WebserviceTicketInvoker'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceInvoker.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceMappingSimple'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceMapping.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceMappingXSLT'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css',
    'Core.CodeMirrorEditor.css',
    'thirdparty/codemirror-5.65.20/lib/codemirror.css',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.css',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.css',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.css',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceMappingXSLT.js',
    'thirdparty/codemirror-5.65.20/lib/codemirror.js',
    'thirdparty/codemirror-5.65.20/addon/hint/xml-hint.js',
    'thirdparty/codemirror-5.65.20/mode/htmlmixed/htmlmixed.js',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.js',
    'thirdparty/codemirror-5.65.20/addon/fold/xml-fold.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchtags.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchbrackets.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closetag.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closebrackets.js',
    'thirdparty/codemirror-5.65.20/addon/search/searchcursor.js',
    'thirdparty/codemirror-5.65.20/addon/search/search.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldcode.js',
    'thirdparty/codemirror-5.65.20/addon/edit/trailingspace.js',
    'thirdparty/codemirror-5.65.20/addon/selection/selection-pointer.js',
    'thirdparty/codemirror-5.65.20/mode/javascript/javascript.js',
    'thirdparty/codemirror-5.65.20/mode/css/css.js',
    'thirdparty/codemirror-5.65.20/mode/xml/xml.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.js',
    'thirdparty/codemirror-5.65.20/addon/fold/brace-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/xml-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/indent-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/comment-fold.js',
    'thirdparty/codemirror-5.65.20/addon/comment/comment.js',
    'thirdparty/codemirror-5.65.20/addon/comment/continuecomment.js',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.js',
    'thirdparty/codemirror-5.65.20/addon/search/jump-to-line.js',
    'thirdparty/codemirror-5.65.20/addon/hint/html-hint.js',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.js',
    'Core.UI.CodeMirrorEditor.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceOperationConfigItem'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceOperation.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceOperationDefault'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceOperation.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceTransportHTTPREST'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css',
    'Core.Agent.Admin.GenericInterfaceWebserviceTicketInvoker.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceTransportHTTPRESTWebserviceTicketInvoker.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceTransportHTTPSOAP'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css',
    'Core.Agent.SortedTree.css',
    'Core.Agent.Admin.GenericInterfaceWebserviceTicketInvoker.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceTransportHTTPSOAPWebserviceTicketInvoker.js',
    'Core.Agent.SortedTree.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceWebservice'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceWebservice.js'
  ]
};
$Self->{'Loader::Module::AdminGenericInterfaceWebserviceHistory'}->{'002-GenericInterface'} =  {
  'CSS' => [
    'Core.Agent.Admin.GenericInterface.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.GenericInterfaceWebserviceHistory.js'
  ]
};
$Self->{'Loader::Module::AdminGroup'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Group.js'
  ]
};
$Self->{'Loader::Module::AdminGroupImportExport'}->{'003-ImportExportStandardObjects'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.GroupImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminITSMCIPAllocate'}->{'003-ITSMCore'} =  {
  'CSS' => [
    'ITSM.Table.css'
  ]
};
$Self->{'Loader::Module::AdminITSMChangeCIPAllocate'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Table.css'
  ]
};
$Self->{'Loader::Module::AdminITSMChangeNotification'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'Core.Agent.Admin.NotificationEvent.css'
  ],
  'JavaScript' => [
    'ITSM.Admin.ChangeManagement.ChangeNotification.js',
    'ITSM.Agent.ChangeManagement.NotificationEvent.js'
  ]
};
$Self->{'Loader::Module::AdminITSMConfigItem'}->{'002-ITSMConfigItem'} =  {
  'CSS' => [
    'Core.CodeMirrorEditor.css',
    'ITSM.Agent.Admin.ITSMConfigItem.css',
    'thirdparty/codemirror-5.65.20/lib/codemirror.css',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.css',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.css',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.css',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.css'
  ],
  'JavaScript' => [
    'thirdparty/codemirror-5.65.20/lib/codemirror.js',
    'thirdparty/codemirror-5.65.20/mode/yaml/yaml.js',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchtags.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchbrackets.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closetag.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closebrackets.js',
    'thirdparty/codemirror-5.65.20/addon/search/searchcursor.js',
    'thirdparty/codemirror-5.65.20/addon/search/search.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldcode.js',
    'thirdparty/codemirror-5.65.20/addon/edit/trailingspace.js',
    'thirdparty/codemirror-5.65.20/addon/selection/selection-pointer.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.js',
    'thirdparty/codemirror-5.65.20/addon/fold/brace-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/indent-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/comment-fold.js',
    'thirdparty/codemirror-5.65.20/addon/comment/comment.js',
    'thirdparty/codemirror-5.65.20/addon/comment/continuecomment.js',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.js',
    'thirdparty/codemirror-5.65.20/addon/search/jump-to-line.js',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.js',
    'Core.UI.CodeMirrorEditor.js',
    'ITSM.Admin.ITSMConfigItem.js'
  ]
};
$Self->{'Loader::Module::AdminImportExport'}->{'001-ImportExport'} =  {
  'CSS' => [
    'ITSM.ImportExport.css'
  ],
  'JavaScript' => [
    'ITSM.Admin.ImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminLog'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Log.js'
  ]
};
$Self->{'Loader::Module::AdminMailAccount'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.MailAccount.js'
  ]
};
$Self->{'Loader::Module::AdminNotificationEvent'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.Admin.NotificationEvent.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.NotificationEvent.js'
  ]
};
$Self->{'Loader::Module::AdminPGP'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.PGP.js'
  ]
};
$Self->{'Loader::Module::AdminPackageManager'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.PackageManager.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.PackageManager.js'
  ]
};
$Self->{'Loader::Module::AdminPerformanceLog'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.PerformanceLog.css'
  ]
};
$Self->{'Loader::Module::AdminPostMasterFilter'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.PostMasterFilter.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.PostMasterFilter.js'
  ]
};
$Self->{'Loader::Module::AdminPriority'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Priority.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminProcessManagement'}->{'002-ProcessManagement'} =  {
  'CSS' => [
    'Core.Agent.Admin.ProcessManagement.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'thirdparty/jsplumb-1.6.4/jsplumb.js',
    'thirdparty/farahey-0.5/farahey.js',
    'thirdparty/jsplumb-labelspacer/label-spacer.js',
    'Core.Agent.Admin.ProcessManagement.js',
    'Core.Agent.Admin.ProcessManagement.Canvas.js',
    'Core.UI.AllocationList.js'
  ]
};
$Self->{'Loader::Module::AdminProcessManagementActivity'}->{'002-ProcessManagement'} =  {
  'CSS' => [
    'Core.Agent.Admin.ProcessManagement.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.ProcessManagement.js',
    'Core.UI.AllocationList.js'
  ]
};
$Self->{'Loader::Module::AdminProcessManagementActivityDialog'}->{'002-ProcessManagement'} =  {
  'CSS' => [
    'Core.CodeMirrorEditor.css',
    'Core.Agent.Admin.ProcessManagement.css',
    'Core.AllocationList.css',
    'thirdparty/codemirror-5.65.20/lib/codemirror.css',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.css',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.css',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.css',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.ProcessManagement.js',
    'Core.UI.AllocationList.js',
    'thirdparty/codemirror-5.65.20/lib/codemirror.js',
    'thirdparty/codemirror-5.65.20/mode/yaml/yaml.js',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchtags.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchbrackets.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closetag.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closebrackets.js',
    'thirdparty/codemirror-5.65.20/addon/search/searchcursor.js',
    'thirdparty/codemirror-5.65.20/addon/search/search.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldcode.js',
    'thirdparty/codemirror-5.65.20/addon/edit/trailingspace.js',
    'thirdparty/codemirror-5.65.20/addon/selection/selection-pointer.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.js',
    'thirdparty/codemirror-5.65.20/addon/fold/brace-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/indent-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/comment-fold.js',
    'thirdparty/codemirror-5.65.20/addon/comment/comment.js',
    'thirdparty/codemirror-5.65.20/addon/comment/continuecomment.js',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.js',
    'thirdparty/codemirror-5.65.20/addon/search/jump-to-line.js',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.js',
    'Core.UI.CodeMirrorEditor.js'
  ]
};
$Self->{'Loader::Module::AdminProcessManagementPath'}->{'002-ProcessManagement'} =  {
  'CSS' => [
    'Core.Agent.Admin.ProcessManagement.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.ProcessManagement.js',
    'Core.UI.AllocationList.js'
  ]
};
$Self->{'Loader::Module::AdminProcessManagementTransition'}->{'002-ProcessManagement'} =  {
  'CSS' => [
    'Core.Agent.Admin.ProcessManagement.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.ProcessManagement.js'
  ]
};
$Self->{'Loader::Module::AdminProcessManagementTransitionAction'}->{'002-ProcessManagement'} =  {
  'CSS' => [
    'Core.Agent.Admin.ProcessManagement.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.ProcessManagement.js',
    'Core.Agent.Admin.ProcessManagement.TransitionActionParameters.js'
  ]
};
$Self->{'Loader::Module::AdminQueue'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Queue.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminQueueAutoResponse'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.QueueAutoResponse.js'
  ]
};
$Self->{'Loader::Module::AdminQueueImportExport'}->{'003-ImportExportStandardObjects'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.QueueImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminQueueTemplates'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.QueueTemplates.js'
  ]
};
$Self->{'Loader::Module::AdminQueueTemplatesImportExport'}->{'003-ImportExportStandardObjects'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.QueueTemplatesImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminRegistration'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.Registration.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.Registration.js'
  ]
};
$Self->{'Loader::Module::AdminResponseTemplatesStatePreselection'}->{'002-ResponseTemplatesStatePreselection'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.ResponseTemplatesStatePreselection.js'
  ]
};
$Self->{'Loader::Module::AdminRole'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Role.js'
  ]
};
$Self->{'Loader::Module::AdminRoleGroup'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.RoleGroup.js'
  ]
};
$Self->{'Loader::Module::AdminRoleGroupImportExport'}->{'003-ImportExportStandardObjects'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.RoleGroupImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminRoleImportExport'}->{'003-ImportExportStandardObjects'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.RoleImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminRoleUser'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.RoleUser.js'
  ]
};
$Self->{'Loader::Module::AdminSLA'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.SLA.js'
  ]
};
$Self->{'Loader::Module::AdminSLAImportExport'}->{'002-ServiceCatalog'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.SLAImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminSMIME'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.SMIME.js'
  ]
};
$Self->{'Loader::Module::AdminSalutation'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Salutation.js'
  ]
};
$Self->{'Loader::Module::AdminSelectBox'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.SelectBox.js'
  ]
};
$Self->{'Loader::Module::AdminService'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Service.js'
  ]
};
$Self->{'Loader::Module::AdminServiceImportExport'}->{'002-ServiceCatalog'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.ServiceImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminSession'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Session.js'
  ]
};
$Self->{'Loader::Module::AdminSignature'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Signature.js'
  ]
};
$Self->{'Loader::Module::AdminState'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.State.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminSupportDataCollector'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.SupportDataCollector.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.SupportDataCollector.js'
  ]
};
$Self->{'Loader::Module::AdminSystemAddress'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.SystemAddress.js'
  ]
};
$Self->{'Loader::Module::AdminSystemConfiguration'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.SystemConfiguration.css'
  ],
  'JavaScript' => [
    'thirdparty/clipboardjs-1.7.1/clipboard.min.js',
    'Core.SystemConfiguration.js',
    'Core.SystemConfiguration.Date.js',
    'Core.SystemConfiguration.DateTime.js',
    'Core.SystemConfiguration.VacationDays.js',
    'Core.SystemConfiguration.VacationDaysOneTime.js',
    'Core.SystemConfiguration.WorkingHours.js',
    'Core.Form.js',
    'Core.Agent.Admin.SystemConfiguration.js'
  ]
};
$Self->{'Loader::Module::AdminSystemConfigurationDeployment'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.SystemConfiguration.css'
  ],
  'JavaScript' => [
    'thirdparty/clipboardjs-1.7.1/clipboard.min.js',
    'Core.SystemConfiguration.js',
    'Core.Agent.Admin.SystemConfiguration.js'
  ]
};
$Self->{'Loader::Module::AdminSystemConfigurationDeploymentHistory'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.SystemConfiguration.css'
  ],
  'JavaScript' => [
    'thirdparty/clipboardjs-1.7.1/clipboard.min.js',
    'Core.Agent.Admin.SystemConfiguration.js',
    'Core.SystemConfiguration.js'
  ]
};
$Self->{'Loader::Module::AdminSystemConfigurationGroup'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.SystemConfiguration.css'
  ],
  'JavaScript' => [
    'thirdparty/clipboardjs-1.7.1/clipboard.min.js',
    'Core.SystemConfiguration.js',
    'Core.SystemConfiguration.Date.js',
    'Core.SystemConfiguration.DateTime.js',
    'Core.SystemConfiguration.VacationDays.js',
    'Core.SystemConfiguration.VacationDaysOneTime.js',
    'Core.SystemConfiguration.WorkingHours.js',
    'Core.Form.js',
    'Core.Agent.Admin.SystemConfiguration.js'
  ]
};
$Self->{'Loader::Module::AdminSystemConfigurationSettingHistory'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.SystemConfiguration.css'
  ],
  'JavaScript' => [
    'thirdparty/clipboardjs-1.7.1/clipboard.min.js',
    'Core.SystemConfiguration.js',
    'Core.Form.js',
    'Core.Agent.Admin.SystemConfiguration.js'
  ]
};
$Self->{'Loader::Module::AdminSystemConfigurationUser'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Admin.SystemConfiguration.css'
  ],
  'JavaScript' => [
    'thirdparty/clipboardjs-1.7.1/clipboard.min.js',
    'Core.SystemConfiguration.js',
    'Core.Form.js',
    'Core.Agent.Admin.SystemConfiguration.js',
    'Core.Agent.Admin.SystemConfigurationUser.js'
  ]
};
$Self->{'Loader::Module::AdminSystemMaintenance'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.SystemMaintenance.js'
  ]
};
$Self->{'Loader::Module::AdminTemplate'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Template.js'
  ]
};
$Self->{'Loader::Module::AdminTemplateAttachment'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.TemplateAttachment.js'
  ]
};
$Self->{'Loader::Module::AdminTemplateImportExport'}->{'003-ImportExportStandardObjects'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.TemplateImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminTicketMask'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.Admin.TicketMask.css',
    'Core.CodeMirrorEditor.css',
    'thirdparty/codemirror-5.65.20/lib/codemirror.css',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.css',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.css',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.css',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.css'
  ],
  'JavaScript' => [
    'thirdparty/codemirror-5.65.20/lib/codemirror.js',
    'thirdparty/codemirror-5.65.20/mode/yaml/yaml.js',
    'thirdparty/codemirror-5.65.20/addon/hint/show-hint.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchtags.js',
    'thirdparty/codemirror-5.65.20/addon/edit/matchbrackets.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closetag.js',
    'thirdparty/codemirror-5.65.20/addon/edit/closebrackets.js',
    'thirdparty/codemirror-5.65.20/addon/search/searchcursor.js',
    'thirdparty/codemirror-5.65.20/addon/search/search.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldcode.js',
    'thirdparty/codemirror-5.65.20/addon/edit/trailingspace.js',
    'thirdparty/codemirror-5.65.20/addon/selection/selection-pointer.js',
    'thirdparty/codemirror-5.65.20/addon/fold/foldgutter.js',
    'thirdparty/codemirror-5.65.20/addon/fold/brace-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/indent-fold.js',
    'thirdparty/codemirror-5.65.20/addon/fold/comment-fold.js',
    'thirdparty/codemirror-5.65.20/addon/comment/comment.js',
    'thirdparty/codemirror-5.65.20/addon/comment/continuecomment.js',
    'thirdparty/codemirror-5.65.20/addon/dialog/dialog.js',
    'thirdparty/codemirror-5.65.20/addon/search/jump-to-line.js',
    'thirdparty/codemirror-5.65.20/addon/display/fullscreen.js',
    'Core.UI.CodeMirrorEditor.js'
  ]
};
$Self->{'Loader::Module::AdminTranslations'}->{'002-Translations'} =  {
  'CSS' => [
    'Translations.Admin.Default.css'
  ],
  'JavaScript' => [
    'Core.Agent.Admin.Translations.js'
  ]
};
$Self->{'Loader::Module::AdminType'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.Type.js',
    'Core.Agent.Admin.SysConfig.Entity.js'
  ]
};
$Self->{'Loader::Module::AdminTypeImportExport'}->{'003-ImportExportStandardObjects'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.TypeImportExport.js'
  ]
};
$Self->{'Loader::Module::AdminUser'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.User.js'
  ]
};
$Self->{'Loader::Module::AdminUserGroup'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.UserGroup.js'
  ]
};
$Self->{'Loader::Module::AgentAppointmentAgendaOverview'}->{'002-Calendar'} =  {
  'CSS' => [
    'thirdparty/fullcalendar-3.10.2/fullcalendar.min.css',
    'Core.AppointmentCalendar.css',
    'Core.AppointmentCalendar.Agenda.css'
  ],
  'JavaScript' => [
    'thirdparty/momentjs-2.29.3/moment.min.js',
    'thirdparty/fullcalendar-3.10.2/fullcalendar.min.js',
    'Core.Agent.AppointmentCalendar.js'
  ]
};
$Self->{'Loader::Module::AgentAppointmentCalendarOverview'}->{'002-Calendar'} =  {
  'CSS' => [
    'thirdparty/fullcalendar-3.10.2/fullcalendar.min.css',
    'thirdparty/fullcalendar-scheduler-1.10.1/scheduler.min.css',
    'Core.AppointmentCalendar.css'
  ],
  'JavaScript' => [
    'thirdparty/momentjs-2.29.3/moment.min.js',
    'thirdparty/fullcalendar-3.10.2/fullcalendar.min.js',
    'thirdparty/fullcalendar-scheduler-1.10.1/scheduler.min.js',
    'Core.Agent.AppointmentCalendar.js',
    'thirdparty/clipboardjs-1.7.1/clipboard.min.js'
  ]
};
$Self->{'Loader::Module::AgentCustomerInformationCenter'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.Dashboard.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.CustomerInformationCenter.js'
  ]
};
$Self->{'Loader::Module::AgentCustomerUserAddressBook'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.CustomerUserAddressBook.css'
  ],
  'JavaScript' => [
    'Core.Agent.CustomerUserAddressBook.js'
  ]
};
$Self->{'Loader::Module::AgentCustomerUserInformationCenter'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.Dashboard.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.CustomerUserInformationCenter.js'
  ]
};
$Self->{'Loader::Module::AgentDashboard'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Dashboard.css',
    'Core.AllocationList.css',
    'thirdparty/fullcalendar-3.10.2/fullcalendar.min.css',
    'thirdparty/nvd3-1.7.1/nv.d3.css'
  ],
  'JavaScript' => [
    'thirdparty/momentjs-2.29.3/moment.min.js',
    'thirdparty/fullcalendar-3.10.2/fullcalendar.min.js',
    'thirdparty/d3-3.5.6/d3.min.js',
    'thirdparty/nvd3-1.7.1/nvd3.min.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOLineChart.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOMultiBarChart.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOStackedAreaChart.js',
    'thirdparty/canvg-1.4/rgbcolor.js',
    'thirdparty/canvg-1.4/StackBlur.js',
    'thirdparty/canvg-1.4/canvg.js',
    'thirdparty/StringView-8/stringview.js',
    'Core.UI.AdvancedChart.js',
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Dashboard.js',
    'Core.Agent.Statistics.ParamsWidget.js'
  ]
};
$Self->{'Loader::Module::AgentDynamicFieldAttachment'}->{'002-OTOBODynamicFieldAttachment'} =  {
  'JavaScript' => [
    'Core.Agent.Admin.DynamicField.js'
  ]
};
$Self->{'Loader::Module::AgentDynamicFieldDBDetailedSearch'}->{'002-DynamicField'} =  {
  'JavaScript' => [
    'Core.Agent.DynamicFieldDBDetailedSearch.js',
    'Core.Agent.DynamicFieldDBSearch.js'
  ]
};
$Self->{'Loader::Module::AgentDynamicFieldDBDetails'}->{'002-DynamicField'} =  {
  'JavaScript' => [
    'Core.Agent.DynamicFieldDBSearch.js'
  ]
};
$Self->{'Loader::Module::AgentFAQAdd'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Agent.Detail.css'
  ],
  'JavaScript' => [
    'FAQ.Agent.FAQ.js'
  ]
};
$Self->{'Loader::Module::AgentFAQCategory'}->{'002-FAQ'} =  {
  'JavaScript' => [
    'FAQ.Agent.ConfirmationDialog.js'
  ]
};
$Self->{'Loader::Module::AgentFAQEdit'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Agent.Detail.css'
  ],
  'JavaScript' => [
    'FAQ.Agent.FAQ.js'
  ]
};
$Self->{'Loader::Module::AgentFAQExplorer'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Agent.Detail.css'
  ],
  'JavaScript' => [
    'FAQ.Agent.FAQ.js'
  ]
};
$Self->{'Loader::Module::AgentFAQJournal'}->{'002-FAQ'} =  {
  'JavaScript' => [
    'FAQ.Agent.FAQ.js'
  ]
};
$Self->{'Loader::Module::AgentFAQLanguage'}->{'002-FAQ'} =  {
  'JavaScript' => [
    'FAQ.Agent.ConfirmationDialog.js'
  ]
};
$Self->{'Loader::Module::AgentFAQSearch'}->{'002-FAQ'} =  {
  'JavaScript' => [
    'FAQ.Agent.FAQ.js'
  ]
};
$Self->{'Loader::Module::AgentFAQZoom'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Agent.Detail.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'FAQ.Agent.ConfirmationDialog.js',
    'FAQ.Agent.TicketCompose.js',
    'FAQ.Agent.FAQZoom.js',
    'Core.UI.AllocationList.js',
    'Core.UI.Table.Sort.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.LinkObject.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChange'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css'
  ],
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.Overview.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeAdd'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.AddEdit.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeCondition'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.Condition.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeConditionEdit'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Table.css'
  ],
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.Condition.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeEdit'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.AddEdit.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeHistory'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.History.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeInvolvedPersons'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.InvolvedPersons.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeManager'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeMyCAB'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeMyChanges'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeMyWorkOrders'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css'
  ]
};
$Self->{'Loader::Module::AgentITSMChangePIR'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css'
  ]
};
$Self->{'Loader::Module::AgentITSMChangePSA'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeSearch'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.Overview.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeTimeSlot'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.TimeSlot.js'
  ]
};
$Self->{'Loader::Module::AgentITSMChangeZoom'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css',
    'Core.AllocationList.css',
    'ITSM.ChangeManagement.Default.css',
    'ITSM.ChangeManagement.Responsive.css',
    'ITSM.ChangeManagement.WorkorderGraph.css',
    'ITSM.ChangeManagement.RTEContent.css'
  ],
  'JavaScript' => [
    'thirdparty/jquery-tablesorter-2.0.5/jquery.tablesorter.js',
    'Core.UI.AllocationList.js',
    'Core.UI.Table.Sort.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.LinkObject.js',
    'ITSM.Agent.ConfirmDialog.js',
    'ITSM.Agent.ChangeManagement.WorkorderGraph.js',
    'ITSM.Agent.ChangeManagement.Zoom.js',
    'ITSM.Agent.ChangeManagement.ConfirmDialog.js'
  ]
};
$Self->{'Loader::Module::AgentITSMConfigItem'}->{'003-ITSMConfigItem'} =  {
  'CSS' => [
    'Core.AllocationList.css',
    'ITSM.Agent.Default.css',
    'ITSM.Agent.ConfigItem.Overview.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'ITSM.Agent.ConfigItem.Overview.js'
  ]
};
$Self->{'Loader::Module::AgentITSMConfigItemAdd'}->{'003-ITSMConfigItem'} =  {
  'JavaScript' => [
    'ITSM.Agent.ConfigItem.Add.js'
  ]
};
$Self->{'Loader::Module::AgentITSMConfigItemEdit'}->{'003-ITSMConfigItem'} =  {
  'CSS' => [
    'ITSM.Agent.ConfigItem.Edit.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldDBDetailedSearch.js',
    'Core.Agent.DynamicFieldDBSearch.js',
    'Core.UI.InputFields.js',
    'ITSM.Agent.ConfigItem.CustomerSearch.js',
    'ITSM.Agent.ConfigItem.Edit.js'
  ]
};
$Self->{'Loader::Module::AgentITSMConfigItemHistory'}->{'003-ITSMConfigItem'} =  {
  'JavaScript' => [
    'ITSM.Agent.ConfigItem.History.js'
  ]
};
$Self->{'Loader::Module::AgentITSMConfigItemSearch'}->{'003-ITSMConfigItem'} =  {
  'CSS' => [
    'Core.AllocationList.css',
    'ITSM.Agent.Default.css',
    'ITSM.Agent.ConfigItem.Overview.css',
    'ITSM.Agent.Detail.css',
    'ITSM.Table.css',
    'ITSM.Print.css'
  ],
  'JavaScript' => [
    'Core.UI.Table.Sort.js',
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'ITSM.Agent.ConfigItem.Overview.js',
    'ITSM.Agent.ConfigItem.Search.js'
  ]
};
$Self->{'Loader::Module::AgentITSMConfigItemTreeView'}->{'003-ITSMConfigItem'} =  {
  'CSS' => [
    'ITSM.Agent.ConfigItem.TreeView.css'
  ],
  'JavaScript' => [
    'Core.Agent.TreeView.js',
    'thirdparty/jsplumb-1.6.4/jsplumb.js'
  ]
};
$Self->{'Loader::Module::AgentITSMConfigItemZoom'}->{'003-DynamicFieldDatabaseExtensions'} =  {
  'CSS' => [
    'DynamicFieldDatabaseExtensions.ITSMConfigItemZoom.css'
  ]
};
$Self->{'Loader::Module::AgentITSMConfigItemZoom'}->{'003-ITSMConfigItem'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css',
    'ITSM.Agent.ConfigItem.Zoom.css',
    'ITSM.Agent.Detail.css',
    'Core.AllocationList.css',
    'ITSM.Print.css'
  ],
  'JavaScript' => [
    'thirdparty/jquery-tablesorter-2.28.14/jquery.tablesorter.js',
    'Core.UI.AllocationList.js',
    'Core.UI.InputFields.js',
    'Core.UI.Table.Sort.js',
    'Core.Agent.DynamicFieldDBDetailedSearch.js',
    'Core.Agent.DynamicFieldDBSearch.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.LinkObject.js',
    'ITSM.Agent.Zoom.js',
    'ITSM.Agent.ConfirmDialog.js',
    'ITSM.Agent.ConfigItem.Zoom.js'
  ]
};
$Self->{'Loader::Module::AgentITSMSLA'}->{'003-ITSMService'} =  {
  'JavaScript' => [
    'ITSM.Agent.SLA.js'
  ]
};
$Self->{'Loader::Module::AgentITSMSLAZoom'}->{'003-ITSMService'} =  {
  'JavaScript' => [
    'ITSM.Agent.SLAZoom.js'
  ]
};
$Self->{'Loader::Module::AgentITSMService'}->{'003-ITSMService'} =  {
  'JavaScript' => [
    'ITSM.Agent.Service.js'
  ]
};
$Self->{'Loader::Module::AgentITSMServiceZoom'}->{'002-ServiceCatalog'} =  {
  'CSS' => [],
  'JavaScript' => [
    'Core.Agent.ITSMServiceZoom.js'
  ]
};
$Self->{'Loader::Module::AgentITSMServiceZoom'}->{'003-ITSMService'} =  {
  'CSS' => [
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.UI.Table.Sort.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.LinkObject.js',
    'ITSM.Agent.ServiceZoom.js'
  ]
};
$Self->{'Loader::Module::AgentITSMTemplateEditCAB'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.CABTemplateEdit.js'
  ]
};
$Self->{'Loader::Module::AgentITSMTemplateOverview'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.ChangeManagement.Default.css'
  ],
  'JavaScript' => [
    'ITSM.Agent.ConfirmDialog.js',
    'ITSM.Agent.ChangeManagement.TemplateOverview.js'
  ]
};
$Self->{'Loader::Module::AgentITSMWorkOrderHistory'}->{'003-ITSMChangeManagement'} =  {
  'JavaScript' => [
    'ITSM.Agent.ChangeManagement.History.js'
  ]
};
$Self->{'Loader::Module::AgentITSMWorkOrderZoom'}->{'003-ITSMChangeManagement'} =  {
  'CSS' => [
    'ITSM.Agent.Default.css',
    'ITSM.ChangeManagement.Default.css',
    'ITSM.ChangeManagement.RTEContent.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.UI.Table.Sort.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.LinkObject.js',
    'ITSM.Agent.ConfirmDialog.js',
    'ITSM.Agent.ChangeManagement.Zoom.js',
    'ITSM.Agent.ChangeManagement.ConfirmDialog.js'
  ]
};
$Self->{'Loader::Module::AgentLinkObject'}->{'001-Framework'} =  {
  'JavaScript' => [
    'Core.Agent.LinkObject.SearchForm.js'
  ]
};
$Self->{'Loader::Module::AgentPreferences'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Agent.Preferences.css',
    'Core.Agent.Admin.SystemConfiguration.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Preferences.js',
    'Core.Agent.SharedSecretGenerator.js',
    'Core.SystemConfiguration.js',
    'Core.SystemConfiguration.Date.js'
  ]
};
$Self->{'Loader::Module::AgentStatistics'}->{'001-Framework'} =  {
  'CSS' => [
    'thirdparty/nvd3-1.7.1/nv.d3.css',
    'Core.Agent.Statistics.css'
  ],
  'JavaScript' => [
    'thirdparty/d3-3.5.6/d3.min.js',
    'thirdparty/nvd3-1.7.1/nvd3.min.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOLineChart.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOMultiBarChart.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOStackedAreaChart.js',
    'thirdparty/canvg-1.4/rgbcolor.js',
    'thirdparty/canvg-1.4/StackBlur.js',
    'thirdparty/canvg-1.4/canvg.js',
    'thirdparty/StringView-8/stringview.js',
    'Core.Agent.Statistics.js',
    'Core.UI.AdvancedChart.js',
    'Core.Agent.Statistics.ParamsWidget.js'
  ]
};
$Self->{'Loader::Module::AgentStatisticsReports'}->{'004'} =  {
  'CSS' => [
    'thirdparty/nvd3-1.7.1/nv.d3.css',
    'Core.Agent.StatisticsReports.css'
  ],
  'JavaScript' => [
    'thirdparty/d3-3.5.6/d3.min.js',
    'thirdparty/nvd3-1.7.1/nvd3.min.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOLineChart.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOMultiBarChart.js',
    'thirdparty/nvd3-1.7.1/models/OTOBOStackedAreaChart.js',
    'Core.UI.AdvancedChart.js',
    'Core.Agent.StatisticsReports.js'
  ]
};
$Self->{'Loader::Module::AgentSurveyAdd'}->{'002-Survey'} =  {
  'CSS' => [
    'Survey.Agent.Default.css'
  ],
  'JavaScript' => [
    'Survey.Agent.CustomerUserConditions.js'
  ]
};
$Self->{'Loader::Module::AgentSurveyEdit'}->{'002-Survey'} =  {
  'CSS' => [
    'Survey.Agent.Default.css'
  ],
  'JavaScript' => [
    'Survey.Agent.CustomerUserConditions.js'
  ]
};
$Self->{'Loader::Module::AgentSurveyEditQuestions'}->{'002-Survey'} =  {
  'CSS' => [
    'Survey.Agent.Default.css'
  ],
  'JavaScript' => [
    'Survey.Agent.SurveyEditQuestions.js'
  ]
};
$Self->{'Loader::Module::AgentSurveyOverview'}->{'002-Survey'} =  {
  'CSS' => [
    'Survey.Agent.Default.css'
  ],
  'JavaScript' => [
    'Survey.Agent.SurveyOverview.js'
  ]
};
$Self->{'Loader::Module::AgentSurveyStats'}->{'002-Survey'} =  {
  'CSS' => [
    'Survey.Agent.Default.css'
  ],
  'JavaScript' => [
    'Survey.Agent.SurveyStats.js'
  ]
};
$Self->{'Loader::Module::AgentSurveyZoom'}->{'002-Survey'} =  {
  'CSS' => [
    'Survey.Agent.Default.css'
  ],
  'JavaScript' => [
    'Survey.Agent.SurveyZoom.js'
  ]
};
$Self->{'Loader::Module::AgentTicketAccountTime'}->{'002-TimeAccounting'} =  {
  'CSS' => [
    'TimeAccounting.Defaults.css',
    'TimeAccounting.Table.css'
  ],
  'JavaScript' => [
    'TimeAccounting.Agent.TicketTimeAccount.js'
  ]
};
$Self->{'Loader::Module::AgentTicketAddtlITSMField'}->{'003-ITSMTicket'} =  {
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketArticleEdit'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketArticleVersionView'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.TicketProcess.css',
    'Core.Agent.TicketMenuModuleCluster.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'thirdparty/jquery-tablesorter-2.28.14/jquery.tablesorter.js',
    'Core.Agent.TicketSplit.js',
    'Core.Agent.TicketZoom.js',
    'Core.UI.AllocationList.js',
    'Core.UI.Table.Sort.js',
    'Core.Agent.LinkObject.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.TicketFormDraft.js'
  ]
};
$Self->{'Loader::Module::AgentTicketBounce'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketBounce.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketBulk'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketBulk.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketClose'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketClose'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketCompose'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.CustomerSearch.js',
    'Core.Agent.CustomerSearchAutoComplete.js',
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketCompose.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketCustomer'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.CustomerSearch.js',
    'Core.Agent.CustomerSearchAutoComplete.js',
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketDecision'}->{'003-ITSMTicket'} =  {
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketEmail'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.CustomerSearch.js',
    'Core.Agent.CustomerSearchAutoComplete.js',
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketEmail.js',
    'Core.Agent.TicketSplit.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketEmail'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketEmailOutbound'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.CustomerSearch.js',
    'Core.Agent.CustomerSearchAutoComplete.js',
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketEmailOutbound.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketEmailResend'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.CustomerSearch.js',
    'Core.Agent.CustomerSearchAutoComplete.js',
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketEmailResend.js'
  ]
};
$Self->{'Loader::Module::AgentTicketEscalationView'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketForward'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.CustomerSearch.js',
    'Core.Agent.CustomerSearchAutoComplete.js',
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketForward.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketFreeText'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketFreeText'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketHistory'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.TicketHistory.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketHistory.js'
  ]
};
$Self->{'Loader::Module::AgentTicketLockedView'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.AgentTicketQueue.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketMasterSlave'}->{'004-MasterSlave'} =  {
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketMasterSlave.js'
  ]
};
$Self->{'Loader::Module::AgentTicketMerge'}->{'002-Ticket'} =  {
  'JavaScript' => [
    'Core.Agent.TicketMerge.js'
  ]
};
$Self->{'Loader::Module::AgentTicketMove'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketMove.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketNote'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketNote'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketOwner'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketOwner'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketPending'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketPending'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketPhone'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.CustomerSearch.js',
    'Core.Agent.CustomerSearchAutoComplete.js',
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketPhone.js',
    'Core.Agent.TicketSplit.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketPhone'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketPhoneInbound'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketPhoneCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketPhoneOutbound'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketPhoneCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketPriority'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketPriority'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketProcess'}->{'002-ProcessManagement'} =  {
  'CSS' => [
    'Core.Agent.TicketProcess.css',
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.CustomerSearch.js',
    'Core.Agent.CustomerSearchAutoComplete.js',
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketProcess.js',
    'Core.TicketProcess.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketQueue'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.AgentTicketQueue.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketResponsible'}->{'002-Ticket'} =  {
  'CSS' => [
    'QuickDateButtons.css'
  ],
  'JavaScript' => [
    'Core.Agent.TicketAction.js',
    'Core.Agent.TicketActionCommon.js',
    'Core.Agent.TicketFormDraft.js',
    'QuickDateButtons.js'
  ]
};
$Self->{'Loader::Module::AgentTicketResponsible'}->{'002-TicketITSMTicket'} =  {
  'JavaScript' => [
    'ITSM.Agent.ITSMIncidentProblemManagement.js'
  ]
};
$Self->{'Loader::Module::AgentTicketResponsibleView'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketSearch'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketService'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.AgentTicketService.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketStatusView'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketWatchView'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.AgentTicketQueue.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js'
  ]
};
$Self->{'Loader::Module::AgentTicketZoom'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.Agent.TicketProcess.css',
    'Core.Agent.TicketMenuModuleCluster.css',
    'Core.AllocationList.css'
  ],
  'JavaScript' => [
    'thirdparty/jquery-tablesorter-2.28.14/jquery.tablesorter.js',
    'Core.Agent.TicketSplit.js',
    'Core.Agent.TicketZoom.js',
    'Core.UI.AllocationList.js',
    'Core.UI.Table.Sort.js',
    'Core.Agent.LinkObject.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.TicketFormDraft.js',
    'Core.Agent.ArticleFeatures.js'
  ]
};
$Self->{'Loader::Module::AgentTicketZoom'}->{'003-DynamicFieldDatabaseExtensions'} =  {
  'CSS' => [
    'DynamicFieldDatabaseExtensions.TicketZoom.css'
  ]
};
$Self->{'Loader::Module::AgentTicketZoom'}->{'010-ArticlePin'} =  {
  'CSS' => [
    'Core.Agent.ArticlePin.css'
  ],
  'JavaScript' => [
    'Core.Agent.ArticlePin.js',
    'thirdparty/jquery-tablesorter-2.28.14/widget-staticRow.min.js'
  ]
};
$Self->{'Loader::Module::AgentTimeAccountingEdit'}->{'002-TimeAccounting'} =  {
  'CSS' => [
    'TimeAccounting.Defaults.css',
    'TimeAccounting.Table.css'
  ],
  'JavaScript' => [
    'TimeAccounting.Agent.js',
    'TimeAccounting.Agent.ConfirmationDialog.js',
    'TimeAccounting.Agent.EditTimeRecords.js'
  ]
};
$Self->{'Loader::Module::AgentTimeAccountingOverview'}->{'002-TimeAccounting'} =  {
  'CSS' => [
    'TimeAccounting.Defaults.css',
    'TimeAccounting.Table.css'
  ]
};
$Self->{'Loader::Module::AgentTimeAccountingReporting'}->{'002-TimeAccounting'} =  {
  'CSS' => [
    'TimeAccounting.Defaults.css',
    'TimeAccounting.Table.css'
  ],
  'JavaScript' => [
    'TimeAccounting.Agent.Reporting.js'
  ]
};
$Self->{'Loader::Module::AgentTimeAccountingSetting'}->{'002-TimeAccounting'} =  {
  'CSS' => [
    'TimeAccounting.Defaults.css',
    'TimeAccounting.Table.css'
  ],
  'JavaScript' => [
    'TimeAccounting.Agent.js',
    'TimeAccounting.Agent.ConfirmationDialog.js',
    'TimeAccounting.Agent.EditTimeRecords.js'
  ]
};
$Self->{'Loader::Module::AgentTimeAccountingView'}->{'002-TimeAccounting'} =  {
  'CSS' => [
    'TimeAccounting.Defaults.css',
    'TimeAccounting.Table.css'
  ]
};
$Self->{'Loader::Module::CustomerAccept'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Accept.css',
    'Core.GenericContent.css'
  ]
};
$Self->{'Loader::Module::CustomerDashboard'}->{'002-CustomerDashboard'} =  {
  'CSS' => [
    'Core.Dashboard.Default.css',
    'Core.Dashboard.Tiles.css',
    'Core.TicketList.css'
  ],
  'JavaScript' => [
    'Core.Customer.TicketList.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::CustomerDashboard'}->{'003-CustomerDashboard'} =  {
  'CSS' => [
    'Core.Dashboard.TileServiceCatalog.css',
    'Core.Widget.css'
  ],
  'JavaScript' => [
    'Core.UI.oooWidget.js',
    'Core.Customer.TileServiceCatalog.js'
  ]
};
$Self->{'Loader::Module::CustomerDynamicFieldDBDetailedSearch'}->{'002-DynamicField'} =  {
  'CSS' => [
    'DynamicFieldDB.css',
    'Core.DynamicFieldDBDetail.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldDBDetailedSearch.js',
    'Core.Agent.DynamicFieldDBSearch.js'
  ]
};
$Self->{'Loader::Module::CustomerDynamicFieldDBDetails'}->{'002-DynamicField'} =  {
  'CSS' => [
    'DynamicFieldDB.css',
    'Core.DynamicFieldDBDetail.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldDBSearch.js'
  ]
};
$Self->{'Loader::Module::CustomerDynamicFieldDBSearch'}->{'002-DynamicField'} =  {
  'CSS' => [
    'DynamicFieldDB.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldDBSearch.js'
  ]
};
$Self->{'Loader::Module::CustomerFAQExplorer'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Customer.Detail.css',
    'FAQ.Customer.Default.css',
    'FAQ.Widget.css'
  ],
  'JavaScript' => [
    'FAQ.Customer.FAQZoom.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::CustomerFAQSearch'}->{'002-FAQ'} =  {};
$Self->{'Loader::Module::CustomerFAQZoom'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Customer.Detail.css',
    'FAQ.Customer.Default.css',
    'FAQ.FAQZoom.css'
  ],
  'JavaScript' => [
    'FAQ.Customer.FAQZoom.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::CustomerGenericContent'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.GenericContent.css'
  ]
};
$Self->{'Loader::Module::CustomerITSMConfigItem'}->{'003-ITSMConfigItem'} =  {
  'CSS' => [
    'ITSM.Customer.ConfigItemList.css',
    'ITSM.Customer.ConfigItemOverview.css',
    'ITSM.Table.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldReferenceSearch.js',
    'ITSM.Agent.ConfigItem.Search.js',
    'ITSM.Customer.ConfigItemList.js',
    'ITSM.Customer.ConfigItem.Overview.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::CustomerITSMConfigItemSearch'}->{'003-ITSMConfigItem'} =  {
  'CSS' => [
    'ITSM.Customer.ConfigItemList.css',
    'ITSM.Customer.ConfigItemOverview.css',
    'ITSM.Customer.ConfigItemSearch.css',
    'ITSM.Agent.Detail.css',
    'ITSM.Table.css',
    'ITSM.Print.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldReferenceSearch.js',
    'ITSM.Agent.ConfigItem.Search.js',
    'ITSM.Customer.ConfigItem.Overview.js',
    'ITSM.Customer.ConfigItemList.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::CustomerITSMConfigItemZoom'}->{'003-DynamicFieldDatabaseExtensions'} =  {
  'CSS' => [
    'DynamicFieldDatabaseExtensions.ITSMConfigItemZoom.css'
  ]
};
$Self->{'Loader::Module::CustomerITSMConfigItemZoom'}->{'003-ITSMConfigItem'} =  {
  'CSS' => [
    'ITSM.Customer.ConfigItem.Zoom.css'
  ],
  'JavaScript' => [
    'ITSM.Customer.ConfigItem.Zoom.js'
  ]
};
$Self->{'Loader::Module::CustomerLogin'}->{'002-CustomerLogin'} =  {
  'CSS' => [
    'Core.Login.css'
  ],
  'JavaScript' => [
    'Core.Customer.InputFields.js'
  ]
};
$Self->{'Loader::Module::CustomerPassword'}->{'002-CustomerPassword'} =  {
  'CSS' => [
    'Core.Password.css'
  ],
  'JavaScript' => [
    'Core.Customer.InputFields.js'
  ]
};
$Self->{'Loader::Module::CustomerPreferences'}->{'001-Framework'} =  {
  'CSS' => [
    'Core.Preferences.css'
  ],
  'JavaScript' => [
    'Core.Customer.Search.js',
    'Core.Customer.InputFields.js'
  ]
};
$Self->{'Loader::Module::CustomerTicketMessage'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.TicketMessage.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldReferenceSearch.js',
    'Core.Customer.TicketMessage.js'
  ]
};
$Self->{'Loader::Module::CustomerTicketMessage'}->{'003-FAQ'} =  {
  'CSS' => [
    'FAQ.RelatedArticles.css',
    'FAQ.Customer.Default.css'
  ],
  'JavaScript' => [
    'FAQ.Customer.RelatedArticles.js'
  ]
};
$Self->{'Loader::Module::CustomerTicketOverview'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.TicketList.css',
    'Core.TicketOverview.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldReferenceSearch.js',
    'Core.Customer.TicketList.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::CustomerTicketSearch'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.TicketList.css',
    'Core.TicketOverview.css',
    'Core.AllocationList.css',
    'Core.TicketSearch.css',
    'Core.Widget.css'
  ],
  'JavaScript' => [
    'Core.UI.AllocationList.js',
    'Core.Agent.TableFilters.js',
    'Core.Agent.Overview.js',
    'Core.Agent.TicketSplit.js',
    'Core.Agent.DynamicFieldReferenceSearch.js',
    'Core.Customer.TicketList.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::CustomerTicketZoom'}->{'002-Ticket'} =  {
  'CSS' => [
    'Core.TicketZoom.css',
    'Core.Process.css',
    'Core.Widget.css'
  ],
  'JavaScript' => [
    'Core.Agent.DynamicFieldReferenceSearch.js',
    'Core.Customer.TicketZoom.js',
    'Core.UI.Popup.js',
    'Core.UI.oooWidget.js'
  ]
};
$Self->{'Loader::Module::CustomerTicketZoom'}->{'003-DynamicFieldDatabaseExtensions'} =  {
  'CSS' => [
    'DynamicFieldDatabaseExtensions.TicketZoom.css'
  ]
};
$Self->{'Loader::Module::PublicFAQExplorer'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Customer.Detail.css',
    'FAQ.Customer.Default.css',
    'FAQ.Widget.css'
  ],
  'JavaScript' => [
    'FAQ.Customer.FAQZoom.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::PublicFAQRSS'}->{'002-FAQ'} =  {};
$Self->{'Loader::Module::PublicFAQSearch'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Customer.Default.css'
  ]
};
$Self->{'Loader::Module::PublicFAQZoom'}->{'002-FAQ'} =  {
  'CSS' => [
    'FAQ.Customer.Default.css',
    'FAQ.Customer.Detail.css',
    'FAQ.FAQZoom.css'
  ],
  'JavaScript' => [
    'FAQ.Customer.FAQZoom.js',
    'Core.Customer.Search.js'
  ]
};
$Self->{'Loader::Module::PublicSurvey'}->{'002-Survey'} =  {
  'CSS' => [
    'Survey.Customer.Default.css'
  ]
};
$Self->{'LogModule'} =  'Kernel::System::Log::SysLog';
$Self->{'LogModule::LogFile'} =  '/tmp/otobo.log';
$Self->{'LogModule::LogFile::Date'} =  '0';
$Self->{'LogModule::LogFile::MaxKeepRotated'} =  '3';
$Self->{'LogModule::LogFile::MaxSize'} =  '524288000';
$Self->{'LogModule::SysLog::Charset'} =  'utf-8';
$Self->{'LogModule::SysLog::Facility'} =  'user';
$Self->{'LoopProtectionLog'} =  '<OTOBO_CONFIG_Home>/var/log/LoopProtection';
$Self->{'LoopProtectionModule'} =  'Kernel::System::PostMaster::LoopProtection::DB';
$Self->{'LostPassword'} =  '1';
$Self->{'MailQueue'} =  {
  'IncrementAttemptDelayInMinutes' => '2',
  'ItemMaxAttempts' => '3'
};
$Self->{'MarkTicketSeenRedirectDefaultURL'} =  'Action=AgentDashboard';
$Self->{'MarkTicketUnseenRedirectDefaultURL'} =  'Action=AgentDashboard';
$Self->{'MasterSlave::AdvancedEnabled'} =  '0';
$Self->{'MasterSlave::DynamicField'} =  'MasterSlave';
$Self->{'MasterSlave::FollowUpdatedMaster'} =  '0';
$Self->{'MasterSlave::ForwardSlaves'} =  '0';
$Self->{'MasterSlave::KeepParentChildAfterUnset'} =  '0';
$Self->{'MasterSlave::KeepParentChildAfterUpdate'} =  '0';
$Self->{'MasterSlave::UnsetMasterSlave'} =  '0';
$Self->{'MasterSlave::UpdateMasterSlave'} =  '0';
$Self->{'MinimumLogLevel'} =  'error';
$Self->{'ModernizeFormFields'} =  '1';
$Self->{'Multitenancy'} =  '1';
$Self->{'Multitenancy::PermissionGroup'} =  'admin';
$Self->{'Nagios::Acknowledge::FreeField::Host'} =  'DynamicField_TicketFreeText1';
$Self->{'Nagios::Acknowledge::FreeField::Service'} =  'DynamicField_TicketFreeText2';
$Self->{'Nagios::Acknowledge::HTTP::Password'} =  'some_pass';
$Self->{'Nagios::Acknowledge::HTTP::URL'} =  'http://nagios.example.com/nagios/cgi-bin/cmd.cgi?cmd_typ=<CMD_TYP>&cmd_mod=2&host=<HOST_NAME>&service=<SERVICE_NAME>&sticky_ack=on&send_notification=on&persistent=on&com_data=<TicketNumber>&btnSubmit=Commit';
$Self->{'Nagios::Acknowledge::HTTP::User'} =  'John';
$Self->{'Nagios::Acknowledge::NamedPipe::CMD'} =  'echo \'<OUTPUTSTRING>\' > /usr/local/nagios/var/rw/nagios.cmd';
$Self->{'Nagios::Acknowledge::NamedPipe::Host'} =  '[<UNIXTIME>] ACKNOWLEDGE_HOST_PROBLEM;<HOST_NAME>;1;1;1;<LOGIN>;<a href="<CONFIG_HttpType>://<CONFIG_FQDN>/<CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom&TicketID=<TicketID>"><CONFIG_Ticket::Hook><TicketNumber></a>';
$Self->{'Nagios::Acknowledge::NamedPipe::Service'} =  '[<UNIXTIME>] ACKNOWLEDGE_SVC_PROBLEM;<HOST_NAME>;<SERVICE_NAME>;1;1;1;<LOGIN>;<a href="<CONFIG_HttpType>://<CONFIG_FQDN>/<CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom&TicketID=<TicketID>"><CONFIG_Ticket::Hook><TicketNumber></a>';
$Self->{'Nagios::Acknowledge::Type'} =  '';
$Self->{'NewTicketInNewWindow::Enabled'} =  '0';
$Self->{'Notification::CharactersPerLine'} =  '80';
$Self->{'Notification::Transport'}->{'Email'} =  {
  'AgentEnabledByDefault' => '1',
  'Icon' => 'fa fa-envelope',
  'Module' => 'Kernel::System::Ticket::Event::NotificationEvent::Transport::Email',
  'Name' => 'Email',
  'Prio' => '100'
};
$Self->{'NotificationBodyLostPassword'} =  'Hi <OTOBO_USERFIRSTNAME>,


Here\'s your new OTOBO password.

New password: <OTOBO_NEWPW>

You can log in via the following URL:

<OTOBO_CONFIG_HttpType>://<OTOBO_CONFIG_FQDN>/<OTOBO_CONFIG_ScriptAlias>index.pl
            ';
$Self->{'NotificationBodyLostPasswordToken'} =  'Hi <OTOBO_USERFIRSTNAME>,

You or someone impersonating you has requested to change your OTOBO
password.

If you want to do this, click on the link below. You will receive another email containing the password.

<OTOBO_CONFIG_HttpType>://<OTOBO_CONFIG_FQDN>/<OTOBO_CONFIG_ScriptAlias>index.pl?Action=LostPassword;Token=<OTOBO_TOKEN>

If you did not request a new password, please ignore this email.
            ';
$Self->{'NotificationSenderEmail'} =  'otobo@<OTOBO_CONFIG_FQDN>';
$Self->{'NotificationSenderName'} =  'OTOBO Notifications';
$Self->{'NotificationSubjectLostPassword'} =  'New OTOBO password';
$Self->{'NotificationSubjectLostPasswordToken'} =  'New OTOBO password request';
$Self->{'OTOBOEscalationEvents::DecayTime'} =  '1440';
$Self->{'OTOBOTimeZone'} =  'UTC';
$Self->{'OnlyValuesOnTicket'} =  '1';
$Self->{'OpenMainMenuOnHover'} =  '0';
$Self->{'Organization'} =  'NCS Pte Ltd';
$Self->{'OutOfOfficeMessageTemplate'} =  '*** out of office until %s (%s d left) ***';
$Self->{'PDF::LogoFile'} =  '<OTOBO_CONFIG_Home>/var/logo-otobo.png';
$Self->{'PDF::MaxPages'} =  '100';
$Self->{'PDF::PageSize'} =  'a4';
$Self->{'PDF::TTFontFile'}->{'Monospaced'} =  'DejaVuSansMono.ttf';
$Self->{'PDF::TTFontFile'}->{'MonospacedBold'} =  'DejaVuSansMono-Bold.ttf';
$Self->{'PDF::TTFontFile'}->{'MonospacedBoldItalic'} =  'DejaVuSansMono-BoldOblique.ttf';
$Self->{'PDF::TTFontFile'}->{'MonospacedItalic'} =  'DejaVuSansMono-Oblique.ttf';
$Self->{'PDF::TTFontFile'}->{'Proportional'} =  'DejaVuSans.ttf';
$Self->{'PDF::TTFontFile'}->{'ProportionalBold'} =  'DejaVuSans-Bold.ttf';
$Self->{'PDF::TTFontFile'}->{'ProportionalBoldItalic'} =  'DejaVuSans-BoldOblique.ttf';
$Self->{'PDF::TTFontFile'}->{'ProportionalItalic'} =  'DejaVuSans-Oblique.ttf';
$Self->{'PGP'} =  '0';
delete $Self->{'PGP::Bin'};
$Self->{'PGP::Key::Password'} =  {
  '488A0B8F' => 'SomePassword',
  'D2DF79FA' => 'SomePassword'
};
$Self->{'PGP::Log'} =  {
  'BADSIG' => 'The PGP signature with the keyid has not been verified successfully.',
  'ERRSIG' => 'It was not possible to check the PGP signature, this may be caused by a missing public key or an unsupported algorithm.',
  'EXPKEYSIG' => 'The PGP signature was made by an expired key.',
  'GOODSIG' => 'Good PGP signature.',
  'KEYREVOKED' => 'The PGP signature was made by a revoked key, this could mean that the signature is forged.',
  'NODATA' => 'No valid OpenPGP data found.',
  'NO_PUBKEY' => 'No public key found.',
  'REVKEYSIG' => 'The PGP signature was made by a revoked key, this could mean that the signature is forged.',
  'SIGEXPIRED' => 'The PGP signature is expired.',
  'SIG_ID' => 'Signature data.',
  'TRUST_UNDEFINED' => 'This key is not certified with a trusted signature!',
  'VALIDSIG' => 'The PGP signature with the keyid is good.'
};
$Self->{'PGP::Method'} =  'Detached';
$Self->{'PGP::Options'} =  '--homedir /opt/otobo/.gnupg/ --batch --no-tty --yes';
$Self->{'PGP::Options::DigestPreference'} =  'sha256';
$Self->{'PGP::TrustedNetwork'} =  '0';
$Self->{'Package::AllowNotVerifiedPackages'} =  '1';
$Self->{'Package::EventModulePost'}->{'2400-RebuildACLPreselectionCache'} =  {
  'Event' => 'PackageInstall|PackageReinstall|PackageUpgrade|PackageUninstall',
  'Module' => 'Kernel::System::Ticket::Event::RebuildACLPreselectionCache'
};
$Self->{'Package::EventModulePost'}->{'8000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'Package::EventModulePost'}->{'9000-SupportDataSend'} =  {
  'Event' => 'Package(?:Install|Reinstall|Upgrade|Uninstall)',
  'Module' => 'Kernel::System::Package::Event::SupportDataSend',
  'Transaction' => '1'
};
$Self->{'Package::FileUpload'} =  '1';
$Self->{'Package::RepositoryList'} =  {
  'https://ncs.com.sg' => 'OTOBO::ITSM Addons'
};
$Self->{'Package::RepositoryRoot'} =  [
  'https://ncs.com.sg'
];
$Self->{'Package::ShowFeatureAddons'} =  '1';
$Self->{'Package::Timeout'} =  '120';
$Self->{'PerformanceLog'} =  '0';
$Self->{'PerformanceLog::File'} =  '<OTOBO_CONFIG_Home>/var/log/Performance.log';
$Self->{'PerformanceLog::FileMax'} =  '25';
$Self->{'PossibleNextActions'} =  {
  '[% Env(\'CGIHandle\') %]?Action=AgentDashboard' => 'Go to dashboard!'
};
$Self->{'PostMaster::CheckFollowUpModule'}->{'0000-BounceEmail'} =  {
  'Module' => 'Kernel::System::PostMaster::FollowUpCheck::BounceEmail'
};
$Self->{'PostMaster::CheckFollowUpModule'}->{'0100-Subject'} =  {
  'Module' => 'Kernel::System::PostMaster::FollowUpCheck::Subject'
};
$Self->{'PostMaster::CheckFollowUpModule'}->{'0200-References'} =  {
  'Module' => 'Kernel::System::PostMaster::FollowUpCheck::References'
};
$Self->{'PostMaster::NewTicket::AutoAssignCustomerIDForUnknownCustomers'} =  '1';
$Self->{'PostMaster::PreCreateFilterModule'}->{'000-FollowUpArticleVisibilityCheck'} =  {
  'IsVisibleForCustomer' => '0',
  'Module' => 'Kernel::System::PostMaster::Filter::FollowUpArticleVisibilityCheck',
  'SenderType' => 'customer'
};
$Self->{'PostMaster::PreFilterModule'}->{'000-DetectBounceEmail'} =  {
  'Module' => 'Kernel::System::PostMaster::Filter::DetectBounceEmail'
};
$Self->{'PostMaster::PreFilterModule'}->{'000-MatchDBSource'} =  {
  'Module' => 'Kernel::System::PostMaster::Filter::MatchDBSource'
};
$Self->{'PostMaster::PreFilterModule'}->{'000-SMIMEFetchFromCustomer'} =  {
  'Module' => 'Kernel::System::PostMaster::Filter::SMIMEFetchFromCustomer'
};
$Self->{'PostMaster::PreFilterModule'}->{'1-SystemMonitoring'} =  {
  'ArticleType' => 'note-report',
  'CloseActionState' => 'closed successful',
  'ClosePendingTime' => '172800',
  'CloseTicketRegExp' => 'OK|UP',
  'DefaultService' => 'Host',
  'FreeTextHost' => '1',
  'FreeTextService' => '2',
  'FreeTextState' => '1',
  'FromAddressRegExp' => 'nagios@example.com',
  'HostRegExp' => '\\s*Host:\\s+(.*)\\s*',
  'KeepOpenIfLocked' => '0',
  'Module' => 'Kernel::System::PostMaster::Filter::SystemMonitoring',
  'NewTicketRegExp' => 'CRITICAL|DOWN',
  'SenderType' => 'system',
  'ServiceRegExp' => '\\s*Service:\\s+(.*)\\s*',
  'StateRegExp' => '\\s*State:\\s+(\\S+)'
};
$Self->{'PostMaster::PreFilterModule::NewTicketReject::Body'} =  '
Dear Customer,

Unfortunately we could not detect a valid ticket number
in your subject, so this email can\'t be processed.

Please create a new ticket via the customer panel.

Thanks for your help!

 Your Helpdesk Team
';
$Self->{'PostMaster::PreFilterModule::NewTicketReject::Subject'} =  'Email Rejected';
$Self->{'PostMasterMaxEmailSize'} =  '32768';
$Self->{'PostMasterReconnectMessage'} =  '20';
$Self->{'PostMasterSSLVerifyMode'} =  '0';
$Self->{'PostmasterAutoHTML2Text'} =  '1';
$Self->{'PostmasterBounceEmailAsFollowUp'} =  '1';
$Self->{'PostmasterDefaultPriority'} =  '3 normal';
$Self->{'PostmasterDefaultQueue'} =  'IPC';
$Self->{'PostmasterDefaultState'} =  'new';
$Self->{'PostmasterFollowUpOnUnlockAgentNotifyOnlyToOwner'} =  '0';
$Self->{'PostmasterFollowUpState'} =  'open';
$Self->{'PostmasterHeaderFieldCount'} =  '12';
$Self->{'PostmasterMaxEmails'} =  '40';
$Self->{'PostmasterMaxEmailsPerAddress'} =  {};
$Self->{'PostmasterUserID'} =  '1';
$Self->{'PostmasterX-Header'} =  [
  'From',
  'To',
  'Cc',
  'Reply-To',
  'ReplyTo',
  'Subject',
  'Message-ID',
  'Message-Id',
  'Resent-To',
  'Resent-From',
  'Precedence',
  'Mailing-List',
  'List-Id',
  'List-Archive',
  'Errors-To',
  'References',
  'In-Reply-To',
  'Auto-Submitted',
  'X-Loop',
  'X-Spam',
  'X-Spam-Flag',
  'X-Spam-Level',
  'X-Spam-Score',
  'X-Spam-Status',
  'X-No-Loop',
  'X-Priority',
  'Importance',
  'X-Mailer',
  'User-Agent',
  'Organization',
  'X-Original-To',
  'Delivered-To',
  'Envelope-To',
  'X-Envelope-To',
  'Return-Path',
  'X-OTOBO-AttachmentExists',
  'X-OTOBO-AttachmentCount',
  'X-OTOBO-Owner',
  'X-OTOBO-OwnerID',
  'X-OTOBO-Responsible',
  'X-OTOBO-ResponsibleID',
  'X-OTOBO-Loop',
  'X-OTOBO-Priority',
  'X-OTOBO-Queue',
  'X-OTOBO-Lock',
  'X-OTOBO-Ignore',
  'X-OTOBO-State',
  'X-OTOBO-State-PendingTime',
  'X-OTOBO-Type',
  'X-OTOBO-Service',
  'X-OTOBO-SLA',
  'X-OTOBO-Title',
  'X-OTOBO-CustomerNo',
  'X-OTOBO-CustomerUser',
  'X-OTOBO-SenderType',
  'X-OTOBO-IsVisibleForCustomer',
  'X-OTOBO-FollowUp-Owner',
  'X-OTOBO-FollowUp-OwnerID',
  'X-OTOBO-FollowUp-Responsible',
  'X-OTOBO-FollowUp-ResponsibleID',
  'X-OTOBO-FollowUp-Priority',
  'X-OTOBO-FollowUp-Queue',
  'X-OTOBO-FollowUp-Lock',
  'X-OTOBO-FollowUp-State',
  'X-OTOBO-FollowUp-State-PendingTime',
  'X-OTOBO-FollowUp-Type',
  'X-OTOBO-FollowUp-Service',
  'X-OTOBO-FollowUp-SLA',
  'X-OTOBO-FollowUp-SenderType',
  'X-OTOBO-FollowUp-IsVisibleForCustomer',
  'X-OTOBO-FollowUp-Title',
  'X-OTOBO-FollowUp-State-Keep',
  'X-OTOBO-BodyDecrypted'
];
$Self->{'PreApplicationModule'}->{'AgentPassword'} =  'Kernel::Modules::AgentPassword';
$Self->{'PreApplicationModule'}->{'AgentPreMasterSlave'} =  'Kernel::Modules::AgentPreMasterSlave';
$Self->{'PreApplicationModule'}->{'AgentTimeAccounting'} =  'Kernel::Modules::AgentTimeAccountingEdit';
$Self->{'Preferences::UpdateAJAX::Allowed'}->{'001-Framework'} =  {
  'AdminNavigationBarFavourites' => '1',
  'UserAgentDoNotShowBrowserLinkMessage' => '1',
  'UserNavBarItemsOrder' => '1',
  'UserSystemConfigurationCategory' => '1',
  'UserSystemConfigurationFavourites' => '1',
  'UserTicketZoomArticleTableHeight' => '1',
  'UserWidgetState_SystemConfiguration_Actions' => '1',
  'UserWidgetState_SystemConfiguration_Help' => '1',
  'UserWidgetState_SystemConfiguration_Navigation' => '1',
  'UserWidgetState_SystemConfiguration_Sticky' => '1'
};
$Self->{'Preferences::UpdateAJAX::Allowed'}->{'002-ITSMConfigurationManagement'} =  {
  'UserConfigItemZoomTableHeight' => '1'
};
$Self->{'PreferencesGroups'}->{'AppointmentNotificationEvent'} =  {
  'Active' => '1',
  'Desc' => 'Choose for which kind of appointment changes you want to receive notifications.',
  'Label' => 'Appointment notifications',
  'Module' => 'Kernel::Output::HTML::Preferences::AppointmentNotificationEvent',
  'PrefKey' => 'AdminAppointmentNotifcationEventTransport',
  'PreferenceGroup' => 'NotificationSettings',
  'Prio' => '8001'
};
$Self->{'PreferencesGroups'}->{'Avatar'} =  {
  'Active' => '1',
  'Block' => 'Avatar',
  'Desc' => 'Change your avatar image.',
  'Key' => 'Avatar',
  'Label' => 'Avatar',
  'Module' => 'Kernel::Output::HTML::Preferences::Avatar',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '1000'
};
$Self->{'PreferencesGroups'}->{'ChangeOverviewSmallPageShown'} =  {
  'Active' => '0',
  'Column' => 'Other Settings',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35'
  },
  'DataSelected' => '25',
  'Desc' => 'Change limit per page for Change Overview "Small".',
  'Key' => '',
  'Label' => 'Change Overview "Small" Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserChangeOverviewSmallPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8000'
};
$Self->{'PreferencesGroups'}->{'Comment'} =  {
  'Active' => '0',
  'Block' => 'Input',
  'Data' => '[% Env("UserComment") %]',
  'Desc' => 'This is a Description for Comment on Framework.',
  'Key' => 'Comment',
  'Label' => 'Comment',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserComment',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '6000'
};
$Self->{'PreferencesGroups'}->{'CommunicationLogPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35',
    '50' => '50'
  },
  'DataSelected' => '25',
  'Desc' => 'Communication log limit per page for Communication Log Overview.',
  'Key' => '',
  'Label' => 'CommunicationLog Overview Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'AdminCommunicationLogPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8100'
};
$Self->{'PreferencesGroups'}->{'ConfigItemOverviewFilterSettings'} =  {
  'Active' => '0',
  'Desc' => 'Column config item filters for ConfigItem Overview.',
  'Key' => '',
  'Label' => 'Enabled filters.',
  'Module' => 'Kernel::Output::HTML::Preferences::ColumnFilters',
  'PrefKey' => 'UserFilterColumnsEnabled',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8100'
};
$Self->{'PreferencesGroups'}->{'ConfigItemOverviewSmallPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35'
  },
  'DataSelected' => '25',
  'Desc' => 'Configuration Item limit per page.',
  'Key' => '',
  'Label' => 'Configuration Item Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserConfigItemOverviewSmallPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8000'
};
$Self->{'PreferencesGroups'}->{'CreateNextMask'} =  {
  'Active' => '1',
  'Data' => {
    '0' => 'Create Ticket',
    'AgentTicketZoom' => 'Ticket Zoom'
  },
  'DataSelected' => '',
  'Desc' => 'Configure which screen should be shown after a new ticket has been created.',
  'Key' => '',
  'Label' => 'Screen after new ticket',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserCreateNextMask',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '3000'
};
$Self->{'PreferencesGroups'}->{'CustomQueue'} =  {
  'Active' => '1',
  'Desc' => 'Your queue selection of your preferred queues. You also get notified about those queues via email if enabled.',
  'Key' => '',
  'Label' => 'My Queues',
  'Module' => 'Kernel::Output::HTML::Preferences::CustomQueue',
  'Permission' => 'ro',
  'PreferenceGroup' => 'NotificationSettings',
  'Prio' => '1000'
};
$Self->{'PreferencesGroups'}->{'CustomService'} =  {
  'Active' => '1',
  'Desc' => 'Your service selection of your preferred services. You also get notified about those services via email if enabled.',
  'Key' => '',
  'Label' => 'My Services',
  'Module' => 'Kernel::Output::HTML::Preferences::CustomService',
  'PreferenceGroup' => 'NotificationSettings',
  'Prio' => '1000'
};
$Self->{'PreferencesGroups'}->{'DynamicFieldsOverviewPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '100' => '100',
    '250' => '250',
    '500' => '500'
  },
  'DataSelected' => '250',
  'Desc' => 'Dynamic fields limit per page for Dynamic Fields Overview.',
  'Key' => '',
  'Label' => 'Dynamic Fields Overview Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'AdminDynamicFieldsOverviewPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8000'
};
$Self->{'PreferencesGroups'}->{'FAQJournalOverviewSmallPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35'
  },
  'DataSelected' => '25',
  'Desc' => 'Select how many items should be shown in Journal Overview "Small" by default.',
  'Label' => 'FAQ Journal Overview "Small" Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserFAQJournalOverviewSmallPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8000'
};
$Self->{'PreferencesGroups'}->{'FAQOverviewSmallPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35'
  },
  'DataSelected' => '25',
  'Desc' => 'Select how many items should be shown in Overview "Small" by default.',
  'Label' => 'FAQ Overview "Small" Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserFAQOverviewSmallPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8000'
};
$Self->{'PreferencesGroups'}->{'GoogleAuthenticatorSecretKey'} =  {
  'Active' => '0',
  'Block' => 'Input',
  'Desc' => 'Enter your shared secret to enable two factor authentication. WARNING: Make sure that you add the shared secret to your generator application and the application works well. Otherwise you will be not able to login anymore without the two factor token.',
  'Key' => 'Shared Secret',
  'Label' => 'Google Authenticator',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserGoogleAuthenticatorSecretKey',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '0600',
  'ValidateRegex' => '^([A-Z2-7]{16}|)$',
  'ValidateRegexMessage' => 'The secret you supplied is invalid. The secret must only contain letters (A-Z, uppercase) and numbers (2-7) and must consist of 16 characters.'
};
$Self->{'PreferencesGroups'}->{'Language'} =  {
  'Active' => '1',
  'Desc' => 'Select the main interface language.',
  'Key' => '',
  'Label' => 'Language',
  'Module' => 'Kernel::Output::HTML::Preferences::Language',
  'NeedsReload' => '1',
  'PrefKey' => 'UserLanguage',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '1000'
};
$Self->{'PreferencesGroups'}->{'MarkTicketSeenRedirectURL'} =  {
  'Active' => '1',
  'Data' => {
    '' => '-',
    'Action=AgentDashboard' => 'Dashboard',
    'Action=AgentTicketEmail' => 'New email ticket',
    'Action=AgentTicketEscalationView' => 'Escalation view',
    'Action=AgentTicketPhone' => 'New phone ticket',
    'Action=AgentTicketQueue' => 'Queue view',
    'Action=AgentTicketStatusView' => 'Status view',
    'Action=AgentTicketZoom;TicketID=###TicketID####1' => 'Ticket Zoom'
  },
  'DataSelected' => '',
  'Desc' => 'Configure which screen should be shown after a ticket has been marked as seen.',
  'Key' => '',
  'Label' => 'Dialog to show after marking a ticket as seen',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserMarkTicketSeenRedirectURL',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '4000'
};
$Self->{'PreferencesGroups'}->{'MarkTicketUnseenRedirectURL'} =  {
  'Active' => '1',
  'Data' => {
    '' => '-',
    'Action=AgentDashboard' => 'Dashboard',
    'Action=AgentTicketEmail' => 'New email ticket',
    'Action=AgentTicketEscalationView' => 'Escalation view',
    'Action=AgentTicketPhone' => 'New phone ticket',
    'Action=AgentTicketQueue' => 'Queue view',
    'Action=AgentTicketStatusView' => 'Status view',
    'Action=AgentTicketZoom;TicketID=###TicketID####1' => 'Ticket Zoom'
  },
  'DataSelected' => '',
  'Desc' => 'Configure which screen should be shown after a ticket has been marked as unseen.',
  'Key' => '',
  'Label' => 'Dialog to show after marking a ticket as unseen',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserMarkTicketUnseenRedirectURL',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '4000'
};
$Self->{'PreferencesGroups'}->{'NotificationEvent'} =  {
  'Active' => '1',
  'Desc' => 'Choose for which kind of ticket changes you want to receive notifications. Please note that you can\'t completely disable notifications marked as mandatory.',
  'Label' => 'Ticket notifications',
  'Module' => 'Kernel::Output::HTML::Preferences::NotificationEvent',
  'PrefKey' => 'AdminNotifcationEventTransport',
  'PreferenceGroup' => 'NotificationSettings',
  'Prio' => '8000'
};
$Self->{'PreferencesGroups'}->{'OutOfOffice'} =  {
  'Active' => '1',
  'Block' => 'OutOfOffice',
  'Desc' => 'If you\'re going to be out of office, you may wish to let other users know by setting the exact dates of your absence.',
  'Key' => '',
  'Label' => 'Out Of Office Time',
  'Module' => 'Kernel::Output::HTML::Preferences::OutOfOffice',
  'PrefKey' => 'UserOutOfOffice',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '4000'
};
$Self->{'PreferencesGroups'}->{'Password'} =  {
  'Active' => '1',
  'Area' => 'Agent',
  'Desc' => 'Set a new password by filling in your current password and a new one.',
  'Label' => 'Change password',
  'Module' => 'Kernel::Output::HTML::Preferences::Password',
  'PasswordHistory' => '3',
  'PasswordMaxLoginFailed' => '0',
  'PasswordMaxValidTimeInDays' => '',
  'PasswordMin2Characters' => '0',
  'PasswordMin2Lower2UpperCharacters' => '0',
  'PasswordMinSize' => '8',
  'PasswordNeedDigit' => '1',
  'PasswordRegExp' => '',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '0500'
};
$Self->{'PreferencesGroups'}->{'RefreshTime'} =  {
  'Active' => '1',
  'Data' => {
    '0' => 'off',
    '10' => '10 minutes',
    '15' => '15 minutes',
    '2' => ' 2 minutes',
    '5' => ' 5 minutes',
    '7' => ' 7 minutes'
  },
  'DataSelected' => '0',
  'Desc' => 'If enabled, the different overviews (Dashboard, LockedView, QueueView) will automatically refresh after the specified time.',
  'Key' => '',
  'Label' => 'Overview Refresh Time',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserRefreshTime',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '2000'
};
$Self->{'PreferencesGroups'}->{'Skin'} =  {
  'Active' => '1',
  'Desc' => 'Select your preferred layout for the software.',
  'Key' => '',
  'Label' => 'Skin',
  'Module' => 'Kernel::Output::HTML::Preferences::Skin',
  'NeedsReload' => '1',
  'PrefKey' => 'UserSkin',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '100'
};
$Self->{'PreferencesGroups'}->{'SurveyOverviewSmallPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35'
  },
  'DataSelected' => '25',
  'Desc' => 'Survey limit per page for Survey Overview "Small".',
  'Key' => 'Limit.',
  'Label' => 'Survey Overview "Small" Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserSurveyOverviewSmallPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8000'
};
$Self->{'PreferencesGroups'}->{'Theme'} =  {
  'Active' => '1',
  'Desc' => 'Select your preferred theme for OTOBO.',
  'Key' => '',
  'Label' => 'Theme',
  'Module' => 'Kernel::Output::HTML::Preferences::Theme',
  'NeedsReload' => '1',
  'PrefKey' => 'UserTheme',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '3000'
};
$Self->{'PreferencesGroups'}->{'TicketOverviewFilterSettings'} =  {
  'Active' => '0',
  'Desc' => 'Column ticket filters for Ticket Overviews type "Small".',
  'Key' => '',
  'Label' => 'Enabled filters.',
  'Module' => 'Kernel::Output::HTML::Preferences::ColumnFilters',
  'PrefKey' => 'UserFilterColumnsEnabled',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8100'
};
$Self->{'PreferencesGroups'}->{'TicketOverviewMediumPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35'
  },
  'DataSelected' => '20',
  'Desc' => 'Ticket limit per page for Ticket Overview "Medium".',
  'Key' => '',
  'Label' => 'Ticket Overview "Medium" Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserTicketOverviewMediumPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8100'
};
$Self->{'PreferencesGroups'}->{'TicketOverviewPreviewPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35'
  },
  'DataSelected' => '15',
  'Desc' => 'Ticket limit per page for Ticket Overview "Preview".',
  'Key' => '',
  'Label' => 'Ticket Overview "Preview" Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserTicketOverviewPreviewPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8200'
};
$Self->{'PreferencesGroups'}->{'TicketOverviewSmallPageShown'} =  {
  'Active' => '0',
  'Data' => {
    '10' => '10',
    '15' => '15',
    '20' => '20',
    '25' => '25',
    '30' => '30',
    '35' => '35'
  },
  'DataSelected' => '25',
  'Desc' => 'Ticket limit per page for Ticket Overview "Small".',
  'Key' => '',
  'Label' => 'Ticket Overview "Small" Limit',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserTicketOverviewSmallPageShown',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '8000'
};
$Self->{'PreferencesGroups'}->{'TimeZone'} =  {
  'Active' => '1',
  'Desc' => 'Select your personal time zone. All times will be displayed relative to this time zone.',
  'Key' => '',
  'Label' => 'Time Zone',
  'Module' => 'Kernel::Output::HTML::Preferences::TimeZone',
  'PrefKey' => 'UserTimeZone',
  'PreferenceGroup' => 'UserProfile',
  'Prio' => '3500'
};
$Self->{'PreferencesGroups'}->{'UserCreateWorkOrderNextMask'} =  {
  'Active' => '1',
  'Column' => 'Other Settings',
  'Data' => {
    'AgentITSMChangeZoom' => 'Change Zoom',
    'AgentITSMWorkOrderZoom' => 'Workorder Zoom'
  },
  'DataSelected' => 'AgentITSMWorkOrderZoom',
  'Desc' => 'Configure which screen should be shown after a new workorder has been created.',
  'Key' => '',
  'Label' => 'Screen after creating a workorder',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserCreateWorkOrderNextMask',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '4000'
};
$Self->{'PreferencesGroups'}->{'UserITSMChangeManagementTemplateEdit'} =  {
  'Active' => '0',
  'Block' => 'Input',
  'Column' => 'Other Settings',
  'Data' => '',
  'Desc' => 'Change and workorder templates edited by this user.',
  'Key' => 'Template',
  'Label' => 'Change and Workorder Templates',
  'Module' => 'Kernel::Output::HTML::Preferences::Generic',
  'PrefKey' => 'UserITSMChangeManagementTemplateEdit',
  'PreferenceGroup' => 'Miscellaneous',
  'Prio' => '9000'
};
$Self->{'PreferencesTable'} =  'user_preferences';
$Self->{'PreferencesTableKey'} =  'preferences_key';
$Self->{'PreferencesTableUserID'} =  'user_id';
$Self->{'PreferencesTableValue'} =  'preferences_value';
$Self->{'Process::CacheTTL'} =  '3600';
$Self->{'Process::DefaultLock'} =  'unlock';
$Self->{'Process::DefaultPriority'} =  '3 normal';
$Self->{'Process::DefaultQueue'} =  'IPC';
$Self->{'Process::DefaultState'} =  'new';
$Self->{'Process::DynamicFieldProcessManagementActivityID'} =  'ProcessManagementActivityID';
$Self->{'Process::DynamicFieldProcessManagementProcessID'} =  'ProcessManagementProcessID';
$Self->{'Process::Entity::Prefix'} =  {
  'Activity' => 'A',
  'ActivityDialog' => 'AD',
  'Process' => 'P',
  'Transition' => 'T',
  'TransitionAction' => 'TA'
};
$Self->{'Process::NavBarOutput::CacheTTL'} =  '900';
$Self->{'ProcessManagement::Transition::Debug::Enabled'} =  '0';
$Self->{'ProductName'} =  'TESSERA';
$Self->{'PublicFrontend::Active'} =  '1';
$Self->{'PublicFrontend::CommonParam'}->{'Action'} =  'PublicFAQExplorer';
$Self->{'PublicFrontend::HeaderMetaModule'}->{'3-FAQSearch'} =  {
  'Action' => 'PublicFAQSearch',
  'Module' => 'Kernel::Output::HTML::HeaderMeta::PublicFAQSearch'
};
$Self->{'PublicFrontend::Module'}->{'PublicCalendar'} =  {
  'Description' => 'Public calendar.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'Public Calendar'
};
$Self->{'PublicFrontend::Module'}->{'PublicDefault'} =  {
  'Description' => 'PublicDefault',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'PublicDefault'
};
$Self->{'PublicFrontend::Module'}->{'PublicFAQ'} =  {
  'Description' => 'Public FAQ Zoom.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => ''
};
$Self->{'PublicFrontend::Module'}->{'PublicFAQExplorer'} =  {
  'Description' => 'Public FAQ.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => ''
};
$Self->{'PublicFrontend::Module'}->{'PublicFAQPrint'} =  {
  'Description' => 'Public FAQ Print.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => ''
};
$Self->{'PublicFrontend::Module'}->{'PublicFAQRSS'} =  {
  'Description' => 'Public FAQ.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ'
};
$Self->{'PublicFrontend::Module'}->{'PublicFAQSearch'} =  {
  'Description' => 'Public FAQ search.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => 'Search FAQ'
};
$Self->{'PublicFrontend::Module'}->{'PublicFAQZoom'} =  {
  'Description' => 'Public FAQ Zoom.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'FAQ',
  'Title' => ''
};
$Self->{'PublicFrontend::Module'}->{'PublicRepository'} =  {
  'Description' => 'PublicRepository',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'PublicRepository'
};
$Self->{'PublicFrontend::Module'}->{'PublicSupportDataCollector'} =  {
  'Description' => 'PublicSupportDataCollector',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => '',
  'Title' => 'PublicSupportDataCollector'
};
$Self->{'PublicFrontend::Module'}->{'PublicSurvey'} =  {
  'Description' => 'Public Survey.',
  'Group' => [],
  'GroupRo' => [],
  'NavBarName' => 'Survey',
  'Title' => 'Survey'
};
$Self->{'PublicFrontend::Navigation'}->{'PublicFAQExplorer'}->{'002-FAQ'} =  [
  {
    'AccessKey' => 'x',
    'Block' => '',
    'Description' => 'FAQ Area',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=PublicFAQExplorer',
    'LinkOption' => '',
    'Name' => 'FAQ',
    'NavBar' => '',
    'Prio' => '400',
    'Type' => ''
  }
];
$Self->{'PublicFrontend::Navigation'}->{'PublicFAQSearch'}->{'002-FAQ'} =  [
  {
    'AccessKey' => '',
    'Block' => '',
    'Description' => 'FAQ Area',
    'Group' => [],
    'GroupRo' => [],
    'Link' => 'Action=PublicFAQSearch',
    'LinkOption' => '',
    'Name' => 'Search FAQ',
    'NavBar' => '',
    'Prio' => '600',
    'Type' => ''
  }
];
$Self->{'Queue::EventModulePost'}->{'2300-UpdateQueue'} =  {
  'Event' => 'QueueUpdate',
  'Module' => 'Kernel::System::Queue::Event::TicketAcceleratorUpdate',
  'Transaction' => '0'
};
$Self->{'Queue::EventModulePost'}->{'8000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'ReplaceCustomerRealNameOnSlaveArticleCommunicationChannels'} =  {
  'Email' => '0'
};
$Self->{'ReplaceCustomerRealNameOnSlaveArticleTypes'} =  {
  'email-external' => '0',
  'email-internal' => '0',
  'email-notification-ext' => '0',
  'email-notification-int' => '0',
  'fax' => '0',
  'note-external' => '0',
  'note-internal' => '0',
  'note-report' => '0',
  'phone' => '0',
  'sms' => '0',
  'webrequest' => '0'
};
$Self->{'SMIME'} =  '0';
delete $Self->{'SMIME::Bin'};
$Self->{'SMIME::CacheTTL'} =  '86400';
$Self->{'SMIME::Cipher'} =  'aes256';
$Self->{'SMIME::FetchFromCustomer'} =  '0';
$Self->{'SOAP::Keep-Alive'} =  '0';
$Self->{'ScriptAlias'} =  'otobo/';
$Self->{'Secure::DisableBanner'} =  '0';
$Self->{'SecureMode'} =  '1';
$Self->{'SendNoAutoResponseRegExp'} =  '(MAILER-DAEMON|postmaster|abuse)@.+?\\..+?';
$Self->{'SendmailBcc'} =  '';
$Self->{'SendmailModule'} =  'Kernel::System::Email::Sendmail';
$Self->{'SendmailModule::CMD'} =  '/usr/sbin/sendmail -i -f';
$Self->{'SendmailModule::Host'} =  'mail.example.com';
$Self->{'ServiceCatalog::CreateTypeServiceRelatedAcls'} =  '1';
$Self->{'ServiceCatalog::CreateTypeServiceRelatedAcls::Options'} =  {
  'ACLDeploy' => '1',
  'ACLValidID' => '1',
  'ConfigChange' => 'Possible',
  'FrontendAction' => [
    'CustomerTicketMessage',
    'AgentTicketPhone',
    'AgentTicketEmail',
    'AgentTicketFreeText'
  ],
  'GenerateInitalACLToDisableAllServices' => '1'
};
$Self->{'SessionAgentOnlineThreshold'} =  '5';
$Self->{'SessionCSRFProtection'} =  '1';
$Self->{'SessionCheckRemoteIP'} =  '1';
$Self->{'SessionCustomerOnlineThreshold'} =  '5';
$Self->{'SessionDeleteIfNotRemoteID'} =  '1';
$Self->{'SessionDeleteIfTimeToOld'} =  '1';
$Self->{'SessionDir'} =  '<OTOBO_CONFIG_Home>/var/sessions';
$Self->{'SessionMaxIdleTime'} =  '7200';
$Self->{'SessionMaxTime'} =  '57600';
$Self->{'SessionModule'} =  'Kernel::System::AuthSession::DB';
$Self->{'SessionName'} =  'OTOBOAgentInterface';
$Self->{'SessionSameSite'} =  'Lax';
$Self->{'SessionTable'} =  'sessions';
$Self->{'SessionUseCookie'} =  '1';
$Self->{'SessionUseCookieAfterBrowserClose'} =  '0';
$Self->{'ShowMotd'} =  '0';
$Self->{'ShowUserTimeZoneSelectionNotification'} =  '1';
$Self->{'SimpleBruteForceProtection::GeneralSettings'} =  {
  'BanDuration' => '30',
  'KeepCacheDuration' => '60',
  'MaxAttempt' => '3'
};
$Self->{'SkinColorDefinition::highcontrast'} =  {
  'BGDark' => '#000000',
  'BGElement' => '#ffffff',
  'BGLight' => '#ffffff',
  'BGLightMedium' => '#fff',
  'BGMedium' => '#ccc',
  'BGMediumDark' => '#ccc',
  'Highlight' => '#fef235',
  'HoverDark' => '#000',
  'HoverLight' => '#ccc',
  'MainDark' => '#333',
  'MainHover' => '#fff',
  'MainLight' => '#333',
  'NotifyErr' => '#ea2400',
  'NotifyOK' => '#c4cdfa',
  'NotifyWarn' => '#fffccc',
  'TextDark' => '#000000',
  'TextErr' => '#000000',
  'TextLight' => '#ffffff',
  'TextLink' => '#001bff',
  'TextMedium' => '#777',
  'TextWarn' => '#000000'
};
$Self->{'StandardTemplate::Types'} =  {
  'Answer' => 'Answer',
  'Create' => 'Create',
  'Email' => 'Email',
  'Forward' => 'Forward',
  'Note' => 'Note',
  'PhoneCall' => 'Phone call',
  'ProcessDialog' => 'Process dialog'
};
$Self->{'Stats::CustomerIDAsMultiSelect'} =  '1';
$Self->{'Stats::CustomerUserLoginsAsMultiSelect'} =  '0';
$Self->{'Stats::DefaultSelectedDynamicObject'} =  'Ticket';
$Self->{'Stats::DefaultSelectedFormat'} =  [
  'Print',
  'CSV',
  'Excel',
  'D3::BarChart',
  'D3::LineChart',
  'D3::StackedAreaChart'
];
$Self->{'Stats::DefaultSelectedPermissions'} =  [
  'stats'
];
$Self->{'Stats::DynamicObjectRegistration'}->{'ArticleList'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ArticleList'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'ITSMChangeManagement'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ITSMChangeManagement'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'ITSMChangeManagementChangesIncidents'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ITSMChangeManagementChangesIncidents'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'ITSMChangeManagementChangesPerCIClasses'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ITSMChangeManagementChangesPerCIClasses'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'ITSMChangeManagementHistory'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ITSMChangeManagementHistory'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'ITSMChangeManagementRfcRequester'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ITSMChangeManagementRfcRequester'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'ITSMConfigItem'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ITSMConfigItem'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'ITSMTicketFirstLevelSolutionRate'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ITSMTicketFirstLevelSolutionRate'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'ITSMTicketSolutionTimeAverage'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::ITSMTicketSolutionTimeAverage'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'SurveyList'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::SurveyList'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'Ticket'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::Ticket'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'TicketAccountedTime'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::TicketAccountedTime'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'TicketList'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::TicketList'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'TicketSolutionResponseTime'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::TicketSolutionResponseTime'
};
$Self->{'Stats::DynamicObjectRegistration'}->{'TimeAccounting'} =  {
  'Module' => 'Kernel::System::Stats::Dynamic::TimeAccounting'
};
$Self->{'Stats::ExchangeAxis'} =  '1';
$Self->{'Stats::Format'} =  {
  'CSV' => 'CSV',
  'D3::BarChart' => 'Graph: Bar Chart',
  'D3::LineChart' => 'Graph: Line Chart',
  'D3::StackedAreaChart' => 'Graph: Stacked Area Chart',
  'Excel' => 'Excel',
  'Print' => 'Print'
};
$Self->{'Stats::SearchLimit'} =  '1000';
$Self->{'Stats::SearchPageShown'} =  '50';
$Self->{'Stats::StatsHook'} =  'Stat#';
$Self->{'Stats::StatsStartNumber'} =  '10000';
$Self->{'Stats::UseAgentElementInStats'} =  '0';
$Self->{'Stats::UseInvalidAgentInStats'} =  '1';
$Self->{'SupportDataCollector::SkipMaskPasswordSettings'} =  [
  'PreferencesGroups###Password',
  'CustomerPreferencesGroups###Password'
];
$Self->{'Survey::AmountOfSurveysPer30Days'} =  '0';
$Self->{'Survey::CheckSendConditionService'} =  '0';
$Self->{'Survey::CheckSendConditionTicketType'} =  '0';
$Self->{'Survey::DeletePeriod'} =  '365';
$Self->{'Survey::Frontend::AgentSurveyOverview'}->{'ShowColumns'} =  {
  'ChangeBy' => '0',
  'ChangeTime' => '0',
  'CreateBy' => '0',
  'CreateTime' => '1',
  'Description' => '0',
  'Introduction' => '0',
  'NotificationBody' => '0',
  'NotificationSender' => '0',
  'NotificationSubject' => '0',
  'Number' => '1',
  'Status' => '1',
  'Title' => '1'
};
$Self->{'Survey::Frontend::ChangeSurveyStatusGroups'} =  [];
$Self->{'Survey::Frontend::HTMLRichTextHeightDefault'} =  '80';
$Self->{'Survey::Frontend::HTMLRichTextHeightMax'} =  '2500';
$Self->{'Survey::Frontend::MenuModule'}->{'000-Back'} =  {
  'Action' => '',
  'Description' => 'Back',
  'Link' => '[% Env("LastScreenOverview") | html %]',
  'Module' => 'Kernel::Output::HTML::SurveyMenu::Generic',
  'Name' => 'Back',
  'Target' => 'Back'
};
$Self->{'Survey::Frontend::MenuModule'}->{'010-EditGeneralInfo'} =  {
  'Action' => 'AgentSurveyEdit',
  'Description' => 'Edit survey general information.',
  'Link' => 'Action=AgentSurveyEdit;SurveyID=[% Data.SurveyID | html %]',
  'Module' => 'Kernel::Output::HTML::SurveyMenu::Generic',
  'Name' => 'Edit General Info',
  'Target' => 'PopUp'
};
$Self->{'Survey::Frontend::MenuModule'}->{'020-EditQuestions'} =  {
  'Action' => 'AgentSurveyEditQuestions',
  'Description' => 'Edit survey questions.',
  'Link' => 'Action=AgentSurveyEditQuestions;SurveyID=[% Data.SurveyID | html %]',
  'Module' => 'Kernel::Output::HTML::SurveyMenu::Generic',
  'Name' => 'Edit Questions',
  'Target' => 'PopUp'
};
$Self->{'Survey::Frontend::MenuModule'}->{'030-StatsDetails'} =  {
  'Action' => 'AgentSurveyStats',
  'Description' => 'Zoom into statistics details.',
  'Link' => 'Action=AgentSurveyStats;SurveyID=[% Data.SurveyID | html %]',
  'Module' => 'Kernel::Output::HTML::SurveyMenu::Generic',
  'Name' => 'Stats Details',
  'Target' => 'PopUp'
};
$Self->{'Survey::Frontend::Overview'}->{'Small'} =  {
  'Image' => 'overviewsmall.png',
  'ImageSelected' => 'overviewsmall-selected.png',
  'Module' => 'Kernel::Output::HTML::SurveyOverview::Small',
  'Name' => 'Small',
  'NameShort' => 'S',
  'PageShown' => '25'
};
$Self->{'Survey::Hook'} =  'Survey#';
$Self->{'Survey::NotificationBody'} =  'Dear Customer,

Thanks for using our service. Help us to improve us and our services.

Please give us feedback on how to improve our services:

<OTOBO_CONFIG_HttpType>://<OTOBO_CONFIG_FQDN>/<OTOBO_CONFIG_ScriptAlias>public.pl?Action=PublicSurvey;PublicSurveyKey=<OTOBO_PublicSurveyKey>

Thanks for your help!

Your OTOBO-Team
            ';
$Self->{'Survey::NotificationRecipientBlacklist'} =  [];
$Self->{'Survey::NotificationSender'} =  'quality@example.com';
$Self->{'Survey::NotificationSubject'} =  'Help us with your feedback!';
$Self->{'Survey::SendInHoursAfterClose'} =  '0';
$Self->{'Survey::SendNoSurveyRegExp'} =  '(MAILER-DAEMON|postmaster|abuse)@.+?\\..+?';
$Self->{'Survey::SendOnlyToRealCustomer'} =  '0';
$Self->{'Survey::SendPeriod'} =  '300';
$Self->{'SuspendEscalatedTickets'} =  '0';
$Self->{'SwitchToCustomer'} =  '0';
$Self->{'SwitchToCustomer::PermissionGroup'} =  'admin';
$Self->{'SwitchToUser'} =  '0';
$Self->{'System::Customer::Permission'} =  [
  'ro',
  'rw'
];
$Self->{'System::Permission'} =  [
  'ro',
  'move_into',
  'create',
  'note',
  'owner',
  'priority',
  'rw'
];
$Self->{'SystemConfiguration::MaximumDeployments'} =  '20';
$Self->{'SystemID'} =  '25';
$Self->{'SystemMaintenance::IsActiveDefaultLoginErrorMessage'} =  'We are performing scheduled maintenance. Login is temporarily not available.';
$Self->{'SystemMaintenance::IsActiveDefaultLoginMessage'} =  'We are performing scheduled maintenance. We should be back online shortly.';
$Self->{'SystemMaintenance::IsActiveDefaultNotification'} =  'We are performing scheduled maintenance.';
$Self->{'SystemMaintenance::TimeNotifyUpcomingMaintenance'} =  '120';
$Self->{'SystemMonitoring::LinkTicketWithCI'} =  '0';
$Self->{'SystemMonitoring::SetIncidentState'} =  '0';
$Self->{'Ticket::ArchiveSystem'} =  '0';
$Self->{'Ticket::ArchiveSystem::RemoveSeenFlags'} =  '1';
$Self->{'Ticket::ArchiveSystem::RemoveTicketWatchers'} =  '1';
$Self->{'Ticket::Article::Backend::MIMEBase::ArticleDataDir'} =  '<OTOBO_CONFIG_Home>/var/article';
$Self->{'Ticket::Article::Backend::MIMEBase::ArticleStorage'} =  'Kernel::System::Ticket::Article::Backend::MIMEBase::ArticleStorageDB';
$Self->{'Ticket::Article::Backend::MIMEBase::CheckAllStorageBackends'} =  '0';
$Self->{'Ticket::Article::Backend::MIMEBase::IndexAttachmentNames'} =  '1';
$Self->{'Ticket::ChangeOwnerToEveryone'} =  '0';
$Self->{'Ticket::CustomQueue'} =  'My Queues';
$Self->{'Ticket::CustomService'} =  'My Services';
$Self->{'Ticket::CustomerArchiveSystem'} =  '0';
$Self->{'Ticket::CustomerFrontend::SeparateDynamicFields'} =  {
  'TitleCategory' => '1',
  'TitleDynamicFields' => '1',
  'TitleMessage' => '1'
};
$Self->{'Ticket::CustomerTicketSearch::Order::Default'} =  'Down';
$Self->{'Ticket::CustomerTicketSearch::SearchLimit'} =  '5000';
$Self->{'Ticket::CustomerTicketSearch::SearchPageShown'} =  '40';
$Self->{'Ticket::CustomerTicketSearch::SortBy::Default'} =  'Age';
$Self->{'Ticket::CustomerViewableStateType'} =  [
  'new',
  'open',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::DefineEmailFrom'} =  'SystemAddressName';
$Self->{'Ticket::DefineEmailFromSeparator'} =  'via';
$Self->{'Ticket::Event::NotificationEvent::IgnoredAttributes'}->{'001-Framework'} =  {
  'AgentEnabledByDefault' => '1',
  'ArticleAttachmentInclude' => '1',
  'ArticleCommunicationChannelID' => '1',
  'ArticleIsVisibleForCustomer' => '1',
  'ArticleSenderTypeID' => '1',
  'EmailDefaultSigningKeys' => '1',
  'EmailMissingCryptingKeys' => '1',
  'EmailMissingSigningKeys' => '1',
  'EmailSecuritySettings' => '1',
  'EmailSigningCrypting' => '1',
  'Events' => '1',
  'IsVisibleForCustomer' => '1',
  'LanguageID' => '1',
  'NotificationType' => '1',
  'OncePerDay' => '1',
  'RecipientAgents' => '1',
  'RecipientGroups' => '1',
  'RecipientRoles' => '1',
  'Recipients' => '1',
  'SendOnOutOfOffice' => '1',
  'SkipRecipients' => '1',
  'TransportEmailTemplate' => '1',
  'Transports' => '1',
  'VisibleForAgent' => '1',
  'VisibleForAgentTooltip' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'042-ITSMConfigItemTicketStatusLink'} =  {
  'Event' => '(TicketStateUpdate|TicketTypeUpdate)',
  'Module' => 'Kernel::System::Ticket::Event::TicketStatusLink'
};
$Self->{'Ticket::EventModulePost'}->{'2300-ArchiveRestore'} =  {
  'Event' => 'TicketStateUpdate',
  'Module' => 'Kernel::System::Ticket::Event::ArchiveRestore'
};
$Self->{'Ticket::EventModulePost'}->{'2600-AcceleratorUpdate'} =  {
  'Event' => 'TicketStateUpdate|TicketQueueUpdate|TicketLockUpdate',
  'Module' => 'Kernel::System::Ticket::Event::TicketAcceleratorUpdate'
};
$Self->{'Ticket::EventModulePost'}->{'3000-ResponsibleAutoSet'} =  {
  'Event' => 'TicketOwnerUpdate',
  'Module' => 'Kernel::System::Ticket::Event::ResponsibleAutoSet'
};
$Self->{'Ticket::EventModulePost'}->{'3300-TicketPendingTimeReset'} =  {
  'Event' => 'TicketStateUpdate',
  'Module' => 'Kernel::System::Ticket::Event::TicketPendingTimeReset'
};
$Self->{'Ticket::EventModulePost'}->{'3600-ForceUnlockOnMove'} =  {
  'Event' => 'TicketQueueUpdate',
  'Module' => 'Kernel::System::Ticket::Event::ForceUnlock'
};
$Self->{'Ticket::EventModulePost'}->{'4000-ScriptDynamicFields'} =  {
  'Event' => '',
  'Module' => 'Kernel::System::Ticket::Event::EvaluateScriptFields',
  'Transaction' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'4000-TicketArticleNewMessageUpdate'} =  {
  'Event' => 'ArticleCreate|ArticleFlagSet',
  'Module' => 'Kernel::System::Ticket::Event::TicketNewMessageUpdate'
};
$Self->{'Ticket::EventModulePost'}->{'4300-EscalationStopEvents'} =  {
  'Event' => 'TicketSLAUpdate|TicketQueueUpdate|TicketStateUpdate|ArticleCreate',
  'Module' => 'Kernel::System::Ticket::Event::TriggerEscalationStopEvents',
  'Transaction' => '0'
};
$Self->{'Ticket::EventModulePost'}->{'7000-NotificationEvent'} =  {
  'Event' => '',
  'Module' => 'Kernel::System::Ticket::Event::NotificationEvent',
  'Transaction' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'8000-GenericInterface'} =  {
  'Event' => '',
  'Module' => 'Kernel::GenericInterface::Event::Handler',
  'Transaction' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'9-Icinga2Acknowledge'} =  {
  'Event' => 'TicketLockUpdate',
  'Module' => 'Kernel::System::Ticket::Event::Icinga2Acknowledge'
};
$Self->{'Ticket::EventModulePost'}->{'9-NagiosAcknowledge'} =  {
  'Event' => 'TicketLockUpdate',
  'Module' => 'Kernel::System::Ticket::Event::NagiosAcknowledge'
};
$Self->{'Ticket::EventModulePost'}->{'950-StoreHistoricalData'} =  {
  'Event' => 'TicketDynamicFieldUpdate_*|ArticleDynamicFieldUpdate',
  'Module' => 'Kernel::System::Ticket::Event::StoreHistoricalData',
  'Transaction' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'950-TicketAppointments'} =  {
  'Event' => 'TicketSLAUpdate|TicketQueueUpdate|TicketStateUpdate|TicketCreate|ArticleCreate|TicketPendingTimeUpdate|TicketDynamicFieldUpdate_.*',
  'Module' => 'Kernel::System::Ticket::Event::TicketAppointments',
  'Transaction' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'9700-GenericAgent'} =  {
  'Event' => '',
  'Module' => 'Kernel::System::Ticket::Event::GenericAgent',
  'Transaction' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'9800-TicketProcessTransitions'} =  {
  'Event' => '',
  'Module' => 'Kernel::System::Ticket::Event::TicketProcessTransitions',
  'Transaction' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'99-SurveySendRequest'} =  {
  'Event' => '(ArticleCreate|TicketStateUpdate)',
  'Module' => 'Kernel::System::Ticket::Event::SurveySendRequest'
};
$Self->{'Ticket::EventModulePost'}->{'999-TimeAccountingTicketTimeUnitsSync'} =  {
  'Event' => 'TicketAccountTime',
  'Module' => 'Kernel::System::Ticket::Event::TimeAccountingTicketTimeUnitsSync'
};
$Self->{'Ticket::EventModulePost'}->{'9990-EscalationIndex'} =  {
  'Event' => 'TicketSLAUpdate|TicketQueueUpdate|TicketStateUpdate|TicketCreate|ArticleCreate|TicketDynamicFieldUpdate|TicketTypeUpdate|TicketServiceUpdate|TicketCustomerUpdate|TicketPriorityUpdate|TicketMerge',
  'Module' => 'Kernel::System::Ticket::Event::TicketEscalationIndex',
  'Transaction' => '1'
};
$Self->{'Ticket::EventModulePost'}->{'MasterSlave'} =  {
  'Event' => 'ArticleCreate|ArticleSend|TicketStateUpdate|TicketPriorityUpdate|TicketPendingTimeUpdate|TicketLockUpdate|TicketOwnerUpdate|TicketResponsibleUpdate',
  'Module' => 'Kernel::System::Ticket::Event::MasterSlave'
};
$Self->{'Ticket::Frontend::AccountTime'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'DynamicField'} =  {
  'ITSMDueDate' => '1',
  'ITSMRecoveryStartTime' => '1',
  'ITSMRepairStartTime' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'HistoryComment'} =  '%%FreeText';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Note'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'NoteMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Permission'} =  'rw';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketAddtlITSMField'}->{'Title'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Article'} =  'Internal';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'ArticleCustomerVisible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'EditCustomerArticles'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'FormDraft'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'HistoryComment'} =  '%%ArticleEdit';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'HistoryType'} =  'ArticleEdit';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'InformAgent'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'InvolvedAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'IsVisibleForCustomer'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'NoteMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Permission'} =  'note';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Priority'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'TimeUnits'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketArticleEdit'}->{'Title'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketBounce'}->{'Permission'} =  'bounce';
$Self->{'Ticket::Frontend::AgentTicketBounce'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketBounce'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketBounce'}->{'StateDefault'} =  'closed successful';
$Self->{'Ticket::Frontend::AgentTicketBounce'}->{'StateType'} =  [
  'open',
  'closed'
];
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'Owner'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'Priority'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'Responsible'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'State'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketBulk'}->{'TicketType'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'DynamicField'} =  {
  'ITSMReviewRequired' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'HistoryComment'} =  '%%Close';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'InformAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'InvolvedAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'NoteMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Permission'} =  'close';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Priority'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'State'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'StateDefault'} =  'closed successful';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'StateType'} =  [
  'closed'
];
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketClose'}->{'Title'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'DynamicField'} =  {
  'ITSMReviewRequired' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'IsVisibleForCustomerDefault'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'Permission'} =  'compose';
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'StateDefault'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketCompose'}->{'StateType'} =  [
  'open',
  'closed',
  'pending auto',
  'pending reminder'
];
$Self->{'Ticket::Frontend::AgentTicketCustomer'}->{'Permission'} =  'customer';
$Self->{'Ticket::Frontend::AgentTicketCustomer'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketCustomer::CustomerIDReadOnly'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'DynamicField'} =  {
  'ITSMDecisionDate' => '1',
  'ITSMDecisionResult' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'HistoryComment'} =  '%%Note';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'NoteMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Permission'} =  'rw';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketDecision'}->{'Title'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'DynamicField'} =  {
  'ITSMDueDate' => '1',
  'ITSMImpact' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'HistoryComment'} =  '';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'HistoryType'} =  'EmailAgent';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'IsVisibleForCustomer'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'Priority'} =  '3 normal';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'SenderType'} =  'agent';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'SplitLinkType'} =  {
  'Direction' => 'Target',
  'LinkType' => 'ParentChild'
};
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'StateDefault'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'StateType'} =  [
  'open',
  'pending auto',
  'pending reminder',
  'closed'
];
$Self->{'Ticket::Frontend::AgentTicketEmail'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketEmail::CustomerIDReadOnly'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'Permission'} =  'compose';
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'StateDefault'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketEmailOutbound'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketEmailResend'}->{'IsVisibleForCustomerDefault'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketEmailResend'}->{'Permission'} =  'compose';
$Self->{'Ticket::Frontend::AgentTicketEmailResend'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketEmailResend'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketEmailResend'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketEscalationView'}->{'DefaultColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '2',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '1',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketEscalationView'}->{'Order::Default'} =  'Up';
$Self->{'Ticket::Frontend::AgentTicketEscalationView'}->{'SortBy::Default'} =  'EscalationTime';
$Self->{'Ticket::Frontend::AgentTicketEscalationView'}->{'TicketPermission'} =  'rw';
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'IsVisibleForCustomerDefault'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'Permission'} =  'forward';
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'StateDefault'} =  'closed successful';
$Self->{'Ticket::Frontend::AgentTicketForward'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'HistoryComment'} =  '%%FreeText';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'InformAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'InvolvedAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Note'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'NoteMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Permission'} =  'rw';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Priority'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Service'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'TicketType'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketFreeText'}->{'Title'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketLockedView'}->{'DefaultColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '1',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '1',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketLockedView'}->{'Order::Default'} =  'Up';
$Self->{'Ticket::Frontend::AgentTicketLockedView'}->{'SortBy::Default'} =  'Age';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'HistoryComment'} =  '%%MasterSlave';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'MasterSlaveMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'NoteMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'Permission'} =  'MasterSlave';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'RichTextHeight'} =  '100';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'StateDefault'} =  'pending reminder';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMasterSlave'}->{'Title'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMerge'}->{'Permission'} =  'rw';
$Self->{'Ticket::Frontend::AgentTicketMerge'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketMerge'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketMerge'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'NextScreen'} =  'TicketZoom';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'Note'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'NoteMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'Priority'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'State'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'StateType'} =  [
  'open',
  'closed'
];
$Self->{'Ticket::Frontend::AgentTicketMove'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'HistoryComment'} =  '%%Note';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'InformAgent'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'InvolvedAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'NoteMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Permission'} =  'note';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Priority'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'StateType'} =  [
  'open',
  'closed',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketNote'}->{'Title'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'HistoryComment'} =  '%%Owner';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'InformAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'InvolvedAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'NoteMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Owner'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'OwnerMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Permission'} =  'owner';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Priority'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'StateDefault'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'StateType'} =  [
  'open',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketOwner'}->{'Title'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'HistoryComment'} =  '%%Pending';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'InformAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'InvolvedAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'NoteMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Permission'} =  'pending';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Priority'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'State'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'StateDefault'} =  'pending reminder';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'StateType'} =  [
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPending'}->{'Title'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'DynamicField'} =  {
  'ITSMDueDate' => '1',
  'ITSMImpact' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'HistoryComment'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'HistoryType'} =  'PhoneCallCustomer';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'IsVisibleForCustomer'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'Priority'} =  '3 normal';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'SenderType'} =  'customer';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'SplitLinkType'} =  {
  'Direction' => 'Target',
  'LinkType' => 'ParentChild'
};
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'StateDefault'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'StateType'} =  [
  'open',
  'pending auto',
  'pending reminder',
  'closed'
];
$Self->{'Ticket::Frontend::AgentTicketPhone'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPhone::AllowMultipleFrom'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPhone::CustomerIDReadOnly'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'HistoryComment'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'HistoryType'} =  'PhoneCallCustomer';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'Permission'} =  'phone';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'RichTextWidth'} =  '475';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'SenderType'} =  'customer';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'State'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'StateType'} =  [
  'open',
  'pending auto',
  'pending reminder',
  'closed'
];
$Self->{'Ticket::Frontend::AgentTicketPhoneInbound'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'HistoryComment'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'HistoryType'} =  'PhoneCallAgent';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'Permission'} =  'phone';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'RichTextWidth'} =  '475';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'SenderType'} =  'agent';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'State'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'StateType'} =  [
  'open',
  'pending auto',
  'pending reminder',
  'closed'
];
$Self->{'Ticket::Frontend::AgentTicketPhoneOutbound'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPrint'}->{'DynamicField'} =  {
  'ITSMCriticality' => '1',
  'ITSMImpact' => '1',
  'ZTicket-Application' => '1',
  'ZTicket-ApprovalGroup' => '1',
  'ZTicket-ApprovalModel' => '1',
  'ZTicket-EndorsementGroup' => '1',
  'ZTicket-Env' => '1',
  'ZTicket-Location' => '1',
  'ZTicket-OwnerGroup' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'DynamicField'} =  {
  'ITSMImpact' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'HistoryComment'} =  '%%Priority';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'InformAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'InvolvedAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'NoteMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Permission'} =  'priority';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Priority'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Responsible'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'ResponsibleMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Service'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'StateDefault'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'StateType'} =  [
  'open',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'TicketType'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketPriority'}->{'Title'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketProcess'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketProcess'}->{'SplitLinkType'} =  {
  'Direction' => 'Target',
  'LinkType' => 'ParentChild'
};
$Self->{'Ticket::Frontend::AgentTicketProcess'}->{'StateType'} =  [
  'new',
  'open',
  'pending auto',
  'pending reminder',
  'closed'
];
$Self->{'Ticket::Frontend::AgentTicketProcess::CustomerIDReadOnly'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'Blink'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'DefaultColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '1',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '1',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'HideEmptyQueues'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'HighlightAge1'} =  '1440';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'HighlightAge2'} =  '2880';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'Order::Default'} =  'Up';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'PreSort::ByPriority'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'SortBy::Default'} =  'Age';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'StripEmptyLines'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'UseSubQueues'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'ViewAllPossibleTickets'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketQueue'}->{'VisualAlarms'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'Article'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'Body'} =  'Ticket closed';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'CommunicationChannel'} =  'Internal';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'ContentType'} =  'text/plain; charset=utf-8';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'HistoryComment'} =  'Ticket was closed';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'IsVisibleForCustomer'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'Permission'} =  'close';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'RequiredLock'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'SenderType'} =  'agent';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'State'} =  'closed successful';
$Self->{'Ticket::Frontend::AgentTicketQuickClose'}->{'Subject'} =  'Ticket closed';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Body'} =  '';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'FormDraft'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'HistoryComment'} =  '%%Responsible';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'HistoryType'} =  'AddNote';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'InformAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'InvolvedAgent'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'IsVisibleForCustomerDefault'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Note'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'NoteMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'OwnerMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Permission'} =  'responsible';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Priority'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'QueueMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'QuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'RequiredLock'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Responsible'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'ResponsibleMandatory'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'RichTextHeight'} =  '320';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'RichTextWidth'} =  '620';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Service'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'ServiceMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'ShowIncidentState'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'State'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'StateDefault'} =  'open';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'StateMandatory'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'StateType'} =  [
  'open',
  'pending reminder',
  'pending auto'
];
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Subject'} =  '';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'TicketType'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketResponsible'}->{'Title'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketResponsibleView'}->{'DefaultColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '1',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '1',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketResponsibleView'}->{'Order::Default'} =  'Up';
$Self->{'Ticket::Frontend::AgentTicketResponsibleView'}->{'SortBy::Default'} =  'Age';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'ArticleCreateTime'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'DefaultColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '1',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '1',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'Defaults'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'Defaults'}->{'Fulltext'} =  '';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'DynamicField'} =  {
  'ITSMDecisionDate' => '1',
  'ITSMDecisionResult' => '1',
  'ITSMDueDate' => '1',
  'ITSMImpact' => '1',
  'ITSMRecoveryStartTime' => '1',
  'ITSMRepairStartTime' => '1',
  'ITSMReviewRequired' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'ExtendedSearchCondition'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'Order::Default'} =  'Down';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'SearchArticleCSVTree'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'SearchCSVData'} =  [
  'TicketNumber',
  'Age',
  'Created',
  'Closed',
  'FirstLock',
  'FirstResponse',
  'State',
  'Priority',
  'Queue',
  'Lock',
  'Owner',
  'UserFirstname',
  'UserLastname',
  'CustomerID',
  'CustomerName',
  'From',
  'Subject',
  'AccountedTime',
  'ArticleTree',
  'SolutionInMin',
  'SolutionDiffInMin',
  'FirstResponseInMin',
  'FirstResponseDiffInMin'
];
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'SearchCSVDynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'SearchLimit'} =  '2000';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'SearchPageShown'} =  '40';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'SearchViewableTicketLines'} =  '10';
$Self->{'Ticket::Frontend::AgentTicketSearch'}->{'SortBy::Default'} =  'Age';
$Self->{'Ticket::Frontend::AgentTicketService'}->{'DefaultColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '1',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '2',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketService'}->{'Order::Default'} =  'Up';
$Self->{'Ticket::Frontend::AgentTicketService'}->{'PreSort::ByPriority'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketService'}->{'SortBy::Default'} =  'Age';
$Self->{'Ticket::Frontend::AgentTicketService'}->{'StripEmptyLines'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketService'}->{'ViewAllPossibleTickets'} =  '0';
$Self->{'Ticket::Frontend::AgentTicketStatusView'}->{'DefaultColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '1',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '1',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketStatusView'}->{'Order::Default'} =  'Down';
$Self->{'Ticket::Frontend::AgentTicketStatusView'}->{'SortBy::Default'} =  'Age';
$Self->{'Ticket::Frontend::AgentTicketWatchView'}->{'DefaultColumns'} =  {
  'Age' => '2',
  'Changed' => '1',
  'Created' => '1',
  'CustomerCompanyName' => '1',
  'CustomerID' => '2',
  'CustomerName' => '1',
  'CustomerUserID' => '1',
  'EscalationResponseTime' => '1',
  'EscalationSolutionTime' => '1',
  'EscalationTime' => '1',
  'EscalationUpdateTime' => '1',
  'Lock' => '2',
  'Owner' => '2',
  'PendingTime' => '1',
  'Priority' => '1',
  'Queue' => '2',
  'Responsible' => '1',
  'SLA' => '1',
  'Sender' => '2',
  'Service' => '1',
  'State' => '2',
  'Subject' => '1',
  'TicketNumber' => '2',
  'Title' => '2',
  'Type' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketWatchView'}->{'Order::Default'} =  'Up';
$Self->{'Ticket::Frontend::AgentTicketWatchView'}->{'SortBy::Default'} =  'Age';
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'DynamicField'} =  {
  'ITSMCriticality' => '1',
  'ITSMDecisionDate' => '1',
  'ITSMDecisionResult' => '1',
  'ITSMDueDate' => '1',
  'ITSMImpact' => '1',
  'ITSMRecoveryStartTime' => '1',
  'ITSMRepairStartTime' => '1',
  'ITSMReviewRequired' => '1',
  'MasterSlave' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'DynamicFieldWidgetDisplay'} =  {
  'NavBarName' => 'Dynamic Fields',
  'WidgetTitle' => 'Dynamic Field Information'
};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'DynamicFieldWidgetDynamicField'} =  {};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'ProcessDisplay'} =  {
  'NavBarName' => 'Processes',
  'WidgetTitle' => 'Process Information'
};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'ProcessWidgetDynamicField'} =  {
  'FirewallPolicyRule' => '1'
};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'ProcessWidgetDynamicFieldGroups'} =  {
  'Firewall Policy' => 'FirewallPolicyRule'
};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'ServiceInciStateSignal'} =  '1';
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'Widgets'}->{'0100-TicketInformation'} =  {
  'Location' => 'Sidebar',
  'Module' => 'Kernel::Output::HTML::TicketZoom::TicketInformation'
};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'Widgets'}->{'0200-CustomerInformation'} =  {
  'Async' => '1',
  'Location' => 'Sidebar',
  'Module' => 'Kernel::Output::HTML::TicketZoom::CustomerInformation'
};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'Widgets'}->{'0210-DynamicField-ContactWD'} =  {
  'Async' => '1',
  'Location' => 'Sidebar',
  'Module' => 'Kernel::Output::HTML::TicketZoom::ContactWD'
};
$Self->{'Ticket::Frontend::AgentTicketZoom'}->{'Widgets'}->{'0300-LinkTable'} =  {
  'Module' => 'Kernel::Output::HTML::TicketZoom::LinkTable'
};
$Self->{'Ticket::Frontend::AgentZoomExpand'} =  '0';
$Self->{'Ticket::Frontend::Article::Actions'}->{'Chat'} =  {
  'AgentTicketCompose' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketCompose',
    'Prio' => '100',
    'Valid' => '1'
  },
  'AgentTicketForward' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketForward',
    'Prio' => '200',
    'Valid' => '1'
  },
  'AgentTicketPrint' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPrint',
    'Prio' => '500',
    'Valid' => '1'
  },
  'ArticlePin' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::ArticlePin',
    'Prio' => '800',
    'Valid' => '1'
  },
  'MarkArticleSeenUnseen' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkArticleSeenUnseen',
    'Prio' => '300',
    'Valid' => '1'
  },
  'MarkAsImportant' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkAsImportant',
    'Prio' => '700',
    'Valid' => '1'
  }
};
$Self->{'Ticket::Frontend::Article::Actions'}->{'Email'} =  {
  'AgentTicketArticleDelete' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleDelete',
    'Prio' => '20',
    'Valid' => '1'
  },
  'AgentTicketArticleEdit' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleEdit',
    'Prio' => '50',
    'Valid' => '1'
  },
  'AgentTicketArticleRestore' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleRestore',
    'Prio' => '10',
    'Valid' => '1'
  },
  'AgentTicketArticleVersion' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleVersion',
    'Prio' => '30',
    'Valid' => '1'
  },
  'AgentTicketBounce' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketBounce',
    'Prio' => '300',
    'Valid' => '1'
  },
  'AgentTicketCompose' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketCompose',
    'Prio' => '100',
    'Valid' => '1'
  },
  'AgentTicketEmailResend' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketEmailResend',
    'Prio' => '900',
    'Valid' => '1'
  },
  'AgentTicketForward' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketForward',
    'Prio' => '200',
    'Valid' => '1'
  },
  'AgentTicketMessageLog' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketMessageLog',
    'Prio' => '550',
    'Valid' => '1'
  },
  'AgentTicketNote' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketNote',
    'Prio' => '800',
    'Valid' => '1'
  },
  'AgentTicketPhone' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPhone',
    'Prio' => '400',
    'Valid' => '1'
  },
  'AgentTicketPlain' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPlain',
    'Prio' => '600',
    'Valid' => '1'
  },
  'AgentTicketPrint' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPrint',
    'Prio' => '500',
    'Valid' => '1'
  },
  'MarkArticleSeenUnseen' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkArticleSeenUnseen',
    'Prio' => '1000',
    'Valid' => '1'
  },
  'MarkAsImportant' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkAsImportant',
    'Prio' => '700',
    'Valid' => '1'
  }
};
$Self->{'Ticket::Frontend::Article::Actions'}->{'Internal'} =  {
  'AgentTicketArticleDelete' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleDelete',
    'Prio' => '20',
    'Valid' => '1'
  },
  'AgentTicketArticleEdit' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleEdit',
    'Prio' => '40',
    'Valid' => '1'
  },
  'AgentTicketArticleRestore' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleRestore',
    'Prio' => '10',
    'Valid' => '1'
  },
  'AgentTicketArticleVersion' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleVersion',
    'Prio' => '30',
    'Valid' => '1'
  },
  'AgentTicketBounce' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketBounce',
    'Prio' => '300',
    'Valid' => '1'
  },
  'AgentTicketCompose' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketCompose',
    'Prio' => '100',
    'Valid' => '1'
  },
  'AgentTicketForward' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketForward',
    'Prio' => '200',
    'Valid' => '1'
  },
  'AgentTicketNote' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketNote',
    'Prio' => '800',
    'Valid' => '1'
  },
  'AgentTicketPhone' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPhone',
    'Prio' => '400',
    'Valid' => '1'
  },
  'AgentTicketPlain' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPlain',
    'Prio' => '600',
    'Valid' => '1'
  },
  'AgentTicketPrint' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPrint',
    'Prio' => '500',
    'Valid' => '1'
  },
  'ArticlePin' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::ArticlePin',
    'Prio' => '1000',
    'Valid' => '1'
  },
  'MarkArticleSeenUnseen' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkArticleSeenUnseen',
    'Prio' => '900',
    'Valid' => '1'
  },
  'MarkAsImportant' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkAsImportant',
    'Prio' => '700',
    'Valid' => '1'
  }
};
$Self->{'Ticket::Frontend::Article::Actions'}->{'Invalid'} =  {
  'GetHelpLink' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::GetHelpLink',
    'Prio' => '100',
    'Valid' => '1'
  },
  'MarkArticleSeenUnseen' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkArticleSeenUnseen',
    'Prio' => '100',
    'Valid' => '1'
  },
  'ReinstallPackageLink' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::ReinstallPackageLink',
    'Prio' => '200',
    'Valid' => '1'
  }
};
$Self->{'Ticket::Frontend::Article::Actions'}->{'Phone'} =  {
  'AgentTicketArticleDelete' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleDelete',
    'Prio' => '20',
    'Valid' => '1'
  },
  'AgentTicketArticleEdit' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleEdit',
    'Prio' => '1100',
    'Valid' => '1'
  },
  'AgentTicketArticleRestore' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleRestore',
    'Prio' => '10',
    'Valid' => '1'
  },
  'AgentTicketArticleVersion' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketArticleVersion',
    'Prio' => '30',
    'Valid' => '1'
  },
  'AgentTicketBounce' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketBounce',
    'Prio' => '300',
    'Valid' => '1'
  },
  'AgentTicketCompose' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketCompose',
    'Prio' => '100',
    'Valid' => '1'
  },
  'AgentTicketForward' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketForward',
    'Prio' => '200',
    'Valid' => '1'
  },
  'AgentTicketNote' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketNote',
    'Prio' => '800',
    'Valid' => '1'
  },
  'AgentTicketPhone' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPhone',
    'Prio' => '400',
    'Valid' => '1'
  },
  'AgentTicketPlain' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPlain',
    'Prio' => '600',
    'Valid' => '1'
  },
  'AgentTicketPrint' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::AgentTicketPrint',
    'Prio' => '500',
    'Valid' => '1'
  },
  'MarkArticleSeenUnseen' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkArticleSeenUnseen',
    'Prio' => '900',
    'Valid' => '1'
  },
  'MarkAsImportant' => {
    'Module' => 'Kernel::Output::HTML::ArticleAction::MarkAsImportant',
    'Prio' => '700',
    'Valid' => '1'
  }
};
$Self->{'Ticket::Frontend::ArticleAttachmentModule'}->{'1-Download'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleAttachment::Download'
};
$Self->{'Ticket::Frontend::ArticleAttachmentModule'}->{'2-HTML-Viewer'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleAttachment::HTMLViewer'
};
$Self->{'Ticket::Frontend::ArticleComposeModule'}->{'1-EmailSecurity'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleCompose::Security',
  'ParamType' => 'Single'
};
$Self->{'Ticket::Frontend::ArticleComposeModule'}->{'2-SignEmail'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleCompose::Sign',
  'ParamType' => 'Single'
};
$Self->{'Ticket::Frontend::ArticleComposeModule'}->{'3-CryptEmail'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleCompose::Crypt',
  'ParamType' => 'Multiple'
};
$Self->{'Ticket::Frontend::ArticleHeadVisibleDefault'} =  '0';
$Self->{'Ticket::Frontend::ArticlePreViewModule'}->{'1-PGP'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleCheck::PGP'
};
$Self->{'Ticket::Frontend::ArticlePreViewModule'}->{'2-SMIME'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleCheck::SMIME'
};
$Self->{'Ticket::Frontend::ArticleViewModule'}->{'1-PGP'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleCheck::PGP'
};
$Self->{'Ticket::Frontend::ArticleViewModule'}->{'1-SMIME'} =  {
  'Module' => 'Kernel::Output::HTML::ArticleCheck::SMIME'
};
$Self->{'Ticket::Frontend::AutomaticMergeSubject'} =  'Ticket Merged';
$Self->{'Ticket::Frontend::AutomaticMergeText'} =  'Merged Ticket <OTOBO_TICKET> to <OTOBO_MERGE_TO_TICKET>.';
$Self->{'Ticket::Frontend::BlockLoadingRemoteContent'} =  '0';
$Self->{'Ticket::Frontend::BounceText'} =  'Your email with ticket number "<OTOBO_TICKET>" is bounced to "<OTOBO_BOUNCE_TO>". Contact this address for further information.';
$Self->{'Ticket::Frontend::BulkAccountedTime'} =  '1';
$Self->{'Ticket::Frontend::BulkFeature'} =  '1';
$Self->{'Ticket::Frontend::BulkModule'}->{'001-MarkTicketSeenUnseen'} =  {
  'Description' => 'Mark tickets as seen or unseen via bulk action',
  'Module' => 'Kernel::Output::HTML::TicketBulk::MarkTicketSeenUnseen',
  'Name' => 'MarkTicketSeenUnseen'
};
$Self->{'Ticket::Frontend::BulkModule'}->{'010-MasterSlave'} =  {
  'Module' => 'Kernel::Output::HTML::TicketBulk::MasterSlave'
};
$Self->{'Ticket::Frontend::ComposeAddCustomerAddress'} =  '1';
$Self->{'Ticket::Frontend::ComposeReplaceSenderAddress'} =  '0';
$Self->{'Ticket::Frontend::CustomerDisableCompanyTicketAccess'} =  '0';
$Self->{'Ticket::Frontend::CustomerInfoCompose'} =  '1';
$Self->{'Ticket::Frontend::CustomerInfoComposeMaxSize'} =  '22';
$Self->{'Ticket::Frontend::CustomerInfoZoomMaxSize'} =  '40';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'DynamicField'} =  {
  'ZTicket-Application' => '2',
  'ZTicket-Env' => '2',
  'ZTicket-Location' => '2'
};
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'HistoryComment'} =  '';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'HistoryType'} =  'WebRequestCustomer';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'NextScreenAfterNewTicket'} =  'CustomerTicketOverview';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'Priority'} =  '1';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'PriorityDefault'} =  '3 normal';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'Queue'} =  '1';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'QueueDefault'} =  'IPC';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'SLA'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'SLAMandatory'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'SenderType'} =  'customer';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'Service'} =  '1';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'ServiceMandatory'} =  '1';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'StateDefault'} =  'new';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'TicketType'} =  '1';
$Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'TicketTypeDefault'} =  'ServiceRequest';
$Self->{'Ticket::Frontend::CustomerTicketOverview'}->{'ColumnHeader'} =  'TicketTitle';
$Self->{'Ticket::Frontend::CustomerTicketOverview'}->{'DynamicField'} =  {
  'ZTicket-Location' => '2',
  'ZTicket-Parent' => '1'
};
$Self->{'Ticket::Frontend::CustomerTicketOverview'}->{'Owner'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketOverview'}->{'Queue'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketOverviewSortable'} =  'Sortable';
$Self->{'Ticket::Frontend::CustomerTicketPrint'}->{'CustomerInformation'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketPrint'}->{'DynamicField'} =  {
  'ITSMCriticality' => '1',
  'ITSMImpact' => '1'
};
$Self->{'Ticket::Frontend::CustomerTicketProcess'}->{'NextScreenAfterFollowUp'} =  'CustomerTicketOverview';
$Self->{'Ticket::Frontend::CustomerTicketProcess'}->{'StateType'} =  [
  'new',
  'open'
];
$Self->{'Ticket::Frontend::CustomerTicketSearch'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::CustomerTicketSearch'}->{'ExtendedSearchCondition'} =  '1';
$Self->{'Ticket::Frontend::CustomerTicketSearch'}->{'SearchArticleCSVTree'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketSearch'}->{'SearchCSVData'} =  [
  'TicketNumber',
  'Age',
  'Created',
  'Closed',
  'State',
  'Priority',
  'Lock',
  'CustomerID',
  'CustomerName',
  'From',
  'Subject'
];
$Self->{'Ticket::Frontend::CustomerTicketSearch'}->{'SearchCSVDynamicField'} =  {};
$Self->{'Ticket::Frontend::CustomerTicketSearch'}->{'SearchOverviewDynamicField'} =  {};
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'AttributesView'} =  {
  'Owner' => '0',
  'Priority' => '1',
  'Queue' => '1',
  'Responsible' => '0',
  'SLA' => '0',
  'Service' => '0',
  'State' => '1',
  'Type' => '0'
};
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'CustomerZoomExpand'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'DefaultAgentName'} =  'Support Agent';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'DisplayNoteFrom'} =  'FromField';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'DynamicField'} =  {
  'ZTicket-Application' => '1',
  'ZTicket-ApprovalGroup' => '1',
  'ZTicket-Env' => '1',
  'ZTicket-Location' => '1',
  'ZTicket-OwnerGroup' => '1',
  'ZTicket-Parent' => '1'
};
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'FollowUpDynamicField'} =  {};
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'HideActivatedActivityDialogButton'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'HistoryComment'} =  '';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'HistoryType'} =  'FollowUp';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'NextScreenAfterFollowUp'} =  'CustomerTicketOverview';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'Priority'} =  '1';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'PriorityDefault'} =  '3 normal';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'SenderType'} =  'customer';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'State'} =  '1';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'StateDefault'} =  'open';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'StatePreset'} =  'open';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'StateType'} =  [
  'open',
  'closed'
];
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'TicketInfoDisplayType'} =  'Permanent';
$Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'ZoomTimeDisplay'} =  '0';
$Self->{'Ticket::Frontend::CustomerTicketZTSMAction'} =  {
  'Actions' => {
    'Approve' => {
      'Label' => 'Approve',
      'State' => 'closed successful',
      'Types' => [
        'Approval'
      ]
    },
    'Assess' => {
      'Label' => 'Assess',
      'State' => 'closed successful',
      'Types' => [
        'Assessment'
      ]
    },
    'Endorse' => {
      'Label' => 'Endorse',
      'State' => 'closed successful',
      'Types' => [
        'Endorsement'
      ]
    },
    'Reject' => {
      'Label' => 'Reject',
      'State' => 'closed rejected',
      'Types' => [
        'Approval',
        'Assessment',
        'Endorsement'
      ]
    }
  },
  'AssessmentFields' => [
    'ZTicket-TechnicalRisk',
    'ZTicket-BusinessRisk',
    'ZTicket-GovernanceRisk'
  ],
  'Article' => '1',
  'ContentType' => 'text/plain; charset=utf-8',
  'HistoryComment' => '%%',
  'HistoryType' => 'AddNote',
  'IsVisibleForCustomer' => '1',
  'Permission' => 'ztsm_action',
  'SenderType' => 'customer'
};
$Self->{'Ticket::Frontend::DefaultQuickDateButtons'} =  [
  {
    '+1 day' => '+1'
  },
  {
    '+1 week' => '+7'
  }
];
$Self->{'Ticket::Frontend::DefaultRecipientDisplayType'} =  'Realname';
$Self->{'Ticket::Frontend::DefaultSenderDisplayType'} =  'Realname';
$Self->{'Ticket::Frontend::DynamicFieldsZoomMaxSizeArticle'} =  '160';
$Self->{'Ticket::Frontend::DynamicFieldsZoomMaxSizeSidebar'} =  '40';
$Self->{'Ticket::Frontend::HTMLArticleHeightDefault'} =  '100';
$Self->{'Ticket::Frontend::HTMLArticleHeightMax'} =  '2500';
$Self->{'Ticket::Frontend::HistoryOrder'} =  'normal';
$Self->{'Ticket::Frontend::HistoryTypes'}->{'000-Framework'} =  {
  'AddNote' => 'Added note (%s).',
  'ArchiveFlagUpdate' => 'Changed archive state to "%s".',
  'ArticleDelete' => 'Article ID: %s was deleted by "%s" (%s)',
  'ArticleDynamicFieldUpdate' => 'Changed dynamic field %s from "%s" to "%s".',
  'ArticleEdit' => 'Article ID: %s was edited by "%s" (%s)',
  'ArticleRestore' => 'Article ID: %s was restored by "%s" (%s)',
  'Bounce' => 'Bounced to "%s".',
  'CustomerUpdate' => 'Changed customer to "%s".',
  'EmailAgent' => 'Sent email to customer.',
  'EmailCustomer' => 'Added email. %s',
  'EmailResend' => 'Resent email to "%s".',
  'EscalationResponseTimeNotifyBefore' => 'Notified about response time escalation.',
  'EscalationResponseTimeStart' => 'Started response time escalation.',
  'EscalationResponseTimeStop' => 'Stopped response time escalation.',
  'EscalationSolutionTimeNotifyBefore' => 'Notified about solution time escalation.',
  'EscalationSolutionTimeStart' => 'Started solution time escalation.',
  'EscalationSolutionTimeStop' => 'Stopped solution time escalation.',
  'EscalationUpdateTimeNotifyBefore' => 'Notified about update time escalation.',
  'EscalationUpdateTimeStart' => 'Started update time escalation.',
  'EscalationUpdateTimeStop' => 'Stopped update time escalation.',
  'FollowUp' => 'Added follow-up to ticket [%s]. %s',
  'Forward' => 'Forwarded to "%s".',
  'Lock' => 'Locked ticket.',
  'LoopProtection' => 'Loop protection: no auto-response sent to "%s".',
  'Merged' => 'Merged Ticket (%s/%s) to (%s/%s).',
  'Misc' => '%s',
  'Move' => 'Changed queue to "%s" (%s) from "%s" (%s).',
  'NewTicket' => 'Created ticket [%s] in "%s" with priority "%s" and state "%s".',
  'OwnerUpdate' => 'Changed owner to "%s" (%s).',
  'PhoneCallAgent' => 'Added phone call to customer.',
  'PhoneCallCustomer' => 'Added phone call from customer.',
  'PriorityUpdate' => 'Changed priority from "%s" (%s) to "%s" (%s).',
  'Remove' => '%s',
  'ResponsibleUpdate' => 'Changed responsible to "%s" (%s).',
  'SLAUpdate' => 'Changed SLA to "%s" (%s).',
  'SendAgentNotification' => 'Sent "%s" notification to "%s" via "%s".',
  'SendAnswer' => 'Sent email to "%s".',
  'SendAutoFollowUp' => 'Sent auto follow-up to "%s".',
  'SendAutoReject' => 'Sent auto reject to "%s".',
  'SendAutoReply' => 'Sent auto reply to "%s".',
  'SendCustomerNotification' => 'Sent notification to "%s".',
  'ServiceUpdate' => 'Changed service to "%s" (%s).',
  'SetPendingTime' => 'Changed pending time to "%s".',
  'StateUpdate' => 'Changed state from "%s" to "%s".',
  'Subscribe' => 'Added subscription for user "%s".',
  'SystemRequest' => 'Added system request (%s).',
  'TicketDynamicFieldUpdate' => 'Changed dynamic field %s from "%s" to "%s".',
  'TicketLinkAdd' => 'Added link to ticket "%s".',
  'TicketLinkDelete' => 'Deleted link to ticket "%s".',
  'TimeAccounting' => 'Added %s time unit(s), for a total of %s time unit(s).',
  'TitleUpdate' => 'Changed title from "%s" to "%s".',
  'TypeUpdate' => 'Changed type from "%s" (%s) to "%s" (%s).',
  'Unlock' => 'Unlocked ticket.',
  'Unsubscribe' => 'Removed subscription for user "%s".',
  'WebRequestCustomer' => 'Added web request from customer.'
};
$Self->{'Ticket::Frontend::InformAgentMaxSize'} =  '3';
$Self->{'Ticket::Frontend::InvolvedAgentMaxSize'} =  '3';
$Self->{'Ticket::Frontend::ListType'} =  'tree';
$Self->{'Ticket::Frontend::MaxArticlesPerPage'} =  '1000';
$Self->{'Ticket::Frontend::MaxArticlesZoomExpand'} =  '400';
$Self->{'Ticket::Frontend::MaxQueueLevel'} =  '5';
$Self->{'Ticket::Frontend::MenuModule'}->{'000-Back'} =  {
  'Action' => '',
  'ClusterName' => '',
  'ClusterPriority' => '',
  'Description' => 'Go back',
  'Link' => '[% Env("LastScreenOverview") %];TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Back',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'001-DownloadAllAttachments'} =  {
  'Action' => '',
  'ClusterName' => 'Miscellaneous',
  'ClusterPriority' => '999',
  'Description' => 'Download all attachments as one zip file',
  'Module' => 'Kernel::Output::HTML::TicketMenu::DownloadAllAttachments',
  'Name' => 'Download ticket attachments',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'001-MarkTicketUnseen'} =  {
  'Action' => '',
  'ClusterName' => 'Mark as (un)seen',
  'ClusterPriority' => '101',
  'Description' => 'Mark ticket as unseen',
  'Link' => 'Action=AgentTicketMarkSeenUnseen;Subaction=Unseen;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Mark as unseen',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'002-MarkTicketSeen'} =  {
  'Action' => '',
  'ClusterName' => 'Mark as (un)seen',
  'ClusterPriority' => '101',
  'Description' => 'Mark ticket as seen',
  'Link' => 'Action=AgentTicketMarkSeenUnseen;Subaction=Seen;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Mark as seen',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'100-Lock'} =  {
  'Action' => 'AgentTicketLock',
  'ClusterName' => '',
  'ClusterPriority' => '1',
  'Description' => 'Lock / unlock this ticket',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Lock',
  'Name' => 'Lock',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'200-History'} =  {
  'Action' => 'AgentTicketHistory',
  'ClusterName' => 'Miscellaneous',
  'ClusterPriority' => '800',
  'Description' => 'Show the history for this ticket',
  'Link' => 'Action=AgentTicketHistory;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'History',
  'PopupType' => 'TicketHistory',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'210-Print'} =  {
  'Action' => 'AgentTicketPrint',
  'ClusterName' => 'Miscellaneous',
  'ClusterPriority' => '800',
  'Description' => 'Print this ticket',
  'Link' => 'Action=AgentTicketPrint;TicketID=[% Data.TicketID | html %]',
  'LinkParam' => 'target="print"',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Print',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'300-Priority'} =  {
  'Action' => 'AgentTicketPriority',
  'ClusterName' => '',
  'ClusterPriority' => '',
  'Description' => 'Change the priority for this ticket',
  'Link' => 'Action=AgentTicketPriority;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Priority',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'310-FreeText'} =  {
  'Action' => 'AgentTicketFreeText',
  'ClusterName' => '',
  'ClusterPriority' => '100',
  'Description' => 'Change Ticket information',
  'Link' => 'Action=AgentTicketFreeText;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Change Ticket',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'315-AddtlITSMField'} =  {
  'Action' => 'AgentTicketAddtlITSMField',
  'Description' => 'Change the ITSM fields!',
  'Link' => 'Action=AgentTicketAddtlITSMField;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Additional ITSM Fields',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'317-ITSMChangeAdd'} =  {
  'Action' => 'AgentITSMChangeAdd',
  'Description' => 'Create a change from this ticket.',
  'Link' => 'Action=AgentITSMChangeAdd;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::ITSMChange',
  'Name' => 'Create Change'
};
$Self->{'Ticket::Frontend::MenuModule'}->{'320-Link'} =  {
  'Action' => 'AgentLinkObject',
  'ClusterName' => 'Miscellaneous',
  'ClusterPriority' => '800',
  'Description' => 'Link this ticket to other objects',
  'Link' => 'Action=AgentLinkObject;SourceObject=Ticket;SourceKey=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Link',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'400-Owner'} =  {
  'Action' => 'AgentTicketOwner',
  'ClusterName' => 'People',
  'ClusterPriority' => '430',
  'Description' => 'Change the owner for this ticket',
  'Link' => 'Action=AgentTicketOwner;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Owner',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'410-Responsible'} =  {
  'Action' => 'AgentTicketResponsible',
  'ClusterName' => 'People',
  'ClusterPriority' => '430',
  'Description' => 'Change the responsible for this ticket',
  'Link' => 'Action=AgentTicketResponsible;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Responsible',
  'Name' => 'Responsible',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'420-Customer'} =  {
  'Action' => 'AgentTicketCustomer',
  'ClusterName' => 'People',
  'ClusterPriority' => '430',
  'Description' => 'Change the customer for this ticket',
  'Link' => 'Action=AgentTicketCustomer;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Customer',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'420-Decision'} =  {
  'Action' => 'AgentTicketDecision',
  'Description' => 'Add a decision!',
  'Link' => 'Action=AgentTicketDecision;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Decision',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'421-Note'} =  {
  'Action' => 'AgentTicketNote',
  'ClusterName' => 'Communication',
  'ClusterPriority' => '435',
  'Description' => 'Add a note to this ticket',
  'Link' => 'Action=AgentTicketNote;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Note',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'425-Phone Call Outbound'} =  {
  'Action' => 'AgentTicketPhoneOutbound',
  'ClusterName' => 'Communication',
  'ClusterPriority' => '435',
  'Description' => 'Add an outbound phone call to this ticket',
  'Link' => 'Action=AgentTicketPhoneOutbound;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Phone Call Outbound',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'426-Phone Call Inbound'} =  {
  'Action' => 'AgentTicketPhoneInbound',
  'ClusterName' => 'Communication',
  'ClusterPriority' => '435',
  'Description' => 'Add an inbound phone call to this ticket',
  'Link' => 'Action=AgentTicketPhoneInbound;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Phone Call Inbound',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'427-Email Outbound'} =  {
  'Action' => 'AgentTicketEmailOutbound',
  'ClusterName' => 'Communication',
  'ClusterPriority' => '435',
  'Description' => 'Send new outgoing mail from this ticket',
  'Link' => 'Action=AgentTicketEmailOutbound;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'E-Mail Outbound',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'430-Merge'} =  {
  'Action' => 'AgentTicketMerge',
  'ClusterName' => 'Miscellaneous',
  'ClusterPriority' => '800',
  'Description' => 'Merge this ticket and all articles into another ticket',
  'Link' => 'Action=AgentTicketMerge;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Merge',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'440-Pending'} =  {
  'Action' => 'AgentTicketPending',
  'ClusterName' => '',
  'ClusterPriority' => '',
  'Description' => 'Set this ticket to pending',
  'Link' => 'Action=AgentTicketPending;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Pending',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'448-Watch'} =  {
  'Action' => 'AgentTicketWatcher',
  'ClusterName' => '',
  'ClusterPriority' => '',
  'Description' => 'Watch this ticket',
  'Module' => 'Kernel::Output::HTML::TicketMenu::TicketWatcher',
  'Name' => 'Watch',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'450-Close'} =  {
  'Action' => 'AgentTicketClose',
  'ClusterName' => '',
  'ClusterPriority' => '',
  'Description' => 'Close this ticket',
  'Link' => 'Action=AgentTicketClose;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Close',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'451-QuickClose'} =  {
  'Action' => 'AgentTicketQuickClose',
  'Description' => 'Close this ticket',
  'Link' => 'Action=AgentTicketQuickClose;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Quick Close',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'480-MasterSlave'} =  {
  'Action' => 'AgentTicketMasterSlave',
  'Description' => 'Change the MasterSlave state of the ticket.',
  'Link' => 'Action=AgentTicketMasterSlave;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'MasterSlave',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'480-Process'} =  {
  'Action' => 'AgentTicketProcess',
  'Cluster' => '',
  'Description' => 'Enroll process for this ticket',
  'Link' => 'Action=AgentTicketProcess;IsProcessEnroll=1;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Process',
  'Name' => 'Process',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'550-Appointment'} =  {
  'Action' => 'AgentAppointmentCalendarOverview',
  'ClusterName' => 'Miscellaneous',
  'ClusterPriority' => '800',
  'Description' => 'Create a new calendar appointment linked to this ticket',
  'Link' => 'Action=AgentAppointmentCalendarOverview;Subaction=AppointmentCreate;PluginKey=0100-Ticket;ObjectID=[% Data.TicketID | uri %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'New Appointment',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'600-AgentTicketAccountTime'} =  {
  'Action' => 'AgentTicketAccountTime',
  'ClusterName' => 'Miscellaneous',
  'ClusterPriority' => '900',
  'Description' => 'Create a new time accounting entry related to the ticket',
  'Link' => 'Action=AgentTicketAccountTime;PluginKey=0100-Ticket;TicketID=[% Data.TicketID | uri %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Time Accounting',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'601-AgentTimeAccountingReportingTicket'} =  {
  'Action' => 'AgentTimeAccountingReportingTicket',
  'ClusterName' => 'Miscellaneous',
  'ClusterPriority' => '901',
  'Description' => 'Show accounted times for this ticket',
  'Link' => 'Action=AgentTimeAccountingReportingTicket;TicketID=[% Data.TicketID | uri %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Time Report',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MenuModule'}->{'9000-ShowHideDeletedArticles'} =  {
  'Action' => 'AgentTicketArticleStatus',
  'ClusterName' => '',
  'ClusterPriority' => '9000',
  'Description' => 'Show or Hide deleted articles.',
  'Module' => 'Kernel::Output::HTML::TicketMenu::ShowHideDeletedArticles',
  'Name' => 'ShowHideDeletedArticles',
  'Target' => ''
};
$Self->{'Ticket::Frontend::MergeText'} =  'Your email with ticket number "<OTOBO_TICKET>" is merged to "<OTOBO_MERGE_TO_TICKET>".';
$Self->{'Ticket::Frontend::MoveType'} =  'form';
$Self->{'Ticket::Frontend::MoveType::Dropdown::MoveEvenIfLocked'} =  '0';
$Self->{'Ticket::Frontend::NeedAccountedTime'} =  '0';
$Self->{'Ticket::Frontend::NewOwnerSelection'} =  '1';
$Self->{'Ticket::Frontend::NewQueueSelectionString'} =  '<Queue>';
$Self->{'Ticket::Frontend::NewQueueSelectionType'} =  'Queue';
$Self->{'Ticket::Frontend::NewResponsibleSelection'} =  '1';
$Self->{'Ticket::Frontend::Overview'}->{'Medium'} =  {
  'CustomerInfo' => '0',
  'Module' => 'Kernel::Output::HTML::TicketOverview::Medium',
  'ModulePriority' => '200',
  'Name' => 'Medium',
  'NameShort' => 'M',
  'OverviewMenuModules' => '1',
  'TicketActionsPerTicket' => '1'
};
$Self->{'Ticket::Frontend::Overview'}->{'Preview'} =  {
  'CustomerInfo' => '0',
  'CustomerInfoMaxSize' => '18',
  'DefaultPreViewLines' => '25',
  'DefaultViewNewLine' => '90',
  'Module' => 'Kernel::Output::HTML::TicketOverview::Preview',
  'ModulePriority' => '300',
  'Name' => 'Large',
  'NameShort' => 'L',
  'OverviewMenuModules' => '1',
  'StripEmptyLines' => '0',
  'TicketActionsPerTicket' => '1'
};
$Self->{'Ticket::Frontend::Overview'}->{'Small'} =  {
  'CustomerInfo' => '1',
  'Module' => 'Kernel::Output::HTML::TicketOverview::Small',
  'ModulePriority' => '100',
  'Name' => 'Small',
  'NameShort' => 'S'
};
$Self->{'Ticket::Frontend::Overview::PreviewArticleLimit'} =  '5';
$Self->{'Ticket::Frontend::OverviewMedium'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::OverviewMenuModule'}->{'001-Sort'} =  {
  'Module' => 'Kernel::Output::HTML::TicketOverviewMenu::Sort'
};
$Self->{'Ticket::Frontend::OverviewPreview'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::OverviewSmall'}->{'DynamicField'} =  {};
$Self->{'Ticket::Frontend::PendingDiffTime'} =  '86400';
$Self->{'Ticket::Frontend::PlainView'} =  '0';
$Self->{'Ticket::Frontend::PreMenuModule'}->{'100-Lock'} =  {
  'Action' => 'AgentTicketLock',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Lock',
  'Name' => 'Lock',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'200-Zoom'} =  {
  'Action' => 'AgentTicketZoom',
  'Description' => 'Look into a ticket!',
  'Link' => 'Action=AgentTicketZoom;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Zoom',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'210-History'} =  {
  'Action' => 'AgentTicketHistory',
  'Description' => 'Show the ticket history',
  'Link' => 'Action=AgentTicketHistory;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'History',
  'PopupType' => 'TicketHistory',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'300-Priority'} =  {
  'Action' => 'AgentTicketPriority',
  'Description' => 'Change the priority for this ticket',
  'Link' => 'Action=AgentTicketPriority;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Priority',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'420-Note'} =  {
  'Action' => 'AgentTicketNote',
  'Description' => 'Add a note to this ticket',
  'Link' => 'Action=AgentTicketNote;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Note',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'440-Close'} =  {
  'Action' => 'AgentTicketClose',
  'Description' => 'Close this ticket',
  'Link' => 'Action=AgentTicketClose;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Close',
  'PopupType' => 'TicketAction',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'441-QuickClose'} =  {
  'Action' => 'AgentTicketQuickClose',
  'Description' => 'Close this ticket',
  'Link' => 'Action=AgentTicketQuickClose;TicketID=[% Data.TicketID | html %]',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Quick Close',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'442-MarkTicketSeen'} =  {
  'Action' => '',
  'Description' => 'Mark ticket as seen',
  'Link' => 'Action=AgentTicketMarkSeenUnseen;Subaction=Seen;TicketID=[% Data.TicketID | html %];RedirectToSearch=1;',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Mark as seen',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'442-MarkTicketUnseen'} =  {
  'Action' => '',
  'Description' => 'Mark ticket as unseen',
  'Link' => 'Action=AgentTicketMarkSeenUnseen;Subaction=Unseen;TicketID=[% Data.TicketID | html %];RedirectToSearch=1;',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Generic',
  'Name' => 'Mark as unseen',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'445-Move'} =  {
  'Action' => 'AgentTicketMove',
  'Description' => 'Change queue!',
  'Module' => 'Kernel::Output::HTML::TicketMenu::Move',
  'Name' => 'Move'
};
$Self->{'Ticket::Frontend::PreMenuModule'}->{'990-DownloadAllAttachments'} =  {
  'Action' => 'DownloadAllAttachments',
  'Description' => 'Download all attachments as one zip file',
  'Module' => 'Kernel::Output::HTML::TicketMenu::DownloadAllAttachments',
  'Name' => 'Download ticket attachments',
  'PopupType' => '',
  'Target' => ''
};
$Self->{'Ticket::Frontend::Quote'} =  '>';
$Self->{'Ticket::Frontend::RedirectAfterCloseDisabled'} =  '0';
$Self->{'Ticket::Frontend::ResponseFormat'} =  '[% Data.Salutation | html %]
[% Data.StdResponse | html %]
[% Data.Signature | html %]

[% Data.CreateTime | Localize("TimeShort") %] - [% Data.OrigFromName | html %] [% Translate("wrote") | html %]:
[% Data.Body | html %]
';
$Self->{'Ticket::Frontend::SeparateDynamicFields'} =  {
  'TitleCategory' => '0',
  'TitleDynamicFields' => '0',
  'TitleMessage' => '0'
};
$Self->{'Ticket::Frontend::ShowCustomerTickets'} =  '1';
$Self->{'Ticket::Frontend::TextAreaEmail'} =  '82';
$Self->{'Ticket::Frontend::TextAreaNote'} =  '78';
$Self->{'Ticket::Frontend::TicketArticleFilter'} =  '1';
$Self->{'Ticket::Frontend::TimeUnits'} =  ' (work units)';
$Self->{'Ticket::Frontend::ZoomCollectMeta'} =  '0';
$Self->{'Ticket::Frontend::ZoomCustomerTickets'} =  '0';
$Self->{'Ticket::Frontend::ZoomExpandSort'} =  'reverse';
$Self->{'Ticket::Frontend::ZoomRichTextForce'} =  '1';
$Self->{'Ticket::GenericAgentAllowCustomModuleExecution'} =  '1';
$Self->{'Ticket::GenericAgentRunLimit'} =  '50000';
$Self->{'Ticket::GenericAgentTicketSearch'}->{'ExtendedSearchCondition'} =  '1';
$Self->{'Ticket::Hook'} =  'Ticket#';
$Self->{'Ticket::HookDivider'} =  '';
$Self->{'Ticket::IncludeUnknownTicketCustomers'} =  '0';
$Self->{'Ticket::IndexModule'} =  'Kernel::System::Ticket::IndexAccelerator::RuntimeDB';
$Self->{'Ticket::InvalidOwner::StateChange'} =  {
  'pending auto' => 'open',
  'pending reminder' => 'open'
};
$Self->{'Ticket::MergeDynamicFields'} =  [];
$Self->{'Ticket::NewArticleIgnoreSystemSender'} =  '0';
$Self->{'Ticket::NumberGenerator'} =  'Kernel::System::Ticket::Number::DateChecksum';
$Self->{'Ticket::NumberGenerator::CheckSystemID'} =  '1';
$Self->{'Ticket::NumberGenerator::Date::UseFormattedCounter'} =  '0';
$Self->{'Ticket::NumberGenerator::MinCounterSize'} =  '5';
$Self->{'Ticket::OwnerResetOnUnlock'} =  '1';
$Self->{'Ticket::PendingAutoStateType'} =  [
  'pending auto'
];
$Self->{'Ticket::PendingNotificationNotToResponsible'} =  '0';
$Self->{'Ticket::PendingNotificationOnlyToOwner'} =  '0';
$Self->{'Ticket::PendingReminderStateType'} =  [
  'pending reminder'
];
$Self->{'Ticket::Permission'}->{'1-OwnerCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::Ticket::Permission::OwnerCheck',
  'Required' => '0'
};
$Self->{'Ticket::Permission'}->{'2-ResponsibleCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::Ticket::Permission::ResponsibleCheck',
  'Required' => '0'
};
$Self->{'Ticket::Permission'}->{'3-GroupCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::Ticket::Permission::GroupCheck',
  'Required' => '0'
};
$Self->{'Ticket::Permission'}->{'4-WatcherCheck'} =  {
  'Granted' => '1',
  'Module' => 'Kernel::System::Ticket::Permission::WatcherCheck',
  'Required' => '0'
};
$Self->{'Ticket::Responsible'} =  '1';
$Self->{'Ticket::ResponsibleAutoSet'} =  '1';
$Self->{'Ticket::SearchIndex::Attribute'} =  {
  'WordCountMax' => '1000',
  'WordLengthMax' => '30',
  'WordLengthMin' => '3'
};
$Self->{'Ticket::SearchIndex::Filters'} =  [
  '[,\\&\\<\\>\\?"\\!\\*\\|;\\[\\]\\(\\)\\+\\$\\^=]',
  '^[\':.]|[\':.]$',
  '^[^\\w]+$'
];
$Self->{'Ticket::SearchIndex::ForceUnfilteredStorage'} =  '0';
$Self->{'Ticket::SearchIndex::IndexArchivedTickets'} =  '0';
$Self->{'Ticket::SearchIndex::StopWords'}->{'de'} =  [
  'aber',
  'als',
  'am',
  'an',
  'auch',
  'auf',
  'aus',
  'bei',
  'bin',
  'bis',
  'bist',
  'da',
  'dadurch',
  'daher',
  'darum',
  'das',
  'daß',
  'dass',
  'dein',
  'deine',
  'dem',
  'den',
  'der',
  'des',
  'dessen',
  'deshalb',
  'die',
  'dies',
  'dieser',
  'dieses',
  'doch',
  'dort',
  'du',
  'durch',
  'ein',
  'eine',
  'einem',
  'einen',
  'einer',
  'eines',
  'er',
  'es',
  'euer',
  'eure',
  'für',
  'hatte',
  'hatten',
  'hattest',
  'hattet',
  'hier',
  'hinter',
  'ich',
  'ihr',
  'ihre',
  'im',
  'in',
  'ist',
  'ja',
  'jede',
  'jedem',
  'jeden',
  'jeder',
  'jedes',
  'jener',
  'jenes',
  'jetzt',
  'kann',
  'kannst',
  'können',
  'könnt',
  'machen',
  'mein',
  'meine',
  'mit',
  'muß',
  'mußt',
  'musst',
  'müssen',
  'müßt',
  'nach',
  'nachdem',
  'nein',
  'nicht',
  'nun',
  'oder',
  'seid',
  'sein',
  'seine',
  'sich',
  'sie',
  'sind',
  'soll',
  'sollen',
  'sollst',
  'sollt',
  'sonst',
  'soweit',
  'sowie',
  'und',
  'unser',
  'unsere',
  'unter',
  'vom',
  'von',
  'vor',
  'wann',
  'warum',
  'was',
  'weiter',
  'weitere',
  'wenn',
  'wer',
  'werde',
  'werden',
  'werdet',
  'weshalb',
  'wie',
  'wieder',
  'wieso',
  'wir',
  'wird',
  'wirst',
  'wo',
  'woher',
  'wohin',
  'zu',
  'zum',
  'zur',
  'über'
];
$Self->{'Ticket::SearchIndex::StopWords'}->{'en'} =  [
  'a',
  'about',
  'above',
  'after',
  'again',
  'against',
  'all',
  'am',
  'an',
  'and',
  'any',
  'are',
  'aren\'t',
  'as',
  'at',
  'be',
  'because',
  'been',
  'before',
  'being',
  'below',
  'between',
  'both',
  'but',
  'by',
  'can\'t',
  'cannot',
  'could',
  'couldn\'t',
  'did',
  'didn\'t',
  'do',
  'does',
  'doesn\'t',
  'doing',
  'don\'t',
  'down',
  'during',
  'each',
  'few',
  'for',
  'from',
  'further',
  'had',
  'hadn\'t',
  'has',
  'hasn\'t',
  'have',
  'haven\'t',
  'having',
  'he',
  'he\'d',
  'he\'ll',
  'he\'s',
  'her',
  'here',
  'here\'s',
  'hers',
  'herself',
  'him',
  'himself',
  'his',
  'how',
  'how\'s',
  'i',
  'i\'d',
  'i\'ll',
  'i\'m',
  'i\'ve',
  'if',
  'in',
  'into',
  'is',
  'isn\'t',
  'it',
  'it\'s',
  'its',
  'itself',
  'let\'s',
  'me',
  'more',
  'most',
  'mustn\'t',
  'my',
  'myself',
  'no',
  'nor',
  'not',
  'of',
  'off',
  'on',
  'once',
  'only',
  'or',
  'other',
  'ought',
  'our',
  'ours',
  'ourselves',
  'out',
  'over',
  'own',
  'same',
  'shan\'t',
  'she',
  'she\'d',
  'she\'ll',
  'she\'s',
  'should',
  'shouldn\'t',
  'so',
  'some',
  'such',
  'than',
  'that',
  'that\'s',
  'the',
  'their',
  'theirs',
  'them',
  'themselves',
  'then',
  'there',
  'there\'s',
  'these',
  'they',
  'they\'d',
  'they\'ll',
  'they\'re',
  'they\'ve',
  'this',
  'those',
  'through',
  'to',
  'too',
  'under',
  'until',
  'up',
  'very',
  'was',
  'wasn\'t',
  'we',
  'we\'d',
  'we\'ll',
  'we\'re',
  'we\'ve',
  'were',
  'weren\'t',
  'what',
  'what\'s',
  'when',
  'when\'s',
  'where',
  'where\'s',
  'which',
  'while',
  'who',
  'who\'s',
  'whom',
  'why',
  'why\'s',
  'with',
  'won\'t',
  'would',
  'wouldn\'t',
  'you',
  'you\'d',
  'you\'ll',
  'you\'re',
  'you\'ve',
  'your',
  'yours',
  'yourself',
  'yourselves'
];
$Self->{'Ticket::SearchIndex::StopWords'}->{'es'} =  [
  'un',
  'una',
  'unas',
  'unos',
  'uno',
  'sobre',
  'todo',
  'también',
  'tras',
  'otro',
  'algún',
  'alguno',
  'alguna',
  'algunos',
  'algunas',
  'ser',
  'es',
  'soy',
  'eres',
  'somos',
  'sois',
  'estoy',
  'esta',
  'estamos',
  'estais',
  'estan',
  'como',
  'en',
  'para',
  'atras',
  'porque',
  'por qué',
  'estado',
  'estaba',
  'ante',
  'antes',
  'siendo',
  'ambos',
  'pero',
  'por',
  'poder',
  'puede',
  'puedo',
  'podemos',
  'podeis',
  'pueden',
  'fui',
  'fue',
  'fuimos',
  'fueron',
  'hacer',
  'hago',
  'hace',
  'hacemos',
  'haceis',
  'hacen',
  'cada',
  'fin',
  'incluso',
  'primero',
  'desde',
  'conseguir',
  'consigo',
  'consigue',
  'consigues',
  'conseguimos',
  'consiguen',
  'ir',
  'voy',
  'va',
  'vamos',
  'vais',
  'van',
  'vaya',
  'gueno',
  'ha',
  'tener',
  'tengo',
  'tiene',
  'tenemos',
  'teneis',
  'tienen',
  'el',
  'la',
  'lo',
  'las',
  'los',
  'su',
  'aqui',
  'mio',
  'tuyo',
  'ellos',
  'ellas',
  'nos',
  'nosotros',
  'vosotros',
  'vosotras',
  'si',
  'dentro',
  'solo',
  'solamente',
  'saber',
  'sabes',
  'sabe',
  'sabemos',
  'sabeis',
  'saben',
  'ultimo',
  'largo',
  'bastante',
  'haces',
  'muchos',
  'aquellos',
  'aquellas',
  'sus',
  'entonces',
  'tiempo',
  'verdad',
  'verdadero',
  'verdadera',
  'cierto',
  'ciertos',
  'cierta',
  'ciertas',
  'intentar',
  'intento',
  'intenta',
  'intentas',
  'intentamos',
  'intentais',
  'intentan',
  'dos',
  'bajo',
  'arriba',
  'encima',
  'usar',
  'uso',
  'usas',
  'usa',
  'usamos',
  'usais',
  'usan',
  'emplear',
  'empleo',
  'empleas',
  'emplean',
  'ampleamos',
  'empleais',
  'valor',
  'muy',
  'era',
  'eras',
  'eramos',
  'eran',
  'modo',
  'bien',
  'cual',
  'cuando',
  'donde',
  'mientras',
  'quien',
  'con',
  'entre',
  'sin',
  'trabajo',
  'trabajar',
  'trabajas',
  'trabaja',
  'trabajamos',
  'trabajais',
  'trabajan',
  'podria',
  'podrias',
  'podriamos',
  'podrian',
  'podriais',
  'yo',
  'aquel'
];
$Self->{'Ticket::SearchIndex::StopWords'}->{'fr'} =  [
  'alors',
  'au',
  'aucuns',
  'aussi',
  'autre',
  'avant',
  'avec',
  'avoir',
  'bon',
  'car',
  'ce',
  'cela',
  'ces',
  'ceux',
  'chaque',
  'ci',
  'comme',
  'comment',
  'dans',
  'des',
  'du',
  'dedans',
  'dehors',
  'depuis',
  'deux',
  'devrait',
  'doit',
  'donc',
  'dos',
  'droite',
  'début',
  'elle',
  'elles',
  'en',
  'encore',
  'essai',
  'est',
  'et',
  'eu',
  'fait',
  'faites',
  'fois',
  'font',
  'force',
  'haut',
  'hors',
  'ici',
  'il',
  'ils',
  'je',
  'juste',
  'la',
  'le',
  'les',
  'leur',
  'là',
  'ma',
  'maintenant',
  'mais',
  'mes',
  'mine',
  'moins',
  'mon',
  'mot',
  'même',
  'ni',
  'nommés',
  'notre',
  'nous',
  'nouveaux',
  'ou',
  'où',
  'par',
  'parce',
  'parole',
  'pas',
  'personnes',
  'peut',
  'peu',
  'pièce',
  'plupart',
  'pour',
  'pourquoi',
  'quand',
  'que',
  'quel',
  'quelle',
  'quelles',
  'quels',
  'qui',
  'sa',
  'sans',
  'ses',
  'seulement',
  'si',
  'sien',
  'son',
  'sont',
  'sous',
  'soyez',
  'sujet',
  'sur',
  'ta',
  'tandis',
  'tellement',
  'tels',
  'tes',
  'ton',
  'tous',
  'tout',
  'trop',
  'très',
  'tu',
  'valeur',
  'voie',
  'voient',
  'vont',
  'votre',
  'vous',
  'vu',
  'ça',
  'étaient',
  'état',
  'étions',
  'été',
  'être'
];
$Self->{'Ticket::SearchIndex::StopWords'}->{'it'} =  [
  'a',
  'adesso',
  'ai',
  'al',
  'alla',
  'allo',
  'allora',
  'altre',
  'altri',
  'altro',
  'anche',
  'ancora',
  'avere',
  'aveva',
  'avevano',
  'ben',
  'buono',
  'che',
  'chi',
  'cinque',
  'comprare',
  'con',
  'consecutivi',
  'consecutivo',
  'cosa',
  'cui',
  'da',
  'del',
  'della',
  'dello',
  'dentro',
  'deve',
  'devo',
  'di',
  'doppio',
  'due',
  'e',
  'ecco',
  'fare',
  'fine',
  'fino',
  'fra',
  'gente',
  'giu',
  'ha',
  'hai',
  'hanno',
  'ho',
  'il',
  'indietro',
  'invece',
  'io',
  'la',
  'lavoro',
  'le',
  'lei',
  'lo',
  'loro',
  'lui',
  'lungo',
  'ma',
  'me',
  'meglio',
  'molta',
  'molti',
  'molto',
  'nei',
  'nella',
  'no',
  'noi',
  'nome',
  'nostro',
  'nove',
  'nuovi',
  'nuovo',
  'o',
  'oltre',
  'ora',
  'otto',
  'peggio',
  'pero',
  'persone',
  'piu',
  'poco',
  'primo',
  'promesso',
  'qua',
  'quarto',
  'quasi',
  'quattro',
  'quello',
  'questo',
  'qui',
  'quindi',
  'quinto',
  'rispetto',
  'sara',
  'secondo',
  'sei',
  'sembra',
  'sembrava',
  'senza',
  'sette',
  'sia',
  'siamo',
  'siete',
  'solo',
  'sono',
  'sopra',
  'soprattutto',
  'sotto',
  'stati',
  'stato',
  'stesso',
  'su',
  'subito',
  'sul',
  'sulla',
  'tanto',
  'te',
  'tempo',
  'terzo',
  'tra',
  'tre',
  'triplo',
  'ultimo',
  'un',
  'una',
  'uno',
  'va',
  'vai',
  'voi',
  'volte',
  'vostro'
];
$Self->{'Ticket::SearchIndex::StopWords'}->{'nl'} =  [
  'de',
  'zijn',
  'een',
  'en',
  'in',
  'je',
  'het',
  'van',
  'op',
  'ze',
  'hebben',
  'het',
  'hij',
  'niet',
  'met',
  'er',
  'dat',
  'die',
  'te',
  'wat',
  'voor',
  'naar',
  'gaan',
  'kunnen',
  'zeggen',
  'dat',
  'maar',
  'aan',
  'veel',
  'zijn',
  'worden',
  'uit',
  'ook',
  'komen',
  'als',
  'om',
  'moeten',
  'we',
  'doen',
  'bij',
  'goed',
  'haar',
  'dan',
  'nog',
  'of',
  'maken',
  'zo',
  'wel',
  'mijn',
  'zien',
  'over',
  'willen',
  'staan',
  'door',
  'kijken',
  'zullen',
  'heel',
  'nu',
  'weten',
  'zitten',
  'hem',
  'schrijven',
  'vinden',
  'woord',
  'hoe',
  'geen',
  'dit',
  'mens',
  'al',
  'jij',
  'ander',
  'groot',
  'waar',
  'maar',
  'weer',
  'kind',
  'me',
  'vragen',
  'een',
  'denken',
  'twee',
  'horen',
  'iets',
  'deze',
  'krijgen',
  'ons',
  'zich',
  'lezen',
  'hun',
  'welk',
  'zin',
  'laten',
  'mogen',
  'hier',
  'jullie',
  'toch',
  'geven',
  'jaar',
  'tegen',
  'al',
  'eens',
  'echt',
  'houden',
  'alleen',
  'lopen',
  'mee',
  'ja',
  'roepen',
  'tijd',
  'dag',
  'elkaar',
  'even',
  'lang',
  'land',
  'liggen',
  'waarom',
  'zetten',
  'vader',
  'laat',
  'beginnen',
  'blijven',
  'nee',
  'moeder',
  'huis',
  'nou',
  'na',
  'af',
  'keer',
  'dus',
  'tot',
  'vertellen',
  'wie',
  'net',
  'jou',
  'les',
  'want',
  'man',
  'nieuw',
  'elk',
  'tekst',
  'omdat',
  'gebruiken',
  'u'
];
$Self->{'Ticket::SearchIndex::WarnOnStopWordUsage'} =  '0';
$Self->{'Ticket::SearchIndexModule'} =  'Kernel::System::Ticket::ArticleSearchIndex::DB';
$Self->{'Ticket::Service'} =  '1';
$Self->{'Ticket::Service::Default::UnknownCustomer'} =  '0';
$Self->{'Ticket::Service::KeepChildren'} =  '0';
$Self->{'Ticket::StateAfterPending'} =  {
  'pending auto close+' => 'closed successful',
  'pending auto close-' => 'closed unsuccessful'
};
$Self->{'Ticket::SubjectFormat'} =  'Left';
$Self->{'Ticket::SubjectFwd'} =  'Fwd';
$Self->{'Ticket::SubjectRe'} =  'Re';
$Self->{'Ticket::SubjectSize'} =  '100';
$Self->{'Ticket::Type'} =  '1';
$Self->{'Ticket::Type::Default'} =  'Unclassified';
$Self->{'Ticket::UnlockOnAway'} =  '1';
$Self->{'Ticket::UnlockStateType'} =  [
  'new',
  'open'
];
$Self->{'Ticket::ViewableLocks'} =  [
  '\'unlock\'',
  '\'tmp_lock\''
];
$Self->{'Ticket::ViewableSenderTypes'} =  [
  '\'customer\''
];
$Self->{'Ticket::ViewableStateType'} =  [
  'new',
  'open',
  'pending reminder'
];
$Self->{'Ticket::Watcher'} =  '0';
$Self->{'Ticket::ZoomAttachmentDisplayCount'} =  '20';
$Self->{'Ticket::ZoomTimeDisplay'} =  '1';
$Self->{'TicketACL::ACLPreselection'} =  '1';
$Self->{'TicketACL::Debug::Enabled'} =  '0';
$Self->{'TicketACL::Default::Action'} =  {};
$Self->{'TicketOverviewMenuSort'}->{'SortAttributes'} =  {
  'Age' => '1',
  'Title' => '1'
};
$Self->{'TimeAccounting::ActionListConstraints'} =  {};
$Self->{'TimeAccounting::ActiveFilter'} =  '0';
$Self->{'TimeAccounting::AllowMassEntryForUser'} =  '0';
$Self->{'TimeAccounting::DefaultActionName'} =  '';
$Self->{'TimeAccounting::DefaultActionStatus'} =  '1';
$Self->{'TimeAccounting::DefaultProjectName'} =  '';
$Self->{'TimeAccounting::DefaultProjectStatus'} =  '1';
$Self->{'TimeAccounting::DefaultUserDateEnd'} =  '2019-12-31';
$Self->{'TimeAccounting::DefaultUserDateStart'} =  '2019-01-01';
$Self->{'TimeAccounting::DefaultUserDescription'} =  'Put your description here.';
$Self->{'TimeAccounting::DefaultUserLeaveDays'} =  '23';
$Self->{'TimeAccounting::DefaultUserOvertime'} =  '0';
$Self->{'TimeAccounting::DefaultUserStatus'} =  '1';
$Self->{'TimeAccounting::DefaultUserWeeklyHours'} =  '40';
$Self->{'TimeAccounting::EnableAutoCompletion'} =  '1';
$Self->{'TimeAccounting::Frontend::ReportingProject'}->{'ShowOnlyActiveUsers'} =  '1';
$Self->{'TimeAccounting::InputHoursWithoutStartEndTime'} =  '1';
$Self->{'TimeAccounting::MaxAllowedInsertDays'} =  '10';
$Self->{'TimeAccounting::MaxIntervalOfIncompleteDays'} =  '4';
$Self->{'TimeAccounting::MaxIntervalOfIncompleteDaysBeforeWarning'} =  '2';
$Self->{'TimeAccounting::Project2RemarkRegExp'} =  '^(?: PROJECT\\# | INFRA: | PRODUCT: )';
$Self->{'TimeAccounting::ProjectListConstraints'} =  {};
$Self->{'TimeAccounting::ReduceTime'} =  {
  'traveling' => '50'
};
$Self->{'TimeAccounting::TicketSync::CreateProjectFromCustomerID'} =  '1';
$Self->{'TimeAccounting::TicketSync::CreateProjectFromTMPCustomerID'} =  '0';
$Self->{'TimeAccounting::TicketSync::DefaultActionID'} =  '4';
$Self->{'TimeAccounting::TicketSync::DefaultProjectID'} =  '5';
$Self->{'TimeAccounting::TicketSync::ServiceToAction'} =  {};
$Self->{'TimeAccounting::TicketSync::SetEntryReadOnly'} =  '1';
$Self->{'TimeAccounting::UseFilter'} =  '0';
$Self->{'TimeInputFormat'} =  'Option';
$Self->{'TimeInputMinutesStep'} =  '1';
$Self->{'TimeShowAlwaysLong'} =  '0';
$Self->{'TimeShowCompleteDescription'} =  '0';
$Self->{'TimeVacationDays'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '25' => 'First Christmas Day'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar1'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar2'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar3'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar4'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar5'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar6'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar7'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar8'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDays::Calendar9'} =  {
  '1' => {
    '1' => 'New Year\'s Day'
  },
  '12' => {
    '24' => 'Christmas Eve',
    '25' => 'First Christmas Day',
    '26' => 'Second Christmas Day',
    '31' => 'New Year\'s Eve'
  },
  '5' => {
    '1' => 'International Workers\' Day'
  }
};
$Self->{'TimeVacationDaysOneTime'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar1'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar2'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar3'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar4'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar5'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar6'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar7'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar8'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeVacationDaysOneTime::Calendar9'} =  {
  '2004' => {
    '1' => {
      '1' => 'test'
    }
  }
};
$Self->{'TimeWorkingHours'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18'
  ],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18'
  ]
};
$Self->{'TimeWorkingHours::Calendar1'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeWorkingHours::Calendar2'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeWorkingHours::Calendar3'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeWorkingHours::Calendar4'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeWorkingHours::Calendar5'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeWorkingHours::Calendar6'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeWorkingHours::Calendar7'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeWorkingHours::Calendar8'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeWorkingHours::Calendar9'} =  {
  'Fri' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Mon' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Sat' => [],
  'Sun' => [],
  'Thu' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Tue' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ],
  'Wed' => [
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20'
  ]
};
$Self->{'TimeZone::Calendar1Name'} =  'Calendar Name 1';
$Self->{'TimeZone::Calendar2Name'} =  'Calendar Name 2';
$Self->{'TimeZone::Calendar3Name'} =  'Calendar Name 3';
$Self->{'TimeZone::Calendar4Name'} =  'Calendar Name 4';
$Self->{'TimeZone::Calendar5Name'} =  'Calendar Name 5';
$Self->{'TimeZone::Calendar6Name'} =  'Calendar Name 6';
$Self->{'TimeZone::Calendar7Name'} =  'Calendar Name 7';
$Self->{'TimeZone::Calendar8Name'} =  'Calendar Name 8';
$Self->{'TimeZone::Calendar9Name'} =  'Calendar Name 9';
$Self->{'TransitionActionParams::SetOptionalParameters'} =  '1';
$Self->{'Translations::AllowModifyAll'} =  '0';
$Self->{'Translations::ObjectList'} =  {
  'DynamicFieldContent' => 'Dynamic Field Contents',
  'DynamicFieldLabel' => 'Dynamic Field Labels',
  'GeneralLabel' => 'General Label',
  'Priority' => 'Priorities',
  'Queue' => 'Queues',
  'SLA' => 'SLAs',
  'Service' => 'Services',
  'State' => 'Ticket States',
  'Template' => 'Templates',
  'Type' => 'Ticket Types'
};
$Self->{'Translations::TranslateParentChild'} =  '1';
$Self->{'UniqueCIName::EnableUniquenessCheck'} =  '0';
$Self->{'UniqueCIName::UniquenessCheckScope'} =  'global';
$Self->{'UserDefaultTimeZone'} =  'UTC';
$Self->{'WebMaxFileUpload'} =  '48000000';
$Self->{'WebUploadCacheModule'} =  'Kernel::System::Web::UploadCache::DB';
$Self->{'WebUserAgent::DisableSSLVerification'} =  '0';
$Self->{'WebUserAgent::Timeout'} =  '15';
$Self->{'Znuny4OTOBOAdvancedDynamicFields::DynamicFieldValid'} =  '1';
    return;
}
1;
