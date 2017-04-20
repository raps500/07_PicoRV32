//
// Timer for for picorv32
//
`include "timescale.vh"

module timer (
    // Bus interface
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable,
    input  wire        mem_valid,
    output wire        mem_ready,
    input  wire        mem_instr,
    input  wire [3:0]  mem_wstrb,
    input  wire [31:0] mem_wdata,
    input  wire [31:0] mem_addr,
    output wire [31:0] mem_rdata
);
    reg [31:0] timers [1:0];
    reg rdy;

    always @(posedge clk) begin
        if (!resetn) begin
            rdy <= 0;
            timers[0] <= 32'h0;
            timers[1] <= 32'h0;
        end else begin
            timers[0] <= timers[0] + 32'h1;
            timers[1] <= timers[1] + 32'h1;
            if (mem_valid & enable) 
                begin
                    if (|mem_wstrb)
                        timers[mem_addr[2]] <= 32'h0; // reset timer
                    rdy <= 1;
                end 
            else 
                begin
                    rdy <= 0;
                end
        end
    end

    // Tri-state the bus outputs.
    assign mem_rdata = enable ? timers[mem_addr[2]] : 'b0;
    assign mem_ready = rdy;

endmodule
