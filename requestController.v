module requestController (clock, reset, floorInput, requestButton, requestAccepted, requestedFloor, requestValid);


/* 
    will handle all floor requests 

    - detect when someone presses the floor request button
    - store the requested floor
    - indicate that request pending
    - clear the request once elevator control module accepts it 
    - reset
    - do not move the elevator 
*/
// input output
input clock, reset, requestButton, requestAccepted;
input [2:0] floorInput; // 8 floors therefore 3 bits;

output reg [2:0] requestedFloor;
output reg requestValid;

// register to track previous button state
// detect when button is pressed, not when its being held down 
// neg edge is signal 
reg prev;

// floor request controller
// reset = 0 -> clear stored request
// reset = 1 -> continue as usual
always @(posedge clock) begin
    if(!reset) begin    // sync active low 
        requestedFloor <= 3'b000;
        requestValid <= 1'b0;
        prev <= 1'b1;
    end else begin
        // KEY[1] = 0 when pressed; detect falling edge
        prev <= requestButton;  // at rising clk edge, prev will recieve current button state 

        // store a request only if no request is pending
        // requestvalid == 1 : request alr pending
        // requestvalid ==0 , no pending 
        if(prev == 1'b1 && requestButton == 1'b0 && !requestValid) begin
            // if previous button state was 1 and current is 0
            requestedFloor <= floorInput;
            requestValid <= 1'b1;
        end else if(requestAccepted) begin
            // if another module from angela accepts the floor request
            // clear the flag so it will take inputs again 
            requestValid <= 1'b0;
        end
    end
end

endmodule
