timer_ticks dd 0
hex_digits db "0123456789ABCDEF"

shift_pressed db 0

keyboard_len dd 0
keyboard_buffer times 128 dd 0

keyboard_cursor dd 0xB8140 ; Start on row 2

;chars
keymap:
    db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0, 0
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0, 'a', 's'
    db 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 0x27, '`', 0, 0x5C, 'z', 'x', 'c', 'v'
    db 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' '
;shift held chars
shift_keymap:
    db 0, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 0, 0
    db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 0, 0, 'A', 'S'
    db 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0, '|', 'Z', 'X', 'C', 'V'
    db 'B', 'N', 'M', '<', '>', '?', 0, 0, 0, ' '

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

keyboard_handler: ;IRQ1 keyboard
    pushad

    in al, 0x60
    movzx ebx, al

    cmp bl, 0x2A ; check shifts
    je .shift_down
    cmp bl, 0x36
    je .shift_down

    cmp bl, 0xAA ; check shifts released
    je .shift_up
    cmp bl, 0xB6
    je .shift_up

    test bl, 0x80 ; ignore other keys
    jnz .eoi

    cmp bl, 0x0E ; Backspace
    je .backspace

    cmp bl, 0x1C ; Enter
    je .enter

    cmp ebx, 58 ; Must be below 58
    jae .eoi

    cmp byte [shift_pressed], 1 ; select a table
    je .shifted

    mov al, [keymap + ebx]
    jmp .character

.shifted: ; send shifted char
    mov al, [shift_keymap + ebx]

.character:
    test al, al
    jz .eoi

    cmp dword [keyboard_len], 127 ; check size
    jae .eoi

    mov ecx, [keyboard_len] ; add char to input buffer
    mov [keyboard_buffer + ecx], al
    inc dword [keyboard_len]

    mov ah, 0x0F ; print loop
    mov edi, [keyboard_cursor]
    mov [edi], ax
    add edi, 2

    mov [keyboard_cursor], edi
    call vga_update_cursor ; update cursor after print
    jmp .eoi

.shift_down:
    mov byte [shift_pressed], 1
    jmp .eoi

.shift_up:
    mov byte [shift_pressed], 0
    jmp .eoi

.backspace:
    cmp dword [keyboard_len], 0
    je .eoi

    dec dword [keyboard_len] ; removes last buffer byte

    mov ecx, [keyboard_len]
    mov byte [keyboard_buffer + ecx], 0

    mov edi, [keyboard_cursor] ; erase from VGA
    call vga_update_cursor ; update cursor after deletion
    sub edi, 2

    mov word [edi], 0x0F20
    mov [keyboard_cursor], edi
    jmp .eoi

.enter:
    mov ecx, [keyboard_len] ; terminate current input
    mov byte [keyboard_buffer + ecx], 0

    mov dword [keyboard_len], 0 ; reset buffer len

    mov edi, [keyboard_cursor] ; Move cursor to next line
    call vga_update_cursor ; move cursor down
    mov eax, edi
    sub eax, 0xB8000

    xor edx, edx
    mov ebx, 160 ; length of a line = 160
    div ebx

    inc eax
    imul eax, 160
    add eax, 0xB8000

    mov [keyboard_cursor], eax
    jmp .eoi

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

vga_update_cursor:
    mov eax, [keyboard_cursor] ; convert VGA memory address to a char index
    sub eax, 0xB8000
    shr eax, 1

    mov ebx, eax ; Set position low
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al

    inc dx
    mov al, bl
    out dx, al

    dec dx ; Set position high
    mov al, 0x0E
    out dx, al

    inc dx
    mov al, bh
    out dx, al

    ret ; return

exception_msg db "CPU Exception", 0