module renderStatic (
    input  logic [9:0] hc, vc,
    input  logic video_on,
    output logic [3:0] R, G, B
);


  localparam PWIDTH  = 5;
  localparam PHEIGHT = 60;
  localparam BALL    = 10;
  localparam LINE_W  = 2;
  //assuming (0,0) is top left corner
  localparam LPAD_X = 50,  LPAD_Y = 430;
  localparam RPAD_X = 585, RPAD_Y = 170;
  localparam BALL_X = 400, BALL_Y = 95;
  localparam LINE_X = 310;

  logic L_Padel, R_Padel, Center_Line, Ball;

  assign L_Padel = (hc >= LPAD_X && hc < LPAD_X + PWIDTH) && (vc >= LPAD_Y && vc < LPAD_Y + PHEIGHT);
  assign R_Padel = (hc >= RPAD_X && hc < RPAD_X + PWIDTH) && (vc >= RPAD_Y && vc < RPAD_Y + PHEIGHT);
  assign Center_Line = vc[3] && (hc >= LINE_X && hc < LINE_X + LINE_W);
  assign Ball = (hc >= BALL_X && hc < BALL_X + BALL) && (vc >= BALL_Y && vc < BALL_Y + BALL);

  always_comb begin
    R = 4'b0000;
    G = 4'b0000;
    B = 4'b0000;

    if (video_on) begin
      if (L_Padel) begin
        R = 4'b1111;
        G = 4'b1111;
        B = 4'b1111;
      end
      if (R_Padel) begin
        R = 4'b1111;
        G = 4'b1111;
        B = 4'b1111;
      end
      if (Center_Line) begin
        R = 4'b1111;
        G = 4'b1111;
        B = 4'b1111;
      end
      if (Ball) begin
        R = 4'b1111;
        G = 4'b1111;
        B = 4'b1111;
      end
    end
  end

endmodule
