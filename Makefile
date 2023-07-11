###############################################################################
#                                    config                                   #
###############################################################################

# target flash chip size (KiB) ################################################
TARGET_FLASH_SIZE := 4096

# esptool config ##############################################################
# chip selection, see:
#   esptool.py --help
ESPTOOL_CHIP := esp8266
# SPI flash mode, see:
#   https://docs.espressif.com/projects/esptool/en/latest/esp8266/advanced-topics/spi-flash-modes.html#spi-flash-modes
ESPTOOL_FLASH_MODE := qio
# SPI flash frequency, see:
#   https://docs.espressif.com/projects/esptool/en/latest/esp8266/esptool/flash-modes.html#flash-frequency-flash-freq-ff
ESPTOOL_FLASH_FREQ := 80m
# serial port baud rate, may be needed to be lowered. see:
#   https://docs.espressif.com/projects/esptool/en/latest/esp8266/esptool/basic-options.html#baud-rate
ESPTOOL_SERIAL_BAUD := 1500000

# directory storing user source
DIR_SRC = src
# directory storing build artifacts
DIR_BUILD = build
# name of output file
OUT_NAME = main
# directory storing generated linker scripts
DIR_LD = ld

CC = xtensa-lx106-elf-gcc
CFLAGS = -I${ESP8266_NONOS_SDK}/include -Iinclude -mlongcalls
LDLIBS = -nostdlib -Wl,--start-group -lmain -lnet80211 -lwpa -llwip -lpp -lphy -lc -lcrypto -Wl,--end-group -lgcc
LDFLAGS = -L${ESP8266_NONOS_SDK}/lib
ESPTOOL = esptool.py --chip $(ESPTOOL_CHIP) --baud $(ESPTOOL_SERIAL_BAUD)


###############################################################################
#                                  generated                                  #
###############################################################################

# get parameters depending on target flash size ###############################
#  TARGET_FLASH_SIZE_HEX     - flash chip size (hexadecimal)
#  ESPTOOL_FLASH_SIZE        - value of --flash_size to pass size to bootloader
#  SPI_FLASH_SIZE_MAP        - last argument of system_partition_table_regist, see:
#    https://github.com/espressif/ESP8266_NONOS_SDK/blob/version_3.0.4/include/user_interface.h#L142
#  SYSTEM_FLASH_PROGRAM_SIZE - maximum size of program defined in linker script, see:
#    ESP8266 SDK Getting Started Guide, Section 4.1.1. Flash Map

# NOTE: supplied sample program is too big to fit inside this flash chip
ifeq ($(TARGET_FLASH_SIZE),512)
  # FLASH_SIZE_4M_MAP_256_256
	SPI_FLASH_SIZE_MAP        := 0
	ESPTOOL_FLASH_SIZE        := 512KB
	TARGET_FLASH_SIZE_HEX     := 0x80000
	SYSTEM_FLASH_PROGRAM_SIZE := 0x5C000
endif

ifeq ($(TARGET_FLASH_SIZE),1024)
  # FLASH_SIZE_8M_MAP_512_512
	SPI_FLASH_SIZE_MAP        := 2
	ESPTOOL_FLASH_SIZE        := 1MB
	TARGET_FLASH_SIZE_HEX     := 0x100000
	SYSTEM_FLASH_PROGRAM_SIZE := 0xBC000
endif

ifeq ($(TARGET_FLASH_SIZE),2048)
  # FLASH_SIZE_16M_MAP_512_512
	SPI_FLASH_SIZE_MAP        := 3
	ESPTOOL_FLASH_SIZE        := 2MB
	TARGET_FLASH_SIZE_HEX     := 0x200000
	SYSTEM_FLASH_PROGRAM_SIZE := 0xC0000
endif

ifeq ($(TARGET_FLASH_SIZE),4096)
  # FLASH_SIZE_32M_MAP_512_512
	SPI_FLASH_SIZE_MAP        := 4
	ESPTOOL_FLASH_SIZE        := 4MB
	TARGET_FLASH_SIZE_HEX     := 0x400000
	SYSTEM_FLASH_PROGRAM_SIZE := 0xC0000
endif

# calculate ROM addresses #####################################################
SYSTEM_PARTITION_SYSTEM_PARAMETER_ADDR := \
	$(shell printf "0x%X\n" $$(($(TARGET_FLASH_SIZE_HEX) - 0x3000))) # -12KiB
