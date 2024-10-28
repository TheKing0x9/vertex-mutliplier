module fp16adder_tb;
    reg [15:0] a;
    reg [15:0] b;
    wire [15:0] y;

    reg clk = 0;
    always #5 clk = ~clk;

    fp16adder uut (
        .a  (a),
        .b  (b),
        .x  (y),
        .clk(clk),
        .rst(1'b1)
    );

    initial begin
        $dumpfile("fp16adder_tb.vcd");
        $dumpvars(0, fp16adder_tb);
        $display("A    B     Y");
        $monitor("%d %d %d", a, b, y);

        #3;
        assign a = 16'b0100011101100110;
        assign b = 16'b0100100000100110;
        #10;

        if (y == 16'b0100101111011001) $display("Correct");

        $finish;
    end
endmodule
