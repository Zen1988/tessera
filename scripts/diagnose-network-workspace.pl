#!/usr/bin/env perl
use strict;use warnings;use Digest::SHA qw(sha256_hex);
use lib '/opt/otobo/Custom','/opt/otobo/Kernel/cpan-lib','/opt/otobo';
$|=1;
my $Login=shift @ARGV;
die "Usage: perl - customer-login < diagnose-network-workspace.pl\n" if !defined $Login || ref $Login || !length $Login || length($Login)>255 || $Login=~/[[:cntrl:]]/;
sub safe {defined $_[0] && !ref $_[0] && $_[0]=~/^[A-Za-z0-9_:.-]{1,120}$/?$_[0]:'absent-or-invalid'}
sub reason {
 my ($E)=@_;
 for my $R ('Customer CMDB read access required.','Asset scope exceeds workspace budget.','Installed CMDB model is incomplete.','Installed address model is incomplete.','Address collection exceeds budget.','Workspace classes unavailable.','Asset scan unavailable.','Native asset scan unavailable.','Native asset page changed.','Authorized workspace exceeds response size budget.') {return $R if index($E,$R)>=0}
 return 'unexpected-runtime-error (raw exception withheld)';
}
my $Stage='object-manager';my $OK=eval {
 chdir '/opt/otobo' or die 'Application directory unavailable';
 require Kernel::System::ObjectManager;local $Kernel::OM=Kernel::System::ObjectManager->new();
 print "diagnostic=network-workspace-read-only\n";
 $Stage='installed-package';my $DB=$Kernel::OM->Get('Kernel::System::DB');
 if($DB->Prepare(SQL=>q{SELECT version,install_status FROM package_repository WHERE name = ?},Bind=>[\(my $Name='TESSERA-Base')])) {while(my @R=$DB->FetchrowArray()){print 'package=',join(',',map {safe($_)} @R),"\n"}}
 $Stage='access-check';my $B=$Kernel::OM->Get('Kernel::System::TESSERA::CustomerNetworkSimulation');
 print 'access_check=',$B->AccessCheck(CustomerUserID=>$Login)?'yes':'no',"\n";
 print 'remote_grant=',$B->_simulation($Login)?'yes':'no',"\n";
 my $Module=$INC{'Kernel/System/TESSERA/CustomerNetworkSimulation.pm'};
 if(defined $Module && -f $Module){open my $F,'<:raw',$Module or die;my $Data=do {local $/;<$F>};close $F;print 'model_module_sha256=',sha256_hex($Data),"\n"}
 $Stage='class-schema';my $Catalog=$Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(Class=>'ITSM::ConfigItem::Class') || {};
 my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem');
 for my $Class (qw(Workload NetworkNode)) {
  my @IDs=grep {$Catalog->{$_} eq $Class} keys %$Catalog;print "schema_class=$Class;matches=",scalar @IDs,"\n";next if @IDs!=1;
  my $D=eval {$CI->DefinitionGet(ClassID=>$IDs[0])};my $E=$@;
  if($E || ref $D ne 'HASH'){print "schema_definition=$Class;unavailable\n";next}
  my $Fields=$D->{DynamicFieldRef};print "schema_fields=$Class;shape=",ref($Fields) || 'scalar-or-absent',"\n";next if ref $Fields ne 'HASH';
  for my $Field (qw(ZTAM-Application ZTAM-Environment ZTAM-NetworkAdapter)) {
   my $F=$Fields->{$Field};print "schema_field=$Class;$Field;type=",ref $F eq 'HASH'?safe($F->{FieldType}):'absent',"\n";
  }
  my $Adapter=$Fields->{'ZTAM-NetworkAdapter'};next if ref $Adapter ne 'HASH';
  print "schema_address=$Class;config_shape=",ref($Adapter->{Config}) || 'scalar-or-absent',"\n";next if ref $Adapter->{Config} ne 'HASH';my $Include=$Adapter->{Config}{Include};
  print "schema_address=$Class;include_shape=",ref($Include) || 'scalar-or-absent',"\n";
  if(ref $Include eq 'ARRAY') {my @IPs=grep {ref $_ eq 'HASH' && ($_->{DF} || '') eq 'ZTAM-IpAddress'} @$Include;
   print "schema_address=$Class;ip_members=",scalar @IPs,"\n";
   for my $IP (@IPs){print "schema_address=$Class;ip_type=",ref $IP->{Definition} eq 'HASH'?safe($IP->{Definition}{FieldType}):'definition-absent',"\n"}
  }
 }
 $Stage='workspace-model';my $M;my $Built=eval {$M=$B->Model(CustomerUserID=>$Login);1};
 if(!$Built){my $E=$@;print 'model_error=',reason($E),"\n";
  if($E=~/Can't locate object method "([A-Za-z0-9_]+)" via package "([A-Za-z0-9_:]+)"/){print "missing_method=$2\::$1\n"}
  if($E=~m{at ((?:/opt/otobo/)?(?:Custom/)?Kernel/[A-Za-z0-9_/.]+\.pm) line ([0-9]+)}){print "error_location=$1:$2\n"}
 } elsif(ref $M eq 'HASH'){print 'model=ok;assets=',scalar @{$M->{Assets} || []},';applications=',scalar @{$M->{Applications} || []},"\n"}
 else {print "model=invalid-return\n"}
 print "diagnostic=completed-no-grants-hooks-or-navis-calls\n";1;
};
if(!$OK){print "failed_stage=$Stage\nreason=",reason($@ || ''),"\n";exit 1}
