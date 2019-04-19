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