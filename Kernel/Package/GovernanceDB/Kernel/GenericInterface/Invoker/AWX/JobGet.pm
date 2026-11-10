package Kernel::GenericInterface::Invoker::AWX::JobGet;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::AWX::Base);
our $ObjectManagerDisabled = 1;
sub _Spec { return ('jobs', 0) }
1;
