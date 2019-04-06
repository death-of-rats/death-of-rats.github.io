<!--
.. title: How my shell mess with me
.. slug: how-my-shell-mess-with-me
.. date: 2019-04-05 00:00:00 UTC+02:00
.. tags: shell, tools 
.. category: fails
.. link: 
.. description: unseen encoding mess with my payload
.. type: text
-->

Last week I spent 2h instead of 20 minutes on stack overflow challenge because my payload has some 
strange values in the middle of jump address. I was impressed by this challenge, and how it managed to
put some values between my bytes.
Imagine my mood when I realized that it wasn't some special power of the program. It was my shell doing
evil decoding behind the 
scene.

<!-- TEASER_END -->

It all starts with a challenge. I'd got program with stack overflow vulnerability:
```sh
$ ./pwn1
Tell me your name: AAAA...AAAA
Hello, AAAA...AAAA
[1]    11870 segmentation fault (core dumped)  ./pwn1
$
```

And when I want to generate payload with value to overwrite return address it won't work. In **gdb** 
I notice that /my ret address wasn't what I intended it to be. It looks like this:

```sh
$ python3 -c "print('\x08\x03\xcd\x44')" | hex
0803c38d440a
$ 
```

Yep, bolded bytes are not mine 0803c**38**d44**0a**. Should I blame python? Lets check:

```sh
$ echo "print('\x08\x03\xcd\x44')"
print(�D')
$ 
```

Ok, so Python has that bizarre string to process instead of what I expected:
```sh
$ echo '\x08\x03\xcd\x44'
\x08\x03\xcd\x44
```
So, shell (**zsh**) decode for me chars in command and pass it to python, which apparently does nothing 
new - just print that chars further. When I switch to /bin/dash everything was as I expected - no evil decoding. I don't
make a decision if I should change **zsh** to another shell or just do not solve challenges in the shell - always 
write solutions in Python script. Maybe I leave things as they are and just check how much pain it will bring 
on me.

For the record, I solve this mystery one day after solving this challenge. So how I eliminate those magic 
bytes from my ret address?

```sh
$ python3 -c 'print(138*"A"+"A\u0b44\u0004\u0008")' > pwn1_arg2
```

Yep, I found (by hand) encoded values which after decoding should give me my original bytes...


**...SQUEAK!**
