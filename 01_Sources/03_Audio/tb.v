/*
 * Test bench for Audio top entity
 *
 *
 */
`timescale 1ns/1ns
 
module tb();


reg clk, enable_mem, enable_ctrl, mem_valid, resetn;
wire ready;
reg [31:0] addr, data;
sd_audio audio (
	.clk(clk),
    .resetn(resetn),
    .enable_ram(enable_mem),
	.enable_ctrl(enable_ctrl),
	.mem_valid(mem_valid),
	.mem_ready(ready),
	.mem_instr(1'b0),
	.mem_wstrb(4'b1111),
	.mem_wdata(data),
	.mem_addr(addr),
    .mem_rdata(),
    .left_o(),
    .irq_o()
	);



always 
	#10 clk = ~clk; // 50 MHz clock
	
initial
	begin
	$dumpvars;
	clk = 0;
    enable_ctrl = 0;
    mem_valid = 0;
    enable_mem = 0;
    #25
    enable_ctrl = 1'b1;
    mem_valid = 1'b1;
    addr = 32'h00000;
    data = 32'h00000001;
    #10
    enable_ctrl = 1'b0;
    #(1000000-35)
    #9000000
    #50000000
	$finish;
	end
	
	
endmodule
