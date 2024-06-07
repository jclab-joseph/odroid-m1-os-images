#!/bin/bash

# This script automatically extends the rootfs partition and the filesystem.

set -e

# Find the root partition.
ROOT_PART=$(findmnt -n -o SOURCE /)

# Separate the root partition device and number.
DEVICE=$(lsblk -no pkname "$ROOT_PART")
PART_NUM=$(echo "$ROOT_PART" | grep -o '[0-9]*$')

# Check if the root partition is LVM.
if lsblk -no TYPE "$ROOT_PART" | grep -q lvm; then
    echo "LVM partitions are not supported."
    exit 1
fi

# Extend the partition using growpart
echo "Extending the partition..."
sudo growpart /dev/"$DEVICE" "$PART_NUM"

# Extend the filesystem.
echo "Extending the filesystem..."
sudo resize2fs "$ROOT_PART"

echo "Root partition and filesystem extension completed."
exit 0

