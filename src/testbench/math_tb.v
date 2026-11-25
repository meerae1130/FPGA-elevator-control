`timescale 1ns/1ps

module math_tb;
    reg clock;
    reg start;
    reg reset;
    reg enter;
    reg signed [7:0] playerans;
    wire correct;
    wire failed;
    wire wrong;
    wire [1:0] failcount;
    wire [3:0] A;
    wire [3:0] B;
    wire [1:0] operator;

    math dut (
        .clock(clock),
        .start(start),
        .reset(reset),
        .playerans(playerans),
        .enter(enter),
        .A(A),
        .B(B),
        .operator(operator),
        .correct(correct),
        .failed(failed),
        .wrong(wrong),
        .failcount(failcount)
    );

    always #10 clock = ~clock;

    initial begin
        clock = 0;
        start = 0;
        reset = 0;
        enter = 0;
        playerans = 0;

        repeat (2) @(posedge clock);
        reset = 1;
        start = 1;
        @(posedge clock);
        start = 0;

        repeat (10) @(posedge clock);
        playerans = (operator == 2'd0) ? (A + B)
                    : (operator == 2'd1) ? (A - B)
                    : (A * B);
        enter = 1;
        @(posedge clock);
        enter = 0;

        repeat (2) @(posedge clock);
        $display("PASS: math smoke test completed (A=%0d B=%0d op=%0d)",
                 A, B, operator);
        $finish;
    end
endmodule
