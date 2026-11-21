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