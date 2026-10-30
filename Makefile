NASM = nasm
QEMU = /opt/local/var/macports/build/qemu-d756fd6b/work/build/qemu-system-i386-unsigned

BOOT_DIR = boot

BOOT = $(BOOT_DIR)/bootload
STAGE2 = $(BOOT_DIR)/bootload_protected
IMAGE = $(BOOT_DIR)/os.img

.PHONY: all run clean

all: $(IMAGE)

$(BOOT).bin: $(BOOT).asm
	$(NASM) -f bin $< -o $@

$(STAGE2).bin: $(STAGE2).asm
	$(NASM) -f bin $< -o $@

$(IMAGE): $(BOOT).bin $(STAGE2).bin
	cat $(BOOT).bin $(STAGE2).bin > $(IMAGE)

run: $(IMAGE)
	$(QEMU) -drive format=raw,file=$(IMAGE) \
		-net none \
		-fw_cfg name=opt/org.seabios/boot-menu-message,string=" "

clean:
	rm -f $(BOOT).bin $(STAGE2).bin $(IMAGE)
