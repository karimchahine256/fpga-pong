module nexys4_top (
    input  logic        CLK100MHZ,
    input  logic        CPU_RESETN,            
    input  logic        BTNU, BTND, BTNL, BTNR,
    input  logic [2:0]  SW,                    
    output logic [3:0]  VGA_R, VGA_G, VGA_B,
    output logic        VGA_HS, VGA_VS
);

logic reset, fstart, fend, video_on, cen;
logic [1:0] counter;
logic [9:0] hc, vc;
logic [6:0] sync1, sync2;
logic [2:0] swPrev;
logic restart, game_reset;

assign reset = ~CPU_RESETN;
    
assign restart = (swPrev != sync2 [2:0]);
    
assign game_reset = reset | restart;    
    
always_ff @(posedge CLK100MHZ) begin
    swPrev <= sync2 [2:0];
end
        
    
// pixel tick: cen high 1 clock in 4 -> 25 MHz
always_ff @(posedge CLK100MHZ) begin
  if (reset) begin
    counter <= 2'b00;
    cen     <= 1'b0;
  end
  else begin
    if (counter == 2'b11) begin
      cen <= 1'b1;
    end
    else begin
      cen <= 1'b0;
    end
    counter <= counter + 2'b01;
  end
end

// synchronize buttons and switches to the clock (two flip-flops each)
// bits: 6 = BTNU, 5 = BTND, 4 = BTNL, 3 = BTNR, 2 = SW2, 1 = SW1, 0 = SW0
always_ff @(posedge CLK100MHZ) begin
  sync1 <= {BTNU, BTND, BTNL, BTNR, SW[2:0]};
  sync2 <= sync1;
end

frame_counter fc (.clk(CLK100MHZ), .reset(reset), .cen(cen), .hc(hc), .vc(vc), .fstart(fstart), .fend(fend));

vga_sync vs (.hc(hc), .vc(vc), .hsync(VGA_HS), .vsync(VGA_VS), .video_on(video_on));

render r (.clk(CLK100MHZ), .reset(game_reset),
          .p1_up(sync2[6]), .p1_down(sync2[5]), .p2_up(sync2[4]), .p2_down(sync2[3]),
          .mode(sync2[2]), .difficulty(sync2[1:0]),
          .fend(fend), .hc(hc), .vc(vc), .video_on(video_on),
          .R(VGA_R), .G(VGA_G), .B(VGA_B),
          .lost1(), .lost2());

endmodule
