bits 64
default rel


; Acá básicamente le estoy asignando nombres a los syscalls
sys_read: equ 0	
sys_write:	equ 1
sys_nanosleep:	equ 35
sys_time:	equ 201
sys_fcntl:	equ 72


; Asigno nombres a cada parte de las intrucciones
opcode: equ 0
rs: equ 1
rt: equ 2
rd: equ 3
shamt: equ 4
funct: equ 5
SigImm: equ 6
ZeroImm: equ 7
address: equ 8

MEM_offset: equ 268500992
pc_base_address: equ 4194304
heap_base_address: equ 268697600
; Leer de consola es a través de STDIN
STDIN_FILENO: equ 0
;Necesario para limpiar consona
F_SETFL:	equ 0x0004
O_NONBLOCK: equ 0x0004


;La pantalla se define como texto, pueden modificarle el tamaño
row_cells:	equ 32	; 
column_cells: 	equ 80 ; 
array_length:	equ row_cells * column_cells + row_cells ; Esto es un mapao lineal de la consola, la necesitan para escribir caracteres

; Esto es para hacer un sleep
timespec:
    tv_sec  dq 0
    tv_nsec dq 200000000

delay:
    tv_sec_delay dq 0
    tv_nsec_delay dq 1000000

;Este comando es para limpiar la pantalla, no es intuitivo usenlo como tal
clear:		db 27, "[2J", 27, "[H"
clear_length:	equ $-clear
	
	

; Pantalla de inicio, ahorita no se pitna
msg1: db "        TECNOLOGICO DE COSTA RICA        ", 0xA, 0xD ; Investiguen porque pongo esto
msg2: db "        ERNESTO RIVERA ALVARADO        ", 0xA, 0xD
msg3: db "        INTENTO DE ARKANOID CLONE        ", 0xA, 0xD
msg4: db "        PRESIONE ENTER PARA INICIAR        ", 0xA, 0xD
msg1_length:	equ $-msg1
msg2_length:	equ $-msg2
msg3_length:	equ $-msg3
msg4_length:	equ $-msg4


;Investiguen cómo hacer macros en assembler, es muy util y le pueden poner argumentos 
%macro caso 3
    cmp %1,%2
    jz %3
%endmacro


%macro extract 2
    mov rdi,%1
    call extract_from_instruction
    mov %2,rax
%endmacro


; Este par que están tienen que ver con lo de consola y no bloquearla, uselos tal cual
%macro setnonblocking 0
	mov rax, sys_fcntl
    mov rdi, STDIN_FILENO
    mov rsi, F_SETFL
    mov rdx, O_NONBLOCK
    syscall
%endmacro

%macro unsetnonblocking 0
	mov rax, sys_fcntl
    mov rdi, STDIN_FILENO
    mov rsi, F_SETFL
    mov rdx, 0
    syscall
%endmacro

; Este es para escribir una linea llena de X
%macro full_line 0
    times column_cells db "X"
    db 0x0a, 0xD
%endmacro

; Una linea con X a los bordes, tal como la que se pinta
%macro hollow_line 0
    db "X"
    times column_cells-2 db " "
    db "X", 0x0a, 0xD
%endmacro


%macro print 2
	mov eax, sys_write ; Aca le digo cual syscall quier aplicar
	mov edi, 1 	; stdout, Aca le digo a donde quiero escribir
	mov rsi, %1 ;Aca va el mensaje
	mov edx, %2 ;Aca el largo del mensaje
	syscall
%endmacro

;Usenlo tal cual está acá
%macro getchar 0
	mov     rax, sys_read
    mov     rdi, STDIN_FILENO
    mov     rsi, input_char
    mov     rdx, 1 ; Numero de bytes que vamos a leer (solo es uno)
    syscall         ;recuperar el texto desde la consola
%endmacro

%macro getinteger 1
    mov     rax, sys_read
    mov     rdi, STDIN_FILENO
    mov     rsi, input_int
    mov     rdx, %1
    syscall
%endmacro


%macro sleeptime 0
	mov eax, sys_nanosleep
	mov rdi, timespec
	xor esi, esi		; ignore remaining time in case of call interruption
	syscall			; sleep for tv_sec seconds + tv_nsec nanoseconds
