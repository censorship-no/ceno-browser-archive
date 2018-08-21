#!/bin/bash

set -e

DIR=`pwd`
SELF=$0
ROOT=$(cd $(dirname $0); pwd)
MOZ_GIT=https://github.com/mozilla/gecko-dev

while getopts m:g: option; do
    case "$option" in
        g) MOZ_GIT=${OPTARG};;
    esac
done

function build_ouinet {
    mkdir -p $DIR/build.ouinet
    cd $DIR/build.ouinet
    $ROOT/ouinet/scripts/build-android.sh
    cd -
}

function build_oui_fennec {
    mkdir -p $DIR/build.fennec
    cd $DIR/build.fennec

    # HACK: This version of Fennec is patched to use the Ouinet library
    # and as such the Fennec build process needs to know where to find
    # that library. Unfortunatelly it's not as easy as passing an argument
    # to gradle (the android build system) because gradle is being executed
    # through the Mozilla's 'mach' script.
    #
    # Thus as a quick hack, we modify the ouinetArchiveDir variable inside
    # the build.gradle build script from here to point to the directory
    # where ouinet-{debug,release}.aar is located.

    local aar_path="$DIR/build.ouinet/build-android/builddir/ouinet/build-android/outputs/aar"
    local gradle_file=$ROOT/gecko-dev/mobile/android/app/build.gradle
    sed -i "s|\(\s*def\s\+ouinetArchiveDir\s*=\s*\).*|\1\"${aar_path}\"|" $gradle_file

    $ROOT/scripts/build-fennec.sh -m $ROOT/gecko-dev -g $MOZ_GIT
    cd -
}

build_ouinet
build_oui_fennec
