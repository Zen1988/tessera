package Kernel::GenericInterface::Invoker::AWX::JobLaunch;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::AWX::Base);
our $ObjectManagerDisabled = 1;
sub _Spec { return ('job_templates', 1) }
1;
