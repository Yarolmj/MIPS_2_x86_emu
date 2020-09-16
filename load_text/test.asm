section .data
    var: db 0

section .text
global _start
    _start:
        mov r8,54
        mov byte [var],r8b
        ALTO:
        mov r9,[var]
        ;and r9,0xFF
        call _exit
    _exit:
    mov rax,60
    ;pop rdi
    mov rdi,0
    syscall