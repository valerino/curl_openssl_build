#!/usr/bin/env bash
_ARCH=""
function usage() {
    echo
    echo "usage: $1 <-a arch to build: android-arm, android-arm64, ...>"
    echo
}

while getopts "a:" arg; do
    case $arg in
    a)
        _ARCH="${OPTARG}"
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

if [ -z "$_ARCH" ]; then
    usage "$0"
    exit 1
fi

_PWD=$(pwd)

# (download and) build openssl
if [ ! -d ./openssl ]; then
    echo "[.] downloading openssl from github"
    git clone https://github.com/openssl/openssl
    if [ "$?" -ne 0 ]; then
        exit 1
    fi
fi
cd ./openssl
make clean
rm -rf "../build/openssl-$_ARCH"
mkdir -p "../build/openssl-$_ARCH"
_prefix=$(realpath "../build/openssl-$_ARCH")
PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH
./Configure "$_ARCH" -D__ANDROID_API__=22 --prefix="$_prefix"
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

