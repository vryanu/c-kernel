BITS 32

%define CODE_SEG 0x08
%define IDT_ENTRIES 256

; call extern labels
extern handler
extern timer_handler
extern keyboard_handler
; create globally used label
global idt_init

section .bss
align 8

idt_start:
    resb IDT_ENTRIES * 8

idt_end:

section .data
align 4

idt_descripter:
    dw idt_end - idt_start - 1
    dd idt_start

handler_table: ; create full 32bit table
%assign i 0
%rep IDT_ENTRIES
    %if i = 32 ; lower bits use timer or handler if past 32
        dd timer_handler
    %elif i = 33
        dd keyboard_handler
    %else
        dd handler
    %endif
%assign i i + 1
%endrep

section .text

idt_init:
    pushad

    mov esi, handler_table
    mov edi, idt_start
    mov ecx, IDT_ENTRIES

.fill_idt:
    mov eax, [esi]
    mov [edi], ax ; low 16bits

    mov word [edi + 2], CODE_SEG ; cs selector

    mov byte [edi + 4], 0 ; Reserved byte

    mov byte [edi + 5], 0x8E ; interrupt gate

    shr eax, 16 ; high 16 bits
    mov [edi + 6], ax

    add esi, 4
    add edi, 8

    loop .fill_idt ; fully fill

    lidt [idt_descripter]

    popad
    ret