%endmacro



global _start

section .bss ; Este es el segmento de datos para variables estáticas, aca se reserva un byte para lo que se lee de consola

input_char: resb 1
input_int:  resb 20

section .data ;variables globales se agregan aqui
;Esto se inicializa antes de que el código se ejecute
beep db 7 ; "BELL"
		

	board: ;Noten que esto es una dirección de memoria donde ustedes tendran que escribir
		full_line
        %rep 30
        hollow_line
        %endrep
        full_line
	board_size:   equ   $ - board

	; Esto se requiere para que la termina no se bloquee usar tal cual
	termios:        times 36 db 0
	stdin:          equ 0
	ICANON:         equ 1<<1
	ECHO:           equ 1<<3
	VTIME: 			equ 5
	VMIN:			equ 6
	CC_C:			equ 18

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;.data del emulador;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    load_byte_buffer: db 0,0
    instruction_buffer: TIMES 4000000 db 0 ;10000 instrucciones * 4bytes = limite del buffer de instrucciones es 4 MBytes
    data_buffer: TIMES 4000000 db 0; Buffer del .data 4 MBytes

    filename_text: db "/home/yarol/MIPS x86/MIPS_2_x86_emu/MIPS TEST/hex2.text",0
    filename_data: db "/home/yarol/MIPS x86/MIPS_2_x86_emu/MIPS TEST/hex2.data",0

    reg: TIMES 32 dd 0 ;;;EMULACION EN MEMORIA DE LOS 32 REGISTROS DE MIPS
    hi_reg: dd 0
    lo_reg: dd 0

    pc_address: dd 0 ;;;Direccion pc actual 
    ;;;;;;;;;;;;;;;;;;;;;;;;;fin .data del emulador;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text

;Acá va el código que se va a utilizar
;;;;;;;;;;;;;;;;;;;;Todo esto es para lo de la terminal, usar tal cual;;;;;;;;;;;;;;;;;
canonical_off:
        call read_stdin_termios

        ; clear canonical bit in local mode flags
        push rax
        mov eax, ICANON
        not eax
        and [termios+12], eax
		mov byte[termios+CC_C+VTIME], 0
		mov byte[termios+CC_C+VMIN], 0
        pop rax

        call write_stdin_termios
        ret

echo_off:
        call read_stdin_termios

        ; clear echo bit in local mode flags
        push rax
        mov eax, ECHO
        not eax
        and [termios+12], eax
        pop rax

        call write_stdin_termios
        ret

canonical_on:
        call read_stdin_termios

        ; set canonical bit in local mode flags
        or dword [termios+12], ICANON
		mov byte[termios+CC_C+VTIME], 0
		mov byte[termios+CC_C+VMIN], 1
        call write_stdin_termios
        ret

echo_on:
        call read_stdin_termios

        ; set echo bit in local mode flags
        or dword [termios+12], ECHO

        call write_stdin_termios
        ret

read_stdin_termios:
        push rax
        push rbx
        push rcx
        push rdx

        mov eax, 36h
        mov ebx, stdin
        mov ecx, 5401h
        mov edx, termios
        int 80h

        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

write_stdin_termios:
        push rax
        push rbx
        push rcx
        push rdx

        mov eax, 36h
        mov ebx, stdin
        mov ecx, 5402h
        mov edx, termios
        int 80h

        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

