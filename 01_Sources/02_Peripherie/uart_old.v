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
    parameter [31:0] BAUD_DIVIDER = 434 //868   // 100MHz / 115200 baud
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

    output wire         bit_clock,
    
    // Serial interface
    input wire          serial_in     // The serial input.
);

    // Internal Variables
    reg [7:0]  shifter;
    reg [7:0]  buffer;
    reg [7:0]  state;
    reg [3:0]  bitCount;
    reg [19:0] bitTimer;
    reg        bufferEmpty;          // TRUE when ready to accept next character.
    reg        rdy;
    reg         old_serial_in;
    reg         old2_serial_in;
    reg         started;

assign bit_clock = bitTimer < (BAUD_DIVIDER / 2) ? 1'b1:1'b0;

`define BAUD_DIVIDER_34  ((BAUD_DIVIDER * 3) / 4)
    
    // UART RX Logic
    always @ (posedge clk or negedge resetn) begin
        if (!resetn) begin
            state       <= 0;
            buffer      <= 0;
            bufferEmpty <= 1'b1; // empty
            shifter     <= 0;

            bitCount    <= 0;
            bitTimer    <= 0;
            rdy         <= 0;
            started     <= 0;
        end else begin
            if (mem_valid & enable) begin
                if  ((|mem_wstrb == 1'b0) && (bufferEmpty == 1'b0)) begin
                    bufferEmpty <= 1'b1;
                end
                rdy <= 1;
            end else begin
                rdy <= 0;
            end

            old_serial_in <= serial_in;
            old2_serial_in <= old_serial_in;
            if ((old2_serial_in == 1'b1) && (old_serial_in == 1'b0)) // start condition
                begin
                    if (started == 0)
                        begin
                            bitTimer <= 0; // start timer
                            state <= 2'h0;
                            started <= 1'b1;
                        end
                end
            
            // Generate bit clock timer for 115200 baud from 50MHz clock
            if (bitTimer == BAUD_DIVIDER) begin
                bitTimer <= 0;
            end

            if (started)
                begin
                    bitTimer <= bitTimer + 1;
            
                    case (bitTimer)
                        20'd0:
                        case (state)
                            // Idle
                            0 : begin

                                    shifter <= 8'h0;
                                    
                                    bitCount <= 8;

                                    // Start bit
                                    state <= 1;
                                //end
                            end

                            // Transmitting
                            1 : begin
                                if (bitCount > 0) begin
                                    // Data bits
                                    bitCount <= bitCount - 1;                                    
                                end else begin
                                    // Stop bit
                                    state <= 2;
                                end
                            end

                            // Second stop bit
                            2 : begin
                                    state <= 0;
                                    buffer <= shifter;
                                    bufferEmpty <= 1'b0; // full
                                    started <= 1'b0;
                                end

                            default : ;
                        endcase
                    `BAUD_DIVIDER_34:
                        if (state == 2'd1)
                            begin
                                shifter <= { old_serial_in, shifter[7:1] };
                            end
                    BAUD_DIVIDER:
                        bitTimer <= 0;
                    endcase
                end
        end
    end

    // Tri-state the bus outputs.
    assign mem_rdata = enable ? { bufferEmpty, buffer } : 'b0;
    assign mem_ready = rdy;

endmodule
