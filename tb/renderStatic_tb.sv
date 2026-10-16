module renderStatic_tb();

logic clk, reset, fstart, fend;
logic cen = 1'b1;
logic hsync, vsync, video_on;
logic [9:0] hc, vc;
logic [3:0] R, G, B;
integer file;

  frame_counter fc (.*);
  vga_sync vga (.*);
  renderStatic rs (.*);
  initial begin

    file = $fopen("test.ppm", "w");
    clk =1'b0;
    reset = 1'b1;
    $fwrite(file, "P3\n640 480\n15\n");
    #30
    reset = 1'b0;
  end

  always begin
    #5
    clk = !clk;
  end

  always @(posedge clk) begin
    if(fend) begin
      $fclose(file);
      $finish;
    end

    else begin
      if(video_on&&!reset) begin
        $fwrite(file, "%0d %0d %0d\n", R, G, B);
      end

    end
  end


endmodule
