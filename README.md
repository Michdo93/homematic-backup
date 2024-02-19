# homematic-backup
A simple shell script for creating manually a homematic backup.

## When to use

I had the extreme case that my SD card was partially damaged and an `fsck` could no longer repair it. Unfortunately, the recovery mode no longer worked either. I could only partially copy the SD card using `dd`. But the existing, important data is still usable. However, as the WebUI is not booted, I was unable to create a backup. Creating a backup via recovery mode also failed.

## How to use

You need a second HomeMatic control centre.

1. Insert the SD card from the first control centre into this one using the USB card reader. This is necessary because HomeMatic uses a `crypttool` that accesses libraries that cannot be installed on a Linux system.
2. Go to the WebUI --> Control Panel --> Security and activate SSH.
3. You have to make the SD card writeable with `mount -o remount,rw /`
4. Then you have to check how you can mount the SD card with `lsblk`:
```
lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda           8:0    1     0B  0 disk
sdb           8:16   1   7.4G  0 disk
|-sdb1        8:17   1   256M  0 part
|-sdb2        8:18   1     1G  0 part
`-sdb3        8:19   1     2G  0 part
mmcblk0     179:0    0   3.8G  0 disk
|-mmcblk0p1 179:1    0   256M  0 part /boot
|-mmcblk0p2 179:2    0     1G  0 part /
`-mmcblk0p3 179:3    0   2.5G  0 part /usr/local
zram0       254:0    0     0B  0 disk
zram1       254:1    0 996.7M  0 disk [SWAP]
```
5. Then you have to create following 3 directories:
```
mkdir -p /mnt/root/bootfs
mkdir -p /mnt/root/rootfs
mkdir -p /mnt/root/bootfs
```
6. After that you have to mount the SD card. In my case I have to use `/dev/sdb`:
```
mount /dev/sdb1 /mnt/root/bootfs
mount /dev/sdb2 /mnt/root/rootfs
mount /dev/sdb3 /mnt/root/userfs
```
7. Then you have to change to `/mnt/root` and download the script an make it executable:
```
cd /mnt/root
wget https://raw.githubusercontent.com/Michdo93/homematic-backup/main/homematic_backup.sh
chmod +x homematic_backup.sh
```
8. After that you have to run it with `./homematic_backup.sh`. This will create a `homematic-backup-YYYY-MM-DD.sbk` file.
9. At least you have to copy it to another computer with `scp root@<homematic-ip>:/mnt/root/<homematic-backup-YYYY-MM-DD.sbk> /path/to/file`
10. Then you can go to the WebUI and import the sbk file.

## Hint

My first attempt was actually when I try to mount the SD card that I can also run crypttool via `qemu-user-static`. Unfortunately it didn't work. So copying the crypttool is not needed, but maybe I found a solution to simulate it.
