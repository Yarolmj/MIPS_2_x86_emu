bits 64
default rel


; Acá básicamente le estoy asignando nombres a los syscalls
sys_read: equ 0	
sys_write:	equ 1
sys_nanosleep:	equ 35
sys_time:	equ 201
sys_fcntl:	equ 72

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


;Acá comienza el ciclo pirncipal
_start:
	call canonical_off
	print clear, clear_length	; limpia la pantalla
	call start_screen	; Esto puesto que consola no bloquea casi no se ve
	mov r8, board + 40 + 29 * (column_cells+2) ; Modifiquen esto y verán el efecto que genera sobre la pantalla
;Estudien esto, en R8 lo que queda definido es una dirección muy específica de memoria
	
	
	.main_loop:
		mov byte [r8], 35 ;ojo acá se define qué caracter se va a pintar
;También estudien esto, en esa dirección específica se está escribiendo un valor
; de 35, que corresponde a  # y es lo que se imprime en pantalla
; Vea los direccionamiento de 86, vea lo que ocurre si descomentan las siguientes lineas
        ;mov byte [r8+1], 35 
        ;mov byte [r8-1], 35 
        ; waooo vieron, será que se pueden detectar colisiones comparando 
; valores contenidos en memoria????
		print board, board_size				
		; aca viene la logica de reconocer tecla y actuar
	.read_more:	
		getchar	
		
		cmp rax, 1
    	jne .done
		
		mov al,[input_char]

		cmp al, 'a'
	    jne .not_left
	    dec r8
	    jmp .done
		
		.not_left:
		 	cmp al, 'd'
	    	jne .not_right
	    	inc r8
    		jmp .done		

		.not_right:

    		cmp al, 'q' ;prueben apretar q v eran que se sale
    		je exit

			jmp .read_more
		
		.done:	
			;unsetnonblocking		
			sleeptime	
			print clear, clear_length
    		jmp .main_loop

		print clear, clear_length
		
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

