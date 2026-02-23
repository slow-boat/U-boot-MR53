#!/bin/sh
# build.sh - source this with: . build.sh

# Environment variables
GCC_VER=gcc-linaro-4.9.4-2017.01-x86_64_arm-eabi
GCC_ARCHIVE=${GCC_VER}.tar.xz
GCC_URL="http://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-eabi/gcc-linaro-4.9.4-2017.01-x86_64_arm-eabi.tar.xz"
export CROSS_COMPILE=/opt/${GCC_VER}/bin/arm-eabi-
[ -f ${CROSS_COMPILE}gcc ] || {
	echo "Installing toolchain"
	wget -P /tmp ${GCC_URL} && sudo tar xJf /tmp/$GCC_ARCHIVE -C /opt || {
		echo "Toolchain install failed"
        return 1
	}
}
echo "Environment_ready"

makemr53(){
	echo "Building u-boot.itb"
	make clean && make cryptid_defconfig && make && return 0
	echo "############ build failed #############"
	return 1
}
