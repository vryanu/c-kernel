BITS 16 ; 16bit mode
ORG 0x7C00 ; origin address

start:
    xor ax, ax ; clear ax, set segs 0
    mov ds, ax ; data seg
    mov es, ax ; extra seg
    mov ss, ax ; stack seg
    mov sp, 0x7C00 ; set stack pointer to top

    mov [BOOT_DRIVE], dl ; save BIOS
    
    mov ah, 0x02 ; load stage 2 to x8000
    mov al, 5
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    mov bx, 0x8000
    int 0x13

    jc disk_error

    jmp 0x0000:0x8000 ; enter stage 2

disk_error:
    mov si, error_msg

.print_error: ; handle error
    lodsb ; loop bytes
    test al, al
    jz halt

    mov ah, 0x0E ; video
    int 0x10
    jmp .print_error ; loop bytes

halt:
    cli

.loop:
    hlt ; idle halt
    jmp .loop

BOOT_DRIVE db 0
error_msg db "Cant read disk!", 13, 10, 0

times 510 - ($ - $$) db 0 ; fill the remaining bytes with zeros (510)
dw 0xAA55 ; boot signature 0x55 & 00xAA (510)
