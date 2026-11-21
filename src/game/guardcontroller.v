
module guardcontroller(clk, reset, guardstart, playerfloor, guardfloor, guarddirection, guardstopped, guardtarget);

// purpose : implement security guard, manages floor, movement and stopping at each floor

//INPUTS
// clk = for automated speed
// reset = active low resets guard to 0
// guardstart = guard will start moving when user begins game (so this indicates game start)
// playerfloor = tracks player's current floor because guard will slowly chase them
// guardfloor = store guards current floor
// guardtarget = tells request module about which floor the guard wants to go to

//OUTPUTS
// guarddirection = idle, up , down 
// guardstopped = is 1 when guard idle -> will tell collision module that player loses if both guard and player are stopped

//note: guard should start at top floor, to give player fair chance

input[0:0] clk, reset, guardstart;
input [2:0] playerfloor, guardfloor;

output[0:0] guardstopped;
output reg [1:0] guarddirection;
output [2:0] guardtarget;

assign guardtarget = guardstart ? playerfloor : guardfloor;
// if 1, targets playerfloor
// if 0 targets guardfloor (stay at its location)
// DIRECTION LOGIC FSM

parameter [1:0] idle = 2'b00, up = 2'b01, down = 2'b10;

reg[1:0] currentstate, nextstate;

always @(*) begin
    
    nextstate = currentstate;

    case(currentstate)

    idle: if(!reset || guardfloor == playerfloor || guardstart == 0) nextstate = idle;
    else if(guardfloor > playerfloor && guardstart ==1 )
     nextstate = down;
    else if(guardfloor < playerfloor && guardstart ==1)
    nextstate = up;

    up: if(guardfloor < playerfloor && guardstart == 1) nextstate = up;
    else if(guardfloor > playerfloor && guardstart == 1) nextstate = down;
    else nextstate = idle;

    down: if(guardfloor > playerfloor && guardstart == 1) nextstate = down;
    else if(guardfloor < playerfloor && guardstart == 1) nextstate = up;
    else nextstate = idle;

    default: nextstate = idle;

    endcase
    guarddirection = currentstate;

end

always @(posedge clk) begin
    if(!reset) begin
        currentstate <= idle;
    end else begin
        currentstate <= nextstate;
    end
end



//OUTPUT LOGIC
assign guardstopped = (currentstate == idle);


endmodule
