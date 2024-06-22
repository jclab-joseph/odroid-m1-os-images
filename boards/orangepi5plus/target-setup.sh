#!/bin/bash

set -ex

apt-get install -y /tmp/linux-image.deb

( \
	cd /boot && \
	ln -s $(find -type f -name "vmlinuz-*" | head -n 1) vmlinuz && \
	ln -s $(find -type f -name "initrd.img-*" | head -n 1) initrd.img \
)

FDT_NAME="rk3588-orangepi-5-plus.dtb"

mkdir -p /boot/dtbs/${KERNEL_VER}/
cp -rf /lib/linux-image-${KERNEL_VER}/rockchip /boot/dtbs/${KERNEL_VER}/rockchip
( \
	cd /boot && \
	ln -s dtbs/${KERNEL_VER}/rockchip/${FDT_NAME} dtbs/${KERNEL_VER}/${FDT_NAME} && \
	ln -s dtbs/${KERNEL_VER}/rockchip/${FDT_NAME} dtb && \
	ln -s dtbs/${KERNEL_VER}/rockchip/${FDT_NAME} dtb-${KERNEL_VER} \
)

