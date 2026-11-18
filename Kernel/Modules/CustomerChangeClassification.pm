package Kernel::Modules::CustomerChangeClassification;
use strict;
use warnings;
use Kernel::System::TESSERA::ChangeClassificationScreen;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {my ($S)=@_;return Kernel::System::TESSERA::ChangeClassificationScreen->new(%$S,Customer=>1)->Run()}
1;
