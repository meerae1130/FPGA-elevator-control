
module guardcontroller(clk, reset, guardstart, playerfloor, guardfloor, guarddirection, guardstopped);

// purpose : implement security guard, manages floor, movement and stopping at each floor

//INPUTS
// clk = for automated speed
// reset = active low resets guard to 7
// guardstart = guard will start moving when user begins game (so this indicates game start)
// playerfloor = tracks player's current floor because guard will slowly chase them
// guardtarget = tells request module about which floor the guard wants to go to (not needed if just follows player)

//OUTPUTS
// guarddirection = idle, up , down 
// guardstopped = always 1 since guard moves instatly floor to floor
// guardfloor = store guards current floor
//note: guard should start at top floor, to give player fair chance

input[0:0] clk, reset, guardstart;
input [2:0] playerfloor;

output[0:0] guardstopped;
output reg [1:0] guarddirection;
//output [2:0] guardtarget;
output reg[2:0] guardfloor;

//assign guardtarget = guardstart ? playerfloor : guardfloor;
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

reg [27:0] counter;

//GUARD floor
always @(posedge clk)begin
    if(!reset) begin
        guardfloor <= 3'd7; // initialize to floor 7

    end else if(counter == 28'd149999999 && guardstart == 1) begin
        
        if(guardfloor > playerfloor)begin
            guardfloor <= guardfloor - 1; 
        end else if (guardfloor < playerfloor) begin
            guardfloor <= guardfloor +1;
        end 
    end
end

//timer logic

// 3 seconds speed for guard
always @(posedge clk) begin
    if (!reset) begin
        counter <= 28'd0;
    end
    else if (!guardstart) begin
        counter <= 28'd0;
    end
    else if (counter == 28'd149999999) begin
        counter <= 28'd0;
    end
    else begin
        counter <= counter + 28'd1;
    end
end


//OUTPUT LOGIC
assign guardstopped = 1; // so guardstopped is 1 when guard is stopped on a floor


endmodule
