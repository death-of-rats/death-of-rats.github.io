all: os03.bin

os03.bin: os03.S
	yasm -f bin -o os03.bin os03.S

run: os03.bin
	qemu-system-i386 -drive format=raw,file=os03.bin

debug: os03.bin
	qemu-system-i386 -S -gdb tcp::8000 -drive format=raw,file=os03.bin &

	gdb \
		-ix gdb_init_real_mode.txt \
		-ex 'target remote localhost:8000' \
		-ex 'break *0x7c00' \
		-ex 'continue'
    
clean:
	rm -rf os03.bin
