// math game 
module math (clock, start, reset, playerans, enter, A, B, operator, correct, failed, wrong, failcount);
    input clock, start, reset, enter;
    input signed [7:0] playerans; // -9 to 81 == 8 bits required minimally to express all numbers in set 

    // start will be 1 when user requests elevator (at KEY1 or equivalent)

    output reg correct, failed;     // user entered correct answer? / 3 consecutive fails? 
    output reg wrong;
    output reg [1:0] failcount;
    output reg [3:0] A, B;          // random number A, B for displaying in other modules
    output reg [1:0] operator;      // random operator, for displaying in other modules 


    reg [2:0] y;                    // current state 3 flipflops 
    wire [3:0] rando;               // will store random number from random module 

    random rng (
        .clock(clock),
        .reset(reset),
        .outputnum(rando)
    );

    reg signed [7:0] ans;           // correct answer, player's has to match this 

    parameter                       // 6 states -> 3bits minimally req. therefore 3 ff
        idle = 3'b000, 
        setA = 3'b001,
        setB = 3'b010, 
        setop = 3'b011, 
        calc = 3'b100, 
        waitans = 3'b101;

    always @(posedge clock) begin 
        if (!reset) begin           // low sync reset 
            y <= idle; 
            A <= 4'b0000;
            B <= 4'b0000;
            operator <= 2'b00;
            correct <= 1'b0;
            wrong <= 1'b0;
            failcount <= 2'b00;
            failed <= 1'b0;

        end else begin
            wrong <= 1'b0;
            case (y) 
                idle: begin
                    if (start && !failed) begin
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
                    end else begin  // when operator is 2 
                        ans <= A * B; 
                    end
                    y <= waitans;
                end
                waitans: begin
                    if (enter) begin 
                        if (playerans == ans) begin 
                            // condition: player got the correct answer 
                            y <= idle;

                            // return correct 
                            correct <= 1'b1;
                            failcount <= 2'b00;   // reset when fail streak lost
                        end else begin
                            wrong <= 1'b1;
                            failcount <= failcount + 2'd1;
                            if (failcount == 2'd2)
                                failed <= 1'b1;
                            y <= idle;
                        end
                    end 
                    
                end
            endcase

        end 
    end 

endmodule
