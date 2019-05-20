FROM registry.gitlab.com/equalitie/ouinet:android as bundle
COPY . /usr/local/src/ouifennec/

FROM bundle as bootstrap-bundle
WORKDIR /usr/local/src/ouifennec
ENV SHELL /bin/bash
RUN cd gecko-dev && \
  ./mach bootstrap --application-choice=mobile_android --no-interactive && \
  # Invoke twice to make sure gecko-dev/python/mozboot/mozboot/base.py::
  # ensure_rust_targets() gets called. It won't normally due to logic being such:
  # have_rust ? ensure_rust_targets() : install_rust() (note no ensure targets
  # in second branch). See gecko-dev/python/mozboot/mozboot/base.py L652.
  ./mach bootstrap --application-choice=mobile_android --no-interactive && \
  # Touch mozconfig so that scripts/build-fennec.sh doesn't rerun bootstrap
  touch mozconfig && \
  cd .. && \
  # we don't need git data after ./mach bootstrap, so free some space
  find -maxdepth 2 -name '.git' -type d -exec rm -rf {} +

FROM bootstrap-bundle as bootstrap
RUN rm -rf ./*

FROM bootstrap-bundle as build
RUN ./build.sh
