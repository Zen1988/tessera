#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
unset PERL5OPT PERL5LIB
install -d /opt/otobo/local /tmp/tessera-cpan
/usr/bin/perl /usr/local/lib/tessera/merge-cpanfiles.pl /opt/tessera/dependencies/cpanfile /opt/tessera/dependencies/cpanfile.packages /opt/tessera/dependencies/cpanfile.extra > /tmp/tessera-cpan/cpanfile
cd /tmp/tessera-cpan
/usr/bin/perl /usr/bin/cpanm --local-lib=/opt/otobo/local --mirror https://cpan.metacpan.org --mirror-only --installdeps .
PERL5LIB=/opt/otobo/local/lib/perl5 /usr/bin/perl /usr/local/lib/tessera/check-integration-deps.pl
cp cpanfile /opt/tessera/dependencies/combined.cpanfile
# These directories contain build downloads/logs only, never application data.
rm -rf /root/.cpanm /tmp/tessera-cpan
