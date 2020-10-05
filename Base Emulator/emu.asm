
; Acá básicamente le estoy asignando nombres a los syscalls
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

stack_base: equ 2143479548
stack_top: equ 2151479548
pc_base_address: equ 4194304
heap_base_address: equ 268697600
; Leer de consola es a través de STDIN
STDIN_FILENO: equ 0
;Necesario para limpiar consona
F_SETFL:	equ 0x0004
O_NONBLOCK: equ 0x0004


;Este comando es para limpiar la pantalla, no es intuitivo usenlo como tal
clear:		db 27, "[2J", 27, "[H"
clear_length:	equ $-clear
	
	

; Pantalla de inicio, ahorita no se pinta
msg1: db "        TECNOLOGICO DE COSTA RICA        ", 0xA, 0xD ; Investiguen porque pongo esto
msg2: db "        YAROL MONTOYA JIMENEZ        ", 0xA, 0xD, "        RUBEN BRENES JIMENEZ        ", 0xA, 0xD
msg3: db "        EMULADOR MIPS EN ARQUITECTURA X86_64        ", 0xA, 0xD
msg4: db "        PRESIONE ENTER PARA INICIAR        ", 0xA, 0xD
msg1_length:	equ $-msg1
msg2_length:	equ $-msg2
msg3_length:	equ $-msg3
msg4_length:	equ $-msg4

;-------------------------User Interface texts---------------------------------

interfaceh_t: db "Seleccione la resolucion horizontal deseada:", 0xA,"1)16", 0xA,"2)32", 0xA,"3)64", 0xA,"4)128", 0xA
interfaceh_t_length: equ $-interfaceh_t

interfacehs_t: db "Resolucion horizontal seleccionada:"
interfacehs_t_length: equ $-interfacehs_t

interfacev_t: db "Seleccione la resolucion vertical deseada:", 0xA,"1)16", 0xA,"2)32", 0xA,"3)64", 0xA,"4)128", 0xA
interfacev_t_length: equ $-interfacev_t

interfacevs_t: db "Resolucion vertical seleccionada:"
interfacevs_t_length: equ $-interfacevs_t

interfaced_t: db "Seleccione la direccion de base para el display deseada:", 0xA,"1)0x10000000(global data)", 0xA,"2)0x10008000($gp)", 0xA,"3)0x10010000(static data)", 0xA,"4)0x10040000(heap)", 0xA
interfaced_t_length: equ $-interfaced_t
interfaceerror_t: db " no pertenece a niguna de las opciones", 0xA,"Por favor seleccione una de las opciones indicadas", 0xA
interfaceerror_t_length: equ $-interfaceerror_t
interfaceds_t: db "Direccion de base para el display seleccionada: "
interfaceds_t_length: equ $-interfaceds_t

m64_t: db "16", 0xA
m64_t_length: equ $-m64_t
m128_t: db "32", 0xA
m128_t_length: equ $-m128_t
m256_t: db "64", 0xA
m256_t_length: equ $-m256_t
m512_t: db "128", 0xA
m512_t_length: equ $-m512_t

global_data_t: db "0x10000000(global data)", 0xA
global_data_t_length: equ $-global_data_t
gp_t: db "0x10008000($gp)", 0xA
gp_t_length: equ $-gp_t
static_data_t: db "0x10010000(static data)", 0xA
static_data_t_length: equ $-static_data_t
heap_t: db "0x10040000(heap)", 0xA
heap_t_length: equ $-heap_t

;-------------------------------------------------------------------------------
;------------------------MACROS-------------------------------------------------
;Se puede usar como un case de C
%macro caso 3
    cmp %1,%2
    jz %3
%endmacro

;Simplifica la extraccion de partes de las instrucciones
%macro extract 2
    mov rdi,%1
    call extract_from_instruction
    mov %2,rax
%endmacro

%macro print 2
	mov eax, sys_write ; Aca le digo cual syscall quier aplicar
	mov edi, 1 	; stdout, Aca le digo a donde quiero escribir
	mov rsi, %1 ;Aca va el mensaje
	mov edx, %2 ;Aca el largo del mensaje
	syscall
%endmacro

;Usado para escrbir la base de board de forma procedural
;1:contador 2:caracter
%macro add_to_board 2
    mov byte[board+%1],%2
    inc %1
