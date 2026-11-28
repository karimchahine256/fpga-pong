module nexys4_top (
    input  logic        CLK100MHZ,
    input  logic        CPU_RESETN,            // red reset button, active-low
    input  logic        BTNU, BTND, BTNL, BTNR,
    input  logic [2:0]  SW,                    // SW2 = mode, SW1-SW0 = difficulty
    output logic [3:0]  VGA_R, VGA_G, VGA_B,
    output logic        VGA_HS, VGA_VS
);

logic reset, fstart, fend, video_on;
logic [9:0] hc, vc;
logic [6:0] sync1, sync2;
logic [2:0] swPrev;
logic restart, game_reset;
logic locked, clk25;

// 25 MHz pixel clock from the 100 MHz board clock (Clocking Wizard IP)
clk_wiz_0 clkgen (.clk_in1(CLK100MHZ), .clk_out1(clk25), .locked(locked));

assign reset = ~CPU_RESETN | ~locked;           // hold reset until the clock is stable

// restart the game when a switch changes (mode or difficulty)
assign restart = (swPrev != sync2[2:0]);
assign game_reset = reset | restart;

always_ff @(posedge clk25) begin
  swPrev <= sync2[2:0];
end

// synchronize buttons and switches to the clock (two flip-flops each)
// bits: 6 = BTNU, 5 = BTND, 4 = BTNL, 3 = BTNR, 2 = SW2, 1 = SW1, 0 = SW0
always_ff @(posedge clk25) begin
  sync1 <= {BTNU, BTND, BTNL, BTNR, SW[2:0]};
  sync2 <= sync1;
end

frame_counter fc (.clk(clk25), .reset(reset), .cen(1'b1), .hc(hc), .vc(vc), .fstart(fstart), .fend(fend));

vga_sync vs (.hc(hc), .vc(vc), .hsync(VGA_HS), .vsync(VGA_VS), .video_on(video_on));

render r (.clk(clk25), .reset(game_reset),
          .p1_up(sync2[6]), .p1_down(sync2[5]), .p2_up(sync2[4]), .p2_down(sync2[3]),
          .mode(sync2[2]), .difficulty(sync2[1:0]),
          .fend(fend), .hc(hc), .vc(vc), .video_on(video_on),
          .R(VGA_R), .G(VGA_G), .B(VGA_B),
          .lost1(), .lost2());

endmodule
