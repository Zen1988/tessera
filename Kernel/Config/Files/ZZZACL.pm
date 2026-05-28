# OTOBO config file (automatically generated)
# VERSION:1.1
package Kernel::Config::Files::ZZZACL;
use strict;
use warnings;
no warnings 'redefine'; ## no critic qw(TestingAndDebugging::ProhibitNoWarnings)
use utf8;
sub Load {
    my ($File, $Self) = @_;

# Created: 2026-04-15 07:14:54 (root@localhost)
# Changed: 2026-04-15 07:14:54 (root@localhost)
# Comment: This ACL was generated when a service was added or changed.
$Self->{TicketAcl}->{'zza - Disable all Services if no Ticket-Type is selected.'} = {
  'Possible' => {},
  'PossibleAdd' => {},
  'PossibleNot' => {
    'Ticket' => {
      'Service' => [
        '[RegExp].*'
      ]
    }
  },
  'Properties' => {
    'Frontend' => {
      'Action' => [
        'CustomerTicketMessage',
        'AgentTicketPhone',
        'AgentTicketEmail',
        'AgentTicketFreeText'
      ]
    }
  },
  'PropertiesDatabase' => {},
  'StopAfterMatch' => 0
};

# Created: 2026-05-12 02:58:21 (root@localhost)
# Changed: 2026-05-12 02:58:36 (root@localhost)
# Comment: This ACL was generated when a service was added or changed.
$Self->{TicketAcl}->{'zzz - Show Service based on Ticket-Type: ServiceRequest'} = {
  'Possible' => {
    'Ticket' => {
      'Service' => [
        'Network::Firewall Policy::New/Modify',
        'Network::Load Balancer::New/Modify'
      ]
    }
  },
  'PossibleAdd' => {},
  'PossibleNot' => {},
  'Properties' => {
    'Frontend' => {
      'Action' => [
        'CustomerTicketMessage',
        'AgentTicketPhone',
        'AgentTicketEmail',
        'AgentTicketFreeText'
      ]
    },
    'Ticket' => {
      'Type' => [
        'ServiceRequest'
      ]
    }
  },
  'PropertiesDatabase' => {},
  'StopAfterMatch' => 0
};



    return;
}
1;
