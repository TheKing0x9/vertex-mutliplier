module csa (
    expA,
    expB,
    inc,
    exp
);
    genvar i;

    input wire [4:0] expA;
    input wire [4:0] expB;
    input wire inc;
    output wire [4:0] exp;

    wire [4:0] bias;
    wire [4:0] sum;
    wire [4:0] carry;
    wire [5:0] intermediate;

    assign bias[4:2] = 3'b100;

    assign bias[1]   = inc;
    assign bias[0]   = ~inc;

    generate
        for (i = 0; i < 5; i = i + 1) begin : g_intermediate
            adder #(
                .BITS(1)
            ) fa (
                .a(expA[i]),
                .b(expB[i]),
                .cin(bias[i]),
                .sum(sum[i]),
                .cout(carry[i])
            );
        end
    endgenerate

    adder #(
        .BITS(5)
    ) rca (
        .a({1'b0, sum[4:1]}),
        .b(carry),
        .cin(1'b0),
        .sum(intermediate[4:0]),
        .cout(intermediate[5])
    );

    assign exp[0]   = sum[0];
    assign exp[4:1] = intermediate[3:0];
endmodule
