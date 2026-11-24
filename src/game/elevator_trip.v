// Reserves one car from dispatch through pickup and the final drop-off.
module elevator_trip #(
    parameter [25:0] PICKUP_CYCLES = 26'd50_000_000
) (
    input clock, reset,
    input assigned, assignedPlayer,
    input [2:0] assignedFloor, playerDestination, currentFloor,
    input carBusy,
    input npcPickupStart, npcPickupDone,
    input [3:0] boardingCount,
    input [23:0] boardingDest,
    output reserved, npcPickupWaiting, playerBoard,
    output reg carMove,
    output reg [2:0] carTarget
);
    localparam [2:0] IDLE = 3'd0, TO_PICKUP = 3'd1, WAIT_NPC = 3'd2,
                     BOARD_NPC = 3'd3, BOARD_PLAYER = 3'd4, NEXT_STOP = 3'd5,
                     TO_STOP = 3'd6;
    reg [2:0] state, pickupFloor;
    reg playerTrip;
    reg [25:0] boardingTimer;
    reg [3:0] stopsLeft;
    reg [23:0] stops;

    assign reserved = (state != IDLE) || assigned;
    assign npcPickupWaiting = state == WAIT_NPC;
    assign playerBoard = state == BOARD_PLAYER && boardingTimer == PICKUP_CYCLES - 26'd1;

    always @(posedge clock) begin
        if (!reset) begin
            state <= IDLE;
            pickupFloor <= 3'd0;
            playerTrip <= 1'b0;
            boardingTimer <= 26'd0;
            stopsLeft <= 4'd0;
            stops <= 24'd0;
            carMove <= 1'b0;
            carTarget <= 3'd0;
        end else begin
            carMove <= 1'b0;
            case (state)
                IDLE: if (assigned) begin
                    pickupFloor <= assignedFloor;
                    playerTrip <= assignedPlayer;
                    carTarget <= assignedFloor;
                    carMove <= 1'b1;
                    state <= TO_PICKUP;
                end
                TO_PICKUP: if (!carMove && !carBusy && currentFloor == pickupFloor) begin
                    boardingTimer <= 26'd0;
                    state <= playerTrip ? BOARD_PLAYER : WAIT_NPC;
                end
                WAIT_NPC: if (npcPickupStart)
                    state <= BOARD_NPC;
                BOARD_NPC: if (npcPickupDone) begin
                    stops <= boardingDest;
                    stopsLeft <= boardingCount;
                    state <= NEXT_STOP;
                end
                BOARD_PLAYER: if (playerBoard) begin
                    stops <= {21'd0, playerDestination};
                    stopsLeft <= 4'd1;
                    state <= NEXT_STOP;
                end else begin
                    boardingTimer <= boardingTimer + 26'd1;
                end
                NEXT_STOP: if (stopsLeft == 4'd0) begin
                    state <= IDLE;
                end else begin
                    carTarget <= stops[2:0];
                    carMove <= 1'b1;
                    stops <= stops >> 3;
                    stopsLeft <= stopsLeft - 4'd1;
                    state <= TO_STOP;
                end
                TO_STOP: if (!carMove && !carBusy && currentFloor == carTarget)
                    state <= NEXT_STOP;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
