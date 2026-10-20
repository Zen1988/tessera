#!/usr/bin/env bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
unset PERL5OPT PERL5LIB
install -d /opt/tessera-perl /tmp/tessera-cpan
cat /opt/tessera/dependencies/cpanfile /opt/tessera/dependencies/cpanfile.extra > /tmp/tessera-cpan/cpanfile
cd /tmp/tessera-cpan
/usr/bin/cpanm --local-lib=/opt/tessera-perl --mirror https://cpan.metacpan.org --mirror-only --installdeps .
cp cpanfile /opt/tessera/dependencies/combined.cpanfile
# These directories contain build downloads/logs only, never application data.
rm -rf /root/.cpanm /tmp/tessera-cpan
