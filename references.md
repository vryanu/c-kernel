# Memory references

## Bootloader & kernel addresses

**Bootloader stage 1** - 0x7C00
**Bootloader stage 2** - 0x8000
**Protected stack** - 0x90000
**C kernel & link** - 0x10000

## ASM Constants

**CODE_SEG** - 0x08
**DATA_SEG** - 0x10

**PIC1_COMMAND** - 0x20
**PIC1_DATA** - 0x21
**PIC1_OFFSET** - 0x20
**PIC2_COMMAND** - 0xA0
**PIC2_DATA** - 0xA1
**PIC2_OFFSET** - 0x28

## GDT

**Start** - null
**code** - 0x00CF9A000000FFFF
**data** - 0x00CF92000000FFFF

## VGA

**VGA cell color** - 0x(`text clr` `background clr`)(ASCII char) eg 0x0F20
**start of memory buffer** - 0xB8000
**end of buffer** - 0xB8FA0
**color text memory** - 0xB8000
**black white memory** 0xB0000
**graphics mode frame buffer** - 0xA0000

## Command addresses

**keyboard buffer** - 0x70000
**keyboard length** - 0x70080
**command ready** - 0x70084
**keyboard cursor** - 0x70088


# ASM label references

## bootload.asm
* **disk_error** - will move error message
* **.print_error** - print the error

## bootload_protected.asm
* **gdt_start** - null descriptor
* **gdt_code** - code segment descriptor
* **gdt_data** - data segment descriptor
* **gdt_end** - end of gdt
* **gdt_descripter** - make the memory structure & mark start
* **load_kernel** - pass disk packet into boot drive
* **disk_packet** - create the DAP structure
32 bits
* **protected_mode** - set up 32bit regs & start a new stack

## interrupts.asm
* **keymap** - regular keyboard keys
* **shift_keymap** - shifted keyboard keys
* **timer_handler** - create a timer
* **keyboard_handler** - handle all keyboard inputs
* .**shifted** - call shifted keymap
* .**character** - print a character
* .**shift_down** - shift is pressed
* .**shift_up** - shift is released
* .**backspace** - handle backspace deleting
* .**enter** - handle newline & command inputting
* .**save_sursor** - save the cursor address
* .**eoi** - end of interrupt, end the interrupt
* **handler** - handle exceptions
* **vga_update_cursor** - updates the cursor address

## idt.asm
* **idt_start** - create interrupt entries
* **idt_end** - end idt
* **idt_descripter** - make the structure & mark start
* **idt_init** - will load the idt

## pic.asm
* **pic_init** - recieve an interrupt request, send to CPU accordingly