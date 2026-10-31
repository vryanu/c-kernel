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

; shared variables with C
%define KEYBOARD_BUFFER 0x70000
%define KEYBOARD_LEN 0x70080
%define COMMAND_READY 0x70084
%define KEYBOARD_CURSOR 0x70088

start:
    cli

    xor ax, ax ; reset
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00 ; stack

    mov [boot_drive], dl

    ; A20 line go over 1mb
    in al, 0x92
    or al, 00000010b
    and al, 11111110b
    out 0x92, al

    call load_kernel ; load kernel during BIOS

    lgdt [gdt_descripter] ; load descripter

    mov eax, cr0 ; load control
    or eax, 1 ; set 0
    mov cr0, eax ; back to control

    jmp dword CODE_SEG:protected_mode

; load kernel from disk
load_kernel:
    mov si, disk_packet
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13

    jc disk_error
    ret

disk_error:
    mov si, disk_error_msg

.print_error:
    lodsb
    test al, al
    jz disk_halt

    mov ah, 0x0E
    int 0x10
    jmp .print_error

disk_halt:
    cli

.halt:
    hlt
    jmp .halt

boot_drive db 0

disk_error_msg db "Kernel failed to read", 13, 10, 0

; make disk packet address
align 4
disk_packet:
    db 0x10 ; packet size
    db 0 ; reserve
    dw 16 ; sectors
    dw 0x0000 ; offset dest
    dw 0x1000 ; segment dest
    dq 8 ; start (9)


; PROTECTED

BITS 32 ; enter 32 bit mode

protected_mode:
    mov ax, DATA_SEG ; set all data_seg

    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov dword [KEYBOARD_LEN], 0
    mov byte [COMMAND_READY], 0
    mov dword [KEYBOARD_CURSOR], 0xB8140

    mov esp, 0x90000 ; new stack

    mov eax, 0x10000 ; call the kernel
    call eax

halt:
    cli
.halt:
    hlt
    jmp .halt

message db "Booted in protected mode                                      ", 0 ;hide label

times 3584 - ($ - $$) db 0