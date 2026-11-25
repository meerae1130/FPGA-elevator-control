module collision(playerfloor, guardfloor, playerstopped, guardstopped, caught);

//purpose: detect if player and guard land stop on the same floor -> player loses and game ends

//INPUTS
//playerfloor = floor player is currently on, receive from playercontroller
//guardfloor = floor guard is currently on, receive from guardcontroller
//playerstopped = indicates whether the player is stopped, receive from playercontroller
// guardstopped = indicates whether guard is stopped, receive from guardcontroller

//OUTPUTS
  //caught = if both are stopped on same floor, caught = 1 and player loses, send to gamecontroller

input[0:0] playerstopped, guardstopped;
input[2:0] playerfloor, guardfloor;

output[0:0] caught;

//assign output
assign caught = ((playerfloor == guardfloor) && (playerstopped == 1) && (guardstopped == 1));


endmodule
