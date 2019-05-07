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
