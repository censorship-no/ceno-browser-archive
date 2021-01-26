#!/bin/bash

# (Fennec = Firefox For Android)

set -e

BUILD_DIR=$(realpath $(pwd))
SOURCE_DIR=$(dirname -- $(dirname -- "$(readlink -f -- "$BASH_SOURCE")"))
SOURCE_DIR_RW=${BUILD_DIR}/source-rw

MOZ_DIR=gecko-dev
L10N_DIR="${SOURCE_DIR}"/mozilla-l10n
# For each locale to be included,
# a commit from the Mercurial repo `https://hg.mozilla.org/l10n-central/<LOCALE>` must be found
# which contains adequate translations for `gecko-dev`.
# As a rule of thumb for Fennec ESR68, look for a commit like
# "Remove obsolete strings and reformat files" from Francesco Lodolo around 2020-08-15,
# and choose the previous one.
#
# Interesting locales and their Mercurial commits:
#
#     [ar]=1c4231166ddf
#     [az]=dd56aead51fa
#     [be]=9d2bff64ddfb
#     [es-ES]=ad1444f4f833
#     [fa]=5a4bb020cf09
#     [fr]=4f9e24a696ee
#     [ko]=963c496ffab2
#     [ru]=3a9587227699
#     [tr]=62ca6a8eaeba
#     [ur]=7d53bce5ae98
#     [vi]=2a000025928a
#     [zh-CN]=be07f660b174
#
# Then a Git mirror must be produced and the equivalent commit
# (or some descendant in the `ceno` branch)
# be used in the submodule placed under `$L10N_DIR`.
LOCALES="en-US $( (cd "$L10N_DIR" && echo *) )"
DIST_DIR="${SOURCE_DIR}"/distribution

IS_RELEASE_BUILD=0
KEYSTORE_FILE=
KEYSTORE_KEY_ALIAS=
KEYSTORE_PASSWORDS_FILE=
OUINET_AAR=
OUINET_CONFIG_XML=
VERSION_NUMBER=

export MOZBUILD_STATE_PATH="${HOME}/.mozbuild"
export PATH="${MOZBUILD_STATE_PATH}/android-sdk-linux/build-tools/29.0.3/:$HOME/.cargo/bin:$PATH"

function usage {
    echo "build-fennec.sh -- Builds ouifennec for android"
    echo "Usage: build-fennec.sh [OPTION]..."
    echo "  -k <keystore-file>            The keystore to use for signing the ouifennec APK. Required."
    echo "  -a <key-alias>                The alias of the key to use for signing the ouifennec APK. Required."
    echo "  -p <keystore-password-file>   The password file containing passwords to unlock the keystore file."
    echo "                                Must contain the password for the keystore, followed by the"
    echo "                                password for the signing key, on separate lines. Required."
    echo "  -o <ouinet-aar>               Filename of the ouinet library AAR file. Required."
    echo "  -r                            Make a release build."
    echo "  -x <ouinet-config-xml>        The ouinet configuration XML file to use."
    echo "  -v <version-number>           Set the ouifennec version number."
    exit 1
}

while getopts k:a:p:o:rx:v: option; do
    case "$option" in
        k)
            [[ -n $KEYSTORE_FILE ]] && usage
            KEYSTORE_FILE="${OPTARG}"
            ;;
        a)
            [[ -n $KEYSTORE_KEY_ALIAS ]] && usage
            KEYSTORE_KEY_ALIAS="${OPTARG}"
            ;;
        p)
            [[ -n $KEYSTORE_PASSWORDS_FILE ]] && usage
            KEYSTORE_PASSWORDS_FILE="${OPTARG}"
            ;;
        o)
            [[ -n $OUINET_AAR ]] && usage
            OUINET_AAR="${OPTARG}"
            ;;
        r)
            IS_RELEASE_BUILD=1
            ;;
        x)
            [[ -n $OUINET_CONFIG_XML ]] && usage
            OUINET_CONFIG_XML="${OPTARG}"
            ;;
        v)
            [[ -n $VERSION_NUMBER ]] && usage
            VERSION_NUMBER="${OPTARG}"
            ;;
        *)
            usage
    esac
