#!/bin/bash
set -e

# Where to store U-Boot source
BASE_DIR="${HOME}/linux_training/bbb-project"
UBOOT_DIR="${BASE_DIR}/09_uBoot"
TEMP_CLONE_DIR="${BASE_DIR}/.tmp_uBoot_clone"

# U-Boot official Git repo
UBOOT_REPO="https://github.com/u-boot/u-boot.git"
UBOOT_BRANCH="v2024.01"

echo "Downloading U-Boot source..."

# Create base and temp directories
mkdir -p "${UBOOT_DIR}"
rm -rf "${TEMP_CLONE_DIR}"
mkdir -p "${TEMP_CLONE_DIR}"

echo "Cloning from ${UBOOT_REPO} (branch: ${UBOOT_BRANCH}) to temp folder..."
git clone --depth=1 --branch "${UBOOT_BRANCH}" "${UBOOT_REPO}" "${TEMP_CLONE_DIR}" || {
    echo "❌ Failed to clone U-Boot"
    exit 1
}

echo "Merging into existing directory: ${UBOOT_DIR} (preserving existing files)..."
shopt -s dotglob
cp -rT "${TEMP_CLONE_DIR}" "${UBOOT_DIR}"
shopt -u dotglob

rm -rf "${TEMP_CLONE_DIR}"

echo "✅ U-Boot cloned and merged into ${UBOOT_DIR}"

