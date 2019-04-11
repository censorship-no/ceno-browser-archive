# OuiFennec

A clone of Firefox For Android (Fennec) with Ouinet/Client in it.

# Set up injector's parameters

These are currently hardcoded in [ouinet.xml](https://github.com/equalitie/gecko-dev/blob/ouinet/mobile/android/app/src/main/res/values/ouinet.xml)
and can't be changed during the runtime (See TODO).

To change the icon name, change the `MOZ_APP_DISPLAYNAME` variable in
`gecko-dev/mobile/android/branding/unofficial/configure.sh`

# Build

```sh
sudo docker build -t ceno - < Dockerfile
mkdir -p root.build/.mozbuild # build cache will be stored in $PWD/ouinet.build, $PWD/ouifennec.build, and $PWD/root.build
sudo docker run --rm -it --mount type=bind,source="$(pwd)",target=/usr/local/src/ouifennec --mount type=bind,source="$(pwd)/root.build",target=/root ceno
cd ouifennec
./build.sh
```

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

Update the build version in the following files:
```
gecko-dev/browser/config/version.txt
gecko-dev/browser/config/version_display.txt
gecko-dev/config/milestone.txt
```

In the ouifennec directory:
```
./build -r
```
Go for lunch while the build compiles.

# TODO

## Technical

* Set up ouinet with injector's IPFS ID, IP and I2P addresses and
  injector's creadentials.
* Allow setting up Injector's values using QR codes
* Get rid of our [`OUINET_QUICK_HACK`](https://github.com/equalitie/gecko-dev/commit/2de7aad32981201d5a75cfbc9c49acf38f21dc0c)
