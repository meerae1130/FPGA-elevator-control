module gamecontroller(clk, reset, started, floorinput, floorvalid, correct, wrong, arrived, submit, caught, failcount, playerfloor, guardfloor, moneyfloor, gamestate, targetfloor, move, check, newgame, newquestion, pickmoney);

input [0:0] clk, reset, started, floorvalid, correct, wrong, arrived, submit, caught;
input [2:0] playerfloor, guardfloor, moneyfloor, floorinput;
input[1:0] failcount;
output [2:0] gamestate;
output reg [2:0] targetfloor;
output reg [0:0] move, check, newgame, newquestion, pickmoney;

// INPUT DEFINITIONS:
// clk = tells when FSM updates
// reset = when pressed  we return to start of game
//started = checks if start is pressed by user
//floorinput = users request
// floorvalid = becomes 1 for 1 clock cycle when a valid floor is selected
// correct = becomes 1 when player answers math question correct
// wrong = becomes 1 when player answers math question wrong
// failcount = counts # of consecutive wrong ans
// playerfloor, guardfloor = floor they are currently on
// moneyfloor = floor w money
//caught = checks if user and guard stop at same floor

//OUTPUT DEFINITIONS:
// gamestate = tells other modules what phase of game we are currently in
// targetfloor = floor requested by user
// move = indicates that the player is allowed to request elevator movement
// check = tells math module to check if players ans is correct or not
// newgame = tells other modules to start a new game (and tells to choose a new floor to put money)
// newquestion = tells game when to give new math questoin
// pickmoney = randomly assigns money to floor

// game state logic :FSM
// will tell vga what to display
parameter [2:0] start = 3'b000, select = 3'b001, math = 3'b010, moving = 3'b011, win = 3'b100, lose = 3'b101, pickfloor = 3'b110;

reg[2:0] currentstate, nextstate;

// active low reset control
always @(posedge clk) begin
    
if(!reset) begin
    currentstate <= start;
end else begin
    currentstate <= nextstate;
end

end

// next state logic
always @(*)begin
    nextstate = currentstate;
    case (currentstate)
    start: if (started) nextstate = pickfloor; // conditon will be if(keycode == "enter" && keyvalid == 1)

    //add pickfloor
    pickfloor: nextstate = select;

    select: if(caught) nextstate = lose;
    else if(floorvalid) nextstate = math;

    math: if(caught) nextstate = lose;
    else if (wrong && failcount == 2'd3) nextstate = lose;
    else if (correct) nextstate = moving;


    moving: if(caught) nextstate = lose;
    else if(arrived && playerfloor == targetfloor) begin
        if(playerfloor == moneyfloor)
        nextstate = win;
        else 
        nextstate = select;
    end

    win:  nextstate = win;

    lose:  nextstate = lose;

    default: nextstate = start;

    endcase
end

// output logic

always @(*) begin
    move = 0; // starts moving elevtor after correct answer
    if(currentstate == math && correct && !caught) begin
        move = 1;
    end

    check = 0;
    
    if(submit  && currentstate == math && !caught) begin
        check = 1;
     
    end

    newquestion = 0; //generate math question when entered math state
    if((currentstate == select && floorvalid && !caught)) begin
        newquestion = 1;
    end

    // generate math question after a failed (incorrect) ans
    if(currentstate == math && wrong && failcount < 2'd3 && !caught)
    newquestion = 1;


    newgame = 0; // starts a new game
    if(currentstate == start && started)begin
        newgame = 1;
    end

    //add pickmoney
    pickmoney = 0;
    if(currentstate == pickfloor)
    pickmoney = 1;
end

// store requested floor logic
always @(posedge clk) begin
    if(!reset)
    targetfloor <= 3'b000;
    else if (currentstate == select && floorvalid && !caught)
    targetfloor <= floorinput;
end

assign gamestate = currentstate; // output the game's current state
endmodule
