# OuiFennec

[![pipeline status](https://gitlab.com/censorship-no/ceno-browser/badges/master/pipeline.svg)](https://gitlab.com/censorship-no/ceno-browser/commits/master)

A clone of Firefox For Android (Fennec) with Ouinet/Client in it.

# Set up injector's parameters

These are currently hardcoded in [ouinet.xml](https://github.com/equalitie/gecko-dev/blob/ouinet/mobile/android/app/src/main/res/values/ouinet.xml)
and can't be changed during the runtime (See TODO).

# Docker Build

This only needs to be run when the Fennec code base is upgraded:

```sh
sudo DOCKER_BUILDKIT=1 docker build --pull \
  -t registry.gitlab.com/censorship-no/ceno-browser:bootstrap .
```

Since that build takes significant time and bandwidth, you may want to try
downloading a pre-built image (still a few gigabytes) instead:

```sh
sudo docker pull registry.gitlab.com/censorship-no/ceno-browser:bootstrap
```

Whenever you build or get a new bootstrap image, you need to create a derived
image to run the build as a normal user:

```sh
sudo DOCKER_BUILDKIT=1 docker build --pull \
  --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) \
  -t registry.gitlab.com/censorship-no/ceno-browser:bootstrap-$USER - < Dockerfile.user
```

To actually build the software, run these:

```sh
mkdir -p _cache/_android _cache/_ccache _cache/_gradle # to hold globally reusable data
mkdir -p fennec && touch fennec/.finished-bootstrap # avoid bootstrap already done above

# Notes on enabling fuse inside docker
# https://stackoverflow.com/questions/48402218/fuse-inside-docker

sudo docker run \
  --rm -it \
  --user $(id -u):$(id -g) \
  --device /dev/fuse --cap-add SYS_ADMIN --security-opt apparmor:unconfined \
  --mount type=bind,source="$(pwd)",target=/usr/local/src/ouifennec \
  --mount type=bind,source="$(pwd)/_cache",target=/root/.cache \
  registry.gitlab.com/censorship-no/ceno-browser:bootstrap-$USER \
  ./build.sh
```

The resulting AAR libraries and APK packages will be eventually left at the current directory.

You can run the last command several times: already built artifacts and cached data will be kept in the `fennec` build and `_cache` directories and reused in subsequent builds. Shall you need to build a new version of the source, you may erase the whole `fennec` build directory, while keeping the `_cache` directory should be safe.

If you want to run arbitrary commands in the container, drop the `./build.sh` argument at the end.

If you need to run commands as `root` (e.g. to install additional packages), you can drop the `--user` option and its argument and use the `.../ceno-browser:bootstrap` image instead of the `bootstrap-$USER` one, but be warned that running `./build.sh` as is will create root-owned files and directories in your build and cache directories which you may have problems to reuse or delete later on. To avoid that, you can run `id -u` and `id -g` at the host machine to get your user and group IDs there, then run `gosu HOST_USER_ID:HOST_GROUP_ID ./build.sh` in the container.

If you want to reuse the container itself, remove the `--rm` option and `./build.sh` argument and add `--name SOMETHING`. After exiting the container, run `sudo docker start -ia SOMETHING` to start it again.

Also, please note that running an APK built with the default `ouinet.xml` configuration is quite pointless, but it may help you check that the build succeeds. If you want a useful configuration, copy your `ouinet.xml` file to the current directory and add the parameters `-x ouinet.xml` after `./build.sh`.

# Developer Build
Build the APK locally with the following script:
```
./build.sh -x /path/to/ouinet.xml
```

# To Make A Release Build

> **Note:** The instructions below must be done at the source directory. Invocations to `./build.sh` may be direct or via the Docker container as explained above.

Before building, you may want to *clean previous build files* by running `./build.sh -c`. This will also remove APK and AAR files in the current directory. If you want to keep these files, please *back them up* elsewhere first.

> **Note:** If you use the Docker container and you cleaned the build files, remember to `touch fennec/.finished-bootstrap` again as explained above before proceeding.

 1. Choose a *version number*. CENO builds with the same version as the release of Firefox it is forked from, but for releases you need to specify an explicit version (like `0.0.42`) to update the relevant numbers in your build. The *build number* which corresponds to the version code in the APK is automatically generated from the current timestamp so it does not need to be manually updated.

 2. Create a `ouinet.xml` file with the *Ouinet client configuration* that will be embedded in CENO.

 3. Choose a set of *target architectures* to build packages for. Currently supported ones are: `armeabi-v7a` (ARM 32 bit), `arm64-v8a` (ARM 64 bit), `x86` (Intel 32 bit), `x86_64` (Intel 64 bit). If none is selected, all of them will be built.

 4. Get the *upload keystore file* and store it in `upload-keystore.jks`. Create a file `upload-keystore.pass` that contains the keystore password on the first line and key password on the second line. Please remember to keep these files private (you may also want to delete them after the build).

Finally run (for release `v0.0.42` and ARM-only packages as an example):

```
./build.sh -rv 0.0.42 -x ouinet.xml \
  -a armeabi-v7a -a arm64-v8a \
  -k upload-keystore.jks -p upload-keystore.pass
```

Go for lunch while the build compiles.

# Adding language support 
The locales that are included in the APK are defined in `scripts/build-fennec.sh`. To add support for more languages, update the `LOCALES` variable in this script. The l10n files will be downloaded from the Mozilla repo by the build script.

# Uninstall using `adb`

The ceno-browser's application package name is `ie.equalit.ceno` and thus to
uninstall the app one would invoke:

```
$ adb uninstall ie.equalit.ceno
```

# Additional Info

We CA certificates usedy by Ouinet are not the system ones because Boost.Asio can't find them. So we're using the ones from https://curl.haxx.se/docs/caextract.html and they are located in gecko-dev/mobile/android/app/src/main/assets/ceno/cacert.pem

The gecko-dev branch we've forked from (and with which it's easiest to merge again) is `esr68`.
