`timescale 1ns/1ns

module nexys4_top_tb();

  logic CLK100MHZ, CPU_RESETN, BTNU, BTND, BTNL, BTNR;
  logic [2:0] SW;                    
  logic [3:0] VGA_R, VGA_G, VGA_B;
  logic VGA_HS, VGA_VS;


  nexys4_top n4 (.*);

  // 100 MHz clock (10 ns period)
  always begin
    #5
    CLK100MHZ = ~CLK100MHZ;
  end


  
  initial begin
    CLK100MHZ = 1'b0;
    SW = 3'b000;        // 2-player mode, easiest difficulty
    BTNU = 1'b0;
    BTND = 1'b0;
    BTNL = 1'b0;
    BTNR = 1'b0;
    CPU_RESETN = 1'b0;  // active-low, so 0 = in reset
    #50
    CPU_RESETN = 1'b1;

    // hsync pulse should be 3840 ns, one line (falling edge to falling edge) 32000 ns
    @(negedge VGA_HS) begin
      $display("Time falling edge HS: %0t ",$time);
    end
    @(posedge VGA_HS) begin
      $display("Time rising edge HS: %0t ",$time);
    end
    @(negedge VGA_HS) begin
      $display("Time second falling edge HS: %0t ", $time);
    end

    $finish;
  end
  


endmodule
