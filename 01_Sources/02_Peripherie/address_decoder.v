//
// address_decoder
//
// Here is where we decide what devices on what addresses get enabled.
//
`include "timescale.vh"

module address_decoder (
    input wire [31:0] address, 
    output reg enable_audio_ctrl,
    output reg enable_video_ctrl,
    output reg enable_spi,
    output reg enable_timers,
    output reg enable_uart_tx,
    output reg enable_uart_rx,
    output reg enable_gpio,
    output wire enable_audio_ram,
    output wire enable_video_ram,
    output wire enable_sdram,
    output wire enable_sram
            
    );

assign enable_sram = (address[31:17] == 15'b0000_0000_0000_000) ? 1'b1:1'b0; // 128 kbytes at address 0x0000_0000..0x0001_FFFF
assign enable_sdram = (address[31:27] == 5'b0000_0) ? 1'b1:1'b0; // 64 Mbytes at address 0x0400_0000..0x07FF_FFFF

assign enable_audio_ram = (address[31:13] == 19'b1111_1111_1111_1111_001) ? 1'b1:1'b0; // // Audio RAM
assign enable_video_ram = (address[31:13] == 19'b1111_1111_1111_1111_010) ? 1'b1:1'b0; // Video RAM text + attribute

    always @(address) begin

        enable_audio_ctrl = 1'b0;
        enable_video_ctrl = 1'b0;
        enable_spi = 1'b0;
        enable_timers = 1'b0; // Timers
        enable_uart_tx = 1'b0; // UART TX
        enable_uart_rx = 1'b0; // UART RX
        enable_gpio = 1'b0;
        case (address[31:4])
            28'hffff000: enable_audio_ctrl = 1'b1;
            28'hffff001: enable_video_ctrl = 1'b1;
            28'hffff002: enable_spi = 1'b1;
            28'hffff003: enable_timers = 1'b1; // Timers
            28'hffff004: enable_uart_tx = 1'b1; // UART TX
            28'hffff005: enable_uart_rx = 1'b1; // UART RX
            28'hffff006: enable_gpio = 1'b1; // GPIO
            default: ;
        endcase
    end
endmodule
