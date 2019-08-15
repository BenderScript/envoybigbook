FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

RUN apt-get -qq update && \
    apt-get -qq install  \
                curl \
                apt-transport-https \
                ca-certificates \
                gnupg-agent \
                iptables \
                software-properties-common \
                < /dev/null > /dev/null

RUN curl -sL 'https://getenvoy.io/gpg' | apt-key add -

RUN apt-key fingerprint 6FF974DB
RUN add-apt-repository \
    "deb [arch=amd64] https://dl.bintray.com/tetrate/getenvoy-deb \
    $(lsb_release -cs) \
    stable"

RUN apt-get -qq update && apt-get -qq install getenvoy-envoy
