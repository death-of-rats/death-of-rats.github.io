<!--
.. title: 0x04 cpprest listener
.. slug: cpprest-listener
.. date: 2018-06-01 00:00:00 UTC+02:00
.. tags: cpp,cpprest,rest,server,http
.. category: cpp
.. link: 
.. description: first cpprest listener demo - experimantal
.. type: text
-->

I want to try to build simple REST server demo with *cpprestsdk*. It is still experimental part of the library.

Let's start the program. I want to listen on *localhost* on port 9000 with relative path */demo*. For now, 
the program will handle only *GET* and *POST*. When the listener starts, we get a notification. 
*cpprestsdk* uses `pplx::task<T>` for composing asynchronous operations (`...then().then().wait()`). The main
loop is very simple, we just `while` infinitely.

<!-- TEASER_END -->

```c++
#include <cpprest/http_listener.h>
#include <cpprest/json.h>
#include <iostream>
#include <string>

using namespace web;
using namespace web::http;
using namespace web::http::experimental::listener;
using namespace std;

void handle_get(http_request request) {
    wcout << L"[HTTP] GET\n";
    json::value  answer;
    answer[U("version")] = json::value::string(U("0.0.1"));
    answer[U("name")] = json::value::string(U("death of rats"));
    request.reply(status_codes::OK, answer);
}

void handle_post(http_request request) {
    wcout << L"[HTTP] POST\n";
    request
        .extract_json()
        .then([&request](json::value val) {
            if(val.is_null()) {
                request.reply(status_codes::BadRequest, U("No object in post data."));
            } else {
                request.reply(status_codes::OK, val);
            }
        }).wait();
}

int main() {
    http_listener listener(uri(U("http://localhost:9000/demo")));

    listener.support(methods::GET, handle_get);
    listener.support(methods::POST, handle_post);

    try {
        listener
            .open()
            .then([&listener](){
                wcout << L"starting to listen\n";        
            })
            .wait();

        while(true);
    } catch(exception const &e) {
        wcout << e.what() << endl;
    }
    
    return 0;
}
```

To build this code I use CMake with configuration from last post 
\[[0x03 building cpprest sample](/posts/building-cpprest-sample/)]. 

```
cmake_minimum_required(VERSION 3.7)
project(simargl C CXX)
set (simargl_VERSION_MAJOR 0)
set (simargl_VERSION_MINOR 1)
set (CMAKE_CXX_STANDARD 14)

set( CMAKE_EXPORT_COMPILE_COMMANDS ON )
find_package(cpprestsdk REQUIRED )
find_package(Boost REQUIRED COMPONENTS system)
find_package(OpenSSL REQUIRED)

add_executable(simargl src/main.cpp)
target_link_libraries(simargl PRIVATE
	cpprestsdk::cpprest
	${Boost_LIBRARIES} 
	${OPENSSL_LIBRARIES}
	)

#message("OpenSSL libs:" ${OPENSSL_LIBRARIES})
#message("Boost libs :" ${Boost_LIBRARIES})
#message("CppRest libs :" ${cpprestsdk_LIBRARIES})
```

The build goes flawlessly. To test the cpprest listener run the program and try a few curl commands:

```sh
$ curl http://localhost:9000/demo
```
```
{"name":"death of rats","version":"0.0.1"}
```
```sh
$ curl --request POST --data '{"label":"value"}' -H "Content-Type: application/json"  http://localhost:9000/demo
```
```
{"label":"value"}
```

What have I learned? If one is looking for examples, one should look up tests...

...**SQUEAK**!
