<!--
.. title: 0x08 Debug booting code in QEMU
.. slug: gdb-qemu-booting
.. date: 2019-05-03 00:00:00 UTC
.. tags: re, asm, os, qemu
.. category: os
.. link: 
.. description: Debug booting program with gdb and qemu. 
.. type: text
-->

How to test and debug your own OS? For running one can use any of available
emulators or VMs. I choose **QEMU**. But running isn't enough. Debugging is
very important - at least for me. In this post, I will build the 'OS' image,
run it and attach **gdb** for debugging.

<!-- TEASER_END -->

First things first. Let's check our 'OS' example.

```asm
; os00.asm
[bits 16]
[org 0x7c00]

start:
  xor ax,ax
  mov ds, ax
  mov es, ax
  mov bx, 0x8000

  mov si, msg
  call print_msg

  msg db 'Welcomme, this is OS 0x00', 0xa, 0x0

print_msg:
  mov ah, 0x0e
.repeat_printing:
  lodsb
  cmp al, 0
  je .done_printing
  int 0x10
  jmp .repeat_printing
.done_printing:
  ret

  times (510 - ($ - $$)) db 0x00
  dw 0xAA55
```

Now build *.bin* image. 
```sh
$ yasm -f bin -o os00.bin os00.asm
```
*.bin* format cannot contain debug symbols so no ```-g dwarf2```.

And run the image in the emulator:

```sh
$ qemu-system-i368 os00.bin

WARNING: Image format was not specified for 'os00.bin' and probing guessed raw.
         Automatically detecting the format is dangerous for raw images, write
         operations on block 0 will be restricted.
         Specify the 'raw' format explicitly to remove the restrictions.
```

Nice, but still some warnings. So, after reading some man pages, let's try this way.

```sh
$ qemu-system-i386 -drive format=raw,file=os00.bin
```

Now it's time to debug. What we need is to run **QEMU** and wait for **gdb**.
**QEMU** has an argument ```-S``` (uppercase s) which stops the CPU until a *continue*
will be sent to it. We need also to tell the emulator to listen after
**gdb** on the selected port. The argument ```-gdb tcp::8000``` listen on the 8000
port for **gdb** connection. Instead ```-gdb``` you could use ```-s``` (small
's') which is short for ```-gdb tcp::1234```. As I mentioned earlier *.bin*
doesn't have debug information so there is no need to run **gdb** with
*os00.bin*.

