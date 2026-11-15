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
