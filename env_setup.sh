#!/bin/bash

set -e

# -----------------------------
# CONFIGURATION
# -----------------------------
BASE_DIR=~/linux_training/bbb-project
KERNEL_DIR="$BASE_DIR/08_kernel/kernel"
ENV_FILE="$BASE_DIR/env.sh"
TOOLCHAIN_PACKAGE="gcc-11-arm-linux-gnueabihf"

echo "📁 Using workspace directory: $BASE_DIR"
mkdir -p "$BASE_DIR"

# -----------------------------
# PROMPT FOR INSTALLATION
# -----------------------------
read -p "⚠️ This script will install packages using sudo. Continue? [y/N]: " proceed
if [[ "$proceed" != "y" && "$proceed" != "Y" ]]; then
    echo "❌ Aborting setup."
    exit 1
fi

# -----------------------------
# TOOLCHAIN CHECK (force version 11.x)
# -----------------------------
echo "🔍 Checking for ARM cross-compiler..."

# Remove conflicting cross-compiler versions if present
if dpkg -l | grep -q "gcc-arm-linux-gnueabihf"; then
    echo "⚠️ Removing previously installed ARM toolchain..."
    sudo apt remove -y gcc-arm-linux-gnueabihf gcc-*-arm-linux-gnueabihf || true
fi

# Install GCC-11 toolchain
if ! dpkg -l | grep -q "$TOOLCHAIN_PACKAGE"; then
    echo "⬇️ Installing toolchain: $TOOLCHAIN_PACKAGE"
    sudo apt update
    sudo apt install -y "$TOOLCHAIN_PACKAGE"
fi

# Verify GCC version
if command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    version=$(arm-linux-gnueabihf-gcc -dumpversion)
else
    echo "❌ arm-linux-gnueabihf-gcc not found after installation!"
    exit 1
fi

echo "🔧 Detected GCC version: $version"

if [[ "$version" != 11* ]]; then
    echo "❌ Incorrect GCC version detected ($version). Expected 11.x"
    echo "➡️ Manually remove existing toolchain and reinstall."
    exit 1
fi

echo "✅ Required GCC version installed: $version"

# -----------------------------
# OTHER PACKAGE DEPENDENCIES
# -----------------------------
echo "📦 Installing build tools and kernel dependencies..."

MISSING_PKGS=()

for pkg in gparted minicom make parted bison flex fzf bc swig libssl-dev libncurses-dev build-essential git wget curl device-tree-compiler u-boot-tools; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        MISSING_PKGS+=("$pkg")
    else
        echo "✅ $pkg already installed."
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "⬇️ Installing missing packages: ${MISSING_PKGS[*]}"
    sudo apt install -y "${MISSING_PKGS[@]}"
else
    echo "✅ All required packages already installed."
fi

# -----------------------------
# KERNEL SOURCE DOWNLOAD
# -----------------------------
if [ ! -d "$KERNEL_DIR" ]; then
    echo "⬇️ Cloning BeagleBone kernel source into $KERNEL_DIR..."
    git clone --depth=1 -b 5.10 https://github.com/beagleboard/linux.git "$KERNEL_DIR"
else
    echo "⚠️ Kernel directory already exists: $KERNEL_DIR"
fi

# -----------------------------
# ENVIRONMENT VARIABLES
# -----------------------------
echo "🌿 Writing environment file: $ENV_FILE"
cat > "$ENV_FILE" <<EOF
# Environment variables for BeagleBone SPI training
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
export KERNEL_SRC=$KERNEL_DIR
EOF

# -----------------------------
# Optional: Bashrc Hook
# -----------------------------
read -p "👉 Do you want to auto-load environment when entering this folder? [y/N]: " add_hook
if [[ "$add_hook" == "y" || "$add_hook" == "Y" ]]; then
    if ! grep -q "source $ENV_FILE" ~/.bashrc; then
        echo "🔧 Adding source command to ~/.bashrc"
        echo "# Load BeagleBone training env" >> ~/.bashrc
        echo "if [ -f \"$ENV_FILE\" ]; then source \"$ENV_FILE\"; fi" >> ~/.bashrc
    else
        echo "✅ Source already present in ~/.bashrc"
    fi
else
    echo "⏭️ Skipping bashrc modification. You can manually run:"
    echo "   source $ENV_FILE"
fi

mv $(pwd)/compile_kernel.sh $BASE_DIR/08_kernel/
mv $(pwd)/compile_uboot.sh $BASE_DIR/09_uBoot/

# -----------------------------
# DONE
# -----------------------------
echo ""
echo "✅ Environment setup complete!"
echo "📁 Project root: $BASE_DIR"
echo "📂 Kernel source: $KERNEL_DIR"
echo ""
echo "# 🧠 Reminder:"
echo "# If you skipped bashrc integration, run this manually each time:"
echo "#"
echo "#    source $ENV_FILE"

