module fp16mult_tb;
    reg [15:0] a;
    reg [15:0] b;
    wire [15:0] y;

    reg clk = 0;
    always #5 clk = ~clk;

    fp16mult uut (
        .a  (a),
        .b  (b),
        .x  (y),
        .clk(clk),
        .rst(1'b1)
    );

    initial begin
        $dumpfile("fp16mult_tb.vcd");
        $dumpvars(0, fp16mult_tb);
        $display("A    B     Y");
        $monitor("%d %d %d", a, b, y);

        #12;
        assign a = 16'b0100011101100110;
        assign b = 16'b0100100000100110;
        if (y == 16'b0101001110101100) $display("Correct");
        #10;
        assign b = 16'b0_00000_0110110010;
        if (y == 16'b0) $display("Correct");
        #10;
        $finish;
    end
endmodule
