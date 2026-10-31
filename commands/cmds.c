#include "../terminal/terminal.h"
#include "cmds.h"

#include <stdint.h>
#include <stddef.h>

Cmd help = {.name = "help", .func = help_func};
Cmd color = {.name = "color", .func = color_func};



void help_func(int argc, char **argv)
{
    (void)argc;
    if (strncmp(argv[1], "list", 4) == 0)
    {
        twriteln("Availible commands:");
        twriteln("help <command>");
        twriteln("color <color>");
        return;
    }

    twriteln("help usage:");
    twriteln("help list - list availible commands");
    twriteln("help <command> - info on a command");
}

void color_func(int argc, char **argv)
{
    if (argc != 2)
    {
        twriteln("Usage: color 0x0F");
        return;
    }

    const char *arg = argv[1];

    if (arg[0] != '0' || (arg[1] != 'x' && arg[1] != 'X'))
    {
        twriteln("Invalid hex value");
        return;
    }

    arg += 2;

    if (arg[0] == '\0' || arg[1] == '\0' || arg[2] != '\0')
    {
        twriteln("Must be 2 hex digits");
        return;
    }

    uint8_t color = 0;

    for (int i = 0; i < 2; i++)
    {
        uint8_t digit;

        if (arg[i] >= '0' && arg[i] <= '9')
            digit = arg[i] - '0';
        else if (arg[i] >= 'a' && arg[i] <= 'f')
            digit = arg[i] - 'a' + 10;
        else if (arg[i] >= 'A' && arg[i] <= 'F')
            digit = arg[i] - 'A' + 10;
        else
        {
            twriteln("Invalid hex value");
            return;
        }

        color = (color << 4) | digit;
    }

    tset_color(color);
}

int strncmp(const char *str1, const char *str2, size_t n)
{
    for (size_t i = 0; i < n; i++)
    {
        if (str1[i] != str2[i] || str1[i] == '\0')
            return (unsigned char)str1[i] - (unsigned char)str2[i];
    }

    return 0;
}










