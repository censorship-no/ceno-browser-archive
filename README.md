# OuiFennec

A clone of Firefox For Android (Fennec) with Ouinet/Client in it.

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
* Preinstall root certificate given by ouinet/client

## Non technical

* Change icon
* Change package name (currently org.mozilla.fennec_`HOME_DIR`)
* Change description
