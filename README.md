 # beebee auditor

 used to be a github repo from my old github account, brought it over to here cuz its actually a good project.. why were all my good projects priv public ones actual garbage.
 
 a small verilog sketch that pretends to keep an eye on a plc-style system while a testbench bangs on it.
 we focused on eating hints from sensor bits, a shadow copy of the output, and a little spi snooper.

 you can treat it as a toy that checks whether an alert would fire when the logic timer and sensors trip together.
 the spi watcher looks for the letters "star" coming across the wires before it says "ok, capture is on".

 the logic auditor waits until two sensor bits and a giant timer combine into a logic bomb, then latches an alert.
 the shadow controller delays the alert by a few cycles, compares it back to the physical output, and keeps an emergency stop flag if things diverge.

 down below there is a simple testbench that flicks the signals around, waits for the emergency stop to trigger, and writes a vcd.
 
 ## why this exists
 - to practice wiring a few verilog modules together without pretending we are running a real plant.
 - to learn how to trace spi bytes, timer checks, and safety hooks at the same time.
 - to stay honest and remind ourselves that the rtl should not wreck anything that is not under our control.
 
 ## what you can do today
 - run the verilator/iverilog line in the commands section to build a simulation.
 - watch the waveform with gtkwave so you can see the alert, capture, and emergency stop dance around.
 - tweak sensors or the threshold if you want to explore how fast the warning lights flash.
 
 ## commands
 - iverilog -o tb_top.vvp tb_top.v bus_monitor.v logic_auditor.v shadow_plc.v tb_top.v
 - vvp tb_top.vvp
 - gtkwave tb_top.vcd
 - (optionally) open the vcd in your favorite viewer and scroll around the capture_active line to understand when the spi start message arrives.
 
 ## safety & ethics
 - this repo is not a finished safety product; it is a learning toy that attempts to highlight what a lodged alert might look like.
 - do not ship this to a real controller without generous peer review and a proper safety lifecycle; the logic here is intentionally simple and could miss edge cases.
 - keep your simulation inputs clean, treat the sensors as imaginary troublemakers, and document every assumption before sharing results.
 
 ## ascii of who this project was named after ⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⣧⠷⠆⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣐⣢⣤⢖⠒⠪⣭⣶⣿⣦⠀⠀⠀⠀⠀⠀⠀
⠀⢸⣿⣿⣿⣌⠀⢀⣿⠁⢹⣿⡇⠀⠀⠀⠀⠀⠀
⠀⢸⣿⣿⣿⣿⣿⡿⠿⢖⡪⠅⢂⠀⠀⠀⠀⠀⠀
⠀⠀⢀⣔⣒⣒⣂⣈⣉⣄⠀⠺⣿⠿⣦⡀⠀⠀⠀
⠀⡴⠛⣉⣀⡈⠙⠻⣿⣿⣷⣦⣄⠀⠛⠻⠦⠀⠀
⡸⠁⢾⣿⣿⣁⣤⡀⠹⣿⣿⣿⣿⣿⣷⣶⣶⣤⠀
⡇⣷⣿⣿⣿⣿⣿⡇⠀⣿⣿⣿⣿⣿⣿⡿⠿⣿⡀
⡇⢿⣿⣿⣿⣟⠛⠃⠀⣿⣿⣿⡿⠋⠁⣀⣀⡀⠃
⢻⡌⠀⠿⠿⠿⠃⠀⣼⣿⣿⠟⠀⣠⣄⣿⣿⡣⠀
⠈⢿⣶⣤⣤⣤⣴⣾⣿⣿⡏⠀⣼⣿⣿⣿⡿⠁⠀
⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⠀⠀⣩⣿⡿⠋⠀⠀⠀
⠀⠀⠀⠀⠈⠙⠛⠿⠿⠿⠇⠀⠉⠁⠀⠀⠀⠀⠀

not my ascii btw its from [beebe ascii art :>](https://emojicombos.com/BB--8-ascii-art)

creds: lorush1

 

