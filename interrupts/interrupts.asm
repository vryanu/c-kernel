;IRQ
ticks dd 0
hex_digits db "0123456789ABCDEF"

timer_handler:
    pushad

    inc dword [ticks]

    mov eax, [ticks]

    mov ebx, eax
    and ebx, 0x0F
    mov dl, [hex_digits + ebx]
    mov dh, 0x0F
    mov [0xB80A0], dx

    shr eax, 4
    and eax, 0x0F
    mov dl, [hex_digits + eax]
    mov [0xB80A2], dx

    mov al, 0x20
    out 0x20, al

    popad
    iretd


handler:
    cli

    mov edi, 0xB8000
    mov esi, exception_msg
    mov ah, 0x4F

.print:
    lodsb
    test al, al
    jz .halt

    mov [edi], ax
    add edi, 2
    jmp .print

.halt:
    hlt
    jmp .halt

exception_msg db "CPU Exception", 0