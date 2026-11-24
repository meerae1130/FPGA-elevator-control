// Verilog sources before the game integration fixes. Every line is commented.

// ===== src/game/collision.v =====
// module collision(playerfloor, guardfloor, playerstopped, guardstopped, caught);
// 
// //purpose: detect if player and guard land stop on the same floor -> player loses and game ends
// 
// //INPUTS
// //playerfloor = floor player is currently on
// //guardfloor = floor guard is currently on
// //playerstopped = indicates whether the player is stopped
// // guardstopped = indicates whether guard is stopped
// 
// //OUTPUTS
// //caught = if both are stopped on same floor, caught = 1 and player loses
// 
// input[0:0] playerstopped, guardstopped;
// input[2:0] playerfloor, guardfloor;
// 
// output[0:0] caught;
// 
// //assign output
// assign caught = ((playerfloor == guardfloor) && (playerstopped == 1) && (guardstopped == 1));
// 
// 
// endmodule


// ===== src/game/cost.v =====
// module cost(currentFloor, requestedFloor, cost);
// 
// input [2:0] currentFloor;
// input [2:0] requestedFloor;
// output reg [2:0] cost;
// 
// // cost = |requestedfloor - currentfloor|
// // add more factors later on 
// // right now just distance from user 
// 
// /* factors 
// 
//     1. position of elevators
//     2. direction of movement 
//     3. destinations
//     4. elevator status 
// */
// 
// 
// /* game rules
// 
//     to request elevator, (submitting part with KEY1), user must solve a math problem 
// 
//     minigame each floor
//     difficulty of the problem will increase (maybe) 
// 
//     we will: 
//         1. make security 
//         -> make another elevator 
//         -> C is not callable, moves up and down at a certian speed, destination updates to player's current location every clock cycle 
//         
// 
// */
// 
// always @(*) begin
//     if(currentFloor < requestedFloor) begin
//         // if requested is higher since we want positive difference
//         // minus small number from big number
//         cost = requestedFloor - currentFloor;
//     end else begin
//         // same thing when current floor is higher up 
//         cost = currentFloor - requestedFloor;
//     end
// end
// 
// endmodule


// ===== src/game/elevatorAssignment.v =====
// module elevatorAssignment(clock, reset, personfloor, requestValid, floorA, floorB, busyA, busyB, targetA, targetB, assignA, assignB, requestAccepted);
// 
// /*
//     will decide which one to respond to request by comparing cost 
//     - check whether a floor request exists
//     - check whether each elevator is busy
//     - check how far each elevator is from te requested floor
//     - check which one should recieve the request 
// 
//     since right now the cost is only dependent on the distance of the\
//     elevator from the user request floor (current floor) the 
//     closer one && available should be called
// 
//     if both elevators are busy, wait until one becomes available 
// 
// */
// input clock, reset, requestValid, busyA, busyB;
// input [2:0] personfloor, floorA, floorB;
// 
// output reg [2:0] targetA;   // destination floor of EA
// output reg [2:0] targetB;   // destination floor of EB
// output reg assignA;         // new request occured to A?
// output reg assignB;         // new request occured to B?
// output reg requestAccepted; 
// 
// // get cost from elevatorcost module 
// wire [2:0] costA;   
// wire [2:0] costB;
// 
// // for busy 
// // 1 == busy, 0 == available 
// 
// // calling elevatorcost.v instantiating 
// cost elevatorACost (
//     .currentFloor(floorA),
//     .requestedFloor(personfloor),
//     .cost(costA)
// );
// // for elevaot rA
// 
// cost elevatorBCost (
//     .currentFloor(floorB),
//     .requestedFloor(personfloor),
//     .cost(costB)
// );
// // for elevator B
// 
// always @(posedge clock) begin
//     if(!reset) begin // low sync reset 
//         targetA <= 3'b000;
//         targetB <= 3'b000;
//         assignA <= 1'b0;
//         assignB <= 1'b0;
//         requestAccepted <= 1'b0;
//     end else begin
//         // reset assignment signals
//         // means they did not occur 
//         assignA <= 1'b0;
//         assignB <= 1'b0;
//         requestAccepted <= 1'b0;
// 
//         // idle elevators keep their targets at their current floors
//         // cuz they got nowhere to be 
//         if(!busyA) begin
//             targetA <= floorA;
//         end
//         if(!busyB) begin
//             targetB <= floorB;
//         end 
// 
//         if(requestValid && !requestAccepted) begin
//             // will check if there is a request 
//             // requestvalid == 1 : there is a pending request 
//             // requestaccepted == 0: request has not been acknowledged 
// 
//             if(!busyA && !busyB) begin 
//                 // case 1: both available 
// 
//                 if(costA <= costB) begin
//                     targetA <= personfloor;
//                     assignA <= 1'b1;
//                     requestAccepted <= 1'b1;
//                 end else begin
//                     targetB <= personfloor;
//                     assignB <= 1'b1;
//                     requestAccepted <= 1'b1;
//                 end
//             end else if(!busyA && busyB) begin
//                 // case2: A available 
//                 targetA <= personfloor;
//                 assignA <= 1'b1;
//                 requestAccepted <= 1'b1;
//             end else if(busyA && !busyB) begin
//                 // case3: B available 
//                 targetB <= personfloor;
//                 assignB <= 1'b1;
//                 requestAccepted <= 1'b1;
//             end
//             // if both elevators are busy, wait
//         end
//     end
// end
// 
// endmodule


// ===== src/game/elevatorController =====
// module elevatorController(clock, reset, targetFloor, currentFloor, elevatorDir, arrival);
// 
// //assign inputs and outputs for
// input clock;
// input reset;
// input [2:0] targetFloor; // 8 floors needs 3 bits
// output reg [2:0] currentFloor;
// output reg [1:0] elevatorDir;
// output arrival;
// 
// reg [2:0] prevTarget; // to account for previous target
// reg [25:0] count;
// 
// //ELEVATOR RESET
// // reset = 0 -> elevator resets to floor 0
// // reset = 1 -> elevator continies as usual
// 
// always @(posedge clock) begin
// 
// 	if(!reset) begin
// 		currentFloor <= 3'b000; // sets to floor 0 
// 		elevatorDir <= 2'b00; // changes direction to idle
// 
// 	end else 
// 	
// 	// ELEVATOR DIRECTION
// 	//compare the current vs target floors -> adjust direction to go up, down or stay still
// 
// 	//ELEVATOR MOVEMENT
// 	//increment or decrement current floor by 1  accordingly
// 	//should only icrement or decrement after 1 second
// 
// 	if(currentFloor < targetFloor) begin
// 		elevatorDir <= 2'b01;//go up
// 		//for simulation change 26'd49999999 to 26'd9
// 		if(count == 26'd49999999 && targetFloor == prevTarget) begin
// 		currentFloor <= currentFloor + 1;
// 		end
// 	end else
// 	
// 	if(currentFloor > targetFloor) begin
// 		elevatorDir <= 2'b10; //go down
// 		
// 		if (count == 26'd49999999 && targetFloor == prevTarget)begin
// 		currentFloor <= currentFloor - 1;
// 		end
// 	end else
// 	
// 	elevatorDir <= 2'b00;
// 	
// 	end
// 
// 	
// // TIMER
// 
// always @(posedge clock) begin
// 
// 
// 	// reset if reset is active, idle or when the target changes midway
// 	if(!reset || targetFloor == currentFloor ||  prevTarget != targetFloor) begin
// 	
// 	count <= 26'd0; // reset to 0 when reset= 0 or idle
// 	
// 	end else
// 	
// 		
// 	// also check count if reached 50M (aka 1 second)
// 	//if yes reset to 0 and move elevator
// 	if(count == 26'd49999999) begin
// 	count  <= 26'd0;
// 	end
// 	
// 	
// 	else 
// 	
// 	count <= count + 1; // + 1 when elevator moves
// 
// end
// 
// //ASSIGN OUPUT
// // ASSIGN OUTPUT
// assign arrival = (currentFloor == targetFloor); // 1 when floors are equal
// 
// 
// // LOGIC FOR MULTIPLE REQUEST TIMER
// // elevator moving 1 floor/sec -> if button is pushed while moving, account for it
// 
// always @(posedge clock) begin
// 
// if(!reset) begin
// prevTarget <= 3'b000; // if reset = 0, reset previous target
// end else 
// 
// prevTarget <= targetFloor;  // if reset not activated set previous target to the target floor
// 
// end
// endmodule


// ===== src/game/elevatorcontroller.v =====
// module elevatorcontroller(clk, reset, move, targetfloor, currentfloor ,elevatordirection, arrival, playerstopped, busy);
// 
// //purpose of this module is to simulate elevator movement
// // when floors accessed->will move 1 floor per sec
// 
// //INPUTS
// // clk= timing of elebvator movement is 1 floor per sec
// // reset = active low reset brings elevator to floor 0
// // move = input from gamecontroller, tells elevator when to start moving to targetfloor
// // targetfloor = user request
// 
// 
// //OUTPUTS
// // currentfloor = current floor user is on
// //elevatordirection = whether elevator is moving up down or still
// // arrival = tells us when the elevator has reached a floor
// // playerstopped = tells us when the elevator has stopped (can get caught by guard, since caught is wehn elevators are stopped on same floor)
// // busy = tells elevatorassignment whether elevator is currently doing a trip (  1 = handling a request, 0 not)
// 
// input[0:0] clk, reset, move;
// input[2:0] targetfloor;
// 
// output[0:0] arrival, playerstopped, busy;
// output reg[2:0] currentfloor;
// output reg[1:0] elevatordirection;
// 
// //MOVEMENT AUTHORIZATION LOGIC
// // must know when moving is allowed -> only when move = 1 ( correct ans to math )
// reg moving; // tells elevator to keep moving if move  = 1 (remembers it)
// assign busy = moving;
// reg [2:0] savedtarget; //to remember destination when it receives move (prevents changing destinations halfway through trips)
// 
// assign arrival = (currentfloor == savedtarget); //  arrival is 1 when currentlfoor = savedtarget
// 
// always @(posedge clk) begin
//     if(!reset)
//     moving <= 0;
//     else if(move == 1 && moving == 0) 
//     moving <= (currentfloor != targetfloor);
//     else if(arrival == 1)
//     moving <= 0;
// end
// 
// always @(posedge clk)begin
//     
//     if(!reset)begin
//         savedtarget <= 3'd0;
//     end else if(move == 1 && moving == 0)begin
//         savedtarget <= targetfloor;
//     end
// end
// 
// //DIRECTION LOGIC
// parameter[1:0] idle = 2'b00, up = 2'b01, down = 2'b10;
// reg [1:0] currentstate, nextstate;
// 
// always@(*) begin
//     nextstate = currentstate;
// 
//     case(currentstate)
//     idle: if(!reset || moving == 0 || currentfloor == savedtarget) nextstate = idle;
//     else if(currentfloor < savedtarget) nextstate = up;
//     else nextstate = down;
// 
//     up: if(moving == 0 || arrival == 1) nextstate = idle; 
//     else nextstate = up;
// 
//     down: if(moving == 0 || arrival == 1) nextstate = idle;
//     else nextstate = down;
// 
//     default: nextstate = idle;
// 
//     endcase
//     elevatordirection = currentstate;
// end
// 
// // MOVEMENT LOGIC "activate" FSM 
// always @(posedge clk) begin
// 
//     //RESET LOGIC -> put player on floor 0 and reset elevators controls to 0
// if(!reset) begin
//     currentstate <= 0;
// end else
//     currentstate <= nextstate;
// end 
// 
// // TIMER AND FLOOR MOVEMENT LOGIC
// 
// reg [25:0] onesecondcounter; //26 bit needed
// 
// always @(posedge clk) begin
//     if(!reset) begin
//         onesecondcounter <= 26'd0;
//         currentfloor <= 3'd0;
//     end
//     else if(moving == 0 || arrival == 1) begin //separately reset counter when idle or reached destination
//         onesecondcounter <= 26'd0;
//     end
// 
//     else if(onesecondcounter == 26'd49999999) begin
//         onesecondcounter <= 26'd0;
// 
//         if(currentstate == up)
//             currentfloor <= currentfloor + 1;
//         else if(currentstate == down)
//             currentfloor <= currentfloor - 1;
//     end
//     else begin
//         onesecondcounter <= onesecondcounter + 1;
//     end
// end
// 
// //player is stopped and vulnerable to being caught if moving = 0
// assign playerstopped = (moving == 0);
// endmodule


