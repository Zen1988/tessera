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

# Created: 2026-06-30 08:44:31 (zen.chan@ncs.com.sg)
# Changed: 2026-08-14 08:17:53 (root@localhost)
# Comment: This ACL was generated when a service was added or changed.
$Self->{TicketAcl}->{'zzz - Show Service based on Ticket-Type: Change'} = {
  'Possible' => {
    'Ticket' => {
      'Service' => [
        'Backup::Exclusion::Modify',
        'Backup::Policy::Modify',
        'Backup::Restore Validation::Perform',
        'Backup::Retention::Modify',
        'Backup::Rollback::Perform',
        'Common Service::Carbon Black::Agent Upgrade',
        'Common Service::Carbon Black::Policy Modify',
        'Common Service::Configuration Rollback',
        'Common Service::Monitoring::Agent Upgrade',
        'Common Service::Monitoring::Configuration Modify',
        'Common Service::Red Hat Satellite::Repository/Content View Modify',
        'Common Service::Splunk::Forwarder Upgrade',
        'Common Service::Splunk::Log Source Modify',
        'Common Service::Trellix ePO::Agent Upgrade',
        'Common Service::Trellix ePO::Policy Modify',
        'Common Service::WSUS::Policy/Group Modify',
        'Compute::Instance Lifecycle::Decommission',
        'Compute::Instance Lifecycle::Handover',
        'Compute::Instance Lifecycle::New Instance',
        'Compute::Migration::Cutover Support',
        'Compute::Migration::Rollback Support',
        'Compute::Migration::Server Migration',
        'Compute::Patch Management::Emergency Patch',
        'Compute::Patch Management::Out-of-Band Patch',
        'Compute::Patch Management::Patch Rollback',
        'Compute::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Compute::System Configuration::Modify',
        'Compute::System Configuration::Rollback',
        'Compute::System Hardening::Apply/Modify',
        'Compute::System Hardening::Remediation',
        'Compute::System Hardening::Rollback',
        'Compute::System Upgrade::Agent Upgrade',
        'Compute::System Upgrade::Firmware Upgrade',
        'Compute::System Upgrade::OS Upgrade',
        'Compute::System Upgrade::Rollback',
        'Directory::Active Directory::Computer Policy Modify',
        'Directory::Active Directory::Domain Policy Modify',
        'Directory::Active Directory::GPO Modify',
        'Directory::Active Directory::OU Modify',
        'Directory::Active Directory::Rollback',
        'Directory::ADFS::Authentication Policy Modify',
        'Directory::ADFS::Certificate Modify',
        'Directory::ADFS::Claim Rule Modify',
        'Directory::ADFS::Relying Party Trust Modify',
        'Directory::ADFS::Rollback',
        'File Transfer::SFTP::Access Policy Modify',
        'File Transfer::SFTP::Configuration Modify',
        'File Transfer::SFTP::Folder/Quota Modify',
        'File Transfer::SFTP::Key Rotation',
        'File Transfer::SFTP::Rollback',
        'Network::Device Lifecycle::Decommission',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Device Lifecycle::New Device',
        'Network::DNS::Configuration Modify',
        'Network::DNS::Rollback',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::Load Balancer::Configuration Modify',
        'Network::Load Balancer::Rollback',
        'Network::Patch Management::Emergency Patch',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Patch Management::Patch Rollback',
        'Network::Patch Management::Scheduled Patch',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Routing/Switching::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network::System Configuration::Modify',
        'Network::System Configuration::Rollback',
        'Network::System Hardening::Apply/Modify',
        'Network::System Hardening::Remediation',
        'Network::System Hardening::Rollback',
        'Platform::Tanzu Kubernetes::Access Policy Modify',
        'Platform::Tanzu Kubernetes::Configuration Modify',
        'Platform::Tanzu Kubernetes::Ingress Modify',
        'Platform::Tanzu Kubernetes::Platform Patch',
        'Platform::Tanzu Kubernetes::Platform Upgrade',
        'Platform::Tanzu Kubernetes::Resource Quota Modify',
        'Platform::Tanzu Kubernetes::Rollback',
        'Privileged Access::Configuration Rollback',
        'Privileged Access::CyberArk::Policy Modify',
        'Privileged Access::CyberArk::Safe Modify',
        'Privileged Access::Jump Host::Access Policy Modify',
        'Privileged Access::RSA::Policy Modify',
        'Security::Certificate::Install',
        'Security::Certificate::Renew',
        'Security::Certificate::Replace',
        'Security::Certificate::Rollback',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Storage::Object Storage::Object Lock Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Platform::Configuration Modify',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Platform::Hardening Apply/Modify',
        'Storage::Platform::Patch Management',
        'Vulnerability::Finding::Remediation',
        'Vulnerability::Tenable::Credential Modify',
        'Vulnerability::Tenable::Scan Policy Modify'
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
        'Change'
      ]
    }
  },
  'PropertiesDatabase' => {},
  'StopAfterMatch' => 0
};

