#!/bin/bash

set -e

DIR=`pwd`
SELF=$0
ROOT=$(cd $(dirname $0); pwd)
MOZ_GIT=https://github.com/mozilla/gecko-dev
BUILD_OUINET=0
BUILD_FENNEC=0
RELEASE_BUILD=
NO_CLOBBER=
while getopts rofg:x:n option; do
    case "$option" in
    g) MOZ_GIT=${OPTARG};;
    r) RELEASE_BUILD=-r;;
    o) BUILD_OUINET=1;;
    f) BUILD_FENNEC=1;;
    n) NO_CLOBBER=-n;;
    x) OUINET_VALUES_XML=${OPTARG};;
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

function build_ouinet {
    mkdir -p $DIR/build.ouinet
    cd $DIR/build.ouinet
    $ROOT/ouinet/scripts/build-android.sh $RELEASE_BUILD
    cd - > /dev/null
}

function build_oui_fennec {
    mkdir -p $DIR/build.fennec
    cd $DIR/build.fennec
    $ROOT/scripts/build-fennec.sh -m $ROOT/gecko-dev -g $MOZ_GIT $RELEASE_BUILD $NO_CLOBBER
    cd - > /dev/null
}

if [[ $BUILD_OUINET -eq 1 ]]; then
  build_ouinet
fi
if [[ $BUILD_FENNEC -eq 1 ]]; then
  build_oui_fennec
fi
