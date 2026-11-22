module main_controller(CLOCK_50, KEY, PS2_CLK, PS2_DAT,
                       VGA_R, VGA_G, VGA_B, VGA_CLK, VGA_HS, VGA_VS,
                       VGA_BLANK_N, VGA_SYNC_N);

//purpose: to connect all modules together

//INPUTS
// CLOCK_50 = drives all our clocks
// KEY = key[0] will be reset
//keyboard signals:
// PS2_CLK = keyboard clock
// PS2_DAT = keyboard data

input CLOCK_50;
inout PS2_CLK, PS2_DAT;
input [3:0] KEY;
output [2:0] VGA_R, VGA_G, VGA_B;
output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N;

// KEYBOARD CONNECTION WIRES

wire [7:0] receiveddata;
wire [0:0] receiveddataen, started, floorvalid, submit, correct, wrong, arrived, caught, move,check, newgame, newquestion, pickmoney, failed;
wire [2:0] gamestate, floorinput, playerfloor, guardfloor, moneyfloor, targetfloor;
wire[1:0] failcount, operator;
wire [3:0] A, B;
wire signed [7:0] finalanswer;

// INSTATIATION OF PS2 CONTROLLER MODULE
PS2_Controller ps2(.CLOCK_50(CLOCK_50), .reset(~KEY[0]), .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT), .received_data(receiveddata), .received_data_en(receiveddataen), .the_command(8'b00000000), .send_command(1'b0));
// not using thecommand and sendcommand so just set to const numbers

//CONNECT PS2 TO KEYBOARDCONTROLLER MODULE
keyboardcontroller keyboard(.receiveddata(receiveddata), .receiveddataen(receiveddataen), .clk(CLOCK_50), .reset(KEY[0]), .gamestate(gamestate), .started(started), .floorinput(floorinput), .floorvalid(floorvalid), .submit(submit), .finalanswer(finalanswer));

//CONNECT GAMECOTROLLER MODULE TO KEYOARDCONTROLLER MODULE
gamecontroller game(.clk(CLOCK_50), .reset(KEY[0]), .started(started), .floorinput(floorinput), .floorvalid(floorvalid), .correct(correct), .wrong(wrong), .arrived(arrived), .submit(submit), .caught(caught), .failcount(failcount), .playerfloor(playerfloor), .guardfloor(guardfloor), .moneyfloor(moneyfloor), .gamestate(gamestate), .targetfloor(targetfloor), .check(check), .newgame(newgame), .newquestion(newquestion), .pickmoney(pickmoney), .move(move));

//CONNECT MATH MODULE
math math1(.clock(CLOCK_50), .start(newquestion), .reset(KEY[0]), .playerans(finalanswer), .enter(check), .A(A), .B(B), .operator(operator), .correct(correct), .failed(failed));
//to change once signals wrong and failcount added

// INSTATIATION OF 2 ELEVATORS (shared by player, guard and npcs)
wire[2:0] currentfloor1, currentfloor2, targetfloor1, targetfloor2;
wire[1:0] direction1, direction2;
wire [0:0] arrival1, arrival2, playerstopped1, playerstopped2, busy1, busy2, move1, move2;

        //for elevator 1
    elevatorcontroller e1(.clk(CLOCK_50), .reset(KEY[0]),.move(move1), .targetfloor(targetfloor1), .currentfloor(currentfloor1), .elevatordirection(direction1), .arrival(arrival1), .playerstopped(playerstopped1), .busy(busy1));
    elevatorcontroller e2(.clk(CLOCK_50), .reset(KEY[0]),.move(move2), .targetfloor(targetfloor2), .currentfloor(currentfloor2), .elevatordirection(direction2), .arrival(arrival2), .playerstopped(playerstopped2), .busy(busy2));

// CONNECT ELEVATORASSIGNMENT MODULE
wire [2:0] requestedfloor;
wire requestvalid, requestAccepted;
elevatorAssignment assignment1(.clock(CLOCK_50), .reset(KEY[0]), .personfloor(requestedfloor), .requestValid(requestvalid), .floorA(currentfloor1), .floorB(currentfloor2), .busyA(busy1), .busyB(busy2), .targetA(targetfloor1), .targetB(targetfloor2), .assignA(move1), .assignB(move2), .requestAccepted(requestAccepted));

wire roundActive = gamestate == 3'd1 || gamestate == 3'd2 || gamestate == 3'd3;
wire guardstopped;
guardcontroller guard (
    .clk(CLOCK_50), .reset(KEY[0]), .guardstart(roundActive),
    .playerfloor(playerfloor), .guardfloor(guardfloor), .guardstopped(guardstopped)
);

wire [5:0] moneyRandomBits;
reg [2:0] savedMoneyFloor;
random moneyRandom (.clock(CLOCK_50), .reset(KEY[0]), .lfsr_bits(moneyRandomBits));
always @(posedge CLOCK_50) begin
    if (!KEY[0])
        savedMoneyFloor <= 3'd0;
    else if (pickmoney)
        savedMoneyFloor <= moneyRandomBits[2:0];
end
assign moneyfloor = savedMoneyFloor;

vga_display display (
    .clock(CLOCK_50), .reset(KEY[0]), .gamestate(gamestate),
    .playerfloor(playerfloor), .guardfloor(guardfloor), .moneyfloor(moneyfloor),
    .targetfloor(targetfloor), .currentfloor1(currentfloor1), .currentfloor2(currentfloor2),
    .busy1(busy1), .busy2(busy2), .A(A), .B(B), .operator(operator),
    .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_CLK(VGA_CLK),
    .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N)
);

//add rest tmrw

endmodule