# Created: 2026-06-30 08:44:31 (zen.chan@ncs.com.sg)
# Changed: 2026-06-30 08:44:31 (zen.chan@ncs.com.sg)
# Comment: This ACL was generated when a service was added or changed.
$Self->{TicketAcl}->{'zzz - Show Service based on Ticket-Type: Change::Major'} = {
  'Possible' => {
    'Ticket' => {
      'Service' => [
        'Backup::Exclusion::Modify',
        'Backup::Policy::Modify',
        'Backup::Restore Validation::Perform',
        'Backup::Retention::Modify',
        'Backup::Rollback::Perform',
        'Common Service::Carbon Black::Agent Upgrade',
        'Common Service::Carbon Black::Policy Modify',
        'Common Service::Configuration Rollback',
        'Common Service::Monitoring::Agent Upgrade',
        'Common Service::Monitoring::Configuration Modify',
        'Common Service::Red Hat Satellite::Repository/Content View Modify',
        'Common Service::Splunk::Forwarder Upgrade',
        'Common Service::Splunk::Log Source Modify',
        'Common Service::Trellix ePO::Agent Upgrade',
        'Common Service::Trellix ePO::Policy Modify',
        'Common Service::WSUS::Policy/Group Modify',
        'Compute::Instance Lifecycle::Decommission',
        'Compute::Instance Lifecycle::Handover',
        'Compute::Instance Lifecycle::New Instance',
        'Compute::Migration::Cutover Support',
        'Compute::Migration::Rollback Support',
        'Compute::Migration::Server Migration',
        'Compute::Patch Management::Emergency Patch',
        'Compute::Patch Management::Out-of-Band Patch',
        'Compute::Patch Management::Patch Rollback',
        'Compute::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Compute::System Configuration::Modify',
        'Compute::System Configuration::Rollback',
        'Compute::System Hardening::Apply/Modify',
        'Compute::System Hardening::Remediation',
        'Compute::System Hardening::Rollback',
        'Compute::System Upgrade::Agent Upgrade',
        'Compute::System Upgrade::Firmware Upgrade',
        'Compute::System Upgrade::OS Upgrade',
        'Compute::System Upgrade::Rollback',
        'Directory::Active Directory::Computer Policy Modify',
        'Directory::Active Directory::Domain Policy Modify',
        'Directory::Active Directory::GPO Modify',
        'Directory::Active Directory::OU Modify',
        'Directory::Active Directory::Rollback',
        'Directory::ADFS::Authentication Policy Modify',
        'Directory::ADFS::Certificate Modify',
        'Directory::ADFS::Claim Rule Modify',
        'Directory::ADFS::Relying Party Trust Modify',
        'Directory::ADFS::Rollback',
        'File Transfer::SFTP::Access Policy Modify',
        'File Transfer::SFTP::Configuration Modify',
        'File Transfer::SFTP::Folder/Quota Modify',
        'File Transfer::SFTP::Key Rotation',
        'File Transfer::SFTP::Rollback',
        'Network::Device Lifecycle::Decommission',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Device Lifecycle::New Device',
        'Network::DNS::Configuration Modify',
        'Network::DNS::Rollback',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::Load Balancer::Configuration Modify',
        'Network::Load Balancer::Rollback',
        'Network::Patch Management::Emergency Patch',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Patch Management::Patch Rollback',
        'Network::Patch Management::Scheduled Patch',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Routing/Switching::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network::System Configuration::Modify',
        'Network::System Configuration::Rollback',
        'Network::System Hardening::Apply/Modify',
        'Network::System Hardening::Remediation',
        'Network::System Hardening::Rollback',
        'Platform::Tanzu Kubernetes::Access Policy Modify',
        'Platform::Tanzu Kubernetes::Configuration Modify',
        'Platform::Tanzu Kubernetes::Ingress Modify',
        'Platform::Tanzu Kubernetes::Platform Patch',
        'Platform::Tanzu Kubernetes::Platform Upgrade',
        'Platform::Tanzu Kubernetes::Resource Quota Modify',
        'Platform::Tanzu Kubernetes::Rollback',
        'Privileged Access::Configuration Rollback',
        'Privileged Access::CyberArk::Policy Modify',
        'Privileged Access::CyberArk::Safe Modify',
        'Privileged Access::Jump Host::Access Policy Modify',
        'Privileged Access::RSA::Policy Modify',
        'Security::Certificate::Install',
        'Security::Certificate::Renew',
        'Security::Certificate::Replace',
        'Security::Certificate::Rollback',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Storage::Object Storage::Object Lock Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Platform::Configuration Modify',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Platform::Hardening Apply/Modify',
        'Storage::Platform::Patch Management',
        'Vulnerability::Finding::Remediation',
        'Vulnerability::Tenable::Credential Modify',
        'Vulnerability::Tenable::Scan Policy Modify'
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
        'Change::Major'
      ]
    }
  },
  'PropertiesDatabase' => {},
  'StopAfterMatch' => 0
};

