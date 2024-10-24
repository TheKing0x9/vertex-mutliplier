module fp16mult (input clk, input rst, input reg [15:0] a, input reg [15:0] b, output reg [15:0] x);
    wire sign;
    wire [4:0] exp;
    wire inc = 0;

    sign signBit (
        .signA(a[15]),
        .signB(b[15]),
        .sign(sign)
    );

    csa expAdder (
        .expA(a[14:10]),
        .expB(b[14:10]),
        .inc(inc),
        .exp(exp)
    );
    
    always @(posedge clk, negedge rst) begin
        if (~rst) begin
            x <= 16'b0;
        end else begin 
            x[15] <= sign;
            x[14:0] <= exp;  
        end
    end
endmodule