module fp16adder (
    input clk,
    input rst,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [15:0] x
);
    reg [15:0] greater_value, smaller_value;
    wire [4:0] exp_diff;
    reg  [4:0] exp_out;
    wire [12:0] adderinput1, adderinput2;
    wire [13:0] adderoutput;
    reg  [13:0] shiftedoutput;
    reg  [11:0] roundedoutput;
    reg  [12:0] shiftedai;
    reg sticky, iszero;
    reg [4:0] i, firstone;


    // Set larger and smaller value
    always @(a or b) begin
        if (a[14:10] > b[14:10] || (a[14:10] == b[14:10] && a[9:0] > b[9:0])) begin
            greater_value <= a;
            smaller_value <= b;
        end else begin
            greater_value <= b;
            smaller_value <= a;
        end
    end
    // Exponent difference
    assign exp_diff = greater_value[14:10] - smaller_value[14:10];

    // Significand
    assign adderinput1[12] = 1;
    assign adderinput1[11:2] = greater_value[9:0];
    assign adderinput1[1:0] = 2'b00;
    assign adderinput2[12] = 1;
    assign adderinput2[11:2] = smaller_value[9:0];
    assign adderinput2[1:0] = 2'b00;

    // Shifting
    always @(*) begin
        if (exp_diff >= 13) begin
            shiftedai <= 1;
        end else begin
            shiftedai <= adderinput2 >> exp_diff;
            sticky = 0;
	    if(exp_diff>=2&&adderinput2[0]==1)sticky = 1;
	    if(exp_diff>=3&&adderinput2[1]==1)sticky = 1;
	    if(exp_diff>=4&&adderinput2[2]==1)sticky = 1;
	    if(exp_diff>=5&&adderinput2[3]==1)sticky = 1;
	    if(exp_diff>=6&&adderinput2[4]==1)sticky = 1;
	    if(exp_diff>=7&&adderinput2[5]==1)sticky = 1;
	    if(exp_diff>=8&&adderinput2[6]==1)sticky = 1;
	    if(exp_diff>=9&&adderinput2[7]==1)sticky = 1;
	    if(exp_diff>=10&&adderinput2[8]==1)sticky = 1;
	    if(exp_diff>=11&&adderinput2[9]==1)sticky = 1;
	    if(exp_diff>=12&&adderinput2[10]==1)sticky = 1;
        end
        if (sticky == 1) shiftedai[0] <= 1;
    end

    // Addition/Subtraction
    assign adderoutput = (a[15] == b[15]) ? (adderinput1 + shiftedai) : (adderinput1 - shiftedai);

    //Normalisation and rounding
    always @(*) begin
        iszero = 0;
	if(adderoutput[13])firstone = 13;
	else if(adderoutput[12]) firstone = 12;
	else if(adderoutput[11]) firstone = 11;
	else if(adderoutput[10]) firstone = 10;
	else if(adderoutput[9]) firstone = 9;
	else if(adderoutput[8]) firstone = 8;
	else if(adderoutput[7]) firstone = 7;
	else if(adderoutput[6]) firstone = 6;
	else if(adderoutput[5]) firstone = 5;
	else if(adderoutput[4]) firstone = 4;
	else if(adderoutput[3]) firstone = 3;
	else if(adderoutput[2]) firstone = 2;
	else if(adderoutput[1]) firstone = 1;
	else if(adderoutput[0]) firstone = 0;
	else iszero = 1;
        if (firstone == 13) begin
            shiftedoutput = adderoutput >> 1;
            if (adderoutput[0]) shiftedoutput[0] = 1;
            exp_out = greater_value[14:10] + 1;
        end else if (firstone < 12) begin
            shiftedoutput = adderoutput << (12 - firstone);
            exp_out = greater_value[14:10] - (12 - firstone);
        end else begin
            shiftedoutput = adderoutput;
            exp_out = greater_value[14:10];
        end
        roundedoutput=shiftedoutput[13:2]+(shiftedoutput[1]&(shiftedoutput[0]|shiftedoutput[2]));
        exp_out = exp_out + roundedoutput[11];

    end


    //Final
    always @(posedge clk, negedge rst) begin
        if (iszero || ~rst) x <= 0;
        else if (a[14:10] == 0) x <= b;
        else if (b[14:10] == 0) x <= a;
        else begin
            x[15] <= greater_value[15];
            x[14:10] <= exp_out;
            x[9:0] <= (roundedoutput[11]) ? roundedoutput[10:1] : roundedoutput[9:0];
        end
    end


endmodule
