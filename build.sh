#!/bin/bash

set -e
set -x

DIR=`pwd`
ROOT=$(cd $(dirname $0); pwd)
MOZ_GIT=https://github.com/mozilla/gecko-dev
BUILD_OUINET=0
BUILD_FENNEC=0
RELEASE_BUILD=
NO_CLOBBER=
TARGETS=()
while getopts rofng:x:t: option; do
    case "$option" in
        r) RELEASE_BUILD=-r;;
        o) BUILD_OUINET=1;;
        f) BUILD_FENNEC=1;;
        n) NO_CLOBBER=-n;;
        g) MOZ_GIT=${OPTARG};;
        x) OUINET_VALUES_XML=${OPTARG};;
        t) TARGETS+=("$OPTARG");;
        *) echo "Error processing options" >&2; exit 1;;
    esac
done

if [[ -n "$OUINET_VALUES_XML" ]]; then
    if [[ ! -f "$OUINET_VALUES_XML" ]]; then
        echo "No such xml file '$OUINET_VALUES_XML'"
        exit 1
    fi
    cp $OUINET_VALUES_XML $ROOT/gecko-dev/mobile/android/app/src/main/res/values/ouinet.xml
fi

if [[ $BUILD_OUINET -eq 0 && $BUILD_FENNEC -eq 0 ]]; then
  # Build both if neither specified
  BUILD_OUINET=1
  BUILD_FENNEC=1
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    #Use default values for targets
    if [[ -n "$RELEASE_BUILD" ]]; then
        # Build both targets when making the release build if none are specified
        TARGETS=(armeabi-v7a arm64-v8a)
    else
        TARGETS=(armeabi-v7a)
    fi
fi

function maybe_build_ouinet {
    if [[ $BUILD_OUINET -ne 1 ]]; then
        return
    fi
    mkdir -p $DIR/build.ouinet
    (cd $DIR/build.ouinet; ABI=$ABI $ROOT/ouinet/scripts/build-android.sh $RELEASE_BUILD)
}

function maybe_build_ouifennec {
    if [[ $BUILD_FENNEC -ne 1 ]]; then
        return
    fi
    mkdir -p $DIR/build.fennec
    (cd $DIR/build.fennec; ABI=$ABI $ROOT/scripts/build-fennec.sh -m $ROOT/gecko-dev -g $MOZ_GIT $RELEASE_BUILD $NO_CLOBBER)
}

for ABI in "${TARGETS[@]}"; do
    maybe_build_ouinet
    maybe_build_ouifennec
done
