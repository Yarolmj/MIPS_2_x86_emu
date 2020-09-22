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
reg_rs: equ 1
reg_rt: equ 2
reg_rd: equ 3
shamt: equ 4
funct: equ 5
imm_sig: equ 6
imm_nsig: equ 7
address: equ 8
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

%macro sleeptime 0
	mov eax, sys_nanosleep
	mov rdi, timespec
	xor esi, esi		; ignore remaining time in case of call interruption
	syscall			; sleep for tv_sec seconds + tv_nsec nanoseconds
%endmacro



global _start

section .bss ; Este es el segmento de datos para variables estáticas, aca se reserva un byte para lo que se lee de consola

input_char: resb 1

section .data ;variables globales se agregan aqui
;Esto se inicializa antes de que el código se ejecute

		

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

    filename_text: db "/home/yarol/MIPS x86/MIPS_2_x86_emu/MIPS TEST/wow_hex.txt",0
    filename_data: db "/home/yarol/MIPS x86/MIPS_2_x86_emu/MIPS TEST/pong data hex.txt",0

    reg: TIMES 32 dd 0 ;;;EMULACION EN MEMORIA DE LOS 32 REGISTROS DE MIPS

    pc_base_address: dd 0x00400000 ;;;;;Direccion base de las instrucciones

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

_input_for_emu:
    ret

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
        and r9,0x3F ; 1111 1100
        
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

;;;EMULA EL CPU
CPU:
    ;;; Extrae el opcode
    mov rdi,0
    call extract_from_instruction

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
    caso r9,35,CPU_lw
    caso r9,36,CPU_lbu
    caso r9,37,CPU_lhu
    caso r9,40,CPU_sb
    caso r9,41,CPU_sh
    caso r9,43,CPU_sw
    

    call exit
    CPU_R:
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
        jmp CPU_END ;;Ninguna de las anteriores
    
    CPU_sll:
        
        jmp CPU_END
    CPU_srl:
        jmp CPU_END
    CPU_Syscall:
        jmp CPU_END
    CPU_mfhi:
        jmp CPU_END
    CPU_mflo:
        jmp CPU_END
    CPU_mult:
        jmp CPU_END
    CPU_multu:
        jmp CPU_END
    CPU_div_e:
        jmp CPU_END
    CPU_divu_e:
        jmp CPU_END
    CPU_add:
        jmp CPU_END
    CPU_addu:
        jmp CPU_END
    CPU_sub:
        jmp CPU_END
    CPU_subu:
        jmp CPU_END
    CPU_and:
        jmp CPU_END
    CPU_or:
        jmp CPU_END
    CPU_xor:
        jmp CPU_END
    CPU_nor:
        jmp CPU_END
    CPU_slt:
        jmp CPU_END
    CPU_sltu:
        jmp CPU_END

    CPU_jump:
        jmp CPU_END
    CPU_jal:
        jmp CPU_END
    CPU_beq:
        jmp CPU_END
    CPU_bne:
        jmp CPU_END
    CPU_blez:
        jmp CPU_END
    CPU_addi:
        jmp CPU_END
    CPU_addiu:
        jmp CPU_END
    CPU_slti:
        jmp CPU_END
    CPU_sltiu:
        jmp CPU_END
    CPU_andi:
        jmp CPU_END
    CPU_ori:
        jmp CPU_END
    CPU_xori:
        jmp CPU_END
    CPU_lui:
        jmp CPU_END
    CPU_mul:
        jmp CPU_END
    CPU_lb:
        jmp CPU_END
    CPU_lw:
        jmp CPU_END
    CPU_lbu:
        jmp CPU_END
    CPU_lhu:
        jmp CPU_END
    CPU_sb:
        jmp CPU_END
    CPU_sh:
        jmp CPU_END
    CPU_sw:
        jmp CPU_END
        
    CPU_END:
        mov r9,[pc_address]
        add r9,4
        mov dd[pc_address],r9
        ret

;;;;;;;;;;;;;;;;;;FIN DE FUNCIONES DEL EMULADOR;;;;;;;;;;;
;Acá comienza el ciclo pirncipal
_start:
    
    call _read_text
    call _read_data
    
    
    ;call exit
	;;call canonical_off
	;print clear, clear_length	; limpia la pantalla
	;;call start_screen	; Esto puesto que consola no bloquea casi no se ve
	;;mov r8, board + 40 + 29 * (column_cells+2) ; Modifiquen esto y verán el efecto que genera sobre la pantalla
;Estudien esto, en R8 lo que queda definido es una dirección muy específica de memoria
	
	
	.main_loop:
        call CPU
        p:

	;;;;	mov byte [r8], 35 ;ojo acá se define qué caracter se va a pintar
;También estudien esto, en esa dirección específica se está escribiendo un valor
; de 35, que corresponde a  # y es lo que se imprime en pantalla
; Vea los direccionamiento de 86, vea lo que ocurre si descomentan las siguientes lineas
        ;mov byte [r8+1], 35 
        ;mov byte [r8-1], 35 
        ; waooo vieron, será que se pueden detectar colisiones comparando 
; valores contenidos en memoria????
		;;;;;;print board, board_size				
		; aca viene la logica de reconocer tecla y actuar
	;;.read_more:	
	;;	getchar	
	;;	
	;;	cmp rax, 1
    ;;	jne .done
	;;	
	;;	mov al,[input_char]
;;
;;		cmp al, 'a'
;;	    jne .not_left
;;	    dec r8
;;	    jmp .done
;;;;		
	;;	.not_left:
	;;	 	cmp al, 'd'
	  ;;  	jne .not_right
	    ;;	inc r8
    	;;	jmp .done		
;;
;;		.not_right:
;;
  ;;  		cmp al, 'q' ;prueben apretar q v eran que se sale
    ;;		je exit
;;
;;			jmp .read_more
;;		
;;		.done:	
			;unsetnonblocking		
;;			sleeptime	
;;			print clear, clear_length
  		jmp .main_loop

;;		print clear, clear_length
		
		jmp exit


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