;;;;;;;;;;;;;;;;;;;;final de lo de la terminal;;;;;;;;;;;;
;;;;;;;;;;;;;;;;INICIO DE FUNCIONES DEL EMULADOR;;;;;;;;;;

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
        rt_clean:
        cmp r8,57
        jle rt_num1
        jmp rt_let1
        rt_num1:
            sub r8,48
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
            jmp rt_clean

        rt_byte2:
        cmp r9,57
        jle rt_num2
        jmp rt_let2

        rt_num2:
            sub r9,48
            and r9,0xFF
            jmp rt_deco
        rt_let2:
            sub r9,87
            and r9,0xFF
            jmp rt_deco
        rt_deco:
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

        mov byte [instruction_buffer + rcx],r8b ;Guarda el dato en memoria antes del siguiente salto

        inc rcx
        cmp rcx,4000000
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

    rd_loop:
    ;file read to buffer
        push rcx
        push rdi


        mov rax,0

        mov rsi,load_byte_buffer
        mov rdx,2
        syscall
        cmp rax,1
        jz rd_loop_end

        mov r8,[load_byte_buffer]
        mov r9,[load_byte_buffer+1]
        and r8,0xFF
        and r9,0xFF
        cmp r8,10
        jz rd_nl
        rd_clean:
        cmp r8,57
        jle rd_num1
        jmp rd_let1
        rd_num1:
            sub r8,48
            ;and r8,0x0F
            jmp rd_byte2
        rd_let1:
            sub r8,87
            and r8,0xFF
            jmp rd_byte2
        rd_nl:
            mov r8,r9

            mov rax,0
            pop rdi
            push rdi

            mov rsi,load_byte_buffer
            mov rdx,1
            syscall

            mov r9,[load_byte_buffer]
            and r9,0xFF
            jmp rd_clean

        rd_byte2:
        cmp r9,57
        jle rd_num2
        jmp rd_let2

        rd_num2:
            sub r9,48
            and r9,0xFF
            jmp rd_deco
        rd_let2:
            sub r9,87
            and r9,0xFF
            jmp rd_deco
        rd_deco:
        mov rax,r8
        mov r8,16
        mul r8
        mov r8,rax
        
        add r8,r9

        jmp rd_next_loop
    rd_loop_end:
        pop rdi
        pop rcx
        ret
    rd_next_loop:
        pop rdi
        pop rcx

        mov byte [data_buffer + rcx],r8b ;Guarda el dato en memoria antes del siguiente salto

        inc rcx
        cmp rcx,4000000
        jnz rd_loop
        ret

;;;;Pasa data_buffer de big-endian a little-endian
_fix_data:
    mov rcx,0
    _fd_loop:
        mov r8d,[data_buffer+rcx*4]
        BSWAP r8d
        mov dword[data_buffer+rcx*4],r8d
        
        inc rcx
        cmp rcx,1000000
        jnz _fd_loop
    ret
;;;rdi = elemento a extraer 0 = opcode, 1 = rs, 2 = rt, 3 = rd, 4 = shamt, 5 = funct, 6 = imm con signo, 7 = imm sin signo,8 = address
extract_from_instruction:
    ;Opcode
    mov r8,[pc_address]
    
    ;;;;;;;;Simil de un switch case
    cmp rdi,0
    jz efi_opcode

    cmp rdi,1
    jz efi_rs
    
    cmp rdi,2
    jz efi_rt

    cmp rdi,3
    jz efi_rd

    cmp rdi,4
    jz efi_shamt

    cmp rdi,5
    jz efi_funct

    cmp rdi,6
    jz efi_SignExtImm

    cmp rdi,7
    jz efi_ZeroExtImm

    cmp rdi,8
    jz efi_address

    ;;Si no es ninguna cierra el programa inmediatamente
    call exit
    efi_opcode:
        mov r9,[instruction_buffer+r8]
        and r9,0xFC ; 1111 1100
        
        shr r9,2
        mov rax,r9
        ret
    efi_rs:
        mov r9,[instruction_buffer+r8]
        and r9,0x3 ; 0000 0011
        mov r10,[instruction_buffer+r8+1]
        and r10,0xE0; 1110 0000

        shl r9,3
        shr r10,5

        add r9,r10
        mov rax,r9
        ret

    efi_rt:
        mov r9,[instruction_buffer+r8+1]
        and r9,0x1F ; 0001 1111
        
        mov rax,r9
        ret

    efi_rd:
        mov r9,[instruction_buffer+r8+2]
        and r9,0xF8 ; 1111 1000
        
        shr r9,3
        mov rax,r9
        ret
    
    efi_shamt:
        mov r9,[instruction_buffer+r8+2]
        and r9,0x7 ; 0000 0111
        mov r10,[instruction_buffer+r8+3]
        and r10,0xC0   ; 1100 0000

        shl r9,2
        shr r10,6

        add r9,r10
        mov rax,r9
        ret

    efi_funct:
        mov r9,[instruction_buffer+r8+3]
        and r9,0x3F ; 0011 1111

        mov rax,r9
        ret
    efi_SignExtImm:
        mov r9,[instruction_buffer+r8+2]
        and r9,0xFF ; 1111 1111
        mov r10,[instruction_buffer+r8+3]
        and r10,0xFF ; 1111 1111

        shl r9,8
        add r9,r10

        ;;Ahora la parte del signo
        mov r10,r9
        shr r10,15

        cmp r10,1
        jz efi_SignExtImm_minus
        ;;; es positivo
        mov rax,r9
        ret
        ;;; es negativo
        efi_SignExtImm_minus:
            or r9,0xFFFFFFFFFFFF0000 ;; 32x1 1111 1111
            mov rax,r9
            ret
    efi_ZeroExtImm:
        mov r9,[instruction_buffer+r8+2]
        and r9,0xFF ; 1111 1111
        mov r10,[instruction_buffer+r8+3]
        and r10,0xFF ; 1111 1111

        shl r9,8
        add r9,r10

        mov rax,r9
        ret
    efi_address:
        mov r10,0
        
        mov r9,[instruction_buffer+r8+3]
        and r9,0xFF
        add r10,r9

        mov r9,[instruction_buffer+r8+2]
        and r9,0xFF
        shl r9,8
        add r10,r9

        mov r9,[instruction_buffer+r8+1]
        and r9,0xFF
        shl r9,16
        add r10,r9

        mov r9,[instruction_buffer+r8]
        and r9,0x3
        shl r9,24
        add r10,r9

        shl r10,2 ;;r10*4

        mov rax,r10
        ret
