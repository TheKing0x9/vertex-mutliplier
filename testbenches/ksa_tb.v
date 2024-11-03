module ksa_tb;

    reg [4:0] a;
    reg [4:0] b;
    reg cin;
    wire [4:0] sum;

    ksa #(
        .BITS(5)
    ) uut (
        .a  (a),
        .b  (b),
        .cin(cin),
        .sum(sum)
    );

    initial begin
        $dumpfile("ksa_tb.vcd");
        $dumpvars(0, ksa_tb);
        $display("a b cin sum");
        $monitor("%b %b %b %b", a, b, cin, sum);

        a   <= 13;
        b   <= 12;
        cin <= 0;
        #10;

        a   <= 19;
        b   <= 11;
        cin <= 1;
        #10;
    end


endmodule
