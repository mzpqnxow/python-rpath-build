#!/bin/bash
#
# Simple script to build Python3 and use RPATH $ORIGIN linking
# Helpful when you need a Python build that supportss an arbitrary-ish OpenSSL
# version and/or when you want to override your "system" OpenSSL library without
# needing to set LD_LIBRARY_PATH (or /etc/ld.so.*, which have system-wide impact)
#
# You will need to specify where your OpenSSL libraries are, and if they aren't one directory
# up from the Python prefix, you may need to make modifications. I use this pattern for
# installations from source:
#
#  /opt
#    - openssl1.1.1j
#    - openssl1.1.1k/
#    - Python3.9/
#    - Python3.10/
#    - Python3.8/
#
# The $ORIGIN when the Python ELF loads will be /opt/Python3.9/bin, so the
# Python link step uses the following two in the RPATH:
#
#   $ORIGIN/../lib
#   $ORIGIN/../../openssl1.1.1k/lib
#

# As with any other Python build from source, you'll need various headers and
# libraries for things like zlib, ncurses and so on. You'll also need a compiler
# and wget, etc. On Debian-based distributions, this should get most of that
# stuff:
#
#   sudo apt-get install -y \
#     build-essential wget \
#     zlib1g-dev libdb5.3-dev libncurses-dev \
#     libsqlite3-dev libgdbm-dev libgdbm-compat-dev
#
#
# 3.7.x, 3.8.x, 3.9.x, 3.10.x and 3.11.x should all support the configure flags
# used in this script. On most systems, this should Just Work (TM)
#
#
# YMMV, this is really not intended for use by anyone other than me
#
#
# - AG
set -u

# If you specify an argument to this script, it will use that version
# Otherwise it will use this one:
DEFAULT_PY_V="3.8.17"
# Prefix for the custom build of OpenSSL and for the new build of Python3
PREFIX="/opt"
# OpenSSL must have already been built and install to this location
OPENSSL_V=1.1.1k
# If 1, sudo make install will be executed automatically to install
# the build when complete
DO_INSTALL=1
# For optimized/special builds, set to 0
# Otherwise use 1 to avoid potential build issues on some platforms/distros
DISABLE_SYSTEM_MPDEC=1
# WARN: Enabling optimizations will force length post-build tests, significantly
# slowing down the build process
ENABLE_OPTIMIZATIONS=0

# --- DO NOT CHANGE ANYTHING BELOW THIS LINE ---

if [ "$ENABLE_OPTIMIZATIONS" -eq 1 ]; then
    optimizations="--enable-optimizations"
fi

if [ $DISABLE_SYSTEM_MPDEC -eq 1 ]; then
    system_mpdec="--without-system-libmpdec"
else
    system_mpdec="--with-system-libmpdec"
fi


OPENSSL_ROOT="$PREFIX/openssl-$OPENSSL_V"
OPENSSL_RPATH="../../openssl-$OPENSSL_V/lib"
# For 3.8.17
FULL_V=${1:-$DEFAULT_PY_V}
# MAJOR_V=$(echo $FULL_V | cut -d '.' -f 1)
# MINOR_V=$(echo $FULL_V | cut -d '.' -f 2)
# REV_V=$(echo $FULL_V | cut -d '.' -f 3)
PY_RPATH="../lib"
tarball=Python-"$FULL_V".tar.xz
url=https://www.python.org/ftp/python/$FULL_V/Python-"$FULL_V".tar.xz

set -e
wget -c "$url"
# rm -rf "$(basename "$tarball" .tar.xz)"
tar -xvf "$tarball"
pushd "$(basename "$tarball" .tar.xz)"
set +e


# Only added to recent versions, so we don't use it
#   --with-openssl-rpath=auto

LDFLAGS="-Wl,-rpath,'\$\$ORIGIN/$PY_RPATH' -Wl,-rpath,'\$\$ORIGIN/$OPENSSL_RPATH'" ./configure \
  --enable-shared \
  --prefix=/opt/Python-"$FULL_V" \
  --enable-ipv6 \
  --enable-loadable-sqlite-extensions \
  --with-dbmliborder=bdb:gdbm \
  --with-ensurepip \
  --with-system-expat \
  $system_mpdec \
  --with-system-ffi \
  --with-openssl="$OPENSSL_ROOT" \
  --with-ssl-default-suites=openssl \
  ${optimizations:-} \
  --disable-test-modules \
  --with-system-expat

if [ $? -ne 0 ]; then
  echo "The configure step failed, sorry !!"
  exit 1
fi

if ! make -j; then
  echo "The build failed, sorry !!"
  echo "Used the following 'special' configure options:"
  echo "$system_mpdec ${optimizations:-}"
  read -p "Press enter to exit ..." ok
  exit 1
fi

# if [ $DO_INSTALL -eq 0 ]; then
#   echo "Build complete, please manually install from $PWD using 'sudo make install'"
#   read -p "Press enter to exit ..." ok
# fi
sudo make install

read -p "Installation complete; Press enter to exit ..." ok