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
    $ROOT/ouinet/scripts/build-fennec.sh -m $ROOT/gecko-dev -g $MOZ_GIT
    cd -
}

build_ouinet
build_oui_fennec