_open_file:
    
    mov rcx, 0
    
    open_file_loop:



    inc rcx
    cmp rcx, 24
    jnz open_file_loop

    ret

;;;;; FUNCIONES BASICAS DE MIPS;;;;;;;;;
_sll:
    mov r8,[reg+rbx*4]
    shl r8,cl
    mov dword[reg+rdx*4],r8d
    ret
_srl:
    mov r8,[reg+rbx*4]
    ;and r8,0xFFFFFFFF ;;Elimina los bites innecesarios;;;; CUIAO CON LOS NEGATIVOS
    shr r8,cl
    mov dword[reg+rdx*4],r8d
    ret
_addi:
    mov r8,[reg+rbx*4]
    ;and r8,0xFFFFFFFF
    mov dword[reg+rcx*4],r8d
    add dword[reg+rcx*4],edx
    ret

_mult:
    mov eax,[reg+rbx*4];;cargo rs
    mov r9d,[reg+rcx*4];;cargo rt
    imul r9d
    
    mov dword[hi_reg],edx ;;Guardo la parte superior en el hi
    mov dword[lo_reg],eax ;;Guardo la parte inferior en lo
    ret

_mul:
    mov eax,[reg+rbx*4];;cargo rs
    mov r9d,[reg+rcx*4];;cargo rt
    mov r8,rdx
    mul r9d
    
    mov dword[hi_reg],edx ;;Guardo la parte superior en el hi
    mov dword[lo_reg],eax ;;Guardo la parte inferior en lo
    mov dword[reg+r8*4],eax ;;Guardo lo en rd
    ret

_multu:
    mov eax,[reg+rbx*4];;cargo rs
    mov r9d,[reg+rcx*4];;cargo rt
    mov r8,rdx
    imul r9d
    
    mov dword[hi_reg],edx ;;Guardo la parte superior en el hi
    mov dword[lo_reg],eax ;;Guardo la parte inferior en lo
    ret

_add:
    mov r8d,[reg+rbx*4]
    add r8d,[reg+rcx*4]
    mov dword[reg+rdx*4],r8d
    ret
_and:
    mov r8d,dword[reg+rbx*4]
    mov r9d,dword[reg+rcx*4]
    and r8d,r9d
    mov dword[reg+rdx*4],r8d
    ret
_or:
    mov r8d,dword[reg+rbx*4]
    mov r9d,dword[reg+rcx*4]
    or r8d,r9d
    mov dword[reg+rdx*4],r8d
    ret
_xor:
    mov r8d, [reg+rbx*4]
    mov r9d, [reg+rcx*4]
    xor r8d,r9d
    mov dword[reg+rdx*4],r8d
    ret
