`default_nettype none

module player_physics #(
  parameter INITIAL_JUMP_VELOCITY = 8'h00,
  parameter DOWNWARD_ACCELERATION = 8'h00,
  parameter FASTDROP_VELOCITY = 8'h00,
) (
  input clk,
  input reset,
  input [1:0] game_tick, // enable for the FF that stores result of velocity [0] and position [1]
  input jump_pulse,      // high for one clock cycle at start of jump (set initial velocity)
  input button_down,     // high if down button is pressed
  output wire jump_done,      // not(msb of adder) -- only sampled when game_tick[1] == 1
  output reg [7:0] position,
);

  // reg [$clog2(INITIAL_JUMP_VELOCITY):0] calc_velocity;

  wire [7:0] adder_in1, adder_in2, adder_res;
  reg [7:0] velocity;
  wire [7:0] active_vel;

  // If player presses down, override velocity calculated by gravity with FASTDROP_VELOCITY
  assign active_vel = (button_down) ? (FASTDROP_VELOCITY) : velocity;

  // game_tick[1] == 0 means calculating velocity, game_tick[1] == 1 means calculating position
  assign adder_in1 = (game_tick[1]) ? (active_vel) : (DOWNWARD_ACCELERATION);
  assign adder_in2 = (game_tick[1]) ? (position) : (velocity);
  assign adder_res = adder_in1 + adder_in2;

  // Only sampled when game_tick[1] == 1, so jump_done == 1 when calculated position overflows
  assign jump_done = (~adder_res[7] & ~reset);

  always @ (posedge clk) begin
    if (reset) begin
      velocity <= 8'h00;
      position <= 8'h00;  // Replace with ground position
    end else if (jump_pulse) begin
      velocity <= INITIAL_JUMP_VELOCITY;
      position <= 8'h00;  // Replace with ground position
    end

    if (game_tick[0]) 
      velocity <= adder_res;
    
    if (game_tick[1]) begin
      position <= adder_res;
      if (~adder_res[7])
        position[7:0] <= 8'h00  // Replace with ground position
    end
  end

endmodule

module player_controller #(
  parameter INITIAL_JUMP_VELOCITY = 0,
  parameter ACCELERATION = 0,
  parameter SPEED_DROP_ACCELERATION = 0,
) (
  input clk,
  input reset,
  input [1:0] game_tick,
  input button_up,
  input button_down,
  input crash,
  output reg [7:0] player_position,
  output reg game_start_pulse,
  output reg game_over_pulse,
  output reg jump_pulse,
  output reg jumping,
  output reg ducking,
);

  localparam RESTART    = 3'b000;
  localparam JUMPING    = 3'b001;
  localparam RUNNING    = 3'b010;
  localparam DUCKING    = 3'b011;
  localparam GAME_OVER  = 3'b100;

  wire jump_done;

  reg [2:0] game_state;

  always @(posedge(clk)) begin
    if (reset) begin
      current_state <= 3'b000;
    end else begin
      case (current_state)
        RESTART: begin
          else if (game_tick[0] &&  button_up  ) game_state <= JUMPING;
          else                                   game_state <= RESTART;
        end
        JUMPING: begin
          if      (game_tick[0] &&  crash      ) game_state <= GAME_OVER;
          else if (game_tick[1] &&  jump_done  ) game_state <= RUNNING;
          else                                   game_state <= JUMPING;
        end
        RUNNING: begin
          if      (game_tick[0] &&  crash      ) game_state <= GAME_OVER;
          else if (game_tick[0] &&  button_down) game_state <= DUCKING;
          else if (game_tick[0] &&  button_up  ) game_state <= JUMPING;
          else                                   game_state <= RUNNING;
        end
        DUCKING: begin
          if      (game_tick[0] &&  crash      ) game_state <= GAME_OVER;
          else if (game_tick[0] && !button_down) game_state <= RUNNING;
          else                                   game_state <= DUCKING;
        end
        GAME_OVER: begin
          if      (game_tick[0] &&  button_up  ) game_state <= RUNNING;
          else                                   game_state <= GAME_OVER;
        end
      endcase
    end
  end

  player_physics u_player_physics #(
    .INITIAL_JUMP_VELOCITY(0),
    .ACCELERATION(0),
    .SPEED_DROP_ACCELERATION(0),
  ) (
    .clk(clk),
    .reset(reset),
    .game_tick(game_tick),
    .jump_pulse(jump_pulse),
    .button_down(button_down),
    .jump_done(jump_done),
    .position(position),
  );

  assign game_start_pulse = (game_state == RESTART   && game_tick[0] && button_up);
  assign game_over_pulse  = (game_state != GAME_OVER && game_tick[0] && button_up);
  assign jump_pulse       = (game_state == RUNNING   && game_tick[0] && button_up);

  assign jumping = (game_state == RUNNING);
  assign ducking = (game_state == DUCKING);

endmodule
