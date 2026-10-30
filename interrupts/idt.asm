;Interrupt description table
entries equ 256 ; interrupts

idt_start:
; create the entries
%assign i 0
%rep entries
    %if i = 32 ; lower bits use timer or handler if past 32
        dw timer_handler
    %else
        dw handler
    %endif
    dw CODE_SEG ; select
    db 0 ; reserve
    db 0x8E ; attribute 
    dw 0 ; shift for upper 16 bits
    %assign i i+1
%endrep

idt_end:

idt_descripter:
    dw idt_end - idt_start - 1 ; limit
    dd idt_start

idt_init: ; load the idt
    lidt [idt_descripter]
    ret