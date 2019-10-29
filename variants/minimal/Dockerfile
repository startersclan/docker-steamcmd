ARG BASE_IMAGE
FROM $BASE_IMAGE

ARG DEBIAN_FRONTEND=noninteractive
ARG STEAMCMD_DIR=/steamcmd
ARG STEAMCMD_AR_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

WORKDIR $STEAMCMD_DIR

RUN apt-get update \
    && apt-get install -y \
        locales \
        ca-certificates \
        curl \
        # Game dependencies
        lib32gcc1 \
        lib32stdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && curl -sqL "$STEAMCMD_AR_URL" | tar -zxvf -

ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

ENV STEAMCMD_DIR $STEAMCMD_DIR
ENV PATH $PATH:$STEAMCMD_DIR