#include "main.h"
#include "gpio.h"
#include "osapi.h"
#include "user_interface.h"

#define LED_PIN 2

void ICACHE_FLASH_ATTR user_pre_init(void) {
  if (!system_partition_table_regist(
          partition_table, sizeof(partition_table) / sizeof(partition_table[0]),
          SPI_FLASH_SIZE_MAP)) {
    os_printf("system_partition_table_regist fail\r\n");
    while (1)
      ;
  }
}

void ICACHE_FLASH_ATTR user_init() {
  uint8_t value = 0;

  /* setup */
  gpio_init(); // init gpio subsytem
  gpio_output_set(0, 0, (1 << LED_PIN),
                  0); // set LED pin as output with low state

  gpio_output_set(0, (1 << LED_PIN), 0, 0); // LED on
  /* gpio_output_set((1 << LED_PIN), 0, 0, 0); // LED off */
  os_printf("hello, world!\r\n");
}
