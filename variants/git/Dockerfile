ARG BASE_IMAGE
FROM $BASE_IMAGE

ARG DEBIAN_FRONTEND=noninteractive
ARG STEAMCMD_DIR=/steamcmd
ARG STEAMCMD_AR_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

WORKDIR $STEAMCMD_DIR

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        ca-certificates \
        curl \
        wget \
        # Game dependencies
        libgcc-s1:amd64 \
        libgcc-s1:i386 \
        libstdc++6 \
        lib32stdc++6 \
        libz1 \
        lib32z1 \
        libbz2-1.0:amd64 \
        libbz2-1.0:i386 \
        libcurl3t64-gnutls:amd64 \
        libcurl3t64-gnutls:i386 \
        # libsdl2-2.0-0:amd64 \
        # libsdl2-2.0-0:i386 \
        # Debugging tools
        file \
        # Game administration packages
        git \
        # Text editors
        vim-tiny \
        nano \
        # Network tools
        conntrack dnsutils iproute2 netcat-traditional net-tools tcpdump \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && curl -sqL "$STEAMCMD_AR_URL" | tar -zxvf -

# Game dependencies
RUN set -eux; \
    # Fix error: Failed to load libtinfo.so.5 or libncurses.so.5. Please install (lib32tinfo5 / ncurses-libs.i686 / equivalent) to enable readline.
    # For 64-bit
    curl -sSLO --fail https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.3_amd64.deb; \
    curl -sSLO --fail https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2ubuntu0.3_amd64.deb; \
    apt install -y --no-install-recommends ./libtinfo5_6.3-2ubuntu0.3_amd64.deb ./libncurses5_6.3-2ubuntu0.3_amd64.deb; \
    rm -fv ./libtinfo5_6.3-2ubuntu0.3_amd64.deb ./libncurses5_6.3-2ubuntu0.3_amd64.deb; \
    # For 32-bit
    curl -sSLO --fail https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.3_i386.deb; \
    curl -sSLO --fail https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2ubuntu0.3_i386.deb; \
    apt install -y --no-install-recommends ./libtinfo5_6.3-2ubuntu0.3_i386.deb ./libncurses5_6.3-2ubuntu0.3_i386.deb; \
    rm -fv ./libtinfo5_6.3-2ubuntu0.3_i386.deb ./libncurses5_6.3-2ubuntu0.3_i386.deb;

ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

ENV STEAMCMD_DIR $STEAMCMD_DIR
ENV PATH $PATH:$STEAMCMD_DIR
