package Kernel::System::DynamicField::Driver::TESSERAChangeDropdown;
use strict;
use warnings;
use parent 'Kernel::System::DynamicField::Driver::Dropdown';
use Kernel::System::TESSERA::ChangeClassification;
our @ObjectDependencies=qw(Kernel::Config Kernel::System::Main Kernel::System::DB Kernel::System::DynamicFieldValue Kernel::System::Ticket Kernel::System::Ticket::ColumnFilter Kernel::System::Log);
sub _protected {my $N=$_[1]{DynamicFieldConfig}{Name} || '';return $N=~/\A(?:ChangeType|ChangeClassification)\z/i}
sub EditFieldRender {
    my ($S,%P)=@_;return {Field=>'',Label=>''} if $S->_protected(\%P);return $S->SUPER::EditFieldRender(%P);
}
sub ValueSet {
    my ($S,%P)=@_;
    return if $S->_protected(\%P) && !Kernel::System::TESSERA::ChangeClassification->WriteAllowed(%P);
    return $S->SUPER::ValueSet(%P);
}
1;