%endmacro
null_t: db "null",0xA
sll_t: db "sll",0xA
srl_t: db "srl",0xA
jr_t: db "jr",0xA
sys_t: db "sys",0xA
exit_t: db "exit",0xA
mfhi_t: db "mfhi",0xA
mflo_t: db "mflo",0xA
mult_t: db "mult",0xA
multu_t: db "multu",0xA
div_e_t: db "dive",0xA
divu_e_t: db "divue",0xA
add_t: db "add",0xA
addu_t: db "addu",0xA
sub_t: db "sub",0xA
subu_t: db "subu",0xA
and_t: db "and",0xA
or_t: db "or",0xA
xor_t: db "xor",0xA
nor_t: db "nor",0xA
slt_t: db "slt",0xA
sltu_t: db "sltu",0xA
jump_t: db "jump",0xA
jal_t: db "jal",0xA
beq_t: db "beq",0xA
bne_t: db "bne",0xA
blez_t: db "blez",0xA
addi_t: db "addi",0xA
addiu_t: db "addiu",0xA
slti_t: db "slti",0xA
sltiu_t: db "sltiu",0xA
andi_t: db "andi",0xA
ori_t: db "ori",0xA
xori_t: db "xori",0xA
lui_t: db "lui",0xA
mul_t: db "mul",0xA
lb_t: db "lb",0xA
lh_t: db "lh",0xA
lw_t: db "lw",0xA
lbu_t: db "lbu",0xA
lhu_t: db "lhu",0xA
sb_t: db "sb",0xA
sh_t: db "sh",0xA
sw_t: db "sw",0xA

;Se usa para escribir en log
%macro write 2
	mov eax, sys_write ; Aca le digo cual syscall quier aplicar
	mov edi,[log_descriptor]  	; stdout, Aca le digo a donde quiero escribir
	mov rsi, %1 ;Aca va el mensaje
	mov edx, %2 ;Aca el largo del mensaje
    add edx,1
	syscall
%endmacro


;Lee 1 carater de la consola
%macro getchar 0
	mov     rax, sys_read
    mov     rdi, STDIN_FILENO
    mov     rsi, input_char
    mov     rdx, 1 ; Numero de bytes que vamos a leer (solo es uno)
    syscall         ;recuperar el texto desde la consola
%endmacro
;Lee 1 integer desde la consola
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

filename_text: resb 20 ;Reserva para la direccion .text
filename_data: resb 20 ;Reserva para la direccion .data
input_char: resb 1
input_int:  resb 20

section .data ;variables globales se agregan aqui
;Esto se inicializa antes de que el código se ejecute
beep db 7 ; "BELL"
		
    sleep_time:
        st_sec  dq 0
        st_nsec dq 0

    board:  TIMES 20000 db 0 ;;128x64 + 128*2 + 62*2 + 0's
    board_size: dd 0
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

    stack_buffer: TIMES 8000000 db 0  ;8 MBytes reservados para el stack, $sp + 4MB y $sp - 4MB

    display_buffer: TIMES 1048576 db 0 ;;Espacio sufienciente para dibujar 512x512 pixeles con 1 pixel = 4 Bytes

    reg: TIMES 32 dd 0 ;;;EMULACION EN MEMORIA DE LOS 32 REGISTROS DE MIPS
    hi_reg: dd 0
    lo_reg: dd 0

    pc_address: dd 0 ;;;Direccion pc actual
    pc_char: TIMES 8 db '0'
    display_base_address: dd 0 ;;Direccion simulada donde empieza la memoria de dibujo del display
    display_top_address: dd 0
    ;;;;Resolución del display, declaradas en .data para poder configurarlas al iniciar el emulador
    res_x: dd 0
    res_y: dd 0

    frame: dd 0

    log_path: db 'log.txt', 0
    log_descriptor: dd 0;

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
    mov rdi,[filename_text]
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
    mov rdi,[filename_data]
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
    mov r8d,[pc_address]
    
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


;;;;; FUNCIONES BASICAS DE MIPS;;;;;;;;;
_sll:
    mov r8,[reg+rbx*4]
    shl r8,cl
    mov dword[reg+rdx*4],r8d
    ret
