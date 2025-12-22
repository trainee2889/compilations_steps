#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
SCRIPT_DIR="$(pwd)"
UBOOT_SRC_DIR="$SCRIPT_DIR"
CROSS_COMPILE="arm-linux-gnueabihf-"
ARCH="arm"
OUTPUT_DIR="$HOME/linux_training/BOOT_FILES"

echo "🛠️ U-Boot source path: $UBOOT_SRC_DIR"

# -----------------------------
# Check u-boot source directory
# -----------------------------
if [ ! -f "$UBOOT_SRC_DIR/Makefile" ]; then
    echo "❌ Makefile not found. Are you in the U-Boot source directory?"
    exit 1
fi

# -----------------------------
# Step 1: Clean previous build
# -----------------------------
read -p "🧹 Remove previous build files? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE distclean
fi

# -----------------------------
# Step 2: Apply defconfig
# -----------------------------
read -p "⚙️ Apply board defconfig (recommended, am335x_evm_defconfig): " CONFIG
if [ -z "$CONFIG" ]; then
    echo "❌ Defconfig name is required!"
    exit 1
fi

make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE "$CONFIG"

# -----------------------------
# Step 3: menuconfig
# -----------------------------
read -p "🛠️ Run menuconfig? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE menuconfig
fi

# -----------------------------
# Step 4: Compile U-Boot
# -----------------------------
read -p "🔧 Compile U-Boot now? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc)
fi

read -p "copy the MLO and u-boot image to sd card? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    boot_sd_path=/media/$(whoami)/BOOT
    if [ -n "$boot_sd_path" ]; then

        # Check for MLO
        if [ ! -f "$boot_sd_path/MLO" ]; then
            echo "WARNING: MLO not found in $boot_sd_path"
        fi
        sudo cp MLO u-boot.img "$boot_sd_path"
    else
        echo "Copying to $(OUTPUT_DIR)"
        mkdir -p "$OUTPUT_DIR"
        cp -v MLO u-boot.img "$OUTPUT_DIR"
        echo "✅ MLO and u-boot.img copied to: $OUTPUT_DIR"
    fi
else
    echo "Copying to $(OUTPUT_DIR)"
    mkdir -p "$OUTPUT_DIR"
    cp -v MLO u-boot.img "$OUTPUT_DIR"
    echo "✅ MLO and u-boot.img copied to: $OUTPUT_DIR"
fi

# -----------------------------
# Done
# -----------------------------
echo "🎉 U-Boot build completed."

