# syntax=docker/dockerfile:1
ARG BASE_IMAGE=ubuntu:26.04
FROM ${BASE_IMAGE}
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG OTOBO_UID=10001
ARG OTOBO_GID=33
ARG TESSERA_VERSION=0.0.180
ARG TESSERA_IMAGE_REVISION=r1
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
COPY apt-packages.txt apt-extra.txt /tmp/tessera-apt/
RUN . /etc/os-release && test "$ID" = ubuntu && test "$VERSION_ID" = 26.04 \
 && mapfile -t packages < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' /tmp/tessera-apt/*.txt) \
 && for package in "${packages[@]}"; do [[ "$package" =~ ^[a-z0-9][a-z0-9+.:=~_-]*$ ]] || exit 1; done \
 && apt-get update \
 && apt-get install -y --no-install-recommends "${packages[@]}" \
 && rm -rf /var/lib/apt/lists/* /tmp/tessera-apt \
 && groupmod --gid "$OTOBO_GID" www-data \
 && useradd --uid "$OTOBO_UID" --gid "$OTOBO_GID" --home-dir /opt/otobo --shell /bin/bash otobo
ENV OTOBO_HOME=/opt/otobo OTOBO_USER=otobo OTOBO_GROUP=www-data OTOBO_RUNS_UNDER_DOCKER=1
COPY dependencies/cpanfile /opt/tessera/dependencies/cpanfile
COPY cpanfile.extra /opt/tessera/dependencies/cpanfile.extra
COPY --chmod=0755 image/ /usr/local/lib/tessera/
# All CPAN/XS modules are installed using Ubuntu's /usr/bin/perl in THIS image.
RUN /usr/local/lib/tessera/install-perl.sh
# Keep the native OTOBO mod_perl/prefork serving model. No default sites/CGI aliases.
# Ubuntu marks autoindex essential; -f acknowledges its intentional removal
# without an interactive prompt in the image build.
RUN a2dismod -f mpm_event autoindex status \
 && a2enmod mpm_prefork perl headers reqtimeout ssl \
 && a2dissite 000-default default-ssl \
 && a2disconf serve-cgi-bin \
 && cp /usr/local/lib/tessera/apache/tls.conf /etc/apache2/sites-available/tessera.conf \
 && a2ensite tessera \
 && test "$(find /etc/apache2/sites-enabled -mindepth 1 -maxdepth 1 -printf '%f\n')" = tessera.conf \
 && find /usr/bin /usr/sbin -xdev -type f -perm /6000 -exec chmod a-s {} +
ENV PERL5LIB=/opt/otobo/Custom:/opt/otobo/Kernel/cpan-lib:/opt/otobo:/opt/tessera-perl/lib/perl5
ENV PATH=/opt/tessera-perl/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY --chown=0:0 app/ /opt/otobo/
COPY dependencies/host-summary.json dependencies/source-sha256.json /opt/tessera/dependencies/
WORKDIR /opt/otobo
# Build checks never load host Config.pm, contact the DB or reinstall a package.
RUN python3 /usr/local/lib/tessera/audit-app.py /opt/otobo \
 && cp -a Kernel/Config/Files /opt/tessera/config-files.dist \
 && chown -R root:www-data /opt/tessera/config-files.dist \
 && find /opt/tessera/config-files.dist -type d -exec chmod 0550 {} + \
 && find /opt/tessera/config-files.dist -type f -exec chmod 0440 {} + \
 && chown -R otobo:www-data /opt/otobo \
 && find /opt/otobo -type d -exec chmod 0550 {} + \
 && find /opt/otobo -type f -exec chmod 0440 {} + \
 && find /opt/otobo/bin -type f -exec chmod 0550 {} + \
 && install -d -m 0750 -o otobo -g www-data var/tmp var/log var/run var/spool var/article var/virtualfs var/stats Kernel/Config/Files \
 && install -d -m 0750 -o otobo -g www-data var/httpd/htdocs/js/js-cache \
 && find var/httpd/htdocs/skins -type d -name css -print0 | while IFS= read -r -d '' dir; do install -d -m 0750 -o otobo -g www-data "$(dirname "$dir")/css-cache"; done \
 && python3 /usr/local/lib/tessera/config-digest.py /opt/tessera/config-files.dist > /opt/tessera/config-definitions.sha256 \
 && /usr/bin/perl -c Custom/Kernel/System/TESSERA/Secrets.pm \
 && /usr/bin/perl -c Custom/Kernel/System/TESSERA/SecretRedis.pm \
 && /usr/bin/perl -c Custom/Kernel/System/Cache/Redis.pm \
 && /usr/bin/perl -MGD -MRedis -MRedis::Fast -MDBD::MariaDB -MPlack::Handler::Gazelle -e 'print "Runtime dependency imports OK\n"' \
 && /usr/local/lib/tessera/check-perl.pl \
 && mkdir -p var/run/apache \
 && chown otobo:www-data var/run/apache \
 && APACHE_RUN_DIR=/opt/otobo/var/run/apache /usr/sbin/apache2 -t -D TESSERA_CONFIGTEST -f /usr/local/lib/tessera/apache/main.conf \
 && dpkg-query -W > /opt/tessera/dependencies/ubuntu-packages.tsv
LABEL org.opencontainers.image.title="TESSERA" org.opencontainers.image.version="${TESSERA_VERSION}"
LABEL io.tessera.image.revision="${TESSERA_IMAGE_REVISION}"
COPY --chmod=0444 scripts/test-configure.py /opt/tessera/tests/test-configure.py
USER otobo
# Verify every packaged definition using the actual configured runtime UID.
# This check contacts no database and makes no changes to a shared volume.
RUN /usr/bin/python3 /usr/local/lib/tessera/configure.py check-source
# Exercise configure's copying/failure/fingerprint lifecycle as otobo, with a
# disposable fixture command instead of touching a database during image build.
RUN TESSERA_CONFIGURE_HELPER=/usr/local/lib/tessera/configure.py \
    TESSERA_REQUIRE_TEST_UID="$OTOBO_UID" \
    /usr/bin/python3 /opt/tessera/tests/test-configure.py
EXPOSE 8443
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=15s --start-period=60s --retries=3 CMD ["/usr/local/lib/tessera/healthcheck.sh"]
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/lib/tessera/entrypoint.sh"]
CMD ["web"]
