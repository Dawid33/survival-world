FROM debian:stable-slim

# number of retries that curl will use when pulling the headless server tarball
ARG CURL_RETRIES=8

ENV PORT=34197 \
    RCON_PORT=27015 \
    VERSION=2.0.42 \
    SAVES=/factorio/saves \
    CONFIG=/factorio/config \
    SCRIPTOUTPUT=/factorio/script-output

RUN apt-get -q update 
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install luarocks ca-certificates curl jq pwgen xz-utils procps gettext-base --no-install-recommends 

RUN curl -sSL "https://www.factorio.com/get-download/$VERSION/headless/linux64" -o "/tmp/factorio_headless_x64_$VERSION.tar.xz" --retry $CURL_RETRIES
RUN mkdir -p /opt/factorio 
RUN chmod ugo=rwx /opt/factorio 
RUN tar xf "/tmp/factorio_headless_x64_$VERSION.tar.xz" --directory /opt 
RUN rm "/tmp/factorio_headless_x64_$VERSION.tar.xz" 
RUN ln -s "$SAVES" /opt/factorio/saves

COPY scenarios/tester /opt/factorio/scenarios/tester
COPY scenario.sh scenario.sh 
COPY config.ini /opt/factorio/config/config.ini

EXPOSE $PORT/udp $RCON_PORT/tcp
CMD ["/scenario.sh", "tester"]
