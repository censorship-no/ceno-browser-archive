#!/bin/bash

set -e

BUILD_DIR=$(pwd)
SOURCE_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

SUPPORTED_ABIS=(armeabi-v7a arm64-v8a x86 x86_64)
RELEASE_DEFAULT_ABIS=(armeabi-v7a arm64-v8a)
DEFAULT_ABI=armeabi-v7a
RELEASE_KEYSTORE_KEY_ALIAS=upload

CLEAN=false
BUILD_RELEASE=false
BUILD_DEBUG=false
BUILD_OUINET=false

ABIS=()
OUINET_CONFIG_XML=
VERSION_NUMBER=
RELEASE_KEYSTORE_FILE=
RELEASE_KEYSTORE_PASSWORDS_FILE=

function usage {
    echo "build.sh -- Builds ouinet and ouifennec for android"
    echo "Usage: build-fennec.sh [OPTION]..."
    echo "  -c                            Remove build files (keep downloaded dependencies)"
    echo "  -r                            Build a release build. Requires -v, -k, and -p."
    echo "  -d                            Build a debug build. Will optionally apply -x and -v. This is the default."
    echo "  -o                            Build ouinet from sources and pass the resulting AAR to build-fennec."
    echo "  -a <abi>                      Build for android ABI <abi>. Can be specified multiple times."
    echo "                                Supported ABIs are [${SUPPORTED_ABIS[@]}]."
    echo "                                Default for debug builds is ${DEFAULT_ABI}."
    echo "                                Default for release builds is all supported ABIs."
    echo "  -x <ouinet-config-xml>        The ouinet configuration XML file to use. Required when building."
    echo "  -v <version-number>           The version number to use on the APK."
    echo "  -k <keystore-file>            The keystore to use for signing the release APK."
    echo "                                Must contain the signing key aliased as '${RELEASE_KEYSTORE_KEY_ALIAS}'."
    echo "  -p <keystore-password-file>   The password file containing passwords to unlock the keystore file."
    echo "                                Must contain the password for the keystore, followed by the"
    echo "                                password for the signing key, on separate lines."
    exit 1
}

while getopts crdoa:x:v:k:p: option; do
    case "$option" in
        c)
            CLEAN=true
            ;;
        r)
            BUILD_RELEASE=true
            ;;
        d)
            BUILD_DEBUG=true
            ;;
        o)
            BUILD_OUINET=true
            ;;
        a)
            supported=false
            for i in ${SUPPORTED_ABIS[@]}; do [[ $i = $OPTARG ]] && supported=true && break; done
            listed=false
            for i in ${ABIS[@]}; do [[ $i = $OPTARG ]] && listed=true && break; done

            if ! $supported; then
                echo "Unknown ABI. Supported ABIs are [${SUPPORTED_ABIS[@]}]."
                exit 1
            fi
            if ! $listed; then
                ABIS+=($OPTARG)
            fi
            ;;
        x)
            [[ -n $OUINET_CONFIG_XML ]] && usage
            OUINET_CONFIG_XML="${OPTARG}"
            ;;
        v)
            [[ -n $VERSION_NUMBER ]] && usage
            VERSION_NUMBER="${OPTARG}"
            ;;
        k)
            [[ -n $RELEASE_KEYSTORE_FILE ]] && usage
            RELEASE_KEYSTORE_FILE="${OPTARG}"
            ;;
        p)
            [[ -n $RELEASE_KEYSTORE_PASSWORDS_FILE ]] && usage
            RELEASE_KEYSTORE_PASSWORDS_FILE="${OPTARG}"
            ;;
        *)
            usage
    esac
done

if $CLEAN; then
    rm *.apk || true
    rm *.aar || true
    rm -rf ouinet-*-{debug,release}/build-android-*-{debug,release} || true
    rm -rf fennec
    exit
fi

$BUILD_RELEASE || $BUILD_DEBUG || BUILD_DEBUG=true

[[ -z $OUINET_CONFIG_XML ]] && echo "Missing ouinet config xml" && usage

if $BUILD_RELEASE; then
    [[ -z $VERSION_NUMBER ]] && echo "Missing version number" && usage
    [[ -z $RELEASE_KEYSTORE_FILE ]] && echo "Missing keystore file" && usage
    [[ -z $RELEASE_KEYSTORE_PASSWORDS_FILE ]] && echo "Missing keystore password file" && usage
fi

