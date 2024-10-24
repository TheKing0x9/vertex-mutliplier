module sign (
    signA,
    signB,
    sign
);
    input wire signA;
    input wire signB;
    output wire sign;

    assign sign = signA ^ signB;    
endmodule
