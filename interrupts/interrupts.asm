;IRQ
timer_ticks dd 0
hex_digits db "0123456789ABCDEF"

keyboard_cursor dd 0xB8140 ; Start on row 2

;chars
keymap:
    db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0, 0
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0, 'a', 's'
    db 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 0x27, '`', 0, 0x5C, 'z', 'x', 'c', 'v'
    db 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' '

timer_handler: ; IRQ0 timer
    pushad

    inc dword [timer_ticks]

    mov eax, [timer_ticks]

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

keyboard_handler: ; IRQ1 keyboard
    pushad

    in al, 0x60 ; read input
    movzx ebx, al

    test bl, 0x80 ; ignore keyreleases
    jnz .eoi
 
    cmp ebx, 58 ; ignore other inputs
    jae .eoi

    mov al, [keymap + ebx] ; translate to ASCII
    test al, al
    jz .eoi

    mov ah, 0x0F ; print to VGA
    mov edi, [keyboard_cursor]
    mov [edi], ax

    add edi, 2 ; move cursor

    cmp edi, 0xB8FA0 ; add wrapping
    jb .save_cursor

    mov edi, 0xB8140

.save_cursor: ; save cursor address
    mov [keyboard_cursor], edi

.eoi:
    mov al, 0x20
    out 0x20, al

    popad
    iretd

handler: ; default handler
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