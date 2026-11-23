use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Digest::SHA qw(sha256_hex);
use JSON::PP qw(decode_json encode_json);
use lib '.';
use Kernel::System::GovernanceDB::Bootstrap;
sub Read {
    open my $F,'<:raw',$_[0] or die $!;local $/;return <$F>;
}
sub Write {
    my($Path,$Data)=@_;make_path(dirname($Path));open my $F,'>:raw',$Path or die $!;print {$F} $Data;close $F;
}
{
    package CompatibilityOM;
    sub Get {$_[0]}
    sub Decode {my($S,%P)=@_;return JSON::PP::decode_json($P{Data})}
    sub GetHome {$_[0]{Home}}
}
# Same method name serves ObjectManager->Get and Config->Get('Home').
{
    no warnings 'redefine';
    *CompatibilityOM::Get=sub {my($S,$Name)=@_;return $S->{Home} if $Name eq 'Home';return $S};
}
my $Home=tempdir(CLEANUP=>1);
my $Manifest=Read('var/tessera/compatibility/otobo-11.1.1.json');
my $Data=decode_json($Manifest);
for my $E (@{$Data->{entries}}) {
    next unless $E->{path}=~m{\ACustom/};
    my $Stable="native fixture $E->{native_path}";
    $E->{target_native_sha256}=sha256_hex($Stable);
    $E->{current_native_sha256}=sha256_hex("legacy fixture $E->{native_path}");
    $E->{override_sha256}=sha256_hex("old Custom fixture $E->{path}");
    is(sha256_hex(Read($E->{source_location})),$E->{merged_sha256},"packaged merged source $E->{path}");
    Write("$Home/$E->{native_path}",$Stable);
    Write("$Home/$E->{source_location}",Read($E->{source_location}));
}
Write("$Home/var/tessera/compatibility/otobo-11.1.1.json",encode_json($Data));
local $Kernel::OM=bless {Home=>$Home},'CompatibilityOM';
my $Bootstrap=bless {},'Kernel::System::GovernanceDB::Bootstrap';
ok($Bootstrap->_OTOBO111CompatibilityPreflight(),'fresh stable installation passes without Custom targets');
my ($E)=grep {$_->{path}=~m{\ACustom/}} @{$Data->{entries}};
my $Target="$Home/$E->{path}";
my $Original="old Custom fixture $E->{path}";
Write($Target,$Original);
ok($Bootstrap->_OTOBO111CompatibilityPreflight(),'reviewed deployed Custom source is upgradeable');
Write($Target,Read($E->{source_location}));
ok($Bootstrap->_OTOBO111CompatibilityPreflight(),'same-version reinstall accepts merged source');
my $Native="$Home/$E->{native_path}";
Write($Native,"legacy fixture $E->{native_path}");
ok($Bootstrap->_OTOBO111CompatibilityPreflight(),'known package-native basis remains supported after package repair');
Write($Native,"native fixture $E->{native_path}");
Write($Target,'unreviewed administrator customization');
eval {$Bootstrap->_OTOBO111CompatibilityPreflight()};
like($@,qr/Unknown administrator override/,'unknown administrator source fails before bootstrap');
is(Read($Target),'unreviewed administrator customization','unknown customization preserved');
Write($Target,Read($E->{source_location}));
my $Core=Read("$Home/$E->{native_path}");
Write("$Home/$E->{native_path}",'unreviewed future core');
eval {$Bootstrap->_OTOBO111CompatibilityPreflight()};
like($@,qr/Native basis changed/,'unreviewed future native core fails closed');
Write("$Home/$E->{native_path}",$Core);
Write("$Home/$E->{source_location}",'corrupted payload');
eval {$Bootstrap->_OTOBO111CompatibilityPreflight()};
like($@,qr/Merged source integrity mismatch/,'corrupted merged payload rejected');
done_testing();
