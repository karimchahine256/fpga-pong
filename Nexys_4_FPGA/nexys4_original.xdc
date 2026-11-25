## Original Nexys 4 (not DDR) constraints for Pong
## Pins taken from Digilent's Nexys-4-Master.xdc (github.com/Digilent/digilent-xdc),
## renamed to match nexys4_top's ports.

## 100 MHz clock
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK100MHZ }];

## Red CPU_RESET button (active-low)
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { CPU_RESETN }];

## Switches: SW2 = mode, SW1-SW0 = difficulty
set_property -dict { PACKAGE_PIN U9  IOSTANDARD LVCMOS33 } [get_ports { SW[0] }];
set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS33 } [get_ports { SW[1] }];
set_property -dict { PACKAGE_PIN R7  IOSTANDARD LVCMOS33 } [get_ports { SW[2] }];

## Buttons: BTNU/BTND = player 1, BTNL/BTNR = player 2
set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS33 } [get_ports { BTNU }];
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports { BTND }];
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports { BTNL }];
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { BTNR }];

## VGA connector (4 bits per colour)
set_property -dict { PACKAGE_PIN A3  IOSTANDARD LVCMOS33 } [get_ports { VGA_R[0] }];
set_property -dict { PACKAGE_PIN B4  IOSTANDARD LVCMOS33 } [get_ports { VGA_R[1] }];
set_property -dict { PACKAGE_PIN C5  IOSTANDARD LVCMOS33 } [get_ports { VGA_R[2] }];
set_property -dict { PACKAGE_PIN A4  IOSTANDARD LVCMOS33 } [get_ports { VGA_R[3] }];
set_property -dict { PACKAGE_PIN C6  IOSTANDARD LVCMOS33 } [get_ports { VGA_G[0] }];
set_property -dict { PACKAGE_PIN A5  IOSTANDARD LVCMOS33 } [get_ports { VGA_G[1] }];
set_property -dict { PACKAGE_PIN B6  IOSTANDARD LVCMOS33 } [get_ports { VGA_G[2] }];
set_property -dict { PACKAGE_PIN A6  IOSTANDARD LVCMOS33 } [get_ports { VGA_G[3] }];
set_property -dict { PACKAGE_PIN B7  IOSTANDARD LVCMOS33 } [get_ports { VGA_B[0] }];
set_property -dict { PACKAGE_PIN C7  IOSTANDARD LVCMOS33 } [get_ports { VGA_B[1] }];
set_property -dict { PACKAGE_PIN D7  IOSTANDARD LVCMOS33 } [get_ports { VGA_B[2] }];
set_property -dict { PACKAGE_PIN D8  IOSTANDARD LVCMOS33 } [get_ports { VGA_B[3] }];
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports { VGA_HS }];
set_property -dict { PACKAGE_PIN B12 IOSTANDARD LVCMOS33 } [get_ports { VGA_VS }];
