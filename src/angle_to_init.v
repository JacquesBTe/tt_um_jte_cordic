module angle_to_init (
    input  wire [7:0] angle,
    output wire signed [7:0] x_init,
    output wire signed [7:0] y_init,
    output wire signed [7:0] z_init,
    output wire        flip_x,
    output wire        flip_y
);

// CORDIC gain compensation: 1/K * 2^6 = 0.6073 * 64 = 38.87 ~ 8'h27
parameter CORDIC_GAIN = 8'h27;

wire [1:0] quadrant;
assign quadrant = angle[7:6];  // upper 2 bits = quadrant

// position within the quadrant, 0..63
wire [6:0] pos;
assign pos = {1'b0, angle[5:0]};

// fold into first quadrant [0..64] (0..90 deg).
// even quadrants advance (pos); odd quadrants reflect (64 - pos)
wire [7:0] z_folded;
assign z_folded = quadrant[0] ? (8'd64 - {1'b0, pos}) : {1'b0, pos};

assign x_init = CORDIC_GAIN;
assign y_init = 8'h00;
assign z_init = z_folded;

// sign flip flags based on quadrant
assign flip_x = (quadrant == 2'b01) || (quadrant == 2'b10);  // Q2, Q3
assign flip_y = (quadrant == 2'b10) || (quadrant == 2'b11);  // Q3, Q4

endmodule