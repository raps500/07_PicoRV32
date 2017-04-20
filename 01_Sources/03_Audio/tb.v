/*
 * Test bench for Audio top entity
 *
 *
 */
`timescale 1ns/1ns
 
module tb();


reg clk, enable, mem_valid;
wire ready;
reg [31:0] addr, data;
sd_audio disp (
	.clk(clk),
    .enable(enable),
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
    enable = 0;
    mem_valid = 0;

    #25
    enable = 1'b1;
    mem_valid = 1'b1;
    addr = 13'h10000;
    data = 32'h00000001;
    #10
    enable = 1'b0;
	#300
    reset = 0;
    #86000
    disp_toggle = 1;
    #500
    disp_toggle = 0;
    
    #100000
	
	$finish;
	end
	
	
endmodule
