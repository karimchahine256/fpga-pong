module render (
    input  logic clk, reset, fend, mode,
    input  logic [1:0] difficulty, 
    input  logic p1_up, p1_down, p2_up, p2_down,
    input  logic [9:0] hc, vc,
    input  logic video_on,
    output logic [3:0] R, G, B,
    output logic lost1, lost2
);

  logic [6:0] disp1,disp2;
  logic [2:0] score1,score2;
  logic gameOver;

  sevenSegment scoreViewer(.*);

  logic score1_on, score2_on;

  digit #(.X0(265), .Y0(20)) d1 (.hc(hc), .vc(vc), .disp(disp1), .on(score1_on));
  digit #(.X0(335), .Y0(20)) d2 (.hc(hc), .vc(vc), .disp(disp2), .on(score2_on));

  localparam PWIDTH  = 5;
  localparam PHEIGHT = 60;
  localparam BALL    = 10;
  localparam LINE_W  = 2;
  //assuming (0,0) is top left corner
  localparam LPAD_X = 50;
  localparam RPAD_X = 585;
  localparam LINE_X = 310;
  localparam MPF    = 6;   // Paddle movemenet per frame
  localparam BALLSPEED = 4;


  logic [9:0] Lpad_Y, Rpad_Y, Ball_X, Ball_Y;
  logic dirX, dirY;       // 1 is right/down, 0 is left/up
  logic nextDirX, nextDirY;

  logic [3:0] hitCount;   // paddle hits this rally (stops at 15)
  logic [2:0] SpeedUp;    // extra px/frame added to the ball speed
  logic paddleHit;        // 1 on the frame the ball actually bounces off a paddle

  // current speeds as 10-bit values since VGA Playground requires it, these should get trimmed during synthesis 
  logic [9:0] spd, padSpd;
  assign spd = BALLSPEED + {7'b0, SpeedUp};    
  assign padSpd = MPF + {7'b0, SpeedUp>>1};       // player paddles: + half the speed-up

  logic L_Padel, R_Padel, Center_Line, Ball,L_Edge,R_Edge,Top_Edge,Bottom_Edge;
  logic hitRoof, hitFloor, hitLpad, hitRpad;

  assign L_Padel = (hc >= LPAD_X && hc < LPAD_X + PWIDTH) && (vc >= Lpad_Y && vc < Lpad_Y + PHEIGHT);
  assign R_Padel = (hc >= RPAD_X && hc < RPAD_X + PWIDTH) && (vc >= Rpad_Y && vc < Rpad_Y + PHEIGHT);
  assign Center_Line = vc[3] && (hc >= LINE_X && hc < LINE_X + LINE_W);
  assign Ball = (hc >= Ball_X && hc < Ball_X + BALL) && (vc >= Ball_Y && vc < Ball_Y + BALL);
  assign L_Edge = (hc==0) && (vc<480);
  assign R_Edge = (hc==639) && (vc<480);
  assign Top_Edge = (hc<640) && (vc==0);
  assign Bottom_Edge = (hc<640) && (vc==479);

  // walls: turn if the next step would cross the edge (one step of margin is enough now)
  assign hitRoof  = (Ball_Y < spd);
  assign hitFloor = (Ball_Y + BALL > 480 - spd);
  assign hitLpad  = (Ball_X <= LPAD_X + PWIDTH && Ball_X >= LPAD_X - spd && Ball_Y + BALL >= Lpad_Y && Ball_Y <= Lpad_Y + PHEIGHT);
  assign hitRpad  = (Ball_X + BALL <= RPAD_X + PWIDTH + spd && Ball_X + BALL >= RPAD_X && Ball_Y + BALL >= Rpad_Y && Ball_Y <= Rpad_Y + PHEIGHT);

  // direction for THIS frame's move: bounce happens on the same frame as the hit
  assign nextDirX = hitLpad ? 1'b1 : hitRpad  ? 1'b0 : dirX;
  assign nextDirY = hitRoof ? 1'b1 : hitFloor ? 1'b0 : dirY;

  // only a loss if the ball is still heading toward that side (not bouncing off a paddle)
  assign lost1 = (Ball_X <= spd) && !nextDirX;
  assign lost2 = (Ball_X + BALL >= 639 - spd) && nextDirX;

  // count a hit only when the ball was moving TOWARD that paddle,
  // so a ball that is still in the hit window next frame isn't counted twice
  assign paddleHit = (hitLpad && !dirX) || (hitRpad && dirX);
  assign SpeedUp = (hitCount > 4'd10) ? 3'd4 : (hitCount > 4'd6) ? 3'd2 : (hitCount > 4'd3) ? 3'd1 : 3'd0;

  // computer paddle
  localparam DEAD = 4;       // dead zone: don't move if within 4 pixels of the ball

  logic [9:0] padC, ballC, distance, step, padUp, padDown;
  logic ballAbove, ballBelow;
  logic [2:0] mpf_com;

  assign padC  = Rpad_Y + PHEIGHT/2;    // paddle centre
  assign ballC = Ball_Y + BALL/2;       // ball centre

  assign ballAbove = (ballC + DEAD < padC);
  assign ballBelow = (ballC > padC + DEAD);

  // distance to the ball (always positive) and how far to move this frame
  assign distance = ballAbove ? padC - ballC : ballC - padC;
  // computer speed = difficulty speed + half the rally speed-up (10 bits so the sum can't overflow)
  logic [9:0] comSpd;
  assign comSpd = {7'b0, mpf_com} + {7'b0, SpeedUp >> 1};
  assign step = (distance < comSpd) ? distance : comSpd;   // never overshoot

  // next position when moving up / down, clamped to the screen
  assign padUp   = (Rpad_Y < step) ? 0 : Rpad_Y - step;
  assign padDown = (Rpad_Y + step > 480 - PHEIGHT) ? 480 - PHEIGHT : Rpad_Y + step;

  assign gameOver = (score1 == 3'd5 || score2 == 3'd5);

  // computer paddle speed for each difficulty
  always_comb begin
    case (difficulty)
      2'b00:   mpf_com = (BALLSPEED/2) + 1;
      2'b01:   mpf_com = BALLSPEED;
      2'b10:   mpf_com = BALLSPEED + 1;
      default: mpf_com = BALLSPEED + 2;
    endcase
  end

  // return speed: half of mpf_com
  logic [2:0] ret;
  assign ret = (mpf_com) >> 1;
  

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
      if(score1_on || score2_on) begin
        R = 4'b1111;
        G = 4'b1111;
        B = 4'b1111;
      end
      if(L_Edge || R_Edge || Top_Edge || Bottom_Edge) begin
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
      hitCount <= 4'd0;
      score1 <= 3'b0;
      score2 <= 3'b0;
    end
    else if (fend) begin
      if(~gameOver) begin
        if (lost1 || lost2) begin
          // re-serve from the center (same serve directions as before)
          Ball_X <= (640 - BALL) / 2;
          Ball_Y <= (480 - BALL) / 2;
          dirX   <= lost1;   // lost1 -> serve right, lost2 -> serve left
          hitCount <= 4'd0;  // new rally -> back to normal speed
        end
        else begin
          Ball_X <= nextDirX ? Ball_X + spd : Ball_X - spd;
          Ball_Y <= nextDirY ? Ball_Y + spd : Ball_Y - spd;
          dirX   <= nextDirX;
          dirY   <= nextDirY;
          if (paddleHit && hitCount != 4'd15)
          hitCount <= hitCount + 4'd1;
        end
      end
      //Paddle 1 control
      if (p1_up && p1_down) begin
        Lpad_Y <= Lpad_Y;
      end
      else if (p1_up) begin
        Lpad_Y <= (Lpad_Y < padSpd) ? 0 : Lpad_Y - padSpd;
      end
      else if (p1_down) begin
        Lpad_Y <= (Lpad_Y + PHEIGHT > 480 - padSpd) ? 480 - PHEIGHT : Lpad_Y + padSpd;
      end

      //Paddle 2 control, mode == 0 => Player Controlled paddle, mode == 1 => Computer Controlled Paddle
      if(mode == 1'b0) begin
      if (p2_up && p2_down) begin
        Rpad_Y <= Rpad_Y;
      end
      else if (p2_up) begin
        Rpad_Y <= (Rpad_Y < padSpd) ? 0 : Rpad_Y - padSpd;
      end
      else if (p2_down) begin
        Rpad_Y <= (Rpad_Y + PHEIGHT > 480 - padSpd) ? 480 - PHEIGHT : Rpad_Y + padSpd;
      end
      end
        else begin
        if (dirX == 1'b0) begin
          if (Rpad_Y > 240)
            Rpad_Y <= Rpad_Y - {7'b0, ret};
          else if (Rpad_Y + PHEIGHT < 240)
            Rpad_Y <= Rpad_Y + {7'b0, ret};
        end
        else begin
          if (ballAbove)
            Rpad_Y <= padUp;
          else if (ballBelow)
            Rpad_Y <= padDown;
        end
      end
      if(lost1) begin
        score2 <= score2+1'b1;
      end
      else if (lost2) begin
        score1 <= score1+1'b1;
      end
    end
  end

endmodule
