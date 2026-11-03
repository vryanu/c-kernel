## C kernel/os written in asm & c

### Create a disk image
For macOS
cd to project folder
run:
dd if=/dev/zero of=disk.img bs=1m count=32
* create a 32MB disk image
hdiutil attach -nomount ./disk.img
* this prints disk(n) use the number on next line
sudo newfs_msdos -F 16 -v DISK /dev/rdiskN
hdiutil detach /dev/diskN

### Dependencies
Uses:
QEMU i386
NASM
i386 elf ld

### Features
* 2 stage boot into a protected mode
* 32 bit kernel
* keyboard interrupt handling
* inline arg parsing in shell
* shell commands
* VGA outputs
* basic IO function header

Final goal
Create & write files in shell+VIM
compile and run the files