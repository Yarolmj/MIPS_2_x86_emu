build:
	nasm -f elf64 -gstabs -o emu.o emu.asm
	ld -o emu emu.o
	gdb emu