if [[ ${#ABIS[@]} -eq 0 ]]; then
    if $BUILD_RELEASE; then
        ABIS=${RELEASE_DEFAULT_ABIS[@]}
    else
        ABIS=($DEFAULT_ABI)
    fi
fi

if $BUILD_DEBUG; then
    DEBUG_KEYSTORE_FILE="${BUILD_DIR}/debug.keystore"
    DEBUG_KEYSTORE_KEY_ALIAS=androiddebugkey
    DEBUG_KEYSTORE_PASSWORDS_FILE="${BUILD_DIR}/debug.keystore-passwords"
    if [[ -e ${DEBUG_KEYSTORE_FILE} && -e ${DEBUG_KEYSTORE_PASSWORDS_FILE} ]]; then
        :
    elif [[ -e ~/.android/debug.keystore ]]; then
        cp ~/.android/debug.keystore "${DEBUG_KEYSTORE_FILE}"
        rm -f "${DEBUG_KEYSTORE_PASSWORDS_FILE}"
        echo android >> ${DEBUG_KEYSTORE_PASSWORDS_FILE}
        echo android >> ${DEBUG_KEYSTORE_PASSWORDS_FILE}
    else
        keytool -genkeypair -keystore "${DEBUG_KEYSTORE_FILE}" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -deststoretype pkcs12 -dname "cn=Unknown, ou=Unknown, o=Unknown, c=Unknown"
        rm -f "${DEBUG_KEYSTORE_PASSWORDS_FILE}"
        echo android >> ${DEBUG_KEYSTORE_PASSWORDS_FILE}
        echo android >> ${DEBUG_KEYSTORE_PASSWORDS_FILE}
    fi
fi

DATE="$(date  +'%Y-%m-%d_%H%m')"
for variant in debug release; do
    if [[ $variant = debug ]]; then
        $BUILD_DEBUG || continue
        KEYSTORE_FILE="$(realpath ${DEBUG_KEYSTORE_FILE})"
        KEYSTORE_KEY_ALIAS="${DEBUG_KEYSTORE_KEY_ALIAS}"
        KEYSTORE_PASSWORDS_FILE="$(realpath ${DEBUG_KEYSTORE_PASSWORDS_FILE})"
        OUINET_VARIANT_FLAGS=
        OUIFENNEC_VARIANT_FLAGS=
    else
        $BUILD_RELEASE || continue
        KEYSTORE_FILE="$(realpath ${RELEASE_KEYSTORE_FILE})"
        KEYSTORE_KEY_ALIAS="${RELEASE_KEYSTORE_KEY_ALIAS}"
        KEYSTORE_PASSWORDS_FILE="$(realpath ${RELEASE_KEYSTORE_PASSWORDS_FILE})"
        OUINET_VARIANT_FLAGS=-r
        OUIFENNEC_VARIANT_FLAGS=-r
    fi

    OUINET_CONFIG_XML="$(realpath ${OUINET_CONFIG_XML})"
    if [[ -n $VERSION_NUMBER ]]; then
        OUIFENNEC_VERSION_NUMBER_FLAGS="-v ${VERSION_NUMBER}"
    else
        OUIFENNEC_VERSION_NUMBER_FLAGS=
    fi

    for ABI in ${ABIS[@]}; do
        if $BUILD_OUINET; then
            OUINET_BUILD_DIR="${BUILD_DIR}/ouinet-${ABI}-${variant}"
            mkdir -p "${OUINET_BUILD_DIR}"
            pushd "${OUINET_BUILD_DIR}" >/dev/null
            ABI=${ABI} "${SOURCE_DIR}"/ouinet/scripts/build-android.sh ${OUINET_VARIANT_FLAGS}
            popd >/dev/null

            OUINET_AAR_BUILT="${OUINET_BUILD_DIR}"/build-android-${ABI}-${variant}/ouinet/outputs/aar/ouinet-${variant}.aar
            OUINET_AAR="$(realpath ${BUILD_DIR}/ouinet-${ABI}-${variant}-${DATE}.aar)"
            cp "${OUINET_AAR_BUILT}" "${OUINET_AAR}"
            OUINET_AAR_BUILT_PARAMS="-o ${OUINET_AAR}"
        fi

        OUIFENNEC_BUILD_DIR="${BUILD_DIR}/fennec"
        mkdir -p "${OUIFENNEC_BUILD_DIR}"
        pushd "${OUIFENNEC_BUILD_DIR}" >/dev/null
        ABI=${ABI} OUINET_VERSION=${OUINET_VERSION} "${SOURCE_DIR}"/scripts/build-fennec.sh \
            -k "${KEYSTORE_FILE}" \
            -a "${KEYSTORE_KEY_ALIAS}" \
            -p "${KEYSTORE_PASSWORDS_FILE}" \
            -x "${OUINET_CONFIG_XML}" \
            ${OUINET_AAR_BUILT_PARAMS} \
            ${OUIFENNEC_VERSION_NUMBER_FLAGS} \
            ${OUIFENNEC_VARIANT_FLAGS}
        popd >/dev/null

        OUIFENNEC_APK_BUILT="${OUIFENNEC_BUILD_DIR}"/ceno-${ABI}-${variant}.apk
        OUIFENNEC_APK="${BUILD_DIR}"/ceno-${ABI}-${variant}-${VERSION_NUMBER}-${DATE}.apk
        cp "${OUIFENNEC_APK_BUILT}" "${OUIFENNEC_APK}"
    done
done

