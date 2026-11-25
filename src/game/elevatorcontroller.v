module elevatorcontroller(clk, reset, move, targetfloor, currentfloor ,elevatordirection, arrival, playerstopped, busy);

//purpose of this module is to simulate elevator movement
// when floors accessed->will move 1 floor per sec

//INPUTS
// clk= timing of elebvator movement is 1 floor per sec
// reset = active low reset brings elevator to floor 0
// move = input from gamecontroller, tells elevator when to start moving to targetfloor
// targetfloor = user request


//OUTPUTS
// currentfloor = current floor user is on
//elevatordirection = whether elevator is moving up down or still
// arrival = tells us when the elevator has reached a floor
// playerstopped = tells us when the elevator has stopped (can get caught by guard, since caught is wehn elevators are stopped on same floor)
// busy = tells elevatorassignment whether elevator is currently doing a trip (  1 = handling a request, 0 not)

input[0:0] clk, reset, move;
input[2:0] targetfloor;

output[0:0] arrival, playerstopped, busy;
output reg[2:0] currentfloor;
output reg[1:0] elevatordirection;

//MOVEMENT AUTHORIZATION LOGIC
// must know when moving is allowed -> only when move = 1 ( correct ans to math )
reg moving; // tells elevator to keep moving if move  = 1 (remembers it)
assign busy = moving;
    reg [2:0] savedtarget; //to remember destination when it receives move (prevents changing destinations halfway through trips, which is what targetfloor could do)

assign arrival = (currentfloor == savedtarget); //  arrival is 1 when currentlfoor = savedtarget

always @(posedge clk) begin
    if(!reset)
    moving <= 0;
    else if(move == 1 && moving == 0) // accept movement request if not already moving
    moving <= (currentfloor != targetfloor);
    else if(arrival == 1)
    moving <= 0;
end

always @(posedge clk)begin
    
    if(!reset)begin
        savedtarget <= 3'd0;
    end else if(move == 1 && moving == 0)begin
        savedtarget <= targetfloor;
    end
end

//DIRECTION LOGIC
parameter[1:0] idle = 2'b00, up = 2'b01, down = 2'b10;
reg [1:0] currentstate, nextstate;

always@(*) begin
    nextstate = currentstate;

    case(currentstate)
    idle: if(!reset || moving == 0 || currentfloor == savedtarget) nextstate = idle;
    else if(currentfloor < savedtarget) nextstate = up;
    else nextstate = down;

    up: if(moving == 0 || arrival == 1) nextstate = idle; 
    else nextstate = up;

    down: if(moving == 0 || arrival == 1) nextstate = idle;
    else nextstate = down;

    default: nextstate = idle;

    endcase
    elevatordirection = currentstate;
end

// MOVEMENT LOGIC "activate" FSM 
always @(posedge clk) begin

    //RESET LOGIC -> put player on floor 0 and reset elevators controls to 0
if(!reset) begin
    currentstate <= 0;
end else
    currentstate <= nextstate;
end 

// TIMER AND FLOOR MOVEMENT LOGIC

reg [25:0] onesecondcounter; //26 bit needed

always @(posedge clk) begin
    if(!reset) begin
        onesecondcounter <= 26'd0;
        currentfloor <= 3'd0;
    end
    else if(moving == 0 || arrival == 1) begin //separately reset counter when idle or reached destination
        onesecondcounter <= 26'd0;
    end

    else if(onesecondcounter == 26'd49999999) begin
        onesecondcounter <= 26'd0;

        if(currentstate == up)
            currentfloor <= currentfloor + 1;
        else if(currentstate == down)
            currentfloor <= currentfloor - 1;
    end
    else begin
        onesecondcounter <= onesecondcounter + 1;
    end
end

//player is stopped and vulnerable to being caught if moving = 0
assign playerstopped = (moving == 0);
endmodule
