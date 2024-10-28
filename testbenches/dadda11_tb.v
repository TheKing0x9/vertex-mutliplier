module dadda_tb;
    reg  [10:0] a;
    reg  [10:0] b;
    wire [21:0] y;

    dadda11 uut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        $dumpfile("dadda_tb.vcd");
        $dumpvars(0, dadda_tb);
        $display("A    B     Y");
        $monitor("%d %d %d", a, b, y);

        assign a = 11'd987;
        assign b = 11'd135;
        #10;
    end
endmodule
