<!--
.. title: Icon 2018 CTF third challenge
.. slug: icon_2018_ctf_third_challenge
.. date: 2018-09-14 00:00:00 UTC+02:00
.. tags: ctf,icon,re,reverse,writeups
.. category: ctf
.. link: 
.. description: Writeup on easy reverse engineering challenge
.. type: text
-->

Third challenge is a reverse engineering problem. Ziped package contains 3 files:

```sh
crackme_baby
crackme.py
run.sh
```

Python file contains definitions of simple math operations (add, sub, mul, div2, mod, inf). Let us
 disassemble crackme_baby file.

Main function shows us that 2 long variables are in play, `d1 = 25052671110843108` 
 and `d2 = 16420105858350620421142892712`. They are passed to `calc_flag__object___object` to calculate 
value for the flag. This value is hashed with sha256 and print in format flag{*hashed_value*}.

```nasm
.0x000021c3      push rbp                    ; main(int argc, char** argv)
.0x000021c4      mov rbp, rsp
.0x000021c7      push rbx
.0x000021c8      sub rsp, 0x88
.0x000021cf      mov dword [local_84h], edi  ; argc
.0x000021d5      mov qword [local_90h], rsi  ; argv
.0x000021dc      mov rax, qword fs:[0x28]    ; [0x28:8]=0x6108 ; '('
.0x000021e5      mov qword [local_18h], rax
.0x000021e9      xor eax, eax
.0x000021eb      call sym.imp.Py_Initialize
.0x000021f0      mov edx, 0xa
.0x000021f5      mov esi, 0
.0x000021fa      lea rdi, qword str.25052671110843108 ; 0x2aa0 ; "25052671110843108"
.0x00002201      call sym.imp.PyLong_FromString       ; create python long object
.0x00002206      mov qword [local_78h], rax           ; here we have d1
.0x0000220a      mov edx, 0xa
.0x0000220f      mov esi, 0
.0x00002214      lea rdi, qword str.16420105858350620421142892712 ; 0x2ab2 ; "16420105858350620421142892712"
.0x0000221b      call sym.imp.PyLong_FromString
.0x00002220      mov qword [local_70h], rax           ; here we have d2
.0x00002224      mov rdx, qword [local_70h]
.0x00002228      mov rax, qword [local_78h]
.0x0000222c      mov rsi, rdx
.0x0000222f      mov rdi, rax
.0x00002232      call sym.calc_flag__object___object ; compute the value for the flag
.0x00002237      mov qword [local_68h], rax
.0x0000223b      lea rsi, qword str.flag:_flag ; 0x2ad0 ; "flag: flag{"  
.0x00002242      lea rdi, qword obj._ZSt4cout__GLIBCXX_3.4 ; 0x204020
.0x00002249      call sym.std::basic_ostream_char_std::char_traits_char___std::operator___std::char_traits_char___std::basic_ostream_char_std::char_traits_char____charconst
.0x0000224e      mov rbx, rax
.0x00002251      mov rax, qword [local_68h] ; get computed value
.0x00002255      mov rdi, rax
.0x00002258      call sym.imp.PyLong_AsLong ; convert Python object to long
.0x0000225d      mov rdx, rax
.0x00002260      lea rax, qword [local_60h]
.0x00002264      mov rsi, rdx
.0x00002267      mov rdi, rax
.0x0000226a      call sym.std::__cxx11::to_string_long ; long -> string
.0x0000226f      lea rax, qword [local_40h] ; buffer for sha256 result
.0x00002273      lea rdx, qword [local_60h] ; string with the computed long value
.0x00002277      mov rsi, rdx
.0x0000227a      mov rdi, rax
.0x0000227d      call sym.sha256_std::__cxx11::basic_string_char_std::char_traits_char__std::allocator_char
.0x00002282      lea rax, qword [local_40h] ; we will print sha256 hash
.0x00002286      mov rsi, rax
.0x00002289      mov rdi, rbx
.0x0000228c      call sym.std::basic_ostream_char_std::char_traits_char___std::operator___char_std::char_traits_char__std::allocator_char___std::basic_ostream_char_std::char_traits_char____std::__cxx11::basic_string_char_std::char_traits_char__std::allocator_char__const
.0x00002291      lea rsi, qword [0x00002adc] ; "}" 
.0x00002298      mov rdi, rax
.0x0000229b      call sym.std::basic_ostream_char_std::char_traits_char___std::operator___std::char_traits_char___std::basic_ostream_char_std::char_traits_char____charconst
.0x000022a0      mov rdx, rax
                  ...
```

So it's time to look closer at function `calc_flag__object___object`. First instructions just load `crackme.py` 
and import math functions: 

