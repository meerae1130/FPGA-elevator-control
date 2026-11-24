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

/*
    LOGIC:

    first come first out fifo queue BUT
        if multiple people are waiting on the same floor, onboard at the same time, no matter of their location in the queue 
        therefore check the current floor of the first person in queue, and check if there are any other people 
        behind, waiting on the same floor.
        -> if there is/are, get them on the elevator altogehter 
        -> none, only the first person in queue will get on
*/

module queue (clock, reset, newcurr, dest, reqaccepted, pickupvalid, pickupfloor, newreqvalid, outcurr, outreqvalid, boardingCount, boardingDest, newreqready, pickupBusy, waitingCounts);
    parameter [25:0] PICKUP_CYCLES = 26'd50_000_000; // One second at 50 MHz.
    // one second per floor (when boarding) number of persons does not matter
    // just one second per boarding event 
    input clock, reset, newreqvalid, reqaccepted, pickupvalid;
    input [2:0] newcurr, dest, pickupfloor;

    output outreqvalid, newreqready;
    output[2:0] outcurr; 
    output [3:0] boardingCount;
    output [23:0] boardingDest;
    output reg pickupBusy;
    output [31:0] waitingCounts; // Four bits per floor, floor 0 in bits 3:0.
    
    wire enqueue, inready; 

    reg [3:0] waitingCount [0:7];
    genvar displayFloor;
    generate
        for (displayFloor = 0; displayFloor < 8; displayFloor = displayFloor + 1) begin : floorCounts
            assign waitingCounts[4 * displayFloor +: 4] = waitingCount[displayFloor];
        end
    endgenerate
    reg [23:0] waitingDest [0:7];
    reg [7:0] pickupAssigned;
    reg [2:0] boardingFloor;
    reg [25:0] pickupCounter;

    wire needsPickup, acceptPassenger, boardGroup;
    wire assigningPickup, startPickup, boardingNewRequestFloor;
    wire [3:0] nextPassengerSlot;

    assign assigningPickup = outreqvalid && reqaccepted;
    // An elevator already at the pickup floor can accept and start pickup together.
    assign startPickup = !pickupBusy && pickupvalid &&
                         (pickupAssigned[pickupfloor] ||
                          (assigningPickup && outcurr == pickupfloor));
    assign boardGroup = pickupBusy && (pickupCounter == PICKUP_CYCLES - 26'd1);

    // A new passenger arriving as a group boards starts the next pickup.
    assign boardingNewRequestFloor = boardGroup && (newcurr == boardingFloor);
    assign nextPassengerSlot = boardingNewRequestFloor ? 4'd0
                                                        : waitingCount[newcurr];
    assign needsPickup = (nextPassengerSlot == 4'd0);

    assign newreqready = (nextPassengerSlot < 4'd8) && (!needsPickup || inready);
    assign acceptPassenger = newreqvalid && newreqready;
    assign enqueue = acceptPassenger && needsPickup;

    // Latch on the clock edge with nonzero boardingCount, as pickupBusy clears.
    // Only the first boardingCount destination slots are valid.
    assign boardingDest = boardGroup ? waitingDest[boardingFloor] : 24'd0;

    assign boardingCount = boardGroup ? waitingCount[boardingFloor] : 4'd0;

    fifo FIFO1(clock, reset, enqueue, newcurr, inready,
               outreqvalid, outcurr, reqaccepted);

    integer floorIndex;
    always @(posedge clock) begin
        if (!reset) begin
            pickupBusy <= 1'b0;
            boardingFloor <= 3'd0;
            pickupCounter <= 26'd0;
            pickupAssigned <= 8'b0;
            for (floorIndex = 0; floorIndex < 8; floorIndex = floorIndex + 1)
                waitingCount[floorIndex] <= 4'd0;
        end else begin
            if (startPickup) begin
                pickupBusy <= 1'b1;
                boardingFloor <= pickupfloor;
                pickupCounter <= 26'd0;
            end else if (boardGroup) begin
                pickupBusy <= 1'b0;
            end else if (pickupBusy) begin
                pickupCounter <= pickupCounter + 26'd1;
            end

            // The elevator accepted the pickup floor.
            if (assigningPickup)
                pickupAssigned[outcurr] <= 1'b1;

            // The pickup delay finished, so the whole group boards.
            if (boardGroup) begin
                waitingCount[boardingFloor] <= 4'd0;
                pickupAssigned[boardingFloor] <= 1'b0;
            end

            // Store the destination in the next free passenger slot.
            if (acceptPassenger) begin
                waitingDest[newcurr][3 * nextPassengerSlot +: 3] <= dest;
                waitingCount[newcurr] <= nextPassengerSlot + 4'd1;
            end
        end
    end


endmodule 

// fifo logic 
/*
    i am making this into a seperate module since 

    new person request != push floor 
    we want push to happen only when (new person request) && (that person is from a new floor)

    if the new request is coming from an already-person-exisiting floor, just want to add person object 
    inside the floorqueue array 

    in contrary, pop will always be called whenever there is a request, and the entire floor queue will pop
    meaning it could delete multiple npc objects at the same time 
*/
module fifo (clock, reset, invalid, infloor, inready, outvalid, outfloor, outready);
    input clock, reset, invalid, outready;
    input [2:0] infloor; 

    output inready, outvalid;
    output [2:0] outfloor;

    // invalid/outvalid : acts like submit button, whatever is going on in this module doesn't matter
    //                    until they are 1. then it gets passed to other modules/activates this module, etc. 

    reg [2:0] floorQueue [0:7];     // each floor has its own queue, all persons waiting on same floor will be stored in each index together 
    reg [2:0] head, tail;           // ehad and tail pointers
    reg [3:0] count;                // min0, max8, number of pickup floors, not the number of people in queue 
    wire push, pop;                 // 1 bit control wires (tells what to do)

    assign outvalid = (count != 4'd0);
    assign outfloor = floorQueue[head];
    assign pop = outvalid && outready;

    assign inready = (count != 4'd8) || pop;
    // if inready is 0, that means all 8 floors have at least a person waiting 
    // therefore should not push any more, since there are only 8 floors in the building 
    
    assign push = invalid && inready;

    always @(posedge clock) begin
        if (!reset) begin       // low sync reset 
            head  <= 3'd0;
            tail  <= 3'd0;
            count <= 4'd0;

        end else begin

            // insertion/deletion (actual fifo logic) ================
            if (push) begin     // insert at tail 
                floorQueue[tail] <= infloor;
                tail <= tail + 3'd1;
            end

            if (pop) begin     // delete at head 
                head <= head + 3'd1;
            end 
            //========================================================


            // updating count (number of pickup floors) ==============
            // if push and popped at the same clock edge, no need for count update 
            if (push && !pop)
                count <= count + 4'd1;
            else if (pop && !push)
                count <= count - 4'd1;
            //========================================================
        end
    end
endmodule
