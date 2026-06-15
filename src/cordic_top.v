module cordic_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] angle,
    input  wire       start,
    output wire [7:0] sin_out,
    output wire [7:0] cos_out,
    output wire       done
);

wire signed [7:0] x_init, y_init, z_init;
wire              flip_x, flip_y;
wire              load, step;
wire [7:0]        x_out, y_out;
wire              iter_done;

angle_to_init angle_inst (.angle(angle), .x_init(x_init), .y_init(y_init), .z_init(z_init), .flip_x(flip_x), .flip_y(flip_y));
cordic_fsm fsm (.clk(clk), .rst_n(rst_n), .start(start), .iter_done(iter_done), .load(load), .step(step), .done(done));
cordic_core core (.clk(clk), .rst_n(rst_n), .load(load), .step(step), .x_init(x_init), .y_init(y_init), .z_init(z_init), .x_out(x_out), .y_out(y_out), .iter_done(iter_done));

assign sin_out = flip_y ? -y_out : y_out;
assign cos_out = flip_x ? -x_out : x_out;

endmodule
