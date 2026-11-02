#!/usr/bin/env perl
use strict;
use warnings;

# Load classes only. Never instantiate ObjectManager, read authentication
# profiles/tokens, load Config.pm, query the database or contact an issuer.
my @Modules=(
    ['Kernel::System::OpenIDConnect::Configuration','Kernel/System/OpenIDConnect/Configuration.pm'],
    ['Kernel::System::OpenIDConnect::OAuth2','Kernel/System/OpenIDConnect/OAuth2.pm'],
    ['Kernel::Modules::AdminOAuthTokenStore','Kernel/Modules/AdminOAuthTokenStore.pm'],
);
for my $M (@Modules) {
    my $OK=eval {require $M->[1];1};
    if (!$OK) {
        my $Error=$@;my $Detail='Run a direct require test with the application Perl and library path for the underlying error.';
        if ($Error=~/Can't locate ([A-Za-z0-9_\/]+)\.pm/) {my $Name=$1;$Name=~s{/}{::}g;$Detail="Missing dependency: $Name."}
        elsif ($Error=~/for module ([A-Za-z0-9_:]+)/) {$Detail="XS/module dependency failed to load: $1."}
        elsif ($Error=~/syntax error/) {$Detail='Module compilation failed.'}
        print STDERR "OAuth load check failed for $M->[0]. $Detail\n";
        exit 1;
    }
}
print "Native OAuth configuration, OAuth2 and token-store classes load OK; no profiles or tokens accessed.\n";
exit 0;
