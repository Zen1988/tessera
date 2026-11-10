package Kernel::GenericInterface::Invoker::AWX::WorkflowGet;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::AWX::Base);
our $ObjectManagerDisabled = 1;
sub _Spec { return ('workflow_jobs', 0) }
1;
