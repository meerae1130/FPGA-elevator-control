`timescale 1ns/1ps

module queue_tb;
    reg clock;
    reg reset;
    reg newreqvalid;
    reg reqaccepted;
    reg pickupvalid;
    reg [2:0] newcurr;
    reg [2:0] dest;
    reg [2:0] pickupfloor;
    wire outreqvalid;
    wire newreqready;
    wire [2:0] outcurr;
    wire [3:0] boardingCount;
    wire [23:0] boardingDest;
    wire pickupBusy;
    wire [31:0] waitingCounts;

    queue #(.PICKUP_CYCLES(26'd5)) dut (
        .clock(clock),
        .reset(reset),
        .newcurr(newcurr),
        .dest(dest),
        .reqaccepted(reqaccepted),
        .pickupvalid(pickupvalid),
        .pickupfloor(pickupfloor),
        .newreqvalid(newreqvalid),
        .outcurr(outcurr),
        .outreqvalid(outreqvalid),
        .boardingCount(boardingCount),
        .boardingDest(boardingDest),
        .newreqready(newreqready),
        .pickupBusy(pickupBusy),
        .waitingCounts(waitingCounts)
    );

    always #10 clock = ~clock;

    initial begin
        clock = 0;
        reset = 0;
        newreqvalid = 0;
        reqaccepted = 0;
        pickupvalid = 0;
        newcurr = 0;
        dest = 0;
        pickupfloor = 0;

        repeat (2) @(posedge clock);
        reset = 1;

        @(negedge clock);
        newcurr = 3'd3;
        dest = 3'd6;
        newreqvalid = 1;
        @(posedge clock);
        @(negedge clock);
        newreqvalid = 0;

        repeat (2) @(posedge clock);
        if (!outreqvalid) begin
            $display("FAIL: queue did not expose the new request");
            $finish;
        end

        pickupfloor = 3'd3;
        pickupvalid = 1;
        reqaccepted = 1;
        @(posedge clock);
        @(negedge clock);
        pickupvalid = 0;
        reqaccepted = 0;

        repeat (20) @(posedge clock);

        $display("PASS: queue smoke test completed (outcurr=%0d waitingCounts=%h)",
                 outcurr, waitingCounts);
        $finish;
    end
endmodule