_srl:
    mov r8,[reg+rbx*4]
    shr r8,cl
    mov dword[reg+rdx*4],r8d
    ret
_jr:
    mov r8d,[reg+rbx*4]
    sub r8d,pc_base_address
    sub r8d,4
    mov dword[pc_address],r8d
    ret
_addi:
    mov r8,[reg+rbx*4]
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
    mov r8,[reg+rbx*4]
    and r8,0xFFFFFFFF
    mov r9,[reg+rcx*4]
    and r9,0xFFFFFFFF
    add r8,r9
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
    and r9d,0xFF ; Elimina signo
    mov dword[reg+rcx*4],r9d ;Guarda en registro
    ret
_lw:
    mov r8,0
    mov r8d,[reg+rbx*4]
    add r8d,edx
    ;-----COMPROBACIONES PARA SABER EN QUE SEGMENTO DEL EMULADOR SE VA A CARGAR INFO
    ;Comprobaciones para entrada de consola
    cmp r8d,0xFFFF0000
    jz .lw_input
    cmp r8d,0xFFFF0004
    jz .lw_input
    ;Comprobaciones para el stack
    cmp r8d,stack_base
    jg .lw_stack
    .lw_no_stack:
    ;Comprobaciones para el display
    cmp r8d,[display_base_address]
    jge .lw_display
    .lw_no_display:
    ;Debe ser en el .data
    sub r8d,MEM_offset ;indice
    mov r9d,[data_buffer+r8d] ;MEM[indice]
    mov dword[reg+rcx*4],r9d
    ret
    .lw_input:
        mov r9b,[input_char]
        and r9b,0xFF
        mov dword[reg+rcx*4],r9d
        ret
    .lw_stack:
        .stack_pausa:
        cmp r8,stack_top
        ja .lw_no_stack
        ;Si está en el rango del stack
        sub r8d,stack_base ;indice
        mov r9d,[stack_buffer+r8d] ;MEM[indice]
        mov dword[reg+rcx*4],r9d
        ret
    .lw_display:
        cmp r8d,[display_top_address]
        ja .lw_no_display
        sub r8d,[display_base_address] ;indice
        mov r9d,[display_buffer+r8d] ;MEM[indice]
        mov dword[reg+rcx*4],r9d
        ret
_sw:
    mov r8,0
    mov r8d,[reg+rbx*4]
    add r8d,edx
    ;----------COMPROBACIONES PARA SABER EN QUE SEGMENTO DEL EMULADOR SE VA A GUARDAR INFO
    ;Comprobaciones para entrada de consola
    cmp r8d,0xFFFF0000
    jz .sw_input
    cmp r8d,0xFFFF0004
    jz .sw_input
    ;Comprobaciones para el stack
    cmp r8d,stack_base
    jg .sw_stack
    .sw_no_stack:
    ;Comprobaciones para el display
    cmp r8d,[display_base_address]
    jge .sw_display
    .sw_no_display:
    ;Debe ser en el .data
    sub r8d,MEM_offset
    mov r9d,[reg+rcx*4]
    mov dword[data_buffer + r8d],r9d
    ret
    .sw_input:
        mov r9d,[reg+rcx*4]
        mov byte[input_char],r9b
        ret
    .sw_stack:
        .stack_pausa:
        cmp r8,stack_top
        ja .sw_no_stack
        ;Si está en el rango del stack
        sub r8d,stack_base
        mov r9d,[reg+rcx*4]
        mov dword[stack_buffer+r8d],r9d
        ret
    .sw_display:
        cmp r8d,[display_top_address]
        ja .sw_no_display
        sub r8d,[display_base_address]
        mov r9d,[reg+rcx*4]
        mov dword[display_buffer+r8d],r9d
        mov eax,r8d
        call _address_to_screen
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
    mov r8d,[pc_address]
    add r8d,pc_base_address
    add r8d,4
    mov dword[reg+31*4],r8d

    sub ebx,pc_base_address
    sub ebx,4
    mov dword[pc_address],ebx
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
    mov r9,[reg+rcx*4]
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
    mov r8d,[reg+rbx*4]
    mov r9d,[reg+rcx*4]
    sub r8d,r9d
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
    mov r9d, [reg + rcx*4];extract rt,rcx
    cmp r8d, r9d
    jl sltu_if
    mov dword[reg + rdx*4], 0 ;extract rd,rdx
    ret
    sltu_if:
    mov dword[reg + rdx*4], 1
    ret
