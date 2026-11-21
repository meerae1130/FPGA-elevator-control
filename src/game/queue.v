/* take inputs from other_users.v 
    // this is from npcs 

    reg [2:0] current, dest;
    reg requestValid; 
*/

/* take inputs from requestController.v 
    // this is from the player 

    reg [2:0] requestedFloor;
    reg requestValid;
*/

/*
    will take in newcurr, dest, newreqvalid from either other_users or requestController
    newcurr     : "newly added request's current floor"
    dest        : "newly added request's destination floor"   // might not need in this module delete later if not needed 
    newreqvalid : "newly added request's requestValid output"

    output will be sent to elevatorAssignment.v module 
    outcurr     : "current floor of the first person in queue"
    outreqvalid : "requestValid of the first person in queue"
*/
module queue (clock, reset, newcurr, dest, newreqvalid, outcurr, outreqvalid);
    input clock, reset, newreqvalid;
    input [2:0] newcurr, dest;

    output outreqvalid;
    output[2:0] outcurr; 
    



endmodule 

// fifo logic 
module floor_fifo (clock, reset, invalid, infloor, inready, outvalid, outfloor, outready);

    input clock, reset, invalid;
    input [2:0] infloor; 

    output inready, outvalid, outready;
    output [2:0] outfloor;

    reg [2:0] floorQueue [0:7];
    reg [2:0] head, tail;
    reg [3:0] count;             // 0 through 8
    wire push, pop;

    assign outValid = (count != 4'd0);
    assign outFloor = floorQueue[head];
    assign pop = outValid && outReady;

    assign inReady = (count != 4'd8) || pop;
    assign push = inValid && inReady;

    always @(posedge clock) begin
        if (!reset) begin
            head  <= 3'd0;
            tail  <= 3'd0;
            count <= 4'd0;
        end else begin
            if (push) begin
                floorQueue[tail] <= inFloor;
                tail <= tail + 3'd1;
            end

            if (pop)
                head <= head + 3'd1;

            if (push && !pop)
                count <= count + 4'd1;
            else if (pop && !push)
                count <= count - 4'd1;
        end
    end
endmodule