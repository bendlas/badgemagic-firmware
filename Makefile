######################################
# target
######################################
TARGET = badgemagic-ch582


######################################
# building variables
######################################
# Uncomment below line to enable debugging
# DEBUG = 1
# Uncomment below to build for USB-C version
USBC_VERSION = 1
# optimization for size
OPT = -Os


#######################################
# Get current version
#######################################
VERSION = $(shell git describe --tags --dirty)
VERSION_ABBR = $(shell git describe --abbrev=0 --tags 2>/dev/null || echo "unknown")
ifeq ($(VERSION_ABBR),unknown)
	$(warning Unable to determine version from git tags)
endif

#######################################
# paths
#######################################
# Build path
BUILD_DIR ?= build

######################################
# source
######################################
# C sources
C_SOURCES = \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_i2c.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_timer2.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_spi0.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_gpio.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_pwr.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_uart3.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_uart2.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_sys.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_clk.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_uart0.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_timer1.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_pwm.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_usbhostClass.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_adc.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_usbhostBase.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_timer3.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_timer0.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_usb2hostClass.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_flash.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_uart1.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_usb2dev.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_usb2hostBase.c \
CH5xx_ble_firmware_library/StdPeriphDriver/CH58x_spi1.c \
CH5xx_ble_firmware_library/RVMSIS/core_riscv.c \
src/main.c \
src/leddrv.c \
src/button.c \
src/bmlist.c \
src/ble/profile/legacy.c \
src/ble/profile/devinfo.c \
src/ble/setup.c \
src/ble/peripheral.c \
src/data.c \
src/usb/utils.c \
src/usb/setup.c \
src/usb/ctrl.c \
src/usb/debug.c \
src/usb/dev.c \
src/usb/composite/hiddev.c \
src/usb/composite/cdc-serial.c \
src/xbm.c \
src/resource.c \
src/animation.c \
src/font.c \


# ASM sources
ASM_SOURCES =  \
CH5xx_ble_firmware_library/Startup/startup_CH583.S

#######################################
# binaries
#######################################
PREFIX ?= riscv32-none-elf-

CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size

HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

#######################################
# CFLAGS
#######################################
# cpu

CPU = -march=rv32imac_zicsr -mabi=ilp32 -msmall-data-limit=8

# fpu
FPU = 

# float-abi
FLOAT-ABI =

# mcu
MCU = $(CPU) $(FPU) $(FLOAT-ABI)

# AS includes
AS_INCLUDES = 

# C includes
C_INCLUDES =  \
-ICH5xx_ble_firmware_library/StdPeriphDriver/inc \
-ICH5xx_ble_firmware_library/RVMSIS \
-ICH5xx_ble_firmware_library/Core \
-ICH5xx_ble_firmware_library/BLE \

# compile gcc flags
ASFLAGS = $(MCU) $(AS_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

CFLAGS = $(MCU) $(C_INCLUDES) $(OPT) -Wall -fdata-sections -ffunction-sections

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2 -DDEBUG=$(DEBUG)
endif

ifeq ($(USBC_VERSION), 1)
CFLAGS += -DUSBC_VERSION=$(USBC_VERSION)
endif

CFLAGS += -DVERSION='"$(VERSION)"' -DVERSION_ABBR='"$(VERSION_ABBR)"'

# Generate dependency information
CFLAGS += -MMD -MP

# Use soft interrups, because of missing proprietary feature (WCH-Interrupt-fast)
# TODO: fix for mainline gcc, see:
#  https://github.com/hydrausb3/riscv-none-elf-gcc-xpack
#  https://www.eevblog.com/forum/microcontrollers/ch32v003-fast-interrupt-(pfic)-features/
#  https://www.reddit.com/r/RISCV/comments/126262j/notes_on_wch_fast_interrupts/
CFLAGS += -DINT_SOFT


#######################################
# LDFLAGS
#######################################
# link script
LDSCRIPT = CH5xx_ble_firmware_library/Ld/Link.ld 

# libraries
LIBS = -lc -lnosys \
	./CH5xx_ble_firmware_library/StdPeriphDriver/libISP583.a \
	./CH5xx_ble_firmware_library/BLE/LIBCH58xBLE.a \

LIBDIR = 
LDFLAGS = $(MCU) -mno-save-restore -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -Wunused -Wuninitialized -T $(LDSCRIPT) -nostartfiles -Xlinker --gc-sections -Wl,-Map=$(BUILD_DIR)/$(TARGET).map --specs=nano.specs $(LIBS)

# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin


#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/, $(C_SOURCES:.c=.o))

# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/, $(ASM_SOURCES:.S=.o))

$(BUILD_DIR)/%.o: %.c Makefile
	@mkdir -pv $(dir $@)
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(@:.o=.lst) $< -o $@

$(BUILD_DIR)/%.o: %.S Makefile
	@mkdir -pv $(dir $@)
	$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	@mkdir -pv $(dir $@)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf
	@mkdir -pv $(dir $@)
	$(HEX) $< $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	@mkdir -pv $(dir $@)
	$(BIN) $< $@	

#######################################
# Program
#######################################
program: $(BUILD_DIR)/$(TARGET).elf
	sudo wch-openocd -f /usr/share/wch-openocd/openocd/scripts/interface/wch-riscv.cfg -c 'init; halt; program $(BUILD_DIR)/$(TARGET).elf; reset; wlink_reset_resume; exit;'

isp: $(BUILD_DIR)/$(TARGET).bin
	wchisp flash $(BUILD_DIR)/$(TARGET).bin

#######################################
# clean up
#######################################
clean:
	rm -f $(OBJECTS)
	rm -f $(OBJECTS:%.o=%.d)
	rm -f $(OBJECTS:%.o=%.lst)
	rm -f $(BUILD_DIR)/$(TARGET).*
	find $(BUILD_DIR) -type d -empty -delete 

#######################################
# dependencies
#######################################
-include $(OBJECTS:%.o=%.d)

# *** EOF ***
