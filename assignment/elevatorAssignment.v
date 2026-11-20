module elevatorAssignment(clock, reset, requestedFloor, requestValid, floorA, floorB, busyA, busyB, targetA, targetB, assignA, assignB, requestAccepted);

/*
    will decide which one to respond to request by comparing cost 
    - check whether a floor request exists
    - check whether each elevator is busy
    - check how far each elevator is from te requested floor
    - check which one should recieve the request 

    since right now the cost is only dependent on the distance of the\
    elevator from the user request floor (current floor) the 
    closer one && available should be called

    if both elevators are busy, wait until one becomes available 

*/
input clock, reset, requestValid, busyA, busyB;
input [2:0] requestedFloor, floorA, floorB;

output reg [2:0] targetA;   // destination floor of EA
output reg [2:0] targetB;   // destination floor of EB
output reg assignA;         // new request occured to A?
output reg assignB;         // new request occured to B?
output reg requestAccepted; 

// get cost from elevatorcost module 
wire [2:0] costA;   
wire [2:0] costB;

// for busy 
// 1 == busy, 0 == available 

// calling elevatorcost.v instantiating 
elevatorCost elevatorACost (
    .currentFloor(floorA),
    .requestedFloor(requestedFloor),
    .cost(costA)
);
// for elevaot rA

elevatorCost elevatorBCost (
    .currentFloor(floorB),
    .requestedFloor(requestedFloor),
    .cost(costB)
);
// for elevator B

always @(posedge clock) begin
    if(!reset) begin // low sync reset 
        targetA <= 3'b000;
        targetB <= 3'b000;
        assignA <= 1'b0;
        assignB <= 1'b0;
        requestAccepted <= 1'b0;
    end else begin
        // reset assignment signals
        // means they did not occur 
        assignA <= 1'b0;
        assignB <= 1'b0;
        requestAccepted <= 1'b0;

        // idle elevators keep their targets at their current floors
        // cuz they got nowhere to be 
        if(!busyA) begin
            targetA <= floorA;
        end
        if(!busyB) begin
            targetB <= floorB;
        end 

        if(requestValid && !requestAccepted) begin
            // will check if there is a request 
            // requestvalid == 1 : there is a pending request 
            // requestaccepted == 0: request has not been acknowledged 

            if(!busyA && !busyB) begin 
                // case 1: both available 

                if(costA <= costB) begin
                    targetA <= requestedFloor;
                    assignA <= 1'b1;
                    requestAccepted <= 1'b1;
                end else begin
                    targetB <= requestedFloor;
                    assignB <= 1'b1;
                    requestAccepted <= 1'b1;
                end
            end else if(!busyA && busyB) begin
                // case2: A available 
                targetA <= requestedFloor;
                assignA <= 1'b1;
                requestAccepted <= 1'b1;
            end else if(busyA && !busyB) begin
                // case3: B available 
                targetB <= requestedFloor;
                assignB <= 1'b1;
                requestAccepted <= 1'b1;
            end
            // if both elevators are busy, wait
        end
    end
end

endmodule
