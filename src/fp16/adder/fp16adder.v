module fp16adder (
    input clk,
    input rst,
    input [15:0] a,
    input [15:0] b,
    output reg [15:0] x
);
reg[15:0] greater_value,smaller_value;
wire[4:0] exp_diff;
reg[4:0] exp_out;
wire[12:0] adderinput1,adderinput2;
wire[13:0] adderoutput;
reg[13:0]shiftedoutput;
reg[11:0] roundedoutput;
reg[12:0] shiftedai;
reg sticky,iszero;
reg[4:0] i,firstone;


// Set larger and smaller value
always @(a or b) begin
if (a[14:10]>b[14:10] || ( a[14:10] == b[14:10] && a[9:0]>b[9:0])) begin
greater_value<=a;
smaller_value<=b;
end
else begin
greater_value<=b;
smaller_value<=a;
end
end
// Exponent difference
assign exp_diff = greater_value[14:10]-smaller_value[14:10];

// Significand
assign adderinput1[12] = 1;
assign adderinput1[11:2] = greater_value[9:0];
assign adderinput1[1:0] = 2'b00;
assign adderinput2[12] = 1;
assign adderinput2[11:2] = smaller_value[9:0];
assign adderinput2[1:0] = 2'b00;

// Shifting
always @(*) begin
if (exp_diff>=13) begin
shiftedai<=1;
end
else begin
shiftedai<= adderinput2 >> exp_diff;
sticky=0;
for (i=1;i<exp_diff;i=i+1) begin
            if(adderinput2[i-1]==1)sticky = 1;
        end
end
if(sticky==1)shiftedai[0]<=1;
end

// Addition/Subtraction
assign adderoutput=(a[15]==b[15])?(adderinput1+shiftedai):(adderinput1-shiftedai);

//Normalisation and rounding
always @(*) begin
iszero=1;
for(i=0;i<=13;i=i+1) begin
if(adderoutput[i]) begin
	firstone=i;
	iszero=0;
end
end

if(firstone==13) begin
shiftedoutput = adderoutput >> 1;
if(adderoutput[0])shiftedoutput[0]=1; 
exp_out = greater_value[14:10]+1;
end
else if(firstone<12) begin
shiftedoutput=adderoutput << (12-firstone);
exp_out=greater_value[14:10]-(12-firstone);
end
else begin
shiftedoutput=adderoutput;
exp_out=greater_value[14:10];
end
roundedoutput=shiftedoutput[13:2]+(shiftedoutput[1]&(shiftedoutput[0]|shiftedoutput[2]));
exp_out=exp_out+roundedoutput[11];

end


//Final
always @(posedge clk,negedge rst) begin
if(iszero||~rst)x<=0;
else if(a[14:0]==0)x<=b;
else if(b[14:0]==0)x<=a;
else begin
x[15]<=greater_value[15];
x[14:10]<=exp_out;
x[9:0]<=(roundedoutput[11])?roundedoutput[10:1]:roundedoutput[9:0];
end
end


endmodule
