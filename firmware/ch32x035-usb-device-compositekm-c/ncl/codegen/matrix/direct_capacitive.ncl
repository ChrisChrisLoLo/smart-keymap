let C = import "codegen/contracts.ncl" in

# codegen for direct connect capacitive matrix scan with proper capacitive sensing
# Uses discharge timing to detect key presses with baseline calibration
{
  board | C.Board
    = {
      matrix,

      keymap_index_for_key,
    },

  matrix_scan =
    if board.matrix.implementation == "direct_capacitive" then
      let keys = board.matrix.cols ++ board.matrix.rows in
      {
        init_key_fragment = fun { port, pin, .. } =>
          m%"
          // %{port}%{std.to_string pin} - Initially configured as input for baseline measurement
          {
            GPIO_InitTypeDef GPIO_InitStructure = { 0 };
            GPIO_InitStructure.GPIO_Pin = GPIO_Pin_%{std.to_string pin};
            GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
            GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
            GPIO_Init( GPIO%{port}, &GPIO_InitStructure );
          }
      "%,

        keyboard_matrix_init
          | doc "Generates C fragment with the keyboard_matrix_init function for capacitive sensing."
          = fun { cols, rows, .. } =>
            m%"
      #define KEY_COUNT %{std.to_string board.matrix.key_count}

      // Capacitive sensing state
      static uint16_t key_baselines[KEY_COUNT];
      static uint16_t key_thresholds[KEY_COUNT];
      static bool baselines_calibrated = false;
      static uint32_t last_recalibration = 0;

      // Key pin definitions for capacitive sensing
      typedef struct {
          GPIO_TypeDef* port;
          uint16_t pin;
      } key_pin_t;

      static const key_pin_t key_pins[KEY_COUNT] = {
          %{keys |> std.array.map_with_index (fun idx key => 
            "{ GPIO%{key.port}, GPIO_Pin_%{std.to_string key.pin} }, // Pin %{std.to_string idx}: %{key.port}%{std.to_string key.pin}"
          ) |> std.string.join "\n          "}
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
              // Set threshold to 30% reduction from baseline
              key_thresholds[key] = key_baselines[key] * 3 / 10;
              
              // Ensure minimum threshold
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

          // Initialize all key pins
          %{keys |> std.array.map init_key_fragment |>std.string.join "\n"}

          // Perform initial baseline calibration
          Delay_Ms(100); // Allow pins to settle
          calibrate_key_baselines();
      }
      "%,



        keyboard_matrix_scan_raw
          | doc "Generates C fragment with capacitive key scanning using discharge timing."
          = fun { cols, rows, .. } =>
            m%"
      void keyboard_matrix_scan_raw(bool scan_buf[KEY_COUNT]) {
          // Periodic recalibration every ~10 seconds (assuming 1ms scan interval)
          static uint32_t scan_counter = 0;
          scan_counter++;
          
          if (!baselines_calibrated || (scan_counter % 10000 == 0)) {
              calibrate_key_baselines();
          }
          
          // Scan all keys using capacitive discharge timing
          for (int i = 0; i < KEY_COUNT; i++) {
              uint16_t discharge_time = measure_key_discharge_time(key_pins[i].port, key_pins[i].pin);
              
              // Key is pressed if discharge time is significantly faster than baseline
              scan_buf[i] = (discharge_time < (key_baselines[i] - key_thresholds[i]));
          }
      }
      "%,

        is_sw_1_1_pressed =
          m%"
        // For capacitive sensing, we need to measure the first key's discharge time
        // This is used for bootloader detection
        uint16_t first_key_discharge = measure_key_discharge_time(key_pins[0].port, key_pins[0].pin);
        
        // Use a simple threshold for bootloader detection (before full calibration)
        // Assume pressed if discharge time is very fast (< 100 cycles)
        bool sw_1_1_is_pressed = (first_key_discharge < 100);
        "%,
      }
    else
      {},
}
