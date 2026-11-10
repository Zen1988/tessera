package Kernel::GenericInterface::Invoker::NetXMS::Objects;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::NetXMS::Base);
our $ObjectManagerDisabled = 1;
sub _Operation { return 'Objects' }
1;