// ===== src/game/gamecontroller.v =====
// module gamecontroller(clk, reset, started, floorinput, floorvalid, correct, wrong, arrived, submit, caught, failcount, playerfloor, guardfloor, moneyfloor, gamestate, targetfloor, move, check, newgame, newquestion, pickmoney);
// 
// input [0:0] clk, reset, started, floorvalid, correct, wrong, arrived, submit, caught;
// input [2:0] playerfloor, guardfloor, moneyfloor, floorinput;
// input[1:0] failcount;
// output [2:0] gamestate;
// output reg [2:0] targetfloor;
// output reg [0:0] move, check, newgame, newquestion, pickmoney;
// 
// // INPUT DEFINITIONS:
// // clk = tells when FSM updates
// // reset = when pressed  we return to start of game
// //started = checks if start is pressed by user
// //floorinput = users request
// // floorvalid = becomes 1 for 1 clock cycle when a valid floor is selected
// // correct = becomes 1 when player answers math question correct
// // wrong = becomes 1 when player answers math question wrong
// // failcount = counts # of consecutive wrong ans
// // playerfloor, guardfloor = floor they are currently on
// // moneyfloor = floor w money
// //caught = checks if user and guard stop at same floor
// 
// //OUTPUT DEFINITIONS:
// // gamestate = tells other modules what phase of game we are currently in
// // targetfloor = floor requested by user
// // move = indicates that the player is allowed to request elevator movement
// // check = tells math module to check if players ans is correct or not
// // newgame = tells other modules to start a new game (and tells to choose a new floor to put money)
// // newquestion = tells game when to give new math questoin
// // pickmoney = randomly assigns money to floor
// 
// // game state logic :FSM
// // will tell vga what to display
// parameter [2:0] start = 3'b000, select = 3'b001, math = 3'b010, moving = 3'b011, win = 3'b100, lose = 3'b101, pickfloor = 3'b110;
// 
// reg[2:0] currentstate, nextstate;
// 
// // active low reset control
// always @(posedge clk) begin
//     
// if(!reset) begin
//     currentstate <= start;
// end else begin
//     currentstate <= nextstate;
// end
// 
// end
// 
// // next state logic
// always @(*)begin
//     nextstate = currentstate;
//     case (currentstate)
//     start: if (started) nextstate = pickfloor; // conditon will be if(keycode == "enter" && keyvalid == 1)
// 
//     //add pickfloor
//     pickfloor: nextstate = select;
// 
//     select: if(caught) nextstate = lose;
//     else if(floorvalid) nextstate = math;
// 
//     math: if(caught) nextstate = lose;
//     else if (wrong && failcount == 2) nextstate = lose;
//     else if (correct) nextstate = moving;
// 
// 
//     moving: if(caught) nextstate = lose;
//     else if(arrived && playerfloor == targetfloor) begin
//         if(playerfloor == moneyfloor)
//         nextstate = win;
//         else 
//         nextstate = select;
//     end
// 
//     win:  nextstate = win;
// 
//     lose:  nextstate = lose;
// 
//     default: nextstate = start;
// 
//     endcase
// end
// 
// // output logic
// 
// always @(*) begin
//     move = 0; // starts moving elevtor after correct answer
//     if(currentstate == math && correct && !caught) begin
//         move = 1;
//     end
// 
//     check = 0;
//     
//     if(submit  && currentstate == math && !caught) begin
//         check = 1;
//      
//     end
// 
//     newquestion = 0; //generate math question when entered math state
//     if((currentstate == select && floorvalid && !caught)) begin
//         newquestion = 1;
//     end
// 
//     // generate math question after a failed (incorrect) ans
//     if(currentstate == math && wrong && failcount < 2 && !caught)
//     newquestion = 1;
// 
// 
//     newgame = 0; // starts a new game
//     if(currentstate == start && started)begin
//         newgame = 1;
//     end
// 
//     //add pickmoney
//     pickmoney = 0;
//     if(currentstate == pickfloor)
//     pickmoney = 1;
// end
// 
// // store requested floor logic
// always @(posedge clk) begin
//     if(!reset)
//     targetfloor <= 3'b000;
//     else if (currentstate == select && floorvalid && !caught)
//     targetfloor <= floorinput;
// end
// 
// assign gamestate = currentstate; // output the game's current state
// endmodule
// 
// // NEED WRONG AND FAILCOUNT AS OUPUTS IN MATH MODULE


// ===== src/game/guardcontroller.v =====
// 
// module guardcontroller(clk, reset, guardstart, playerfloor, guardfloor, guarddirection, guardstopped);
// 
// // purpose : implement security guard, manages floor, movement and stopping at each floor
// 
// //INPUTS
// // clk = for automated speed
// // reset = active low resets guard to 7
// // guardstart = guard will start moving when user begins game (so this indicates game start)
// // playerfloor = tracks player's current floor because guard will slowly chase them
// // guardtarget = tells request module about which floor the guard wants to go to (not needed if just follows player)
// 
// //OUTPUTS
// // guarddirection = idle, up , down 
// // guardstopped = always 1 since guard moves instatly floor to floor
// // guardfloor = store guards current floor
// //note: guard should start at top floor, to give player fair chance
// 
// input[0:0] clk, reset, guardstart;
// input [2:0] playerfloor;
// 
// output[0:0] guardstopped;
// output reg [1:0] guarddirection;
// //output [2:0] guardtarget;
// output reg[2:0] guardfloor;
// 
// //assign guardtarget = guardstart ? playerfloor : guardfloor;
// // if 1, targets playerfloor
// // if 0 targets guardfloor (stay at its location)
// // DIRECTION LOGIC FSM
// 
// parameter [1:0] idle = 2'b00, up = 2'b01, down = 2'b10;
// 
// reg[1:0] currentstate, nextstate;
// 
// always @(*) begin
//     
//     nextstate = currentstate;
// 
//     case(currentstate)
// 
//     idle: if(!reset || guardfloor == playerfloor || guardstart == 0) nextstate = idle;
//     else if(guardfloor > playerfloor && guardstart ==1 )
//      nextstate = down;
//     else if(guardfloor < playerfloor && guardstart ==1)
//     nextstate = up;
// 
//     up: if(guardfloor < playerfloor && guardstart == 1) nextstate = up;
//     else if(guardfloor > playerfloor && guardstart == 1) nextstate = down;
//     else nextstate = idle;
// 
//     down: if(guardfloor > playerfloor && guardstart == 1) nextstate = down;
//     else if(guardfloor < playerfloor && guardstart == 1) nextstate = up;
//     else nextstate = idle;
// 
//     default: nextstate = idle;
// 
//     endcase
//     guarddirection = currentstate;
// 
// end
// 
// always @(posedge clk) begin
//     if(!reset) begin
//         currentstate <= idle;
//     end else begin
//         currentstate <= nextstate;
//     end
// end
// 
// //GUARD floor
// always @(posedge clk)begin
//     if(!reset) begin
//         guardfloor <= 3'd7; // initialize to floor 7
// 
//     end else if(counter == 28'd149999999 && guardstart == 1) begin
//         
//         if(guardfloor > playerfloor)begin
//             guardfloor <= guardfloor - 1; 
//         end else if (guardfloor < playerfloor) begin
//             guardfloor <= guardfloor +1;
//         end 
//     end
// end
// 
// //timer logic
// 
// reg [27:0] counter;
// // 3 seconds speed for guard
// always @(posedge clk) begin
//     if (!reset) begin
//         counter <= 28'd0;
//     end
//     else if (!guardstart) begin
//         counter <= 28'd0;
//     end
//     else if (counter == 28'd149999999) begin
//         counter <= 28'd0;
//     end
//     else begin
//         counter <= counter + 28'd1;
//     end
// end
// 
// 
// //OUTPUT LOGIC
// assign guardstopped = 1; // so guardstopped is 1 when guard is stopped on a floor
// 
// 
// endmodule


