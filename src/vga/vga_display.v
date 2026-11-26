/* vga display specs: 
    640 x 480 resolution (this is 1:1)
    9 bit color depth == can make 512 colors in total
                         3 bits for each RGB 

    this module basically decides the color of the pizel picked by the timing module 
*/

module vga_display (
    input clock, reset,
    input [2:0] gamestate, playerfloor, guardfloor, moneyfloor, targetfloor,
    input [2:0] currentfloor1, currentfloor2,
    input busy1, busy2, riding1, riding2,
    input [3:0] npcRiders1, npcRiders2,
    input [31:0] waitingCounts,
    input [3:0] A, B,
    input [1:0] operator,
    output [2:0] VGA_R, VGA_G, VGA_B,   // RGB combos 
    output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N 
    // exposes the pixel clock, horizontal sync, vertical sync, blanking, 
    // & sync outputs from vga_timing.
);
    localparam [2:0] START = 3'd0, SELECT = 3'd1, MATH = 3'd2,
                     MOVING = 3'd3, WIN = 3'd4, LOSE = 3'd5;
    // RGB, three bits per channel.

    // setting colors defaults 
    localparam [8:0] BACKGROUND = 9'b000_000_001, PANEL = 9'b001_001_010,
                     TEXT = 9'b111_111_111, PLAYER = 9'b001_110_101,
                     GUARD = 9'b111_011_100, MONEY = 9'b111_110_011,
                     ELEVATOR = 9'b011_101_111, NPC = 9'b111_000_000;

    wire [9:0] x, y;    // current scan coordinates 
    vga_timing timing (
        .clock(clock), .reset(reset), .VGA_CLK(VGA_CLK),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N), .x(x), .y(y)
    );

    // snapshot game signals once per frame 
    // all use same 50 clock.
    reg [2:0] state, player, guard, money, target, elevator1, elevator2;
    reg moving1, moving2, playerInA, playerInB;
    reg [3:0] ridersA, ridersB;
    reg [31:0] floorWaitingCounts;
    reg [3:0] operandA, operandB;
    reg [1:0] operation;
    /*
    reset == 0 == load the reset values. state becomes START, guard becomes floor 7, and the other registers become zero.
    reset == 1 and VGA_CLK == 1, x == 799, y == 524 == copy the live game inputs for the next frame
    reset == 1 at any other time == hold previous values
    */
    always @(posedge clock) begin
        if (!reset || (VGA_CLK && x == 10'd799 && y == 10'd524)) begin
            // condition ? a : b as “if the condition is true, choose a; otherwise, choose b.
            state <= !reset ? START : gamestate;
            player <= !reset ? 3'd0 : playerfloor;
            guard <= !reset ? 3'd7 : guardfloor;
            money <= !reset ? 3'd0 : moneyfloor;
            target <= !reset ? 3'd0 : targetfloor;
            elevator1 <= !reset ? 3'd0 : currentfloor1;
            elevator2 <= !reset ? 3'd0 : currentfloor2;
            moving1 <= reset && busy1;
            moving2 <= reset && busy2;
            playerInA <= reset && riding1;
            playerInB <= reset && riding2;
            ridersA <= !reset ? 4'd0 : npcRiders1;
            ridersB <= !reset ? 4'd0 : npcRiders2;
            floorWaitingCounts <= !reset ? 32'd0 : waitingCounts;
            operandA <= !reset ? 4'd0 : A;
            operandB <= !reset ? 4'd0 : B;
            operation <= !reset ? 2'd0 : operator;
        end
    end

    reg [127:0] status; // holds 16 chars
    // use for sentences 
    reg [7:0] opChar;   // holds 1 
    // use for operations 
    always @(*) begin
        case (state)
            START:  status = "PRESS SPACE     ";
            SELECT: status = "PICK FLOOR 0-7  ";
            MATH:   status = "SOLVE AND SUBMIT";
            MOVING: status = "GOING TO FLOOR  ";
            WIN:    status = "YOU WIN         ";
            LOSE:   status = "GAME OVER       ";
            default: status = "GET READY       ";
        endcase
        case (operation)
            2'd0: opChar = "+";
            2'd1: opChar = "-";
            2'd2: opChar = "*";
            default: opChar = " ";
        endcase
    end

    // 8 rows of 40 pixels, with floor 7 at the top.
    wire [9:0] buildingY = y - 10'd112; // distance down from the building’s top at screen y = 112
    reg [2:0] floorNumber; // the floor num 
    reg [5:0] rowY; //pixel’s height within that floors 40-pixel row
    /*
        0–39	7	buildingY
        40–79	6	buildingY - 40
        80–119	5	buildingY - 80
        120–159	4	buildingY - 120
        160–199	3	buildingY - 160
        200–239	2	buildingY - 200
        240–279	1	buildingY - 240
        280–319	0	buildingY - 280
    */
    always @(*) begin
        if (buildingY < 10'd40) begin floorNumber = 3'd7; rowY = buildingY; end
        else if (buildingY < 10'd80) begin floorNumber = 3'd6; rowY = buildingY - 10'd40; end
        else if (buildingY < 10'd120) begin floorNumber = 3'd5; rowY = buildingY - 10'd80; end
        else if (buildingY < 10'd160) begin floorNumber = 3'd4; rowY = buildingY - 10'd120; end
        else if (buildingY < 10'd200) begin floorNumber = 3'd3; rowY = buildingY - 10'd160; end
        else if (buildingY < 10'd240) begin floorNumber = 3'd2; rowY = buildingY - 10'd200; end
        else if (buildingY < 10'd280) begin floorNumber = 3'd1; rowY = buildingY - 10'd240; end
        else begin floorNumber = 3'd0; rowY = buildingY - 10'd280; end
    end

    // locating rlevaotr cars and their npcs 
    // each elevator car == a 32 x 32  
    // dots occupy two rows of four
    wire inShaftA = x >= 10'd224 && x < 10'd256;  // checks whether the pixel is in elevator A’s 32 pixel wide horizontal range
    wire inShaftB = x >= 10'd384 && x < 10'd416;  // same thing for B 
    wire carHere = (inShaftA && floorNumber == elevator1) || (inShaftB && floorNumber == elevator2);

    wire [4:0] carX = x[4:0]; //takes the lowest 5 bits of x, equivalent to x % 32 bc both start at multiples of 32 
    wire [5:0] carY = rowY - 6'd4;  // car starts 4 pixels below the top of its floor row

    wire carBorder = carX == 5'd0 || carX == 5'd31 ||carY == 6'd0 || carY == 6'd31;
    // detect4 edges of the square 

    wire carReserved = inShaftA ? moving1 : moving2; // select busy flag 
    wire playerInCar = inShaftA ? playerInA : playerInB; // select player in car flag
    wire [3:0] riderCount = inShaftA ? ridersA : ridersB;   // select count number of npc in that specific car 

    // using top half of the car == 2 rows of 4 npc slots, allowing 8
    // each slot == 8 x 8 pixl
    wire [3:0] dotIndex = {1'b0, carY[3], carX[4:3]};
    wire [2:0] dotX = carX[2:0];
    wire [2:0] dotY = carY[2:0];
    wire npcDot = carY < 6'd16 && dotIndex < riderCount &&
                  ((dotX == 3'd4 && dotY >= 3'd3 && dotY <= 3'd5) ||
                   (dotY == 3'd4 && dotX >= 3'd3 && dotX <= 3'd5));

    // The hall between cars has eight waiting spots on each floor.
    /*
        selects the current floor’s count from your packed waitingCounts bus. 
        +: 4 means: start at this bit and take four bits upward like ++4 
        on floor 3 the starting bit is 4 * 3 = 12, so this selects bits [15:12]
    */
    wire [3:0] floorWaiting = floorWaitingCounts[4 * floorNumber +: 4];
    wire waitingDot = x >= 10'd256 && x < 10'd384 && {1'b0, x[6:4]} < floorWaiting && ((x[3:0] == 4'd8 && rowY >= 6'd19 && rowY <= 6'd21) || (rowY == 6'd20 && x[3:0] >= 4'd7 && x[3:0] <= 4'd9));

    // turning text into pixels 
    // decides what colour to send to the monitor for the current pixel (x, y)
    // 1. picks the colour underneath the text. 
    // 2. checks whether a letter should cover that pixel.
    /*
        should: 
        start with color = BACKGROUND, a blank textLine, and white text (ink = TEXT) 
        -> if statements then change those defaults depending on where the pixel is
    */
    reg [127:0] textLine;
    reg [3:0] textIndex;
    reg [9:0] textX, textY; // coordinates relative to the text’s starting point
    reg [8:0] color, ink;   // underlying scene color, color of lettering respectively 
    wire [2:0] glyphX = textX[3:1];
    wire [2:0] glyphY = textY[3:1];
    wire [7:0] character = textLine[127 - 8 * textIndex -: 8];
    wire glyphOn;
    vga_font font (.character(character), .x(glyphX), .y(glyphY), .pixel(glyphOn));
    /*
        textLine = "                "	-> start with a blank text line
        textX = x and textY = y -> start with screen coordinates, text regions override these with local coordinates
        color = BACKGROUND	-> start with the background colour
        ink = TEXT	-> use white lettering unless a branch changes it.
    */
    always @(*) begin
        textLine = "                ";
        textX = x;
        textY = y;
        color = BACKGROUND;
        ink = TEXT;
        // 
        if (x >= 10'd32 && x < 10'd608 && y >= 10'd112 && y < 10'd432) begin

            // rectangles for each row/floor should be 8 
            if (rowY < 6'd2)
                color = BACKGROUND;
            else
                color = PANEL;

            // when the current pixel is inside the car 
            if (carHere && rowY >= 6'd4 && rowY < 6'd36) begin
                if (carBorder) begin
                    if (carReserved)    // occupied by somethihg
                        color = ELEVATOR;
                    else
                        color = TEXT;   // white border when the elevator is free
                end else begin          // pixel inside the car, awy from border 
                    color = BACKGROUND;
                end
                if (npcDot)             // theres npc 
                    color = NPC;        //red
                if (playerInCar && carX >= 5'd11 && carX < 5'd27 && carY >= 6'd16) begin
                    textLine[127:120] = "P";
                    textX = carX - 5'd11;
                    textY = carY - 6'd16;
                    ink = PLAYER;
                end
            end else if (waitingDot) begin  // npc in queue
                color = NPC;

                //which character to draw on a floor 
                /*
                    64–79	Floor number    every floor. adding 8'h30 converts the floor number to an ASCII digit
                    96–111	    P	        the player’s floor while the player is outside both elevators
                    128–143	    G	        guard’s floor
                    544–559	    $	        money floor when the state is neither START nor 3'd6
                */
            end else if (rowY >= 6'd12 && rowY < 6'd28) begin
                textY = rowY - 6'd12;
                textX = {6'd0, x[3:0]};
                if (x >= 10'd64 && x < 10'd80)
                    textLine[127:120] = 8'h30 + {5'd0, floorNumber};
                else if (x >= 10'd96 && x < 10'd112 && floorNumber == player &&
                         !playerInA && !playerInB) begin
                    textLine[127:120] = "P"; ink = PLAYER;
                end else if (x >= 10'd128 && x < 10'd144 && floorNumber == guard) begin
                    textLine[127:120] = "G"; ink = GUARD;
                end else if (x >= 10'd544 && x < 10'd560 && floorNumber == money &&
                             state != START && state != 3'd6) begin
                    textLine[127:120] = "$"; ink = MONEY;
                end
            end
        end else if (y >= 10'd24 && y < 10'd40 && x >= 10'd32 && x < 10'd288) begin
            textLine = "ELEVATOR GAME   ";
            textX = x - 10'd32;
            textY = y - 10'd24;
        end else if (y >= 10'd48 && y < 10'd64 && x >= 10'd32 && x < 10'd288) begin
            textLine = status;
            textX = x - 10'd32;
            textY = y - 10'd48;
            if (state == WIN) ink = PLAYER;
            else if (state == LOSE) ink = GUARD;
        end else if (y >= 10'd48 && y < 10'd64 && x >= 10'd320 && x < 10'd576) begin
            textX = x - 10'd320;
            textY = y - 10'd48;
            if (state == MATH)
                textLine = {8'h30 + {4'd0, operandA}, " ", opChar, " ",
                            8'h30 + {4'd0, operandB}, " = ?       "};
            else if (state == MOVING)
                textLine[127:120] = 8'h30 + {5'd0, target};
        end
        textIndex = textX[7:4];
    end

    assign {VGA_R, VGA_G, VGA_B} = VGA_BLANK_N ? (glyphOn ? ink : color) : 9'd0;
endmodule
