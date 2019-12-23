`timescale 1ns / 1ps

module VGA(CLK_50M, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS);

	input CLK_50M;
	output [2:0] VGA_R;
	output [2:0] VGA_G;
	output [1:0] VGA_B;
	output VGA_HS;
	output VGA_VS;

	reg [1:0] clock_count;
	wire clk;
	assign clk = clock_count[0];

	reg [9:0] hcount;
	reg [9:0] vcount;

	reg [3:0] vga_r_out;
	reg [3:0] vga_g_out;
	reg [3:0] vga_b_out;
	reg VGA_HS_out;
	reg VGA_VS_out;

	assign VGA_R = vga_r_out;
	assign VGA_G = vga_g_out;
	assign VGA_B = vga_b_out;
	assign VGA_HS = VGA_HS_out;
	assign VGA_VS = VGA_VS_out;

	reg [2:0] out_count;
	reg [6:0] out_color;

	parameter H_ACTIVE_PIXEL_LIMIT = 640;
	parameter H_FPORCH_PIXEL_LIMIT = 656; // 640+16
	parameter H_SYNC_PIXEL_LIMIT   = 752; // 640+16+96
	parameter H_BPORCH_PIXEL_LIMIT = 800; // 640+16+96+48

	parameter V_ACTIVE_LINE_LIMIT = 480;
	parameter V_FPORCH_LINE_LIMIT = 490; // 480+10
	parameter V_SYNC_LINE_LIMIT   = 492; // 480+10+2
	parameter V_BPORCH_LINE_LIMIT = 521; // 480+10+2+29

	reg [31:0] c;
	reg ledout;

always @(posedge clk)
begin
	if (c == 32'd25000000)
	begin
		ledout <= ~ledout;
		c <= 0;
	end
	else
		c <= c + 1;
end

always @(posedge CLK_50M)
begin
	clock_count <= clock_count + 1;
end

always @(posedge clk)
begin
	if (hcount < H_BPORCH_PIXEL_LIMIT)
		hcount <= hcount + 1;
	else
	begin
		hcount <= 0;
		if (vcount < V_BPORCH_LINE_LIMIT) vcount <= vcount + 1;
		else vcount <= 0;
	end

	if (hcount < H_ACTIVE_PIXEL_LIMIT &&
		vcount < V_ACTIVE_LINE_LIMIT) // active video
	begin
		if (out_count < 4)
			out_count <= out_count + 1;
		else begin
			out_count <= 0;
			out_color <= out_color + 1;
		end
		if (~out_color[4]) vga_b_out <= ~out_color[3:0];
		else vga_b_out <= 0;
		if (~out_color[5]) vga_r_out <= ~out_color[3:0];
		else vga_r_out <= 0;
		if (~out_color[6]) vga_g_out <= ~out_color[3:0];
		else vga_g_out <= 0;
	end
	else
	case (hcount)
	H_ACTIVE_PIXEL_LIMIT : // front porch
	begin
		vga_r_out <= 4'd0;
		vga_g_out <= 4'd0;
		vga_b_out <= 4'd0;
		out_count <= 0;
		out_color <= 0;
	end
	H_FPORCH_PIXEL_LIMIT : // sync pulse
		VGA_HS_out <= 1'b0;
	H_SYNC_PIXEL_LIMIT : // back porch
		VGA_HS_out <= 1'b1;
	endcase

	case (vcount)
	V_ACTIVE_LINE_LIMIT : // front porch
		;
	V_FPORCH_LINE_LIMIT : // sync pulse
		VGA_VS_out <= 1'b0;
	V_SYNC_LINE_LIMIT : // back porch
		VGA_VS_out <= 1'b1;
	endcase
end

endmodule
