global _start
extern printf
extern scanf
extern read

section .data
    msg     db  "write something for echo:",0x0a,0x00
    frm     db  "%s",0x00
    emg     db  "the end...",0x0a,0x00

section .text
main:
    push rbp
    mov rbp, rsp
    sub rsp, 0x80 

    lea rdi, [msg]
    call printf

    mov rdi, 0
    mov rsi, rsp
    mov rdx, 0x80
    call read

    lea rdi, [frm]
    mov rsi, rsp
    call printf

    lea rdi, [emg]
    call printf

    leave
    ret

_start:
    call main

_exit:
    mov rax, 60
    mov rdi, 0
    syscall
