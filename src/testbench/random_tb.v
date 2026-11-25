`timescale 1ns/1ps

module random_tb;
    reg clock;
    reg reset;
    wire [3:0] outputnum;
    wire [5:0] lfsr_bits;

    random dut (
        .clock(clock),
        .reset(reset),
        .outputnum(outputnum),
        .lfsr_bits(lfsr_bits)
    );

    always #10 clock = ~clock;

    initial begin
        clock = 0;
        reset = 0;
        repeat (2) @(posedge clock);
        reset = 1;
        repeat (20) @(posedge clock);

        if (outputnum < 4'd10)
            $display("PASS: random digit = %0d, lfsr_bits = %0b",
                     outputnum, lfsr_bits);
        else
            $display("FAIL: random digit out of range");
        $finish;
    end
endmodule
