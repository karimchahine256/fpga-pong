module vga_sync #(parameter H_VISIBLE = 640, H_FP = 16, H_SYNC = 96, H_BP = 48, parameter V_VISIBLE = 480, V_FP = 10, V_SYNC = 2,  V_BP = 33)
(input logic [9:0] hc, vc, output logic hsync, vsync, video_on);

always_comb begin
    hsync    = 1'b1;
    vsync    = 1'b1;
    video_on = 1'b0;

    if (hc >= H_VISIBLE + H_FP && hc < H_VISIBLE + H_FP + H_SYNC) begin
        hsync = 1'b0;
    end
    if (vc >= V_VISIBLE + V_FP && vc < V_VISIBLE + V_FP + V_SYNC) begin
        vsync = 1'b0;
    end
    if (hc < H_VISIBLE && vc < V_VISIBLE) begin
        video_on = 1'b1;
    end
end

endmodule