```sh
$ qemu-system-i386 -S -gdb tcp::8000 -drive format=raw,file=os00.bin
[1] 44444
$ gdb
 ...
pwndbg> target remote localhost:8000
Remote debugging using localhost:8000
warning: No executable has been specified and target does not support
determining executable automatically.  Try using the "file" command.
0x0000fff0 in ?? ()
Could not check ASLR: Couldn't get personality
LEGEND: STACK | HEAP | CODE | DATA | RWX | RODATA
─────────────────────────────[ REGISTERS ]──────────────────────────────
 EAX  0 ◂— 0
 EBX  0 ◂— 0
 ECX  0 ◂— 0
 EDX  0x663 —▸ 0 ◂— 0
 EDI  0 ◂— 0
 ESI  0 ◂— 0
 EBP  0 ◂— 0
 ESP  0 ◂— 0
 EIP  0xfff0 —▸ 0 ◂— 0
───────────────────────────────[ DISASM ]───────────────────────────────
 ► 0xfff0     add    byte ptr [eax], al
   0xfff2     add    byte ptr [eax], al
   0xfff4     add    byte ptr [eax], al
   0xfff6     add    byte ptr [eax], al
   0xfff8     add    byte ptr [eax], al
   0xfffa     add    byte ptr [eax], al
   0xfffc     add    byte ptr [eax], al
   0xfffe     add    byte ptr [eax], al
   0x10000    add    byte ptr [eax], al
   0x10002    add    byte ptr [eax], al
   0x10004    add    byte ptr [eax], al
───────────────────────────────[ STACK ]────────────────────────────────
00:0000│ eax ebx ecx edi esi ebp esp eflags-2  0 ◂— 0
... ↓
─────────────────────────────[ BACKTRACE ]──────────────────────────────
 ► f 0     fff0
pwndbg> b *0x7c00
Breakpoint 1 at 0x7c00
pwndbg> c
Continuing.

Breakpoint 1, 0x00007c00 in ?? ()
LEGEND: STACK | HEAP | CODE | DATA | RWX | RODATA
──────────────────────────────[ REGISTERS ]───────────────────────────────
 EAX  0xaa55 —▸ 0 —▸ 0xf000ff53 ◂— 0
 EBX  0 —▸ 0xf000ff53 ◂— 0
 ECX  0 —▸ 0xf000ff53 ◂— 0
 EDX  128 —▸ 0xf000ff53 —▸ 0 ◂— push   ebx /* 0xf000ff53 */
 EDI  0 —▸ 0xf000ff53 ◂— 0
 ESI  0 —▸ 0xf000ff53 ◂— 0
 EBP  0 —▸ 0xf000ff53 ◂— 0
 ESP  0x6ef0 —▸ 0xf000d038 —▸ 0 —▸ 0xf000ff53 ◂— 0
 EIP  0x7c00 —▸ 0xd88ec031 —▸ 0 —▸ 0xf000ff53 ◂— 0
────────────────────────────────[ DISASM ]────────────────────────────────
 ► 0x7c00    xor    eax, eax
   0x7c02    mov    ds, eax
   0x7c04    mov    es, eax
   0x7c06    mov    ebx, 0xfbe8000
   0x7c0b    jl     0x7bf5

   0x7c0d    sbb    eax, dword ptr [eax]
   0x7c0f    push   edi
   0x7c10    insb   byte ptr es:[edi], dx
   0x7c12    arpl   word ptr [edi + 0x6d], bp
   0x7c15    insd   dword ptr es:[edi], dx
   0x7c16    sub    al, 0x20
────────────────────────────────[ STACK ]─────────────────────────────────
00:0000│ esp  0x6ef0 —▸ 0xf000d038 —▸ 0 —▸ 0xf000ff53 ◂— 0
01:0004│      0x6ef4 —▸ 0 —▸ 0xf000ff53 ◂— 0
02:0008│      0x6ef8 —▸ 0x6f4e —▸ 0 —▸ 0xf000ff53 ◂— 0
03:000c│      0x6efc —▸ 0 —▸ 0xf000ff53 ◂— 0
04:0010│      0x6f00 —▸ 0x7ec4 —▸ 0 —▸ 0xf000ff53 ◂— 0
05:0014│      0x6f04 —▸ 0x6f4e —▸ 0 —▸ 0xf000ff53 ◂— 0
06:0018│      0x6f08 —▸ 0 —▸ 0xf000ff53 ◂— 0
07:001c│      0x6f0c —▸ 0x7e8b —▸ 0 —▸ 0xf000ff53 ◂— 0
──────────────────────────────[ BACKTRACE ]───────────────────────────────
 ► f 0     7c00
Breakpoint *0x7c00
pwndbg>
```
As you can see, there is some mismatch in disassembled code after ```mov ebx,
0xfbe8000```. Yes, the original code looks different. 

