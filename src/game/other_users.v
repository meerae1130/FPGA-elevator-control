// this module is for periodically spawning people who shares the elevator with the player 
// one spawns every 2 seconds, random floor and random destination 

// i think we should have something like objects and classes 

// this would be a class, creating one user object, and later we make a queue basically in
// another module (linked list typa)


module other_users (clock, reset, current, dest, requestValid); 
    input clock, reset; 
    output reg [2:0] current, dest; // range [0,7] == 3 bits 
    output reg requestValid; 

    reg [26:0] twosec;  // 2 seconds counter, range: [0,27'd99999999]

    wire [5:0] lfsr_bits;
    wire [2:0] pickup_sample = lfsr_bits[2:0];
    wire [2:0] dest_sample = lfsr_bits[5:3];

    random rng (         
        .clock(clock),
        .reset(reset),
        .lfsr_bits(lfsr_bits)
    );

    always @(posedge clock) begin
        if (!reset) begin
            twosec       <= 27'd0;
            current      <= 3'd0;
            dest         <= 3'd0;
            requestValid <= 1'b0;

        end else begin
            requestValid <= 1'b0;

            if (twosec == 27'd99_999_999) begin
                twosec       <= 27'd0;
                current      <= pickup_sample;

                if (dest_sample == pickup_sample) begin
                    dest <= dest_sample + 3'd1;  // Floor 7 wraps to floor 0.
                end else begin
                    dest <= dest_sample;
                end

                requestValid <= 1'b1;
                
            end else begin
                twosec <= twosec + 27'd1;
            end
        end
    end

endmodule 
