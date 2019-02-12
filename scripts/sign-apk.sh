set -Eex

usage() {
    cat <<USAGE
Example usage:
    export KEYSTORE_PATH=/tmp/a
    export KEY_ALIAS=staging
    export KEYSTORE_PASSWORD=pass
    export KEY_PASSWORD=ssap

    $(basename $0) gecko-dev/obj-arm-linux-androideabi/dist/ceno-64.0.1.en-US.android-arm-unsigned-unaligned.apk

USAGE
    exit 0
}

[ -z $1 ] && { usage; }

# Generate keystore (interactive; -alias sets this key's alias inside store)
# keytool -genkey -v -keystore "$KEYSTORE_PATH" -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 -alias "$KEY_ALIAS"

# See https://wiki.mozilla.org/Mobile/Fennec/Android/AdvancedTopics#Sign_a_Fennec_build
jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" -keypass "$KEY_PASSWORD" "$1" "$KEY_ALIAS" -signedjar "$1.signed"
zipalign -f -v 4 "$1.signed" "$1.signed.aligned"

# Result
echo 'APK ready at:'
ls "$1.signed.aligned"
