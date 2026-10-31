BITS 32

%define KEYBOARD_BUFFER 0x70000
%define KEYBOARD_LEN 0x70080
%define COMMAND_READY 0x70084
%define KEYBOARD_CURSOR 0x70088

global handler
global keyboard_handler
global timer_handler

extern terminal_color

timer_ticks dd 0
hex_digits db "0123456789ABCDEF"


shift_pressed db 0

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

    cmp dword [KEYBOARD_LEN], 127 ; check size
    jae .eoi

    mov ecx, [KEYBOARD_LEN] ; add char to input buffer
    mov [KEYBOARD_BUFFER + ecx], al
    inc dword [KEYBOARD_LEN]

    mov ah, 0x0F ; print loop
    mov edi, [KEYBOARD_CURSOR]

    mov cl, al

    movzx eax, byte [terminal_color]
    shl eax, 8
    mov al, cl
    
    mov [edi], ax

    add edi, 2
    mov [KEYBOARD_CURSOR], edi

    call vga_update_cursor ; update cursor after print
    jmp .eoi

.shift_down:
    mov byte [shift_pressed], 1
    cmp byte [COMMAND_READY], 1
    jmp .eoi

.shift_up:
    mov byte [shift_pressed], 0
    cmp byte [COMMAND_READY], 1
    jmp .eoi

.backspace:
    cmp dword [KEYBOARD_LEN], 0
    je .eoi

    dec dword [KEYBOARD_LEN]

    mov ecx, [KEYBOARD_LEN]
    mov byte [KEYBOARD_BUFFER + ecx], 0

    mov edi, [KEYBOARD_CURSOR] ; removes last buffer byte
    cmp edi, 0xB8000
    jbe .eoi

    sub edi, 2

    movzx eax, byte [terminal_color]
    shl eax, 8
    mov al, ' '

    mov [edi], ax
    mov [KEYBOARD_CURSOR], edi

    call vga_update_cursor ; update cursor after deletion
    jmp .eoi

.enter:
    mov ecx, [KEYBOARD_LEN] ; terminate current input
    mov byte [KEYBOARD_BUFFER + ecx], 0
    mov byte [COMMAND_READY], 1 ; read command

    mov edi, [KEYBOARD_CURSOR] ; Move cursor to next line
    mov eax, edi
    sub eax, 0xB8000

    xor edx, edx
    mov ebx, 160 ; length of a line = 160
    div ebx

    inc eax
    imul eax, 160
    add eax, 0xB8000

    mov [KEYBOARD_CURSOR], eax
    call vga_update_cursor ; move cursor down
    jmp .eoi

.save_cursor: ; save cursor address
    mov [KEYBOARD_CURSOR], edi

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
    mov eax, [KEYBOARD_CURSOR] ; convert VGA memory address to a char index
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