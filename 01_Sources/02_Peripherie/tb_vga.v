/* 
 * Testbench for vgatext.v module
 *
 * 
 */
`timescale 1ns/1ns

module tb();

reg pixel_clk, cpu_clk, reset;

reg enable_ctrl, enable_ram, mem_valid, serial;
reg [31:0] wdata, waddr;

always 
	#10 cpu_clk = ~cpu_clk; // 50 MHz
	
always 
	#12.5 pixel_clk = ~pixel_clk; // 40 MHz
    
vgatext vtext(
    .pixel_clk_in(pixel_clk),
    .cpu_clk_in(cpu_clk),
    .resetn_in(reset),
    .enable_ctrl_in(enable_ctrl),
    .enable_ram_in(enable_ram),
    .mem_valid_in(mem_valid),
    .mem_ready_o(),
    .mem_instr_in(1'b0),
    .mem_wstrb_in(4'hf),
    .mem_wdata_in(wdata),
    .mem_addr_in(waddr),
    .mem_rdata_o(),
    
    .green_o(),
    .red_o(),
    .blue_o(),
    .hsync_o(),
    .vsync_o()
);
`define BITTIME (434*20)

initial
	begin
		$dumpvars;
		cpu_clk = 0;
        pixel_clk = 0;
		reset = 0;
        wdata = 0;
        waddr = 0;
        enable_ctrl = 0;
        enable_ram = 0;
		#0
		#55
		reset = 1;
		#45
        #20000000
        $finish;
	end

endmodule