// ===== src/game/keyboardcontroller.v =====
// module keyboardcontroller(receiveddata, receiveddataen, clk, reset, gamestate, started, floorinput, floorvalid, submit, finalanswer);
// 
// //purpose: turn input from keyboard into signals for our modules
// 
// //SIGNALS: (keyboard = meaning)
// // space (starting screen) =  start the game
// // enter (to enter a math answer) = submit the answer
// // #'s 0 to 7 = floor # requested by user
// 
// 
// // how it works:
// // ps/2 controller (given module) receives electric signals through cable from keyboard and turns it into a code
// // keyboardcontroller then takes that code and turns it into our input signals for gamecontroller
// 
// //INPUTS
// //inputs given by ps/2 module:
// //received_data = tells us WHAT the code sent by user on keyboard is
// // received_data_en = tells us WHEN the code is sent
// 
// //clk = timing
// // reset = active low
// // gamestate = tells which part of game we are in
// 
// //OUTPUTS
// //started = tells gamemcontroller to start the game
// // floorinput = to store the requested floor selected by player
// //floorvalid = tells us that a valid floor # is selected by user
// //submit = tells us that the player used enter to submit their math answer
// // answer = tells us the answer that the user puts for the math question
// 
// input [0:0] clk, reset, receiveddataen;
// input [7:0] receiveddata;
// input [2:0] gamestate;
// 
// 
// output reg [0:0] started, floorvalid;
// output reg[0:0] submit;
// output reg [2:0] floorinput;
// output reg signed [7:0] finalanswer; // signed for pos or neg
// 
// //RESET AND GETTING CODE LOGIC
// reg[7:0] getcode; //stores code received from ps2 board
// reg[0:0] keyReleased; // track if release or not
// 
// 
// always @(posedge clk) begin
//     if(!reset) begin
// 
//     getcode <= 8'b00000000;
//     keyReleased <= 0;
//        
//     end else begin
//         if(receiveddataen == 1) begin
//            
// 
//             // KEY RELEASE LOGIC
//             // needed so that controller doesn't count user input twice
// 
//             // ie: 5 sends code 2E, user releases 5, sends code F0 and 2E, needs to recognize 2E isnt another 5 input
//             // (F0 is the release signal for any key)
// 
//             if(receiveddata == 8'hF0 && keyReleased == 0) begin
//                 keyReleased <= 1; // raise flag
//             end else if(receiveddata != 8'hF0 && keyReleased == 1)begin //if flag was already raised reset to 0
//                 keyReleased <= 0;
//             end else  if(receiveddata != 8'hF0 && keyReleased == 0) begin // if not after a release , store
//                  getcode <= receiveddata;
//             end
// 
//         end
//     end 
// end 
// 
// // DECODE LOGIC
// // turn codes to numbers 
// 
// reg[3:0] digit; // 4 bits for 0 to 9
// reg [0:0] valid; // flag for if a new digit is entered
// 
// always @(posedge clk) begin
//     
//     if (!reset) begin
//         digit <= 4'd0;
//         valid <= 0;
//     end else begin
// 
// valid <= 0; // default
// 
//         if(receiveddataen == 1 && keyReleased == 0) begin
//             
//                case(receiveddata)
//     
//     8'h45: begin digit <= 4'd0; 
//     valid <= 1; end
//     8'h16: begin digit <= 4'd1;
//     valid <= 1; end
//     8'h1E: begin digit <= 4'd2;
//     valid<=1; end
//     8'h26: begin digit <= 4'd3;
//     valid <=1; end
//     8'h25: begin digit <= 4'd4;
//     valid <=1; end
//     8'h2E: begin digit <= 4'd5;
//     valid <=1; end
//     8'h36: begin digit <= 4'd6;
//     valid<=1; end
//     8'h3D: begin digit <=4'd7;
//     valid<=1; end
//     8'h3E: begin digit <= 4'd8;
//     valid <=1; end
//     8'h46: begin digit <= 4'd9;
//     valid <=1; end
//     default: digit <= digit;
// 
//     endcase
//         end
//     end
// end
// 
// // MULTIDIGIT ANSWER LOGIC
// // if more than 1 digit entered -> multiple first digit by 10, add second digit
// 
// // if enter is pressed -> user has inputted their full answer to question, so reset answer back to 0 for next question
// always @(posedge clk) begin
//     
//     if(!reset)begin
//         answer <= 8'b00000000;
//     end else begin
//     
//     if(valid == 1 && gamestate == 3'b010) begin
//         answer <= answer*10 + digit;
//     end else if(receiveddata == 8'h5A && receiveddataen == 1 && keyReleased == 0 && gamestate == 3'b010) begin
//             answer<=8'b00000000;
//         end
//     
//     end
//     end
// 
// // NEGATIVE ANS LOGIC
// 
// reg[0:0] sign; // keep track of sign of ans
// // 8'h4E is codefor - symbol
// // sign = 1 means neg ans
// always @(posedge clk)begin
//     if(!reset) begin
//         sign <= 0;
//     end else if(receiveddata ==  8'h4E && receiveddataen == 1 && keyReleased ==0 && gamestate == 3'b010)begin
//         sign <=1; 
//     end else if(receiveddata == 8'h5A && receiveddataen == 1 && keyReleased == 0 && gamestate == 3'b010) begin
//         sign <= 0; // reset to 0 when enter pressed so next ans wont be neg
//     end
// end
// 
// // apply it to ans
// // 8'h5A is code for enter 
// 
// always @(posedge clk)begin
//     submit<= 0;
//     if(!reset) begin
//         submit <= 0;
//     end else if(receiveddata == 8'h5A && receiveddataen == 1 && keyReleased == 0 &&gamestate == 3'b010)begin
//         submit<=1;
//     end
// end
// 
// reg signed [7:0] answer; // store final  ans to give back to math module
// always @(posedge clk)begin
// 
//     if(!reset)begin
//         finalanswer <=0; 
// 
//     end else if(receiveddata == 8'h5A && receiveddataen == 1 && keyReleased == 0 && gamestate == 3'b010) begin
//     if(sign == 1) begin
//         finalanswer<= answer*-1;
//     end else begin
//         finalanswer<=answer;
//     end
//     
//     end
//     
// end
// 
// // FLOOR SELECTION LOGIC
// 
// always@ (posedge clk)begin
//    
//     if(!reset) begin
//         floorinput <= 3'b000;
//         floorvalid <= 0;
//     end else begin 
// 
//          floorvalid <= 0; //reset to 0 every clock cycle so it doesnt keep signaling a new selection
//         
//         if(gamestate == 3'b001 && receiveddataen == 1 && keyReleased == 0)
//           
//           case(receiveddata)
//    
//     8'h45: begin floorinput <= 3'd0; 
//     floorvalid <= 1; end
//     8'h16: begin floorinput <= 3'd1;
//     floorvalid <= 1; end
//     8'h1E: begin floorinput <= 3'd2;
//     floorvalid<=1; end
//     8'h26: begin floorinput <= 3'd3;
//     floorvalid <=1; end
//     8'h25: begin floorinput <= 3'd4;
//     floorvalid <=1; end
//     8'h2E: begin floorinput <= 3'd5;
//     floorvalid <=1; end
//     8'h36: begin floorinput <= 3'd6;
//     floorvalid<=1; end
//     8'h3D: begin floorinput <=3'd7;
//     floorvalid<=1; end
// 
//     default: floorvalid<= 0;
//           endcase
//         
//     end
// end
// 
// // STARTING GAME LOGIC
// // starts when spacebar is pushed -> 8'h29
// 
// always @(posedge clk)begin
//     if(!reset)begin
//         started <= 0;
//     end else begin
//     started <=0;
//     if(receiveddata == 8'h29 && receiveddataen == 1 && keyReleased == 0 && gamestate == 3'b000)
//         started <=1;
//     end
// end
// endmodule


// ===== src/game/main.v =====
// module main_controller ();
//     // TOP MODULE 
// 
// 
// 
//     
//     // money floor randomization 
//     wire [3:0] rando;
//     reg  [2:0] money;   // since floor 1-8, 3 bits enough to express 8 diff floors (0-7)
// 
//     random rng (        // instantiating using random.v module 
//         .clock(clock),
//         .reset(reset),
//         .outputnum(rando)
//     );
// 
// 
// 
// 
//     // copy ur main module here 
//     // also in your main fsm, after idle, insert a state called pickfloor 
//     // next state after pickfloor == start game or smth 
//     // and insert this below in ur reset and pickfloor case: 
//     // not literal copy and paste but integrate it yk
// 
//     if (!reset) begin
//         money <= 3'd0;
//     end
//     case(y)
//         pickfloor: 
//             money <= rando [2:0];
// 
//     endcase
// 
// endmodule

// ===== src/game/main_controller.v =====
// module main_controller(CLOCK_50, KEY, PS2_CLK, PS2_DAT,
//                        VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_HS, VGA_VS,
//                        VGA_BLANK_N, VGA_SYNC_N);
// 
// //purpose: to connect all modules together
// 
// //INPUTS
// // CLOCK_50 = drives all our clocks
// // KEY = key[0] will be reset
// //keyboard signals:
// // PS2_CLK = keyboard clock
// // PS2_DAT = keyboard data
// 
// input CLOCK_50;
// inout PS2_CLK, PS2_DAT;
// input [3:0] KEY;
// output [2:0] VGA_R, VGA_G, VGA_B;
// output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N;
// 
// // KEYBOARD CONNECTION WIRES
// 
// wire [7:0] receiveddata;
// wire [0:0] receiveddataen, started, floorvalid, submit, correct, wrong, arrived, caught, move,check, newgame, newquestion, pickmoney, failed;
// wire [2:0] gamestate, floorinput, playerfloor, guardfloor, moneyfloor, targetfloor;
// wire[1:0] failcount, operator;
// wire [3:0] A, B;
// wire signed [7:0] finalanswer;
// 
// // INSTATIATION OF PS2 CONTROLLER MODULE
// PS2_Controller ps2(.CLOCK_50(CLOCK_50), .reset(~KEY[0]), .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT), .received_data(receiveddata), .received_data_en(receiveddataen), .the_command(8'b00000000), .send_command(1'b0));
// // not using thecommand and sendcommand so just set to const numbers
// 
// //CONNECT PS2 TO KEYBOARDCONTROLLER MODULE
// keyboardcontroller keyboard(.receiveddata(receiveddata), .receiveddataen(receiveddataen), .clk(CLOCK_50), .reset(KEY[0]), .gamestate(gamestate), .started(started), .floorinput(floorinput), .floorvalid(floorvalid), .submit(submit), .finalanswer(finalanswer));
// 
// //CONNECT GAMECOTROLLER MODULE TO KEYOARDCONTROLLER MODULE
// gamecontroller game(.clk(CLOCK_50), .reset(KEY[0]), .started(started), .floorinput(floorinput), .floorvalid(floorvalid), .correct(correct), .wrong(wrong), .arrived(arrived), .submit(submit), .caught(caught), .failcount(failcount), .playerfloor(playerfloor), .guardfloor(guardfloor), .moneyfloor(moneyfloor), .gamestate(gamestate), .targetfloor(targetfloor), .check(check), .newgame(newgame), .newquestion(newquestion), .pickmoney(pickmoney), .move(move));
// 
// //CONNECT MATH MODULE
// math math1(.clock(CLOCK_50), .start(newquestion), .reset(KEY[0]), .playerans(finalanswer), .enter(check), .A(A), .B(B), .operator(operator), .correct(correct), .failed(failed));
// //to change once signals wrong and failcount added
// 
// // INSTATIATION OF 2 ELEVATORS (shared by player, guard and npcs)
// wire[2:0] currentfloor1, currentfloor2, targetfloor1, targetfloor2;
// wire[1:0] direction1, direction2;
// wire [0:0] arrival1, arrival2, playerstopped1, playerstopped2, busy1, busy2, move1, move2;
// 
//         //for elevator 1
//     elevatorcontroller e1(.clk(CLOCK_50), .reset(KEY[0]),.move(move1), .targetfloor(targetfloor1), .currentfloor(currentfloor1), .elevatordirection(direction1), .arrival(arrival1), .playerstopped(playerstopped1), .busy(busy1));
//     elevatorcontroller e2(.clk(CLOCK_50), .reset(KEY[0]),.move(move2), .targetfloor(targetfloor2), .currentfloor(currentfloor2), .elevatordirection(direction2), .arrival(arrival2), .playerstopped(playerstopped2), .busy(busy2));
// 
// // CONNECT ELEVATORASSIGNMENT MODULE
// wire [2:0] requestedfloor;
// wire requestvalid, requestAccepted;
// elevatorAssignment assignment1(.clock(CLOCK_50), .reset(KEY[0]), .personfloor(requestedfloor), .requestValid(requestvalid), .floorA(currentfloor1), .floorB(currentfloor2), .busyA(busy1), .busyB(busy2), .targetA(targetfloor1), .targetB(targetfloor2), .assignA(move1), .assignB(move2), .requestAccepted(requestAccepted));
// 
// wire roundActive = gamestate == 3'd1 || gamestate == 3'd2 || gamestate == 3'd3;
// wire guardstopped;
// guardcontroller guard (
//     .clk(CLOCK_50), .reset(KEY[0]), .guardstart(roundActive),
//     .playerfloor(playerfloor), .guardfloor(guardfloor), .guardstopped(guardstopped)
// );
// 
// wire [5:0] moneyRandomBits;
// reg [2:0] savedMoneyFloor;
// random moneyRandom (.clock(CLOCK_50), .reset(KEY[0]), .lfsr_bits(moneyRandomBits));
// always @(posedge CLOCK_50) begin
//     if (!KEY[0])
//         savedMoneyFloor <= 3'd0;
//     else if (pickmoney)
//         savedMoneyFloor <= moneyRandomBits[2:0];
// end
// assign moneyfloor = savedMoneyFloor;
// 
// vga_display display (
//     .clock(CLOCK_50), .reset(KEY[0]), .gamestate(gamestate),
//     .playerfloor(playerfloor), .guardfloor(guardfloor), .moneyfloor(moneyfloor),
//     .targetfloor(targetfloor), .currentfloor1(currentfloor1), .currentfloor2(currentfloor2),
//     .busy1(busy1), .busy2(busy2), .A(A), .B(B), .operator(operator),
//     .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_CLK(VGA_CLK),
//     .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N)
// );
// 
// //add rest tmrw
// 
// endmodule


