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
AUTOCLOBBER=0

RELEASE_KEYSTORE_FILE=~/upload-keystore.jks
RELEASE_KEYSTORE_PASSWORDS=~/.upload-keystore.pass
RELEASE_KEY_ALIAS=upload

export PATH="$HOME/.mozbuild/android-sdk-linux/build-tools/27.0.3/:$HOME/.cargo/bin:$PATH"

while getopts m:g:rn option; do
    case "$option" in
        m) MOZ_DIR=${OPTARG};;
        g) MOZ_GIT=${OPTARG};;
        r) IS_RELEASE_BUILD=1;;
        n) CLOBBER=0;;
    esac
done

ABI=${ABI:-armeabi-v7a}
case "$ABI" in
    armeabi-v7a)
        TARGET=arm-linux-androideabi
        BUILDDIR=obj-arm-unknown-linux-androideabi
        ;;
    arm64-v8a)
        TARGET=aarch64
        BUILDDIR=obj-aarch64-unknown-linux-android
        ;;
    x86_64)
        TARGET=x86_64
        BUILDDIR=obj-x86_64-unknown-linux-android
        ;;
    x86)
        TARGET=i686
        BUILDDIR=obj-i686-unknown-linux-android
        ;;
    *)
        echo "Unknown ABI: '$ABI', valid values are armeabi-v7a, arm64-v8a, x86 and x86_64."
        exit 1
esac

if [ $IS_RELEASE_BUILD -eq 1 -a $CLOBBER -eq 1 ]; then
    AUTOCLOBBER=1
fi

if [ $IS_RELEASE_BUILD -eq 1 ]; then
  BUILDDIR_EXT=-release
fi

if [ $IS_RELEASE_BUILD -eq 1 ]; then
    OUINET_AAR=${OUINET_AAR:-${DIR}/../build.ouinet/build-android-${ABI}-release/ouinet/outputs/aar/ouinet-release.aar}
else
    OUINET_AAR=${OUINET_AAR:-${DIR}/../build.ouinet/build-android-${ABI}/ouinet/outputs/aar/ouinet-debug.aar}
fi
export OUINET_BUILDDIR=$(dirname ${OUINET_AAR})
export OUINET_LIBRARY=$(basename ${OUINET_AAR} .aar)

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
            (cd $LOCALE; hg -q pull)
        fi
    done
}

function write_mozconfig {
    local DIST_DIR=$(realpath $MOZ_DIR/../distribution)
    local L10N_BASE=$DIR/${L10N_DIR}

    local MOZ_OFFICIAL=
    if [ $IS_RELEASE_BUILD -eq 1 ]; then
        MOZ_OFFICIAL="export MOZILLA_OFFICIAL=1 "
    fi

    local ELF_HACK=
    if [ "$ABI" == armeabi-v7a -o "$ABI" == x86 -o "$ABI" == x86_64 ]; then
        # See https://mozilla.logbot.info/mobile/20190706#c16442172
        # This can be removed when the bug causing it is fixed.
        ELF_HACK="ac_add_options --disable-elf-hack"
    fi

    cat > mozconfig <<EOF
export MOZ_INSTALL_TRACKING=
export MOZ_TELEMETRY_REPORTING=
$MOZ_OFFICIAL
# Build Firefox for Android:
ac_add_options --enable-application=mobile/android
ac_add_options --with-android-min-sdk=16
ac_add_options --target=${TARGET}

# With the following Android SDK and NDK
ac_add_options --with-android-sdk="${HOME}/.mozbuild/android-sdk-linux"
# Only the NDK version installed by ./mach bootstrap is supported.
ac_add_options --with-android-ndk="${HOME}/.mozbuild/android-ndk-r17b"

# Only the versions of clang and ld installed by ./mach bootstrap are supported.
CC="${HOME}/.mozbuild/clang/bin/clang"
CXX="${HOME}/.mozbuild/clang/bin/clang++"
# Use the linker installed by mach instead of the system linker.
ac_add_options --enable-linker=lld
${ELF_HACK}

mk_add_options 'export CCACHE_CPP2=yes'
ac_add_options --with-ccache

mk_add_options AUTOCLOBBER=${AUTOCLOBBER}
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj-@CONFIG_GUESS@${BUILDDIR_EXT}

ac_add_options --with-android-distribution-directory="${DIST_DIR}"
ac_add_options --with-l10n-base="${L10N_BASE}"

ac_add_options --disable-crashreporter
# Don't build tests
ac_add_options --disable-tests
ac_add_options --disable-ipdl-tests
EOF
}

################################################################################
(cd $DIR; maybe_install_rust)
(cd $DIR; maybe_download_moz_sources)
clone_or_pull_l10n
################################################################################

## https://developer.mozilla.org/en-US/docs/Mozilla/Developer_guide/Build_Instructions/Simple_Firefox_for_Android_build#I_want_to_work_on_the_back-end

cd $MOZ_DIR
if [ ! -f mozconfig ]; then
    # Install some dependencies and configure Firefox build
    ./mach bootstrap --application-choice=mobile_android --no-interactive
fi

if [ $AUTOCLOBBER -eq 1 ]; then
    # The release build needs a full rebuild to reset the generated build ID timestamp in buildid.h.
    (read -t 10 -p 'This script is about to clobber any intermediate build files and will perform a full rebuild.
This is extrememly slow, so if it is not what you want Ctrl-C this script now, otherwise hit Enter to continue.
If you do not need to update the build number use the -n flag to make a release build without clobbering. > ' || true)
    ./mach clobber
fi

write_mozconfig

# Note: If during building clang crashes, try increasing vagrant's RAM
./mach build
./mach package

if [ $IS_RELEASE_BUILD -eq 1 ]; then
  ./mach package-multi-locale --locales en-US
  ./mach package-multi-locale --locales en-US ${LOCALES}
  ./mach gradle app:assembleWithGeckoBinariesRelease

  APK=$(ls -tr ${BUILDDIR}-release/dist/ceno-*.multi.android-*.apk | tail -1)

  echo "Release APK: "
  ls -al "$(realpath $APK)"

  DATE=$(date  +'%Y-%m-%d_%H%m')
  COMMIT=$(cd ../ && git rev-parse HEAD)
  DEST="${DIR}/ceno_${ABI}_${DATE}_${COMMIT:0:8}.apk"

  apksigner sign \
      --ks "$RELEASE_KEYSTORE_FILE" --ks-pass "file:${RELEASE_KEYSTORE_PASSWORDS}" \
      --ks-key-alias "$RELEASE_KEY_ALIAS" --key-pass "file:${RELEASE_KEYSTORE_PASSWORDS}" \
      --out "$DEST" "$APK"

  echo
  echo "Signed release APK:"
  ls -alh $(realpath $DEST)
else
  APK=$(ls -tr ${BUILDDIR}/dist/ceno-*.android-*.apk | tail -1)

  apksigner sign --ks ~/.android/debug.keystore --ks-pass pass:android \
      --ks-key-alias androiddebugkey --key-pass pass:android "$APK"
  echo
  echo 'Developer APK:'
  ls -al $(realpath $APK)
fi