_bne:;R
    mov r8d, [reg + rbx*4]  ;extract rs,rbx
    mov r9d, [reg + rcx*4]  ;extract rt,rcx
    cmp r8d, r9d
    jne bne_if
    ret
    bne_if:
    mov r9d,edx
    shl r9d,2
    add r9d, [pc_address]     ;extract SigImm,rdx
    mov dword[pc_address], r9d
    ret
_beq:;R
    mov r8d, [reg + rbx*4]  ;extract rs,rbx
    mov r9d, [reg + rcx*4]  ;extract rt,rcx
    cmp r8d, r9d
    je beq_if
    ret
    beq_if:
    mov r9d,edx
    shl r9d,2
    add r9d,[pc_address]     ;extract SigImm,rdx
    mov dword[pc_address], r9d
    ret
_blez:;R
    mov r8d, [reg + rbx*4]  ;extract rs,rbx
    cmp r8d, 0
    jle blez_if
    ret
    blez_if:
    mov r9d,edx
    shl r9d,2
    add r9d, [pc_address]     ;extract SigImm,rdx
    mov dword[pc_address], r9d
    ret

_addiu:;R
    mov r8,[reg+rbx*4]
    and r8,0xFFFFFFFF
    mov r9, rdx
    and r9,0xFFFFFFFF
    add r8, r9
    mov dword[reg+rcx*4],r8d
    ret
_slti:;R
    mov r8d, [reg + rbx*4];extract rs,rbx
    mov r9d, edx;extract SigImm,rdx
    cmp r8d, r9d
    jl slti_if
    mov dword[reg + rcx*4], 0 ;extract rt,rcx
    ret
    slti_if:
    mov dword[reg + rcx*4], 1
    ret
_sltiu:;R
    mov r8d, [reg + rbx*4];extract rs,rbx
    mov r9d, edx;extract SigImm,rdx
    cmp r8d, r9d
    jl sltiu_if
    mov dword[reg + rcx*4], 0 ;extract rt,rcx
    ret
    sltiu_if:
    mov dword[reg + rcx*4], 1
    ret
_andi:;R
    mov r8d, [reg+rbx*4]
    mov r9d, edx
    and r8d, r9d
    mov dword[reg+rcx*4],r8d
    ret
_ori:;R
    mov r8d,[reg+rbx*4]
    mov r9d,edx 
    or r8d, r9d
    mov dword[reg+rcx*4],r8d
    ret
_xori:;R
    mov r8d,[reg+rbx*4]
    mov r9d,edx
    and r9d, 0xFFFF
    xor r8d,r9d
    mov dword[reg+rcx*4],r8d
    ret
_syscall:
    mov r8d, [reg+2*4]
    caso r8d,1,print_integer
    caso r8d,5,read_integer
    caso r8d,9,allocate_heap_memory
    caso r8d,10,exit
    caso r8d,11,print_caracter
    caso r8d,13,open_file
    caso r8d,17,terminate_with_value
    caso r8d,31,MIDI
    caso r8d,32,sleep
    caso r8d,40,Init_random_generator
    caso r8d,41,random_int
    caso r8d,42,random_int_range
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
        print clear,clear_length
        print board,[board_size]
        mov eax,[reg+4*4]
        call sleepSyscall
        
        ret
    Init_random_generator:;no se utiliza en el pong
        ret
    random_int:;no se usa 
        ret
    random_int_range: ;no se usa en pong pero si en wow
        ret
;;eax = recibe los milisegundos
sleepSyscall:
    mov qword[sleep_time],0
    mov qword[sleep_time+8],0

    cmp eax,1000
    jae .seconds
    .mseconds:
        ;mov eax,ebx
        mov ebx,1000000
        imul ebx
        and rax,0xFFFFFFFF
        mov qword[sleep_time+8],rax
        jmp .doSyscall
    .seconds:
        mov edx,0
        mov ecx,1000
        div ecx
        .alto:
        and rax,0xFFFFFFFF
        mov qword[sleep_time],rax 
        mov eax,edx
        jmp .mseconds
    .doSyscall:
	mov eax, sys_nanosleep
	mov rdi, sleep_time
	xor esi, esi		; ignore remaining time in case of call interruption
	syscall			; sleep for tv_sec seconds + tv_nsec nanoseconds
    ret

