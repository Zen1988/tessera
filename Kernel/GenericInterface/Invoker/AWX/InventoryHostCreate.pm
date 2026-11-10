package Kernel::GenericInterface::Invoker::AWX::InventoryHostCreate;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::AWX::Inventory);
our $ObjectManagerDisabled = 1;
sub _Kind { return 'create' }
1;
