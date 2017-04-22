/**
 * Uart receiver
 *
 *
 * Memory Map
 *
 * XXXX_XX40 : Uart Transmitter
 * XXXX_XX48 : Uart receiver
 *
 * XXXX_XX48 : recieved byte
 *
 * Write
 *   31                                                          16
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 *
 *   15                                                           0
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 *
 * Read
 *   31                                                          16
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 *
 *   15                           8   7                           0
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * |   |   |   |   |   |   |   | E | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 */


//`include "timescale.vh"

module uart_rx  #(
    parameter [31:0] BAUD_DIVIDER = 3 //108    // 50MHz / 57600 baud
) (
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
    output wire [31:0] mem_rdata,

    output wire         bit_clock_o,
    
    // Serial interface
    input wire          serial_in     // The serial input.
);

    // Internal Variables
    reg [7:0]   shifter;
    reg [7:0]   buffer;
    reg [1:0]   state;
    reg [3:0]   bitCount;
    reg [2:0]   clkCount;
    reg [15:0]  bitTimer;
    reg         bufferFull;          // TRUE when ready to accept next character.
    reg         rdy, old_rdy;
    reg         old_serial_in;
    reg         old2_serial_in;
    reg         started, old_started;
    reg         bit_clock;
    reg         bufferFull_pending;
    
    assign bit_clock_o = bit_clock;
    
    // UART RX Logic
    always @ (posedge clk or negedge resetn) begin
        if (!resetn) begin
            bufferFull  <= 1'b0; // empty
            bitTimer    <= 1'b0;
            rdy         <= 1'b0;
            old_rdy     <= 1'b0;
            bit_clock   <= 1'b0;
            old_started <= 1'b0;
            bufferFull_pending <= 1'b0;
        end else begin
            if (mem_valid & enable) 
                begin
                    if (|mem_wstrb == 1'b0)
                        rdy <= 1;
                end 
            else 
                begin
                    rdy <= 0;
                end
            old_rdy <= rdy;
            if  ((old_rdy == 1'b1) && (rdy == 1'b0)) 
                begin
                    bufferFull <= 1'b0;// ensures that at least one access sees that the buffer is full
                end
            // Generate bit clock timer for 115200 baud from 50MHz clock
            if (bitTimer == BAUD_DIVIDER)
                begin
                    bitTimer <= 'h0;
                    bit_clock <= ~bit_clock;
                end
            else
                bitTimer <= bitTimer + 1;
            old_started <= started;
            
            if ((old_started == 1'd1) && (started == 1'b0))
                begin
                    if (enable)
                        bufferFull_pending <= 1'b1; // delay seeting this bit, avoids the cpu getting unsettled data
                    else
                        bufferFull <= 1'b1; // received
                end
            if (bufferFull_pending && (~enable )) // delay setting bufferFull till current access is over
                begin
                    bufferFull_pending <= 1'b0;
                    bufferFull <= 1'b1;
                end
        end
    end
    
    
    always @(posedge bit_clock)
        begin
            old_serial_in <= serial_in;
            old2_serial_in <= old_serial_in;
            if ((old2_serial_in == 1'b1) && (old_serial_in == 1'b0)) // start condition
                begin
                    if (started == 0)
                        begin
                            state <= 2'h0;
                            started <= 1'b1;
                            clkCount <= 3'h5; // 2 cycles already elapsed
                        end
                end

            if (started)
                begin
                    case (state)
                        // Idle
                        2'd0: begin
                                bitCount <= 7;
                                if (clkCount == 3'h0)
                                    begin
                                        state <= 2'd1;
                                        clkCount <= 3'h7;
                                    end
                                else
                                    clkCount <= clkCount - 3'd1;
                            end
                        2'd1: begin
                                if (clkCount == 3'd4)
                                    shifter <= { old_serial_in, shifter[7:1] }; // shift in
                                if (clkCount == 3'd0)
                                    begin
                                        clkCount <= 3'h7;
                                        if (bitCount == 4'd0) 
                                            begin
                                                state <= 2'd2;
                                            end
                                        else
                                            begin
                                                bitCount <= bitCount - 4'd1;
                                            end
                                    end
                                else
                                    clkCount <= clkCount - 3'd1;
                            end
                        2'd2 : begin // stop bit
                                buffer <= shifter;
                                started <= 1'b0;
                            end
                        default : ;
                    endcase
                end
        end


    // Tri-state the bus outputs.
    assign mem_rdata = enable ? { bufferFull, buffer } : 'b0;
    assign mem_ready = rdy;
initial
    started = 0;
endmodule
