#include <stdbool.h>

#include "debug.h"

#include "ch32x035_gpio.h"

static uint16_t keyboard_led_timer = 0;
static uint8_t keyboard_led_state = 0;

void keyboard_led_tick(void) {
    // Toggle the LED every 1000 ticks
    keyboard_led_timer++;
    if (keyboard_led_timer > 1000) {
        keyboard_led_timer = 0;
        keyboard_led_state = 1 - keyboard_led_state;

        GPIO_WriteBit(GPIOA, GPIO_Pin_5, keyboard_led_state);
    }
}