; W.I.P Usado para escribir el pc de la instruccion ejecutandose 
write_pc:
    mov eax,[pc_address]
    add eax,pc_base_address
    mov edx,0
    mov r8d,10
    mov ecx,7
    .pc_loop:
        div r8d
        add rdx,'0'
        mov byte[pc_char+ecx],dl
        ;push rax
        ;write pc_char,0
        ;pop rax
        cmp rax,0
        jnz .pc_nl
        jmp .pc_end
    .pc_nl:
        dec ecx
        mov edx,0
        jmp .pc_loop
    .pc_end:
        mov byte[pc_char],'0'
        write pc_char,7
        mov byte[pc_char],'-'
        write pc_char,0
        ret

;;;EMULA EL CPU
_CPU:
    call write_pc
    ;Extrae el opcode
    mov rdi,0
    call extract_from_instruction
    opcode_dec:
    mov r9,rax
    ;Dirige el proceso a la instruccion correspondiente
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
       
        mov r9d,[pc_address]
        mov r9d,[instruction_buffer+r9d]
         ;;;;;Para que se salga si no encuentra mas instrucciones
        cmp r9d,0
        jz exit

        mov rdi,5
        call extract_from_instruction
        mov r9,rax
        
        caso r9,0,CPU_sll
        caso r9,2,CPU_srl
        caso r9,8,CPU_jr
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
        write sll_t,3
        jmp CPU_END
    CPU_srl:;Y
        extract rt,rbx
        extract rd,rdx
        extract shamt,rcx
        call _srl
        write srl_t,3
        jmp CPU_END
    CPU_jr:
        extract rs,rbx
        call _jr
        write jr_t,2
        jmp CPU_END
    CPU_Syscall:;R
        call _syscall
        write sys_t,3
        jmp CPU_END
    CPU_mfhi:;R
        extract rd, rdx
        call _mfhi
        write mfhi_t,4
        jmp CPU_END
    CPU_mflo:;R
        extract rd, rdx
        call _mflo
        write mflo_t,4
        jmp CPU_END
    CPU_mult:;Y
        extract rs,rbx
        extract rt,rcx
        call _mult
        write mult_t,4
        jmp CPU_END
    CPU_multu:;Y
        extract rs,rbx
        extract rt,rcx
        call _multu
        write multu_t,5
        jmp CPU_END
    CPU_div_e:;R
        extract rs,rbx
        extract rt,rcx
        call _div_e
        write div_e_t,4
        jmp CPU_END
    CPU_divu_e:;R
        extract rs,rbx
        extract rt,rcx
        call _divu_e
        write divu_e_t,5
        jmp CPU_END
    CPU_add:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _add
        write add_t,3
        jmp CPU_END
    CPU_addu:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _addu
        write addu_t,4
        jmp CPU_END
    CPU_sub:;R
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _sub
        write sub_t,3
        jmp CPU_END
    CPU_subu:;R
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _subu
        write subu_t,4
        jmp CPU_END
    CPU_and:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _and
        write and_t,3
        jmp CPU_END
    CPU_or:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _or
        write or_t,2
        jmp CPU_END
    CPU_xor:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _xor
        write xor_t,3
        jmp CPU_END
    CPU_nor:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _nor
        write nor_t,3
        jmp CPU_END
    CPU_slt:;R
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _slt
        write slt_t,3
        jmp CPU_END
    CPU_sltu:;R
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _sltu
        write sltu_t,4
        jmp CPU_END

    CPU_jump:;Y
        extract address,rbx
        call _jump
        jmp CPU_END
        write jump_t,4
    CPU_jal:;Y
        extract address,rbx
        call _jal
        write jal_t,3
        jmp CPU_END
    CPU_beq:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _beq
        write beq_t,3
        jmp CPU_END
    CPU_bne:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _bne
        write bne_t,3
        jmp CPU_END
    CPU_blez:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _blez
        write blez_t,4
        jmp CPU_END
    CPU_addi:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _addi
        write addi_t,4
        jmp CPU_END
    CPU_addiu:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _addiu
        write addiu_t,5
        jmp CPU_END
    CPU_slti:;R
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _slti
        write slti_t,4
        jmp CPU_END
    CPU_sltiu:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        call _sltiu
        write sltiu_t,5
        jmp CPU_END
    CPU_andi:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        call _andi
        write andi_t,4
        jmp CPU_END
    CPU_ori:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        call _ori
        write ori_t,3
        jmp CPU_END
    CPU_xori:;R
        extract rs,rbx
        extract rt,rcx
        extract ZeroImm,rdx
        call _xori
        write xori_t,4
        jmp CPU_END
    CPU_lui:;R
        extract rt,rbx
        extract ZeroImm,rcx
        call _lui
        write lui_t,3
        jmp CPU_END
    CPU_mul:;Y
        extract rs,rbx
        extract rt,rcx
        extract rd,rdx
        call _mul
        write mul_t,3
        jmp CPU_END
    CPU_lb:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _lb
        write lb_t,2
        jmp CPU_END
    CPU_lh:
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx 
        call _lh
        write lh_t,2
        jmp CPU_END
    CPU_lw:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _lw
        write lw_t,2
        jmp CPU_END
    CPU_lbu:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _lbu
        write lbu_t,3
        jmp CPU_END
    CPU_lhu:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx 
        call _lhu
        write lhu_t,3
        jmp CPU_END
    CPU_sb:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _sb
        write sb_t,2
        jmp CPU_END
    CPU_sh:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _sh
        write sh_t,2
        jmp CPU_END
    CPU_sw:;Y
        extract rs,rbx
        extract rt,rcx
        extract SigImm,rdx
        call _sw
        write sw_t,2
        jmp CPU_END
        
    CPU_END:
        mov r9,[pc_address]
        add r9,4
        mov dword [pc_address],r9d
        ret

