#!/bin/bash

echo "Linfinity Linux Build Tool"
echo "<========================>"

shopt -s extglob
export ARCH=i386
export BUILDDIR=$(pwd)
export BUILDROOT=buildroot-2022.02.1

function downloadTools {
    echo "Downloading build tools..."
    sudo apt -y update
    sudo apt -y install sed make binutils build-essential gcc g++ patch perl cpio unzip rsync bc wget git python3
    echo "Downloading Buildroot..."
    wget https://buildroot.org/downloads/buildroot-2022.02.1.tar.gz
    tar -xzf buildroot-2022.02.1.tar.gz
    rm buildroot-2022.02.1.tar.gz
}

function buildSystem {
    echo "Configuring Buildroot..."
    cd $BUILDDIR
    echo "Building system..."
    cd $BUILDROOT
    make BR2_EXTERNAL=$BUILDDIR "neutrino_${ARCH}_defconfig"
    make -j16
}

function createDiskImage {
    echo "Creating disk image..."
    cd $BUILDDIR
    dd if=/dev/zero of=$BUILDDIR/linfinity.linux.img bs=1M count=96 > /dev/null
    echo "Mounting image..."
    lodev=$(sudo losetup -f)
    sudo losetup $lodev $BUILDDIR/linfinity.linux.img
    cat << EOF | sudo fdisk $lodev
o
n
p
1
2048

a
p
w
q
EOF
    sudo losetup -d $lodev
    lodev=$(losetup -f)
    sudo losetup -P $lodev $BUILDDIR/linfinity.linux.img
    sudo mkfs -t ext4 ${lodev}p1
    mkdir $BUILDDIR/imgdir
    sudo mount ${lodev}p1 $BUILDDIR/imgdir
    echo "Copying files..."
    sudo tar -xf $BUILDROOT/output/images/rootfs.tar -C $BUILDDIR/imgdir
    echo "Installing kernel..."
    sudo cp $BUILDROOT/output/images/bzImage $BUILDDIR/imgdir/boot/
    echo "Installing Grub2 bootloader..."
    grub_tgt="${ARCH}-pc"
    case $ARCH in
        i686)
            grub_tgt="i386-pc"
            ;;
    esac
    btd=$(find buildroot-2022.02.1/output/build -maxdepth 1 -type d -name '*grub2-*' -print -quit)
    sudo $BUILDROOT/output/host/sbin/grub-bios-setup -b ${btd#*/}/build-${ARCH}-pc/grub-core/boot.img -c output/images/grub.img -d $BUILDROOT $lodev
    echo "Unmounting..."
    sudo umount -l $BUILDDIR/imgdir
    sudo losetup -d $lodev
    echo "Cleaning up..."
    rm -rf $BUILDDIR/imgdir
    echo "Linfinity Linux bootable image linfinity.linux.img created successfully! Have a nice day :)"
}

function clear {
    echo "Cleaning up..."
    cd $BUILDROOT
    make clean
}

function build {
    clear
    buildSystem
    createDiskImage
}

function run {
    qemu-system-$ARCH -hda linfinity.linux.img
}

$1