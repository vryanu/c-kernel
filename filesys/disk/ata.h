#ifndef ATA_H
#define ATA_H

#include <stdint.h>

#define SECTOR_SIZE 512
/* identify the sector to read
   buffer recieves read bytes
   return true/false */
int read_sector(uint32_t sector, uint8_t *buffer);

#endif