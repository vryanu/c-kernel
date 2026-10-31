#ifndef CMDS_H
#define CMDS_H

#include <stddef.h>

typedef struct
{   /* Create command object
       pass argc & argv */
    const char *name;
    void (*func)(int argc, char **argv);
} Cmd;

void help_func(int argc, char **argv);
void color_func(int argc, char **argv);
int strncmp(const char *str1, const char *str2, size_t n);

extern Cmd help;
extern Cmd color;


#endif