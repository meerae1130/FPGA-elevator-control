module cost(currentFloor, requestedFloor, cost);

input [2:0] currentFloor;
input [2:0] requestedFloor;
output reg [2:0] cost;

// cost = |requestedfloor - currentfloor|
// add more factors later on 
// right now just distance from user 

/* factors 

    1. position of elevators
    2. direction of movement 
    3. destinations
    4. elevator status 
*/


/* game rules

    to request elevator, (submitting part with ENTER), user must solve a math problem 

    minigame each floor
    difficulty of the problem will increase (maybe) 
*/

always @(*) begin
    if(currentFloor < requestedFloor) begin
        // if requested is higher since we want positive difference
        // minus small number from big number
        cost = requestedFloor - currentFloor;
    end else begin
        // same thing when current floor is higher up 
        cost = currentFloor - requestedFloor;
    end
end

endmodule
