#ifndef CMDS_H
#define CMDS_H

typedef struct
{    /* Create command object
        consists of name and function */
    const char *name;
    void (*func)(void);
} Cmd;

void *help_func(void);
extern Cmd help = {.name = "help", .func = help_func};

void *color_func(void);
extern Cmd color = {.name = "color", .func = color_func};

#endif