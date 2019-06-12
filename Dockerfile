# syntax=docker/dockerfile:experimental
FROM registry.gitlab.com/equalitie/ouinet:android
WORKDIR /usr/local/src/ouifennec
ENV HOME /mnt/home
ENV SHELL /bin/bash
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
  apt-get install -y ccache && \
  /mnt/home/.cargo/bin/cargo install sccache && \
  chmod -R 777 /mnt/home
