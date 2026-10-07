use strict;
use warnings;
use Test::More;
sub Slurp { my ($P)=@_; open my $F,'<:raw',$P or die $!; local $/; return <$F>; }
my $Base='Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/';
my $Set=Slurp($Base.'Set.pm');
for my $Method (qw(EditFieldValueValidate _RenderContentGet _RenderFieldListGet)) {
    my ($Code)=$Set =~ /(sub \Q$Method\E \{.*?)(?=\nsub |\n1;)/s;
    die "Missing $Method" if !$Code;
    eval "package Kernel::System::DynamicField::Driver::Set; $Code"; die $@ if $@;
}
my $Group=Slurp($Base.'DynamicFieldGroup.pm');
$Group =~ s/^use (?:Kernel::[^;]+|namespace::autoclean|parent[^;]+);\r?\n//mg;
eval $Group; die $@ if $@;
{
    no strict 'refs';
    @{'Kernel::System::DynamicField::Driver::DynamicFieldGroup::ISA'}=('Kernel::System::DynamicField::Driver::Set');
    *{'Kernel::System::DynamicField::Driver::Set::IsHashRefWithData'}=sub {ref $_[0] eq 'HASH' && keys %{$_[0]}};
    *{'Kernel::System::DynamicField::Driver::Set::IsArrayRefWithData'}=sub {ref $_[0] eq 'ARRAY' && @{$_[0]}};
    *{'Kernel::System::DynamicField::Driver::Set::_GetIncludedDynamicFields'}=sub {$_[0]{Members}};
    *{'Kernel::System::DynamicField::Driver::Set::_SubmittedSetIndexListGet'}=sub {@{$_[0]{Indexes}}};
    *{'Kernel::System::DynamicField::Driver::Set::_SubmittedSetHasData'}=sub {$_[0]{HasData}};
}
{ package RequiredBackend;
  sub Get { $_[0] }
  sub EditFieldValueValidate {
    my ($S,%P)=@_; push @{$S->{Calls}},\%P;
    return { Nested => { ServerError=>1,ErrorMessage=>'Nested required member' } } if $S->{Nested};
    return {ServerError=>($P{Mandatory} && !$S->{Populated}),ErrorMessage=>'Required member'};
  }
}
for my $Class (qw(Kernel::System::DynamicField::Driver::Set Kernel::System::DynamicField::Driver::DynamicFieldGroup)) {
  my $D=bless {Members=>{'ZRM-RiskAction'=>{Mandatory=>1},'ZRM-RiskDetail'=>{Mandatory=>0}},Indexes=>[0,1],HasData=>1},$Class;
  my $OM=bless {},'RequiredBackend'; local $Kernel::OM=$OM;
  my %P=(DynamicFieldConfig=>{Name=>'RiskAssessment',Config=>{Include=>[]}},GetParam=>{DynamicField=>{DynamicField_RiskAssessment=>[{}]}},Mandatory=>0);
  my $R=$D->EditFieldValueValidate(%P);
  ok($R->{ServerError},"$Class exposes child errors at container");
  is(scalar @{$OM->{Calls}},4,"$Class validates every member in both rows");
  is_deeply([map {$_->{Mandatory}} @{$OM->{Calls}}],[1,0,1,0],"$Class required members and optional members stay distinct");
  $OM->{Calls}=[]; $OM->{Populated}=1;
  $R=$D->EditFieldValueValidate(%P,Mandatory=>1);
  ok(!$R->{ServerError},"$Class valid members pass");
  is($OM->{Calls}[1]{Mandatory},0,"$Class required container does not require optional member");
  $OM->{Nested}=1; $R=$D->EditFieldValueValidate(%P);
  ok($R->{ServerError},"$Class aggregates nested group errors");
  $D->{HasData}=0; $R=$D->EditFieldValueValidate(%P,Mandatory=>1);
  ok($R->{ServerError},"$Class required empty container fails");
  for my $Layout ('Vertical','Horizontal') {
    my $Content=$D->_RenderContentGet(DynamicFieldConfig=>{Config=>{RenderLayout=>$Layout,Include=>[{DF=>'ZRM-RiskAction',Mandatory=>1},{DF=>'ZRM-RiskDetail',Mandatory=>0}]}});
    my @Fields=$D->_RenderFieldListGet(Include=>$Content);
    is_deeply([map {$_->{Mandatory}} @Fields],[1,0],"$Class $Layout renderer preserves required metadata for OTOBO client validation");
  }
}
done_testing();
