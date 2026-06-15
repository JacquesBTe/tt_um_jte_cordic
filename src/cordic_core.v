module cordic_core (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       load,
    input  wire       step,
    input  wire [7:0] x_init,
    input  wire [7:0] y_init,
    input  wire [7:0] z_init,
    output wire [7:0] x_out,
    output wire [7:0] y_out,
    output reg  [2:0] iter,
    output wire       iter_done
);

reg [7:0] x,y,z;
wire signed [7:0] x_next, y_next, z_next;

always @(posedge clk) begin
    if (!rst_n) begin
        iter  <= 0;
        x <= 0;
        y <= 0;
        z <= 0;
        
    end
    else if (load) begin
        x <= x_init;
        y <= y_init;
        z <= z_init;
        iter <=0;
    end
    else if (step) begin
        x <= x_next;
        y <= y_next;
        z <= z_next;
        iter  <=  iter + 1;
    end
end

rotation_step u_step (.x_in(x), .y_in(y), .z_in(z),.i(iter),
    .x_out(x_next), .y_out(y_next), .z_out(z_next)
);

assign iter_done = (iter == 7);
assign x_out = x;
assign y_out = y;

endmodule