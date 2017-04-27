/**
 * A Text driver for 640x480, 800x600
 *
 *
 * Control register
 *
 * Write
 *   31                                                          16
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   | O | Cursor active/inactive
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 *
 *   15                           8   7                           0
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * | - | - | Y | Y | Y | Y | Y | Y | - | X | X | X | X | X | X | X | Cursor Y/X coordinates
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 *
 * Read
 *   31                                                          16
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   | O | Cursor active/inactive
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 *
 *   15                           8   7                           0
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 * | - | - | Y | Y | Y | Y | Y | Y | - | X | X | X | X | X | X | X | Cursor Y/X coordinates
 * +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
 *
 *
 */
`define CLK_FREQ_40 // 25, 40 or 50
module vgatext(
    input  wire        pixel_clk_in,
    input  wire        cpu_clk_in,
    input  wire        resetn_in,
    input  wire        enable_ctrl_in,
    input  wire        enable_ram_in,
    input  wire        mem_valid_in,
    output wire        mem_ready_o,
    input  wire        mem_instr_in,
    input  wire [3:0]  mem_wstrb_in,
    input  wire [31:0] mem_wdata_in,
    input  wire [31:0] mem_addr_in,
    output wire [31:0] mem_rdata_o,
    
    output reg  [3:0]  green_o,
    output reg  [3:0]  red_o,
    output reg  [3:0]  blue_o,
    output reg         hsync_o,
    output reg         vsync_o
    
);

`ifdef CLK_FREQ_25
`define LINE_LENGTH    11'd831
`define HSYNC_START    11'd704+11'd64+11'd32
`define HVISIBLE_START 11'd16+11'd64
`define HVISIBLE_END   11'd656+11'd64
`define VVISIBLE_START 11'd10
`define VVISIBLE_END   11'd490
`define FRAME_END      11'd525
`define VSYNC_START    11'd524
`else
`ifdef CLK_FREQ_40
/* For 40 MHz clk 800x600 60 Hz */
`define LINE_LENGTH    11'd1055
`define HSYNC_START    11'd840+11'd88
`define HVISIBLE_START 11'd40
`define HVISIBLE_END   11'd840
`define VVISIBLE_START 11'd16
`define VVISIBLE_END   11'd616
`define FRAME_END      11'd627
`define VSYNC_START    11'd624
`else
`ifdef CLK_FREQ_50
`else
`endif
`endif
`endif

reg [10:0] hsync_cnt, vsync_cnt;
reg [3:0] redr, greenr, bluer;
reg hsyncr, vsyncr;
reg visible;
reg [5:0] blink_cnt; 

reg [6:0] x_cnt, y_cnt;
reg [3:0] line_cnt;
reg [7:0] chars_data, font_data, tshift, shift, color_bus, current_color, tcurrent_color;
wire [7:0] font_bus;
wire [31:0] chars_bus;
wire enable;
wire [11:0] yptr;
wire [6:0] cur_x, cur_y;
reg [3:0] fgreen, fred, fblue;
reg [3:0] bgreen, bred, bblue;

reg [7:0] fontrom[0: 4095];
    reg rdy;
    reg [31:0] ctrl;

// we need 8 kbytes for 100x50
`ifdef SIMULATOR
    reg [7:0] mem0 [0 : 2048 - 1];
    reg [7:0] mem1 [0 : 2048 - 1];
    reg [7:0] mem2 [0 : 2048 - 1];
    reg [7:0] mem3 [0 : 2048 - 1];
    reg [31:0] q;
`else
    wire [31:0] q;
    
