# Select the board to build for: 
BOARD ?= itac_dio
ifeq ($(wildcard boards/$(BOARD)/.),)
$(error Invalid BOARD specified)
endif

BTARGET ?= application

# Make 'release' the default build type
BTYPE ?= release


# If the build directory is not given, make it reflect the board name.
BUILD ?= build/$(BOARD)/$(BTYPE)

include ../../py/mkenv.mk
-include ../../localconfig.mk

CROSS_COMPILE ?= arm-none-eabi-

CFLAGS_CORTEX_M4 = -mthumb -mtune=cortex-m4 -march=armv7e-m -mabi=aapcs -mcpu=cortex-m4 -msoft-float -mfloat-abi=soft -fsingle-precision-constant -Wdouble-promotion
CFLAGS = -Wall -Wpointer-arith -Werror -std=gnu99 -nostdlib $(CFLAGS_CORTEX_M4) -Os
CFLAGS += -g -ffunction-sections -fdata-sections -fno-common -fsigned-char -mno-unaligned-access
CFLAGS += -Iboards/$(BOARD)
CFLAGS += $(CFLAGS_MOD)

LDFLAGS = -Wl,-nostdlib -Wl,--gc-sections -Wl,-Map=$@.map

FLASH_SIZE_LAUNCHXL = 1M

ifeq ($(BTARGET), application)
# qstr definitions (must come before including py.mk)
QSTR_DEFS = qstrdefsport.h $(BUILD)/pins_qstr.h
# include MicroPython make definitions
include $(TOP)/py/py.mk
include application.mk
else
$(error Invalid BTARGET specified)
endif

# always include MicroPython make rules
include $(TOP)/py/mkrules.mk


