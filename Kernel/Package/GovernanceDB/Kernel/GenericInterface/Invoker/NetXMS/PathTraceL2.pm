package Kernel::GenericInterface::Invoker::NetXMS::PathTraceL2;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::NetXMS::PathTrace);
our $ObjectManagerDisabled=1;
sub _Operation { 'PathTraceL2' }
sub _TraceMethod { 'traceL2Path' }
1;
