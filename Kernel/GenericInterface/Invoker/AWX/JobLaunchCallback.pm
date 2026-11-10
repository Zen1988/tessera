package Kernel::GenericInterface::Invoker::AWX::JobLaunchCallback;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::AWX::JobLaunch);
our $ObjectManagerDisabled = 1;
sub _CallbackLaunch { return 1 }
1;
