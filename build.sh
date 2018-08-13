#!/bin/bash

set -e

DIR=`pwd`
SELF=$0
ROOT=`dirname $0`

function usage {
    echo "Usage: $SELF <PATH-TO-OUIFENNEC-ROOT>"
}

if [ ! -d "$ROOT" ]; then
    usage
    [ "$ROOT" == "help" ] && return 0 || return 1
fi

(cd $ROOT; git submodule update --init --recursive)

function build_ouinet {
    mkdir -p $DIR/build.ouinet
    cd $DIR/build.ouinet
    $ROOT/ouinet/scripts/build-android.sh
    cd -
}

function build_oui_fennec {
    mkdir -p $DIR/build.fennec
    $ROOT/ouinet/scripts/build-firefox-for-android.sh $ROOT/gecko-dev
    cd -
}

#build_ouinet
build_oui_fennec
