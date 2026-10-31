#include "terminal/terminal.h"
#include "commands/cmds.h"

#include <stdint.h>
#include <stddef.h>

#define KEYBOARD_BUFFER ((volatile char *)0x70000)
#define KEYBOARD_LEN    (*(volatile uint32_t *)0x70080)
#define COMMAND_READY   (*(volatile uint8_t *)0x70084)
#define KEYBOARD_CURSOR (*(volatile uint32_t *)0x70088)
#define COMMAND_MAX 128
#define MAX_ARGS 16

static int parse_args(char *command, char **argv);
static void shell_execute(const char *command);
static int parse_command(char *destination);

extern void idt_init(void);
extern void pic_init(void);

void kernel_main(void)
{   /* initialize idt, pic, terminal
       main loop, waits and checks for input*/

    idt_init();
    pic_init();

    tinitialize();

    twrite("Kernel Initialized");
    tprintChar('\n');

    __asm__ volatile ("sti");

    char command[COMMAND_MAX];

    while(1)
    {
        if (parse_command(command))
            shell_execute(command);

        __asm__ volatile ("hlt");
    }
}

static void shell_execute(const char *command)
{   /* fill argv and argc
       call according functions */
    char buffer[COMMAND_MAX];
    char *argv[MAX_ARGS];

    size_t i = 0;

    while (command[i] && i < COMMAND_MAX - 1)
    {
        buffer[i] = command[i];
        i++;
    }

    buffer[i] = '\0';

    int argc = parse_args(buffer, argv);

    if (argc == 0)
        return;

    if (strncmp(argv[0], help.name, 4) == 0)
        help.func(argc, argv);
    else if (strncmp(argv[0], color.name, 5) == 0)
        color.func(argc, argv);
    else
    {
        twrite("command not found");
        tprintChar('\n');
    }
}

static int parse_command(char *destination)
{   /* disables interrupts to parse inputted command
       returns 1 if there is text */
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

static int parse_args(char *command, char **argv)
{   /* creates inline args
       every space/tab = an arg
       returns argc for the count
       loops each space/tab for command
       fills argv with commands */
    int argc = 0;
    char *p = command;

    while (*p && argc < MAX_ARGS)
    {
        while (*p == ' ' || *p == '\t')
            p++;

        if (*p == '\0')
            break;

        argv[argc++] = p;

        while (*p && *p != ' ' && *p != '\t')
            p++;

        if (*p)
            *p++ = '\0';
    }

    return argc;
}