// ===== src/game/math.v =====
// // math game 
// module math (clock, start, reset, playerans, enter, A, B, operator, correct, failed);
//     input clock, start, reset, enter;
//     input signed [7:0] playerans; // -9 to 81 == 8 bits required minimally to express all numbers in set 
// 
//     // start will be 1 when user requests elevator (at KEY1 or equivalent)
// 
//     output reg correct, failed;     // user entered correct answer? / 3 consecutive fails? 
//     output reg [3:0] A, B;          // random number A, B for displaying in other modules
//     output reg [1:0] operator;      // random operator, for displaying in other modules 
// 
// 
//     reg [2:0] y;                    // current state 3 flipflops 
//     wire [3:0] rando;               // will store random number from random module 
// 
//     random rng (
//         .clock(clock),
//         .reset(reset),
//         .outputnum(rando)
//     );
// 
//     reg signed [7:0] ans;           // correct answer, player's has to match this 
//     reg[1:0] failcounter; 
// 
//     parameter                       // 6 states -> 3bits minimally req. therefore 3 ff
//         idle = 3'b000, 
//         setA = 3'b001,
//         setB = 3'b010, 
//         setop = 3'b011, 
//         calc = 3'b100, 
//         waitans = 3'b101;
// 
//     always @(posedge clock) begin 
//         if (!reset) begin           // low sync reset 
//             y <= idle; 
//             A <= 4'b0000;
//             B <= 4'b0000;
//             operator <= 2'b00;
//             correct <= 1'b0; 
//             failcounter <= 2'b00;
//             failed <= 1'b0;
// 
//         end else begin 
//             case (y) 
//                 idle: begin
//                     if (start && !failed) begin
//                         y <= setA; 
//                     end
//                     correct <= 1'b0;
//                 end
// 
//                 setA: begin
//                     A <= rando;
//                     y <= setB;
//                 end
// 
//                 setB: begin
//                     B <= rando; 
//                     y <= setop;
// 
//                 end 
//                 setop: begin
//                     operator <= rando%3;
//                     y <= calc; 
// 
//                 end
//                 calc: begin
//                     if (operator == 2'd0) begin 
//                         ans <= A + B;
//                     end else if (operator == 2'd1) begin
//                         ans <= A - B; 
//                     end else begin  // when operator is 2 
//                         ans <= A * B; 
//                     end
//                     y <= waitans;
//                 end
//                 waitans: begin
//                     if (enter) begin 
//                         if (playerans == ans) begin 
//                             // condition: player got the correct answer 
//                             y <= idle;
// 
//                             // return correct 
//                             correct <= 1'b1;
//                             failcounter <= 2'b00;   // reset when fail streak lost 
//                         end else if (failcounter == 2'b10)begin 
//                             // condition: player got it wrong, and they alr have 2 consecutive fail streak
//                             // game should end -> in this module, just raise failed flag
// 
//                             failed <= 1'b1;
//                             y <= idle; 
//                         end else begin
//                             failcounter <= failcounter + 1'b1;
//                             // state should also stay the same at waitans 
//                         end
//                     end 
//                     
//                 end
//             endcase
// 
//         end 
//     end 
// 
// endmodule

// ===== src/game/other_users.v =====
// // this module is for periodically spawning people who shares the elevator with the player 
// // one spawns every 2 seconds, random floor and random destination 
// 
// // i think we should have something like objects and classes 
// 
// // this would be a class, creating one user object, and later we make a queue basically in
// // another module (linked list typa)
// 
// 
// module other_users (clock, reset, current, dest, requestValid); 
//     input clock, reset; 
//     output reg [2:0] current, dest; // range [0,7] == 3 bits 
//     output reg requestValid; 
// 
//     reg [26:0] twosec;  // 2 seconds counter, range: [0,27'd99999999]
// 
//     wire [5:0] lfsr_bits;
//     wire [2:0] pickup_sample = lfsr_bits[2:0];
//     wire [2:0] dest_sample = lfsr_bits[5:3];
// 
//     random rng (         
//         .clock(clock),
//         .reset(reset),
//         .lfsr_bits(lfsr_bits)
//     );
// 
//     always @(posedge clock) begin
//         if (!reset) begin
//             twosec       <= 27'd0;
//             current      <= 3'd0;
//             dest         <= 3'd0;
//             requestValid <= 1'b0;
// 
//         end else begin
//             requestValid <= 1'b0;
// 
//             if (twosec == 27'd99_999_999) begin
//                 twosec       <= 27'd0;
//                 current      <= pickup_sample;
// 
//                 if (dest_sample == pickup_sample) begin
//                     dest <= dest_sample + 3'd1;  // Floor 7 wraps to floor 0.
//                 end else begin
//                     dest <= dest_sample;
//                 end
// 
//                 requestValid <= 1'b1;
//                 
//             end else begin
//                 twosec <= twosec + 27'd1;
//             end
//         end
//     end
// 
// endmodule 


// ===== src/game/playercontroller.v =====
// 
// module playercontroller(clk, reset, playerboard1, playerboard2, currentfloor1, currentfloor2, targetfloor, playerfloor, playerstopped, arrived);
// 
// //purpose: track player floor and which elevator the player is riding
// 
// //INPUTS
// // clk = clock
// // reset = active low reset, player starts at floor 0
// // playerboard1 = player boards elevator 1
// // playerboard2 = player boards elevator 2
// // currentfloor1 = elevator 1 current floor
// // currentfloor2 = elevator 2 current floor
// // targetfloor = player's destination floor
// 
// //OUTPUTS
// // playerfloor = player's current floor
// // playerstopped = 1 when player is not riding
// // arrived = 1 for one clock cycle when player reaches destination
// 
// input[0:0] clk, reset, playerboard1, playerboard2;
// input[2:0] currentfloor1, currentfloor2, targetfloor;
// 
// output reg[2:0] playerfloor;
// output[0:0] playerstopped;
// output reg[0:0] arrived;
// 
// //PLAYER STATE FSM
// parameter[1:0] waiting = 2'b00, elevator1 = 2'b01, elevator2 = 2'b10;
// 
// reg[1:0] currentstate;
// 
// always @(posedge clk) begin
// 
//     if(!reset) begin
//         currentstate <= waiting;
//         playerfloor <= 3'd0;
//         arrived <= 0;
//     end else begin
// 
//         arrived <= 0; //ny default
// 
//         case(currentstate)
// 
//         waiting: begin
//             if(playerboard1 == 1) begin
//                 currentstate <= elevator1;
//                 playerfloor <= currentfloor1;
//             end else if(playerboard2 == 1) begin
//                 currentstate <= elevator2;
//                 playerfloor <= currentfloor2;
//             end
//         end
// 
//         elevator1: begin
//             playerfloor <= currentfloor1;
// 
//             if(currentfloor1 == targetfloor) begin
//                 currentstate <= waiting;
//                 arrived <= 1;
//             end
//         end
// 
//         elevator2: begin
//             playerfloor <= currentfloor2;
// 
//             if(currentfloor2 == targetfloor) begin
//                 currentstate <= waiting;
//                 arrived <= 1;
//             end
//         end
// 
//         default: currentstate <= waiting;
// 
//         endcase
//     end
// end
// 
// //OUTPUT LOGIC
// assign playerstopped = (currentstate == waiting);
// 
// endmodule


// ===== src/game/queue.v =====
// /* take inputs from other_users.v 
//     // this is from npcs 
// 
//     reg [2:0] current, dest;
//     reg requestValid; 
// */
// 
// /* take inputs from requestController.v 
//     // this is from the player 
// 
//     reg [2:0] requestedFloor;
//     reg requestValid;
// */
// 
// /*
//     will take in newcurr, dest, newreqvalid from either other_users or requestController
//     newcurr     : "newly added request's current floor"
//     dest        : "newly added request's destination floor"   // might not need in this module delete later if not needed 
//     newreqvalid : "newly added request's requestValid output"
// 
//     output will be sent to elevatorAssignment.v module 
//     outcurr     : "current floor of the first person in queue"
//     outreqvalid : "requestValid of the first person in queue"
// */
// 
// /*
//     LOGIC:
// 
//     first come first out fifo queue BUT
//         if multiple people are waiting on the same floor, onboard at the same time, no matter of their location in the queue 
//         therefore check the current floor of the first person in queue, and check if there are any other people 
//         behind, waiting on the same floor.
//         -> if there is/are, get them on the elevator altogehter 
//         -> none, only the first person in queue will get on
// */
// 
// module queue (clock, reset, newcurr, dest, reqaccepted, pickupvalid, pickupfloor, newreqvalid, outcurr, outreqvalid, boardingCount, boardingDest, newreqready, pickupBusy);
//     parameter [25:0] PICKUP_CYCLES = 26'd50_000_000; // One second at 50 MHz.
//     // one second per floor (when boarding) number of persons does not matter
//     // just one second per boarding event 
//     input clock, reset, newreqvalid, reqaccepted, pickupvalid;
//     input [2:0] newcurr, dest, pickupfloor;
// 
//     output outreqvalid, newreqready;
//     output[2:0] outcurr; 
//     output reg [3:0] boardingCount;
//     output [23:0] boardingDest;
//     output reg pickupBusy;
//     
//     wire enqueue, inready; 
// 
//     reg [3:0] waitingCount [0:7];
//     reg [23:0] waitingDest [0:7];
//     reg [7:0] pickupAssigned;
//     reg [2:0] boardingFloor;
//     reg [25:0] pickupCounter;
// 
//     wire needsPickup, acceptPassenger, boardGroup;
//     wire assigningPickup, startPickup, boardingNewRequestFloor;
//     wire [3:0] nextPassengerSlot;
// 
//     assign assigningPickup = outreqvalid && reqaccepted;
//     // An elevator already at the pickup floor can accept and start pickup together.
//     assign startPickup = !pickupBusy && pickupvalid &&
//                          (pickupAssigned[pickupfloor] ||
//                           (assigningPickup && outcurr == pickupfloor));
//     assign boardGroup = pickupBusy && (pickupCounter == PICKUP_CYCLES - 26'd1);
// 
//     // A new passenger arriving as a group boards starts the next pickup.
//     assign boardingNewRequestFloor = boardGroup && (newcurr == boardingFloor);
//     assign nextPassengerSlot = boardingNewRequestFloor ? 4'd0
//                                                         : waitingCount[newcurr];
//     assign needsPickup = (nextPassengerSlot == 4'd0);
// 
//     assign newreqready = (nextPassengerSlot < 4'd8) && (!needsPickup || inready);
//     assign acceptPassenger = newreqvalid && newreqready;
//     assign enqueue = acceptPassenger && needsPickup;
// 
//     // Latch on the clock edge with nonzero boardingCount, as pickupBusy clears.
//     // Only the first boardingCount destination slots are valid.
//     assign boardingDest = boardGroup ? waitingDest[boardingFloor] : 24'd0;
// 
//     always @(*) begin
//         if (boardGroup)
//             boardingCount = waitingCount[boardingFloor];
//         else
//             boardingCount = 4'd0;
//     end
// 
//     fifo FIFO1(clock, reset, enqueue, newcurr, inready,
//                outreqvalid, outcurr, reqaccepted);
// 
//     integer floorIndex;
//     always @(posedge clock) begin
//         if (!reset) begin
//             pickupBusy <= 1'b0;
//             boardingFloor <= 3'd0;
//             pickupCounter <= 26'd0;
//             pickupAssigned <= 8'b0;
//             for (floorIndex = 0; floorIndex < 8; floorIndex = floorIndex + 1)
//                 waitingCount[floorIndex] <= 4'd0;
//         end else begin
//             if (startPickup) begin
//                 pickupBusy <= 1'b1;
//                 boardingFloor <= pickupfloor;
//                 pickupCounter <= 26'd0;
//             end else if (boardGroup) begin
//                 pickupBusy <= 1'b0;
//             end else if (pickupBusy) begin
//                 pickupCounter <= pickupCounter + 26'd1;
//             end
// 
//             // The elevator accepted the pickup floor.
//             if (assigningPickup)
//                 pickupAssigned[outcurr] <= 1'b1;
// 
//             // The pickup delay finished, so the whole group boards.
//             if (boardGroup) begin
//                 waitingCount[boardingFloor] <= 4'd0;
//                 pickupAssigned[boardingFloor] <= 1'b0;
//             end
// 
//             // Store the destination in the next free passenger slot.
//             if (acceptPassenger) begin
//                 waitingDest[newcurr][3 * nextPassengerSlot +: 3] <= dest;
//                 waitingCount[newcurr] <= nextPassengerSlot + 4'd1;
//             end
//         end
//     end
// 
// 
// endmodule 
// 
// // fifo logic 
// /*
//     i am making this into a seperate module since 
// 
//     new person request != push floor 
//     we want push to happen only when (new person request) && (that person is from a new floor)
// 
//     if the new request is coming from an already-person-exisiting floor, just want to add person object 
//     inside the floorqueue array 
// 
//     in contrary, pop will always be called whenever there is a request, and the entire floor queue will pop
//     meaning it could delete multiple npc objects at the same time 
// */
// module fifo (clock, reset, invalid, infloor, inready, outvalid, outfloor, outready);
//     input clock, reset, invalid, outready;
//     input [2:0] infloor; 
// 
//     output inready, outvalid;
//     output [2:0] outfloor;
// 
//     // invalid/outvalid : acts like submit button, whatever is going on in this module doesn't matter
//     //                    until they are 1. then it gets passed to other modules/activates this module, etc. 
// 
//     reg [2:0] floorQueue [0:7];     // each floor has its own queue, all persons waiting on same floor will be stored in each index together 
//     reg [2:0] head, tail;           // ehad and tail pointers
//     reg [3:0] count;                // min0, max8, number of pickup floors, not the number of people in queue 
//     wire push, pop;                 // 1 bit control wires (tells what to do)
// 
//     assign outvalid = (count != 4'd0);
//     assign outfloor = floorQueue[head];
//     assign pop = outvalid && outready;
// 
//     assign inready = (count != 4'd8) || pop;
//     // if inready is 0, that means all 8 floors have at least a person waiting 
//     // therefore should not push any more, since there are only 8 floors in the building 
//     
//     assign push = invalid && inready;
// 
//     always @(posedge clock) begin
//         if (!reset) begin       // low sync reset 
//             head  <= 3'd0;
//             tail  <= 3'd0;
//             count <= 4'd0;
// 
//         end else begin
// 
//             // insertion/deletion (actual fifo logic) ================
//             if (push) begin     // insert at tail 
//                 floorQueue[tail] <= infloor;
//                 tail <= tail + 3'd1;
//             end
// 
//             if (pop) begin     // delete at head 
//                 head <= head + 3'd1;
//             end 
//             //========================================================
// 
// 
//             // updating count (number of pickup floors) ==============
//             // if push and popped at the same clock edge, no need for count update 
//             if (push && !pop)
//                 count <= count + 4'd1;
//             else if (pop && !push)
//                 count <= count - 4'd1;
//             //========================================================
//         end
//     end
// endmodule


