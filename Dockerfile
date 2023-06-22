FROM debian:bullseye as builder

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    git ca-certificates curl wget python3 python-is-python3 debootstrap \
    e2fsprogs util-linux fdisk

RUN mkdir -p /work/boot /work/rootfs /work/output

ARG DEBIAN_MIRROR=
RUN debootstrap \
    --arch=arm64 \
    --include=ca-certificates,bash-completion,vim,util-linux,fdisk,openssl,passwd,systemd,openssh-server,openssh-sftp-server,openssh-client,ifupdown2,isc-dhcp-client,gnupg2,initramfs-tools \
    bullseye \
    /work/rootfs \
    ${DEBIAN_MIRROR}

RUN wget -O /work/rootfs/tmp/kernel.deb https://github.com/jclab-joseph/odroid-m1-kernel-builder/releases/download/v4.19.219-r0/linux-image-4.19.219-odroid-arm64_4.19.219-odroid-arm64-1_arm64.deb && \
    chroot /work/rootfs dpkg --install /tmp/kernel.deb

RUN mkdir -p /work/rootfs/etc/network
COPY interfaces /work/rootfs/etc/network/interfaces

ARG DEBIAN_FRONTEND=noninteractive
RUN echo "deb https://raw.githubusercontent.com/pimox/pimox7/master/ dev/" > /work/rootfs/etc/apt/sources.list.d/pimox.list && \
    curl https://raw.githubusercontent.com/pimox/pimox7/master/KEY.gpg | chroot /work/rootfs apt-key add - && \
    chroot /work/rootfs apt-get update && \
    chroot /work/rootfs apt install -y --no-install-recommends -o Dpkg::Options::="--force-confdef" pve-manager && \
    chroot /work/rootfs apt install -y -o Dpkg::Options::="--force-confdef" proxmox-ve

RUN ROOTFS_SIZE=$(du -sb /work/rootfs | sed -E 's/\t/ /g' | cut -d' ' -f1) && \
    ROOTFS_SIZE=$((ROOTFS_SIZE + 134217728 + 1048575)) && \
    ROOTFS_SIZE=$((ROOTFS_SIZE / 1048576))

RUN rm -rf /work/rootfs/debootstrap && \
    mke2fs -L 'rootfs' \
    -N 0 \
    -d "/work/rootfs/" \
    -m 5 \
    -r 1 \
    -t ext4 \
    "/work/rootfs.ext4" \
    ${ROOTFS_SIZE}M

COPY "boot" "/work/boot/"
RUN mke2fs -L 'boot' \
    -N 0 \
    -d "/work/boot/" \
    -m 5 \
    -r 1 \
    -t ext4 \
    "/work/boot.ext4" \
    500M

COPY disk.txt /tmp/disk.txt
RUN DISK_SIZE=$((ROOTFS_SIZE + 500 + 4)) && \
    fallocate -l $((DISK_SIZE * 1024 * 1024)) /work/output/disk.img && \
    sfdisk /work/output/disk.img < /tmp/disk.txt && \
    dd if=/work/boot.ext4 of=/work/output/disk.img bs=512 seek=2048 conv=notrunc && \
    dd if=/work/rootfs.ext4 of=/work/output/disk.img bs=512 seek=1026048 conv=notrunc

FROM scratch

COPY --from=builder ["/output/*", "/"]

