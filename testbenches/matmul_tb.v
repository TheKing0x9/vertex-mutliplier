module matmul_tb;
    reg [15:0][15:0] a;
    reg [3:0][15:0] b;
    wire [3:0][15:0] y;

    reg clk = 0;
    always #5 clk = ~clk;

    matmul uut (
        .a  (a),
        .b  (b),
        .x  (y),
        .clk(clk),
        .rst(1'b1)
    );

    initial begin
        $dumpfile("matmul_tb.vcd");
        $dumpvars(0, matmul_tb);
        $display("A    B     Y");
        $monitor("%d %d %d", a, b, y);

        #3;

        a[0]  = 16'b0011010011001101;  // 0.3001
        a[1]  = 16'b0010100100011111;  // 0.04001
        a[2]  = 16'b0011010111000011;  // 0.3602
        a[3]  = 16'b0011100111000011;  // 0.7203

        a[12] = 16'b0;
        a[13] = 16'b0;
        a[14] = 16'b0;
        a[15] = 16'b0011110000000000;

        b[0]  = 16'b0011110110011010;  //1.4
        b[1]  = 16'b0011101011100001;  // 0.86
        b[2]  = 16'b0100000011001101;  // 2.4
        b[3]  = 16'b0011110000000000;  // 1

        // result 0.54
        #70;

        // if (y == 16'b0100101111011001) $display("Correct");

        $finish;
    end
endmodule
