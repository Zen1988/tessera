package Kernel::GenericInterface::Invoker::NetXMS::DataCollection;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::NetXMS::Base);
our $ObjectManagerDisabled = 1;
sub _Operation { return 'DataCollection' }
1;
