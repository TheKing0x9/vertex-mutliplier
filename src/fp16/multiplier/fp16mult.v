module fp16mult (
    input clk,
    input rst,
    input reg [15:0] a,
    input reg [15:0] b,
    output reg [15:0] x
);
    wire sign;
    wire [9:0] rounded;
    wire [4:0] exp;
    wire [21:0] dadda_x;
    wire inc;

    assign sign = a[15] ^ b[15];

    csa expAdder (
        .expA(a[14:10]),
        .expB(b[14:10]),
        .inc (inc),
        .exp (exp)
    );

    dadda11 dadda (
        .a({1'b1, a[9:0]}),
        .b({1'b1, b[9:0]}),
        .y(dadda_x)
    );

    rounding round (
        .num  (dadda_x),
        .round(rounded),
        .shift(inc)
    );

    always @(posedge clk, negedge rst) begin
        if (~rst) begin
            x <= 16'b0;
        end else begin
            x[15] <= sign;
            x[14:10] <= exp;
            x[9:0] <= rounded;
        end
    end
endmodule
