#!/usr/bin/env bash
_ARCH=""
_ANDROID_VERSION=23
_SSLPATH=""

function usage() {
    echo
    echo "usage: $1 <-a arch to build: android-arm, android-arm64, ...> -o <openssl root, to find lib and include>"
    echo
}

while getopts "a:o:" arg; do
    case $arg in
    a)
        _ARCH="${OPTARG}"
        ;;
    o)
        _SSLPATH="${OPTARG}"
        _SSLPATH=$(realpath "$_SSLPATH")
        ;;
    *)
        usage "$0"
        exit 1
        ;;

    esac
done

# android ndk must be installed somewhere
if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo "[!] ANDROID_NDK_ROOT must be set to point to the Android NDK (min r21d) !"
    exit 1
fi

if [ -z "$_ARCH" ] || [ -z "$_SSLPATH" ]; then
    usage "$0"
    exit 1
fi

_PWD=$(pwd)

# (download and) build curl
if [ ! -d ./curl ]; then
    echo "[.] downloading curl from github"
    git clone https://github.com/curl/curl
    if [ "$?" -ne 0 ]; then
        exit 1
    fi
fi

cd ./curl
make clean
rm -rf "../build/curl-$_ARCH"
mkdir -p "../build/curl-$_ARCH"
_prefix=$(realpath "../build/curl-$_ARCH")
if [ ! -d "$_SSLPATH" ]; then
    echo "[!] cannot find openssl include and libs must be in $_SSLPATH"
    exit 1
fi

autoreconf -fi
if [ "$?" -ne 0 ]; then
    cd "$_PWD"
    exit 1
fi

if [ "$_ARCH" == 'android-arm64' ]; then
    _target=aarch64-linux-android
    _target2=aarch64-linux-android
else
    _target=arm-linux-androideabi
    _target2=armv7a-linux-androideabi
fi

export NDK="$ANDROID_NDK_ROOT"
export HOST_TAG=linux-x86_64 # use "darwin-x86_64" on mac
export TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/$HOST_TAG"
export AR="$TOOLCHAIN/bin/$_target-ar"
export AS="$TOOLCHAIN/bin/$_target-as"
export CC="$TOOLCHAIN/bin/$_target2$_ANDROID_VERSION-clang"
export CXX="$TOOLCHAIN/bin/$_target2$_ANDROID_VERSION-clang++"
export LD="$TOOLCHAIN/bin/$_target-ld"
export RANLIB="$TOOLCHAIN/bin/$_target-ranlib"
export STRIP="$TOOLCHAIN/bin/$_target-strip"
./configure --host "$_target" --with-pic --prefix "$_prefix" --disable-shared --with-ssl="$_SSLPATH"
if [ "$?" -ne 0 ]; then
    cd "$_PWD"
    exit 1
fi

make -j4
if [ "$?" -ne 0 ]; then
    cd "$_PWD"
    exit 1
fi

# copy to output dir
make install
cd "$_PWD"