vgamem vgamem (
	.address_a(mem_addr_in >> 2),
    .byteena_a(mem_wstrb_in),
	.wren_a(mem_valid_in & enable_ram_in & (|mem_wstrb_in)),
	.data_a(mem_wdata_in),
    .clock_a(cpu_clk_in),
	.clock_b(pixel_clk_in),
	.q_a(q),
	.data_b(32'h0),
	.address_b(yptr >> 1),
	.wren_b(1'b0),
	.q_b(chars_bus)
    );
`endif
    
// CPU interface
   always @(posedge cpu_clk_in) begin
        if (~resetn_in)
            ctrl <= 32'h00010000; // cursor on at 0,0
        if (enable_ram_in & mem_valid_in) 
            begin
`ifdef SIMULATOR
                if (mem_wstrb_in[0])
                    mem0[mem_addr_in >> 2] <= mem_wdata_in[7:0];
                if (mem_wstrb_in[1])
                    mem1[mem_addr_in >> 2] <= mem_wdata_in[15:8];
                if (mem_wstrb_in[2])
                    mem2[mem_addr_in >> 2] <= mem_wdata_in[23:16];
                if (mem_wstrb_in[3])
                    mem3[mem_addr_in >> 2] <= mem_wdata_in[31:24];
                q <= {mem3[mem_addr_in >> 2], mem2[mem_addr_in >> 2], mem1[mem_addr_in >> 2], mem0[mem_addr_in >> 2]};
`endif
                rdy <= 1;
            end
        else   
            if (enable_ctrl_in & mem_valid_in)
                begin
                    if (mem_wstrb_in[0])
                        ctrl[7:0] <= mem_wdata_in[7:0];
                    if (mem_wstrb_in[1])
                        ctrl[15:8] <= mem_wdata_in[15:8];
                    if (mem_wstrb_in[2])
                        ctrl[23:16] <= mem_wdata_in[23:16];
                    if (mem_wstrb_in[3])
                        ctrl[31:24] <= mem_wdata_in[31:24];
                    rdy <= 1;
            //        q <= ctrl;
                end
            else 
                begin
                    rdy <= 0;
                end
    end

    // OR'ed BUS
    assign mem_rdata_o = (enable_ctrl_in) ? ctrl: enable_ram_in ? q : 'b0;
    assign mem_ready_o = rdy;

always @(*)
    begin
        case (current_color[3:0])
            4'b0000: begin fred = 4'h0; fgreen = 4'h0; fblue = 4'h0; end
            4'b0001: begin fred = 4'h0; fgreen = 4'h0; fblue = 4'hA; end
            4'b0010: begin fred = 4'h0; fgreen = 4'hA; fblue = 4'h0; end
            4'b0011: begin fred = 4'h0; fgreen = 4'hA; fblue = 4'hA; end
            4'b0100: begin fred = 4'hA; fgreen = 4'h0; fblue = 4'h0; end
            4'b0101: begin fred = 4'hA; fgreen = 4'h0; fblue = 4'hA; end
            4'b0110: begin fred = 4'hA; fgreen = 4'h6; fblue = 4'h0; end
            4'b0111: begin fred = 4'hA; fgreen = 4'hA; fblue = 4'hA; end
            4'b1000: begin fred = 4'h6; fgreen = 4'h6; fblue = 4'h6; end
            4'b1001: begin fred = 4'h5; fgreen = 4'h5; fblue = 4'hf; end
            4'b1010: begin fred = 4'h5; fgreen = 4'hf; fblue = 4'h5; end
            4'b1011: begin fred = 4'h5; fgreen = 4'hf; fblue = 4'hf; end
            4'b1100: begin fred = 4'hf; fgreen = 4'h5; fblue = 4'h5; end
            4'b1101: begin fred = 4'hf; fgreen = 4'h5; fblue = 4'hf; end
            4'b1110: begin fred = 4'hf; fgreen = 4'hf; fblue = 4'h5; end
            4'b1111: begin fred = 4'hf; fgreen = 4'hf; fblue = 4'hf; end
        endcase
    end

always @(*)
    begin
        case (current_color[7:4])
            4'b0000: begin bred = 4'h0; bgreen = 4'h0; bblue = 4'h0; end
            4'b0001: begin bred = 4'h0; bgreen = 4'h0; bblue = 4'hA; end
            4'b0010: begin bred = 4'h0; bgreen = 4'hA; bblue = 4'h0; end
            4'b0011: begin bred = 4'h0; bgreen = 4'hA; bblue = 4'hA; end
            4'b0100: begin bred = 4'hA; bgreen = 4'h0; bblue = 4'h0; end
            4'b0101: begin bred = 4'hA; bgreen = 4'h0; bblue = 4'hA; end
            4'b0110: begin bred = 4'hA; bgreen = 4'h6; bblue = 4'h0; end
            4'b0111: begin bred = 4'hA; bgreen = 4'hA; bblue = 4'hA; end
            4'b1000: begin bred = 4'h6; bgreen = 4'h6; bblue = 4'h6; end
            4'b1001: begin bred = 4'h5; bgreen = 4'h5; bblue = 4'hf; end
            4'b1010: begin bred = 4'h5; bgreen = 4'hf; bblue = 4'h5; end
            4'b1011: begin bred = 4'h5; bgreen = 4'hf; bblue = 4'hf; end
            4'b1100: begin bred = 4'hf; bgreen = 4'h5; bblue = 4'h5; end
            4'b1101: begin bred = 4'hf; bgreen = 4'h5; bblue = 4'hf; end
            4'b1110: begin bred = 4'hf; bgreen = 4'hf; bblue = 4'h5; end
            4'b1111: begin bred = 4'hf; bgreen = 4'hf; bblue = 4'hf; end
        endcase
    end
// color output

assign enable = (hsync_cnt >= `HVISIBLE_START-11'd8) && (hsync_cnt < `HVISIBLE_END) && 
                (vsync_cnt >= `VVISIBLE_START) && (vsync_cnt < `VVISIBLE_END);

                
assign cur_x = ctrl[6:0];
assign cur_y = ctrl[14:8];
                
always @(posedge pixel_clk_in)
    begin
        if ((hsync_cnt >= `HVISIBLE_START) && (hsync_cnt < `HVISIBLE_END) && (vsync_cnt >= `VVISIBLE_START) && (vsync_cnt < `VVISIBLE_END))
            begin
            if ((cur_x == x_cnt) && (cur_y == y_cnt) && (line_cnt > 4'd13) && blink_cnt[5] && ctrl[16])
					begin
						red_o <= ~bred;
                        green_o <= ~bgreen;
                        blue_o <= ~bblue;
					end
				else
					begin
						red_o <= shift[7] ? fred:bred;
						green_o <= shift[7] ? fgreen:bgreen;
						blue_o <= shift[7] ? fblue:bblue;
						//$write("%c", shift[7] ? 33:32);
					end
            end
        else
            begin
                red_o <= 4'h0;
                green_o <= 4'h0;
                blue_o <= 4'h0;
			end
    end

always @(posedge pixel_clk_in)
	begin
		if (~resetn_in)
			begin
				hsync_cnt <= 11'h0;
				vsync_cnt <= 11'h0;
                blink_cnt <= 6'h0;
			end
		else
			begin
				if (hsync_cnt == `LINE_LENGTH) // end of line
					begin
						hsync_cnt <= 0;
						hsyncr <= 1'b1;
						if (vsync_cnt == `FRAME_END)
							begin
								vsync_cnt <= 11'd0;
								blink_cnt <= blink_cnt + 6'h1; // blinking cursor counter
							end
						else
							vsync_cnt <= vsync_cnt + 11'd1;
					end
				else
					hsync_cnt <= hsync_cnt + 11'd1;
			end
		hsync_o <= hsync_cnt >= `HSYNC_START ? 0:1;
		vsync_o <= vsync_cnt >= `VSYNC_START ? 0:1;
		visible <= (hsync_cnt >= `HVISIBLE_START) && (hsync_cnt < `HVISIBLE_END) && (vsync_cnt >= `VVISIBLE_START) && (vsync_cnt < `VVISIBLE_END);
	end


assign font_bus = fontrom[{ chars_data, line_cnt }];

assign yptr = { y_cnt[5:0], 6'h0 } + { y_cnt[5:0], 5'h0 } + { y_cnt[5:0], 2'h0 } + { 4'h0, x_cnt };

`ifdef SIMULATOR

//assign chars_bus = yptr[0] ? mem2[yptr >> 1]:mem0[yptr >> 1];
//assign color_bus = yptr[0] ? mem3[yptr >> 1]:mem1[yptr >> 1];    
always @(posedge pixel_clk_in) // read memory
	begin
		chars_data <= yptr[0] ? mem2[yptr >> 1]:mem0[yptr >> 1];
        color_bus  <= yptr[0] ? mem3[yptr >> 1]:mem1[yptr >> 1];    
		font_data  <= font_bus;
	end

`else
always @(posedge pixel_clk_in) // read memory
	begin
		chars_data <= yptr[0] ? chars_bus[23:16]:chars_bus[ 7: 0];
        color_bus  <= yptr[0] ? chars_bus[31:24]:chars_bus[15: 8];
		font_data  <= font_bus;
	end
`endif

always @(posedge pixel_clk_in)
	begin
		if (hsync_cnt == 0)
			begin
				x_cnt <= 0;
				//cur_x <= 3; // not needed
			end
		if (vsync_cnt == 0)
			begin
				y_cnt <= 0;
				line_cnt <= 0;
				//cur_y <= 1;
			end
		if ((hsync_cnt == `LINE_LENGTH) && (vsync_cnt >= `VVISIBLE_START))
			begin
				line_cnt <= line_cnt + 1;
				if (line_cnt == 4'hf)
					y_cnt <= y_cnt + 1;
			end
		if (enable)
			begin
				case (hsync_cnt[2:0]) // start of group of 8 consecutive pixels
					0: // read new char/color
						begin    
							shift <= shift << 1;
						    x_cnt <= x_cnt + 1;
						end
					1: // reads font
						shift <= shift << 1;
					2: // load font data into shift register
						begin
							shift <= shift << 1;
							tshift <= font_data;
						end
					3, 4, 5, 6:
						shift <= shift << 1;
					7: // uses read shift register
						begin
							shift <= tshift;
                            tcurrent_color <= color_bus;
                            current_color <= tcurrent_color;
						end
				endcase
			end
	end
initial
	begin
        $readmemh("font256x16l.hex", fontrom);
`ifdef SIMULATOR
        $readmemh("text_pattern0.hex", mem0);
		$readmemh("text_pattern1.hex", mem1);
		$readmemh("text_pattern2.hex", mem2);
		$readmemh("text_pattern3.hex", mem3);
`endif
		vsync_cnt = 0;
		hsync_cnt = 0;
	end
endmodule
