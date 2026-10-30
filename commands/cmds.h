#ifndef CMDS_H
#define CMDS_H

typedef struct
{   /* Create command object
    consists of name and function */
    const char *name;
    void (*func)(const char *command);
} Cmd;

void help_func(const char *command);
void color_func(const char *command);

extern Cmd help;
extern Cmd color;

#endif