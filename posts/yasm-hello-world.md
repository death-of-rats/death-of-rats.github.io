<!--
.. title: 0x06 Yasm: Hello World! ELF64
.. slug: yasm-hello-world
.. date: 2019-04-26 00:00:00 UTC
.. tags: re, asm
.. category: asm
.. link: 
.. description: Simple hello world in assebmbler.
.. type: text
-->

First, try to write some x64 assembler program. I will use **yasm** and **ld**.
I have a few books about assembler, but not for 64-bit architecture. Lucky for
me, I found the "Introduction to 64 Bit Assembly Language Programming for Linux
and OS X" by Ray Seyfarth.

<!-- TEASER_END -->

What I remember from old asm, are sections: ```.text``` section for code and
```.data``` for data. 

Let us start with 'the simplest' example:

```asm
;asm00.s

section .data
    msg       db     'Hello world!'
    nl        db     0x0a
    msgLen    equ    $-msg
section .text
global _start
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, msgLen
    syscall
    
    mov rax, 60
    mov rdi, 0
    syscall
```

To build this code one must run **yasm** assembler and **ld** linker:

```sh
$ yasm -f elf64 asm00.s
$ ld -o asm00 asm00.o
```

And the effect:

```sh
$ ./asm00
Hello world!
$ 
```
Ok, so what happens here? We have here 2 calls to the *syscall*. The first
one is calling to *sys_write* (```mov rax, 1```) to print to *stdout* (file
descriptor 1 ```mov rdi, 1```). In ```rsi``` and ```rdx``` we pass address of
text to print and its length.
The second call is to *sys_exit* (```mov rax, 60```). I want to exit with 0,
so I pass it to ```rdi```.

The list of
available **syscalls** I found
[here](http://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/).


&nbsp;

The fun begins...

**...SQUEAK!**
