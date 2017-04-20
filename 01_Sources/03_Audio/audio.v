/**
 * Mono sigma delta audio module
 * 4 kbytes Buffer memory and 4 kbytes for control
 *
 */
 
module sd_audio (
    input  wire        clk,
    input  wire        enable,
    input  wire        mem_valid,
    output wire        mem_ready,
    input  wire        mem_instr,
    input  wire [3:0]  mem_wstrb,
    input  wire [31:0] mem_wdata,
    input  wire [31:0] mem_addr,
    output wire [31:0] mem_rdata
    
    output wire         left_o,
    output wire         irq_o
);

    reg [7:0] mem0 [0 : 1024 - 1];
    reg [7:0] mem1 [0 : 1024 - 1];
    reg [7:0] mem2 [0 : 1024 - 1];
    reg [7:0] mem3 [0 : 1024 - 1];

    reg [31:0] q;
    reg rdy;
    reg [31:0] ctrl;
    
    wire control_enable = mem_valid & (mem_addr[12]) & enable;
    wire buffer_enable = mem_valid & (~mem_addr[12]) & enable;
    initial
    begin
        //$readmemh("firmware/firmware0.hex", mem0);
        //$readmemh("firmware/firmware1.hex", mem1);
        //$readmemh("firmware/firmware2.hex", mem2);
        //$readmemh("firmware/firmware3.hex", mem3);
    end

    always @(negedge clk) begin
        if (buffer_enable) 
            begin
                if (mem_wstrb[0])
                    mem0[mem_addr >> 2] <= mem_wdata[7:0];
                if (mem_wstrb[1])
                    mem1[mem_addr >> 2] <= mem_wdata[15:8];
                if (mem_wstrb[2])
                    mem2[mem_addr >> 2] <= mem_wdata[23:16];
                if (mem_wstrb[3])
                    mem3[mem_addr >> 2] <= mem_wdata[31:24];
                rdy <= 1;
            end
        else   
            if (control_enable)
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
                end
            else 
                begin
                    rdy <= 0;
                end
        q <= {mem3[mem_addr >> 2], mem2[mem_addr >> 2], mem1[mem_addr >> 2], mem0[mem_addr >> 2]};
    end

    // Tri-state the outputs.
    assign mem_rdata = enable ? q : 'b0;
    assign mem_ready = enable;
    
    // Sigma Delta DAC
    // Rate is determined by the divisor of the clock
    // 50 MHz / 1024
    
    reg [3:0] divisor;
    reg [5:0] sd_counter;
    reg [15:0] integral;
    reg old_value;
    reg [11:0] index;
    wire active = ctrl[0];
    reg left, irq;
    
    assign irq_o = irq;
    assign left_o = left;
    
    wire [7:0] digital_left;
    
    assign digital_left = index[1:0] == 2'b00 ? mem0[index >> 2]:
                          index[1:0] == 2'b01 ? mem1[index >> 2]:
                          index[1:0] == 2'b20 ? mem2[index >> 2]:mem3[index >> 2];
    
    
    always @(posedge clk)
        begin
        if (active)
            begin
                divisor <= divisor + 4'h1;
                if (divisor == 4'hf)
                    begin
                        sd_counter <= sd_counter + 6'd1;
                        integral <= integral +  (old_value) ? { 8'hff, digital_left }:{ 8'h0, digital_left };
                        if (integral + { 8'h0, digital_left } > 16'd32767)
                            begin
                                old_value <= 1'b1;
                                left <= 1'b1;
                            end
                        else
                            begin
                                old_value <= 1'b0;
                                left <= 1'b0;
                            end
                        if (sd_counter == 6'd63)
                            index <= index + 12'h1;
                    end
                if (index == 12'd2048) // raise interrupt on buffer half-empty
                    irq <= 1'b1;
                else
                    irq <= 1'b0;
            end
        else
            begin
                irq <= 1'b0;
                index <= 12'h0;
                divisor = 4'h0;
                integral = 16'h0;
                old_value = 1'b0;
                left = 1'b0;
                sd_counter = 6'h0;
            end
        end
 initial
    begin
        divisor = 0;
        ctrl = 0;
        sd_counter = 0;
        integral = 0;
        old_value = 0;
        index = 0;
        left = 0;
    end
    
endmodule