module cordic_fsm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire       iter_done,
    output wire        load,
    output wire        step,
    output wire        done
);

parameter IDLE = 0, LOAD = 1, COMPUTE = 2, DONE = 3;
reg[1:0] state, next_state;


always @(*) begin
    case (state)
        IDLE: next_state = (start) ? LOAD : IDLE;
        LOAD: next_state = COMPUTE;
        COMPUTE: next_state = (iter_done) ? DONE : COMPUTE;
        DONE: next_state = (start) ? IDLE : DONE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;    // Reset goes to IDLE
        else
            state <= next_state;
    end

assign load = (state == LOAD);
assign step = (state == COMPUTE);
assign done = (state == DONE);

endmodule