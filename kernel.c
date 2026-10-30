#include "terminal/terminal.h"
#include "commands/cmds.h"

#include <stdint.h>
#include <stddef.h>

#define KEYBOARD_BUFFER ((volatile char *)0x70000)
#define KEYBOARD_LEN    (*(volatile uint32_t *)0x70080)
#define COMMAND_READY   (*(volatile uint8_t *)0x70084)
#define KEYBOARD_CURSOR (*(volatile uint32_t *)0x70088)
#define COMMAND_MAX 128

int strncmp(const char *str1, const char *str2, size_t n);
static void shell_execute(const char *command);
static int parse_command(char *destination);

void kernel_main(void)
{
    tinitialize();

    twrite("Kernel Initialized");
    tprintChar('\n');

    char command[COMMAND_MAX];

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
    if (strncmp(command, help.name, 4) == 0)
        help.func(command);
    else if (strncmp(command, color.name, 5) == 0)
        color.func(command);
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



int strncmp(const char *str1, const char *str2, size_t n)
{
    for (size_t i = 0; i < n; i++)
    {
        if (str1[i] != str2[i] || str1[i] == '\0')
            return (unsigned char)str1[i] - (unsigned char)str2[i];
    }

    return 0;
}
