# syntax=docker/dockerfile:experimental
FROM registry.gitlab.com/equalitie/ouinet:android
WORKDIR /usr/local/src/ouifennec
ENV HOME /mnt/home
ENV SHELL /bin/bash
RUN \
  # Bootstrapping below installs the latest version of Rust,
  # which may break the build,
  # so pin one that we know works.
  # See <https://bugzilla.mozilla.org/show_bug.cgi?id=1585099>.
  wget -q -O- https://sh.rustup.rs | sh -s -- -y && \
  ~/.cargo/bin/rustup update && \
  ~/.cargo/bin/rustup toolchain install 1.37.0 && \
  ~/.cargo/bin/rustup default 1.37.0
RUN \
  # See <https://bugzilla.mozilla.org/show_bug.cgi?id=1384231>.
  ~/.cargo/bin/rustup target add armv7-linux-androideabi
RUN apt-get update && apt-get install -y ccache gosu ninja-build libnotify4
RUN --mount=type=bind,target=/usr/local/src/ouifennec,rw \
  cd gecko-dev && \
  ./mach bootstrap --application-choice=mobile_android --no-interactive && \
  # Invoke twice to make sure gecko-dev/python/mozboot/mozboot/base.py::
  # ensure_rust_targets() gets called. It won't normally due to logic being such:
  # have_rust ? ensure_rust_targets() : install_rust() (note no ensure targets
  # in second branch). See gecko-dev/python/mozboot/mozboot/base.py L652.
  ./mach bootstrap --application-choice=mobile_android --no-interactive && \
  cd .. && \
  ./ouinet/scripts/build-android.sh bootstrap && \
  ~/.cargo/bin/cargo install sccache && \
  chmod -R 777 ~
