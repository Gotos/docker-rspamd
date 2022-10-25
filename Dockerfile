FROM docker.io/tiredofit/alpine:3.16
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ARG RSPAMD_VERSION

ENV RSPAMD_VERSION=${RSPAMD_VERSION:-"3.3"} \
    RSPAMD_REPO_URL=https://github.com/rspamd/rspamd \
    CONTAINER_ENABLE_MESSAGING=FALSE \
    IMAGE_NAME="tiredofit/rspamd" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-rspamd/"

### Install Dependencies
RUN source /assets/functions/00-container && \
    set -x && \
    addgroup -S -g 11333 rspamd && \
    adduser -S -D -H -h /dev/null -s /sbin/nologin -G rspamd -u 11333 rspamd && \
    apk update && \
    apk upgrade && \
    apk add -t .rspamd-build-deps \
                build-base \
                cmake \
                curl-dev \
                fmt-dev \
                git \
                glib-dev \
                icu-dev \
                libsodium-dev \
                luajit-dev \
                openssl1.1-compat-dev \
                pcre2-dev \
                perl \
                py3-pip \
                ragel \
                redis \
                samurai \
                sqlite-dev \
                vectorscan-dev \
                zlib-dev \
                zstd-dev \
                && \
    \
    apk add -t .rspamd-run-deps \
                fmt \
                glib \
                icu \
                icu-data-full \
                libestr \
                libfastjson \
                libsodium \
                libuuid \
                luajit \
                pcre2 \
                openssl \
                python3 \
                rsyslog \
                sqlite \
                vectorscan \
                zlib \
                zstd \
                && \
    \
    pip3 install \
                configparser \
                inotify \
                && \
    \
   clone_git_repo ${RSPAMD_REPO_URL} ${RSPAMD_VERSION} && \
   cmake \
                  -B build \
                  -G Ninja \
                  -DCMAKE_BUILD_TYPE=MinSizeRel \
                  -DCMAKE_INSTALL_PREFIX=/usr \
                  -DCONFDIR=/etc/rspamd \
                  -DRUNDIR=/run/rspamd \
                  -DRSPAMD_USER=rspamd \
                  -DRSPAMD_GROUP=rspamd \
                  -DENABLE_REDIRECTOR=ON \
                  -DENABLE_PCRE2=ON \
                  -DENABLE_HYPERSCAN=ON \
                  -DENABLE_LUAJIT=ON \
                  #-DNO_SHARED=OFF \
                  -DSYSTEM_FMT=ON \
                  -DSYSTEM_ZSTD=ON \
                  -DCMAKE_HOST_SYSTEM_NAME=Linux \
                  . \
                  && \
    cmake --build build --target all && \
    cmake --build build --target install && \
    #make -C /usr/src/rspamd/build -j$(nproc) all && \
    #make -C /usr/src/rspamd/build -j$(nproc) install && \
    mkdir -p /run/rspamd && \
    mkdir -p /assets/rspamd && \
    mkdir -p /etc/rspamd/local.d && \
    mkdir -p /etc/rspamd/override.d && \
    mv /etc/rspamd/maps.d /assets/rspamd/ && \
    mv /usr/bin/redis-cli /usr/sbin && \
    \
### Cleanup
    apk del .rspamd-build-deps && \
    rm -rf /etc/logrotate.d/* /var/cache/apk/* /usr/src/*

### Networking Configuration
EXPOSE 11333 11334 11335

### Add Files
ADD install /
