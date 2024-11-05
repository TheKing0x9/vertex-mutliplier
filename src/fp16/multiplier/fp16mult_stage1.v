module fp16mult_stage1 (
    input clk,
    input rst,
    input [15:0] a,
    input [15:0] b,
    output reg [20:0] t1,
    output reg [20:0] t2,
    output reg [4:0] expa,
    output reg [4:0] expb,
    output reg sign
);

    wire [20:0] t1x, t2x;

    dadda11 dadda (
        .a ({1'b1, a[9:0]}),
        .b ({1'b1, b[9:0]}),
        .t1(t1x),
        .t2(t2x)
    );

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            sign <= 1'b0;
            expa <= 5'b00000;
            expb <= 5'b00000;
            t1   <= 22'b0;
            t2   <= 22'b0;
        end else begin
            sign <= a[15] ^ b[15];
            expa <= a[14:10];
            expb <= b[14:10];
            t1   <= t1x;
            t2   <= t2x;
        end
    end

endmodule