// ===== src/game/random.v =====
// // random number generating shift register 
// // Provides a decimal digit and six unfiltered LFSR bits.
// module random (clock, reset, outputnum, lfsr_bits);
//     input clock, reset;
//     output reg [3:0] outputnum;
//     output wire [5:0] lfsr_bits;
// 
//     reg [15:0] lfsr;
//     wire feedback;
// 
//     assign lfsr_bits = lfsr[5:0];
//     assign feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
//     // this either 0 or 1 feedback will be inserted into rightmost digit during shift to left 
// 
//     always @(posedge clock) begin
//         if (!reset) begin
//             lfsr <= 16'b0000000000000001;
//             outputnum <= 4'd0;
//         end
//         else begin
//             lfsr <= {lfsr[14:0], feedback};
// 
//             if (lfsr[3:0] < 4'd10)
//                 // keep previous state if lfsr is bigger than 9 
//                 // assign randomnum to lfsr if it is less than 9 
//                 outputnum <= lfsr[3:0];
//         end
//     end
// endmodule


// ===== src/game/requestController.v =====
// module requestController (clock, reset, floorInput, requestButton, requestAccepted, requestedFloor, requestValid);
// 
// 
// /* 
//     will handle all floor requests 
// 
//     - detect when someone presses the floor request button
//     - store the requested floor
//     - indicate that request pending
//     - clear the request once elevator control module accepts it 
//     - reset
//     - do not move the elevator 
// */
// // input output
// input clock, reset, requestButton, requestAccepted;
// input [2:0] floorInput; // 8 floors therefore 3 bits;
// 
// output reg [2:0] requestedFloor;
// output reg requestValid;
// 
// // register to track previous button state
// // detect when button is pressed, not when its being held down 
// // neg edge is signal 
// reg prev;
// 
// // floor request controller
// // reset = 0 -> clear stored request
// // reset = 1 -> continue as usual
// always @(posedge clock) begin
//     if(!reset) begin    // sync active low 
//         requestedFloor <= 3'b000;
//         requestValid <= 1'b0;
//         prev <= 1'b1;
//     end else begin
//         // KEY[1] = 0 when pressed; detect falling edge
//         prev <= requestButton;  // at rising clk edge, prev will recieve current button state 
// 
//         // store a request only if no request is pending
//         // requestvalid == 1 : request alr pending
//         // requestvalid ==0 , no pending 
//         if(prev == 1'b1 && requestButton == 1'b0 && !requestValid) begin
//             // if previous button state was 1 and current is 0
//             requestedFloor <= floorInput;
//             requestValid <= 1'b1;
//         end else if(requestAccepted) begin
//             // if another module from angela accepts the floor request
//             // clear the flag so it will take inputs again 
//             requestValid <= 1'b0;
//         end
//     end
// end
// 
// endmodule


// ===== src/input_source/Altera_UP_PS2.v =====
// /*****************************************************************************
//  *                                                                           *
//  * Module:       Altera_UP_PS2                                               *
//  * Description:                                                              *
//  *      This module communicates with the PS2 core.                          *
//  *                                                                           *
//  *****************************************************************************/
// 
// module PS2_Controller #(parameter INITIALIZE_MOUSE = 0) (
// 	// Inputs
// 	CLOCK_50,
// 	reset,
// 
// 	the_command,
// 	send_command,
// 
// 	// Bidirectionals
// 	PS2_CLK,					// PS2 Clock
//  	PS2_DAT,					// PS2 Data
// 
// 	// Outputs
// 	command_was_sent,
// 	error_communication_timed_out,
// 
// 	received_data,
// 	received_data_en			// If 1 - new data has been received
// );
// 
// /*****************************************************************************
//  *                           Parameter Declarations                          *
//  *****************************************************************************/
// 
// 
// /*****************************************************************************
//  *                             Port Declarations                             *
//  *****************************************************************************/
// // Inputs
// input			CLOCK_50;
// input			reset;
// 
// input	[7:0]	the_command;
// input			send_command;
// 
// // Bidirectionals
// inout			PS2_CLK;
// inout		 	PS2_DAT;
// 
// // Outputs
// output			command_was_sent;
// output			error_communication_timed_out;
// 
// output	[7:0]	received_data;
// output		 	received_data_en;
// 
// wire [7:0] the_command_w;
// wire send_command_w, command_was_sent_w, error_communication_timed_out_w;
// 
// generate
// 	if(INITIALIZE_MOUSE) begin
// 		assign the_command_w = init_done ? the_command : 8'hf4;
// 		assign send_command_w = init_done ? send_command : (!command_was_sent_w && !error_communication_timed_out_w);
// 		assign command_was_sent = init_done ? command_was_sent_w : 0;
// 		assign error_communication_timed_out = init_done ? error_communication_timed_out_w : 1;
// 		
// 		reg init_done;
// 		
// 		always @(posedge CLOCK_50)
// 			if(reset) init_done <= 0;
// 			else if(command_was_sent_w) init_done <= 1;
// 		
// 	end else begin
// 		assign the_command_w = the_command;
// 		assign send_command_w = send_command;
// 		assign command_was_sent = command_was_sent_w;
// 		assign error_communication_timed_out = error_communication_timed_out_w;
// 	end
// endgenerate
// 
// /*****************************************************************************
//  *                           Constant Declarations                           *
//  *****************************************************************************/
// // states
// localparam	PS2_STATE_0_IDLE			= 3'h0,
// 			PS2_STATE_1_DATA_IN			= 3'h1,
// 			PS2_STATE_2_COMMAND_OUT		= 3'h2,
// 			PS2_STATE_3_END_TRANSFER	= 3'h3,
// 			PS2_STATE_4_END_DELAYED		= 3'h4;
// 
// /*****************************************************************************
//  *                 Internal wires and registers Declarations                 *
//  *****************************************************************************/
// // Internal Wires
// wire			ps2_clk_posedge;
// wire			ps2_clk_negedge;
// 
// wire			start_receiving_data;
// wire			wait_for_incoming_data;
// 
// // Internal Registers
// reg		[7:0]	idle_counter;
// 
// reg				ps2_clk_reg;
// reg				ps2_data_reg;
// reg				last_ps2_clk;
// 
// // State Machine Registers
// reg		[2:0]	ns_ps2_transceiver;
// reg		[2:0]	s_ps2_transceiver;
// 
// /*****************************************************************************
//  *                         Finite State Machine(s)                           *
//  *****************************************************************************/
// 
// always @(posedge CLOCK_50)
// begin
// 	if (reset == 1'b1)
// 		s_ps2_transceiver <= PS2_STATE_0_IDLE;
// 	else
// 		s_ps2_transceiver <= ns_ps2_transceiver;
// end
// 
// always @(*)
// begin
// 	// Defaults
// 	ns_ps2_transceiver = PS2_STATE_0_IDLE;
// 
//     case (s_ps2_transceiver)
// 	PS2_STATE_0_IDLE:
// 		begin
// 			if ((idle_counter == 8'hFF) && 
// 					(send_command == 1'b1))
// 				ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;
// 			else if ((ps2_data_reg == 1'b0) && (ps2_clk_posedge == 1'b1))
// 				ns_ps2_transceiver = PS2_STATE_1_DATA_IN;
// 			else
// 				ns_ps2_transceiver = PS2_STATE_0_IDLE;
// 		end
// 	PS2_STATE_1_DATA_IN:
// 		begin
// 			if ((received_data_en == 1'b1)/* && (ps2_clk_posedge == 1'b1)*/)
// 				ns_ps2_transceiver = PS2_STATE_0_IDLE;
// 			else
// 				ns_ps2_transceiver = PS2_STATE_1_DATA_IN;
// 		end
// 	PS2_STATE_2_COMMAND_OUT:
// 		begin
// 			if ((command_was_sent == 1'b1) ||
// 				(error_communication_timed_out == 1'b1))
// 				ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
// 			else
// 				ns_ps2_transceiver = PS2_STATE_2_COMMAND_OUT;
// 		end
// 	PS2_STATE_3_END_TRANSFER:
// 		begin
// 			if (send_command == 1'b0)
// 				ns_ps2_transceiver = PS2_STATE_0_IDLE;
// 			else if ((ps2_data_reg == 1'b0) && (ps2_clk_posedge == 1'b1))
// 				ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;
// 			else
// 				ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
// 		end
// 	PS2_STATE_4_END_DELAYED:	
// 		begin
// 			if (received_data_en == 1'b1)
// 			begin
// 				if (send_command == 1'b0)
// 					ns_ps2_transceiver = PS2_STATE_0_IDLE;
// 				else
// 					ns_ps2_transceiver = PS2_STATE_3_END_TRANSFER;
// 			end
// 			else
// 				ns_ps2_transceiver = PS2_STATE_4_END_DELAYED;
// 		end	
// 	default:
// 			ns_ps2_transceiver = PS2_STATE_0_IDLE;
// 	endcase
// end
// 
// /*****************************************************************************
//  *                             Sequential logic                              *
//  *****************************************************************************/
// 
// always @(posedge CLOCK_50)
// begin
// 	if (reset == 1'b1)
// 	begin
// 		last_ps2_clk	<= 1'b1;
// 		ps2_clk_reg		<= 1'b1;
// 
// 		ps2_data_reg	<= 1'b1;
// 	end
// 	else
// 	begin
// 		last_ps2_clk	<= ps2_clk_reg;
// 		ps2_clk_reg		<= PS2_CLK;
// 
// 		ps2_data_reg	<= PS2_DAT;
// 	end
// end
// 
// always @(posedge CLOCK_50)
// begin
// 	if (reset == 1'b1)
// 		idle_counter <= 6'h00;
// 	else if ((s_ps2_transceiver == PS2_STATE_0_IDLE) &&
// 			(idle_counter != 8'hFF))
// 		idle_counter <= idle_counter + 6'h01;
// 	else if (s_ps2_transceiver != PS2_STATE_0_IDLE)
// 		idle_counter <= 6'h00;
// end
// 
// /*****************************************************************************
//  *                            Combinational logic                            *
//  *****************************************************************************/
// 
// assign ps2_clk_posedge = 
// 			((ps2_clk_reg == 1'b1) && (last_ps2_clk == 1'b0)) ? 1'b1 : 1'b0;
// assign ps2_clk_negedge = 
// 			((ps2_clk_reg == 1'b0) && (last_ps2_clk == 1'b1)) ? 1'b1 : 1'b0;
// 
// assign start_receiving_data		= (s_ps2_transceiver == PS2_STATE_1_DATA_IN);
// assign wait_for_incoming_data	= 
// 			(s_ps2_transceiver == PS2_STATE_3_END_TRANSFER);
// 
// /*****************************************************************************
//  *                              Internal Modules                             *
//  *****************************************************************************/
// 
// Altera_UP_PS2_Data_In PS2_Data_In (
// 	// Inputs
// 	.clk							(CLOCK_50),
// 	.reset							(reset),
// 
// 	.wait_for_incoming_data			(wait_for_incoming_data),
// 	.start_receiving_data			(start_receiving_data),
// 
// 	.ps2_clk_posedge				(ps2_clk_posedge),
// 	.ps2_clk_negedge				(ps2_clk_negedge),
// 	.ps2_data						(ps2_data_reg),
// 
// 	// Bidirectionals
// 
// 	// Outputs
// 	.received_data					(received_data),
// 	.received_data_en				(received_data_en)
// );
// 
// Altera_UP_PS2_Command_Out PS2_Command_Out (
// 	// Inputs
// 	.clk							(CLOCK_50),
// 	.reset							(reset),
// 
// 	.the_command					(the_command_w),
// 	.send_command					(send_command_w),
// 
// 	.ps2_clk_posedge				(ps2_clk_posedge),
// 	.ps2_clk_negedge				(ps2_clk_negedge),
// 
// 	// Bidirectionals
// 	.PS2_CLK						(PS2_CLK),
//  	.PS2_DAT						(PS2_DAT),
// 
// 	// Outputs
// 	.command_was_sent				(command_was_sent_w),
// 	.error_communication_timed_out	(error_communication_timed_out_w)
// );
// 
// endmodule
// 


