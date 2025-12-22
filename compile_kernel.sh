#!/bin/bash

set -e

# -----------------------------
# Configuration
# -----------------------------
SCRIPT_DIR="$(pwd)"
KERNEL_SRC_DIR="$SCRIPT_DIR/kernel"
CROSS_COMPILE="arm-linux-gnueabihf-"
ARCH="arm"
PRVCONFIG="my_bbb_custom_defconfig"
DEFCONFIG="bb.org_defconfig"
LOADADDR="0x80008000"
ROOTFS=~/linux_training/bbb-project/10_rootfs/rootfs/mnt
BOOT_DIR=~/linux_training/BOOT_FILES

echo "🛠️ Kernel source path: $KERNEL_SRC_DIR"

# Check if kernel directory exists
if [ ! -d "$KERNEL_SRC_DIR" ]; then
    echo "❌ Error: Kernel source directory not found at $KERNEL_SRC_DIR"
    exit 1
fi

# Enter kernel directory
cd "$KERNEL_SRC_DIR" || exit 1

# -----------------------------
# Step 1: Clean previous build
# -----------------------------
read -p "🧹 Remove previous build files? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH distclean
fi

# -----------------------------
# Step 2: Configure kernel
# -----------------------------
read -p "⚙️ Load default defconfig ($DEFCONFIG)? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE "$DEFCONFIG"
else
    read -p "⚙️ Load previous config ($PRVCONFIG)? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE "$PRVCONFIG"
    else
        read -p "📄 Enter custom defconfig : " CUSTOM_DEFCONFIG
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE "$CUSTOM_DEFCONFIG"
    fi
fi

# -----------------------------
# Step 3: menuconfig
# -----------------------------
read -p "🛠️ Run menuconfig? (y/n): " run_menuconfig
if [[ "$run_menuconfig" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE menuconfig
fi

# -----------------------------
# Step 3.1: Save defconfig after menuconfig (if updated)
# -----------------------------
if [[ "$run_menuconfig" =~ ^[Yy]$ ]]; then
    echo "💾 Saving updated kernel config to custom defconfig..."
    make ARCH=$ARCH savedefconfig
    mv defconfig arch/arm/configs/my_bbb_custom_defconfig
    echo "🔄 PRVCONFIG updated → arch/arm/configs/my_bbb_custom_defconfig"
    PRVCONFIG="my_bbb_custom_defconfig"
fi

# -----------------------------
# Step 3.2: Build only DTBs
# -----------------------------
read -p "🌳 Build only DTBs? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs -j$(nproc)
fi

# -----------------------------
# Step 4: Build kernel image and DTBs
# -----------------------------
read -p "🔧 Compile kernel uImage + dtbs? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE uImage dtbs LOADADDR=$LOADADDR -j$(nproc)
fi

# -----------------------------
# Step 5: Build kernel modules
# -----------------------------
read -p "📦 Build kernel modules? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE modules -j$(nproc)
fi

# -----------------------------
# Step 6: Install modules to rootfs
# -----------------------------
read -p "📦 Install modules to rootfs? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    read -p "📁 Enter rootfs path (or leave blank to use default): " input_rootfs
    if [ -n "$input_rootfs" ]; then
        ROOTFS="$input_rootfs"
    fi

    if [ -n "$ROOTFS" ]; then
        echo "📦 Installing modules to: $ROOTFS"
        sudo make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH="$ROOTFS" modules_install
    else
        echo "⚠️  No rootfs path provided, skipping modules install."
    fi
else
    echo "🚫 Skipping module installation."
fi

# -----------------------------
# Step 7: Install kernel to /boot
# -----------------------------
read -p "📦 Install kernel to rootfs /boot? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    read -p "📁 Enter rootfs path (or leave blank to use previous path): " input_rootfs_k
    if [ -n "$input_rootfs_k" ]; then
        ROOTFS_K="$input_rootfs_k"
    else
        ROOTFS_K="$ROOTFS"
    fi

    if [ -n "$ROOTFS_K" ]; then
        echo "📥 Installing kernel to: $ROOTFS_K/boot"
        sudo make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_PATH="$ROOTFS_K/boot" install
    else
        echo "⚠️  No rootfs path provided, skipping kernel install."
    fi
else
    echo "🚫 Skipping kernel installation."
fi

# -----------------------------
# Step 8: copy boot files
# -----------------------------
read -p "copy the boot image to sd card? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    boot_sd_path=/media/$(whoami)/BOOT
    if [ -n "$boot_sd_path" ]; then

        # Check for MLO
        if [ ! -f "$boot_sd_path/MLO" ]; then
            echo "WARNING: MLO not found in $boot_sd_path"
        else
            sudo cp $KERNEL_SRC_DIR/arch/arm/boot/zImage $(boot_sd_path)
            read -p "copy wireless .dtb image into sd card? (y/n): " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                sudo cp $KERNEL_SRC_DIR/arch/arm/boot/am335x-boneblack-wireless.dtb $(boot_sd_path)
            else
                sudo cp $KERNEL_SRC_DIR/arch/arm/boot/dts/am335x-boneblack.dtb $(boot_sd_path)
            fi
        fi
    else
        echo "Copying to $(BOOT_DIR)"
        sudo cp $KERNEL_SRC_DIR/arch/arm/boot/zImage $KERNEL_SRC_DIR/arch/arm/boot/uImage $(BOOT_DIR)
        sudo cp $KERNEL_SRC_DIR/arch/arm/boot/am335x-boneblack-wireless.dtb $KERNEL_SRC_DIR/arch/arm/boot/dts/am335x-boneblack.dtb $(BOOT_DIR)
    fi
else
    echo "Copying to $(BOOT_DIR)"
    sudo cp $KERNEL_SRC_DIR/arch/arm/boot/zImage $KERNEL_SRC_DIR/arch/arm/boot/uImage $(BOOT_DIR)
    sudo cp $KERNEL_SRC_DIR/arch/arm/boot/am335x-boneblack-wireless.dtb $KERNEL_SRC_DIR/arch/arm/boot/dts/am335x-boneblack.dtb $(BOOT_DIR)
fi

# -----------------------------
# Done
# -----------------------------
sync
echo "✅ Kernel build and install process completed."
