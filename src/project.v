/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_player_group (
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_oe  = 8'hFF;
  assign uio_out = 8'h00;

  assign uo_out[7:6]  = 2'b00;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:6], uio_in};

  wire [1:0] debounced_buttons;
  wire button_up, button_down;

  genvar i;
  for (i = 0; i < 2; i = i + 1) begin
    button_debounce u_debounce(
      .clk(clk),
      .reset_n(rst_n),
      .countdown_en(ui_in[2]),
      .button_in(ui_in[i]),
      .button_out(debounced_buttons[i])
    );
  end

  assign button_up   = debounced_buttons[0];
  assign button_down = debounced_buttons[1];

  wire [5:0] player_position;

  player_controller u_player(
    .clk(clk),
    .reset_n(rst_n),
    .game_tick({ui_in[3], ui_in[4]}),
    .button_up(button_up),
    .button_down(button_down),
    .crash(ui_in[5]),
    .player_position(player_position),
    .game_start_pulse(uo_out[1]),
    .game_over_pulse(uo_out[2]),
    .jump_pulse(uo_out[3]),
    .jumping(uo_out[4]),
    .ducking(uo_out[5])
  );

  assign uo_out[0] = &(player_position);

endmodule
