# syntax=docker/dockerfile:experimental
FROM registry.gitlab.com/equalitie/ouinet:android
WORKDIR /usr/local/src/ouifennec
ENV SHELL /bin/bash
RUN --mount=type=bind,target=/usr/local/src/ouifennec,rw \
  cd gecko-dev && \
  ./mach bootstrap --application-choice=mobile_android --no-interactive && \
  # Invoke twice to make sure gecko-dev/python/mozboot/mozboot/base.py::
  # ensure_rust_targets() gets called. It won't normally due to logic being such:
  # have_rust ? ensure_rust_targets() : install_rust() (note no ensure targets
  # in second branch). See gecko-dev/python/mozboot/mozboot/base.py L652.
  ./mach bootstrap --application-choice=mobile_android --no-interactive && \
  # Touch mozconfig so that scripts/build-fennec.sh doesn't rerun bootstrap
  touch mozconfig && \
  cd .. && \
  apt-get install -y ccache && \
  /root/.cargo/bin/cargo install sccache
