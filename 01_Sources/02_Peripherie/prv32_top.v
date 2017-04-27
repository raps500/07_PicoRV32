//
// Pico RISCV32 top file
//
// DE10-Lite
//
`include "timescale.vh"

module prv32_top (

    input wire           CLOCK_50, 
    input wire           reset_btn, 
    output wire [9:0]    LED,  
    
    input wire [0:0]     porta_in,
    // UART
    output wire          UART_TX,
    input wire           UART_RX,
    output wire          audio_test_out,
    output wire          bit_clock,
    output wire [3:0]    RND_OUT,
    
    output wire          audio_left_o,
    output wire          audio_right_o,
    
    output wire  [3:0]   green_o,
    output wire  [3:0]   red_o,
    output wire  [3:0]   blue_o,
    output wire          hsync_o,
    output wire          vsync_o
    
    );

    wire        trap;

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    wire [31:0] mem_rdata_mem;
    wire [31:0] mem_rdata_gpio;
    wire [31:0] mem_rdata_uart_tx;
    wire [31:0] mem_rdata_uart_rx;
    wire [31:0] mem_rdata_timer;
    wire [31:0] mem_rdata_audio;
    wire [31:0] mem_rdata_video;
    
    wire        mem_ready_mem;
    wire        mem_ready_gpio;
    wire        mem_ready_uart_tx;
    wire        mem_ready_uart_rx;
    wire        mem_ready_timer;
    wire        mem_ready_audio;
    wire        mem_ready_video;
    
    // Look-Ahead Interface
    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [3:0]  mem_la_wstrb;

    wire        pcpi_valid;
    wire [31:0] pcpi_insn;
    wire [31:0] pcpi_rs1;
    wire [31:0] pcpi_rs2;
    reg         pcpi_wr;
    reg  [31:0] pcpi_rd;
    reg         pcpi_wait;
    reg         pcpi_ready;

    // gpio
    wire [31:0] gpio_in;
    
    // IRQ Interface
    reg  [31:0] irq;
    wire [31:0] eoi;

    // Trace Interface
    wire        trace_valid;
    wire [35:0] trace_data;

    // Peripheral enables
    wire enable_audio_ctrl;
    wire enable_video_ctrl;
    wire enable_spi;
    wire enable_timers;
    wire enable_uart_tx;
    wire enable_uart_rx;
    wire enable_gpio;
    wire enable_audio_ram;
    wire enable_video_ram;
    wire enable_sdram;
    wire enable_sram;

    reg resetn = 0;
    reg [7:0] resetCount = 0;

    wire CLOCK_100;
    wire CLOCK_100_SHIFTED;
    wire pixel_clock;
    wire CLOCK_LOCKED;

    always @(posedge CLOCK_100)
    begin
        if (reset_btn == 1'b0)
            begin
                resetn <= 1'b0;
                resetCount <= 8'h0;
            end
        else
            resetCount <= resetCount + 1;
        
        if (resetCount == 100) resetn <= 1;
    end

assign gpio_in = { 31'h0, porta_in[0] };
assign audio_test_out = porta_in[0]; // let's see what the input saw
    
`ifndef SIMULATION
    // Generate 100MHz and 10MHz clocks
    // See Quartus PLL tutorial here: http://www.emb4fun.de/fpga/nutos1/
    pll_sys pll_sys_inst (
        .inclk0 (CLOCK_50),      // The input clock
        .c0 (CLOCK_100),         // 100MHz clock
        .c1 (CLOCK_100_SHIFTED), // 100MHz clock with phase shift of -54 degrees for SDRAM
        .c2 (pixel_clock),       // 40MHz pixel clock
        .locked (CLOCK_LOCKED)   // PLL is locked signal
    );
