# OuiFennec

A clone of Firefox For Android (Fennec) with Ouinet/Client in it.

# Set up injector's parameters

These are currently hardcoded in [ouinet.xml](https://github.com/equalitie/gecko-dev/blob/ouinet/mobile/android/app/src/main/res/values/ouinet.xml)
and can't be changed during the runtime (See TODO).

# Build

    $ vagrant up
    $ vagrant ssh
    vagrant $ git clone /vagrant ouifennec
    vagrant $ git submodule update --init --recursive
    vagrant $ cd ouifennec
    vagrant $ ./build.sh

# TODO

## Technical

* Set up ouinet with injector's IPFS ID, IP and I2P addresses and
  injector's creadentials.
* Try to get rid of the prompt asking to install Ouinet/Client's CA Root
  certificate
* Allow setting up Injector's values using QR codes
* Get rid of our [`OUINET_QUICK_HACK`](https://github.com/equalitie/gecko-dev/commit/2de7aad32981201d5a75cfbc9c49acf38f21dc0c)

## Non technical

* Change icon
* Change package name (currently org.mozilla.fennec_`HOME_DIR`)
* Change description
