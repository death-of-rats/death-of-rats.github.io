<!--
.. title: 0x03 building cpprest sample
.. slug: building-cpprest-sample
.. date: 2018-05-27 22:00:00 UTC
.. tags: cpp,rest,cmake
.. category: cmake
.. link: 
.. description: set up cmake for building cpprest sample project
.. type: text
-->

One can install the [C++ REST SDK](https://github.com/Microsoft/cpprestsdk) running 
`sudo apt install libcpprest-dev`. Unfortunately after that my CMake couldn't find it. 
I have some other troubles with compiling a project with cpprest. So I change my mind and 
I built the library from the source 
([instructions](https://github.com/Microsoft/cpprestsdk/wiki/How-to-build-for-Linux)).

To try the new toy I choose this [sample](https://github.com/Microsoft/cpprestsdk/blob/master/Release/samples/BingRequest/bingrequest.cpp).
<!-- TEASER_END -->
For the test, I will rename the source file to `main.cpp`. Let us create CMakeLists.txt. The readme of 
the project gives us the example:
```sh
cmake_minimum_required(VERSION 3.7)
project(main)

find_package(cpprestsdk REQUIRED)

add_executable(main main.cpp)
target_link_libraries(main PRIVATE cpprestsdk::cpprest)
```

I know this is the time of trial:
```sh
$ mkdir build
$ cd build
$ cmake ..
```

```
 -- The C compiler identification is GNU 7.3.0
 -- The CXX compiler identification is GNU 7.3.0
 -- Check for working C compiler: /usr/bin/cc
 -- Check for working C compiler: /usr/bin/cc -- works
 -- Detecting C compiler ABI info
 -- Detecting C compiler ABI info - done
 -- Detecting C compile features
 -- Detecting C compile features - done
 -- Check for working CXX compiler: /usr/bin/c++
 -- Check for working CXX compiler: /usr/bin/c++ -- works
 -- Detecting CXX compiler ABI info
 -- Detecting CXX compiler ABI info - done
 -- Detecting CXX compile features
 -- Detecting CXX compile features - done
 -- Found ZLIB: /usr/lib/x86_64-linux-gnu/libz.so (found version "1.2.11") 
 -- Found OpenSSL: /usr/lib/x86_64-linux-gnu/libcrypto.so (found version "1.1.0g") 
 -- Configuring done
 -- Generating done
 -- Build files have been written to: ~/Projects/cpprest01/build
```

```sh
$ make
```

```
 Scanning dependencies of target main
 [ 50%] Building CXX object CMakeFiles/main.dir/main.cpp.o
 [100%] Linking CXX executable main
 /usr/bin/x86_64-linux-gnu-ld: CMakeFiles/main.dir/main.cpp.o: undefined reference to symbol '_ZN5boost6system15system_categoryEv'
 //usr/lib/x86_64-linux-gnu/libboost_system.so.1.65.1: error adding symbols: DSO missing from command line
 collect2: error: ld returned 1 exit status
 CMakeFiles/main.dir/build.make:97: recipe for target 'main' failed
 make[2]: \*\*\* [main] Error 1
 CMakeFiles/Makefile2:67: recipe for target 'CMakeFiles/main.dir/all' failed
 make[1]: \*\*\* [CMakeFiles/main.dir/all] Error 2
 Makefile:83: recipe for target 'all' failed
 make: \*\*\* [all] Error 2
```


## cmake for Microsoft/cpprestsdk

Ok, so it doesn't work... surprise, surprise.

Time to go back to instructions for building **cpprest** on Linux. There is `g++` instruction 
at the end of the page. It builds the project with our library:

```cpp
g++ -std=c++11 my_file.cpp -o my_file -lboost_system -lcrypto -lssl -lcpprest ./my_file
```

And it works... So change our `CMakeLists.txt`. We want to use *Boost* and *OpenSSL* (this 
library contains both *SSL* and *crypto*). Add this two libraries to cmake configuration:

```sh
...
find_package(Boost REQUIRED COMPONENTS system)
find_package(OpenSSL REQUIRED)
                                             # show lib paths
message("OpenSSL: " ${OPENSSL_LIBRARIES})    # libs to be linked by OpenSSL
message("Boost: " ${Boost_LIBRARIES})        # linked components of Boosta

add_executable(main main.cpp)
target_link_libraries(main PRIVATE
    cpprestsdk::cpprest
    ${Boost_LIBRARIES}
    ${OPENSSL_LIBRARIES})

```

```sh
$ cmake ..
```

```
 -- The C compiler identification is GNU 7.3.0
 -- The CXX compiler identification is GNU 7.3.0
 -- Check for working C compiler: /usr/bin/cc
 -- Check for working C compiler: /usr/bin/cc -- works
 -- Detecting C compiler ABI info
 -- Detecting C compiler ABI info - done
 -- Detecting C compile features
 -- Detecting C compile features - done
 -- Check for working CXX compiler: /usr/bin/c++
 -- Check for working CXX compiler: /usr/bin/c++ -- works
 -- Detecting CXX compiler ABI info
 -- Detecting CXX compiler ABI info - done
 -- Detecting CXX compile features
 -- Detecting CXX compile features - done
 -- Found ZLIB: /usr/lib/x86_64-linux-gnu/libz.so (found version "1.2.11") 
 -- Found OpenSSL: /usr/lib/x86_64-linux-gnu/libcrypto.so (found version "1.1.0g") 
 -- Boost version: 1.65.1
 -- Found the following Boost libraries:
 --   system
 OpenSSL: /usr/lib/x86_64-linux-gnu/libssl.so/usr/lib/x86_64-linux-gnu/libcrypto.so
 Boost: /usr/lib/x86_64-linux-gnu/libboost_system.so
 -- Configuring done
 -- Generating done
 -- Build files have been written to: ~/Projects/cpprest01/build
```

```sh
$ make
```

```
 Scanning dependencies of target main
 [ 50%] Building CXX object CMakeFiles/main.dir/main.cpp.o
 [100%] Linking CXX executable main
 [100%] Built target main
```

Done. One day in a hundred lines...

...**PIP**!
