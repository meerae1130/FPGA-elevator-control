// 640 x 480 VGA timing at a 25 MHz pixel clock derived from CLOCK_50
// basically tells me where the current cursor/pixel is 
module vga_timing (
    input clock, reset,
    output reg VGA_CLK,
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N,
    output reg [9:0] x, y
);
    always @(posedge clock) begin
        if (!reset) begin
            VGA_CLK <= 1'b0;
            x <= 10'd0;
            y <= 10'd0;
        end else begin
            VGA_CLK <= ~VGA_CLK;
            // Change pixel data on the falling edge of VGA_CLK.
            if (VGA_CLK) begin
                if (x == 10'd799) begin
                    x <= 10'd0;
                    if (y == 10'd524)
                        y <= 10'd0;
                    else
                        y <= y + 10'd1;
                end else begin
                    x <= x + 10'd1;
                end
            end
        end
    end

    assign VGA_HS = !(x >= 10'd656 && x < 10'd752);
    assign VGA_VS = !(y >= 10'd490 && y < 10'd492);
    assign VGA_BLANK_N = x < 10'd640 && y < 10'd480;
    assign VGA_SYNC_N = 1'b0;
endmodule