# Created: 2026-06-30 08:44:31 (zen.chan@ncs.com.sg)
# Changed: 2026-07-01 07:25:03 (zen.chan@ncs.com.sg)
# Comment: This ACL was generated when a service was added or changed.
$Self->{TicketAcl}->{'zzz - Show Service based on Ticket-Type: Incident'} = {
  'Possible' => {
    'Ticket' => {
      'Service' => [
        'Access Management::Authentication Failure',
        'Access Management::Login Issue',
        'Access Management::MFA/Token Issue',
        'Access Management::Permission Issue',
        'Application Management::Application Degradation',
        'Application Management::Application Error',
        'Application Management::Application Performance Issue',
        'Application Management::Application Unavailable',
        'File Transfer::SFTP::Access Issue',
        'File Transfer::SFTP::Performance Issue',
        'File Transfer::SFTP::Transfer Issue',
        'General Assist::Incident Classification::Assist',
        'Infra Management::Connectivity Issue',
        'Infra Management::Infrastructure Component Fault',
        'Infra Management::Monitoring Alert',
        'Infra Management::Performance Issue',
        'Infra Management::Scheduled System Impact',
        'Infra Management::System Degradation',
        'Infra Management::System Unavailable',
        'Infra Management::Unknown Infra Issue',
        'Security::Certificate::Issue',
        'Security::Security Tool::Issue'
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
        'Incident'
      ]
    }
  },
  'PropertiesDatabase' => {},
  'StopAfterMatch' => 0
};

# Created: 2026-06-30 08:44:31 (zen.chan@ncs.com.sg)
# Changed: 2026-07-01 07:25:03 (zen.chan@ncs.com.sg)
# Comment: This ACL was generated when a service was added or changed.
$Self->{TicketAcl}->{'zzz - Show Service based on Ticket-Type: Incident::Major'} = {
  'Possible' => {
    'Ticket' => {
      'Service' => [
        'Access Management::Authentication Failure',
        'Access Management::Login Issue',
        'Access Management::MFA/Token Issue',
        'Access Management::Permission Issue',
        'Application Management::Application Degradation',
        'Application Management::Application Error',
        'Application Management::Application Performance Issue',
        'Application Management::Application Unavailable',
        'File Transfer::SFTP::Access Issue',
        'File Transfer::SFTP::Performance Issue',
        'File Transfer::SFTP::Transfer Issue',
        'General Assist::Incident Classification::Assist',
        'Infra Management::Connectivity Issue',
        'Infra Management::Infrastructure Component Fault',
        'Infra Management::Monitoring Alert',
        'Infra Management::Performance Issue',
        'Infra Management::Scheduled System Impact',
        'Infra Management::System Degradation',
        'Infra Management::System Unavailable',
        'Infra Management::Unknown Infra Issue',
        'Security::Certificate::Issue',
        'Security::Security Tool::Issue'
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
        'Incident::Major'
      ]
    }
  },
  'PropertiesDatabase' => {},
  'StopAfterMatch' => 0
};

