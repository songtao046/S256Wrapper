#!/bin/bash

VERSION="v0.6.0"
URL="https://github.com/bitcoin-core/secp256k1/archive/refs/tags/$VERSION.zip"
ARCHIVE="secp256k1-$VERSION.zip"
DIR="secp256k1"

# download secp256k1 source code
if [ ! -f "$ARCHIVE" ]; then
    curl -L $URL -o $ARCHIVE
fi

# 解压缩
if [ ! -d "$DIR" ]; then
    unzip $ARCHIVE -d temp_folder
    mv temp_folder/* $DIR
    rm -r temp_folder
    rm -r $ARCHIVE
fi


cd $DIR
# clean previous build
make clean

# set env
IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
SIM_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
CFLAGS="-isysroot $IOS_SDK -arch arm64 -miphoneos-version-min=10.0"
SIM_CFLAGS="-isysroot $SIM_SDK -arch x86_64 -mios-simulator-version-min=10.0"

# build for ios device
./autogen.sh
./configure --host=arm-apple-darwin --enable-module-recovery --disable-shared --enable-static CFLAGS="$CFLAGS"
make
cp .libs/libsecp256k1.a libsecp256k1-ios.a

# clean and build for ios simulator
make clean
./configure --host=x86_64-apple-darwin --enable-module-recovery --disable-shared --enable-static CFLAGS="$SIM_CFLAGS"
make
cp .libs/libsecp256k1.a libsecp256k1-sim.a

# lipo
lipo -create -output libsecp256k1-fat.a libsecp256k1-ios.a libsecp256k1-sim.a
echo "lipo success: libsecp256k1.a"

cp libsecp256k1-fat.a ../Sources/libsecp256k1.a


