compilar:
	nasm -f elf64 -gstabs load_data.asm
	ld -o load_data load_data.o
	gdb load_data
