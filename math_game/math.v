module mathgame (clock, reset, SW, KEY3, HEX3, HEX2, HEX1); 
    input clock, reset, KEY3; 
    input[7:0]SW;
    output [6:0] HEX3, HEX2, HEX1; 

    /*
        user will enter answer in 2 digit hexadecimal using switches 7:0
    */
    wire [3:0] A, B; 

    random ranA (clock, reset, A);
    random ranB (clock, reset, B); 

    // generated random 4 bit number A and B (0-9)
    

    // since random handles 0-9, for operation i want 3 variance 
    // just going to divide random by 3

    wire [2:0] rannumforoperation, operation;
    random ranoper (clock, reset, rannumforoperation); 

    assign operation = rannumforoperation/3; 

    // A is left operand 
    // B is right operand 
    // operation will be [2:0] either +,-,*, excluding / because then i have to take care of 
    // case where the denominator is 0 

    hex displayall (A, B, operation, HEX3, HEX2, HEX1); 

endmodule 

// generating random number of 4 bits
// shift register 
module random(clock, reset, randomNum);
    input clock, reset;
    output reg [3:0] randomNum;

    reg [15:0] lfsr;
    wire feedback;

    assign feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    // this either 0 or 1 feedback will be inserted into leftmost digit during shift to left 

    always @(posedge clock) begin
        if (!reset) begin
            lfsr <= 16'b0000000000000001;
            randomNum <= 4'd0;
        end
        else begin
            lfsr <= {lfsr[14:0], feedback};

            if (lfsr[3:0] < 4'd10)
                // keep previous state if lfsr is bigger than 9 
                // assign randomnum to lfsr if it is less than 9 
                randomNum <= lfsr[3:0];
        end
    end
endmodule



module hex(num1, num2, operation, HEX3, HEX2, HEX1);
    input[2:0] operation; 
    input[3:0] num1, num2; 

    output[6:0] HEX3, HEX2, HEX1;

    // HEX2 should display operation (+,-,*) not doing / because denominator cannot be 0 
    // + == half circle at the top
    // - == middle dash
    // * == H 

    // might have to just hook this up to vga 


endmodule 