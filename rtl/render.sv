module render (
    input  logic clk, reset, fend,
    input  logic p1_up, p1_down, p2_up, p2_down,
    input  logic [9:0] hc, vc,
    input  logic video_on,
    output logic [3:0] R, G, B,
    output logic lost1, lost2
);

  localparam PWIDTH  = 5;
  localparam PHEIGHT = 60;
  localparam BALL    = 10;
  localparam LINE_W  = 2;
  //assuming (0,0) is top left corner
  localparam LPAD_X = 50;
  localparam RPAD_X = 585;
  localparam LINE_X = 310;
  localparam MPF    = 5;   // Paddle movemenet per frame
  localparam BALLSPEED = 3;

  logic [9:0] Lpad_Y, Rpad_Y, Ball_X, Ball_Y;
  logic dirX, dirY;       // 1 is right/down, 0 is left/up
  logic nextDirX, nextDirY;

  logic L_Padel, R_Padel, Center_Line, Ball;
  logic hitRoof, hitFloor, hitLpad, hitRpad;

  assign L_Padel = (hc >= LPAD_X && hc < LPAD_X + PWIDTH) && (vc >= Lpad_Y && vc < Lpad_Y + PHEIGHT);
  assign R_Padel = (hc >= RPAD_X && hc < RPAD_X + PWIDTH) && (vc >= Rpad_Y && vc < Rpad_Y + PHEIGHT);
  assign Center_Line = vc[3] && (hc >= LINE_X && hc < LINE_X + LINE_W);
  assign Ball = (hc >= Ball_X && hc < Ball_X + BALL) && (vc >= Ball_Y && vc < Ball_Y + BALL);

  // walls: turn if the next step would cross the edge (one step of margin is enough now)
  assign hitRoof  = (Ball_Y < BALLSPEED);
  assign hitFloor = (Ball_Y + BALL > 480 - BALLSPEED);
  assign hitLpad  = (Ball_X <= LPAD_X + PWIDTH && Ball_X >= LPAD_X - BALLSPEED && Ball_Y + BALL >= Lpad_Y && Ball_Y <= Lpad_Y + PHEIGHT);
  assign hitRpad  = (Ball_X + BALL <= RPAD_X + PWIDTH + BALLSPEED && Ball_X + BALL >= RPAD_X && Ball_Y + BALL >= Rpad_Y && Ball_Y <= Rpad_Y + PHEIGHT);

  // direction for THIS frame's move: bounce happens on the same frame as the hit
  assign nextDirX = hitLpad ? 1'b1 : hitRpad  ? 1'b0 : dirX;
  assign nextDirY = hitRoof ? 1'b1 : hitFloor ? 1'b0 : dirY;

  // only a loss if the ball is still heading toward that side (not bouncing off a paddle)
  assign lost1    = (Ball_X <= BALLSPEED) && !nextDirX;
  assign lost2    = (Ball_X + BALL >= 639 - BALLSPEED) && nextDirX;

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

  always_ff @(posedge clk) begin

    if (reset) begin
      Lpad_Y <= (480 - PHEIGHT) / 2;
      Rpad_Y <= (480 - PHEIGHT) / 2;
      Ball_X <= (640 - BALL) / 2;
      Ball_Y <= (480 - BALL) / 2;
      dirX   <= 1'b1;
      dirY   <= 1'b1;
    end
    else if (fend) begin
      if (lost1 || lost2) begin
        // re-serve from the center (same serve directions as before)
        Ball_X <= (640 - BALL) / 2;
        Ball_Y <= (480 - BALL) / 2;
        dirX   <= lost1;   // lost1 -> serve right, lost2 -> serve left
      end
      else begin
        Ball_X <= nextDirX ? Ball_X + BALLSPEED : Ball_X - BALLSPEED;
        Ball_Y <= nextDirY ? Ball_Y + BALLSPEED : Ball_Y - BALLSPEED;
        dirX   <= nextDirX;
        dirY   <= nextDirY;
      end

      //Paddle 1 control
      if (p1_up && p1_down) begin
        Lpad_Y <= Lpad_Y;
      end
      else if (p1_up) begin
        Lpad_Y <= (Lpad_Y < MPF) ? 0 : Lpad_Y - MPF;
      end
      else if (p1_down) begin
        Lpad_Y <= (Lpad_Y + PHEIGHT > 480 - MPF) ? 480 - PHEIGHT : Lpad_Y + MPF;
      end

      //Paddle 2 control
      if (p2_up && p2_down) begin
        Rpad_Y <= Rpad_Y;
      end
      else if (p2_up) begin
        Rpad_Y <= (Rpad_Y < MPF) ? 0 : Rpad_Y - MPF;
      end
      else if (p2_down) begin
        Rpad_Y <= (Rpad_Y + PHEIGHT > 480 - MPF) ? 480 - PHEIGHT : Rpad_Y + MPF;
      end

    end
  end

endmodule
