
section .data
    sad: db 'sad',10
section .text
global _start

_exit:
    mov rax,60
    ;pop rdi
    mov rdi,0
    syscall

_start:
    mov rcx,0
    main_loop:
        push rcx
        mov rax,1
        mov rdi,0
        mov rsi,sad
        mov rdx,4
        syscall
        pop rcx ;LA SYSCALL ANTERIOR MODIFICA EL RCX por eso se enclocha
        inc rcx
        cmp rcx,10
        jnz main_loop
	
    call _exit
        