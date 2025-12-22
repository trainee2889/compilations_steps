#!/bin/bash
set -e

# ----------------------------------------
# Configuration
# ----------------------------------------
BASE_DIR=~/linux_training/bbb-project/10_rootfs
ROOTFS_DIR=$BASE_DIR/rootfs
MOUNT_DIR=$ROOTFS_DIR/mnt
RCN_BASE_URL="https://rcn-ee.com/rootfs/debian-armhf-12-bookworm-iot-v6.1-ti/"
ARCHIVE_EXT=".img.xz"

mkdir -p "$ROOTFS_DIR"
cd "$ROOTFS_DIR"

echo "🔍 Searching for latest dated folder..."

# ----------------------------------------
# Get Latest Dated Folder
# ----------------------------------------
latest_folder=$(curl -s "$RCN_BASE_URL" | grep -oP '\d{4}-\d{2}-\d{2}/' | sort -Vr | head -n1)

if [[ -z "$latest_folder" ]]; then
    echo "❌ Failed to find a valid dated folder at: $RCN_BASE_URL"
    exit 1
fi

full_url="${RCN_BASE_URL}${latest_folder}"
echo "📁 Latest folder: $latest_folder"

# ----------------------------------------
# Auto-detect image name
# ----------------------------------------
image_filename=$(curl -s "$full_url" | grep -oP 'am335x-debian-.*?\.img\.xz' | sort -Vr | head -n1)

if [[ -z "$image_filename" ]]; then
    echo "❌ No image file found in $full_url"
    exit 1
fi

download_url="${full_url}${image_filename}"
echo "✅ Latest image: $image_filename"
echo "🌐 Download URL: $download_url"

# ----------------------------------------
# Download Image
# ----------------------------------------
if [ -f "$image_filename" ]; then
    echo "✅ Image already exists: $image_filename"
else
    echo "⬇️ Downloading image..."
    wget "$download_url"
fi

# ----------------------------------------
# Extract Image
# ----------------------------------------
extracted_img="${image_filename%.xz}"
if [ -f "$extracted_img" ]; then
    echo "✅ Already extracted: $extracted_img"
else
    echo "📦 Extracting image..."
    xz -dk "$image_filename"
fi

# ----------------------------------------
# Optional Mount
# ----------------------------------------
read -p "👉 Mount and explore the rootfs now? [y/N]: " do_mount
if [[ "$do_mount" =~ ^[Yy]$ ]]; then
    echo "🔎 Detecting Linux partition offset..."
    echo "🔍 fdisk output:"
    fdisk -l "$extracted_img"

    PART_OFFSET=$(fdisk -l "$extracted_img" | grep -m 1 -E "^[^:]+img[0-9]+" | awk '{print $3}')

    if [[ -z "$PART_OFFSET" || ! "$PART_OFFSET" =~ ^[0-9]+$ ]]; then
        echo "❌ Failed to detect Linux partition offset in image."
        exit 1
    fi

    OFFSET_BYTES=$((PART_OFFSET * 512))

    if mount | grep -q "$MOUNT_DIR"; then
        echo "⚠️ Already mounted at $MOUNT_DIR"
    else
        mkdir -p "$MOUNT_DIR"
        echo "📂 Mounting partition at $MOUNT_DIR (offset: $OFFSET_BYTES)"
        sudo mount -o loop,offset=$OFFSET_BYTES "$extracted_img" "$MOUNT_DIR"
        echo "✅ Mounted! Explore with: sudo ls $MOUNT_DIR"
    fi
fi

# ----------------------------------------
# Optional Unmount
# ----------------------------------------
read -p "👉 Unmount rootfs if mounted? [y/N]: " do_unmount
if [[ "$do_unmount" =~ ^[Yy]$ ]]; then
    if mount | grep -q "$MOUNT_DIR"; then
        sudo umount "$MOUNT_DIR"
        echo "✅ Unmounted: $MOUNT_DIR"
    else
        echo "ℹ️ Not currently mounted: $MOUNT_DIR"
    fi
fi

echo ""
echo "🎉 Done! Rootfs is available at: $ROOTFS_DIR"
