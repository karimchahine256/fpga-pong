module frame_counter_tb();

logic clk, reset, cen, fstart, fend;
logic [9:0] hc, vc;
logic [1:0] cntr;

frame_counter #(.HMAX(4), .VMAX(3)) fc1 (.clk(clk), .reset(reset), .cen(cen), .hc(hc), .vc(vc), .fstart(fstart), .fend(fend));

initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    cen = 1'b0;
    cntr = 2'b00;
    clk = 1'b0;
    reset = 1'b1;
    #20
    reset = 1'b0;
    #2000
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