_nor:
    mov r8d,dword[reg+rbx*4]
    mov r9d,dword[reg+rcx*4]
    or r8d,r9d
    not r8d 
    mov dword[reg+rdx*4],r8d
    ret

_addu:
    mov r8d,[reg+rbx*4]
    add r8d,[reg+rcx*4]
    mov dword[reg+rdx*4],r8d
    ret
_lb:
    mov r8,0
    mov r8d,[reg+rbx*4]
    add r8d,edx
    sub r8d,MEM_offset
    mov r9b,[data_buffer+r8d]
    mov r10,r9
    and r10,0x80
    
    cmp r10,128
    jz _lb_minus
    jmp _lb_plus
    _lb_minus:
        or r9d,0xFFFFFF00
        mov dword[reg+rcx*4],r9d
        ret
    _lb_plus:
        and r9d,0xFF
        mov dword[reg+rcx*4],r9d
        ret
_lbu:
    mov r8,0
    mov r8d,[reg+rbx*4]
    add r8d,edx
    sub r8d,MEM_offset
    mov r9b,[data_buffer+r8d]
    and r9d,0xFF ;; Elimina signo
    mov dword[reg+rcx*4],r9d ;;Guarda en registro
    ret
_lw:
    mov r8,0
    mov r8d,[reg+rbx*4]
    cmp r8d,0xFFFF0000
    jz _lw_input
    cmp r8d,0xFFFF0004
    jz _lw_input
    add r8d,edx
    sub r8d,MEM_offset ;indice
    mov r9d,[data_buffer+r8d] ;MEM[indice]
    mov dword[reg+rcx*4],r9d
    ret
    _lw_input:
        mov r9b,[input_char]
        and r9b,0xFF
        mov dword[reg+rcx*4],r9d
        ret

_sw:
    mov r8,0
    mov r8d,[reg+rbx*4]
    cmp r8d,0xFFFF0000
    jz _sw_input
    cmp r8d,0xFFFF0004
    jz _sw_input
    add r8d,edx
    sub r8d,MEM_offset
    mov r9d,[reg+rcx*4]
    mov dword[data_buffer + r8d],r9d
    ret
    _sw_input:
        mov r9d,[reg+rcx*4]
        mov byte[input_char],r9b
        ret
_lui:
    shl rcx,16
    mov dword[reg+rbx*4],ecx
    ret

_jump:
    sub ebx,pc_base_address
    sub ebx,4
    mov dword[pc_address],ebx
    ret

_jal:
    sub ebx,pc_base_address
    sub ebx,4
    mov dword[pc_address],ebx
    mov dword[reg+31*4],ebx ;;Guarda en $ra
    ret  
_lhu:
    mov r8d,[reg+rbx*4] ;Reg[rs]
    add r8d,edx ;Reg[rs]+SignImm
    sub r8d,MEM_offset ;Reg[rs]+SignImm-MEM_offset
    mov r8d,[data_buffer + r8d] ; r8d = MEM[r8d]
    and r8d,0xFFFF ; r8 and 0000 0000 1111 1111
    mov dword[reg+rcx*4],r8d
    ret

_lh:
    mov r8d,[reg+rbx*4] ;Reg[rs]
    add r8d,edx ;Reg[rs]+SignImm
    sub r8d,MEM_offset ;Reg[rs]+SignImm-MEM_offset
    mov r8d,[data_buffer + r8d] ; r8d = MEM[r8d]
    movsx r9d,r8w
    mov dword[reg+rcx*4],r9d
    ret
_sb:
    mov r8d,[reg+rbx*4];Reg[rs]
    add r8d,edx ; Reg[rs] + SignImm
    sub r8d,MEM_offset
    mov r9b,[reg+rcx*4]
    mov byte[data_buffer+r8d],r9b
    ret
_sh:
    mov r8d,[reg+rbx*4];Reg[rs]
    add r8d,edx ; Reg[rs] + SignImm
    sub r8d,MEM_offset
    mov r9w,[reg+rcx*4]
    mov word[data_buffer+r8d],r9w
    ret
    ret
_mfhi:;R
    mov dword[reg+rdx*4],hi_reg
    ret