```nasm
.0x00001e83      push rbp                               
.0x00001e84      mov rbp, rsp                
.0x00001e87      sub rsp, 0x70               ; 'p'
.0x00001e8b      mov qword [local_68h], rdi  ; d1
.0x00001e8f      mov qword [local_70h], rsi  ; d2
.0x00001e93      lea rdi, qword str.crackme  ; 0x2a7f ; "crackme"
.0x00001e9a      call sym.imp.PyUnicode_FromString
.0x00001e9f      mov qword [local_48h], rax
.0x00001ea3      mov rax, qword [local_48h]
.0x00001ea7      mov rdi, rax                           
.0x00001eaa      call sym.imp.PyImport_Import
.0x00001eaf      mov qword [local_40h], rax             
.0x00001eb3      mov rax, qword [local_40h]
.0x00001eb7      mov rdi, rax
.0x00001eba      call sym.imp.PyModule_GetDict
.0x00001ebf      mov qword [local_38h], rax
.0x00001ec3      mov rax, qword [local_38h]
.0x00001ec7      lea rsi, qword [0x00002a87] ; "add"
.0x00001ece      mov rdi, rax
.0x00001ed1      call sym.imp.PyDict_GetItemString
.0x00001ed6      mov qword [local_30h], rax
.0x00001eda      mov rax, qword [local_38h]
.0x00001ede      lea rsi, qword [0x00002a8b] ; "sub"
.0x00001ee5      mov rdi, rax
.0x00001ee8      call sym.imp.PyDict_GetItemString
.0x00001eed      mov qword [local_28h], rax
.0x00001ef1      mov rax, qword [local_38h]
.0x00001ef5      lea rsi, qword [0x00002a8f] ; "mul"
.0x00001efc      mov rdi, rax
.0x00001eff      call sym.imp.PyDict_GetItemString
.0x00001f04      mov qword [local_20h], rax
.0x00001f08      mov rax, qword [local_38h]
.0x00001f0c      lea rsi, qword str.div2     ; 0x2a93 ; "div2"
.0x00001f13      mov rdi, rax
.0x00001f16      call sym.imp.PyDict_GetItemString
.0x00001f1b      mov qword [local_18h], rax
.0x00001f1f      mov rax, qword [local_38h]
.0x00001f23      lea rsi, qword [0x00002a98] ; "mod"
.0x00001f2a      mov rdi, rax
.0x00001f2d      call sym.imp.PyDict_GetItemString
.0x00001f32      mov qword [local_10h], rax
.0x00001f36      mov rax, qword [local_38h]
.0x00001f3a      lea rsi, qword [0x00002a9c] ; "sup"
.0x00001f41      mov rdi, rax
.0x00001f44      call sym.imp.PyDict_GetItemString
.0x00001f49      mov qword [local_8h], rax
``` 

From above code we can extract variables with functions imported and assigned to them:

````
 local_30h | add
 local_28h | sub
 local_20h | mul
 local_18h | div2
 local_10h | mod
 local_8h  | sup
````
and also our longs:

````
 local_68h | d1
 local_70h | d2
````

We will need this to find out what calculations take place in `calc_flag__object___object`. 
I will replace *local_xxh* with known or choosen names.
This way the graph below should be easer to underestand.

