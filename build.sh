#! /bin/sh

MainPath="$(pwd)"
clang="$(pwd)/../clang"
gcc64="$(pwd)/../gcc64"
gcc="$(pwd)/../gcc"
Any="$(pwd)/../AnyKernel3"

MakeZip(){
    if [ ! -d $Any ];then
        git clone https://github.com/TeraaBytee/AnyKernel3 -b r-oss $Any
    else
        cd $Any
        git reset --hard
        git fetch origin r-oss
        git checkout r-oss
        git reset --hard origin/r-oss
    fi
    cd $Any
    cp -af $MainPath/out/arch/arm64/boot/Image.gz-dtb $Any
    cp -af anykernel-real.sh anykernel.sh
    sed -i "s/kernel.string=.*/kernel.string=$KERNEL_NAME-$HeadCommit test by $KBUILD_BUILD_USER/g" anykernel.sh
    zip -r $MainPath/"[$Compiler][R-OSS]-$ZIP_KERNEL_VERSION-$KERNEL_NAME-$TIME.zip" * -x .git .git/**\* ./.git ./anykernel-real.sh ./.gitignore ./LICENSE ./README.md ./*.zip
    cd $MainPath
}

if [ ! -d $clang ];then
   git clone --depth=1 https://github.com/pjorektneira/aosp-clang $clang
fi
if [ ! -d $gcc64 ];then
    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 $gcc64
fi
if [ ! -d $gcc ];then
    git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 $gcc
fi

HeadCommit="$(git log --pretty=format:'%h' -1)"
export ARCH="arm64"
export SUBARCH="arm64"
export KBUILD_BUILD_USER="TeraaBytee"
export KBUILD_BUILD_HOST="$(hostname)"
Defconfig="begonia_user_defconfig"
KERNEL_NAME=$(cat "$MainPath/arch/arm64/configs/$Defconfig" | grep "CONFIG_LOCALVERSION=" | sed 's/CONFIG_LOCALVERSION="-*//g' | sed 's/"*//g' )
ZIP_KERNEL_VERSION="4.14.$(cat "$MainPath/Makefile" | grep "SUBLEVEL =" | sed 's/SUBLEVEL = *//g')$(cat "$(pwd)/Makefile" | grep "EXTRAVERSION =" | sed 's/EXTRAVERSION = *//g')"
TIME=$(date +"%m%d%H%M")

Compiler=DragonTC
MAKE="./makeparallel"
rm -rf out *.log
exec 2> >(tee -a error.log >&2)
BUILD_START=$(date +"%s")
make -j 8  O=out ARCH=arm64 SUBARCH=arm64 $Defconfig

if [ ! -z "$1" ] && [ "$1" == "regen" ] ;then
    cp -af out/.config $MainPath/arch/arm64/configs/$Defconfig
else
    make -j 8 O=out \
                          PATH="$clang/bin:$gcc64/bin:$gcc/bin:/usr/bin:$PATH" \
                          LD_LIBRARY_PATH="$clang/lib64:$LD_LIBRABRY_PATH" \
                          CC=clang \
                          LD=ld.lld \
                          CROSS_COMPILE=aarch64-linux-android- \
                          CROSS_COMPILE_ARM32=arm-linux-androideabi- \
                          CLANG_TRIPLE=aarch64-linux-gnu-
fi

if [ -e $MainPath/out/arch/arm64/boot/Image.gz-dtb ];then
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    MakeZip
    echo "Build success in : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
else
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    echo "Build fail in : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
fi
