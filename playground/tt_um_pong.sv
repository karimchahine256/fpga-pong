module tt_um_pong(
    input logic [7:0] ui_in, uio_in,
    input logic clk, rst_n,ena,
    output logic [7:0] uio_out, uo_out, uio_oe
);

logic reset, cen, fstart, fend;
logic p1_up, p1_down, p2_up, p2_down;
logic [9:0] hc, vc;
logic video_on;
logic [3:0] R, G, B;
logic lost1, lost2;
logic hsync, vsync;
logic mode;               // 0 = two players, 1 = vs computer
logic [1:0] difficulty;   // 0 = easy ... 3 = hard
logic restart;            // 1 for one clock after the difficulty changes
logic game_reset;         // resets the game (paddles + ball) but not the video timing

// Gamepad Pmod on ui_in[6:4]
wire inp_present;
wire inp_b, inp_y, inp_select, inp_start, inp_up, inp_down, inp_left, inp_right, inp_a, inp_x, inp_l, inp_r;

gamepad_pmod_single driver (
    // Inputs:
    .rst_n(rst_n),
    .clk(clk),
    .pmod_data(ui_in[6]),
    .pmod_clk(ui_in[5]),
    .pmod_latch(ui_in[4]),
    // Outputs:
    .b(inp_b),
    .y(inp_y),
    .select(inp_select),
    .start(inp_start),
    .up(inp_up),
    .down(inp_down),
    .left(inp_left),
    .right(inp_right),
    .a(inp_a),
    .x(inp_x),
    .l(inp_l),
    .r(inp_r),
    .is_present(inp_present)
);

frame_counter f (.*);
vga_sync v (.*);
render r (.reset(game_reset), .*);   // render gets its own reset (see below)
assign reset = ~rst_n;
assign game_reset = reset | restart;
assign cen = 1'b1;
// Player 1: gamepad Up/Down or ui_in[0]/[1]; Player 2: gamepad X/B or ui_in[2]/[3]
assign p1_up   = inp_up   | ui_in[1];
assign p1_down = inp_down | ui_in[0];
assign p2_up   = inp_x    | ui_in[3];
assign p2_down = inp_b    | ui_in[2];
// Mode and difficulty, changed with button presses (checked once per frame):
//   Select (S key) or button 7: toggle 1-player / 2-player
//   Start  (T key):             cycle difficulty 0 -> 1 -> 2 -> 3 -> 0
logic sel_prev, start_prev, b7_prev;

always_ff @(posedge clk) begin
    if (reset) begin
        mode       <= 1'b0;
        difficulty <= 2'd1;
        sel_prev   <= 1'b0;
        start_prev <= 1'b0;
        b7_prev    <= 1'b0;
        restart    <= 1'b0;
    end
    else if (fend) begin
        sel_prev   <= inp_select;
        start_prev <= inp_start;
        b7_prev    <= ui_in[7];
        // Select pressed (rising edge) or button 7 toggled (any change)
        if ((inp_select && !sel_prev) || (ui_in[7] != b7_prev))
            mode <= ~mode;
        // Start pressed (rising edge)
        if (inp_start && !start_prev) begin
            difficulty <= difficulty + 2'd1;
            restart    <= 1'b1;   // new difficulty -> restart the game
        end
    end
    else begin
        restart <= 1'b0;          // only high for the one clock after fend
    end
end
assign uo_out = {hsync, B[2], G[2], R[2], vsync, B[3], G[3], R[3]};
assign uio_out = 0;
assign uio_oe = 0;


wire _unused = &{uio_in, ena, fstart, lost1, lost2,
                    R[1:0], G[1:0], B[1:0],
                    inp_y, inp_left, inp_right, inp_a, inp_l, inp_r, inp_present, 1'b0};

endmodule


module frame_counter #(parameter HMAX = 800, VMAX = 525)
(input logic clk, input logic reset, input logic cen, output logic [9:0] hc, output logic [9:0] vc, output logic fstart, output logic fend);

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


/* verilator lint_off UNUSED */  // H_BP / V_BP only document the timing
module vga_sync #(
    parameter H_VISIBLE = 640, H_FP = 16, H_SYNC = 96, H_BP = 48,
    parameter V_VISIBLE = 480, V_FP = 10, V_SYNC = 2,  V_BP = 33
)
(input logic [9:0] hc, vc, output logic hsync, vsync, video_on);
/* verilator lint_on UNUSED */

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


module digit #(parameter X0 = 0, Y0 = 0) (
    input  logic [9:0] hc, vc,
    input  logic [6:0] disp,     
    output logic on             
);

    localparam W = 20;   // digit width
    localparam H = 40;   // digit height
    localparam T = 4;    // bar thickness

logic a, b, c, d, e, f, g;


    assign a = (hc >= X0 && hc < X0 + W) && (vc >= Y0 && vc < Y0 + T);  
    assign b = (hc >= X0 + W - T && hc < X0 + W) && (vc >= Y0 && vc< Y0 + H/2); 
    assign c = (hc >= X0 + W - T && hc < X0 + W) && (vc >= Y0 + H/2 && vc< Y0 + H); 
    assign d = (hc >= X0 && hc < X0 + W) && (vc >= Y0 + H - T && vc < Y0 + H);
    assign e = (hc >= X0 && hc < X0 + T) && (vc >= Y0 + H/2 && vc< Y0 + H);
    assign f = (hc >= X0 && hc < X0 + T) && (vc >= Y0 && vc< Y0 + H/2); 
    assign g = (hc >= X0 && hc < X0 + W) && (vc >= Y0 + H/2 - T/2 && vc < Y0 + H/2 + T/2);  
    assign on = (a&disp[6] | b&disp[5] | c&disp[4] | d&disp[3] | e&disp[2] | f&disp[1] | g&disp[0]);


endmodule

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
