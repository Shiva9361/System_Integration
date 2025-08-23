module program_counter(pc,clk);
output [31:0] pc;
reg [31:0] pc_i;
input clk;
initial begin
    pc_i <= 0;
end
always @(posedge clk ) begin
    pc_i <= pc_i + 1;
    $display("pc=%d",pc_i);
end

assign pc = pc_i;

endmodule