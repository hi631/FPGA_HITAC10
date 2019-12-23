`default_nettype none
module HTP( clk, reset, H_DIN, H_DOUT, H_DSEL, H_DOPT, H_DRDY, H_DREQ );
//	
input  wire clk;
input  wire reset;
output reg [7:0] H_DIN;
input      [7:0] H_DOUT; // Not.Use
input      [3:0] H_DSEL;
input            H_DOPT;
output reg [3:0] H_DRDY;
input      [3:0] H_DREQ;
//
reg  [13:0] omladr;
reg  [3:0]  dreqd;
//(* syn_preserve = 1 *)reg  [7:0]  pbit;
reg  [7:0]  pbit /* synthesis preserve = 1 */;
(* preserve = 1 *) reg         pflg;
wire  [7:0]  omldt;
omltape	omltape ( .clock (clk),	.address (omladr), .q (omldt) );

always@( posedge clk or posedge reset ) begin
	if(reset) begin 
		H_DRDY <= 4'h0; omladr <= 12'h000; H_DIN <= 8'h0; dreqd <= 4'h0; pbit <= 8'h0; pflg <= 1'b0;
	end else begin
		// Req to Rdy
		dreqd <= H_DREQ;
		if(H_DREQ[0]) begin
			if(H_DREQ[0] && !dreqd[0]) begin pbit <= 8'h1; pflg <= 1'b0; end
		end else begin
			H_DRDY[0] <= 1'b0; 
		end
		// Set Parity
		if(pbit!=8'h0) begin
			if((omldt & pbit)!=8'h0) pflg <= !pflg;
			if(pbit[7]==1'b1) begin 
				H_DIN <= {pflg,omldt[6:0]}; // Add.Parity.Bit
				H_DRDY[0] <= 1'b1;
				omladr <= omladr + 12'h1;
				pbit <= 8'h0;
			end
			pbit <= pbit << 1;
		end	
		
	end
end
	

endmodule
`default_nettype wire