# Created: 2026-06-30 08:44:31 (zen.chan@ncs.com.sg)
# Changed: 2026-08-14 04:28:42 (root@localhost)
# Comment: This ACL was generated when a service was added or changed.
$Self->{TicketAcl}->{'zzz - Show Service based on Ticket-Type: Problem'} = {
  'Possible' => {
    'Ticket' => {
      'Service' => [
        'Problem Management::Known Error Record',
        'Problem Management::Major Incident Follow-up',
        'Problem Management::Post Incident Review',
        'Problem Management::Preventive Action',
        'Problem Management::Recurring Incident Investigation',
        'Problem Management::Trend Degradation Investigation',
        'Problem Management::Unknown Root Cause Investigation'
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
        'Problem'
      ]
    }
  },
  'PropertiesDatabase' => {},
  'StopAfterMatch' => 0
};

# Created: 2026-05-12 02:58:21 (root@localhost)
# Changed: 2026-08-14 04:30:16 (root@localhost)
# Comment: This ACL was generated when a service was added or changed.
$Self->{TicketAcl}->{'zzz - Show Service based on Ticket-Type: ServiceRequest'} = {
  'Possible' => {
    'Ticket' => {
      'Service' => [
        'Backup::Assist::Request',
        'Backup::Exclusion::Request',
        'Backup::Policy::New/Modify',
        'Backup::Restore::Request',
        'Backup::Service::Onboarding/Modify',
        'Backup::Service::Remove',
        'Common Service::Carbon Black::Agent Upgrade',
        'Common Service::Carbon Black::Assist',
        'Common Service::Carbon Black::Onboarding/Modify',
        'Common Service::Carbon Black::Policy New/Modify',
        'Common Service::Carbon Black::Remove',
        'Common Service::Monitoring::Agent Upgrade',
        'Common Service::Monitoring::Alert Rule New/Modify',
        'Common Service::Monitoring::Assist',
        'Common Service::Monitoring::Onboarding/Modify',
        'Common Service::Monitoring::Remove',
        'Common Service::Red Hat Satellite::Assist',
        'Common Service::Red Hat Satellite::Onboarding/Modify',
        'Common Service::Red Hat Satellite::Remove',
        'Common Service::Red Hat Satellite::Repository/Content View New/Modify',
        'Common Service::Splunk::Access New/Modify',
        'Common Service::Splunk::Assist',
        'Common Service::Splunk::Forwarder Upgrade',
        'Common Service::Splunk::Log Source Onboarding/Modify',
        'Common Service::Splunk::Log Source Remove',
        'Common Service::Trellix ePO::Agent Upgrade',
        'Common Service::Trellix ePO::Assist',
        'Common Service::Trellix ePO::Onboarding/Modify',
        'Common Service::Trellix ePO::Policy New/Modify',
        'Common Service::Trellix ePO::Remove',
        'Common Service::WSUS::Assist',
        'Common Service::WSUS::Onboarding/Modify',
        'Common Service::WSUS::Policy/Group New/Modify',
        'Common Service::WSUS::Remove',
        'Compute::Resource::Assist',
        'Compute::Resource::Disk Expansion',
        'Compute::Resource::Upgrade/Downgrade',
        'Compute::Virtual Machine::Assist',
        'Compute::Virtual Machine::New',
        'Compute::Virtual Machine::Reboot',
        'Compute::Virtual Machine::Remove',
        'Compute::Virtual Machine::Snapshot/Restore',
        'Directory::Active Directory::Assist',
        'Directory::Active Directory::Computer Join/Modify',
        'Directory::Active Directory::GPO New/Modify',
        'Directory::Active Directory::Group New/Modify',
        'Directory::Active Directory::Group Remove',
        'Directory::Active Directory::Membership New/Modify',
        'Directory::Active Directory::Password Reset/Unlock',
        'Directory::Active Directory::Service Account New/Modify',
        'Directory::Active Directory::Service Account Remove/Disable',
        'Directory::Active Directory::User New/Modify',
        'Directory::Active Directory::User Remove/Disable',
        'Directory::ADFS::Application New/Modify',
        'Directory::ADFS::Application Remove',
        'Directory::ADFS::Assist',
        'Directory::ADFS::Certificate New/Modify',
        'Directory::ADFS::Claim/Relying Party Trust New/Modify',
        'Directory::ADFS::Login Assist',
        'File Transfer::SFTP::Assist',
        'File Transfer::SFTP::Folder/Path New/Modify',
        'File Transfer::SFTP::Key New/Modify',
        'File Transfer::SFTP::Quota New/Modify',
        'File Transfer::SFTP::Tenant Onboarding/Modify',
        'File Transfer::SFTP::Tenant Remove',
        'File Transfer::SFTP::Transfer Assist',
        'File Transfer::SFTP::User Access New/Modify',
        'File Transfer::SFTP::User Access Remove',
        'General Assist::Architecture Consultation::Request',
        'General Assist::Audit Support::Request',
        'General Assist::Document/Information Request::Request',
        'General Assist::General Enquiry::Request',
        'General Assist::Meeting Support::Request',
        'General Assist::Others::Request',
        'General Assist::Request Classification::Assist',
        'General Assist::Technical Consultation::Request',
        'Network::Address::New',
        'Network::Address::Release',
        'Network::Connectivity::Allowlist New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::DNS::Assist',
        'Network::DNS::Record New/Modify',
        'Network::DNS::Record Remove',
        'Network::Firewall Policy::Emergency',
        'Network::Firewall Policy::New/Modify',
        'Network::Firewall Policy::Remove',
        'Network::Firewall Policy::Review',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Certificate New/Modify',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::New',
        'Network::Segment',
        'Network::Segment::New',
        'Platform::Tanzu Kubernetes::Access New/Modify',
        'Platform::Tanzu Kubernetes::Assist',
        'Platform::Tanzu Kubernetes::Ingress New/Modify',
        'Platform::Tanzu Kubernetes::Namespace New/Modify',
        'Platform::Tanzu Kubernetes::Namespace Remove',
        'Platform::Tanzu Kubernetes::Resource Quota New/Modify',
        'Privileged Access::CyberArk::Account Onboarding/Modify',
        'Privileged Access::CyberArk::Account Remove',
        'Privileged Access::CyberArk::Assist',
        'Privileged Access::CyberArk::Password Rotation Assist',
        'Privileged Access::CyberArk::Safe Access New/Modify',
        'Privileged Access::Jump Host::Access New/Modify',
        'Privileged Access::Jump Host::Access Remove',
        'Privileged Access::Jump Host::Assist',
        'Privileged Access::Jump Host::Server Onboarding/Modify',
        'Privileged Access::RSA::Assist',
        'Privileged Access::RSA::Token New/Modify',
        'Privileged Access::RSA::Token Remove',
        'Privileged Access::RSA::Token Reset/Resync',
        'Security::Certificate::Assist',
        'Security::Certificate::CSR Signing',
        'Security::Certificate::Install/Update',
        'Security::Certificate::New/Renew',
        'Security::Certificate::Revoke',
        'Storage::Object Storage::Access New/Modify',
        'Storage::Object Storage::Assist',
        'Storage::Object Storage::Bucket New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning New/Modify',
        'Vulnerability::Tenable::Assist',
        'Vulnerability::Tenable::Credential New/Modify',
        'Vulnerability::Tenable::Report Request',
        'Vulnerability::Tenable::Scan Onboarding/Modify',
        'Vulnerability::Tenable::Scan Remove',
        'Risk::Policy & Compliance::Control Attestation'
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
