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

If you need to run commands as `root` (e.g. to install additional packages), you can drop the `--user` option and its argument, but be warned that running `./build.sh` as is will create root-owned files and directories in your cache and source directories which you may have problems to reuse or delete later on. To avoid that, you can run `id -u` and `id -g` at the host machine to get your user and group IDs there, then run `gosu HOST_USER_ID:HOST_GROUP_ID ./build.sh` in the container.

If you want to reuse the container itself, remove the `--rm` option and `./build.sh` argument and add `--name SOMETHING`. After exiting the container, run `sudo docker start -ia SOMETHING` to start it again.

Also, please note that running an APK built with the default `ouinet.xml` configuration is quite pointless, but it may help you check that the build succeeds. If you want a useful configuration, copy your `ouinet.xml` file to the current directory and add the parameters `-x ouinet.xml` after `./build.sh`.

# Developer Build
Build the APK locally with the following script:
```
./build.sh -x /path/to/ouinet.xml
```

# To Make A Release Build

Get the upload keystore file and store it in `~/upload-keystore.jks`. Create a file `~/.upload-keystore.pass` that contains the keystore password on the first line and key password on the second line.

**Optional** Update the version number. CENO is currently using the same version as the release of Firefox it is forked from. If you want to change the version, call `build.sh -v <version-number>` to update the relevant numbers in your build.

The *build number* which corresponds to the version code in the APK is automatically generated from the current timestamp so it does not need to manually updated.

In the ouifennec directory:
```
./build.sh -rx /path/to/ouinet.xml
```
Go for lunch while the build compiles.

# Adding language support 
The locales that are included in the APK are defined in `scripts/build-fennec.sh`. To add support for more languages, update the `LOCALES` variable in this script. The l10n files will be downloaded from the Mozilla repo by the build script to `build.fennec/l10n-central/`.

# Uninstall using `adb`

The ceno-browser's application package name is `ie.equalit.ceno` and thus to
uninstall the app one would invoke:

```
$ adb uninstall ie.equalit.ceno
```

# TODO

## Technical

* Get rid of our [`OUINET_QUICK_HACK`](https://github.com/equalitie/gecko-dev/commit/2de7aad32981201d5a75cfbc9c49acf38f21dc0c)
