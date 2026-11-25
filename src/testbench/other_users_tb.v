`timescale 1ns/1ps

module other_users_tb;
    reg clock;
    reg reset;
    wire [2:0] current;
    wire [2:0] dest;
    wire requestValid;

    other_users dut (
        .clock(clock),
        .reset(reset),
        .current(current),
        .dest(dest),
        .requestValid(requestValid)
    );

    always #10 clock = ~clock;

    initial begin
        clock = 0;
        reset = 0;
        repeat (2) @(posedge clock);
        reset = 1;

        // Reach the periodic spawn edge without running 100 million clocks.
        force other_users_tb.dut.twosec = 27'd99_999_998;
        repeat (3) @(posedge clock);
        release other_users_tb.dut.twosec;

        repeat (2) @(posedge clock);
        if (requestValid) begin
            $display("PASS: other_users spawned floor %0d -> %0d",
                     current, dest);
        end else begin
            $display("FAIL: other_users did not assert requestValid");
        end
        $finish;
    end
endmodule
