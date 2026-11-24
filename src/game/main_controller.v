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
output [7:0] VGA_R, VGA_G, VGA_B;
output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N;

// KEYBOARD CONNECTION WIRES

wire [7:0] receiveddata;
wire [0:0] receiveddataen, started, floorvalid, submit, correct, wrong, arrived, caught, move,check, newgame, newquestion, pickmoney;
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
math math1(.clock(CLOCK_50), .start(newquestion), .reset(KEY[0]), .playerans(finalanswer), .enter(check), .A(A), .B(B), .operator(operator), .correct(correct), .failed(), .wrong(wrong), .failcount(failcount));

// Assignment reserves a car for the whole trip, including stopped time.
wire [2:0] currentfloor1, currentfloor2, targetfloor1, targetfloor2;
wire [2:0] assignedFloor1, assignedFloor2;
wire busy1, busy2, reserved1, reserved2, move1, move2, assign1, assign2;
wire playerboard1, playerboard2, playerstopped, guardstopped;
wire requestAccepted;
wire roundActive = gamestate == 3'd1 || gamestate == 3'd2 || gamestate == 3'd3;

reg playerPending;
reg assignedPlayer;
wire [2:0] npcPickupFloor;
wire npcRequest;
wire requestValid = roundActive && (playerPending || npcRequest);
wire [2:0] requestedfloor = playerPending ? playerfloor : npcPickupFloor;

always @(posedge CLOCK_50) begin
    if (!KEY[0]) begin
        playerPending <= 1'b0;
        assignedPlayer <= 1'b0;
    end else begin
        if (!roundActive || (requestAccepted && assignedPlayer))
            playerPending <= 1'b0;
        if (move)
            playerPending <= 1'b1;
        // Match the request sampled by elevatorAssignment on this edge.
        if (requestValid && !requestAccepted)
            assignedPlayer <= playerPending;
    end
end

elevatorAssignment assignment1 (
    .clock(CLOCK_50), .reset(KEY[0]), .personfloor(requestedfloor),
    .requestValid(requestValid), .floorA(currentfloor1), .floorB(currentfloor2),
    .busyA(reserved1), .busyB(reserved2), .targetA(assignedFloor1),
    .targetB(assignedFloor2), .assignA(assign1), .assignB(assign2),
    .requestAccepted(requestAccepted)
);

wire [2:0] npcCurrent, npcDest;
wire npcSpawn, npcReady;
wire waiting1, waiting2, pickupBusy;
wire startPickup1 = waiting1 && !pickupBusy;
wire startPickup2 = waiting2 && !waiting1 && !pickupBusy;
reg pickupCar2;
wire [3:0] boardingCount;
wire [23:0] boardingDest;
wire pickupDone = boardingCount != 4'd0;

always @(posedge CLOCK_50) begin
    if (!KEY[0])
        pickupCar2 <= 1'b0;
    else if (startPickup1 || startPickup2)
        pickupCar2 <= startPickup2;
end

other_users npcs (
    .clock(CLOCK_50), .reset(KEY[0] && roundActive),
    .current(npcCurrent), .dest(npcDest), .requestValid(npcSpawn)
);
// When a floor is full, skip that spawn. The two-second cadence continues.
queue npcQueue (
    .clock(CLOCK_50), .reset(KEY[0]), .newcurr(npcCurrent), .dest(npcDest),
    .newreqvalid(npcSpawn && roundActive && npcReady), .newreqready(npcReady),
    .reqaccepted(requestAccepted && !assignedPlayer),
    .outcurr(npcPickupFloor), .outreqvalid(npcRequest),
    .pickupvalid(startPickup1 || startPickup2),
    .pickupfloor(startPickup1 ? currentfloor1 : currentfloor2),
    .boardingCount(boardingCount), .boardingDest(boardingDest), .pickupBusy(pickupBusy)
);

elevator_trip trip1 (
    .clock(CLOCK_50), .reset(KEY[0]), .assigned(assign1), .assignedPlayer(assignedPlayer),
    .assignedFloor(assignedFloor1), .playerDestination(targetfloor),
    .currentFloor(currentfloor1), .carBusy(busy1), .reserved(reserved1),
    .npcPickupWaiting(waiting1), .npcPickupStart(startPickup1),
    .npcPickupDone(pickupDone && !pickupCar2), .boardingCount(boardingCount),
    .boardingDest(boardingDest), .playerBoard(playerboard1),
    .carMove(move1), .carTarget(targetfloor1)
);
elevator_trip trip2 (
    .clock(CLOCK_50), .reset(KEY[0]), .assigned(assign2), .assignedPlayer(assignedPlayer),
    .assignedFloor(assignedFloor2), .playerDestination(targetfloor),
    .currentFloor(currentfloor2), .carBusy(busy2), .reserved(reserved2),
    .npcPickupWaiting(waiting2), .npcPickupStart(startPickup2),
    .npcPickupDone(pickupDone && pickupCar2), .boardingCount(boardingCount),
    .boardingDest(boardingDest), .playerBoard(playerboard2),
    .carMove(move2), .carTarget(targetfloor2)
);

elevatorcontroller e1 (
    .clk(CLOCK_50), .reset(KEY[0]), .move(move1), .targetfloor(targetfloor1),
    .currentfloor(currentfloor1), .busy(busy1)
);
elevatorcontroller e2 (
    .clk(CLOCK_50), .reset(KEY[0]), .move(move2), .targetfloor(targetfloor2),
    .currentfloor(currentfloor2), .busy(busy2)
);

playercontroller player (
    .clk(CLOCK_50), .reset(KEY[0]), .playerboard1(playerboard1),
    .playerboard2(playerboard2), .currentfloor1(currentfloor1),
    .currentfloor2(currentfloor2), .targetfloor(targetfloor),
    .playerfloor(playerfloor), .playerstopped(playerstopped), .arrived(arrived)
);
guardcontroller guard (
    .clk(CLOCK_50), .reset(KEY[0]), .guardstart(roundActive),
    .playerfloor(playerfloor), .guardfloor(guardfloor), .guardstopped(guardstopped)
);
collision collisionCheck (
    .playerfloor(playerfloor), .guardfloor(guardfloor),
    .playerstopped(playerstopped), .guardstopped(guardstopped), .caught(caught)
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

// Expand the 3-bit channels to cover the full DE1-SoC VGA DAC range.
wire [2:0] red9, green9, blue9;
assign VGA_R = {red9, red9, red9[2:1]};
assign VGA_G = {green9, green9, green9[2:1]};
assign VGA_B = {blue9, blue9, blue9[2:1]};

vga_display display (
    .clock(CLOCK_50), .reset(KEY[0]), .gamestate(gamestate),
    .playerfloor(playerfloor), .guardfloor(guardfloor), .moneyfloor(moneyfloor),
    .targetfloor(targetfloor), .currentfloor1(currentfloor1), .currentfloor2(currentfloor2),
    .busy1(reserved1), .busy2(reserved2), .A(A), .B(B), .operator(operator),
    .VGA_R(red9), .VGA_G(green9), .VGA_B(blue9), .VGA_CLK(VGA_CLK),
    .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N)
);

endmodule