done

[[ -z $KEYSTORE_FILE ]] && echo "Missing keystore file" && usage
[[ -z $KEYSTORE_KEY_ALIAS ]] && echo "Missing key alias" && usage
[[ -z $KEYSTORE_PASSWORDS_FILE ]] && echo "Missing keystore password file" && usage
[[ -z $OUINET_AAR ]] && echo "Missing ouinet AAR file" && usage

ABI=${ABI:-armeabi-v7a}
case "$ABI" in
    armeabi-v7a)
        TARGET=arm-linux-androideabi
        ;;
    arm64-v8a)
        TARGET=aarch64
        ;;
    x86_64)
        TARGET=x86_64
        ;;
    x86)
        TARGET=i686
        ;;
    *)
        echo "Unknown ABI: '$ABI', valid values are armeabi-v7a, arm64-v8a, x86 and x86_64."
        exit 1
esac
if [ $IS_RELEASE_BUILD -eq 1 ]; then
    VARIANT=release
else
    VARIANT=debug
fi



ABI_BUILD_DIR="${BUILD_DIR}"/build-${ABI}-${VARIANT}



function mount_cow {
    local WORK_DIR="${BUILD_DIR}"/source-cow-work

    local DO_INITIALIZE
    [[ -e ${SOURCE_DIR_RW} ]] && DO_INITIALIZE=false || DO_INITIALIZE=true
    local IS_MOUNTED
    mount | awk '{ print $3 }' | grep -x -F "$(realpath "${SOURCE_DIR_RW}")" >/dev/null && IS_MOUNTED=true || IS_MOUNTED=false

    mkdir -p "${WORK_DIR}"
    mkdir -p "${SOURCE_DIR_RW}"

    if ! $IS_MOUNTED; then
        unionfs -o cow -o hide_meta_files "${WORK_DIR}"=RW:"${SOURCE_DIR}"=RO "${SOURCE_DIR_RW}"
    fi
    trap "sleep 1 && fusermount -u -z '${SOURCE_DIR_RW}'" EXIT

    if $DO_INITIALIZE; then
        pushd "${SOURCE_DIR_RW}"/${MOZ_DIR} >/dev/null
        ./mach clobber
        popd >/dev/null
    fi
}

function bootstrap_fennec {
    local COOKIE_FILE="${BUILD_DIR}"/.finished-bootstrap
    if [[ -e "${COOKIE_FILE}" ]]; then
        return
    fi

    if ! which rustc >/dev/null; then
        # Install rust https://www.rust-lang.org/en-US/install.html
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        rustup update
        rustup toolchain install 1.37.0
        rustup default 1.37.0
    fi

    pushd "${SOURCE_DIR_RW}"/${MOZ_DIR} >/dev/null
    ./mach bootstrap --application-choice=mobile_android --no-interactive
    popd >/dev/null
    touch "${COOKIE_FILE}"
}

