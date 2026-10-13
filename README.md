## fpga-pong

My attempt at building Pong in SystemVerilog, with VGA output (640x480 @ 60Hz). I'm doing this to actually learn RTL design instead of just reading about it, so the code is written by me and the commit history shows the mistakes along the way.

Up until this point I am verifying everything through simulations until I can get access to a board to test on.

## Completed modules

- `frame_counter`: counts `hc` (0-799) and `vc` (0-524) across the whole frame, including the blanking area. Advances on a pixel tick `cen` instead of a divided clock. Also outputs `fstart` and `fend`, one-cycle pulses at the first and last pixel of each frame. The game logic will use these later to update once per frame.

- `vga_sync`: takes hc/vc and generates `hsync`, `vsync` and `video_on`. Timing values are parameters, so I can test with a tiny 7x6 "screen" instead of scrolling through 420,000 cycles.

Both are tested in EDA Playground. Waveforms are in docs/.


## Layout

`rtl/` design files

`tb/` testbenches

`docs/` waveforms and notes


## Things I got wrong 

- Originally had `fend` as a level, not a pulse. With `cen` high only 1 in 4 clocks, it stayed high for 4 cycles, which would make the game update 4 times per frame. Fixed by ANDing with cen.

- Made `hsync` low for the whole blanking period instead of just the sync pulse.



## Next

- []draw paddles + ball (static)

- [] dump a frame to an image file so I can see it without a monitor 

- [] paddle movement

- [] ball physics / collisions

- [] scoring + game states

- [] get it on real hardware


