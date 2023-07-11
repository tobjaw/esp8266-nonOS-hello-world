# esp8266-nonOS-hello-world

Minimal example to program an ESP8266 using the non-OS SDK.

## Background

The ESP8266 is an inexpensive but powerful WiFi-enabled SoC.  
While official support (of the non-OS SDK) has been dropped, modules featuring the SoC (such as the
[LOLIN D1 mini v3.1.0](https://www.wemos.cc/en/latest/d1/d1_mini_3.1.0.html)) are still widely available.  
There are various ways to get started programming the chip, but I've had trouble locating a minimal end-to-end example of how to program an ESP8266 using v3 of the non-OS SDK with no OTA firmware updates enabled.  
This has only been tested with the D1 mini module on macOS Ventura, but the example _should_ work on other ESP8266 configurations and platforms (`aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `i686-linux`, possibly Windows with WSL).

## Dependencies

- GNU Make
- ESP8266 Toolchain v2020r3
- ESP8266 non-OS SDK v3
- ESPTool.py

## Usage

### Install

The **recommended** way is to use the included Nix development shell.  
To get all dependencies: install Nix with flake support and run

```
nix develop
```

**Alternatively**, you can manually get the required dependencies.  
Make sure the binaries of the ESP8266 toolchain v2020r3 as well as `esptool.py` are in `PATH`
and set the `ESP8266_NONOS_SDK` environment variable to the root directory of the
ESP8266 non-OS SDK v3 or greater.

### Configuration

Adjust values in the config section of the [Makefile](./Makefile) to fit your environment.  
In particular, `TARGET_FLASH_SIZE` must match the size of your flash chip in KiB,
e.g. `4096` for the D1 mini module.

### Compile

Generate bootloader and actual program.

```
make
```

### Erase Flash

Erase flash and sets initial data for system as expected by non-OS SDK.  
**Required** before initial flashing.

```
make erase_flash
```

### Flash

Flash bootloader and actual program.

```
make flash
```

After successful flashing, the ESP8266 should reboot and light up the internal LED.  
On the serial console, the output should look like the following:

```
 ets Jan  8 2013,rst cause:2, boot mode:(3,6)

load 0x3ffe8000, len 1276, room 16
tail 12
chksum 0xd0
ho 0 tail 12 room 4
load 0x3ffe8500, len 1316, room 12
tail 8
chksum 0xf6
load 0x40100000, len 27280, room 0
tail 0
chksum 0x04
csum 0x04
boot not set
ota1 not set
ota2 not set
V2
Mo

rf cal sector: 1019
freq trace enable 0
rf[112] : 00
rf[113] : 00
rf[114] : 01

SDK ver: 3.0.5(b29dcd3) compiled @ Oct  9 2021 09:52:05
phy ver: 1156_0, pp ver: 10.2

hello, world!
mode : softAP(3e:71:bf:31:64:a5)
add if1
dhcp server start:(ip:192.168.4.1,mask:255.255.255.0,gw:192.168.4.1)
bcn 100
```

### TTY

By default, the ESP8266 uses the following serial port settings:

| Parameter    | Value |
| ------------ | ----- |
| Baud Rate    | 74880 |
| Data Bits    | 8     |
| Stop Bits    | 1     |
| Parity       | None  |
| Flow Control | None  |

In essence, it communicates using the `8-N-1` schema, but with the non-standard baud rate of
`74880`.  
Many terminal emulators (such as `screen`) unfortunatly **do not support** this baud rate by default.  
I have yet to find a free non-GUI platform-independant terminal emulator that supports this baud rate.

## Documentation

Refer to the [Makefile](./Makefile) for some details on the process of programming the ESP8266
using the non-OS SDK with no OTA updates.

Useful links:

- [ESP8266 SDK Getting Started Guide](https://www.espressif.com/sites/default/files/documentation/2a-esp8266-sdk_getting_started_guide_en.pdf)  
  Despite the _obsolete_ label, this seems to be the most up-to-date resource containing the actual flash maps.
- [Official ESP8266 Documentation](http://espressif.com/en/support/download/documents?keys=&field_type_tid%5B%5D=14)
- [ESP8266 non-OS SDK](https://github.com/espressif/ESP8266_NONOS_SDK)
- [ESPTool.py Documentation](https://docs.espressif.com/projects/esptool/en/latest/esp8266/index.html)
