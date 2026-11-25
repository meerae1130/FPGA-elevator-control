`timescale 1ns/1ps

module vga_tb;
    reg clock;
    reg reset;
    reg [2:0] gamestate;
    reg [2:0] playerfloor;
    reg [2:0] guardfloor;
    reg [2:0] moneyfloor;
    reg [2:0] targetfloor;
    reg [2:0] currentfloor1;
    reg [2:0] currentfloor2;
    reg busy1;
    reg busy2;
    reg riding1;
    reg riding2;
    reg [3:0] npcRiders1;
    reg [3:0] npcRiders2;
    reg [31:0] waitingCounts;
    reg [3:0] A;
    reg [3:0] B;
    reg [1:0] operator;

    wire [2:0] VGA_R;
    wire [2:0] VGA_G;
    wire [2:0] VGA_B;
    wire VGA_CLK;
    wire VGA_HS;
    wire VGA_VS;
    wire VGA_BLANK_N;
    wire VGA_SYNC_N;

    vga_display dut (
        .clock(clock),
        .reset(reset),
        .gamestate(gamestate),
        .playerfloor(playerfloor),
        .guardfloor(guardfloor),
        .moneyfloor(moneyfloor),
        .targetfloor(targetfloor),
        .currentfloor1(currentfloor1),
        .currentfloor2(currentfloor2),
        .busy1(busy1),
        .busy2(busy2),
        .riding1(riding1),
        .riding2(riding2),
        .npcRiders1(npcRiders1),
        .npcRiders2(npcRiders2),
        .waitingCounts(waitingCounts),
        .A(A),
        .B(B),
        .operator(operator),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_CLK(VGA_CLK),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N)
    );

    always #10 clock = ~clock;

    initial begin
        clock = 0;
        reset = 0;
        gamestate = 3'd2;
        playerfloor = 3'd1;
        guardfloor = 3'd6;
        moneyfloor = 3'd4;
        targetfloor = 3'd5;
        currentfloor1 = 3'd2;
        currentfloor2 = 3'd5;
        busy1 = 1'b1;
        busy2 = 1'b0;
        riding1 = 1'b1;
        riding2 = 1'b0;
        npcRiders1 = 4'd3;
        npcRiders2 = 4'd1;
        waitingCounts = 32'h0001_0204;
        A = 4'd7;
        B = 4'd3;
        operator = 2'd0;

        repeat (4) @(posedge clock);
        reset = 1;

        repeat (10000) @(posedge clock);

        if (^VGA_R === 1'bx || ^VGA_G === 1'bx || ^VGA_B === 1'bx)
            $display("FAIL: VGA color outputs contain unknown values");
        else
            $display("PASS: VGA display test completed");

        $finish;
    end
endmodule
