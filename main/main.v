// math game 
module math (clock, start, reset, playerans, enter, A, B, operator, correct);
    input clock, start, reset, enter;
    input signed [7:0] playerans; // -9 to 81 == 8 bits required minimally to express all numbers in set 

    // start will be 1 when user requests elevator 

    output reg correct; 
    output reg [3:0] A, B;
    output reg [1:0] operator; 

    
    reg [2:0] y; 
    wire [3:0] rando; 
    random inst (clock, reset, rando);

    reg signed [7:0] ans; 

    parameter
        idle = 3'b000, 
        setA = 3'b001,
        setB = 3'b010, 
        setop = 3'b011, 
        calc = 3'b100, 
        waitans = 3'b101;

    always @(posedge clock) begin 
        if (!reset) begin
            y <= idle; 
            A <= 4'b0000;
            B <= 4'b0000;
            operator <= 2'b00;
            correct <= 1'b0; 
        end else begin 
            case (y) 
                idle: begin
                    if (start) begin
                        y <= setA; 
                    end
                    correct <= 1'b0;
                end

                setA: begin
                    A <= rando;
                    y <= setB;
                end

                setB: begin
                    B <= rando; 
                    y <= setop;

                end 
                setop: begin
                    operator <= rando%3;
                    y <= calc; 

                end
                calc: begin
                    if (operator == 2'd0) begin 
                        ans <= A + B;
                    end else if (operator == 2'd1) begin
                        ans <= A - B; 
                    end else begin  // when operator is 3 
                        ans <= A * B; 
                    end
                    y <= waitans;
                end
                waitans: begin
                    if (enter && (playerans == ans)) begin 
                        y <= idle;

                        // return correct 
                        correct <= 1'b1;
                    end else begin
                        // return incorrect 
                        correct <= 1'b0;

                    end
                end
            endcase

        end 
    end 

endmodule

// random number generating shift register 
// will only generate number between 0 and 9, inclusive 
module random (clock, reset, outputnum);
    input clock, reset;
    output reg [3:0] outputnum;

    reg [15:0] lfsr;
    wire feedback;

    assign feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    // this either 0 or 1 feedback will be inserted into rightmost digit during shift to left 

    always @(posedge clock) begin
        if (!reset) begin
            lfsr <= 16'b0000000000000001;
            outputnum <= 4'd0;
        end
        else begin
            lfsr <= {lfsr[14:0], feedback};

            if (lfsr[3:0] < 4'd10)
                // keep previous state if lfsr is bigger than 9 
                // assign randomnum to lfsr if it is less than 9 
                outputnum <= lfsr[3:0];
        end
    end
endmodule