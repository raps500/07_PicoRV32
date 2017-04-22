Pico RISCV32 for the DE10-Lite (MAX10 based)

- CPU @ 64 MHz, according to the summary report it should go up to 105 MHz
- UART: Pin 4 is TX (Output), Pin 6 is RX (Input)
- 2 Resettable Timers
- Minimal GPIO
- 64 k RAM with bootloader (serial loading)
- KEY0 acts as reset button.




SignalTap is active in the project, you may have to disable it, just remove all
referencies to it from prv32_top.qsf. Internal RAM reduced to 64 kbytes because
SignalTap needs some RAM too. Reconfigure iram.qip to 128 k.

The UART is configured for 1 MBit. Intel Hex downloading seems to work well, I 
tried with the simple user_app that is in the firmware directory.

ToDo in no particular order:

A next step would be to get that DMA Audio bit working.
SDRAM, the board has 64 MBytes of it, I want it working !
VGA Output in text of graphical form.
A better bootloader, with write-protection to survive ill-behaving code. 