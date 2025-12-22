#!/bin/bash

OUTPUT_DIR="$HOME/linux_training/BOOT_FILES"

echo "Generate boot.cmd for BeagleBone:"
read -p "Is this a Wireless board? (y/n): " choice

# file to generate
BOOTCMD=boot.cmd

# common part
cat << 'EOF' > $BOOTCMD
echo "*** Booting via boot.scr ***"

setenv bootargs "console=ttyS0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rw rootwait"
setenv bootfile "zImage"
EOF

# choose DTB
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo 'setenv fdtfile "am335x-boneblack-wireless.dtb"' >> $BOOTCMD
else
    echo 'setenv fdtfile "am335x-boneblack.dtb"' >> $BOOTCMD
fi

# finish script
cat << 'EOF' >> $BOOTCMD

load mmc 0:1 ${loadaddr} ${bootfile}
load mmc 0:1 ${fdtaddr} ${fdtfile}

echo "*** Booting Kernel ***"

bootz ${loadaddr} - ${fdtaddr}
EOF

echo "Generated boot.cmd:"
echo "------------------------------------------------"
cat $BOOTCMD
echo "------------------------------------------------"

# now create boot.scr using mkimage
mkimage -A arm -T script -O linux -d $BOOTCMD boot.scr

echo "Done:"
echo " → boot.cmd created"
echo " → boot.scr generated successfully"

read -p "copy the boot.scr image to sd card? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    boot_sd_path=/media/$(whoami)/BOOT
    if [ -n "$boot_sd_path" ]; then

        # Check for MLO
        if [ ! -f "$boot_sd_path/MLO" ]; then
            echo "WARNING: MLO not found in $boot_sd_path"
        else
            sudo cp boot.scr $(boot_sd_path)
        fi
    else
        echo "Copying to $(OUTPUT_DIR)"
        mkdir -p "$OUTPUT_DIR"
        cp -v boot.scr "$OUTPUT_DIR"
        echo "✅ boot.scr copied to: $OUTPUT_DIR"
    fi
else
    echo "Copying to $(OUTPUT_DIR)"
    mkdir -p "$OUTPUT_DIR"
    cp -v boot.scr "$OUTPUT_DIR"
    echo "✅ boot.scr copied to: $OUTPUT_DIR"
fi
