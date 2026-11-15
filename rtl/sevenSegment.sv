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
        case (score2)   // mirrored: b/c drawn on the left, e/f on the right
            3'h0:    disp2 = 7'b1111110;
            3'h1:    disp2 = 7'b0000110;
            3'h2:    disp2 = 7'b1011011;
            3'h3:    disp2 = 7'b1001111;
            3'h4:    disp2 = 7'b0100111;
            3'h5:    disp2 = 7'b1101101;
            3'h6:    disp2 = 7'b1111101;
            3'h7:    disp2 = 7'b1000110;
        endcase
    end

endmodule
