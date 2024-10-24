module rounding (
    num,
    round,
    shift
);

    input wire [21:0] num;
    output wire [9:0] round;
    output wire shift;

    wire [11:0] rounded;
    wire [10:0] shifted;

    wire m0, r, s;

    assign s = |num[9:0];
    assign m0 = num[11];
    assign r = num[10];

    assign rounded = num[21:10] + (r & (m0 | s));
    assign shift = rounded[11];
    assign shifted = rounded[11:0] >> shift;
    assign round = shifted[9:0];
endmodule
