use strict;use warnings;use Test::More;
open my $f,'<','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerTicketMessage.pm' or die $!;
my $src=do{local $/;<$f>};my ($code)=$src=~/(sub _ZTSMValidationFailures \{.*)/s;eval "package Diagnostic; $code";die $@ if $@;
my $s=bless {},'Diagnostic';my $r=$s->_ZTSMValidationFailures(Field=>'FirewallPolicyRule',Validation=>{ServerError=>1,ErrorMessage=>'aggregate','ZFirewall-SrcIp_0'=>{ServerError=>1,ErrorMessage=>'Invalid IP'},'ZFirewall-SrcPurpose_0'=>{ServerError=>0},'ZFirewall-Type_1'=>{ServerError=>1,ErrorMessage=>'This field is required.'}});
is(scalar @$r,2,'logs only failing members without duplicate aggregate');is($r->[0]{Field},'ZFirewall-SrcIp_0','identifies indexed field');is($r->[1]{Message},'This field is required.','preserves member explanation');
$r=$s->_ZTSMValidationFailures(Field=>'FirewallPolicyRule',Validation=>{ServerError=>1});is($r->[0]{Field},'FirewallPolicyRule','container-only failure identified');like($r->[0]{Message},qr/without an explanatory/,'explicit absent message');
$r=$s->_ZTSMValidationFailures(Field=>'X',Validation=>{Nested=>{Row=>{ServerError=>1,ErrorMessage=>"bad\nvalue"}}});is($r->[0]{Message},'bad value','nested error sanitized');
$r=$s->_ZTSMValidationFailures(Field=>'X',Validation=>{ServerError=>0});is_deeply($r,[],'valid result generates no diagnostic errors');
done_testing();
