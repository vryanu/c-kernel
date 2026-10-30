BITS 16 ; 16 bit mode
ORG 0x8000 
jmp start

CODE_SEG equ 0x08 ; Constants
DATA_SEG equ 0x10

gdt_start:
    dq 0x0000000000000000 ; NULL

gdt_code:
    dq 0x00CF9A000000FFFF ; cs

gdt_data:
    dq 0x00CF92000000FFFF ; ds

gdt_end:

gdt_descripter:
    dw gdt_end - gdt_start - 1 ; length
    dd gdt_start

start:
    cli

    xor ax, ax ; reset
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00 ; stack

    ; A20 line go over 1mb
    in al, 0x92
    or al, 00000010b
    and al, 11111110b
    out 0x92, al

    lgdt [gdt_descripter] ; load descripter

    mov eax, cr0 ; load control
    or eax, 1 ; set 0
    mov cr0, eax ; back to control

    jmp dword CODE_SEG:protected_mode

BITS 32 ; enter 32 bit mode

protected_mode:
    mov ax, DATA_SEG ; set all data_seg

    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000 ; new stack
    call idt_init
    call pic_init

    mov al, 0xFE
    out 0x21, al
    sti

    mov edi, 0xB8000
    mov esi, message
    mov ah, 0x0F ;white on black


print:
    lodsb
    test al, al
    jz halt

    mov [edi], ax
    add edi, 2

    jmp print

halt:
    hlt
    jmp halt

message db "Booted in protected mode                                      ", 0 ;hide label

%include "../kernel/interrupts/interrupts.asm"
%include "../kernel/interrupts/idt.asm"
%include "../kernel/interrupts/pic.asm"

times 2560 - ($ - $$) db 0
dw 0xAA55