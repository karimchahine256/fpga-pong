module vga_tb();

logic clk, reset, cen, fstart, fend;
logic hsync, vsync, video_on;
logic [9:0] hc, vc;
logic [1:0] cntr;

  frame_counter #(.HMAX(7), .VMAX(6)) fc (.clk(clk),.reset(reset),.cen(cen),.fstart(fstart),.fend(fend),.hc(hc),.vc(vc));
  vga_sync #(.H_VISIBLE(4), .H_FP(1), .H_SYNC(1), .H_BP(1),.V_VISIBLE(3), .V_FP(1), .V_SYNC(1), .V_BP(1)) vga (.hc(hc), .vc(vc),.hsync(hsync),.vsync(vsync),.video_on(video_on));

initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    cen = 1'b0;
    cntr = 2'b00;
    clk = 1'b0;
    reset = 1'b1;
    #20
    reset = 1'b0;
    #5000
    $finish;
end

always begin
    #5
    clk = !clk;
end

always @(posedge clk) begin
    if (cntr == 3) begin
        cntr <= cntr + 1'b1;
        cen <= 1'b1;
    end
    else begin
        cntr <= cntr + 1'b1;
        cen <= 1'b0;
    end
end

endmodule
