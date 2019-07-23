# OuiFennec

[![pipeline status](https://gitlab.com/censorship-no/ceno-browser/badges/master/pipeline.svg)](https://gitlab.com/censorship-no/ceno-browser/commits/master)

A clone of Firefox For Android (Fennec) with Ouinet/Client in it.

# Set up injector's parameters

These are currently hardcoded in [ouinet.xml](https://github.com/equalitie/gecko-dev/blob/ouinet/mobile/android/app/src/main/res/values/ouinet.xml)
and can't be changed during the runtime (See TODO).

# Docker Build

```sh
sudo DOCKER_BUILDKIT=1 docker build -t registry.gitlab.com/censorship-no/ceno-browser:bootstrap .
mkdir -p root.build/.cache/ root.build/.ccache/ # build cache will be stored in $PWD/ouinet.build, $PWD/ouifennec.build, and $PWD/root.build
sudo docker run --user $(id -u):$(id -g) --mount type=bind,source="$(pwd)",target=/usr/local/src/ouifennec --mount type=bind,source="$(pwd)/root.build/.cache",target=/root/.cache --mount type=bind,source="$(pwd)/root.build/.ccache",target=/root/.ccache registry.gitlab.com/censorship-no/ceno-browser:bootstrap
./build.sh
```

# Developer Build
Build the APK locally with the following script:
```
./build.sh -x /path/to/ouinet.xml
```
You can build Ouinet separately with `./build.sh -o`, and correspondingly, you can build and package just the browser with `./build.sh -fx /path/to/ouinet.xml`

# To Make A Release Build

Get the upload keystore file and store it somewhere outside of VCS.

Create a gradle settings file `~/.gradle/gradle.properties` with the following content. Fill in the correct values for the passwords and path to the keystore.
```
RELEASE_STORE_FILE=/path/to/upload-keystore.jks
RELEASE_STORE_PASSWORD=XXXX
RELEASE_KEY_ALIAS=upload
RELEASE_KEY_PASSWORD=XXXX
```
This is preferable to using the gradle.properties file in gecko-dev as there is no way it can accidently be checked into VCS.

**Optional** Update the version number. CENO is currently using the same version as the release of Firefox it is forked from. If you want to change the version, update the following files:
```
gecko-dev/browser/config/version.txt
gecko-dev/browser/config/version_display.txt
gecko-dev/config/milestone.txt
```
The *build number* which corresponds to the version code in the APK is automatically generated from the current timestamp so it does not need to manually updated.

In the ouifennec directory:
```
./build.sh -rx /path/to/ouinet.xml
```
Go for lunch while the build compiles.

# Adding language support 
The locales that are included in the APK are defined in `scripts/build-fennec.sh`. To add support for more languages, update the `LOCALES` variable in this script. The l10n files will be downloaded from the Mozilla repo by the build script to `build.fennec/l10n-central/`.

# TODO

## Technical

* Set up ouinet with injector's IPFS ID, IP and I2P addresses and
  injector's creadentials.
* Allow setting up Injector's values using QR codes
* Get rid of our [`OUINET_QUICK_HACK`](https://github.com/equalitie/gecko-dev/commit/2de7aad32981201d5a75cfbc9c49acf38f21dc0c)
