FROM ubuntu:16.04

MAINTAINER The Oh Brothers

ARG DEBIAN_FRONTEND=noninteractive
ARG STEAMCMD_DIR=/steamcmd
ARG STEAMCMD_AR_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
ARG TIME_ZONE=Asia/Singapore

WORKDIR $STEAMCMD_DIR

RUN apt-get update \
    && apt-get install -y \
        locales \
        curl \
        lib32gcc1 \
        lib32stdc++6 \
        # Game Administration Packages
        tzdata \
        git \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime \
    && curl -sqL "$STEAMCMD_AR_URL" | tar zxvf -

ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8"

ENV STEAMCMD_DIR $STEAMCMD_DIR
ENV PATH $PATH:$STEAMCMD_DIR