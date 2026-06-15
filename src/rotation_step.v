module rotation_step (
    input  wire signed [7:0] x_in,
    input  wire signed [7:0] y_in,
    input  wire signed [7:0] z_in,
    input  wire        [2:0] i,
    output reg signed [7:0] x_out,
    output reg signed [7:0] y_out,
    output reg signed [7:0] z_out
);

wire [7:0] arctan_val;
wire direction; // 0 is positive rotation, 1 is negative rotation

assign direction = z_in[7]; //signed binary so MSB indicates pos or neg

arctan_lut arctan1(i,arctan_val);

always @(*)begin
    if (direction == 1'b0)begin
        x_out = x_in - (y_in >>> i);
        y_out = y_in + (x_in >>> i);
        z_out = z_in - arctan_val;
    end
    else begin
        x_out = x_in + (y_in >>> i);
        y_out = y_in - (x_in >>> i);
        z_out = z_in + arctan_val;
    end

end

endmodule
