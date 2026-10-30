#include "terminal/terminal.h"
#include "commands/cmds.h"

#include <stdint.h>
#include <stddef.h>

#define KEYBOARD_BUFFER ((volatile char *)0x70000)
#define KEYBOARD_LEN    (*(volatile uint32_t *)0x70080)
#define COMMAND_READY   (*(volatile uint8_t *)0x70084)
#define KEYBOARD_CURSOR (*(volatile uint32_t *)0x70088)
#define COMMAND_MAX 128

int strcmp(const char *str1, const char *str2);
static void shell_execute(const char *command);
static int parse_command(char *destination);

char command[COMMAND_MAX];

void kernel_main(void)
{
    tinitialize();

    twrite("Kernel Initialized");
    tprintChar('\n');

    while(1)
    {
        if (parse_command(command))
        {
            shell_execute(command);
        }
        __asm__ volatile ("hlt");
    }
}

static void shell_execute(const char *command)
{
    if (strcmp(command, help.name) == 0)
        help.func();
    else if (strcmp(command, color.name) == 0)
        color.func();
    else
    {
        twrite("command not found");
        tprintChar('\n');
    }

}

static int parse_command(char *destination)
{
    uint32_t flags;
    uint32_t length;

    __asm__ volatile ( // temp disable interrupts and save state
        "pushfl\n"
        "popl %0\n"
        "cli"
        : "=r"(flags)
        :
        : "memory"
    );

    if (!COMMAND_READY)
    {
        __asm__ volatile ( // reenable interrupts
            "pushl %0\n"
            "popfl"
            :
            : "r"(flags)
            : "memory", "cc"
        );

        return 0;
    }

    length = KEYBOARD_LEN;

    if (length >= COMMAND_MAX)
        length = COMMAND_MAX - 1;

    for (uint32_t i = 0; i < length; i++)
        destination[i] = KEYBOARD_BUFFER[i];

    destination[length] = '\0';

    // Reset inputs state
    KEYBOARD_LEN = 0;
    KEYBOARD_BUFFER[0] = '\0';
    COMMAND_READY = 0;

    // restore interrupt state
    __asm__ volatile (
        "pushl %0\n"
        "popfl"
        :
        : "r"(flags)
        : "memory", "cc"
    );

    return 1;
}



int strcmp(const char *str1, const char *str2)
{
    while (*str1 && (*str1 == *str2))
    {
        str1++;
        str2++;
    }

    return (unsigned char)*str1 - (unsigned char)*str2;
}
