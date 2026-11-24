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
    open my $FH, '<:raw', $_[0] or die $!;
    local $/;
    return <$FH>;
}
sub Write {
    my ($Path, $Data) = @_;
    make_path(dirname($Path));
    open my $FH, '>:raw', $Path or die $!;
    print {$FH} $Data;
    close $FH;
}
{
    package AddonGuardOM;
    sub Get { my ($Self, $Name) = @_; return $Name eq 'Home' ? $Self->{Home} : $Self; }
    sub Decode { my ($Self, %Param) = @_; return JSON::PP::decode_json($Param{Data}); }
}
my $Home = tempdir(CLEANUP => 1);
my $Manifest = decode_json(Read('var/tessera/compatibility/otobo-11.1.1-addons.json'));
for my $Entry (@{$Manifest->{overlaps}}) {
    my $Content = Read($Entry->{source_location});
    is(sha256_hex($Content), $Entry->{merged_sha256}, 'packaged add-on source hash matches');
    Write("$Home/$Entry->{source_location}", $Content);
    $Entry->{allowed_sha256} = [sha256_hex('reviewed vendor fixture'), $Entry->{merged_sha256}];
}
Write("$Home/var/tessera/compatibility/otobo-11.1.1-addons.json", encode_json($Manifest));
local $Kernel::OM = bless {Home => $Home}, 'AddonGuardOM';
my $Bootstrap = bless {}, 'Kernel::System::GovernanceDB::Bootstrap';
ok($Bootstrap->_OTOBO111AddonPreflight(), 'fresh installation accepts missing Custom targets');
my $Entry = $Manifest->{overlaps}[0];
my $Target = "$Home/$Entry->{path}";
Write($Target, 'reviewed vendor fixture');
ok($Bootstrap->_OTOBO111AddonPreflight(), 'known vendor deployment may be merged');
Write($Target, Read($Entry->{source_location}));
ok($Bootstrap->_OTOBO111AddonPreflight(), 'same-version reinstall accepts merged target');
Write($Target, 'administrator customization');
eval { $Bootstrap->_OTOBO111AddonPreflight(); };
like($@, qr/Unknown add-on override/, 'unknown override requires explicit merge');
is(Read($Target), 'administrator customization', 'preflight preserves unknown override');
Write($Target, Read($Entry->{source_location}));
Write("$Home/$Entry->{source_location}", 'corrupt');
eval { $Bootstrap->_OTOBO111AddonPreflight(); };
like($@, qr/source integrity mismatch/, 'corrupt packaged source rejected');
done_testing;
