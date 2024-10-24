module ksa #(
    parameter BITS = 22
) (
    input wire [BITS-1:0] a,
    input wire [BITS-1:0] b,
    input wire cin,
    output [BITS:0] sum
);

    localparam integer LEVELS = $clog2(BITS);

    wire [BITS-1:0] pg[LEVELS-1:0], g[LEVELS-1:0];

    assign pg[0][BITS-1:0] = a ^ b;
    assign g[0][BITS-1:0]  = a & b;

    genvar lvl;

    generate
        for (lvl = 1; lvl < LEVELS; lvl = lvl + 1) begin : g_ksa
            // buffers
            assign pg[lvl][2**(lvl-1)-1:0] = pg[lvl-1][2**(lvl-1)-1:0];
            assign g[lvl][2**(lvl-1)-1:0] = g[lvl-1][2**(lvl-1)-1:0];
            // pg and g blocks
            assign pg[lvl][BITS-1:2**(lvl-1)] =
                pg[lvl-1][BITS-1:2**(lvl-1)] &
                pg[lvl-1][BITS-1 - 2**(lvl-1):0];
            assign g[lvl][BITS-1:2**(lvl-1)] =
                (pg[lvl-1][BITS-1:2**(lvl-1)] & g[lvl-1][BITS-1 - 2**(lvl-1):0]) |
                g[lvl-1][BITS-1:2**(lvl-1)];
        end
    endgenerate
    assign sum = {1'b0, pg[0]} ^ {g[LEVELS-1], cin};
endmodule
