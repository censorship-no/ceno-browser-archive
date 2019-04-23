#!/bin/bash

# (Fennec = Firefox For Android)

set -e

DIR=`pwd`
MOZ_DIR=gecko-dev
MOZ_GIT=https://github.com/mozilla/gecko-dev
L10N_DIR=l10n-central
L10N_REPO='https://hg.mozilla.org/l10n-central/'
LOCALES='fa az' # en-US is included by default, you do not need to list it here
IS_RELEASE_BUILD=0
# Do a full rebuild when building the release APK. This is necessary when making a release build for upload to the
# play store as it updates the build number, but it is very slow so if you are making a release build for testing,
# it is unnecessary. Use the command line option -n to disable clobbering.
CLOBBER=1

export PATH="$HOME/.cargo/bin:$PATH"

while getopts m:g:rn option; do
    case "$option" in
        m) MOZ_DIR=${OPTARG};;
        g) MOZ_GIT=${OPTARG};;
        r) IS_RELEASE_BUILD=1;;
        n) CLOBBER=0;;
    esac
done

function install_dependencies {
    local deps="curl mercurial libpulse-dev libpango1.0-dev \
               libgtk-3-dev libgtk2.0-dev libgconf2-dev libdbus-glib-1-dev \
               yasm libnotify-dev libnotify-bin clang-4.0"

    local need_install=0

    for d in $deps; do
        dpkg -s $d >/dev/null || (need_install=1 && break)
    done

    if [ "$need_install" == "1" ]; then
        sudo apt-get update
        sudo apt-get -y install $deps
    fi
}

function maybe_download_moz_sources {
    # Useful for debuggning when we often need to fetch unmodified versions
    # of Mozilla's source tree (which is about 6GB big).
    local keep_copy=0

    # https://developer.mozilla.org/en-US/docs/Mozilla/Developer_guide/Build_Instructions/Simple_Firefox_for_Android_build
    if [ ! -d $MOZ_DIR ]; then
        if [ -d ${MOZ_DIR}-orig ]; then
            cp -r ${MOZ_DIR}-orig $MOZ_DIR
        else
            git clone --recursive $MOZ_GIT $MOZ_DIR

            # I was getting some clang failures past this revision.
            # TODO: Check periodically whether it's been fixed.
            (cd $MOZ_DIR; git checkout 1d1b8fc55142de)

            if [ $keep_copy == "1" ]; then
                cp -r $MOZ_DIR ${MOZ_DIR}-orig
            fi
        fi
    fi
}

function maybe_install_rust {
    if ! which rustc; then
        # Install rust https://www.rust-lang.org/en-US/install.html
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        rustup update
        # https://bugzilla.mozilla.org/show_bug.cgi?id=1384231
        rustup target add armv7-linux-androideabi
    fi
}

function clone_or_pull_l10n {
    cd $DIR
    if [ ! -d $L10N_DIR ]; then
        mkdir $L10N_DIR
    fi
    cd $L10N_DIR
    for LOCALE in $LOCALES; do
        if [ ! -d $LOCALE ]; then
            hg clone ${L10N_REPO}${LOCALE}
        else
            cd $LOCALE
            hg -q pull
            cd -
        fi
    done
}

# The NDK version autogenerated by `mach bootstrap` is specified in
# python/mozboot/mozboot/android.py . Make sure the one in that file
# and the one below are the same.
export NDK_VERSION="r15c"

function write_mozconfig {
    echo -n >  mozconfig

    if [ $IS_RELEASE_BUILD -eq 1 ]; then
      cat >> mozconfig <<EOF
export MOZILLA_OFFICIAL=1
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj-@CONFIG_GUESS@-release

EOF
    fi
    local DIST_DIR=$(realpath $MOZ_DIR/../distribution)
    local L10N_BASE=$DIR/${L10N_DIR}

    cat >> mozconfig <<EOL
export MOZ_INSTALL_TRACKING=
export MOZ_TELEMETRY_REPORTING=

# Build Firefox for Android:
ac_add_options --enable-application=mobile/android
ac_add_options --with-android-min-sdk=16
ac_add_options --target=arm-linux-androideabi

# With the following Android SDK and NDK:
ac_add_options --with-android-sdk="$HOME/.mozbuild/android-sdk-linux"
ac_add_options --with-android-ndk="$HOME/.mozbuild/android-ndk-${NDK_VERSION}"

ac_add_options --with-android-distribution-directory=${DIST_DIR}
ac_add_options --with-l10n-base=${L10N_BASE}

ac_add_options --disable-crashreporter
# Don't build tests
ac_add_options --disable-tests
ac_add_options --disable-ipdl-tests
EOL
}

################################################################################
install_dependencies
cd $DIR; maybe_install_rust; cd -
cd $DIR; maybe_download_moz_sources; cd -
clone_or_pull_l10n
################################################################################

cd ${MOZ_DIR}

## https://developer.mozilla.org/en-US/docs/Mozilla/Developer_guide/Build_Instructions/Simple_Firefox_for_Android_build#I_want_to_work_on_the_back-end

if [ ! -f mozconfig ]; then
    # Install some dependencies and configure Firefox build
    ./mach bootstrap --application-choice=mobile_android --no-interactive
fi
if [ $IS_RELEASE_BUILD -eq 1 -a $CLOBBER -eq 1 ]; then
  # The release build needs a full rebuild to reset the generated build ID timestamp in buildid.h.
  read -p 'This script is about to clobber any intermediate build files and will perform a full rebuild.
This is extrememly slow, so if it is not what you want Ctrl-C this script now, otherwise hit Enter to continue.
If you do not need to update the build number use the -n flag to make a release build without clobbering. > '
  ./mach clobber
fi
write_mozconfig

# Note: If during building clang crashes, try increasing vagrant's RAM
./mach build
./mach package
./mach package-multi-locale --locales en-US ${LOCALES}

if [ $IS_RELEASE_BUILD -eq 1 ]; then
  ./mach gradle app:assembleWithGeckoBinariesRelease
  echo
  echo "Signed release APK:"
  ls -alh $(realpath obj-arm-linux-androideabi-release/gradle/build/mobile/android/app/outputs/apk/withGeckoBinaries/release/app-withGeckoBinaries-release.apk)
else
  echo 'Result APKs:'
  find $(realpath obj-arm-linux-androideabi/dist) -maxdepth 1 -name '*multi*arm.apk'
fi
