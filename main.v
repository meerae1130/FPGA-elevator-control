// main game controller module 
module main_controller ();
    // money floor randomization 
    wire [3:0] rando;
    reg  [2:0] money;   // since floor 1-8, 3 bits enough to express 8 diff floors (0-7)

    random rng (        // instantiating using random.v module 
        .clock(clock),
        .reset(reset),
        .outputnum(rando)
    );




    // copy ur main module here 
    // also in your main fsm, after idle, insert a state called pickfloor 
    // next state after pickfloor == start game or smth 
    // and insert this below in ur reset and pickfloor case: 
    // not literal copy and paste but integrate it yk

    if (!reset) begin
        money <= 3'd0;
    end
    case(y)
        pickfloor: 
            money <= rando [2:0];

    endcase

endmodule