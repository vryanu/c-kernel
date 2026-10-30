#include "../terminal/terminal.h"
#include "cmds.h"
#include "../kernel.c"

#include <stdint.h>
#include <stddef.h>

void *help_func(void)
{
    twrite("Available Commands:");
    tprintChar('\n');
    twrite("help");
    tprintChar('\n');
}

void *color_func(void)
{
    if (command[9] == '\0')
    {
        twrite("invalid color");
        tprintChar('\n');
        return;
    }
    const uint8_t color = 0;

    for (int i=0; i<3; i++)
        color>>command[6+i];

    tset_color(color);
}











