#!/bin/bash

################################################################################
# PAGE 1 : STEPS 1–2 (WITH NEXT BUTTON)
################################################################################

CHOICE=$(whiptail --title "SD Card Partitioning (1/4)" --nocancel  \
--menu "
Partitioning the SD Card (GUI)

Step 1: Open GParted
--------------------------------
Run:
sudo gparted

Step 2: Select your SD card
--------------------------------
Use the top-right dropdown and select:

/dev/sdb   (8.0 GB)

⚠️ Do NOT select your system disk.

" 25 55 2 \
"Next ->" "Go to next steps" \
"Exit ->" "Close instructions" \
3>&1 1>&2 2>&3)

# If user chooses Exit or window is closed → stop script
[[ "$CHOICE" == "Exit ->" || -z "$CHOICE" ]] && exit 0

################################################################################
# PAGE 2 : STEPS 3–4 (WITH NEXT BUTTON)
################################################################################

CHOICE=$(whiptail --title "SD Card Partitioning (2/4)" --nocancel  \
--menu "

Step 3: Delete existing partitions
--------------------------------
Right-click each partition → Delete

Step 4: Create BOOT Partition (FAT32)
--------------------------------
Right-click → New
Size        : 1 GB
File System : FAT32
Label       : BOOT

" 25 55 2 \
"Next ->" "Go to next steps" \
"Exit ->" "Close instructions" \
3>&1 1>&2 2>&3)

[[ "$CHOICE" == "Exit ->" || -z "$CHOICE" ]] && exit 0

################################################################################
# PAGE 3 : STEPS 5-6 (REMOVED --msgbox FLAG TO PREVENT CRASH)
################################################################################

CHOICE=$(whiptail --title "SD Card Partitioning (3/4)" --nocancel  \
--menu "

Step 5: Create ROOTFS Partition (ext4)
--------------------------------
Right-click on unallocated space → New
File System : ext4
Label       : ROOTFS
Use remaining space

Step 6: Apply changes
--------------------------------
Click the green ✓ Apply button

" 25 55 2 \
"Next ->" "Go to next steps" \
"Exit ->" "Close instructions" \
3>&1 1>&2 2>&3)

[[ "$CHOICE" == "Exit ->" || -z "$CHOICE" ]] && exit 0

################################################################################
# PAGE 4 : STEPS 7 and 8 (REMOVED --msgbox FLAG TO PREVENT CRASH)
################################################################################

CHOICE=$(whiptail --title "SD Card Partitioning (4/4)" --nocancel  \
--menu "

Step 7: Set boot flag
--------------------------------
Right-click BOOT partition
Manage Flags → Enable boot
Close GParted


Step 8: Eject the SD card
--------------------------------
Run:
sudo eject /dev/sdb

" 25 55 2 \
"Finish" "End of instructions" \
"Exit ->" "Close instructions" \
3>&1 1>&2 2>&3)

exit 0
