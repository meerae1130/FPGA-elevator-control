module keyboardcontroller(receiveddata, receiveddataen, clk, reset, gamestate, started, floorinput, floorvalid, submit, finalanswer);

//purpose: turn input from keyboard into signals for our modules

//SIGNALS: (keyboard = meaning)
// space (starting screen) =  start the game
// enter (to enter a math answer) = submit the answer
// #'s 0 to 7 = floor # requested by user


// how it works:
// ps/2 controller (given module) receives electric signals through cable from keyboard and turns it into a code
// keyboardcontroller then takes that code and turns it into our input signals for gamecontroller

//INPUTS
//inputs given by ps/2 module:
//received_data = tells us WHAT the code sent by user on keyboard is
// received_data_en = tells us WHEN the code is sent

//clk = timing
// reset = active low
// gamestate = tells which part of game we are in

//OUTPUTS
//started = tells gamemcontroller to start the game
// floorinput = to store the requested floor selected by player
//floorvalid = tells us that a valid floor # is selected by user
//submit = tells us that the player used enter to submit their math answer
// answer = tells us the answer that the user puts for the math question

input [0:0] clk, reset, receiveddataen;
input [7:0] receiveddata;
input [2:0] gamestate;


output reg [0:0] started, floorvalid;
output reg[0:0] submit;
output reg [2:0] floorinput;
output reg signed [7:0] finalanswer; // signed for pos or neg

//RESET AND GETTING CODE LOGIC
reg[7:0] getcode; //stores code received from ps2 board
reg[0:0] keyReleased; // track if release or not


always @(posedge clk) begin
    if(!reset) begin

    getcode <= 8'b00000000;
    keyReleased <= 0;
       
    end else begin
        if(receiveddataen == 1) begin
           

            // KEY RELEASE LOGIC
            // needed so that controller doesn't count user input twice

            // ie: 5 sends code 2E, user releases 5, sends code F0 and 2E, needs to recognize 2E isnt another 5 input
            // (F0 is the release signal for any key)

            if(receiveddata == 8'hF0 && keyReleased == 0) begin
                keyReleased <= 1; // raise flag
            end else if(receiveddata != 8'hF0 && keyReleased == 1)begin //if flag was already raised reset to 0
                keyReleased <= 0;
            end else  if(receiveddata != 8'hF0 && keyReleased == 0) begin // if not after a release , store
                 getcode <= receiveddata;
            end

        end
    end 
end 

// DECODE LOGIC
// turn codes to numbers 

reg[3:0] digit; // 4 bits for 0 to 9
reg [0:0] valid; // flag for if a new digit is entered

always @(posedge clk) begin
    
    if (!reset) begin
        digit <= 4'd0;
        valid <= 0;
    end else begin

valid <= 0; // default

        if(receiveddataen && !keyReleased && gamestate == 3'd2) begin
            
               case(receiveddata)
    
    8'h45: begin digit <= 4'd0; 
    valid <= 1; end
    8'h16: begin digit <= 4'd1;
    valid <= 1; end
    8'h1E: begin digit <= 4'd2;
    valid<=1; end
    8'h26: begin digit <= 4'd3;
    valid <=1; end
    8'h25: begin digit <= 4'd4;
    valid <=1; end
    8'h2E: begin digit <= 4'd5;
    valid <=1; end
    8'h36: begin digit <= 4'd6;
    valid<=1; end
    8'h3D: begin digit <=4'd7;
    valid<=1; end
    8'h3E: begin digit <= 4'd8;
    valid <=1; end
    8'h46: begin digit <= 4'd9;
    valid <=1; end
    default: digit <= digit;

    endcase
        end
    end
end

// An explicit digit is required, even when the answer is zero.
reg signed [7:0] answer;
reg hasDigit, sign;
wire mathKey = receiveddataen && !keyReleased;
wire enterKey = mathKey && receiveddata == 8'h5A;
wire signed [7:0] appendedAnswer = (answer > 8'sd9) ? 8'sd127
                                                    : answer * 8'sd10 + $signed({4'd0, digit});
wire signed [7:0] submittedAnswer = valid ? appendedAnswer : answer;

always @(posedge clk) begin
    submit <= 1'b0;
    if (!reset || gamestate != 3'd2) begin
        answer <= 8'sd0;
        hasDigit <= 1'b0;
        sign <= 1'b0;
        finalanswer <= 8'sd0;
    end else if (enterKey) begin
        if (hasDigit || valid) begin
            finalanswer <= sign ? -submittedAnswer : submittedAnswer;
            submit <= 1'b1;
        end
        answer <= 8'sd0;
        hasDigit <= 1'b0;
        sign <= 1'b0;
    end else begin
        if (valid) begin
            answer <= appendedAnswer;
            hasDigit <= 1'b1;
        end
        if (mathKey && receiveddata == 8'h4E)
            sign <= 1'b1;
    end
end

// FLOOR SELECTION LOGIC

always@ (posedge clk)begin
   
    if(!reset) begin
        floorinput <= 3'b000;
        floorvalid <= 0;
    end else begin 

         floorvalid <= 0; //reset to 0 every clock cycle so it doesnt keep signaling a new selection
        
        if(gamestate == 3'b001 && receiveddataen == 1 && keyReleased == 0)
          
          case(receiveddata)
   
    8'h45: begin floorinput <= 3'd0; 
    floorvalid <= 1; end
    8'h16: begin floorinput <= 3'd1;
    floorvalid <= 1; end
    8'h1E: begin floorinput <= 3'd2;
    floorvalid<=1; end
    8'h26: begin floorinput <= 3'd3;
    floorvalid <=1; end
    8'h25: begin floorinput <= 3'd4;
    floorvalid <=1; end
    8'h2E: begin floorinput <= 3'd5;
    floorvalid <=1; end
    8'h36: begin floorinput <= 3'd6;
    floorvalid<=1; end
    8'h3D: begin floorinput <=3'd7;
    floorvalid<=1; end

    default: floorvalid<= 0;
          endcase
        
    end
end

// STARTING GAME LOGIC
// starts when spacebar is pushed -> 8'h29

always @(posedge clk)begin
    if(!reset)begin
        started <= 0;
    end else begin
    started <=0;
    if(receiveddata == 8'h29 && receiveddataen == 1 && keyReleased == 0 && gamestate == 3'b000)
        started <=1;
    end
end
endmodule
