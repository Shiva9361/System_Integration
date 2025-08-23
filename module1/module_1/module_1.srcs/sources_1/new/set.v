module set_less_than_u(input1,input2,out);
input [31:0] input1,input2;
output [31:0] out;
assign out = (input1<input2) ? 1:0;
endmodule

module set_less_than(input1,input2,out);
input [31:0] input1,input2;
output [31:0] out;
assign out = (input1[31] & 1'b1) ? (input2[31] & 1'b1)? input1>input2 ? 1:0 : 1 : (input2[31] & 1'b1) ? 0: input1 < input2 ?1:0;
endmodule