#!/bin/bash

set -ex

apt-get install -y /tmp/linux-image.deb

( \
	cd /boot && \
	ln -s $(find -type f -name "vmlinuz-*" | head -n 1) vmlinuz && \
	ln -s $(find -type f -name "initrd.img-*" | head -n 1) initrd.img \
)

mkdir -p /boot/dtbs/${KERNEL_VER}/
cp -rf /lib/linux-image-${KERNEL_VER}/rockchip /boot/dtbs/${KERNEL_VER}/rockchip
ln -s /lib/linux-image-${KERNEL_VER}/rockchip/rk3568-odroid-m1.dtb /boot/dtbs/${KERNEL_VER}/rk3568-odroid-m1.dtb
ln -s /boot/dtbs/${KERNEL_VER}/rockchip/rk3568-odroid-m1.dtb /boot/dtb
ln -s /boot/dtbs/${KERNEL_VER}/rockchip/rk3568-odroid-m1.dtb /boot/dtb-${KERNEL_VER}
