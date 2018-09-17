/*
 * This file is part of the MicroPython project, http://micropython.org/
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 Daniel Campora
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <stdint.h>
#include <stdbool.h>
#include "inc/hw_types.h"
#include "inc/hw_ints.h"
#include "inc/hw_nvic.h"
#include "inc/hw_shamd5.h"
#include "inc/hw_memmap.h"
#include "inc/hw_sysctl.h"
#include "driverlib/rom_map.h"
#include "driverlib/sysctl.h"
#include "driverlib/shamd5.h"
#include "cryptohash.h"


/******************************************************************************
 DEFINE PUBLIC FUNCTIONS
 ******************************************************************************/
void CRYPTOHASH_Init (void) {
    // Enable the Data Hashing and Transform Engine
    MAP_SysCtlPeripheralEnable(SYSCTL_PERIPH_CCM0); //Enable the CCM module.
	while(!MAP_SysCtlPeripheralReady(SYSCTL_PERIPH_CCM0)); //Wait for the CCM module to be ready.
    
    MAP_SHAMD5Reset(SHAMD5_BASE); //Reset the SHA/MD5 module before use.
}

void CRYPTOHASH_SHAMD5Start (uint32_t algo, uint32_t blocklen) {
    // wait until the context is ready
    while ((HWREG(SHAMD5_BASE + SHAMD5_O_IRQSTATUS) & SHAMD5_INT_CONTEXT_READY) == 0);
    
    // Configure the SHA/MD5 module algorithm
    MAP_SHAMD5ConfigSet(SHAMD5_BASE, algo);

    // if not a multiple of 64 bytes, close the hash
    if (blocklen % 64) {
        HWREG(SHAMD5_BASE + SHAMD5_O_MODE) |= SHAMD5_MODE_CLOSE_HASH;
    }

    // set the lenght
    HWREG(SHAMD5_BASE + SHAMD5_O_LENGTH) = blocklen;
}

void CRYPTOHASH_SHAMD5Update (uint8_t *data, uint32_t datalen) {
    // write the data
    //SHAMD5DataWriteMultiple(data, datalen);
	uint32_t ui32SHA256Result[8];
    SHAMD5DataProcess(SHAMD5_BASE, (uint32_t *)data,  datalen, ui32SHA256Result);
}

void CRYPTOHASH_SHAMD5Read (uint8_t *hash) {
    // wait for the output to be ready
    //while((HWREG(SHAMD5_BASE + SHAMD5_O_IRQSTATUS) & SHAMD5_INT_OUTPUT_READY) == 0);
    // read the result
    MAP_SHAMD5ResultRead(SHAMD5_BASE, (uint32_t *)hash);
}
