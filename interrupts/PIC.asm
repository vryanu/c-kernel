;programmable interrupt controller
BITS 32
global pic_init
;master
PIC1_COMMAND equ 0x20;32
PIC1_DATA    equ 0x21;33
PIC1_OFFSET  equ 0x20;32

;slave
PIC2_COMMAND equ 0xA0;160
PIC2_DATA    equ 0xA1;161
PIC2_OFFSET  equ 0x28;40

; master 0-7 slave 8-15 start from 32

pic_init:
    mov al, 0x11 ; start initialize PIC
    out PIC1_COMMAND, al ; send to output
    out PIC2_COMMAND, al

    mov al, PIC1_OFFSET ; set master to interrupt 32
    out PIC1_DATA, al

    mov al, PIC2_OFFSET ; slave interrupt 40
    out PIC2_DATA, al

    mov al, 0x04 ; slave is on IRQ2
    out PIC1_DATA, al

    mov al, 0x02
    out PIC2_DATA, al

    mov al, 0x01 ; 8086
    out PIC1_DATA, al
    out PIC2_DATA, al

    mov al, 0xFC
    out PIC1_DATA, al

    mov al, 0xFF
    out PIC2_DATA, al

    ret