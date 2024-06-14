VERSION 0.6

base-rootfs:
	FROM --platform=linux/arm64 debian:bookworm
	
	ARG DEBIAN_FRONTEND=noninteractive

	RUN apt-get update && \
	    apt-get install -y \
	    gpgv2 gnupg2 \
	    initramfs-tools \
	    bash ca-certificates curl wget \
	    vim util-linux pciutils usbutils uuid-runtime unzip tar gzip bzip2 xz-utils \
	    openssh-server openssh-sftp-server rsync \
	    net-tools sysstat smartmontools systemd systemd-timesyncd \
	    firmware-linux-free \
	    cloud-guest-utils e2fsprogs \
	    sudo ifupdown2 isc-dhcp-client

debian-rootfs:
	FROM --platform=linux/arm64 +base-rootfs
	
	RUN useradd -m -s /bin/bash -G sudo admin && \
	    echo "admin:debian" | chpasswd
	
	SAVE ARTIFACT --keep-own /. rootfs
	
proxmox-rootfs:
	FROM --platform=linux/arm64 +base-rootfs
	
	COPY proxmox/pveport.gpg /tmp/pveport.gpg
	RUN  apt-key add /tmp/pveport.gpg && \
	     echo "deb https://mirrors.apqa.cn/proxmox/debian/pve/ bookworm port ceph-reef" | tee /etc/apt/sources.list.d/apqa-pve.list
	
	RUN apt-get update && apt dist-upgrade -y && \
	    apt install -y --no-install-recommends -o Dpkg::Options::="--force-confdef" pve-manager && \
	    apt install -y -o Dpkg::Options::="--force-confdef" proxmox-ve
	
	RUN for name in pve-cluster.service pve-firewall.service pve-guests.service pve-ha-crm.service pve-ha-lrm.service pvedaemon.service pvefw-logger.service pveproxy.service pvescheduler.service pvestatd.service; do \
	    systemctl disable $name; done
	
	# Enable root login with SSH using sed
	RUN sed -i -E 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
	
	COPY proxmox/opt /opt
	COPY proxmox/pve-initialize.service /lib/systemd/system/pve-initialize.service

	RUN systemctl enable pve-initialize.service && \
	    rm -f /etc/network/interfaces && \
	    mkdir -p /var/log/pveproxy/ && \
	    chown www-data:www-data /var/log/pveproxy/
	
	RUN echo "root:proxmox" | chpasswd
	
	SAVE ARTIFACT --keep-own /. rootfs
	
disk:
	FROM alpine
	RUN apk add \
	    bash e2fsprogs uuidgen sfdisk mtools dosfstools losetup wget curl zstd \
	    u-boot-tools
	WORKDIR /build
	
	ARG FLAVOR
	COPY --platform=linux/arm64 +${FLAVOR}-rootfs/rootfs /build/rootfs
	
	ARG BOARD
	ARG KERNEL_VER
	ARG KERNEL_URL
	COPY boards/${BOARD} board
	COPY extend-rootfs.sh /build/rootfs/opt/extend-rootfs.sh
	RUN chmod +x /build/rootfs/opt/extend-rootfs.sh
	
	RUN mkdir -p tmp-copy
	RUN wget -O tmp-copy/linux-image.deb "${KERNEL_URL}"
	RUN --privileged DISK_OUT=/build/disk.img ROOTFS_DIR=/build/rootfs ROOTFS_ADD_SIZE=1024 BOARD_DIR=${PWD}/board ./board/make-disk-image.sh
	
	RUN zstd /build/disk.img
	SAVE ARTIFACT /build/disk.img.zst ${BOARD}_${FLAVOR}-disk.img.zst AS LOCAL output/

all:
	FROM alpine
	RUN mkdir -p ./output/
	ARG BOARD_odroidm1_KERNEL_VER=5.10.198-odroid-arm64
	ARG BOARD_odroidm1_KERNEL_URL=https://github.com/jclab-joseph/odroid-m1-kernel-builder/releases/download/v5.10.198-r5/linux-image-5.10.198-odroid-arm64_5.10.198-odroid-arm64-1_arm64.deb
	BUILD +disk --FLAVOR=debian --BOARD=odroid-m1 --KERNEL_VER=${BOARD_odroidm1_KERNEL_VER} --KERNEL_URL=${BOARD_odroidm1_KERNEL_URL}
	BUILD +disk --FLAVOR=proxmox --BOARD=odroid-m1 --KERNEL_VER=${BOARD_odroidm1_KERNEL_VER} --KERNEL_URL=${BOARD_odroidm1_KERNEL_URL}
	ARG BOARD_orangepi5plus_KERNEL_VER=6.1.43
	ARG BOARD_orangepi5plus_KERNEL_URL=https://github.com/jclab-joseph/armbian-rockchip-kernel-builder/releases/download/nightly/linux-image-6.1.43_6.1.43-1_arm64.deb
	BUILD +disk --FLAVOR=debian --BOARD=orangepi5plus --KERNEL_VER=${BOARD_orangepi5plus_KERNEL_VER} --KERNEL_URL=${BOARD_orangepi5plus_KERNEL_URL}
	BUILD +disk --FLAVOR=proxmox --BOARD=orangepi5plus --KERNEL_VER=${BOARD_orangepi5plus_KERNEL_VER} --KERNEL_URL=${BOARD_orangepi5plus_KERNEL_URL}
	# COPY (+disk/ --FLAVOR=debian --BOARD= --KERNEL_VER= --KERNEL_URL= ) ./output/
	# COPY (+disk/ --FLAVOR=proxmox --BOARD= --KERNEL_VER= --KERNEL_URL= ) ./output/
	# SAVE ARTIFACT ./output/* AS LOCAL output/
	
