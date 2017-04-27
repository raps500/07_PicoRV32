/**
 * Mono sigma delta audio module
 * 4 kbytes Buffer memory and 4 kbytes for control
 *
 */
 
module sd_audio (
    input  wire        clk,
    input  wire        resetn,
    input  wire        enable_ctrl,
    input  wire        enable_ram,
    input  wire        mem_valid,
    output wire        mem_ready,
    input  wire        mem_instr,
    input  wire [3:0]  mem_wstrb,
    input  wire [31:0] mem_wdata,
    input  wire [31:0] mem_addr,
    output wire [31:0] mem_rdata,
    
    output wire         left_o,
    output wire         right_o,
    output wire         irq_o
);

    reg [7:0] mem0 [0 : 2048 - 1];
    reg [7:0] mem1 [0 : 2048 - 1];
    reg [7:0] mem2 [0 : 2048 - 1];
    reg [7:0] mem3 [0 : 2048 - 1];

    reg [31:0] q;
    reg rdy;
    reg [31:0] ctrl;

    // Sigma Delta DAC
    // Rate is determined by the divisor of the clock
    // 50 MHz / 1024
    
    reg [3:0] divisor;
    reg [5:0] sd_counter;
    reg [15:0] integral_left, integral_right;
    reg old_value_left, old_value_right;
    reg [11:0] index;
    wire active = ctrl[0];
    reg left, right, irq;
    wire [7:0] digital_left;
    wire [7:0] digital_right;
    
    assign irq_o = irq;
    assign left_o = left;
    assign right_o = right;
    
    initial
    begin
        $readmemh("audio_saw.hex", mem0);
        $readmemh("audio_saw.hex", mem1);
        $readmemh("audio_saw.hex", mem2);
        $readmemh("audio_saw.hex", mem3);
    end

    always @(posedge clk) begin
        if (~resetn)
            ctrl <= 32'h0;
        if (enable_ram & mem_valid) 
            begin
                if (mem_wstrb[0])
                    mem0[mem_addr >> 2] <= mem_wdata[7:0];
                if (mem_wstrb[1])
                    mem1[mem_addr >> 2] <= mem_wdata[15:8];
                if (mem_wstrb[2])
                    mem2[mem_addr >> 2] <= mem_wdata[23:16];
                if (mem_wstrb[3])
                    mem3[mem_addr >> 2] <= mem_wdata[31:24];
                q <= {mem3[mem_addr >> 2], mem2[mem_addr >> 2], mem1[mem_addr >> 2], mem0[mem_addr >> 2]};
                rdy <= 1;
            end
        else   
            if (enable_ctrl & mem_valid)
                begin
                    if (mem_wstrb[0])
                        ctrl[7:0] <= mem_wdata[7:0];
                    if (mem_wstrb[1])
                        ctrl[15:8] <= mem_wdata[15:8];
                    if (mem_wstrb[2])
                        ctrl[23:16] <= mem_wdata[23:16];
                    if (mem_wstrb[3])
                        ctrl[31:24] <= mem_wdata[31:24];
                    rdy <= 1;
                    q <= { 20'h0, index };
                end
            else 
                begin
                    rdy <= 0;
                end
    end

    // OR'ed BUS
    assign mem_rdata = (enable_ctrl | enable_ram) ? q : 'b0;
    assign mem_ready = rdy;
        
    assign digital_left = index[0] == 1'b0 ? mem0[index >> 1]:mem2[index >> 1]; // 4 k bytes interleaved per channel
    assign digital_right= index[0] == 1'b0 ? mem1[index >> 1]:mem3[index >> 1];    
    wire [15:0] new_int_left, new_int_right;
    
    assign new_int_left = integral_left + { 8'h0, digital_left } - ((old_value_left) ? 16'h0100:16'h0000);
    assign new_int_right= integral_right + { 8'h0, digital_right } - ((old_value_right) ? 16'h0100:16'h0000);
    
    always @(posedge clk)
        begin
        if (active)
            begin
                divisor <= divisor + 4'h1;
                if (divisor == 4'hf)
                    begin
                        sd_counter <= sd_counter + 6'd1;
                        if (new_int_left[15])
                            begin
                                old_value_left <= 1'b0;
                                left <= 1'b0;
                            end
                        else
                            begin
                                old_value_left <= 1'b1;
                                left <= 1'b1;
                            end
                        if (new_int_right[15])
                            begin
                                old_value_right <= 1'b0;
                                right <= 1'b0;
                            end
                        else
                            begin
                                old_value_right <= 1'b1;
                                right <= 1'b1;
                            end
                        integral_left <= new_int_left;
                        integral_right <= new_int_right;
                        if (sd_counter == 6'd63)
                            index <= index + 12'h1;
                    end
                if (index == 12'd2048) // raise interrupt on buffer half-full
                    irq <= 1'b1;
                else
                    irq <= 1'b0;
            end
        else
            begin
                irq <= 1'b0;
                index <= 12'h0;
                divisor <= 4'h0;
                integral_left <= 16'h0;
                old_value_left <= 1'b0;
                left <= 1'b0;
                old_value_right <= 1'b0;
                integral_right <= 16'b0;
                right <= 1'b0;
                sd_counter <= 6'h0;
            end
        end
 initial
    begin
        irq = 1'b0;
        index = 12'h0;
        divisor = 4'h0;
        integral_left = 16'h0;
        old_value_left = 1'b0;
        left = 1'b0;
        old_value_right = 1'b0;
        integral_right = 16'b0;
        right = 1'b0;
        sd_counter = 6'h0;
    end
    
endmodule