module matmul (
    clk,
    rst,
    a,
    b,
    x
);

    input clk, rst;
    input reg [15:0][15:0] a;
    input reg [3:0][15:0] b;

    output wire [3:0][15:0] x;

    wire [15:0][15:0] partials;
    wire [ 7:0][15:0] sum0;

    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : g_row
            for (j = 0; j < 4; j = j + 1) begin : g_col
                fp16mult mult (
                    .clk(clk),
                    .rst(rst),
                    .a  (a[4*i+j]),
                    .b  (b[j]),
                    .x  (partials[4*i+j])
                );
            end
        end
    endgenerate


    generate
        for (i = 0; i < 15; i = i + 2) begin : g_reduce0
            fp16adder adder (
                .clk(clk),
                .rst(rst),
                .a  (partials[i]),
                .b  (partials[i+1]),
                .x  (sum0[i/2])
            );
        end
    endgenerate


    generate
        for (i = 0; i < 7; i = i + 2) begin : g_reduce1
            fp16adder adder (
                .clk(clk),
                .rst(rst),
                .a  (sum0[i]),
                .b  (sum0[i+1]),
                .x  (x[i/2])
            );
        end
    endgenerate
endmodule
