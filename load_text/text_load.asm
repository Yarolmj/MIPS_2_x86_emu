%macro printint 1
    mov rax,1
    mov rdi,1
    mov rsi,%1
    mov rdx,1
    syscall
%endmacro

section .data
    hex_to_dec: db "0123456789abcdef",0
    instruction_byte_buffer: db 0,0
    instruction_buffer: TIMES 40000 db 0 ;10000 instrucciones * 4bytes = limite del buffer de instrucciones es 10000

    instruction_opcodes: TIMES 10000 db 0 ; guarda los opcodes de las 10000 instrucciones de instruction_buffer
    filename_text: db "/home/yarol/MIPS x86/MIPS_2_x86_emu/MIPS TEST/hex1.txt",0

    example: db "HOLA PUTOS",10
    example2: db "HOLA2PUTOS",10
    example3: db "HOLA3PUTOS",10
section .text
global _start


_wait_for_input:
    ret
_traslade_opcodes:

_read_text:
    ;file open
    mov rax,2
    mov rdi,filename_text
    mov rsi,0
    mov rdx,0
    syscall

    mov rcx,0
    _rt_loop:
    ;file read to buffer
        
        mov rdi,rax
        mov rax,0
        mov rsi,instruction_byte_buffer
        mov rdx,2
        syscall
        mov r8b,[instruction_byte_buffer]
        mov r9,instruction_byte_buffer+1
        sub r9,48
        add r8,r9
        ;mov r10,instruction_buffer
        ;stop_:
        sub r8b,48
        mov [instruction_buffer],r8b
        ;inc rcx
        ;cmp rcx,40000
        ;jz _rt_loop
    _rt_loop_end:
    ;print the readed information
    mov rax,1
    mov rdi,0
    mov rsi,instruction_buffer
    mov rdx,40000
    syscall
    ret
_exit:
    mov rax,60
    ;pop rdi
    mov rdi,0
    syscall
_start:
    mov r8,85
    _stop2:
    call _wait_for_input
    call _read_text
    call _exit


