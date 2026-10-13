module frame_counter #(parameter HMAX = 800, VMAX = 525)
(input logic clk, logic reset, logic cen, output logic [9:0] hc, logic [9:0] vc, logic fstart, logic fend);

assign fstart = (hc == 10'b0 && vc == 10'b0) && cen;
assign fend = (hc == HMAX-1) && (vc == VMAX-1) && cen;

always_ff @(posedge clk) begin
    if (reset) begin
        hc <= 10'b0;
        vc <= 10'b0;
    end
    else begin
        if (cen) begin
            if (hc == HMAX-1) begin
                if (vc == VMAX-1) begin
                    vc <= 10'b0;
                    hc <= 10'b0;
                end
                else begin
                    vc <= vc + 1'b1;
                    hc <= 10'b0;
                end
            end
            else begin
                hc <= hc + 1'b1;
            end
        end
    end
end

endmodule
