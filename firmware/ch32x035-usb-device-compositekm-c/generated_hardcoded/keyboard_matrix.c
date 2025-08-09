#include <stdbool.h>

#include "debug.h"

#include "ch32x035_gpio.h"
#include "ch32x035_rcc.h"

#include "smart_keymap.h"

#ifdef KEYBOARD_SPLIT
#include "keyboard_split.h"
#endif

// Similar to https://github.com/adafruit/circuitpython/blob/main/shared-bindings/touchio/TouchIn.c at a high level

#define KEY_COUNT 9

// Capacitive sensing state
static uint16_t key_baselines[KEY_COUNT];
static uint16_t key_thresholds[KEY_COUNT];
static bool baselines_calibrated = false;

// Key pin definitions for capacitive sensing
typedef struct {
    GPIO_TypeDef* port;
    uint16_t pin;
} key_pin_t;

// All key pins mapped to their physical locations
static const key_pin_t key_pins[KEY_COUNT] = {
    { GPIOA, GPIO_Pin_10 },   // Key 0
    { GPIOA, GPIO_Pin_11 },   // Key 1
    { GPIOA, GPIO_Pin_0 },    // Key 2
    { GPIOC, GPIO_Pin_3 },    // Key 3
    { GPIOA, GPIO_Pin_2 },    // Key 4
    { GPIOA, GPIO_Pin_1 },    // Key 5
    { GPIOA, GPIO_Pin_4 },    // Key 6
    { GPIOA, GPIO_Pin_3 },    // Key 7
    { GPIOA, GPIO_Pin_5 },    // Key 8
};

uint16_t measure_key_discharge_time(GPIO_TypeDef* port, uint16_t pin) {
    uint16_t discharge_time = 0;
    
    // 1. Charge the capacitor by setting pin as output high
    GPIO_InitTypeDef GPIO_InitStructure = {0};
    GPIO_InitStructure.GPIO_Pin = pin;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(port, &GPIO_InitStructure);
    GPIO_SetBits(port, pin);
    Delay_Us(10); // Charge time
    
    // 2. Switch to input and measure discharge time
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_Init(port, &GPIO_InitStructure);
    
    // 3. Count time until pin reads low (with timeout)
    while (GPIO_ReadInputDataBit(port, pin) && discharge_time < 2000) {
        discharge_time++;
        // Small delay for timing resolution
        __asm("nop"); __asm("nop"); __asm("nop"); __asm("nop");
    }
    
    return discharge_time;
}

void calibrate_key_baselines(void) {
    // Take multiple samples and average for each key
    for (int key = 0; key < KEY_COUNT; key++) {
        uint32_t total = 0;
        uint16_t samples = 16;
        
        for (int sample = 0; sample < samples; sample++) {
            total += measure_key_discharge_time(key_pins[key].port, key_pins[key].pin);
            Delay_Us(100); // Small delay between samples
        }
        
        key_baselines[key] = total / samples;
        // Create a threshold that will be added on top of the normal baseline
        key_thresholds[key] = key_baselines[key] * (1/8);
        
        // Ensure minimum threshold
        // TODO: is 20 even reasonable??
        if (key_thresholds[key] < 20) {
            key_thresholds[key] = 20;
        }
    }
    baselines_calibrated = true;
}

void keyboard_matrix_init(void) {
    // NOTE: This implementation uses capacitive discharge timing
    // to detect key presses. Each key acts as a capacitor that
    // discharges faster when touched.

    RCC_APB2PeriphClockCmd( RCC_APB2Periph_GPIOA, ENABLE );
    RCC_APB2PeriphClockCmd( RCC_APB2Periph_GPIOB, ENABLE );
    RCC_APB2PeriphClockCmd( RCC_APB2Periph_GPIOC, ENABLE );

    // Initialize all key pins as floating inputs initially
    GPIO_InitTypeDef GPIO_InitStructure = { 0 };
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    
    // Initialize unique pins only (avoid duplicates)
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_3 | GPIO_Pin_4 | GPIO_Pin_7;
    GPIO_Init(GPIOA, &GPIO_InitStructure);
    
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_18 | GPIO_Pin_19;
    GPIO_Init(GPIOC, &GPIO_InitStructure);

    // Perform initial baseline calibration
    Delay_Ms(100); // Allow pins to settle
    calibrate_key_baselines();
}

void key_state_changed(uint32_t index, bool new_state) {
    KeymapInputEvent ev = { .event_type = 0, .value = index };
    if (new_state) {
        ev.event_type = KeymapEventPress;
    } else {
        ev.event_type = KeymapEventRelease;
    }
    keymap_register_input_event(ev);

    #ifdef KEYBOARD_SPLIT
    keyboard_split_write(ev);
    #endif
}

void keyboard_matrix_scan_raw(bool scan_buf[KEY_COUNT]) {
    // Periodic recalibration every ~10 seconds (assuming 1ms scan interval)
    static uint32_t scan_counter = 0;
    scan_counter++;
    
    // if (!baselines_calibrated || (scan_counter % 10000 == 0)) {
    if (!baselines_calibrated) {
        calibrate_key_baselines();
    }
    
    // Scan all keys using capacitive discharge timing
    for (int i = 0; i < KEY_COUNT; i++) {
        uint16_t discharge_time = measure_key_discharge_time(key_pins[i].port, key_pins[i].pin);
        
        // Key is pressed if discharge time is significantly slower than baseline
        // (finger adds capacitance, making discharge take longer)
        scan_buf[i] = (discharge_time > (key_baselines[i] + key_thresholds[i]));
    }
}

void keyboard_matrix_scan(void) {
    static bool debounced_state[KEY_COUNT] = { false };
    static bool previous_raw_scan[KEY_COUNT] = { false };
    static bool current_raw_scan[KEY_COUNT] = { false };
    static uint8_t debounce_counter[KEY_COUNT] = { 0 };

    keyboard_matrix_scan_raw(current_raw_scan);

    for (uint32_t i = 0; i < KEY_COUNT; i++) {
        if (current_raw_scan[i] == debounced_state[i]) {
            debounce_counter[i] = 0;
        } else {
            if (current_raw_scan[i] != previous_raw_scan[i]) {
                debounce_counter[i] = 0;
            } else {
                debounce_counter[i]++;
            }

            if (debounce_counter[i] >= 5) {
                key_state_changed(i, current_raw_scan[i]);
                debounced_state[i] = current_raw_scan[i];
            }
        }

        previous_raw_scan[i] = current_raw_scan[i];
    }
}