// ===== src/input_source/Altera_UP_PS2_Command_Out .v =====
// /*****************************************************************************
//  *                                                                           *
//  * Module:       Altera_UP_PS2_Command_Out                                   *
//  * Description:                                                              *
//  *      This module sends commands out to the PS2 core.                      *
//  *                                                                           *
//  *****************************************************************************/
// 
// 
// module Altera_UP_PS2_Command_Out (
// 	// Inputs
// 	clk,
// 	reset,
// 
// 	the_command,
// 	send_command,
// 
// 	ps2_clk_posedge,
// 	ps2_clk_negedge,
// 
// 	// Bidirectionals
// 	PS2_CLK,
//  	PS2_DAT,
// 
// 	// Outputs
// 	command_was_sent,
// 	error_communication_timed_out
// );
// 
// /*****************************************************************************
//  *                           Parameter Declarations                          *
//  *****************************************************************************/
// 
// // Timing info for initiating Host-to-Device communication 
// //   when using a 50MHz system clock
// parameter	CLOCK_CYCLES_FOR_101US		= 5050;
// parameter	NUMBER_OF_BITS_FOR_101US	= 13;
// parameter	COUNTER_INCREMENT_FOR_101US	= 13'h0001;
// 
// //parameter	CLOCK_CYCLES_FOR_101US		= 50;
// //parameter	NUMBER_OF_BITS_FOR_101US	= 6;
// //parameter	COUNTER_INCREMENT_FOR_101US	= 6'h01;
// 
// // Timing info for start of transmission error 
// //   when using a 50MHz system clock
// parameter	CLOCK_CYCLES_FOR_15MS		= 750000;
// parameter	NUMBER_OF_BITS_FOR_15MS		= 20;
// parameter	COUNTER_INCREMENT_FOR_15MS	= 20'h00001;
// 
// // Timing info for sending data error 
// //   when using a 50MHz system clock
// parameter	CLOCK_CYCLES_FOR_2MS		= 100000;
// parameter	NUMBER_OF_BITS_FOR_2MS		= 17;
// parameter	COUNTER_INCREMENT_FOR_2MS	= 17'h00001;
// 
// /*****************************************************************************
//  *                             Port Declarations                             *
//  *****************************************************************************/
// // Inputs
// input				clk;
// input				reset;
// 
// input		[7:0]	the_command;
// input				send_command;
// 
// input				ps2_clk_posedge;
// input				ps2_clk_negedge;
// 
// // Bidirectionals
// inout				PS2_CLK;
// inout			 	PS2_DAT;
// 
// // Outputs
// output	reg			command_was_sent;
// output	reg		 	error_communication_timed_out;
// 
// /*****************************************************************************
//  *                           Constant Declarations                           *
//  *****************************************************************************/
// // states
// parameter	PS2_STATE_0_IDLE					= 3'h0,
// 			PS2_STATE_1_INITIATE_COMMUNICATION	= 3'h1,
// 			PS2_STATE_2_WAIT_FOR_CLOCK			= 3'h2,
// 			PS2_STATE_3_TRANSMIT_DATA			= 3'h3,
// 			PS2_STATE_4_TRANSMIT_STOP_BIT		= 3'h4,
// 			PS2_STATE_5_RECEIVE_ACK_BIT			= 3'h5,
// 			PS2_STATE_6_COMMAND_WAS_SENT		= 3'h6,
// 			PS2_STATE_7_TRANSMISSION_ERROR		= 3'h7;
// 
// /*****************************************************************************
//  *                 Internal wires and registers Declarations                 *
//  *****************************************************************************/
// // Internal Wires
// 
// // Internal Registers
// reg			[3:0]	cur_bit;
// reg			[8:0]	ps2_command;
// 
// reg			[NUMBER_OF_BITS_FOR_101US:1]	command_initiate_counter;
// 
// reg			[NUMBER_OF_BITS_FOR_15MS:1]		waiting_counter;
// reg			[NUMBER_OF_BITS_FOR_2MS:1]		transfer_counter;
// 
// // State Machine Registers
// reg			[2:0]	ns_ps2_transmitter;
// reg			[2:0]	s_ps2_transmitter;
// 
// /*****************************************************************************
//  *                         Finite State Machine(s)                           *
//  *****************************************************************************/
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		s_ps2_transmitter <= PS2_STATE_0_IDLE;
// 	else
// 		s_ps2_transmitter <= ns_ps2_transmitter;
// end
// 
// always @(*)
// begin
// 	// Defaults
// 	ns_ps2_transmitter = PS2_STATE_0_IDLE;
// 
//     case (s_ps2_transmitter)
// 	PS2_STATE_0_IDLE:
// 		begin
// 			if (send_command == 1'b1)
// 				ns_ps2_transmitter = PS2_STATE_1_INITIATE_COMMUNICATION;
// 			else
// 				ns_ps2_transmitter = PS2_STATE_0_IDLE;
// 		end
// 	PS2_STATE_1_INITIATE_COMMUNICATION:
// 		begin
// 			if (command_initiate_counter == CLOCK_CYCLES_FOR_101US)
// 				ns_ps2_transmitter = PS2_STATE_2_WAIT_FOR_CLOCK;
// 			else
// 				ns_ps2_transmitter = PS2_STATE_1_INITIATE_COMMUNICATION;
// 		end
// 	PS2_STATE_2_WAIT_FOR_CLOCK:
// 		begin
// 			if (ps2_clk_negedge == 1'b1)
// 				ns_ps2_transmitter = PS2_STATE_3_TRANSMIT_DATA;
// 			else if (waiting_counter == CLOCK_CYCLES_FOR_15MS)
// 				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
// 			else
// 				ns_ps2_transmitter = PS2_STATE_2_WAIT_FOR_CLOCK;
// 		end
// 	PS2_STATE_3_TRANSMIT_DATA:
// 		begin
// 			if ((cur_bit == 4'd8) && (ps2_clk_negedge == 1'b1))
// 				ns_ps2_transmitter = PS2_STATE_4_TRANSMIT_STOP_BIT;
// 			else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
// 				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
// 			else
// 				ns_ps2_transmitter = PS2_STATE_3_TRANSMIT_DATA;
// 		end
// 	PS2_STATE_4_TRANSMIT_STOP_BIT:
// 		begin
// 			if (ps2_clk_negedge == 1'b1)
// 				ns_ps2_transmitter = PS2_STATE_5_RECEIVE_ACK_BIT;
// 			else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
// 				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
// 			else
// 				ns_ps2_transmitter = PS2_STATE_4_TRANSMIT_STOP_BIT;
// 		end
// 	PS2_STATE_5_RECEIVE_ACK_BIT:
// 		begin
// 			if (ps2_clk_posedge == 1'b1)
// 				ns_ps2_transmitter = PS2_STATE_6_COMMAND_WAS_SENT;
// 			else if (transfer_counter == CLOCK_CYCLES_FOR_2MS)
// 				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
// 			else
// 				ns_ps2_transmitter = PS2_STATE_5_RECEIVE_ACK_BIT;
// 		end
// 	PS2_STATE_6_COMMAND_WAS_SENT:
// 		begin
// 			if (send_command == 1'b0)
// 				ns_ps2_transmitter = PS2_STATE_0_IDLE;
// 			else
// 				ns_ps2_transmitter = PS2_STATE_6_COMMAND_WAS_SENT;
// 		end
// 	PS2_STATE_7_TRANSMISSION_ERROR:
// 		begin
// 			if (send_command == 1'b0)
// 				ns_ps2_transmitter = PS2_STATE_0_IDLE;
// 			else
// 				ns_ps2_transmitter = PS2_STATE_7_TRANSMISSION_ERROR;
// 		end
// 	default:
// 		begin
// 			ns_ps2_transmitter = PS2_STATE_0_IDLE;
// 		end
// 	endcase
// end
// 
// /*****************************************************************************
//  *                             Sequential logic                              *
//  *****************************************************************************/
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		ps2_command <= 9'h000;
// 	else if (s_ps2_transmitter == PS2_STATE_0_IDLE)
// 		ps2_command <= {(^the_command) ^ 1'b1, the_command};
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		command_initiate_counter <= {NUMBER_OF_BITS_FOR_101US{1'b0}};
// 	else if ((s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) &&
// 			(command_initiate_counter != CLOCK_CYCLES_FOR_101US))
// 		command_initiate_counter <= 
// 			command_initiate_counter + COUNTER_INCREMENT_FOR_101US;
// 	else if (s_ps2_transmitter != PS2_STATE_1_INITIATE_COMMUNICATION)
// 		command_initiate_counter <= {NUMBER_OF_BITS_FOR_101US{1'b0}};
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		waiting_counter <= {NUMBER_OF_BITS_FOR_15MS{1'b0}};
// 	else if ((s_ps2_transmitter == PS2_STATE_2_WAIT_FOR_CLOCK) &&
// 			(waiting_counter != CLOCK_CYCLES_FOR_15MS))
// 		waiting_counter <= waiting_counter + COUNTER_INCREMENT_FOR_15MS;
// 	else if (s_ps2_transmitter != PS2_STATE_2_WAIT_FOR_CLOCK)
// 		waiting_counter <= {NUMBER_OF_BITS_FOR_15MS{1'b0}};
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		transfer_counter <= {NUMBER_OF_BITS_FOR_2MS{1'b0}};
// 	else
// 	begin
// 		if ((s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) ||
// 			(s_ps2_transmitter == PS2_STATE_4_TRANSMIT_STOP_BIT) ||
// 			(s_ps2_transmitter == PS2_STATE_5_RECEIVE_ACK_BIT))
// 		begin
// 			if (transfer_counter != CLOCK_CYCLES_FOR_2MS)
// 				transfer_counter <= transfer_counter + COUNTER_INCREMENT_FOR_2MS;
// 		end
// 		else
// 			transfer_counter <= {NUMBER_OF_BITS_FOR_2MS{1'b0}};
// 	end
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		cur_bit <= 4'h0;
// 	else if ((s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) &&
// 			(ps2_clk_negedge == 1'b1))
// 		cur_bit <= cur_bit + 4'h1;
// 	else if (s_ps2_transmitter != PS2_STATE_3_TRANSMIT_DATA)
// 		cur_bit <= 4'h0;
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		command_was_sent <= 1'b0;
// 	else if (s_ps2_transmitter == PS2_STATE_6_COMMAND_WAS_SENT)
// 		command_was_sent <= 1'b1;
// 	else if (send_command == 1'b0)
// 			command_was_sent <= 1'b0;
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		error_communication_timed_out <= 1'b0;
// 	else if (s_ps2_transmitter == PS2_STATE_7_TRANSMISSION_ERROR)
// 		error_communication_timed_out <= 1'b1;
// 	else if (send_command == 1'b0)
// 		error_communication_timed_out <= 1'b0;
// end
// 
// /*****************************************************************************
//  *                            Combinational logic                            *
//  *****************************************************************************/
// 
// assign PS2_CLK	= 
// 	(s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) ? 
// 		1'b0 :
// 		1'bz;
// 
// assign PS2_DAT	= 
// 	(s_ps2_transmitter == PS2_STATE_3_TRANSMIT_DATA) ? ps2_command[cur_bit] :
// 	(s_ps2_transmitter == PS2_STATE_2_WAIT_FOR_CLOCK) ? 1'b0 :
// 	((s_ps2_transmitter == PS2_STATE_1_INITIATE_COMMUNICATION) && 
// 		(command_initiate_counter[NUMBER_OF_BITS_FOR_101US] == 1'b1)) ? 1'b0 : 
// 			1'bz;
// 
// /*****************************************************************************
//  *                              Internal Modules                             *
//  *****************************************************************************/
// 
// 
// endmodule


// ===== src/input_source/Altera_UP_PS2_Data_In.v =====
// /*****************************************************************************
//  *                                                                           *
//  * Module:       Altera_UP_PS2_Data_In                                       *
//  * Description:                                                              *
//  *      This module accepts incoming data from a PS2 core.                   *
//  *                                                                           *
//  *****************************************************************************/
// 
// 
// module Altera_UP_PS2_Data_In (
// 	// Inputs
// 	clk,
// 	reset,
// 
// 	wait_for_incoming_data,
// 	start_receiving_data,
// 
// 	ps2_clk_posedge,
// 	ps2_clk_negedge,
// 	ps2_data,
// 
// 	// Bidirectionals
// 
// 	// Outputs
// 	received_data,
// 	received_data_en			// If 1 - new data has been received
// );
// 
// 
// /*****************************************************************************
//  *                           Parameter Declarations                          *
//  *****************************************************************************/
// 
// 
// /*****************************************************************************
//  *                             Port Declarations                             *
//  *****************************************************************************/
// // Inputs
// input				clk;
// input				reset;
// 
// input				wait_for_incoming_data;
// input				start_receiving_data;
// 
// input				ps2_clk_posedge;
// input				ps2_clk_negedge;
// input			 	ps2_data;
// 
// // Bidirectionals
// 
// // Outputs
// output reg	[7:0]	received_data;
// 
// output reg		 	received_data_en;
// 
// /*****************************************************************************
//  *                           Constant Declarations                           *
//  *****************************************************************************/
// // states
// localparam	PS2_STATE_0_IDLE			= 3'h0,
// 			PS2_STATE_1_WAIT_FOR_DATA	= 3'h1,
// 			PS2_STATE_2_DATA_IN			= 3'h2,
// 			PS2_STATE_3_PARITY_IN		= 3'h3,
// 			PS2_STATE_4_STOP_IN			= 3'h4;
// 
// /*****************************************************************************
//  *                 Internal wires and registers Declarations                 *
//  *****************************************************************************/
// // Internal Wires
// reg			[3:0]	data_count;
// reg			[7:0]	data_shift_reg;
// 
// // State Machine Registers
// reg			[2:0]	ns_ps2_receiver;
// reg			[2:0]	s_ps2_receiver;
// 
// /*****************************************************************************
//  *                         Finite State Machine(s)                           *
//  *****************************************************************************/
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		s_ps2_receiver <= PS2_STATE_0_IDLE;
// 	else
// 		s_ps2_receiver <= ns_ps2_receiver;
// end
// 
// always @(*)
// begin
// 	// Defaults
// 	ns_ps2_receiver = PS2_STATE_0_IDLE;
// 
//     case (s_ps2_receiver)
// 	PS2_STATE_0_IDLE:
// 		begin
// 			if ((wait_for_incoming_data == 1'b1) && 
// 					(received_data_en == 1'b0))
// 				ns_ps2_receiver = PS2_STATE_1_WAIT_FOR_DATA;
// 			else if ((start_receiving_data == 1'b1) && 
// 					(received_data_en == 1'b0))
// 				ns_ps2_receiver = PS2_STATE_2_DATA_IN;
// 			else
// 				ns_ps2_receiver = PS2_STATE_0_IDLE;
// 		end
// 	PS2_STATE_1_WAIT_FOR_DATA:
// 		begin
// 			if ((ps2_data == 1'b0) && (ps2_clk_posedge == 1'b1))
// 				ns_ps2_receiver = PS2_STATE_2_DATA_IN;
// 			else if (wait_for_incoming_data == 1'b0)
// 				ns_ps2_receiver = PS2_STATE_0_IDLE;
// 			else
// 				ns_ps2_receiver = PS2_STATE_1_WAIT_FOR_DATA;
// 		end
// 	PS2_STATE_2_DATA_IN:
// 		begin
// 			if ((data_count == 3'h7) && (ps2_clk_posedge == 1'b1))
// 				ns_ps2_receiver = PS2_STATE_3_PARITY_IN;
// 			else
// 				ns_ps2_receiver = PS2_STATE_2_DATA_IN;
// 		end
// 	PS2_STATE_3_PARITY_IN:
// 		begin
// 			if (ps2_clk_posedge == 1'b1)
// 				ns_ps2_receiver = PS2_STATE_4_STOP_IN;
// 			else
// 				ns_ps2_receiver = PS2_STATE_3_PARITY_IN;
// 		end
// 	PS2_STATE_4_STOP_IN:
// 		begin
// 			if (ps2_clk_posedge == 1'b1)
// 				ns_ps2_receiver = PS2_STATE_0_IDLE;
// 			else
// 				ns_ps2_receiver = PS2_STATE_4_STOP_IN;
// 		end
// 	default:
// 		begin
// 			ns_ps2_receiver = PS2_STATE_0_IDLE;
// 		end
// 	endcase
// end
// 
// /*****************************************************************************
//  *                             Sequential logic                              *
//  *****************************************************************************/
// 
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1) 
// 		data_count	<= 3'h0;
// 	else if ((s_ps2_receiver == PS2_STATE_2_DATA_IN) && 
// 			(ps2_clk_posedge == 1'b1))
// 		data_count	<= data_count + 3'h1;
// 	else if (s_ps2_receiver != PS2_STATE_2_DATA_IN)
// 		data_count	<= 3'h0;
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		data_shift_reg			<= 8'h00;
// 	else if ((s_ps2_receiver == PS2_STATE_2_DATA_IN) && 
// 			(ps2_clk_posedge == 1'b1))
// 		data_shift_reg	<= {ps2_data, data_shift_reg[7:1]};
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		received_data		<= 8'h00;
// 	else if (s_ps2_receiver == PS2_STATE_4_STOP_IN)
// 		received_data	<= data_shift_reg;
// end
// 
// always @(posedge clk)
// begin
// 	if (reset == 1'b1)
// 		received_data_en		<= 1'b0;
// 	else if ((s_ps2_receiver == PS2_STATE_4_STOP_IN) &&
// 			(ps2_clk_posedge == 1'b1))
// 		received_data_en	<= 1'b1;
// 	else
// 		received_data_en	<= 1'b0;
// end
// 
// /*****************************************************************************
//  *                            Combinational logic                            *
//  *****************************************************************************/
// 
// 
// /*****************************************************************************
//  *                              Internal Modules                             *
//  *****************************************************************************/
// 
// 
// endmodule


// ===== src/vga/vga_display.v =====
// /* vga display specs: 
//     640 x 480 resolution (this is 1:1)
//     9 bit color depth == can make 512 colors in total
//                          3 bits for each RGB 
// 
// 
// */
// 
// module vga_display (
//     input clock, reset,
//     input [2:0] gamestate, playerfloor, guardfloor, moneyfloor, targetfloor,
//     input [2:0] currentfloor1, currentfloor2,
//     input busy1, busy2,
//     input [3:0] A, B,
//     input [1:0] operator,
//     output [2:0] VGA_R, VGA_G, VGA_B,
//     output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N
// );
//     localparam [2:0] START = 3'd0, SELECT = 3'd1, MATH = 3'd2,
//                      MOVING = 3'd3, WIN = 3'd4, LOSE = 3'd5;
//     // Packed RGB, three bits per channel.
//     localparam [8:0] BACKGROUND = 9'b000_000_001, PANEL = 9'b001_001_010,
//                      TEXT = 9'b111_111_111, PLAYER = 9'b001_110_101,
//                      GUARD = 9'b111_011_100, MONEY = 9'b111_110_011,
//                      ELEVATOR = 9'b011_101_111;
// 
//     wire [9:0] x, y;
//     vga_timing timing (
//         .clock(clock), .reset(reset), .VGA_CLK(VGA_CLK),
//         .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N),
//         .VGA_SYNC_N(VGA_SYNC_N), .x(x), .y(y)
//     );
// 
//     // Snapshot game signals once per frame; all use the same 50 MHz clock.
//     reg [2:0] state, player, guard, money, target, elevator1, elevator2;
//     reg moving1, moving2;
//     reg [3:0] operandA, operandB;
//     reg [1:0] operation;
//     always @(posedge clock) begin
//         if (!reset || (VGA_CLK && x == 10'd799 && y == 10'd524)) begin
//             state <= !reset ? START : gamestate;
//             player <= !reset ? 3'd0 : playerfloor;
//             guard <= !reset ? 3'd7 : guardfloor;
//             money <= !reset ? 3'd0 : moneyfloor;
//             target <= !reset ? 3'd0 : targetfloor;
//             elevator1 <= !reset ? 3'd0 : currentfloor1;
//             elevator2 <= !reset ? 3'd0 : currentfloor2;
//             moving1 <= reset && busy1;
//             moving2 <= reset && busy2;
//             operandA <= !reset ? 4'd0 : A;
//             operandB <= !reset ? 4'd0 : B;
//             operation <= !reset ? 2'd0 : operator;
//         end
//     end
// 
//     reg [127:0] status;
//     reg [7:0] opChar;
//     always @(*) begin
//         case (state)
//             START:  status = "PRESS SPACE     ";
//             SELECT: status = "PICK FLOOR 0-7  ";
//             MATH:   status = "SOLVE AND SUBMIT";
//             MOVING: status = "GOING TO FLOOR  ";
//             WIN:    status = "YOU WIN         ";
//             LOSE:   status = "GAME OVER       ";
//             default: status = "GET READY       ";
//         endcase
//         case (operation)
//             2'd0: opChar = "+";
//             2'd1: opChar = "-";
//             2'd2: opChar = "*";
//             default: opChar = " ";
//         endcase
//     end
// 
//     // Eight rows of 40 pixels, with floor 7 at the top.
//     wire [9:0] buildingY = y - 10'd112;
//     reg [2:0] floorNumber;
//     reg [5:0] rowY;
//     always @(*) begin
//         if (buildingY < 10'd40) begin floorNumber = 3'd7; rowY = buildingY; end
//         else if (buildingY < 10'd80) begin floorNumber = 3'd6; rowY = buildingY - 10'd40; end
//         else if (buildingY < 10'd120) begin floorNumber = 3'd5; rowY = buildingY - 10'd80; end
//         else if (buildingY < 10'd160) begin floorNumber = 3'd4; rowY = buildingY - 10'd120; end
//         else if (buildingY < 10'd200) begin floorNumber = 3'd3; rowY = buildingY - 10'd160; end
//         else if (buildingY < 10'd240) begin floorNumber = 3'd2; rowY = buildingY - 10'd200; end
//         else if (buildingY < 10'd280) begin floorNumber = 3'd1; rowY = buildingY - 10'd240; end
//         else begin floorNumber = 3'd0; rowY = buildingY - 10'd280; end
//     end
// 
//     reg [127:0] textLine;
//     reg [3:0] textIndex;
//     reg [9:0] textX, textY;
//     reg [8:0] color, ink;
//     wire [2:0] glyphX = textX[3:1];
//     wire [2:0] glyphY = textY[3:1];
//     wire [7:0] character = textLine[127 - 8 * textIndex -: 8];
//     wire glyphOn;
//     vga_font font (.character(character), .x(glyphX), .y(glyphY), .pixel(glyphOn));
// 
//     always @(*) begin
//         textLine = "                ";
//         textX = x;
//         textY = y;
//         color = BACKGROUND;
//         ink = TEXT;
//         if (x >= 10'd32 && x < 10'd608 && y >= 10'd112 && y < 10'd432) begin
//             color = rowY < 6'd2 ? BACKGROUND : PANEL;
//             if (rowY >= 6'd12 && rowY < 6'd28) begin
//                 textY = rowY - 6'd12;
//                 if (x >= 10'd64 && x < 10'd80)
//                     textLine[127:120] = 8'h30 + {5'd0, floorNumber};
//                 else if (x >= 10'd160 && x < 10'd176 && floorNumber == player) begin
//                     textLine[127:120] = "P"; ink = PLAYER;
//                 end else if (x >= 10'd256 && x < 10'd272 && floorNumber == guard) begin
//                     textLine[127:120] = "G"; ink = GUARD;
//                 end else if (x >= 10'd352 && x < 10'd368 && floorNumber == elevator1) begin
//                     textLine[127:120] = "1"; ink = moving1 ? ELEVATOR : TEXT;
//                 end else if (x >= 10'd448 && x < 10'd464 && floorNumber == elevator2) begin
//                     textLine[127:120] = "2"; ink = moving2 ? ELEVATOR : TEXT;
//                 end else if (x >= 10'd544 && x < 10'd560 && floorNumber == money &&
//                              state != START && state != 3'd6) begin
//                     textLine[127:120] = "$"; ink = MONEY;
//                 end
//                 textX = {6'd0, x[3:0]};
//             end
//         end else if (y >= 10'd24 && y < 10'd40 && x >= 10'd32 && x < 10'd288) begin
//             textLine = "ELEVATOR GAME   ";
//             textX = x - 10'd32;
//             textY = y - 10'd24;
//         end else if (y >= 10'd48 && y < 10'd64 && x >= 10'd32 && x < 10'd288) begin
//             textLine = status;
//             textX = x - 10'd32;
//             textY = y - 10'd48;
//             if (state == WIN) ink = PLAYER;
//             else if (state == LOSE) ink = GUARD;
//         end else if (y >= 10'd48 && y < 10'd64 && x >= 10'd320 && x < 10'd576) begin
//             textX = x - 10'd320;
//             textY = y - 10'd48;
//             if (state == MATH)
//                 textLine = {8'h30 + {4'd0, operandA}, " ", opChar, " ",
//                             8'h30 + {4'd0, operandB}, " = ?       "};
//             else if (state == MOVING)
//                 textLine[127:120] = 8'h30 + {5'd0, target};
//         end else if (y >= 10'd88 && y < 10'd104 && x >= 10'd64 && x < 10'd608) begin
//             textX = {6'd0, x[3:0]};
//             textY = y - 10'd88;
//             case (x[9:4])
//                 6'd4:  textLine[127:120] = "F";
//                 6'd10: begin textLine[127:120] = "P"; ink = PLAYER; end
//                 6'd16: begin textLine[127:120] = "G"; ink = GUARD; end
//                 6'd22: textLine[127:120] = "1";
//                 6'd28: textLine[127:120] = "2";
//                 6'd34: begin textLine[127:120] = "$"; ink = MONEY; end
//                 default: textLine[127:120] = " ";
//             endcase
//         end
//         textIndex = textX[7:4];
//     end
// 
//     assign {VGA_R, VGA_G, VGA_B} = VGA_BLANK_N ? (glyphOn ? ink : color) : 9'd0;
// endmodule


// ===== src/vga/vga_font.v =====
// // Five columns and seven rows per glyph, most significant bit at top left.
// module vga_font (input [7:0] character, input [2:0] x, y, output pixel);
//     reg [34:0] glyph;
//     always @(*) begin
//         case (character)
//             "0": glyph = 35'h3A33AE62E;
//             "1": glyph = 35'h11842108E;
//             "2": glyph = 35'h3A211111F;
//             "3": glyph = 35'h78213063E;
//             "4": glyph = 35'h08CA97C42;
//             "5": glyph = 35'h7E1E0862E;
//             "6": glyph = 35'h1910F462E;
//             "7": glyph = 35'h7C2222108;
//             "8": glyph = 35'h3A317462E;
//             "9": glyph = 35'h3A317844C;
//             "A": glyph = 35'h3A31FC631;
//             "B": glyph = 35'h7A31F463E;
//             "C": glyph = 35'h3A308422E;
//             "D": glyph = 35'h7A318C63E;
//             "E": glyph = 35'h7E10F421F;
//             "F": glyph = 35'h7E10F4210;
//             "G": glyph = 35'h3A30BC62F;
//             "H": glyph = 35'h4631FC631;
//             "I": glyph = 35'h38842108E;
//             "J": glyph = 35'h1C4214A4C;
//             "K": glyph = 35'h4654C5251;
//             "L": glyph = 35'h42108421F;
//             "M": glyph = 35'h4775AC631;
//             "N": glyph = 35'h4739ACE71;
//             "O": glyph = 35'h3A318C62E;
//             "P": glyph = 35'h7A31F4210;
//             "Q": glyph = 35'h3A318D64D;
//             "R": glyph = 35'h7A31F5251;
//             "S": glyph = 35'h3E107043E;
//             "T": glyph = 35'h7C8421084;
//             "U": glyph = 35'h46318C62E;
//             "V": glyph = 35'h46318C544;
//             "W": glyph = 35'h4631AD6AA;
//             "X": glyph = 35'h462A22A31;
//             "Y": glyph = 35'h462A21084;
//             "Z": glyph = 35'h7C222221F;
//             "+": glyph = 35'h0084F9080;
//             "-": glyph = 35'h0000F8000;
//             "*": glyph = 35'h02AEFBAA0;
//             "=": glyph = 35'h001F07C00;
//             "?": glyph = 35'h3A2221004;
//             "$": glyph = 35'h11F4717C4;
//             default: glyph = 35'd0;
//         endcase
//     end
//     assign pixel = (x < 3'd5 && y < 3'd7) ? glyph[34 - 5 * y - x] : 1'b0;
// endmodule


// ===== src/vga/vga_timing.v =====
// // 640 x 480 VGA timing at a 25 MHz pixel clock derived from CLOCK_50.
// module vga_timing (
//     input clock, reset,
//     output reg VGA_CLK,
//     output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N,
//     output reg [9:0] x, y
// );
//     always @(posedge clock) begin
//         if (!reset) begin
//             VGA_CLK <= 1'b0;
//             x <= 10'd0;
//             y <= 10'd0;
//         end else begin
//             VGA_CLK <= ~VGA_CLK;
//             // Change pixel data on the falling edge of VGA_CLK.
//             if (VGA_CLK) begin
//                 if (x == 10'd799) begin
//                     x <= 10'd0;
//                     if (y == 10'd524)
//                         y <= 10'd0;
//                     else
//                         y <= y + 10'd1;
//                 end else begin
//                     x <= x + 10'd1;
//                 end
//             end
//         end
//     end
// 
//     assign VGA_HS = !(x >= 10'd656 && x < 10'd752);
//     assign VGA_VS = !(y >= 10'd490 && y < 10'd492);
//     assign VGA_BLANK_N = x < 10'd640 && y < 10'd480;
//     assign VGA_SYNC_N = 1'b0;
// endmodule

