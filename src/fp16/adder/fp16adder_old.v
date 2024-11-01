module fp16adder_old (
    input clk,
    input rst,
    input reg [15:0] a,
    input reg [15:0] b,
    output reg [15:0] x
);

    // Is only a fp16 adder i.e. it does not handle subtractions for the moment.

    wire [4:0] elderExp;
    wire isAExpGreater;

    wire [20:0] largerMantissa, smallerMantissa;
    wire [21:0] summedMantissa;
    wire [15:0] sum;
    wire shift;
    wire [10:0] shifted;

    assign isAExpGreater = a[14:10] > b[14:10];
    assign elderExp = isAExpGreater ? a[14:10] - b[14:10] : b[14:10] - a[14:10];

    assign largerMantissa = isAExpGreater ? {1'b1, a[9:0], 10'b0} : {1'b1, b[9:0], 10'b0};
    assign smallerMantissa = isAExpGreater ? {1'b1, b[9:0], 10'b0} >> elderExp : {1'b1, a[9:0], 10'b0} >> elderExp;

    ksa #(
        .BITS(21)
    ) adder (
        .a  (largerMantissa),
        .b  (smallerMantissa),
        .cin(1'b0),
        .sum(summedMantissa)
    );

    assign shift = summedMantissa[21];
    assign shifted = summedMantissa[20:10] >> shift;

    assign sum[15] = a[15];
    assign sum[14:10] = (isAExpGreater ? a[14:10] : b[14:10]) + shift;
    assign sum[9:0] = shifted[9:0];

    always @(posedge clk, negedge rst) begin
        if (~rst) begin
            x <= 16'b0;
        end else begin
            x[15] <= sum[15];
            x[14:10] <= sum[14:10];
            x[9:0] <= sum[9:0];
        end
    end

endmodule
