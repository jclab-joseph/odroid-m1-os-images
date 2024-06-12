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
	
	COPY pveport.gpg /tmp/pveport.gpg
	RUN  apt-key add /tmp/pveport.gpg && \
	     echo "deb https://mirrors.apqa.cn/proxmox/debian/pve/ bookworm port ceph-reef" | tee /etc/apt/sources.list.d/apqa-pve.list
	
	RUN apt-get update && apt dist-upgrade -y && \
	    apt install -y --no-install-recommends -o Dpkg::Options::="--force-confdef" pve-manager && \
	    apt install -y -o Dpkg::Options::="--force-confdef" proxmox-ve
	
	RUN for name in pve-cluster.service pve-firewall.service pve-guests.service pve-ha-crm.service pve-ha-lrm.service pvedaemon.service pvefw-logger.service pveproxy.service pvescheduler.service pvestatd.service; do \
	    systemctl disable $name; done
	
	# Enable root login with SSH using sed
	RUN sed -i -E 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
	
	COPY opt /opt
	COPY pve-initialize.service /lib/systemd/system/pve-initialize.service

	RUN systemctl enable pve-initialize.service && \
	    rm -f /etc/network/interfaces && \
	    mkdir -p /var/log/pveproxy/ && \
	    chown www-data:www-data /var/log/pveproxy/
	
	RUN echo "root:proxmox" | chpasswd
	
	SAVE ARTIFACT --keep-own /. rootfs
	
disk:
	ARG FLAVOR
	
	FROM alpine
	RUN apk add \
	    bash e2fsprogs uuidgen sfdisk mtools dosfstools losetup wget curl zstd \
	    u-boot-tools
	WORKDIR /build
	COPY --platform=linux/arm64 +${FLAVOR}-rootfs/rootfs /build/rootfs
	COPY boot /build/boot
	COPY boot.template /build/boot.template
	COPY extend-rootfs.sh /build/rootfs/opt/extend-rootfs.sh
	RUN chmod +x /build/rootfs/opt/extend-rootfs.sh
	
	COPY make-disk-image.sh target-setup.sh .
	RUN mkdir -p tmp-copy
	RUN wget -O tmp-copy/linux-image.deb https://github.com/jclab-joseph/odroid-m1-kernel-builder/releases/download/v5.10.198-r5/linux-image-5.10.198-odroid-arm64_5.10.198-odroid-arm64-1_arm64.deb
	RUN --privileged DISK_OUT=/build/disk.img ROOTFS_DIR=/build/rootfs BOOT_ADD_DIR=/build/boot ROOTFS_ADD_SIZE=1024 ./make-disk-image.sh
	
	RUN zstd /build/disk.img
	SAVE ARTIFACT /build/disk.img.zst disk.img.zst

all:
	LOCALLY
	RUN mkdir -p ./output/
	# BUILD +disk --FLAVOR=proxmox
	COPY (+disk/disk.img.zst --FLAVOR=debian) ./output/debian-disk.img.zst
	COPY (+disk/disk.img.zst --FLAVOR=proxmox) ./output/proxmox-disk.img.zst
	
