use strict;
use warnings;
use Test::More;
use XML::LibXML;
sub Slurp { my ($Path)=@_;open my $FH,'<',$Path or die $!;return do{local $/;<$FH>}; }
my $Name='Loader::Customer::CommonCSS###120-TESSERAPortalResponse';
my $XML=XML::LibXML->load_xml(location=>'Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/ZTSMGovernanceRuntime.xml');
my @Settings=$XML->findnodes('//Setting[@Name="'.$Name.'"]');
is(scalar @Settings,1,'one common response CSS registration');
is($Settings[0]->getAttribute('Valid'),1,'new setting enabled');
my @CSS=map {$_->textContent} $Settings[0]->findnodes('Value/Array/Item');
is_deeply(\@CSS,['TESSERA.Customer.SecurityResponse.css'],'shared response CSS owned by common customer loader');
ok(-f 'Kernel/Package/GovernanceDB/var/httpd/htdocs/skins/Customer/default/css/'.$CSS[0],'registered file exists in customer skin payload');
my $Native=Slurp('Kernel/Output/HTML/Layout/Loader.pm');
$Native =~ /(sub LoaderCreateCustomerCSSCalls \{.*?^\})/ms or die 'native loader method absent';
eval 'package SecurityLoaderUnderTest;'.$1;die $@ if $@;
{
 package SecurityLoaderUnderTest;
 sub _HandleCSSList {my($Self,%Param)=@_;push @{$Self->{Calls}},\%Param;}
 package SecurityCSSConfig;
 sub Get {my($Self,$Key)=@_;return $Self->{Values}{$Key};}
 package SecurityCSSRequest;
 sub Header {undef}
 package SecurityCSSOM;
 sub Get {my($Self,$Key)=@_;return $Self->{Objects}{$Key} || die "unexpected dependency $Key";}
}
my $Config=bless {Values=>{
 Home=>'.','Loader::Customer::SelectedSkin'=>'default',
 'Loader::Customer::CommonCSS'=>{'120-TESSERAPortalResponse'=>\@CSS},'Loader::Customer::ResponsiveCSS'=>{},
 'Loader::Module::CustomerTicketZTSMAction'=>{'120-TESSERASecurityResponse'=>{CSS=>[],JavaScript=>[]}},
}},'SecurityCSSConfig';
local $Kernel::OM=bless {Objects=>{'Kernel::Config'=>$Config,'Kernel::System::Web::Request'=>bless({},'SecurityCSSRequest')}},'SecurityCSSOM';
for my $Minify (0,1) {
 $Config->{Values}{'Loader::Enabled::CSS'}=$Minify;
 my $Loader=bless {Action=>'CustomerTicketZTSMAction',Calls=>[]},'SecurityLoaderUnderTest';
 $Loader->LoaderCreateCustomerCSSCalls();
 my ($Module)=grep {$_->{BlockName} eq 'ModuleCSS'} @{$Loader->{Calls}};
 is_deeply($Module->{List},[],'module registration no longer duplicates shared CSS');
 is($Module->{DoMinify},$Minify,'native pipeline honors minification setting');
 my ($Common)=grep {$_->{BlockName} eq 'CommonCSS'} @{$Loader->{Calls}};
 is_deeply($Common->{List},\@CSS,'native common loader selects response CSS with minification '.$Minify);
}
my $Bootstrap=Slurp('Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm');
$Bootstrap =~ /(sub _CustomerResponseLoaderMigration \{.*?^\})/ms or die 'migration absent';
eval 'package SecurityDeployUnderTest;'.$1;die $@ if $@;
$Bootstrap =~ /(sub _SysConfigDeploy \{.*?^\})/ms or die 'deployment method absent';
eval 'package SecurityDeployUnderTest;'.$1;die $@ if $@;
{
 package SecurityDeployUnderTest;sub _CustomerPhotoRegistrationRepair {1}
 package SecurityDeployConfig;
 sub SettingGet {my($Self,%Param)=@_;return (EffectiveValue=>$Self->{Value},IsValid=>0);}
 sub SettingsSet {my($Self,%Param)=@_;$Self->{Writes}++;$Self->{Value}=$Param{Settings}[0]{EffectiveValue};$Self->{IsValid}=$Param{Settings}[0]{IsValid};return 1;}
 sub ConfigurationDeploy {my($Self,%Param)=@_;push @{$Self->{Deploys}},\%Param;return(Success=>1)}
 package SecurityDeployCache;sub CleanUp {1}
}
my $DeployConfig=bless {Deploys=>[],Writes=>0,Value=>{CSS=>['admin.css','TESSERA.Customer.SecurityResponse.css'],JavaScript=>['admin.js'],Custom=>'preserve'}},'SecurityDeployConfig';
$Kernel::OM->{Objects}{'Kernel::System::SysConfig'}=$DeployConfig;
$Kernel::OM->{Objects}{'Kernel::System::Cache'}=bless {},'SecurityDeployCache';
my $Deploy=bless {},'SecurityDeployUnderTest';
for (1..2) {
 ok($Deploy->_SysConfigDeploy(),'fresh/upgrade/reinstall deployment succeeds');
 my $Entries=$DeployConfig->{Deploys}[-1]{DirtySettings};
 is(scalar(grep {$_ eq $Name} @$Entries),1,'new loader setting deployed exactly once');
}
is($DeployConfig->{Writes},1,'legacy module CSS migrates only once across repeated installation');
is_deeply($DeployConfig->{Value}{CSS},['admin.css'],'administrator CSS preserved');
is_deeply($DeployConfig->{Value}{JavaScript},['admin.js'],'administrator JS preserved');
is($DeployConfig->{Value}{Custom},'preserve','unrelated admin configuration preserved');
is($DeployConfig->{IsValid},0,'existing disabled module setting remains disabled');
my $Branding=Slurp('Kernel/Package/GovernanceDB/var/httpd/htdocs/skins/Customer/default/css/TESSERA.Customer.Branding.css');
unlike($Branding,qr/ZTSMSecurityCard/,'security CSS removed from login-only branding');
my $SecurityCSS=Slurp('Kernel/Package/GovernanceDB/var/httpd/htdocs/skins/Customer/default/css/TESSERA.Customer.SecurityResponse.css');
like($SecurityCSS,qr/ZTSMSecurityCode.*?#b42318/s,'red large error code in correct stylesheet');
like($SecurityCSS,qr/ZTSMSecurityWarning.*?#fff3c4/s,'yellow warning in correct stylesheet');
done_testing();