_mflo:;R
    mov dword[reg+rdx*4],lo_reg
    ret
_div_e:;R
    mov eax,[reg+rbx*4]
    mov r9d,[reg+rcx*4]
    idiv r9d
    
    mov dword[hi_reg],edx 
    mov dword[lo_reg],eax 
    ret
_divu_e:;R
    mov rax,[reg+rbx*4]
    ;and rax, 0xFFFFFFFF
    mov r9,[reg+rcx*4]
    ;and r9, 0xFFFFFFFF
    div r9
    
    mov dword[hi_reg],edx 
    mov dword[lo_reg],eax 
    ret
_sub:;R
    mov r8d,[reg+rbx*4]
    sub r8d,[reg+rcx*4]
    mov dword[reg+rdx*4],r8d
    ret
_subu:;R
    mov r8,[reg+rbx*4]
    and r8, 0xFFFFFFF
    mov r9,[reg+rcx*4]
    and r9, 0xFFFFFFF
    sub r8,r9
    mov dword[reg+rdx*4],r8d
    ret
_slt:;R
    mov r8d, [reg + rbx*4];extract rs,rbx
    mov r9d, [reg + rcx*4];extract rt,rdx
    cmp r8d, r9d
    jl slt_if
    mov dword[reg + rdx*4], 0 ;extract rd,rdx
    ret
    slt_if:
    mov dword[reg + rdx*4], 1
    ret
_sltu:;R
    mov r8d, [reg + rbx*4];extract rs,rbx
    and r8d, 0xFFFFFF
    mov r9d, [reg + rcx*4];extract rt,rdx
    and r9d, 0xFFFFFF
    cmp r8d, r9d
    jl sltu_if
    mov dword[reg + rdx*4], 0 ;extract rd,rdx
    ret
    sltu_if:
    mov dword[reg + rdx*4], 1
    ret
_bne:;R
    mov r8d, [reg + rbx*4]  ;extract rs,rbx
    mov r9d, [reg + rdx*4]  ;extract rt,rcx
    cmp r8d, r9d
    jne bne_if
    ret
    bne_if:
    add rdx, pc_address     ;extract SigImm,rdx
    mov dword[pc_address], edx
    ret
_beq:;R
    mov r8d, [reg + rbx*4]  ;extract rs,rbx
    mov r9d, [reg + rdx*4]  ;extract rt,rcx
    cmp r8d, r9d
    je beq_if
    ret
    beq_if:
    add rdx, pc_address     ;extract SigImm,rdx
    mov dword[pc_address], edx
    ret
_blez:;R
    mov r8d, [reg + rbx*4]  ;extract rs,rbx
    cmp r8d, 0
    jle blez_if
    ret
    blez_if:
    add rdx, pc_address     ;extract SigImm,rdx
    mov dword[pc_address], edx
    ret

_addiu:;R
    mov r8, [reg+rbx*4]
    mov r9, [reg+rdx*4]
    and r8, r9
    mov dword[reg+rcx*4],r8d
    ret
_slti:;R
    mov r8d, [reg + rbx*4];extract rs,rbx
    mov r9d, [reg + rdx*4];extract SigImm,rdx
    cmp r8d, r9d
    jl slti_if
    mov dword[reg + rcx*4], 0 ;extract rt,rcx
    ret
    slti_if:
    mov dword[reg + rcx*4], 1
    ret
_sltiu:;R
    mov r8d, [reg + rbx*4];extract rs,rbx
    and r8d, 0xFFFFFF
    mov r9d, [reg + rdx*4];extract SigImm,rdx
    and r8d, 0xFFFFFF
    cmp r8d, r9d
    jl sltiu_if
    mov dword[reg + rcx*4], 0 ;extract rt,rcx
    ret
    sltiu_if:
    mov dword[reg + rcx*4], 1
    ret
_andi:;R
    mov r8, [reg+rbx*4]
    mov r9, [reg+rdx*4]
    and r9, 0xFFFFFFF
    and r8, r9
    mov dword[reg+rcx*4],r8d
    ret
_ori:;R
    mov r8, [reg+rbx*4]
    mov r9, [reg+rdx*4]
    and r9, 0xFFFFFFF
    or r8, r9
    mov dword[reg+rcx*4],r8d
    ret
