#include <stdbool.h>

#include "debug.h"

#include "ch32x035_flash.h"
#include "ch32x035_gpio.h"
#include "ch32x035_rcc.h"

#include "smart_keymap.h"

#include "keyboard_matrix.h"

#ifdef KEYBOARD_LED_ENABLED
#include "keyboard_led.h"
#endif
#ifdef KEYBOARD_SPLIT
#include "keyboard_split.h"
#endif

void keyboard_reset_to_bootloader(void) {
    SystemReset_StartMode(Start_Mode_BOOT);
    NVIC_SystemReset();
}

void keyboard_init(void) {
    keyboard_matrix_init();

    // GPIO_ResetBits(GPIOB, GPIO_Pin_1); // col 0
    // Delay_Us(5);
    // bool sw_1_1_is_pressed = GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_4) != 1; // row0
    // if (sw_1_1_is_pressed) {
    //     keyboard_reset_to_bootloader();
    // }

    // keymap_register_callback(KEYMAP_CALLBACK_BOOTLOADER, keyboard_reset_to_bootloader);

    // Disable SWD
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_AFIO, ENABLE);
    GPIO_PinRemapConfig(GPIO_Remap_SWJ_Disable, ENABLE);

    // Init LED
    {
      GPIO_InitTypeDef GPIO_InitStructure = {0};
      GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6;
      GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
      GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
      GPIO_Init(GPIOA, &GPIO_InitStructure);
    }

    
}