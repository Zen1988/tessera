use strict; use warnings; use Test::More; use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::ITSMConfigItem::Document;
my $c=bless {},'Kernel::System::ITSMConfigItem::Document';
for my $case ([46660,0,'Date','2027-09-30 00:00:00'],[45055,0,'Date','2023-05-09 00:00:00'],[46660.5,0,'DateTime','2027-09-30 12:00:00'],[0,1,'Date','1904-01-01 00:00:00'],[1,0,'Date','1900-01-01 00:00:00'],[61,0,'Date','1900-03-01 00:00:00'],['2027-09-30',0,'Date','2027-09-30 00:00:00'],['2027-09-30 14:30:45',0,'DateTime','2027-09-30 14:30:45'],['',0,'Date','']) {
 is($c->_ImportDateNormalize(Value=>$case->[0],Excel=>1,ExcelDate1904=>$case->[1],FieldType=>$case->[2]),$case->[3],'serial/string normalized'); }
for my $bad (60,'2027-02-30','09/10/2027','abc',-1) { eval{$c->_ImportDateNormalize(Value=>$bad,Excel=>1,FieldType=>'Date')}; ok($@,'invalid or ambiguous date rejected'); }
eval{$c->_ImportDateNormalize(Value=>46660,Excel=>0,FieldType=>'Date')};ok($@,'serial restricted to Excel import');
done_testing();
