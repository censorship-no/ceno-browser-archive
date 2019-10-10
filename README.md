# OuiFennec

[![pipeline status](https://gitlab.com/censorship-no/ceno-browser/badges/master/pipeline.svg)](https://gitlab.com/censorship-no/ceno-browser/commits/master)

A clone of Firefox For Android (Fennec) with Ouinet/Client in it.

# Set up injector's parameters

These are currently hardcoded in [ouinet.xml](https://github.com/equalitie/gecko-dev/blob/ouinet/mobile/android/app/src/main/res/values/ouinet.xml)
and can't be changed during the runtime (See TODO).

# Docker Build

```sh
sudo DOCKER_BUILDKIT=1 docker build -t registry.gitlab.com/censorship-no/ceno-browser:bootstrap .
touch gecko-dev/mozconfig # avoid bootstrap already done above
mkdir -p root.build/.cache/ root.build/.ccache/ # build cache will be stored in $PWD/ouinet.build, $PWD/ouifennec.build, and $PWD/root.build
sudo docker run \
  --rm -it \
  --user $(id -u):$(id -g) \
  --mount type=bind,source="$(pwd)",target=/usr/local/src/ouifennec \
  --mount type=bind,source="$(pwd)/root.build/.cache",target=/root/.cache \
  --mount type=bind,source="$(pwd)/root.build/.ccache",target=/root/.ccache \
  registry.gitlab.com/censorship-no/ceno-browser:bootstrap \
  ./build.sh
```

You can run the last command several times, and already built artifacts will be kept in different cache directories under the current directory and reused.

If you want to run arbitrary commands in the container, drop the `./build.sh` argument at the end.

If you need to run commands as `root` (e.g. to install additional packages), you can drop the `--user` option and its argument, but be warned that running `./build.sh` will create root-owned files and directories in your cache and source directories which you may have problems to reuse or delete later on.

If you want to reuse the container itself, remove the `--rm` option and `./build.sh` argument and add `--name SOMETHING`. After exiting the container, run `sudo docker start -ia SOMETHING` to start it again.

# Developer Build
Build the APK locally with the following script:
```
./build.sh -x /path/to/ouinet.xml
```
You can build Ouinet separately with `./build.sh -o`, and correspondingly, you can build and package just the browser with `./build.sh -fx /path/to/ouinet.xml`

# To Make A Release Build

Get the upload keystore file and store it in `~/upload-keystore.jks`. Create a file `~/.upload-keystore.pass` that contains the keystore password on the first line and key password on the second line.

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
