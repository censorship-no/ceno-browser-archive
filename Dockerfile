FROM registry.gitlab.com/equalitie/ouinet:android
RUN wget https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -O - | \
    python - --application-choice=mobile_android --no-interactive \
    || true # gecko-dev/python/mozboot/mozboot/bootstrap.py::maybe_install_private_packages_or_exit only works on repo checkout, so we cannot complete bootstrap fully here
# mach
ENV SHELL /bin/bash
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
