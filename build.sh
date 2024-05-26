## Clone Kernel repository
git clone https://github.com/BPI-SINOVOIP/BPI-R4-bsp-6.1.git

cd BPI-R4-bsp-6.1
./build.sh clean
./build.sh all

cd ..

dd if=/dev/zero bs=1M count=7296 | pv | dd of=bpi-r4-debian.img

losetup /dev/loop8 bpi-r4-debian.img

###4. Make partitions and format:
parted -s /dev/loop8 mklabel msdos
parted -s /dev/loop8 unit MiB mkpart primary fat32 -- 100MiB 356MiB
parted -s /dev/loop8 unit MiB mkpart primary ext2 -- 356MiB 7295MiB
partprobe /dev/loop8
mkfs.vfat /dev/loop8p1 -I -n BPI-BOOT
mkfs.ext4 -O ^has_journal -E stride=2,stripe-width=1024 -b 4096 /dev/loop8p2 -L BPI-ROOT
sync
parted -s /dev/loop8 print


#Now fill the linux root filesystem:

mkdir /mnt/rootfs
mount /dev/loop8p2 /mnt/rootfs
mkdir /mnt/rootfs/boot
mount /dev/loop8p1 /mnt/rootfs/boot


##2. Bootstrap debian rootfs (part 1):
debootstrap --arch=armhf --foreign bookworm /mnt/rootfs http://ftp.ch.debian.org/debian


cp /usr/bin/qemu-arm-static /mnt/rootfs/usr/bin/
cp configure-image.sh /mnt/rootfs/tmp

chroot /mnt/rootfs
chmod /tmp/configure-images.sh 755
/tmp/configure-images.sh


##1. Copy boot partition files:
tar -x -f BPI-R4-bsp-6.1/SD/BPI-BOOT-bpi-r4-linux-6.1.tgz --keep-directory-symlink -C /mnt/rootfs/boot

##2. Copy kernel files to root file system:
tar -x -f BPI-R4-bsp-6.1/SD/6.1.73.tgz --keep-directory-symlink -C /mnt/rootfs
tar -x -f BPI-R4-bsp-6.1/SD/6.1.73-net.tgz  --keep-directory-symlink -C /mnt/rootfs

##3. Copy bootloader files to root file system:
tar -x -f BPI-R4-bsp-6.1/SD/BOOTLOADER-bpi-r4-linux-6.1.tgz --keep-directory-symlink -C /mnt/rootfs

##4. Blacklist power button module:
echo "blacklist mtk_pmic_keys" > /mnt/rootfs/etc/modules-load.d/mtk_pmic_keys.conf

##5. Unmount:
umount /mnt/rootfs/boot
umount /mnt/rootfs
sync

##8. Remove loop device:
losetup -d /dev/loop8
