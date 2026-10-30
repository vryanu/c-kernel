#ifndef TERMINAL_H
#define TERMINAL_H

#include <stdint.h>

void tinitialize(void);
void tprintChar(char c);
void twrite(const char *text);
void tclear(void);
void tset_color(uint8_t color);

extern volatile uint8_t terminal_color;

#endif