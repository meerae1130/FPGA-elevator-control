module guardcontroller(clk, reset, guardstart, playerfloor, guardfloor, guarddirection, guardstopped);

// purpose : implement security guard, manages floor, movement and stopping at each floor

//INPUTS
// clk = for automated speed
// reset = active low resets guard to 0
// guardstart = guard will start moving when user begins game (so this indicates game start)
// playerfloor = tracks player's current floor because guard will slowly chase them

//OUTPUTS
// guardfloor = store guards current floor
// guarddirection = idle, up , down 
// guardstopped = is 1 when guard idle -> will tell collision module that player loses if both guard and player are stopped

//note: guard should start at top floor, to give player fair chance

input[0:0] clk, reset, guardstart;
input [2:0] playerfloor;

output[0:0] guardstopped;
output reg [1:0] guarddirection;
output reg [2:0] guardfloor;

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


//TIMER LOGIC
reg[26:0] twosecondcounter; // 27 bits needed
always @(posedge clk) begin
    
    if(!reset) begin
        guardfloor <= 3'd7;
        twosecondcounter<= 27'd0;

    end  else if(guardstart == 0 || currentstate == idle) begin
        twosecondcounter <= 27'd0;
    end
    else if(currentstate != nextstate) begin // if user changes direction , reset timer and guard will follow new direction
        twosecondcounter <= 27'd0; 
    end
    else if (twosecondcounter == 27'd99999999 ) begin
        twosecondcounter <= 27'd0;

        // GUARD FLOOR MOVEMENT LOGIC
        // cant let guard go out of bounds if user is at end pts

        if(currentstate == up && guardfloor < 7) begin //
            guardfloor <= guardfloor+ 1;
        end else if(currentstate == down && guardfloor > 0) begin
            guardfloor <= guardfloor - 1;
        end

    end 
    
    else begin
        twosecondcounter <= twosecondcounter + 1;

    end

end


//OUTPUT LOGIC
assign guardstopped = (currentstate == 0);


endmodule
