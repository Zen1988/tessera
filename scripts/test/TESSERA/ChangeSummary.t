use strict;use warnings;use Test::More;
our $Value;
{ package Kernel; our $OM; }
{ package Mock; sub Get { bless {},'Mock' } sub DynamicFieldGet { return {Name=>$_[2]} } sub ValueGet { return $main::Value->{$_[2]->{Name}} } sub Ascii2Html { return $_[2] } }
$Kernel::OM=bless {},'Mock';
sub IsHashRefWithData { ref $_[0] eq 'HASH' && keys %{$_[0]} }
open my $fh,'<','var/governancedb/runtime_overlay/Kernel/Modules/CustomerTicketZoom.pm' or die $!;local $/;my $src=<$fh>;
my ($helper)=$src=~/(sub _ZTSMChangeSummaryFields \{.*?)(?=sub _ZTSMIncidentSeverityBadgeHTML)/s;eval $helper;die $@ if $@;
$Value={ChangeType=>'Emergency',ChangeClassification=>'Major'};
my @rows=_ZTSMChangeSummaryFields({},TicketID=>42);
is($rows[0][0],'Change Type');is($rows[0][1],'Emergency');is($rows[1][0],'Change Classification');like($rows[1][1],qr/class="ZTSMChangeClassificationMajor">Major/);
$Value={};@rows=_ZTSMChangeSummaryFields({},TicketID=>42);is($rows[0][1],'Normal');is($rows[1][1],'Not-Assessed');
$Value={ChangeType=>'<script>',ChangeClassification=>'<img>'};@rows=_ZTSMChangeSummaryFields({},TicketID=>42);is($rows[0][1],'Normal');is($rows[1][1],'Not-Assessed');
like($src,qr/splice \@SummaryFields, 2, 0, \$Self->_ZTSMChangeSummaryFields/);like($src,qr/my \$IsChange = .* eq 'Change'/);
done_testing;