;rax = address
_address_to_screen:
    shr rax,2
    div dword[res_x]
    mov rbx,rdx
    push r9
    call _xy_boar_to_address
    pop r9
    cmp r9,0
    je .empty
    .full:
        mov byte[eax],'#'
        jmp .end
    .empty:
        mov byte[eax],' '
    .end:
        ret
; rax = y
; rbx = x
; return eax = address
_xy_boar_to_address:
    mov r8,board
    add r8,rbx
    add r8,1
    mov r9d,[res_x]
    add r9d,4
    add eax,1
    mul r9d ; eax = (pos_y+1)*(res_x+2)
    add eax,r8d
    ret
_init_registers:
    mov dword[reg+28*4],268468224 ;;$gp
    mov dword[reg+29*4],2147479548 ;;$sp
    ret
_create_log:
    ;file open
    mov eax,5
    mov ebx,log_path
    mov ecx,0102o
    mov edx,0666o
    int 80h
    mov dword[log_descriptor],eax
    ret

;;;Resolucion maxima 128x128, mas grande no cabe en 1080p con letra tamaño 6!!!
_create_board:
    mov r8d,0 ;Contador de bytes escritos
    mov ecx,[res_x]
    add ecx,2
    .top_loop:
        add_to_board r8d,'_'
        dec ecx
        cmp ecx,0
        jne .top_loop
    add_to_board r8d,0x0a
    add_to_board r8d,0xD
    mov ecx,[res_y]
    .middle_loop:
        push rcx 
        add_to_board r8d,'|'
        mov ecx,[res_x]
        .horizontal_loop:
            add_to_board r8d,' '
            dec ecx
            cmp ecx,0
            jne .horizontal_loop
        .next_line:
            add_to_board r8d,'|'
            add_to_board r8d,0x0a
            add_to_board r8d,0xD
            pop rcx 
            dec ecx 
            cmp ecx,0
            jne .middle_loop
    ;Ultima linea
    mov ecx,[res_x]
    add ecx,2
    .bottom_loop:
        add_to_board r8d,'-'
        dec ecx
        cmp ecx,0
        jne .bottom_loop
    add_to_board r8d,0x0a
    add_to_board r8d,0xD
    mov dword[board_size],r8d
    ;Calculo de display_top_address
    mov eax,[res_x]
    mul dword[res_y]
    mov r10d,eax
    shl r10d,2
    add r10d,[display_base_address]
    mov dword[display_top_address],r10d

    ret

    
