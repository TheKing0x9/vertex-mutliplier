module adder #(
    parameter BITS = 1
) (
    input wire [BITS-1:0] a,
    input wire [BITS-1:0] b,
    input wire cin,
    output wire [BITS-1:0] sum,
    output wire cout
);

    wire [BITS:0] temp;

    assign temp = a + b + cin;
    assign sum  = temp[(BITS-1):0];
    assign cout = temp[BITS];
endmodule
