<!--
.. title: 0x07 Yasm: Echo with libc.
.. slug: yasm-libc-echo
.. date: 2019-04-29 00:00:00 UTC
.. tags: re, asm
.. category: asm
.. link: 
.. description: Printf, scanf in assembler.
.. type: text
-->

Let us write something with standard C functions like *printf* or *scanf*. What
I plan to learn from this is how to link the program with libc and do a little
refactor to program structure. 

<!-- TEASER_END -->

The mini topic for this post is 'echo'. We want to read some string and print
it. To do this with libc functions one needs to let known which functions are
external. For this purpose, we can use ```extern```. 

I'm still using **ld**. This is the reason why I use *_start* label and have to
finish the program with ```syscall``` instead of, for example, ```ret```.
But now *_start* function calls  *main*. *main* do full stack frame and do
'echo' job.

```asm
; asm01.s - scanf version
global _start
extern printf
extern scanf

section .data
    msg     db  "write something for echo:",0x0a,0x00
    frm     db  "%127s\n",0x00
    frm2    db  "%s",0x00
    emg     db  0x0a,"the end...",0x0a,0x00

section .text
main:
    push rbp
    mov rbp, rsp
    sub rsp, 0x80 

    lea rdi, [msg]
    call printf

    lea rdi, [frm]
    mov rsi, rsp
    call scanf

    lea rdi, [frm2]
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
```

To build this I created **Makefile**. In yasm section ```-g dwarf2``` is for
debug information. Linker line is also longer. It linked additional *c* library
(```-lc```). But this was not enough. When I tried to run a program linked in
this way I've got: 'no such file or directory'. I've read somewhere that **ld**
has some problems with libc on some distros. The way to solve this is to link
dynamically real lib. 

```sh
# Makefile
all: prog

prog: asm01.o
	ld -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc -o asm01 asm01.o

asm01.o: asm01.s
	yasm -f elf64 -g dwarf2 asm01.s

clean:
	rm -rf asm01.o
	rm -rf asm01
```

```sh
$ ./asm01 
write something for echo:
Echo is a nice function.... print whatever you put in...
Echo
the end...
```

Hmmm, ok something goes wrong... Ah, yes, ```%s``` reads string to a first white
character. Not what I intended. First I go for *fgets*. But it needs *FILE\**
structure for **stdin**. I didn't want to handle standard descriptions
so I have changed my mind to *read*.  So change *scanf* to *read*.

```asm
; asm01.s
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
```

Ok, this is what I want. And **Makefile** works like a charm...

&nbsp;
**...SQUEAK!**
