package Kernel::GenericInterface::Invoker::NetXMS::ServerInfo;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::NetXMS::Base);
our $ObjectManagerDisabled = 1;
sub _Operation { return 'ServerInfo' }
1;
