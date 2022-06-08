# <img src="./ceno_logo.png" alt="CENO"> Browser

[![pipeline status](https://gitlab.com/censorship-no/ceno-browser/badges/master/pipeline.svg)](https://gitlab.com/censorship-no/ceno-browser/commits/master)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/censorship-no/ceno-browser)](https://github.com/censorship-no/ceno-browser/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)
[![Weblate](https://hosted.weblate.org/widgets/censorship-no/-/android-strings/svg-badge.svg)](https://hosted.weblate.org/projects/censorship-no/android-strings/)

CENO (Censorship.No!) is a mobile web browser, built on Mozilla's Firefox for Android (Fennec). It uses peer-to-peer technology to deliver websites to your phone and caches popular content with cooperating peers. CENO can be used to bypass Internet censorship and help others retrieve blocked pages.

## ▶️ Access

[<img src="https://play.google.com/intl/en_us/badges/images/generic/en_badge_web_generic.png"
      alt="Get it on Play Store"
      height="80">](https://play.google.com/store/apps/details?id=ie.equalit.ceno)
[<img src="https://github.com/censorship-no/ceno-browser/blob/master/paskoocheh_badge.png"
      alt="Get it on Paskoocheh"
      height="80">](https://paskoocheh.com/tools/124/android.html?utm_source=UpdatePage)
      
## 🚀 Features

🌴 **Browse freely, anytime.**<br>
CENO is designed with internet shutdown scenarios in mind. Websites are shared by a global network of peers, and stored in a distributed cache for availability when traditional networks are blocked or go down.

🔓 **Unlock the web.**<br>
Access any website. Frequently requested content is cached on the network and cannot be forcibly removed.

💲 **Reduce Data Costs.**<br>
By routing user traffic through peer-to-peer networks, CENO Browser incurs less data costs while still providing users with circumvention capability.

🌐 **Grow the Network, Fight Censorship.**<br>
Fight censorship by becoming a bridge! Install and run CENO Browser to instantly join the network and expand the availability of blocked websites to those in censored countries.

👐 **Free and open source.**<br>
CENO Browser is powered by Ouinet, an open source library enabling third party developers to incorporate the CENO network into their apps for peer-to-peer connectivity.

## 👪 Contributing!
Interested in contributing to the project? Great! For starters, make sure to review and agree to the terms of our [Code of Conduct](CODE_OF_CONDUCT.md)

Here are some ways to help CENO Browser improve:
* Test the app with different devices
* Report issues in the [issue tracker](https://github.com/censorship-no/ceno-browser/issues)
* Create a [Pull Request](https://opensource.guide/how-to-contribute/#opening-a-pull-request)
* Help increasing the test coverage by contributing unit tests
* Translate the app on [Weblate](https://hosted.weblate.org/projects/censorship-no/) 

### ➿ Translations
Translation support is needed for:
* Android strings
* the [CENO web extension](https://github.com/censorship-no/ceno-web-ext/)
* The [user manual](https://github.com/censorship-no/ceno-docs/)

We use Weblate for continuously-updated translations. To get started, create an account at https://weblate.org and visit https://hosted.weblate.org/projects/censorship-no/ to join the project.

## 🔧 Building
### Developer Build

The client configuration is currently hardcoded at build time and cannot be changed at run time.  You may customize a copy of the provided `ouinet.sample.xml` with your values, put it in the current directory as `ouinet.xml` (conventionally), and pass it to the invocation of `build.sh` with the option `-x`.  Using `ouinet.sample.xml` as provided is quite pointless, but it may still help you check that the build succeeds.

Thus you can build the APK locally with the following command:

```
./build.sh -x ouinet.xml
```

By default, the latest version of the Ouinet library is automatically downloaded from Maven Central repository and used for building CENO Browser. You can also specify a different Ouinet version by setting `OUINET_VERSION` as follows:

```bash
OUINET_VERSION=0.20.0 ./build.sh -x ouinet.xml
```

You can also build Ouinet locally as part of the CENO Browser build process by using the option `-o` and specifying the target ABIs with the `-a` flag:

```bash
./build.sh -a armeabi-v7a -x ouinet.xml -o
```

### Docker Build

This only needs to be run when the Fennec code base is upgraded:

```sh
sudo DOCKER_BUILDKIT=1 docker build --pull \
  -t registry.gitlab.com/censorship-no/ceno-browser:bootstrap .
```

Since that build takes significant time and bandwidth, you may want to try downloading a pre-built image (still a few gigabytes) instead:

```sh
sudo docker pull registry.gitlab.com/censorship-no/ceno-browser:bootstrap
```

Whenever you build or get a new bootstrap image, you need to create a derived image to run the build as a normal container user with numeric identifiers matching those of your local user (instead of `root`; see below for more information):

```sh
sudo DOCKER_BUILDKIT=1 docker build \
  --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) \
  -t registry.gitlab.com/censorship-no/ceno-browser:bootstrap-$USER - < Dockerfile.user
```

If that command fails with `addgroup: The GID [or UID] '<ID>' is already in use.`, your user's identifiers clash with the image's system ones and you will need to run the build as the container's `root` (see below). This is known to happen under macOS.

To actually build the software as a normal container user, run these:

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
  ./build.sh [BUILD_OPTION]...
```

The resulting AAR libraries and APK packages will be eventually left at the current directory.

You can run the last command several times: already built artifacts and cached data will be kept in the `fennec` build and `_cache` directories and reused in subsequent builds. Shall you need to build a new version of the source, you may erase the whole `fennec` build directory, while keeping the `_cache` directory should be safe. If you are asked for a `root` password after the container starts, the `fennec/.finished-bootstrap` may be missing; if it is not, please file a bug.

If you need to run commands as `root` in the container (e.g. to install additional packages), you can drop the `--user` option and its argument and use the `.../ceno-browser:bootstrap` image instead of the `bootstrap-$USER` one, but be warned that running `./build.sh` as is will create root-owned files and directories in your build and cache directories which you may have problems to reuse or delete later on. To avoid that, you can run `id -u` and `id -g` at the host machine to get your user and group IDs there, then run `gosu HOST_USER_ID:HOST_GROUP_ID ./build.sh` in the container.

If you want to run arbitrary commands in the container, drop the `./build.sh` argument at the end.

If you want to reuse the container itself, remove the `--rm` option and `./build.sh` argument and add `--name SOMETHING`. After exiting the container, run `sudo docker start -ia SOMETHING` to start it again.

### To Make A Release Build

> **Note:** The instructions below must be done at the source directory. Invocations to `./build.sh` may be direct or via the Docker container as explained above.

Before building, it is strongly recommended that you *clean previous build files* by running `./build.sh -c` (otherwise the resulting packages may break in subtle ways). This will also remove APK and AAR files in the current directory. If you want to keep these files, please *back them up* elsewhere first.

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

### Adding support for a language

CENO localization (l10n) is based on Mozilla repositories from <https://hg.mozilla.org/l10n-central/>. For a given `$LOCALE` (like `my` for generic Burmese or `zh-CN` for China's Chinese), we mirror its Mercurial repo to Git and create a `ceno` branch with CENO-specific changes, then use it as a submodule in `ceno-browser`.

```
$ apt-get install git-remote-hg
$ git clone "hg::https://hg.mozilla.org/l10n-central/$LOCALE" mozilla-l10n-$LOCALE,censorship-no
$ cd mozilla-l10n-$LOCALE,censorship-no
$ git remote rename origin upstream
```

Now a GitHub mirror repository `https://github.com/censorship-no/mozilla-l10n-$LOCALE` is created empty and all commits pushed to it:

```
$ git remote add origin "git@github.com:censorship-no/mozilla-l10n-$LOCALE.git"
$ git push --mirror --set-upstream origin
```

A commit in the repo must be found which contains adequate translations for `gecko-dev`. As a rule of thumb for Fennec ESR68, look for a commit like "Remove obsolete strings and reformat files" from Francesco Lodolo around 2020-08-15, and choose the previous one. Let `$BASE_COMMIT` be the Git hash of that commit, then it is used as a base for the `ceno` branch:

```
$ git checkout "$BASE_COMMIT"
$ git checkout -b ceno
$ git push --set-upstream origin ceno
```

Then the default branch of the GitHub repo is switched to `ceno`. Further CENO-specific changes must be pushed to that branch.

To add the language to `ceno-browser`:

```
$ cd /path/to/ceno-browser/mozilla-l10n
$ git submodule add "https://github.com/censorship-no/mozilla-l10n-$LOCALE.git" "$LOCALE"
$ git commit ...
```

The release build (not the debug one) will include the new language.

## ❌ Uninstalling 

**Uninstall using `adb`**

The ceno-browser's application package name is `ie.equalit.ceno` and thus to
uninstall the app one would invoke:

```
$ adb uninstall ie.equalit.ceno
```

## ℹ️ Additional Info

The CA certificates used by Ouinet are not the system ones because Boost.Asio can't find them. So we're using the ones from https://curl.haxx.se/docs/caextract.html and they are located in gecko-dev/mobile/android/app/src/main/assets/ceno/cacert.pem

The gecko-dev branch we've forked from (and with which it's easiest to merge again) is `esr68`.

## 📖 License
All contributions to this repository are considered to be licensed under the [MIT License](/LICENSE).
