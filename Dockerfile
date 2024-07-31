FROM debian:stable-slim

# number of retries that curl will use when pulling the headless server tarball
ARG CURL_RETRIES=8

ENV PORT=34197 \
    RCON_PORT=27015 \
    VERSION=1.1.109 \
    SAVES=/factorio/saves \
    CONFIG=/factorio/config \
    SCRIPTOUTPUT=/factorio/script-output

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN set -ox pipefail \
    && archive="/tmp/factorio_headless_x64_$VERSION.tar.xz" \
    && mkdir -p /opt/factorio \
    && apt-get -q update \
    && DEBIAN_FRONTEND=noninteractive apt-get -qy install ca-certificates curl jq pwgen xz-utils procps gettext-base --no-install-recommends \
    && curl -sSL "https://www.factorio.com/get-download/$VERSION/headless/linux64" -o "$archive" --retry $CURL_RETRIES\
    && tar xf "$archive" --directory /opt \
    && chmod ugo=rwx /opt/factorio \
    && rm "$archive" \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s "$SAVES" /opt/factorio/saves \
    && ln -s "$CONFIG" /opt/factorio/config

COPY scenarios/tester /opt/factorio/scenarios/tester
COPY config.ini /opt/factorio/config/config.ini

VOLUME /factorio
EXPOSE $PORT/udp $RCON_PORT/tcp
CMD ["/opt/factorio/bin/x64/factorio", "--start-server-load-scenario", "survival-world/tester"]
