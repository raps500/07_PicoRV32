/* 
 * 
 *
 * 
 */
`timescale 1ns/1ns

module tb();

reg clk, reset;

reg enable, mem_valid, serial;
always 
	#10 clk = ~clk; // 50 MHz
	
uart_rx uart(
    .clk(clk),
    .resetn(reset),
    .enable(enable),
    .mem_valid(mem_valid),
    .mem_ready(mem_ready),
    .mem_instr(1'b0),
    .mem_wstrb(4'b0000),
    .mem_wdata(32'h0),
    .mem_addr(32'hfffff050),
    .mem_rdata(),
    .serial_in(serial)
);
`define BITTIME (434*20)

initial
	begin
		$dumpvars;
		clk = 0;
		reset = 0;
        serial = 1;
		#0
		#55
		reset = 1;
		#101
        enable = 1;
        mem_valid = 1;
        #112
        enable = 0;
        mem_valid = 0;
        #1000
        serial = 0; // start bit
        #`BITTIME
        serial = 1; // lsb
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 1;
        
        //#`BITTIME
        //#`BITTIME
        // enable = 1;
        //mem_valid = 1;
        //#13
        //enable = 0;
        //mem_valid = 0;
        //#`BITTIME
        //#`BITTIME
        #`BITTIME
        serial = 0; // start bit
        #`BITTIME
        serial = 0; // lsb
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 1;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 1;
        #`BITTIME
        serial = 1;
        #`BITTIME
        #`BITTIME
         enable = 1;
        mem_valid = 1;
        #13
        enable = 0;
        mem_valid = 0;
        #`BITTIME
        #`BITTIME
        #`BITTIME
        serial = 0; // start bit
        #`BITTIME
        serial = 0; // lsb
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 1;
        #`BITTIME
        serial = 0;
        #`BITTIME
        serial = 1;
        #`BITTIME
        serial = 1;
        #`BITTIME
        serial = 1;
        #`BITTIME
        #`BITTIME
        #`BITTIME
        
		$finish;
	end

endmodule
