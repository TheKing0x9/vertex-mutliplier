module fp16adder_tb;
    reg [15:0] a, b;
    reg clk, rst;
    wire [15:0] out;
    real ar, br, outr;

    fp16adder uut (
        .clk(clk),
        .rst(rst),
        .a  (a),
        .b  (b),
        .x  (out)
    );

    always #5 clk = ~clk;

    function automatic real fp16_to_real(input [15:0] num);
        begin
            fp16_to_real = (num[15] ? -1 : 1) * (1.0 + ($itor(num[9:0]) / $itor(2 ** 10))) *
                $itor(2 ** (num[14:10] - 5'd15));
        end
    endfunction

    initial begin
        $dumpfile("fp16adder_tb.vcd");
        $dumpvars(0, fp16adder_tb);
        $display("A    B     Y");

        clk = 0;
        rst = 1;

        a   = 16'b0_10000_1000000000;
        b   = 16'b0_10011_1000000000;

        //greater lesser exponent difference check
        #10;
        a = 16'b0_11000_1000000000;
        b = 16'b0_10011_1000000000;
        #10;
        a = 16'b0_10000_1000000000;
        b = 16'b0_00000_1011011011;
        #10;
        a = 16'b0_11000_1000000000;
        b = 16'b0_11000_1000000011;
        // adder inputs check
        #10;
        a = 16'b0_11000_1111000000;
        b = 16'b0_10011_1000100011;
        // shifting check
        #10;
        a = 16'b1_11110_1110000000;
        b = 16'b0_11010_0011100011;

        #10;
        a = 16'b0_10010_1101100000;
        b = 16'b0_10001_1100000000;

        if (out == 16'b0100110101110000) $display("Correct 1");
        //finalcheck-expectedoutput=1 10001 1111100000
        #20;
        a = 16'b1100101101100000;
        b = 16'b0100011100000000;
        if (out == 16'b1100011111100000) $display("Correct 2");
        #20;
        a = 16'b0100011101100110;
        b = 16'b0100100000100110;
        if (out == 16'b0100101111011001) $display("Correct 3");

        $finish;
    end

    always @(a, b, out) begin
        ar   = fp16_to_real(a);
        br   = fp16_to_real(b);
        outr = fp16_to_real(out);
    end

    always @(outr) begin
        $display("%f %f %f", ar, br, outr);
        if (ar + br == outr) $display("Correct");
    end

endmodule