`else
    assign CLOCK_100 = CLOCK_50;
`endif

    memory mem (
        .clk(CLOCK_100),
        .enable(enable_sram),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready_mem),
        .mem_instr(mem_instr),
        .mem_wstrb(mem_wstrb),
        .mem_wdata(mem_wdata),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata_mem)
    );

    gpio gpio (
        .clk(CLOCK_100),
        .resetn(resetn),
        .enable(enable_gpio),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready_gpio),
        .mem_instr(mem_instr),
        .mem_wstrb(mem_wstrb),
        .mem_wdata(mem_wdata),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata_gpio),
        .gpio(LED),
        .gpio_in(gpio_in)
    );

    uart_rx uart_rx (
        .clk(CLOCK_100),
        .resetn(resetn),
        .enable(enable_uart_rx),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready_uart_rx),
        .mem_instr(mem_instr),
        .mem_wstrb(mem_wstrb),
        .mem_wdata(mem_wdata),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata_uart_rx),
        .bit_clock_o(bit_clock),
        .serial_in(UART_RX)
    );

    uartTx uartTx (
        .clk(CLOCK_100),
        .resetn(resetn),
        .enable(enable_uart_tx),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready_uart_tx),
        .mem_instr(mem_instr),
        .mem_wstrb(mem_wstrb),
        .mem_wdata(mem_wdata),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata_uart_tx),
        .serialOut(UART_TX)
    );

    timer timer (
        .clk(CLOCK_100),
        .resetn(resetn),
        .enable(enable_timers),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready_timer),
        .mem_instr(mem_instr),
        .mem_wstrb(mem_wstrb),
        .mem_wdata(mem_wdata),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata_timer)
    );

    sd_audio sd_audio (
        .clk(CLOCK_100),
        .resetn(resetn),
        .enable_ctrl(enable_audio_ctrl),
        .enable_ram(enable_audio_ram),
        .mem_valid(mem_valid),
        .mem_ready(mem_ready_audio),
        .mem_instr(mem_instr),
        .mem_wstrb(mem_wstrb),
        .mem_wdata(mem_wdata),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata_audio),
        .left_o(audio_left_o),
        .right_o(audio_right_o)
        
    );

    vgatext vgatex(
        .pixel_clk_in(pixel_clock),
        .cpu_clk_in(CLOCK_100),
        .resetn_in(resetn),
        .enable_ctrl_in(enable_video_ctrl),
        .enable_ram_in(enable_video_ram),
        .mem_valid_in(mem_valid),
        .mem_ready_o(mem_ready_video),
        .mem_instr_in(mem_instr),
        .mem_wstrb_in(mem_wstrb),
        .mem_wdata_in(mem_wdata),
        .mem_addr_in(mem_addr),
        .mem_rdata_o(mem_rdata_video),

        .green_o(green_o),
        .red_o(red_o),
        .blue_o(blue_o),
        .hsync_o(hsync_o),
        .vsync_o(vsync_o)
    );
    
    address_decoder ad (
        .address(mem_addr),
        .enable_audio_ctrl(enable_audio_ctrl),
        .enable_video_ctrl(enable_video_ctrl),
        .enable_spi(enable_spi),
        .enable_timers(enable_timers),
        .enable_uart_tx(enable_uart_tx),
        .enable_uart_rx(enable_uart_rx),
        .enable_gpio(enable_gpio),
        .enable_audio_ram(enable_audio_ram),
        .enable_video_ram(enable_video_ram),
        .enable_sdram(enable_sdram),
        .enable_sram(enable_sram)
    );

    assign  mem_rdata = mem_rdata_mem | mem_rdata_gpio | mem_rdata_uart_tx | mem_rdata_uart_rx | mem_rdata_timer | mem_rdata_audio | mem_rdata_video;
    assign  mem_ready = mem_ready_mem | mem_ready_gpio | mem_ready_uart_tx | mem_ready_uart_rx | mem_ready_timer | mem_ready_audio | mem_ready_video;
    
    
    
    defparam cpu.BARREL_SHIFTER = 1;
    defparam cpu.TWO_CYCLE_COMPARE = 1;
    defparam cpu.TWO_CYCLE_ALU = 1;
    defparam cpu.ENABLE_PCPI = 1;        //
    defparam cpu.ENABLE_FAST_MUL = 1;    // MUL and DIV cost 564 LE and !
    defparam cpu.ENABLE_DIV = 1;         //

    picorv32 cpu (
        .clk(CLOCK_100),
        .resetn(resetn),
        .trap(trap),

        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),

        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),

        // Look-Ahead Interface
        .mem_la_read(mem_la_read),
        .mem_la_write(mem_la_write),
        .mem_la_addr(mem_la_addr),
        .mem_la_wdata(mem_la_wdata),
        .mem_la_wstrb(mem_la_wstrb),

        // Pico Co-Processor Interface (PCPI)
        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
        .pcpi_rs2(pcpi_rs2),
        .pcpi_wr(pcpi_wr),
        .pcpi_rd(pcpi_rd),
        .pcpi_wait(pcpi_wait),
        .pcpi_ready(pcpi_ready),

        // IRQ Interface
        .irq(irq),
        .eoi(eoi),

        // Trace Interface
        .trace_valid(trace_valid),
        .trace_data(trace_data)
    );

    // Put the clocks out on some pins so we can see them working.
    assign RND_OUT = {CLOCK_100, CLOCK_100_SHIFTED, pixel_clock, CLOCK_LOCKED};

endmodule
