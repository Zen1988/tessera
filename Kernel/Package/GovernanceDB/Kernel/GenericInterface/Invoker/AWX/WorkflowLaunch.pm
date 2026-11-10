package Kernel::GenericInterface::Invoker::AWX::WorkflowLaunch;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::AWX::Base);
our $ObjectManagerDisabled = 1;
sub _Spec { return ('workflow_job_templates', 1) }
1;
