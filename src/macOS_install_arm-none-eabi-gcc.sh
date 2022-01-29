#!/bin/bash

MYPATH=$(realpath `dirname "$0"`)
ARCHIVESPATH="${MYPATH}/archives"
SRCPATH="${MYPATH}/src"
TARGET=arm-none-eabi
DSTPATH="${MYPATH}/${TARGET}"

# Script to install gcc as described on 
# http://retroramblings.net/?p=315

BINUTILS_VERSION=binutils-2.27
BINUTILS_ARCHIVE=${BINUTILS_VERSION}.tar.bz2
BINUTILS_MD5=2869c9bf3e60ee97c74ac2a6bf4e9d68

GCC_VERSION=gcc-5.2.0
GCC_ARCHIVE=${GCC_VERSION}.tar.bz2
GCC_MD5=a51bcfeb3da7dd4c623e27207ed43467

NEWLIB_VERSION=newlib-2.2.0
NEWLIB_ARCHIVE=${NEWLIB_VERSION}.tar.gz
NEWLIB_MD5=f2294ded26e910a73637ecdfbdd1ef05

mkdir -p "${ARCHIVESPATH}"
mkdir -p "${SRCPATH}"
mkdir -p "${DSTPATH}"

cd "${ARCHIVESPATH}"

if [ ! -f ${BINUTILS_ARCHIVE} ]; then
    echo "Downloading ${BINUTILS_ARCHIVE} ..."
    curl -OL ftp://ftp.fu-berlin.de/unix/gnu/binutils/${BINUTILS_ARCHIVE}
fi

if [ `md5sum -b ${BINUTILS_ARCHIVE} | cut -d* -f1` != ${BINUTILS_MD5} ]; then
    echo "Archive is broken: $BINUTILS_ARCHIVE"
    exit 1;
fi

if [ ! -f ${GCC_ARCHIVE} ]; then
    echo "Downloading ${GCC_ARCHIVE} ..."
    curl -OL ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-5.2.0/${GCC_ARCHIVE}
fi

if [ `md5sum -b ${GCC_ARCHIVE} | cut -d* -f1` != ${GCC_MD5} ]; then
    echo "Archive is broken: $GCC_ARCHIVE"
    exit 1;
fi

if [ ! -f ${NEWLIB_ARCHIVE} ]; then
    echo "Downloading ${NEWLIB_ARCHIVE} ..."
    curl -OL ftp://sourceware.org/pub/newlib/${NEWLIB_ARCHIVE}
fi

if [ `md5sum -b ${NEWLIB_ARCHIVE} | cut -d* -f1` != ${NEWLIB_MD5} ]; then
    echo "Archive is broken: $NEWLIB_ARCHIVE"
    exit 1;
fi

cd "${MYPATH}"

# ------------------------ build binutils ------------------
echo "Building ${BINUTILS_VERSION}"

if [ -d "${SRCPATH}/${BINUTILS_VERSION}" ]; then
    echo "Cleaning up previous build ..."
    rm -rf "${SRCPATH}/${BINUTILS_VERSION}"
fi

tar xfj "${ARCHIVESPATH}/${BINUTILS_ARCHIVE}" -C "${SRCPATH}"
cd "${SRCPATH}/${BINUTILS_VERSION}"
mkdir "${TARGET}"
cd "${TARGET}"
../configure --target="${TARGET}" --prefix="${DSTPATH}"
make
make install

# ------------------------ build gcc ------------------
export PATH="${DSTPATH}/bin":$PATH

cd "${MYPATH}"

echo "Building ${GCC_VERSION}"
if [ -d "${SRCPATH}/${GCC_VERSION}" ]; then
    echo "Cleaning up previous build ..."
    rm -rf "${SRCPATH}/${GCC_VERSION}"
fi

tar xfj "${ARCHIVESPATH}/${GCC_ARCHIVE}" -C "${SRCPATH}" 

if [ -d "${SRCPATH}/${NEWLIB_VERSION}" ]; then
    echo "Cleaning up previous build ..."
    rm -rf "${SRCPATH}/${NEWLIB_VERSION}"
fi

tar xfz "${ARCHIVESPATH}/${NEWLIB_ARCHIVE}" -C "${SRCPATH}"

cd "${SRCPATH}/${GCC_VERSION}"
ln -s ../${NEWLIB_VERSION}/newlib .

mkdir "${TARGET}"
cd "${TARGET}"
../configure --target="${TARGET}" --prefix=${DSTPATH} --enable-languages=c --with-newlib --enable-newlib-io-long-long
make CXXFLAGS="-fbracket-depth=512"
make install

cd "${MYPATH}"
