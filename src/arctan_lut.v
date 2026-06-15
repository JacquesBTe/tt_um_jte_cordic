module arctan_lut (
    input  wire [2:0] i,
    output reg  [7:0] arctan_val
);

always @(*)begin
    // arctan(2^-i) scaled so that 90 deg = 64 counts (1 count = 1.40625 deg)
    case(i)
        0: arctan_val = 8'h20;  // 45.000 deg -> 32
        1: arctan_val = 8'h13;  // 26.565 deg -> 19
        2: arctan_val = 8'h0A;  // 14.036 deg -> 10
        3: arctan_val = 8'h05;  //  7.125 deg ->  5
        4: arctan_val = 8'h03;  //  3.576 deg ->  3
        5: arctan_val = 8'h01;  //  1.790 deg ->  1
        6: arctan_val = 8'h01;  //  0.895 deg ->  1
        7: arctan_val = 8'h00;  //  0.448 deg ->  0
        default: arctan_val = 8'h00;
    endcase
end

endmodule