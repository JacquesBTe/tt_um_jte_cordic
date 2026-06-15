/*
 * Copyright (c) 2026 Jacques Benzly Te
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_jte_cordic (
    input  wire [7:0] ui_in,    // [6:0] = angle (7-bit, 0..127 = 0..360 deg); [7] = start
    output wire [7:0] uo_out,   // sin (Q2.6, two's complement)
    input  wire [7:0] uio_in,   // unused
    output wire [7:0] uio_out,  // cos (Q2.6, two's complement)
    output wire [7:0] uio_oe,   // direction: all outputs
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);


wire [7:0] sin_out, cos_out;
wire done;
wire [7:0] angle_int = {ui_in[6:0], 1'b0};

cordic_top top (.clk(clk), .rst_n(rst_n),.angle(angle_int), .start(ui_in[7]),.sin_out(sin_out), .cos_out(cos_out), .done(done));

assign uo_out  = sin_out;
assign uio_out = cos_out;
assign uio_oe  = 8'hFF; // uio used entirely as cos output

// tie off unused inputs so Verilator / TT lint stays clean
wire _unused = &{ena, uio_in, done, 1'b0};


endmodule

`default_nettype wire