_xori:;R
    mov r8,[reg+rbx*4]
    mov r9,[reg+rdx*4]
    and r9, 0xFFFFFFF
    xor r8,r9
    mov dword[reg+rcx*4],r8d
    ret
_syscall:
    mov r8, [reg+2*4]
    caso r8,1,print_integer
    caso r8,5,read_integer
    caso r8,9,allocate_heap_memory
    caso r8,10,exit
    caso r8,11,print_caracter
    caso r8,13,open_file
    caso r8,17,terminate_with_value
    caso r8,31,MIDI
    caso r8,32,sleep
    caso r8,40,Init_random_generator
    caso r8,41,random_int
    caso r8,42,random_int_range
    ret
    MIDI:
        mov eax, 1
	    mov edi, 1
	    mov rsi, beep
	    mov edx,1
	    syscall
        ret
    print_integer:
        print [reg + 4*4], 256
        ret
    
    read_integer:
        getinteger 20
        ret
    allocate_heap_memory:
        mov r11,[reg + 4*4]
        mov r12,0
        mov rcx,0
        mov r12, heap_base_address
        sub r12, MEM_offset
        allocate_heap_memory_loop:
        add r12, rcx
        mov dword[data_buffer + r12], 0
        inc rcx
        cmp rcx, r11
        jnz allocate_heap_memory_loop
        add r11, heap_base_address
        mov rax, heap_base_address
        sub rax, r11
        ret
    print_caracter:
        print [reg + 4*4], 20
        ret
    open_file:;no se utiliza en pong
        mov r8, [reg + 4*4]
        mov r9, [reg + 5*4]
        mov r10, [reg + 6*4]

        ret
    terminate_with_value:;no se usa
        mov rax, [reg+4*4]
        call exit
        ret
    sleep:
        mov eax, sys_nanosleep
	    mov rdi, delay
        imul rdi, [reg + 4*4]
	    xor esi, esi
        syscall	
        ret
    Init_random_generator:;no se utiliza en el pong
        ret
    random_int:;no se usa 
        ret
    random_int_range: ;no se usa en pong pero si en wow
        ret

