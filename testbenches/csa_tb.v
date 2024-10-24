module csa_tb;
    reg [4:0] expA;
    reg [4:0] expB;
    reg inc;
    wire [4:0] exp;

    csa csa (
        .expA(expA),
        .expB(expB),
        .inc (inc),
        .exp (exp)
    );

    initial begin
        $dumpfile("csa_tb.vcd");
        $dumpvars(0, csa_tb);
        $display("expA expB inc exp");
        $monitor("%b %b %b %b", expA, expB, inc, exp);

        assign expA = 5'b01111;
        assign expB = 5'b01111;
        assign inc = 1'b0;
        #10;
        assign inc = 1'b1;
        #10;
        assign expA = 7;
        assign expB = 17;
        #10;
    end
endmodule
