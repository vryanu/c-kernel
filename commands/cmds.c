#include "../terminal/terminal.h"
#include "cmds.h"

#include <stdint.h>

Cmd help = {.name = "help", .func = help_func};
Cmd color = {.name = "color", .func = color_func};

void help_func(const char *command)
{
    (void)command;
    twrite("Available Commands:");
    tprintChar('\n');
    twrite("help");
    tprintChar('\n');
}

void color_func(const char *command)
{
    const char *arg = command + 6;

    if (arg[0] != '0' || (arg[1] != 'x' && arg[1] != 'X'))
    {
        twrite("Usage: color 0x0F");
        tprintChar('\n');
        return;
    }

    arg += 2;

    uint8_t color = 0;

    while (*arg)
    {
        uint8_t digit;

        if (*arg >= '0' && *arg <= '9')
            digit = *arg - '0';
        else if (*arg >= 'a' && *arg <= 'f')
            digit = *arg - 'a' + 10;
        else if (*arg >= 'A' && *arg <= 'F')
            digit = *arg - 'A' + 10;
        else
        {
            twrite("Invalid hex value");
            tprintChar('\n');
            return;
        }

        color = (color << 4) | digit;
        arg++;
    }

    tset_color(color);
}











