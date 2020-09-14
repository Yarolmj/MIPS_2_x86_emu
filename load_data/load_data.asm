section .data
    instruction_buffer: TIMES 330000 dq '*' ;10000 instrucciones * 32 bit + 10000 saltos de linea = limite del buffer de instrucciones es 10000
    filename: db "/home/yarol/MIPS x86/MIPS_2_x86_emu/MIPS TEST/mips1.txt",0

section .text
global _start




_read_text:
    ;file open
    mov rax,2
    mov rdi,filename
    mov rsi,0
    mov rdx,0
    syscall
    ;file read to buffer
    mov rdi,rax
    mov rax,0
    mov rsi,instruction_buffer
    mov rdx,33*2
    syscall
    ;print the readed information
    mov rax,1
    mov rdi,0
    mov rsi,instruction_buffer
    mov rdx,33*2
    syscall
    ret
_exit:
    mov rax,60
    ;pop rdi
    mov rdi,0
    syscall
_start:
    call _read_text
    call _exit


