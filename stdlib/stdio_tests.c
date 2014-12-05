#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "stdio.h"
#include "clam_internal.h"

void printClamStringInfo(void* clamStr)
{
    printf("Ref-count: %d\n", ((uint32_t*)clamStr-1)[0]);
    printf("Length   : %d\n", ((uint32_t*)clamStr)[0]);
}

int main(int argc, char** argv)
{
    void* testString = allocClamString("Hello, world!", 13);
    printClamStringInfo(testString);
    writeln(testString);
    freeClamString(testString);
    return 0;
}
