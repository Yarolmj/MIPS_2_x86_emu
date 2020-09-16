%macro printint 1
    mov rax,1
    mov rdi,1
    mov rsi,%1
    mov rdx,1
    syscall
%endmacro

section .data
    ;hex_to_dec: db "0123456789abcdef",0
    load_byte_buffer: db 0,0
    instruction_buffer: TIMES 4096 db 0 ;10000 instrucciones * 4bytes = limite del buffer de instrucciones es 4 MBytes
    data_buffer: TIMES 4096 db 0; Buffer del .data 4 MBytes

    ;instruction_opcodes: TIMES 10000 db 0 ; guarda los opcodes de las 10000 instrucciones de instruction_buffer
    filename_text: db "/home/yarol/MIPS x86/MIPS_2_x86_emu/MIPS TEST/hex1.txt",0
    filename_data: db "/home/yarol/MIPS x86/MIPS_2_x86_emu/MIPS TEST/pong data hex.txt",0

    ;example: db "HOLA PUTOS",10
    ;example2: db "HOLA2PUTOS",10
    ;example3: db "HOLA3PUTOS",10
    ;nl: db 10
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

    mov rcx,0 ;contador
    mov rdi,rax
    mov r8,0
    mov r9,0

    rt_loop:
    ;file read to buffer
        push rcx
        push rdi


        mov rax,0

        mov rsi,load_byte_buffer
        mov rdx,2
        syscall
        cmp rax,1
        jz rt_loop_end

        mov r8,[load_byte_buffer]
        mov r9,[load_byte_buffer+1]
        and r8,0xFF
        and r9,0xFF
        cmp r8,10
        jz rt_nl
        break1:
        cmp r8,57
        jle rt_num1
        jmp rt_let1
        rt_num1:
            sub r8,48
            ;and r8,0x0F
            jmp rt_byte2
        rt_let1:
            sub r8,87
            and r8,0xFF
            jmp rt_byte2
        rt_nl:
            mov r8,r9

            mov rax,0
            pop rdi
            push rdi

            mov rsi,load_byte_buffer
            mov rdx,1
            syscall

            mov r9,[load_byte_buffer]
            and r9,0xFF
            jmp break1

        rt_byte2:
        cmp r9,57
        jle rt_num2
        jmp rt_let2

        rt_num2:
            sub r9,48
            and r9,0xFF
            jmp stop
        rt_let2:
            sub r9,87
            and r9,0xFF
            jmp stop
        stop:
        ALTO: 
        mov rax,r8
        mov r8,16
        mul r8
        mov r8,rax
        
        add r8,r9

        jmp rt_next_loop
    rt_loop_end:
        pop rdi
        pop rcx
        ret
    rt_next_loop:
        pop rdi
        pop rcx
        ;push rdi
        ;push rcx
        
        mov byte [instruction_buffer + rcx],r8b ;Guarda el dato en memoria antes del siguiente salto
        
        ;pop rcx
        ;pop rdi
        inc rcx
        cmp rcx,4096
        jnz rt_loop
        ret

_read_data:
    ;file open
    mov rax,2
    mov rdi,filename_data
    mov rsi,0
    mov rdx,0
    syscall

    mov rcx,0 ;contador
    mov rdi,rax
    mov r8,0
    mov r9,0

    rt_loop:
    ;file read to buffer
        push rcx
        push rdi


        mov rax,0

        mov rsi,load_byte_buffer
        mov rdx,2
        syscall
        cmp rax,1
        jz rt_loop_end

        mov r8,[load_byte_buffer]
        mov r9,[load_byte_buffer+1]
        and r8,0xFF
        and r9,0xFF
        cmp r8,10
        jz rt_nl
        break1:
        cmp r8,57
        jle rt_num1
        jmp rt_let1
        rt_num1:
            sub r8,48
            ;and r8,0x0F
            jmp rt_byte2
        rt_let1:
            sub r8,87
            and r8,0xFF
            jmp rt_byte2
        rt_nl:
            mov r8,r9

            mov rax,0
            pop rdi
            push rdi

            mov rsi,load_byte_buffer
            mov rdx,1
            syscall

            mov r9,[load_byte_buffer]
            and r9,0xFF
            jmp break1

        rt_byte2:
        cmp r9,57
        jle rt_num2
        jmp rt_let2

        rt_num2:
            sub r9,48
            and r9,0xFF
            jmp stop
        rt_let2:
            sub r9,87
            and r9,0xFF
            jmp stop
        stop:
        ALTO: 
        mov rax,r8
        mov r8,16
        mul r8
        mov r8,rax
        
        add r8,r9

        jmp rt_next_loop
    rt_loop_end:
        pop rdi
        pop rcx
        ret
    rt_next_loop:
        pop rdi
        pop rcx

        mov byte [data_buffer + rcx],r8b ;Guarda el dato en memoria antes del siguiente salto

        inc rcx
        cmp rcx,4096
        jnz rt_loop
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