After some
[reading](https://stackoverflow.com/questions/32955887/how-to-disassemble-16-bit-x86-boot-sector-code-in-gdb-with-x-i-pc-it-gets-tr/32960272#32960272),
I find out that usually ```set architecture i8086``` solves the problem. Until
at least **gdb** version 8. But there is another way of building the code so
one could use debug symbols during debugging.

From the code I need to throw away ```org``` as it is not allowed in *elf*,
the linker will take this address. Next, we build *elf*, linked, *objcopy* binaries
to *.img* and run **gdb** with symbols from *.elf*.  

```sh
$ yasm -f elf32 -g dwarf2 os00_v2.asm -o os00_v2.o
$ ld -Ttext=0x7c00 -melf_i386 os00_v2.o -o os00_v2.elf
ld: warning: cannot find entry symbol _start; defaulting to 0000000000007c00
$ objcopy -O binary os00_v2.elf os00_v2.img
$ qemu-system-i386 -S -s -drive format=raw,file=os00_v2.img &
[1] 55555
$ gdb os00_v2.elf
 ...
Reading symbols from os00_v2.elf...done.
pwndbg> target remote localhost:1234
Remote debugging using localhost:1234
pwndbg> b *0x7c00
Breakpoint 1 at 0x7c00: file os00_v2.asm, line 5.
pwndbg> c
Continuing.
Breakpoint 1, start () at os00_v2.asm:5
5	  xor ax,ax
LEGEND: STACK | HEAP | CODE | DATA | RWX | RODATA
───────────────────────────────[ REGISTERS ]───────────────────────────────
 EAX  0xaa55 —▸ 0 —▸ 0xf000ff53 ◂— 0
 EBX  0 —▸ 0xf000ff53 ◂— 0
 ECX  0 —▸ 0xf000ff53 ◂— 0
 EDX  128 —▸ 0xf000ff53 —▸ 0 ◂— push   ebx /* 0xf000ff53 */
 EDI  0 —▸ 0xf000ff53 ◂— 0
 ESI  0 —▸ 0xf000ff53 ◂— 0
 EBP  0 —▸ 0xf000ff53 ◂— 0
 ESP  0x6ef0 —▸ 0xf000d038 —▸ 0 —▸ 0xf000ff53 ◂— 0
 EIP  0x7c00 —▸ 0xd88ec031 —▸ 0 —▸ 0xf000ff53 ◂— 0
─────────────────────────────────[ DISASM ]─────────────────────────────────
 ► 0x7c00    xor    eax, eax
   0x7c02    mov    ds, eax
   0x7c04    mov    es, eax
   0x7c06    mov    ebx, 0xfbe8000
   0x7c0b    jl     0x7bf5

   0x7c0d    sbb    eax, dword ptr [eax]
   0x7c0f    push   edi
   0x7c10    insb   byte ptr es:[edi], dx
   0x7c12    arpl   word ptr [edi + 0x6d], bp
   0x7c15    insd   dword ptr es:[edi], dx
   0x7c16    sub    al, 0x20
───────────────────────────────[ SOURCE (CODE) ]──────────────────────────────
In file: /home/jurek/Projects/os/os00/os00_v2.asm
    1 bits 16
    2 ;[org 0x7c00]
    3
    4 start:
 ►  5   xor ax,ax
    6   mov ds, ax
    7   mov es, ax
    8   mov bx, 0x8000
    9
   10   mov si, msg
──────────────────────────────────[ STACK ]─────────────────────────────────
00:0000│ esp  0x6ef0 —▸ 0xf000d038 —▸ 0 —▸ 0xf000ff53 ◂— 0
01:0004│      0x6ef4 —▸ 0 —▸ 0xf000ff53 ◂— 0
02:0008│      0x6ef8 —▸ 0x6f4e —▸ 0 —▸ 0xf000ff53 ◂— 0
03:000c│      0x6efc —▸ 0 —▸ 0xf000ff53 ◂— 0
04:0010│      0x6f00 —▸ 0x7ec4 —▸ 0 —▸ 0xf000ff53 ◂— 0
05:0014│      0x6f04 —▸ 0x6f4e —▸ 0 —▸ 0xf000ff53 ◂— 0
06:0018│      0x6f08 —▸ 0 —▸ 0xf000ff53 ◂— 0
07:001c│      0x6f0c —▸ 0x7e8b —▸ 0 —▸ 0xf000ff53 ◂— 0
────────────────────────────────[ BACKTRACE ]───────────────────────────────
 ► f 0     7c00
Breakpoint *0x7c00
pwndbg>
```
Somewhat better. What if I try to disassemble *.bin* file with objdump?

```sh
$ objdump -D -b binary -mi8086 -Maddr16,data16 os00.bin

os00.bin:     file format binary


Disassembly of section .data:

00000000 <.data>:
   0:	31 c0                	xor    %ax,%ax
   2:	8e d8                	mov    %ax,%ds
   4:	8e c0                	mov    %ax,%es
   6:	bb 00 80             	mov    $0x8000,%bx
   9:	be 0f 7c             	mov    $0x7c0f,%si
   c:	e8 1b 00             	call   0x2a
   f:	57                   	push   %di
  10:	65 6c                	gs insb (%dx),%es:(%di)
  12:	63 6f 6d             	arpl   %bp,0x6d(%bx)
  15:	6d                   	insw   (%dx),%es:(%di)
  16:	65 2c 20             	gs sub $0x20,%al
  19:	74 68                	je     0x83
  1b:	69 73 20 69 73       	imul   $0x7369,0x20(%bp,%di),%si
  20:	20 4f 53             	and    %cl,0x53(%bx)
  23:	20 30                	and    %dh,(%bx,%si)
  25:	78 30                	js     0x57
  27:	30 0a                	xor    %cl,(%bp,%si)
  29:	00 b4 0e ac          	add    %dh,-0x53f2(%si)
  2d:	3c 00                	cmp    $0x0,%al
  2f:	74 04                	je     0x35
  31:	cd 10                	int    $0x10
  33:	eb f7                	jmp    0x2c
  35:	c3                   	ret
	...
 1fe:	55                   	push   %bp
 1ff:	aa                   	stos   %al,%es:(%di)
$ 
```
Close... Maybe I need to align my code...


...**SQUEAK**!
