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
    const char *themes[][2] = { {"default", "0x0F"},
                                {"hacker", "0x0A"}, 
                                {"halloween", "0x60"},
                                {"christmas", "0x42"},
                                {"sky", "0x1F"},
                                {"void", "0x00"},
                                {"neon", "0xA9"} };

    if (argc != 2)
    {
        twriteln("Usage: color 0x0F");
        return;
    }

    const char *arg = argv[1];
    int found = 0;

    if (arg[0] != '0' || (arg[1] != 'x' && arg[1] != 'X'))
    {
        for (size_t i = 0; i < sizeof(themes) / sizeof(themes[0]); i++)
        {
            int result = strcmp(argv[1], themes[i][0]);
            if (result == 0)
            {
                arg = themes[i][1];
                found = 1;
                break;
            }
        }
        if (!found)
        {
            twriteln("Unknown theme");
            return;
        }
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

int strcmp(const char *str1, const char *str2) 
{
    while (*str1 && (*str1 == *str2)) {
        str1++;
        str2++;
    }

    return *(const unsigned char *)str1 - *(const unsigned char *)str2;
}