function write_build_config {
    function cp_if_different {
        local from="$1"
        local to="$2"
        cmp -s "$from" "$to" || cp "$from" "$to"
    }

    mkdir -p "${ABI_BUILD_DIR}"
    pushd "${ABI_BUILD_DIR}" >/dev/null

    cat > mozconfig-new <<MOZCONFIG_BASE
export MOZ_TELEMETRY_REPORTING=

# Build Firefox for Android:
ac_add_options --enable-application=mobile/android
ac_add_options --with-android-min-sdk=16
ac_add_options --target=${TARGET}
ac_add_options --without-google-play-services

# With the following Android SDK and NDK
ac_add_options --with-android-sdk="${MOZBUILD_STATE_PATH}/android-sdk-linux"
# Only the NDK version installed by ./mach bootstrap is supported.
ac_add_options --with-android-ndk="${MOZBUILD_STATE_PATH}/android-ndk-r20"

# Only the versions of clang and ld installed by ./mach bootstrap are supported.
CC="${MOZBUILD_STATE_PATH}/clang/bin/clang"
CXX="${MOZBUILD_STATE_PATH}/clang/bin/clang++"
# Use the linker installed by mach instead of the system linker.
ac_add_options --enable-linker=lld

mk_add_options 'export CCACHE_COMPRESS=""'
mk_add_options 'export CCACHE_CPP2=yes'
ac_add_options --with-ccache

mk_add_options MOZ_OBJDIR="${ABI_BUILD_DIR}"

ac_add_options --with-android-distribution-directory="${DIST_DIR}"
ac_add_options --with-l10n-base="${L10N_DIR}"

ac_add_options --disable-crashreporter
# Don't build tests
ac_add_options --disable-tests
ac_add_options --disable-ipdl-tests

MOZCONFIG_BASE

    if [[ $IS_RELEASE_BUILD -eq 1 ]]; then
        echo "export MOZILLA_OFFICIAL=1" >> mozconfig-new
    fi

    if [ "$ABI" == armeabi-v7a -o "$ABI" == x86 -o "$ABI" == x86_64 ]; then
        # See https://mozilla.logbot.info/mobile/20190706#c16442172
        # This can be removed when the bug causing it is fixed.
        echo "ac_add_options --disable-elf-hack" >> mozconfig-new
    fi

    cp_if_different mozconfig-new mozconfig

    popd >/dev/null

    if [[ -n $OUINET_CONFIG_XML ]]; then
        cp_if_different "${OUINET_CONFIG_XML}" "${SOURCE_DIR_RW}"/${MOZ_DIR}/mobile/android/app/src/main/res/values/ouinet.xml
    fi
    if [[ -n $VERSION_NUMBER ]]; then
        echo "${VERSION_NUMBER}" > "${ABI_BUILD_DIR}"/ouifennec-version.txt
        cp_if_different "${ABI_BUILD_DIR}"/ouifennec-version.txt "${SOURCE_DIR_RW}"/${MOZ_DIR}/browser/config/version.txt
        cp_if_different "${ABI_BUILD_DIR}"/ouifennec-version.txt "${SOURCE_DIR_RW}"/${MOZ_DIR}/browser/config/version_display.txt
        #cp_if_different "${ABI_BUILD_DIR}"/ouifennec-version.txt "${SOURCE_DIR_RW}"/${MOZ_DIR}/config/milestone.txt
    fi

    export MOZCONFIG="${ABI_BUILD_DIR}/mozconfig"
    export OUINET_BUILDDIR=$(dirname $(realpath "${OUINET_AAR}"))
    export OUINET_LIBRARY=$(basename "${OUINET_AAR}" .aar)
}

function build_fennec {
    pushd "${ABI_BUILD_DIR}" >/dev/null
    "${SOURCE_DIR_RW}"/${MOZ_DIR}/mach build
    popd >/dev/null
}

function package_fennec {
    pushd "${ABI_BUILD_DIR}" >/dev/null
    "${SOURCE_DIR_RW}"/${MOZ_DIR}/mach package
    if [ $IS_RELEASE_BUILD -eq 1 ]; then
        "${SOURCE_DIR_RW}"/${MOZ_DIR}/mach package-multi-locale --locales ${LOCALES}
        "${SOURCE_DIR_RW}"/${MOZ_DIR}/mach gradle app:assembleWithGeckoBinariesRelease
        BUILT_APK=$(ls -tr "${ABI_BUILD_DIR}"/dist/ceno-*.multi.android-*.apk | tail -1)
    else
        BUILT_APK=$(ls -tr "${ABI_BUILD_DIR}"/dist/ceno-*.android-*.apk | tail -1)
    fi
    popd >/dev/null
}

function sign_apk {
    DESTINATION_APK="${BUILD_DIR}/ceno-${ABI}-${VARIANT}.apk"

    apksigner sign \
        --ks ${KEYSTORE_FILE} \
        --ks-pass "file:${KEYSTORE_PASSWORDS_FILE}" \
        --ks-key-alias "${KEYSTORE_KEY_ALIAS}" \
        --key-pass "file:${KEYSTORE_PASSWORDS_FILE}" \
        --out "${DESTINATION_APK}" \
        "${BUILT_APK}"
}


mount_cow
bootstrap_fennec
write_build_config
build_fennec
package_fennec
sign_apk