SYSTEM_PARTITION_PHY_DATA_ADDR := \
	$(shell printf "0x%X\n" $$(($(TARGET_FLASH_SIZE_HEX) - 0x4000))) # -16KiB
SYSTEM_PARTITION_RF_CAL_ADDR := \
	$(shell printf "0x%X\n" $$(($(TARGET_FLASH_SIZE_HEX) - 0x5000))) # -20KiB

CFLAGS += -DTARGET_FLASH_SIZE_HEX=$(TARGET_FLASH_SIZE_HEX)
CFLAGS += -DSPI_FLASH_SIZE_MAP=$(SPI_FLASH_SIZE_MAP)
CFLAGS += -DSYSTEM_PARTITION_SYSTEM_PARAMETER_ADDR=$(SYSTEM_PARTITION_SYSTEM_PARAMETER_ADDR)
CFLAGS += -DSYSTEM_PARTITION_PHY_DATA_ADDR=$(SYSTEM_PARTITION_PHY_DATA_ADDR)
CFLAGS += -DSYSTEM_PARTITION_RF_CAL_ADDR=$(SYSTEM_PARTITION_RF_CAL_ADDR)

LD_TARGET := $(DIR_LD)/eagle.app.v6.$(TARGET_FLASH_SIZE).ld
LDFLAGS += -T$(LD_TARGET)


###############################################################################
#                                   targets                                   #
###############################################################################

default: $(DIR_BUILD)/$(OUT_NAME)-0x00000.bin

$(DIR_BUILD)/$(OUT_NAME).o: $(DIR_SRC)/$(OUT_NAME).c $(LD_TARGET)
	@mkdir -p $(DIR_BUILD)
	$(CC) $(CFLAGS) $(LDLIBS) $(LDFLAGS) -o $@ -c $<

$(DIR_BUILD)/$(OUT_NAME)-0x00000.bin: $(DIR_BUILD)/$(OUT_NAME)
	$(ESPTOOL) elf2image $^

$(DIR_BUILD)/$(OUT_NAME): $(DIR_BUILD)/$(OUT_NAME).o

# create linker script.
# the default linker script targets a 1MiB flash:
# copy it and change program size according to the target chip
$(LD_TARGET): ${ESP8266_NONOS_SDK}/ld/eagle.app.v6.ld ${ESP8266_NONOS_SDK}/ld/eagle.rom.addr.v6.ld
	@mkdir -p $(DIR_LD)
	@cp ${ESP8266_NONOS_SDK}/ld/eagle.rom.addr.v6.ld $(DIR_LD)/eagle.rom.addr.v6.ld
	@cp ${ESP8266_NONOS_SDK}/ld/eagle.app.v6.ld $(LD_TARGET)
	@sed -i "8s/0x5C000/$(SYSTEM_FLASH_PROGRAM_SIZE)/" $(LD_TARGET)

# flash chip.
# writes both bootloader and actual program to fixed addresses as defined in ESP8266 flash map.
flash: $(DIR_BUILD)/$(OUT_NAME)-0x00000.bin
	$(ESPTOOL) \
		write_flash \
		--flash_mode $(ESPTOOL_FLASH_MODE) \
		--flash_size $(ESPTOOL_FLASH_SIZE) \
		--flash_freq $(ESPTOOL_FLASH_FREQ) \
		0x00000 $(DIR_BUILD)/$(OUT_NAME)-0x00000.bin \
		0x10000 $(DIR_BUILD)/$(OUT_NAME)-0x10000.bin

# erase flash.
# sets initial data for system as expected by non-OS SDK.
erase_flash:
	$(ESPTOOL) erase_flash && \
	$(ESPTOOL) write_flash \
		--flash_mode $(ESPTOOL_FLASH_MODE) \
		--flash_freq $(ESPTOOL_FLASH_FREQ) \
		$(SYSTEM_PARTITION_RF_CAL_ADDR) ${ESP8266_NONOS_SDK}/bin/blank.bin \
		$(SYSTEM_PARTITION_PHY_DATA_ADDR) ${ESP8266_NONOS_SDK}/bin/esp_init_data_default_v08.bin \
		$(SYSTEM_PARTITION_SYSTEM_PARAMETER_ADDR) ${ESP8266_NONOS_SDK}/bin/blank.bin

# clean build artifacts.
clean:
	@rm -f $(DIR_LD)/*.ld
	@rm -f $(DIR_BUILD)/*