;;;;;;;;;;;;;;;;;;FIN DE FUNCIONES DEL EMULADOR;;;;;;;;;;;
_start:
    call _user_interface
    mov r8,0
    pop r8          
    pop rsi         
    pop rsi
    mov [filename_text], rsi
    pop rsi
    mov [filename_data], rsi
    call _read_text
    call _read_data
    call _fix_data
	call canonical_off
    call _init_registers
    call _create_log
    call _create_board
	
	.main_loop:
        call _CPU
		getchar
    	
        jmp .main_loop


start_screen:
	
	print msg1, msg1_length	
	getchar
	print clear, clear_length
	ret


_user_interface:
    
    print clear, clear_length
    call start_screen
    print interfaceh_t, interfaceh_t_length
    
    looph:
        getchar
        mov r8, 0
        mov r8, [input_char]
        caso r8, 49,interfaceh1
        caso r8, 50,interfaceh2
        caso r8, 51,interfaceh3
        caso r8, 52,interfaceh4
        print input_char, 1
        print interfaceerror_t, interfaceerror_t_length
        jmp looph
        interfaceh1:;64
        mov dword[res_x],16
        print interfacehs_t, interfacehs_t_length
        print m64_t,m64_t_length
        print interfacev_t, interfacev_t_length
        jmp loopv
        interfaceh2:;128
        mov dword[res_x],32
        print interfacehs_t, interfacehs_t_length
        print m128_t,m128_t_length
        print interfacev_t, interfacev_t_length
        jmp loopv
        interfaceh3:;256
        mov dword[res_x],64
        print interfacehs_t, interfacehs_t_length
        print m256_t,m256_t_length
        print interfacev_t, interfacev_t_length
        jmp loopv
        interfaceh4:;512
        mov dword[res_x],128
        print interfacehs_t, interfacehs_t_length
        print m512_t,m512_t_length
        print interfacev_t, interfacev_t_length
        jmp loopv
    loopv:
        getchar
        mov r8, 0
        mov r8, [input_char]
        caso r8, 0xA, loopv
        caso r8, 49,interfacev1
        caso r8, 50,interfacev2
        caso r8, 51,interfacev3
        caso r8, 52,interfacev4
        print input_char, 1
        print interfaceerror_t, interfaceerror_t_length
        jmp loopv
        interfacev1:
        mov dword[res_y],16
        print interfacevs_t, interfacevs_t_length
        print m64_t,m64_t_length 
        print interfaced_t, interfaced_t_length
        jmp loopd
        interfacev2:
        mov dword[res_y],32
        print interfacevs_t, interfacevs_t_length
        print m128_t,m128_t_length 
        print interfaced_t, interfaced_t_length
        jmp loopd
        interfacev3:
        mov dword[res_y],64
        print interfacevs_t, interfacevs_t_length
        print m256_t,m256_t_length 
        print interfaced_t, interfaced_t_length
        jmp loopd
        interfacev4:
        mov dword[res_y],128
        print interfacevs_t, interfacevs_t_length
        print m512_t,m512_t_length 
        print interfaced_t, interfaced_t_length
        jmp loopd
    loopd:
        getchar
        mov r8, 0
        mov r8, [input_char]
        caso r8, 0xA, loopd
        caso r8, 49,interfaced1
        caso r8, 50,interfaced2
        caso r8, 51,interfaced3
        caso r8, 52,interfaced4
        print input_char, 1
        print interfaceerror_t, interfaceerror_t_length
        jmp loopd
        interfaced1:;global data
        mov dword[display_base_address], 268435456
        print interfaceds_t, interfaceds_t_length
        print global_data_t, global_data_t_length
        ret
        interfaced2:;$gp
        mov dword[display_base_address], 268468224
        print interfaceds_t, interfaceds_t_length
        print gp_t, gp_t_length
        ret
        interfaced3:;static data
        mov dword[display_base_address], 268500992
        print interfaceds_t, interfaceds_t_length
        print static_data_t, static_data_t_length
        ret
        interfaced4:;heap
        mov dword[display_base_address], 268697600
        print interfaceds_t, interfaceds_t_length
        print heap_t, heap_t_length
        ret
    ret


exit: 
	call canonical_on
	mov    rax, 60
    mov    rdi, 0
    syscall


