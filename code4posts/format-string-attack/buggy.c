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