;;;EMULA EL CPU
_CPU:
    ;;; Extrae el opcode
    mov rdi,0
    call extract_from_instruction
    opcode_dec:
    mov r9,rax
    ;;;Dirige el proceso a la instruccion correspondiente
    caso r9,0,CPU_R
    caso r9,2,CPU_jump
    caso r9,3,CPU_jal
    caso r9,4,CPU_beq
    caso r9,5,CPU_bne
    caso r9,6,CPU_blez
    caso r9,8,CPU_addi
    caso r9,9,CPU_addiu
    caso r9,10,CPU_slti
    caso r9,11,CPU_sltiu
    caso r9,12,CPU_andi
    caso r9,13,CPU_ori
    caso r9,14,CPU_xori
    caso r9,15,CPU_lui
    caso r9,28,CPU_mul
    caso r9,32,CPU_lb
    caso r9,33,CPU_lh
    caso r9,35,CPU_lw
    caso r9,36,CPU_lbu
    caso r9,37,CPU_lhu
    caso r9,40,CPU_sb
    caso r9,41,CPU_sh
    caso r9,43,CPU_sw
    

    call exit
    CPU_R:
        ;;;;;Para que se salga si no encuentra mas instrucciones
        mov r9d,[pc_address]
        mov r9d,[instruction_buffer+r9d]
        cmp r9d,0
        jz exit

        mov rdi,5
        call extract_from_instruction
        mov r9,rax
        
        caso r9,0,CPU_sll
        caso r9,2,CPU_srl
        caso r9,12,CPU_Syscall
        caso r9,13,exit
        caso r9,16,CPU_mfhi
        caso r9,18,CPU_mflo
        caso r9,24,CPU_mult
        caso r9,25,CPU_multu
        caso r9,26,CPU_div_e
        caso r9,27,CPU_divu_e
        caso r9,32,CPU_add
        caso r9,33,CPU_addu
        caso r9,34,CPU_sub
        caso r9,35,CPU_subu
        caso r9,36,CPU_and
        caso r9,37,CPU_or
        caso r9,38,CPU_xor
        caso r9,39,CPU_nor
        caso r9,42,CPU_slt
        caso r9,43,CPU_sltu
        
        call exit    
    CPU_sll: ;Y
        extract rt,rbx
        extract rd,rdx
        extract shamt,rcx
        call _sll

        jmp CPU_END
    CPU_srl:;Y
        extract rt,rbx
        extract rd,rdx
        extract shamt,rcx
        call _srl
        jmp CPU_END
    CPU_Syscall:;R
        call _syscall
        jmp CPU_END
    CPU_mfhi:;R
        extract rd, rdx
        call _mfhi
        jmp CPU_END
    CPU_mflo:;R
        extract rd, rdx
        call _mflo
        jmp CPU_END
    CPU_mult:;Y
        extract rs,rbx
        extract rt,rcx
        call _mult
        jmp CPU_END
    CPU_multu:;Y
        extract rs,rbx
        extract rt,rcx
        call _multu
        jmp CPU_END
    CPU_div_e:;R
        extract rs,rbx
        extract rt,rcx
        call _div_e
        jmp CPU_END
    CPU_divu_e:;R
        extract rs,rbx
        extract rt,rcx
        call _divu_e
        jmp CPU_END
    CPU_add:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _add
        jmp CPU_END
    CPU_addu:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _addu
        jmp CPU_END
    CPU_sub:;R
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        jmp CPU_END
    CPU_subu:;R
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        jmp CPU_END
    CPU_and:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _and
        jmp CPU_END
    CPU_or:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _or
        jmp CPU_END
    CPU_xor:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _xor
        jmp CPU_END
    CPU_nor:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _nor
        jmp CPU_END
    CPU_slt:;R
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        jmp CPU_END
    CPU_sltu:;R
        jmp CPU_END

    CPU_jump:;Y
        extract address,rbx
        call _jump
        jmp CPU_END
    CPU_jal:;Y
        extract address,rbx
        call _jal
        jmp CPU_END
    CPU_beq:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        jmp CPU_END
    CPU_bne:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        jmp CPU_END
    CPU_blez:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        jmp CPU_END
    CPU_addi:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _addi
        jmp CPU_END
    CPU_addiu:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        jmp CPU_END
    CPU_slti:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        jmp CPU_END
    CPU_sltiu:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        jmp CPU_END
    CPU_andi:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        jmp CPU_END
    CPU_ori:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        jmp CPU_END
    CPU_xori:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        call _xori
        jmp CPU_END
    CPU_lui:;R
        extract rt,rbx
        extract ZeroImm,rcx
        call _lui
        jmp CPU_END
    CPU_mul:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _mul
        jmp CPU_END
    CPU_lb:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _lb
        jmp CPU_END
    CPU_lh:
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx 
        call _lh
        jmp CPU_END
    CPU_lw:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _lw
        jmp CPU_END
    CPU_lbu:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _lbu
        jmp CPU_END
    CPU_lhu:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx 
        call _lhu
        jmp CPU_END
    CPU_sb:;Y AAAAA
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _sb
        jmp CPU_END
    CPU_sh:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _sh
        jmp CPU_END
    CPU_sw:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _sw
        jmp CPU_END
        
    CPU_END:
        mov r9,[pc_address]
        add r9,4
        mov dword [pc_address],r9d
        ;mov byte [instruction_buffer + rcx],r8b ;Guarda el dato en memoria antes del siguiente salto
        ret

;;;;;;;;;;;;;;;;;;FIN DE FUNCIONES DEL EMULADOR;;;;;;;;;;;
;Acá comienza el ciclo pirncipal
_start:
    call canonical_off
    call _read_text
    call _read_data
    call _fix_data
	
	.main_loop:
        call _CPU
        .read_more:	
        getchar
        jmp .done
        .done:	
            unsetnonblocking		
            sleeptime	
            print clear, clear_length
            jmp .main_loop


start_screen:
	
	print msg1, msg1_length	
	getchar
	print clear, clear_length
	ret
;;; Si quieren ver la pantalla de inicio, pongan un sleep aqui

exit: 
	call canonical_on
	mov    rax, 60
    mov    rdi, 0
    syscall

