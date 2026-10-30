#include "terminal.h"

#include <stdint.h>

#define KEYBOARD_CURSOR (*(volatile uint32_t *)0x70088)
#define VGA_WIDTH  80
#define VGA_HEIGHT 25
#define VGA_MEMORY ((volatile uint16_t *)0xB8000)

static uint8_t terminal_color;

static uint16_t vga_entry(char c, uint8_t color)
{   /* combine char and color, c=A & color=0x0F
       will return 0x0F41 */
    return (uint16_t)c | ((uint16_t)color << 8);
}

static void tupdate_cursor(void)
{   /* write to cursors memory in asm
       moves the cursor to supposed screen spot */
    uint32_t position = (KEYBOARD_CURSOR - 0xB8000) / 2;

    uint8_t low = position & 0xFF;
    uint8_t high = (position >> 8) & 0xFF;

    __asm__ volatile ("outb %0, %1"
        : : "a"((uint8_t)0x0F), "Nd"((uint16_t)0x3D4));

    __asm__ volatile ("outb %0, %1"
        : : "a"(low), "Nd"((uint16_t)0x3D5));

    __asm__ volatile ("outb %0, %1"
        : : "a"((uint8_t)0x0E), "Nd"((uint16_t)0x3D4));

    __asm__ volatile ("outb %0, %1"
        : : "a"(high), "Nd"((uint16_t)0x3D5));
}

static void tnewline(void)
{   /* Move to next row
       currently wraps no scrolling */
    uint32_t offset = KEYBOARD_CURSOR - 0xB8000;
    uint32_t row = offset / (VGA_WIDTH * 2);

    row++;

    if (row >= VGA_HEIGHT)
        row = 0;

    KEYBOARD_CURSOR = 0xB8000 + row * VGA_WIDTH * 2;
}

void tinitialize(void)
{   /* set terminals color to black
       clear all text */
    terminal_color = 0x0F;
    tclear();
}

void tprintChar(char c)
{   /* handle newline and carriage return escape keys
       writes the vga entry to the next vga memory
       update & move cursor memory address */
    if (c == '\n')
    {
        tnewline();
    }
    else if (c == '\r')
    {
        uint32_t offset = KEYBOARD_CURSOR - 0xB8000;
        uint32_t row = offset / (VGA_WIDTH * 2);

        KEYBOARD_CURSOR = 0xB8000 + row * VGA_WIDTH * 2;
    }
    else
    {
        *(volatile uint16_t *)KEYBOARD_CURSOR =
            vga_entry(c, terminal_color);

        KEYBOARD_CURSOR += 2;

        uint32_t offset = KEYBOARD_CURSOR - 0xB8000;

        if (offset >= VGA_WIDTH * VGA_HEIGHT * 2)
        {
            KEYBOARD_CURSOR = 0xB8000;
        }
        else if (offset % (VGA_WIDTH * 2) == 0)
        {
            tnewline();
        }
    }

    tupdate_cursor();
}

void twrite(const char *text)
{   // prints a string by repeat printing chars
    while (*text)
        tprintChar(*text++);
}

void tclear(void)
{   /* iterate all VGA bytes
       sets all memory to a space with terminal color 
       reset the rows & columns */
    for (uint32_t i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++)
        VGA_MEMORY[i] = vga_entry(' ', terminal_color);

    KEYBOARD_CURSOR = 0xB8000;

    tupdate_cursor();
}

void tset_color(uint8_t color)
{ // change color
    terminal_color = color;
}
