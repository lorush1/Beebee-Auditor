 # technical deep dive
 
 this doc goes into the techy details of how the verilog glue works, what happens on each cycle, and how to reason about the safety paths. it stays low on fluff while keeping the tone soft, but it dives into the actual register transfers, clocks, and signal checks that make the project tick.
 
 ## module map
 - `top.v` wires up three guard rails: `bus_monitor`, `logic_auditor`, and `shadow_plc`. there is no additional logic inside `top`; it just gives each submodule the right ports and lets them talk through shared nets such as `ALERT`, `capture_active`, and `EMERGENCY_STOP`.
 - `bus_monitor` watches spi lines and raises `capture_active` when the ascii string `STAR` is fully observed.
 - `logic_auditor` polls the sensors and the plc timer, latching `ALERT` high whenever both sensor bits [0:1] are set and the timer has crossed the threshold.
 - `shadow_plc` delays the alert signal across a 5-cycle shift register, feeds that into `shadow_comparator`, and exposes `EMERGENCY_STOP` if the shadow output ever disagrees with the physical output.
 - `tb_top` is our simple stimulus driver; it toggles clock/reset, stabs the sensor bits, raises `physical_output`, and waits for `EMERGENCY_STOP`.
 
 ## clock domains and resets
 - single `clk` drives everything; each module is edge sensitive on `posedge clk`.
 - asynchronous resets:
   - `bus_monitor` and `shadow_plc` use active-low `rst_n` so the registers zero out when the reset line drops.
   - `logic_auditor` uses `hw_reset` (active high) so it can be asserted independently of the spi/reset domain – this mimics a manual hardware reset.
 - when `rst_n` is low, `capture_active`, SPI buffers, delay registers, and emergency stop are forced to zero immediately. the `logic_auditor` latch only clears when `hw_reset` is asserted, so alerts persist until someone actively resets them.
 
 ## spi capture path (bus_monitor)
 - `bus_monitor` samples SPI on the rising edge of `spi_sck` whenever `spi_ss_n` is low (active) and the chip select is held.
 - `sck_d` stores the previous clock state so we detect a rising edge only once per cycle; this prevents double counting if the clk and spi clocks are close.
 - `shift_reg[7:0]` collects the current byte by shifting in `spi_mosi` each rising edge.
 - `bit_cnt` tracks the bit position; once it reaches 7, the byte is ready:
   - `byte_val` captures the full byte with the last `spi_mosi` bit appended.
   - `byte_valid` signals the rest of the always block that the byte is available and pushes it into the 32-bit `window`.
   - the 32-bit window shifts left by 8 bits (`next_window = {window[23:0], byte_val}`), so `window` always holds the last four bytes on the spi bus.
   - if `window == START_SIG` (which equals ascii `STAR`), we assert `capture_active` for the rest of that frame.
 - when `spi_ss_n` goes high or reset hits, we clear all counters, so the capture window only contains valid bytes from the current transaction.
 
 ## logic auditor
 - uses a single register `latch_alert`; the combinational signal `logic_bomb` checks `sensors[0] & sensors[1]` and if `plc_timer` passes the constant threshold `0x00FF_FFFF`.
 - `logic_bomb` is evaluated every clock; the logic follows this chain:
   1. when both sensor bits are 1 and the timer is above threshold, `logic_bomb` goes high.
   2. `latch_alert` is set to 1 on the next rising edge, and it stays high even if the inputs go away.
   3. `ALERT` is the OR of `logic_bomb` and `latch_alert`, so we can still see the original trigger plus the latched state.
 - asserting `hw_reset` clears `latch_alert`, effectively acknowledging the alarm; otherwise it keeps raising `ALERT` forever.
 
 ## shadow comparator and emergency stop
 - `shadow_plc` pipelines the alert through a 5-stage shift register before sending the last bit (`delay_shift[4]`) to `shadow_comparator`.
 - the idea is to match the pin output after a predictable propagation delay and compare it to `physical_output`.
 - `shadow_comparator` keeps the previous cycle's shadow output in `shadow_delayed` so we compare across one extra cycle to tolerate single-cycle skews.
 - `match` is true if either the current shadow output equals `physical_output` or the delayed version matches; otherwise we assert `emergency_stop`.
 - once `EMERGENCY_STOP` goes high, it never goes low until the next reset, since the comparator only ever sets the reg high but never drives it low except during reset.
 
 ## testbench walk-through
 - `tb_top` instantiates `top` and dumps signals into `tb_top.vcd` for waveform viewing.
 - `initial` block sets defaults, releases reset after 5 ns, and clears `hw_reset`.
 - a second `initial` block raises `sensors` to `0x03`, `physical_output` to `1`, and loads `plc_timer` with `0x01000000` after 20 ns.
 - `attack_time` records the current simulation time right before the emergency stop is expected, then `wait (EMERGENCY_STOP)` blocks until the comparator flips the flag.
 - once `EMERGENCY_STOP` fires, it checks whether the stop happened within 10 ns of the attack start; if not, the test fails with `$fatal`.
 - the `always #2.5 clk = ~clk;` line creates a 4 ns clock period to drive everything.
 
 ## waveform pointers and commands
 - compile and run:
   ```
   iverilog -o tb_top.vvp tb_top.v bus_monitor.v logic_auditor.v shadow_plc.v tb_top.v
   vvp tb_top.vvp
   ```
 - open `tb_top.vcd` in gtkwave:
   - look for `capture_active` to confirm the spi `STAR` sequence was seen.
   - inspect `ALERT` and `EMERGENCY_STOP`; they should assert shorty after `physical_output` rises.
 - use gtkwave's `signal->search` to find the shift register chain inside `shadow_plc` if you need to verify the delay.
 
 ## ascii signal map
 
 ```
      spi_sck
        |
   spi_mosi --> byte_val -> window -> capture_active
        |                             |
        +-----------------+           |
                          |           |
   sensors + plc_timer --> logic_auditor --> ALERT ----+
                                                      |
                                                  +---v---+
   ALERT --> delay_shift -> shadow_output --> shadow_comparator -> EMERGENCY_STOP
                                                      ^
                                    physical_output --+
 ```
 
 ## debugging notes
 - add `$monitor` calls in the testbench if you want live prints (gtkwave is still easier for multi-cycle timing).
 - to test resilience, wiggle `spi_ss_n` up and down; `bus_monitor` will reset its window and ignore stray bytes.
 - to explore threshold tuning, adjust `logic_auditor.THRESHOLD` and rerun the simulator; nothing else needs changing.
 - remember: `shadow_comparator` never resets `emergency_stop` unless `rst_n` pulses low, so if you want to reuse the module you must reset the top-level bench between shots.

creds lorush1
and cursor but only for the technical docs code is mostly mine (some ai help kay not a genius to write hdl by hand even tho most of it is so lowkey a genius hihihihi) yeah. 