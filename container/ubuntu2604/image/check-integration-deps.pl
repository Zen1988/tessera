#!/usr/bin/env perl
use strict;
use warnings;

# Check the concrete modules required by the OPM, not just the distribution name.
# No Config.pm, database, mounted secret or external system is accessed.
my @Missing;
push @Missing, 'Crypt::AuthEnc::GCM >= 0.087' if !eval {require Crypt::AuthEnc::GCM;Crypt::AuthEnc::GCM->VERSION('0.087');1};
push @Missing, 'Crypt::PRNG >= 0.087' if !eval {require Crypt::PRNG;Crypt::PRNG->VERSION('0.087');1};
if (@Missing) {
    print STDERR 'Missing application Perl dependency: '.join(', ',@Missing).".\n";
    print STDERR "Install the CryptX distribution with the application's Perl and library path, then rebuild the immutable runtime image.\n";
    exit 1;
}
my $OK=eval {
    my $Key=Crypt::PRNG::random_bytes(32);
    my $IV=Crypt::PRNG::random_bytes(12);
    die if length($Key)!=32 || length($IV)!=12;
    my ($Cipher,$Tag)=Crypt::AuthEnc::GCM::gcm_encrypt_authenticate('AES',$Key,$IV,'dependency-check','synthetic-roundtrip');
    my $Plain=Crypt::AuthEnc::GCM::gcm_decrypt_verify('AES',$Key,$IV,'dependency-check',$Cipher,$Tag);
    die if !defined $Plain || $Plain ne 'synthetic-roundtrip';
    substr($Tag,0,1)=chr(ord(substr($Tag,0,1)) ^ 1);
    my $Tampered=eval {Crypt::AuthEnc::GCM::gcm_decrypt_verify('AES',$Key,$IV,'dependency-check',$Cipher,$Tag)};
    die if defined $Tampered;
    1;
};
if (!$OK) {print STDERR "CryptX runtime check failed: AES-GCM/PRNG must function under the application's Perl.\n";exit 1}
print "CryptX GCM/PRNG imports, minimum versions, AES-256 roundtrip and tamper rejection OK.\n";
exit 0;
