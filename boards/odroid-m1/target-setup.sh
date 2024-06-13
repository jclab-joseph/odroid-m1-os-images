#!/bin/bash

set -ex

apt-get install -y /tmp/linux-image.deb

( \
	cd /boot && \
	ln -s $(find -type f -name "vmlinuz-*" | head -n 1) vmlinuz && \
	ln -s $(find -type f -name "initrd.img-*" | head -n 1) initrd.img \
)


mkdir -p /boot/dtbs/5.10.198-odroid-arm64/
cp -rf /lib/linux-image-5.10.198-odroid-arm64/rockchip /boot/dtbs/5.10.198-odroid-arm64/rockchip
ln -s /lib/linux-image-5.10.198-odroid-arm64/rockchip/rk3568-odroid-m1.dtb /boot/dtbs/5.10.198-odroid-arm64/rk3568-odroid-m1.dtb
ln -s /boot/dtbs/5.10.198-odroid-arm64/rockchip/rk3568-odroid-m1.dtb /boot/dtb
ln -s /boot/dtbs/5.10.198-odroid-arm64/rockchip/rk3568-odroid-m1.dtb /boot/dtb-5.10.198-odroid-arm64

