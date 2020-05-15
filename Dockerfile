# syntax=docker/dockerfile:experimental

# Use this configuration to build CENO
# with a root user inside of the build container.

FROM registry.gitlab.com/equalitie/ouinet:android

WORKDIR /usr/local/src/ouifennec
# Required by some task in Fennec bootstrap.
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
  # Enable ARMv7 Android target,
  # see <https://bugzilla.mozilla.org/show_bug.cgi?id=1384231>.
  # Also note that `ensure_rust_targets` during bootstrap below
  # adds target `thumbv7neon-linux-androideabi` instead of this one for Rust >= 1.33.
  # That one might work for us, but it still needs testing.
  ~/.cargo/bin/rustup target add armv7-linux-androideabi

RUN apt-get update && apt-get install -y ccache gosu ninja-build unionfs-fuse libnotify-bin

RUN --mount=type=bind,target=/usr/local/src/ouifennec,ro \
  cd gecko-dev && \
  # This would need to be invoked twice if we hadn't installed Rust above,
  # so that `gecko-dev/python/mozboot/mozboot/base.py::ensure_rust_targets` gets called.
  # It won't normally due to logic being such:
  # `have_rust ? ensure_rust_targets() : install_rust()`
  # (note no ensure targets in second branch).
  ./mach bootstrap --application-choice=mobile_android --no-interactive

# Move all dot directories that will be receiving reusable data during the build
# into a single directory (with symbolic links from the expected locations),
# so that the directory can be bind-mounted outside
# and data reused between different runs.
# Please note that the bind-mounted directory
# should already contain the subdirectories listed below.
RUN \
  cd ~ && \
  mkdir -p .android .ccache .gradle .cache && \
  mv .android .cache/_android && ln -s .cache/_android .android && \
  mv .ccache  .cache/_ccache  && ln -s .cache/_ccache  .ccache && \
  mv .gradle  .cache/_gradle  && ln -s .cache/_gradle  .gradle
