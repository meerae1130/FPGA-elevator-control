
module playercontroller(clk, reset, playerboard1, playerboard2, currentfloor1, currentfloor2, targetfloor, playerfloor, playerstopped, arrived, riding1, riding2);

//purpose: track player floor and which elevator the player is riding

//INPUTS
// clk = clock
// reset = active low reset, player starts at floor 0
// playerboard1 = player boards elevator 1
// playerboard2 = player boards elevator 2
// currentfloor1 = elevator 1 current floor
// currentfloor2 = elevator 2 current floor
// targetfloor = player's destination floor

//OUTPUTS
// playerfloor = player's current floor
// playerstopped = 1 when player is not riding
// arrived = 1 for one clock cycle when player reaches destination

input[0:0] clk, reset, playerboard1, playerboard2;
input[2:0] currentfloor1, currentfloor2, targetfloor;

output reg[2:0] playerfloor;
output[0:0] playerstopped;
output reg[0:0] arrived;
output riding1, riding2;

//PLAYER STATE FSM
parameter[1:0] waiting = 2'b00, elevator1 = 2'b01, elevator2 = 2'b10;

reg[1:0] currentstate;

always @(posedge clk) begin

    if(!reset) begin
        currentstate <= waiting;
        playerfloor <= 3'd0;
        arrived <= 0;
    end else begin

        arrived <= 0; //ny default

        case(currentstate)

        waiting: begin
            if(playerboard1 == 1) begin
                currentstate <= elevator1;
                playerfloor <= currentfloor1;
            end else if(playerboard2 == 1) begin
                currentstate <= elevator2;
                playerfloor <= currentfloor2;
            end
        end

        elevator1: begin
            playerfloor <= currentfloor1;

            if(currentfloor1 == targetfloor) begin
                currentstate <= waiting;
                arrived <= 1;
            end
        end

        elevator2: begin
            playerfloor <= currentfloor2;

            if(currentfloor2 == targetfloor) begin
                currentstate <= waiting;
                arrived <= 1;
            end
        end

        default: currentstate <= waiting;

        endcase
    end
end

//OUTPUT LOGIC
assign playerstopped = (currentstate == waiting);
assign riding1 = (currentstate == elevator1);
assign riding2 = (currentstate == elevator2);

endmodule
