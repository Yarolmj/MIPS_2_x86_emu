compilar:
	nasm -f elf64 -gstabs text_load.asm
	ld -o text_load text_load.o
	gdb text_load
