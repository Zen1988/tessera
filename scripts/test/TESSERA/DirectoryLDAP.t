use strict;
use warnings;
use Test::More;
use lib '.';
use Kernel::System::TESSERA::DirectoryLDAP;
BEGIN {
    $INC{'Net/LDAP/Control/Paged.pm'}=1;
    $INC{'Net/LDAP/Util.pm'}=1;
}
{package Net::LDAP::Control::Paged;sub new {my ($T,%P)=@_;bless \%P,$T}sub cookie {$_[0]{cookie}=$_[1] if @_>1;return $_[0]{cookie} || ''}
 package Net::LDAP::Util;sub escape_filter_value {my ($V)=@_;$V=~s/([\x00()*\\])/sprintf('\\%02x',ord $1)/ge;return $V}
 package DirectoryPage;sub code {$_[0]{code} || 0}sub references {$_[0]{refs} || 0}sub entries {@{$_[0]{entries} || []}}sub control {return $_[0]{control}}
 package DirectoryEntry;sub get_value {$_[0]{$_[1]}}sub dn {$_[0]{DN}}
 package DirectoryWire;sub search {my ($S,%P)=@_;push @{$S->{queries}},\%P;return shift @{$S->{pages}}}sub unbind {$_[0]{unbound}++;return 1}
 package DirectoryMockLDAP;our @ISA=('Kernel::System::TESSERA::DirectoryLDAP');sub Connect {return $_[0]{wire}}
}
sub page {my (%P)=@_;return bless \%P,'DirectoryPage'}
sub cookie {return bless {cookie=>$_[0]},'Net::LDAP::Control::Paged'}
my $Wire=bless {pages=>[],queries=>[]},'DirectoryWire';my $S=DirectoryMockLDAP->new(wire=>$Wire);
$Wire->{pages}=[page(entries=>[1],control=>cookie('next')),page(entries=>[2],control=>cookie(''))];
is_deeply($S->_Search($Wire,base=>'DC=test',filter=>'(cn=*)'),[1,2],'complete paged result accumulated');
ok($Wire->{queries}[0]{control}[0]{critical},'paging control is critical');
for my $Bad (page(code=>4,entries=>[1]),page(refs=>1),page(entries=>[1])) {
    $Wire->{pages}=[$Bad];ok(!eval {$S->_Search($Wire,base=>'DC=test');1},'limit/referral/missing paging proof fails closed');
}
$Wire->{pages}=[page(control=>cookie('same')),page(control=>cookie('same'))];
ok(!eval {$S->_Search($Wire,base=>'DC=test');1},'repeated pagination cookie rejected');
$Wire->{pages}=[page(entries=>[bless({objectGUID=>'x'x16,cn=>'Network',DN=>'CN=Network,DC=test'},'DirectoryEntry')],control=>cookie(''))];
my $Groups=$S->Groups({GroupBase=>'DC=test',GroupFilter=>'(cn=Network*)'},'secret');
is($Groups->[0]{GUID},unpack('H*','x'x16),'binary AD group GUID retained as stable identity');
is($Wire->{queries}[-1]{filter},'(&(objectClass=group)(cn=Network*))','configured group filter applied under group class boundary');
$Wire->{pages}=[page(entries=>[bless({objectGUID=>'y'x16,sAMAccountName=>'alice',givenName=>'Alice',sn=>'Smith',mail=>'alice@test'},'DirectoryEntry')],control=>cookie(''))];
my $Users=$S->Members({Nested=>1,LoginAttribute=>'sAMAccountName',UserBase=>'OU=Users,DC=test'},'secret',{DN=>'CN=Group(*),DC=test'});
is($Users->[0]{Login},'alice','member mapped to customer login');
like($Wire->{queries}[-1]{filter},qr/memberOf:1\.2\.840\.113556\.1\.4\.1941:/,'nested membership explicitly configured');
like($Wire->{queries}[-1]{filter},qr/Group\\28\\2a\\29/,'group DN escaped as LDAP filter value');
like($Wire->{queries}[-1]{filter},qr/!\(userAccountControl:/,'disabled AD users excluded');
done_testing();
