NASM = nasm
CC = i386-elf-gcc
LD = i386-elf-ld
OBJCOPY = i386-elf-objcopy

QEMU = /opt/local/var/macports/build/qemu-d756fd6b/work/build/qemu-system-i386-unsigned

BOOT_DIR = boot

BOOT = $(BOOT_DIR)/bootload
STAGE2 = $(BOOT_DIR)/bootload_protected
IMAGE = $(BOOT_DIR)/os.img

KERNEL_ELF = kernel.elf
KERNEL_BIN = kernel.bin
KERNEL_PADDED = kernel_padded.bin
LINKER_SCRIPT = linker.ld

ASM_SOURCES = \
    interrupts/interrupts.asm \
    interrupts/idt.asm \
    interrupts/PIC.asm

ASM_OBJECTS = $(ASM_SOURCES:.asm=.o)

C_SOURCES = \
    kernel.c \
    terminal/terminal.c \
    commands/cmds.c

C_OBJECTS = $(C_SOURCES:.c=.o)

CFLAGS = -m32 -ffreestanding -fno-pie -fno-pic \
         -fno-stack-protector -fno-builtin \
         -Wall -Wextra -O2

.PHONY: all run clean

all: $(IMAGE)

$(BOOT).bin: $(BOOT).asm
	$(NASM) -f bin $< -o $@

$(STAGE2).bin: $(STAGE2).asm
	$(NASM) -f bin $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.asm
	$(NASM) -f elf32 $< -o $@

$(KERNEL_ELF): $(C_OBJECTS) $(ASM_OBJECTS) $(LINKER_SCRIPT)
	$(LD) -m elf_i386 -T $(LINKER_SCRIPT) -o $@ $(C_OBJECTS) $(ASM_OBJECTS)

$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@

$(KERNEL_PADDED): $(KERNEL_BIN)
	test "$$(wc -c < $(KERNEL_BIN))" -le 8192
	dd if=/dev/zero of=$@ bs=8192 count=1
	dd if=$(KERNEL_BIN) of=$@ conv=notrunc

$(IMAGE): $(BOOT).bin $(STAGE2).bin $(KERNEL_PADDED)
	cat $(BOOT).bin $(STAGE2).bin $(KERNEL_PADDED) > $(IMAGE)

run: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE) \
		-net none \
		-fw_cfg name=opt/org.seabios/boot-menu-message,string=" "

clean:
	rm -f $(BOOT).bin $(STAGE2).bin $(IMAGE)
	rm -f $(C_OBJECTS) $(ASM_OBJECTS)
	rm -f $(KERNEL_ELF) $(KERNEL_BIN) $(KERNEL_PADDED)
