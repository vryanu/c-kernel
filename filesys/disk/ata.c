#include "ata.h"
#include <stdint.h>

#define DATA 0x1F0
#define ERROR 0x1F1
#define SEC_COUNT 0x1F2
#define LBA_LOW 0x1F3
#define LBA_MID 0x1F4
#define LBA_HIGH 0x1F5
#define DRIVE 0x1F6
#define STATUS 0x1F7
#define COMMAND 0x1F7
#define CONTROL 0x3F6
#define BUSY 0x80
#define DRQ 0x08
#define ERR 0x01
#define DF 0x20
#define READ 0x20

static inline void outb(unsigned short port, unsigned char value)
{ // write an 8bit value to a IO port
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline unsigned char inb(unsigned short port)
{ // reads & returns 8bit value from an IO port
    unsigned char value;
    __asm__ volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static inline unsigned short inw(unsigned short port)
{ // reads & returna a 16 bit value from IO port
    unsigned short value;
    __asm__ volatile ("inw %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

static int wait(int require_drq)
{
    for (int i=0; i<1000000; i++)
    {
        unsigned char status = inb(STATUS); // read status

        if (status == 0xFF || status == 0x00) // handle no ATA devices/no response
            return -1;

        if (status & ERR || status & DF) // handle ATA errors
            return -1;

        if (!(status & BUSY))
        {
            if (!require_drq || (status & DRQ))
                return 0;
        }
    }
    return -1;
}

int read_sector(uint32_t lba, uint8_t *buffer)
{
    if (buffer == 0 || lba >= 0x10000000) // handle null and invalid lba value
        return -1;

    outb(DRIVE, 0xF0 | ((lba >> 24) & 0x0F)); /* select Slave device 0xF0,
                                              lba>>24 selects highest 4 bits of sector */

    for (volatile int i = 0; i < 4; i++) // delay after selection, dont let compiler remove reads
        inb(CONTROL);

    if (wait(0) != 0) // stop busy flag
        return -1;

    outb(SEC_COUNT, 1); // 1 sector needed
    outb(LBA_LOW,  (unsigned char)lba); // low bits 0-7
    outb(LBA_MID,  (unsigned char)(lba >> 8)); // mid bits 8 - 15
    outb(LBA_HIGH, (unsigned char)(lba >> 16)); // high bits 16 - 23
    // 24bit LBA is split into 4 parts, low, mid, high, and drive contains upper 4 bits
    outb(COMMAND, READ); // write the read to command

    if (wait(1) != 0) // wait for busy flag til drq flag is set
        return -1;

    for (int i = 0; i < SECTOR_SIZE / 2; i++) 
    {
        unsigned short word = inw(DATA); // read in 2 bytes of data, 512/2 = 256 reads needed
        buffer[i * 2] = (uint8_t)word; // split lower bits
        buffer[i * 2 + 1] = (uint8_t)(word >> 8); // split upper bits
        // buffer filled with 512 bytes
    }

    return 0;
}
