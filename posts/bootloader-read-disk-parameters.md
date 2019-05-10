<!--
.. title: 0x09 Bootloader - read disk parameters
.. slug: bootloader-read-disk-parameters
.. date: 2019-05-10 00:00:00 UTC
.. tags: asm, os, re, qemu
.. category: os
.. link: 
.. description: Bootloader which reads and shows boot disk parameters (CHS). 
.. type: text
-->

When BIOS finishes its job, it finds a bootable disk and loads the first sector
- the first 512 bytes. The magic 0xaa55 is the value marking bootable 510
bytes. But 510 bytes is not enough for a greedy programmer.

<!-- TEASER_END -->

BIOS handle the first sector. the rest of them we must load ourselves. To do
this one must understand parameters of BIOS INT 0x13 interrupt. Nowadays the
commonly used scheme for locating blocks of data on storage devices is **LBA**
(Logical Block Addressing). It replaced the **CHS** (Cylinder-Head-Sector)
scheme. As you may see CHS expose some technical details. BIOS of cors uses CHS
in basic interruptions and LBA in extended ones. Knowledge is knowledge,
knowing where our data is stored and converting this to *Cylinders*, *Heads*
and *Sectors* is good for understanding this topic. 

BIOS leaves a little gift in **dl** register - the disk/drive index. To
calculate proper values we must know disk parameters: how big is a sector, how
many sectors are on track and heads in a cylinder. To get that information one
may run **ah** = 0x08 or if available the extended version **ah** = 0x48
[[WI13]](https://en.wikipedia.org/wiki/INT_13H). 

Lets try **ah** = 0x48, **dl** we have already, it leaves only a pointer
(**ds:si**) to the structure to fill. If something goes bad **cf** register
will be set and **ah** will have return code. Structure of the buffer has this
informations:

```
 *----------*
 | 2 bytes  |  +0x00 size of this buffer = 0x1e   
 *----------*
 | 2 bytes  |  +0x02 flags
 *----------*
 | 4 bytes  |  +0x04 number of cylinders
 *----------*
 | 4 bytes  |  +0x08 number of heads/tracks
 *----------*
 | 4 bytes  |  +0x0c number of sectors per track
 *----------*
 | 8 bytes  |  +0x10 number of all sectors
 *----------*
 | 2 bytes  |  +0x18 sector size in bytes
 *----------*
 | 4 bytes  |  +0x1a pointer to EDD (Enhanced Disk Drives)
 *----------* 
 | 2 bytes  |  +0x1e 0x0BEDD - indicates presence of Device Path Information
 *----------*
 | 1 byte   |  +0x20 length of DPI with indicator
 *----------*
 | 1 byte   |  +0x21 reserved
 *----------*
 | 2 bytes  |  +0x22 reserved
 *----------*
 | 8 bytes  |  +0x24 host bus type ASCII
 *----------*
 | 8 bytes  |  +0x2c interface type ASCII
 *----------*
 | 8 bytes  |  +0x34 interface path
 *----------*
 | 8 bytes  |  +0x3c device path
 *----------*
 | 1 byte   |  +0x44 reserved
 *----------*
 | 1 byte   |  +0x45 checksum
 *----------*
```
More details one can find in EDD specifications [[EDDS]](http://mbldr.sourceforge.net/specsedd30.pdf).

PoC code shows what I was looking for.
```asm
[bits 16]
[org 0x7c00]
; dl has drive number

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov si, start_title
    call print

    mov si, drive_title
    call print

    xor ax, ax
    mov al, dl
    call print_value

    mov ah, 0x48
    mov si, dps
    int 0x13
    jc disk_error

    mov si, cylinders_title
    call print
    lea si, [dps+0x04]
    mov cx, 2
    call print_structure_part

    mov si, heads_title
    call print
    lea si, [dps+0x08]
    mov cx, 2
    call print_structure_part

    mov si, sectors_title
    call print
    lea si, [dps+0x0c]
    mov cx, 0x02
    call print_structure_part

    mov si, all_sectors_title
    call print
    lea si, [dps+0x10]
    mov cx, 4
    call print_structure_part

    mov si, sector_size_title
    call print
    mov ax, [dps+0x18]
    call print_value

    mov si, new_line
    call print
    lea si, [dps+0x24]
    call print

    jmp $

print_structure_part:
    mov dx, cx
    dec dx
    shl dx, 1
    add si, dx
    .loop:
    lodsw
    call print_value
    dec cx
    sub si, 0x04
    cmp cx, 0x00
    ja .loop
    ret

disk_error:
    push ax
    mov si, disk_error_msg
    call print
    pop ax
    call print_value
    jmp $

print:
    mov ah, 0x0e
    .repeat_print:
    lodsb
    cmp al, 0
    je .done_print
    int 0x10
    jmp .repeat_print
    .done_print:
    ret

print_value:
    push bx
    push cx
    push dx
    mov bh, 0
    mov bl, 15
    mov dx, ax
    mov cx, 0x10 ; we want to print 16-bit value
    .repeat_print_value:
    sub cx, 0x04
    mov ax, dx
    shr ax, cl
    and ax, 0x0f
    cmp ax, 0x0a
    jb .decimal_pritnt_value
    add al, char_A
    jmp .print_char_pritnt_value
    .decimal_pritnt_value:
    add al, char_0
    .print_char_pritnt_value:
    mov ah, 0x0e
    int 0x10
    cmp cx, 0
    je .done_print_value
    jmp .repeat_print_value
    .done_print_value:
    pop dx
    pop cx
    pop bx
    ret

char_0 equ 0x30
char_A equ 0x37

start_title         db "OS 0x03", 0xd, 0xa, 0x0
cylinders_title     db 0xd, 0xa, "Cylinders: ", 0x0
heads_title         db 0xd, 0xa, "Heads: ", 0x0
sectors_title       db 0xd, 0xa, "Sectors: ", 0x0
all_sectors_title   db 0xd, 0xa, "All sectors: ", 0x0
sector_size_title   db 0xd, 0xa, "Sector size: ", 0x0
drive_title         db 0xd, 0xa, "Drive num: ", 0x0
new_line            db 0xd, 0xa, 0x0
disk_error_msg      db "Disk error, could not read disk parameters", 0xd, 0xa, 0x0

dps     dw  0x0042,                         ; size of structure
        dw  0x0000,                         ; information flags
        dw  0x0000,0x0000,                  ; physical num of cylinders
        dw  0x0000,0x0000,                  ; physical num of heads
        dw  0x0000,0x0000,                  ; physical num of sectors
        dw  0x0000,0x0000,0x0000,0x0000,    ; absolute num of sectors
        dw  0x0000,                         ; bytes per sector
        dw  0x0000,0x0000                   ; optional pointer to EDD
        dw  0x0000                          ; 
        dw  0x0000,0x0000
        dw  0x0000,0x0000                   ; host bus type ASCII
        dw  0x0000,0x0000,0x0000,0x0000     ; interface type ASCII
        dw  0x0000,0x0000,0x0000,0x0000     ; interface path
        dw  0x0000,0x0000,0x0000,0x0000     ; device path
        dw  0x0000                          ; reserved + checksum

times (0x200 - 2 - ($ - $$)) db 0x00
dw 0xaa55
```

As always *Makefile* makes life easy. *gdb_init_real_mode.txt* I found at
[GitHub - mhugo/gdb_init_real_mode: GDB macros for real mode
debugging](https://github.com/mhugo/gdb_init_real_mode).

```make
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
```
The bootloader produces this output:
```
OS 0x03

Drive num: 0080
Cylinders: 00000002
Heads: 00000010
Sectors: 0000003F
All sectors: 0000000000000001
Sector size: 0200
PCI ATA       
```
Calculating and conversion is nicely described at [[WLBA]](https://en.wikipedia.org/wiki/Logical_block_addressing).


### References:

* [WI13] [https://en.wikipedia.org/wiki/INT_13H](https://en.wikipedia.org/wiki/INT_13H)
* [EDDS] [http://mbldr.sourceforge.net/specsedd30.pdf](http://mbldr.sourceforge.net/specsedd30.pdf)
* [WLBA] [https://en.wikipedia.org/wiki/Logical_block_addressing](https://en.wikipedia.org/wiki/Logical_block_addressing)

&nbsp;

**...SQUEAK!**
