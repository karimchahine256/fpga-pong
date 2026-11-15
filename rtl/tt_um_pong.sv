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
