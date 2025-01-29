`default_nettype none

module player_physics #(
  parameter INITIAL_JUMP_VELOCITY = 0,
  parameter DOWNWARD_ACCELERATION = 0,
  parameter DUCKING_DOWNWARD_ACCELERATION = 0,
) (
  input clk,
  input [1:0] game_tick, // [0] pulses, and then [1] pulses on following clock cycle
  input jump_pulse,      // high for one clock cycle at start of jump (set initial velocity)
  input button_down,     // high if down button is pressed
  output jump_done,      // not(msb of adder) -- only sampled when game_tick_en[1] == 1
  output [7:0] position,
);

  reg [$clog2(INITIAL_JUMP_VELOCITY):0] velocity
  // 2s complement negative position
  // sign bit -- (0 on ground, 1 in air)

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
          else if (game_tick[0] && !button_down) game_state <= DUCKING;
          else                                   game_state <= RUNNING;
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
