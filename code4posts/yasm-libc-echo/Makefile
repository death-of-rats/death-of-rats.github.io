all: prog

prog: asm01.o
	ld -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc -o asm01 asm01.o

asm01.o: asm01.s
	yasm -f elf64 -g dwarf2 asm01.s

clean:
	rm -rf asm01.o
	rm -rf asm01
