module sevenSegment (
    input  logic [2:0] score1,score2,
    output logic [6:0] disp1,disp2
);

    always_comb begin
        case (score1)
            3'h0:    disp1 = 7'b1111110;
            3'h1:    disp1 = 7'b0110000;
            3'h2:    disp1 = 7'b1101101;
            3'h3:    disp1 = 7'b1111001;
            3'h4:    disp1 = 7'b0110011;
            3'h5:    disp1 = 7'b1011011;
            3'h6:    disp1 = 7'b1011111;
            3'h7:    disp1 = 7'b1110000;
        endcase
        case (score2)   // normal digits, except 1 is drawn on the left (e/f) so it sits next to the centre line
            3'h0:    disp2 = 7'b1111110;
            3'h1:    disp2 = 7'b0000110;
            3'h2:    disp2 = 7'b1101101;
            3'h3:    disp2 = 7'b1111001;
            3'h4:    disp2 = 7'b0110011;
            3'h5:    disp2 = 7'b1011011;
            3'h6:    disp2 = 7'b1011111;
            3'h7:    disp2 = 7'b1110000;
        endcase
    end

endmodule
