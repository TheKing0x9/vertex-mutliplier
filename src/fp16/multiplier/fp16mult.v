module fp16mult (
    input clk,
    input rst,
    input [15:0] a,
    input [15:0] b,
    output reg [15:0] x
);

    wire [4:0] expa, expb;
    wire [20:0] t1, t2;
    wire sign;

    wire [21:0] sum;
    wire inc;
    wire [4:0] exp;
    wire [9:0] rounded;

    fp16mult_stage1 stage1 (
        .a   (a),
        .b   (b),
        .clk (clk),
        .rst (rst),
        .sign(sign),
        .expa(expa),
        .expb(expb),
        .t1  (t1),
        .t2  (t2)
    );

    ksa #(
        .BITS(21)
    ) adder (
        .a  (t1),
        .b  (t2),
        .cin(1'b0),
        .sum(sum)
    );

    csa expAdder (
        .expA(expa),
        .expB(expb),
        .inc (inc),
        .exp (exp)
    );

    rounding round (
        .num  (sum),
        .round(rounded),
        .shift(inc)
    );

    always @(posedge clk, negedge rst) begin
        if (~rst) begin
            x <= 16'b0;
        end else if (!(|expa) | !(|expb)) begin
            // subnormal numbers are clamped to zero
            x[15] <= sign;
            x[14:10] <= 5'b00000;
            x[9:0] <= 10'b0;
        end else if (&expa | &expb) begin
            // infinity and NaN are clamped to infinity
            x[15] <= sign;
            x[14:10] <= 5'b11111;
            x[9:0] <= 10'b0;
        end else begin
            x[15] <= sign;
            x[14:10] <= exp;
            x[9:0] <= rounded;
        end
    end
endmodule
