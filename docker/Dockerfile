# syntax = docker/dockerfile:1.0-experimental
ARG UBUNTU_RELEASE=focal
FROM ubuntu:focal AS mc

RUN : \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      git ca-certificates golang-go \
      gcc libc6-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && git clone https://github.com/minio/mc /mc \
 && :

WORKDIR /mc
RUN go install

FROM ubuntu:$UBUNTU_RELEASE AS builder
SHELL [ "/bin/bash", "-eou", "pipefail", "-c" ]

#hadolint ignore=DL3008
RUN : \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      curl ca-certificates \
      devscripts equivs \
      dpkg-dev \
      git \
      gpg \
      lsb-release \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && git config --global advice.detachedHead false \
 && :

ARG GIT_REPOSITORY
ARG GIT_REF
ARG ORIGINAL_TARBALL_URL
# SECRET gpgkey -- armored private GPG key for signing debs

#
#  TODO - extract package_version from ubuntu/changelog
#
RUN : \
 && mkdir build \
 && git clone "${GIT_REPOSITORY}" /build/src \
 && git -C /build/src checkout "${GIT_REF}" \
 && package_version=$(sed -n '1s/^.*(\([0-9\.]*\)[-~ ].*$/\1/p' /build/src/debian/changelog) \
 && suffix=$(sed -nE 's/^.*\.tar\.([^\.]+)$/\1/p' <<< "${ORIGINAL_TARBALL_URL}") \
 && source_name=$(sed -nE 's/^Source:\s+(\S*)/\1/ip' /build/src/debian/control) \
 && curl -L "${ORIGINAL_TARBALL_URL}" \
         -o "/build/${source_name}_${package_version}.orig.tar.${suffix}" \
 && :

WORKDIR /build/src

RUN : \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive mk-build-deps --install \
      --tool 'apt-get --yes --no-install-recommends' --remove \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && :

#
#  TODO:  Can there be logic to detect and accommodate whether a key has been
#         provided?  Or is it a must-have?
#

#hadolint ignore=SC2215
RUN --mount=type=secret,id=gpgkey : \
 && trap 'rm -rf "$HOME/.gpg"' EXIT \
 && gpg --import /run/secrets/gpgkey \
 #  vvv Change the relase to match UBUNTU_RELEASE -- our little bit of magic
 && sed -i "1s/\\S*;/$(lsb_release -cs);/" debian/changelog \
 && debuild -b \
 && { debuild -S -sa || { shopt -s nullglob && cat /tmp/*.diff.* && exit 12; }; } \
 && :

WORKDIR /build
RUN : \
 && mkdir -p /debs \
 && shopt -s nullglob \
 && ln -- *.buildinfo *.changes *.deb *.ddeb *.dsc *.tar.* /debs \
 && :

FROM ubuntu:focal

RUN : \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      dput \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && :

COPY --from=mc /root/go/bin/mc /usr/bin/mc
COPY --from=builder /debs /debs
