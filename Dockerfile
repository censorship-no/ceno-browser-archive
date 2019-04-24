# This is similar to ouinet/Dockerfile, but based on ubuntu (easier to build Android on)
FROM ubuntu:18.04
# To get the list of build dependency packages from the Vagrantfile, run:
#
#     sed '/# Install toolchain/,/^$/!d' Vagrantfile \
#         | sed -En 's/^\s+(\S+)\s*\\?$/\1/p' | sort
#
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autopoint \
    build-essential \
    cmake \
    gettext \
    git \
    libgcrypt-dev \
    libidn11-dev \
    libssl-dev \
    libtool \
    libunistring-dev \
    pkg-config \
    rsync \
    texinfo \
    wget \
    zlib1g-dev \
    libnotify-bin \
    mercurial \
    sudo \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /usr/local/src
RUN wget -q "https://downloads.sourceforge.net/project/boost/boost/1.67.0/boost_1_67_0.tar.bz2" \
 && tar -xf boost_1_67_0.tar.bz2 \
 && cd boost_1_67_0 \
 && ./bootstrap.sh \
 && ./b2 -j `nproc` -d+0 --link=shared \
         --with-system \
         --with-program_options \
         --with-test \
         --with-coroutine \
         --with-filesystem \
         --with-date_time \
         --with-regex \
         --with-iostreams \
         --prefix=/usr/local install
# Fennec-specific part
# Observe we don't clean lists here:
# ouinet/scripts/build-android.sh & mach bootstrap will `apt-get install` things
# and will be unhappy shall there be no install candidates
RUN apt-get -qq update && \
    apt-get install -qqy --no-install-recommends \
      autoconf2.13 \
      openjdk-8-jdk-headless \
      curl \
      bsdtar \
      zip \
      unzip \
      zipalign \
      python \
      python3
# A workaround for ouinet/scripts/build-android.sh & mach bootstrap
# doing apt-get install default-jdk and thus breaking the build
# (Fennec only builds w/JDK8)
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
# mach
ENV SHELL /bin/bash
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
