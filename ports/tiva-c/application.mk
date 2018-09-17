APP_INC =  -I.
APP_INC += -I$(TOP)
APP_INC += -Ihal
APP_INC += -Ihal/inc
APP_INC += -Ihal/driverlib
APP_INC += -Imisc
APP_INC += -Imods
APP_INC += -Ifatfs/src
APP_INC += -Ifatfs/src/drivers

APP_INC += -I$(BUILD)
APP_INC += -I$(BUILD)/genhdr

APP_CPPDEFINES = -Dgcc

APP_HAL_SRC_C = $(addprefix hal/,\
	utils.c \
	driverlib/startup_gcc.c \
	driverlib/adc.c \
	driverlib/aes.c \
	driverlib/cpu.c \
	driverlib/crc.c \
	driverlib/des.c \
	driverlib/gpio.c \
	driverlib/i2c.c \
	driverlib/interrupt.c \
	driverlib/pin.c \
	driverlib/shamd5.c \
	driverlib/ssi.c \
	driverlib/systick.c \
	driverlib/timer.c \
	driverlib/uart.c \
	driverlib/watchdog.c \
	)

APP_MAIN_SRC_C = \
	main.c \
	mphalport.c \
	irq.c \

APP_MISC_SRC_C = $(addprefix misc/,\
	help.c \
	mpirq.c \
	mperror.c \
	mpexception.c \
	fatfs_port.c \
	gccollect.c \
	bufhelper.c \
	random.c \
	fifo.c \
	cryptohash.c \
	)

APP_MISC_SRC_S = $(addprefix misc/,\
	gchelper.s \
	sleeprestore.s \
	)
	

APP_MODS_SRC_C = $(addprefix mods/,\
	modmachine.c \
	modtiva.c \
	modubinascii.c \
	moduos.c \
	modutime.c \
	pybadc.c \
	pybpin.c \
	pybi2c.c \
	pybrtc.c \
	pybsleep.c \
	pybspi.c \
	pybtimer.c \
	pybuart.c \
	pybwdt.c \
	)
#	pybsd.c \
#	pybflash.c \
    
APP_LIB_SRC_C = $(addprefix lib/,\
	oofatfs/ff.c \
	oofatfs/option/unicode.c \
	libc/string0.c \
	mp-readline/readline.c \
	netutils/netutils.c \
	timeutils/timeutils.c \
	utils/pyexec.c \
	utils/interrupt_char.c \
	utils/sys_stdio_mphal.c \
	)

APP_FATFS_SRC_C = $(addprefix fatfs/src/,\
	drivers/sd_diskio.c \
	)
#	drivers/sflash_diskio.c \

    
OBJ = $(PY_O) $(addprefix $(BUILD)/, $(APP_HAL_SRC_C:.c=.o) )
OBJ += $(addprefix $(BUILD)/, $(APP_MAIN_SRC_C:.c=.o) $(APP_MISC_SRC_C:.c=.o) $(APP_MISC_SRC_S:.s=.o))
OBJ += $(addprefix $(BUILD)/, $(APP_MODS_SRC_C:.c=.o) $(APP_FATFS_SRC_C:.c=.o) $(APP_LIB_SRC_C:.c=.o))
OBJ += $(BUILD)/pins.o

# List of sources for qstr extraction
SRC_QSTR += $(APP_MODS_SRC_C) $(APP_MISC_SRC_C)
# Append any auto-generated sources that are needed by sources listed in SRC_QSTR
SRC_QSTR_AUTO_DEPS +=

# Add the linker script
LINKER_SCRIPT = application.lds
LDFLAGS += -T $(LINKER_SCRIPT)

# Add the application specific CFLAGS
CFLAGS += $(APP_CPPDEFINES) $(APP_INC)

# Check if we would like to debug the port code
ifeq ($(BTYPE), release)
CFLAGS += -DNDEBUG
else
ifeq ($(BTYPE), debug)
CFLAGS += -DNDEBUG
else
$(error Invalid BTYPE specified)
endif
endif


all: $(BUILD)/application.bin

.PHONY: 

$(BUILD)/application.axf: $(OBJ) $(LINKER_SCRIPT)
	$(ECHO) "LINK $@"
	$(Q)$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)
	$(Q)$(SIZE) $@

$(BUILD)/application.bin: $(BUILD)/application.axf
	$(ECHO) "Create $@"
	$(Q)$(OBJCOPY) -O binary $< $@


MAKE_PINS = boards/make-pins.py
BOARD_PINS = boards/$(BOARD)/pins.csv
AF_FILE = boards/tm4c_af.csv
PREFIX_FILE = boards/tm4c_prefix.c
GEN_PINS_SRC = $(BUILD)/pins.c
GEN_PINS_HDR = $(HEADER_BUILD)/pins.h
GEN_PINS_QSTR = $(BUILD)/pins_qstr.h

# Making OBJ use an order-only dependency on the generated pins.h file
# has the side effect of making the pins.h file before we actually compile
# any of the objects. The normal dependency generation will deal with the
# case when pins.h is modified. But when it doesn't exist, we don't know
# which source files might need it.
$(OBJ): | $(GEN_PINS_HDR)

# Call make-pins.py to generate both pins_gen.c and pins.h
$(GEN_PINS_SRC) $(GEN_PINS_HDR) $(GEN_PINS_QSTR): $(BOARD_PINS) $(MAKE_PINS) $(AF_FILE) $(PREFIX_FILE) | $(HEADER_BUILD)
	$(ECHO) "Create $@"
	$(Q)$(PYTHON) $(MAKE_PINS) --board $(BOARD_PINS) --af $(AF_FILE) --prefix $(PREFIX_FILE) --hdr $(GEN_PINS_HDR) --qstr $(GEN_PINS_QSTR) > $(GEN_PINS_SRC)

$(BUILD)/pins.o: $(BUILD)/pins.c
	$(call compile_c)