```
                                                        ...
                                   | mov qword [sup], rax                       |                               
                                   | mov edi, 2                                 |                               
                                   | call sym.imp.PyLong_FromLong;[ge]          |                               
                                   | mov qword [factor], rax                    |                               
                                   | mov edi, 1                                 |                               
                                   | call sym.imp.PyLong_FromLong;[ge]          |                               
                                   | mov qword [last_factor], rax               |                               
                                   `--------------------------------------------'                               
                                                               |                                                
                                                               |                                                
     .---------------------------------------------------------.                                                
     |                                                         |                                                
     |                                                         |                                                
     |                        .------------------------------------------------------------------.              
     |                        |  0x1f69 ;[gj]                                                    |              
     |                        |      ; JMP XREF from 0x0000200d (sym.calc_flag__object___object) |              
     |                        | mov edi, 1                                                       |              
     |                        | call sym.imp.PyLong_FromLong;[ge]                                |              
     |                        | mov rdx, rax                                                     |              
     |                        | mov rcx, qword [d1]                                              |              
     |                        | mov rax, qword [sup]                                             |              
     |                        | mov rsi, rcx                                                     |              
     |                        | mov rdi, rax                                                     |              
     |                        | call sym.call__object___object___object;[gg]                     | 
     |                        | mov rdi, rax                                                     |              
     |                        | call sym.imp.PyLong_AsLong;[gh]                                  |              
     |                        | test rax, rax                                                    |              
     |                        | setne al                                                         |              
     |                        | test al, al                                                      |              
     |                        | je 0x2012;[gi]                                                   |              
     |                        `------------------------------------------------------------------'              
     |                                                             | |                                          
     |                                                             | '------------.                             
     |                    .----------------------------------------'              |                             
     |.---------------.   |                                                       |                             
     ||               |   |                                                       |                             
     ||               |   |                                                       |                             
     ||  .-----------------------------------------------.  .-----------------------------------------------.  
     ||  |  0x1f9b ;[gl]                                 |  | [0x2012] ;[gi]                                |  
     ||  |      ; JMP XREF from 0x00001fe7               |  |      ; JMP XREF from 0x00001f99               | 
     ||  |      ;   (sym.calc_flag__object___object)     |  |      ;   (sym.calc_flag__object___object)     |
     ||  | mov rdx, qword [factor]                       |  | mov rdx, qword [last_factor]                  |  
     ||  | mov rcx, qword [d1]                           |  | mov rcx, qword [d2]                           |  
     ||  | mov rax, qword [mod]                          |  | mov rax, qword [sub]                          |  
     ||  | mov rsi, rcx                                  |  | mov rsi, rcx                                  |  
     ||  | mov rdi, rax                                  |  | mov rdi, rax                                  |  
     ||  | call sym.call__object___object___object;[gg]  |  | call sym.call__object___object___object;[gg]  |  
     ||  | mov rdi, rax                                  |  | leave                                         |  
     ||  | call sym.imp.PyLong_AsLong;[gh]               |  | ret                                           |  
     ||  | test rax, rax                                 |  `-----------------------------------------------'  
     ||  | sete al                                       |                                                                      
     ||  | test al, al                                   |                                                                      
     ||  | je 0x1fe9;[gk]                                |                                                                      
     ||  `-----------------------------------------------'                                                                      
     ||                   | |                                                                                                    
     ||                   | '------------------------------------.                                                               
     ||        .----------'                                      |                                                               
     ||        |                                                 |                                                               
     ||        |                                                 |                                                               
     ||.-----------------------------------------------.   .------------------------------------------------------------------.  
     |||  0x1fc4 ;[gm]                                 |   |  0x1fe9 ;[gk]                                                    |  
     ||| mov rdx, qword [factor]                       |   |      ; JMP XREF from 0x00001fc2 (sym.calc_flag__object___object) |  
     ||| mov rcx, qword [d1]                           |   | mov edi, 1                                                       |  
     ||| mov rax, qword [div2]                         |   | call sym.imp.PyLong_FromLong;[ge]                                |  
     ||| mov rsi, rcx                                  |   | mov rdx, rax                                                     |  
     ||| mov rdi, rax                                  |   | mov rcx, qword [factor]                                          |  
     ||| call sym.call__object___object___object;[gg]  |   | mov rax, qword [add]                                             |  
     ||| mov qword [d1], rax                           |   | mov rsi, rcx                                                     |  
     ||| mov rax, qword [factor]                       |   | mov rdi, rax                                                     |  
     ||| mov qword [last_factor], rax                  |   | call sym.call__object___object___object;[gg]                     |  
     ||| jmp 0x1f9b;[gl]                               |   | mov qword [factor], rax                                          |  
     ||`-----------------------------------------------'   | jmp 0x1f69;[gj]                                                  |  
     ||    |                                               `------------------------------------------------------------------'  
     ||    |                                                   |                                                                 
     |`----'                                                   |                                                    
     `---------------------------------------------------------' 
```

Calling python functions convention is to put adress of imported function to `rdi` register,
adress of python object with first argument to `rsi` and second to `rdx`. Then there is a call to
 `sym.call__object___object___object`, result will be also python object which adress will be in `rax` register.

Algorithm shown above could be describe like this:

 1. Set `factor = 2` and `last_factor = 2`.
 2. Next we check if `d1` is greater than `1`. If not `return d2 - last_factor`.
 3. Test if `factor` divides `d1` with no rest. If *True* then go to *step 4*  else *step 5*.
 4. `d1 = d1 / factor` and save value of `factor` in `last_factor` and go to *step 2*. 
 5. `factor += 1` and go to *step 2*.

In other words when condition `d1 > 1` will not be fullfilled `last_factor` will holds the greatest
 prime factor of `d1`. And this value will be substracted from `d2` and the result will be returned
 from function. As you might already suspect running this program will gives us nothing.
 So we better write our faster version of it.

To get the greatest prime factor of `d1` I will use **[primefac](https://pypi.org/project/primefac/)**  python library.

```
import primefac
import hashlib

arg1 = 25052671110843108
arg2 = 16420105858350620421142892712

fac = list( primefac.primefac(arg1) )
bigestPrime = fac[-1]
flag = arg2 - bigestPrime
flag_str = str(flag)
f = hashlib.sha256(flag_str.encode('utf-8')).hexdigest()
print("flag{%s}"%(f))
```
And there it is:
```
flag{5121b89fd330e8aaf59109e37ea3adf9c9497ee49dac1262e039919a9cb84912}
```

...**SQUEAK**!
