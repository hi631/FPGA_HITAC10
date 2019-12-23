`default_nettype none

module H10(
	input CLK_50M,
	// H10 I/O
//	input      [7:0] H_DIN,  // TRB(Tape Reader)/TIB(Type Input) Input.Data
//	output reg [7:0] H_DOUT, // TPB(Tape Puncher)/TOB(Type output) Output.Data
//	output reg [3:0] H_DSEL, // Device.Select
// output reg       H_DOPT, // H_DSEL Option.Select
//	input      [3:0] H_DRDY, // Device.Ready   TI/TO/YP/TR
//	output reg [3:0] H_DREQ, // Device.Request TI/TO/YP/TR
	// Hard.IO
	input  [2:0] BTN,
	output [7:0] LED,
	output [3:0] DIG,
	// Display(Dumy)
	output [2:0] VGA_R,
	output [2:0] VGA_G,
	output [1:0] VGA_B,
	output VGA_HS,VGA_VS
);
// Dumy.I/O Regs
wire [7:0] H_DIN;
reg  [7:0] H_DOUT;
reg  [3:0] H_DSEL;
reg        H_DOPT;
wire [3:0] H_DRDY;
reg  [3:0] H_DREQ;

// Hitac10 Regs
reg  [14:0] H_PC,H_MA;
reg  [15:0] H_AC,H_AU,H_MBW;
reg  [6:0]  H_IRB;
wire [6:0]  H_IR;
reg  [8:0]  H_AD;
reg  [3:0]  H_CT;
reg         H_CAR,H_IM,H_MR, H_MW;
reg  [3:0]  H_ERR; // pow,mem,adr,opt
wire [15:0] H_MBR; // H_MB(Read)
wire [15:0] H_DSW = 16'h1234; // Front.Panel.Sw(Hard)

wire reset,clkcpu,clkcpux2,locked;
assign reset = !locked || BTN[0];

cgen	cgen (
	.areset (1'b0), .inclk0(CLK_50M), .c0(clkcpux2), .c1(clkcpu),.locked (locked) );

MCORE	MCORE (
	.clock (clkcpux2), .address (H_MA[11:0]),	.wren (H_MW), .data (H_MBW), .q (H_MBR) );

// Main Seq
reg  [3:0]  mseq,brkcnt;
reg  [4:0]  ipldt;
wire [2:0]  f_skip; // P/M Z/NZ C/NC
reg         req_ind,req_jump,req_kct,req_pcn,req_holt,req_trap;
reg         req_step,req_rrun,req_brk,req_mass;
reg  [1:0]  f_intm;
wire        chkerr,chkskip;       
assign H_IR = (mseq==4'h1 && !req_ind) ? H_MBR[15:9] : H_IRB;
assign chkerr = (H_ERR & H_AD[3:0])== 4'b0000 ? 1'b0 : 1'b1;
assign f_skip[0] = H_CAR;
assign f_skip[1] = H_AC==16'h0000 ? 1'b1 : 1'b0;
assign f_skip[2] = H_AC[15];
assign chkskip = (f_skip & H_AD[2:0])==3'b000 ? 1'b0 : 1'b1; 
// IOC
wire [2:0]  devno;
wire [3:0]  f_iod; // TI,TP,HTP,PTR
assign devno = H_AD[7:5]; // Device.namber(001-100)
assign f_iod = devno==3'b001 ? 4'b0001 :devno==3'b010 ? 4'b0010 :devno==3'b011 ? 4'b0100 :devno==3'b100 ? 4'b1000 : 4'b0000;
// OP.Check.OK 
// L A S N X ST SRL/SLL SRA/SSLA HLT ,I ,Z SCAR/LCAR LDSW SIM/RI
// B BAL KCT KNC/KZC KNA/KZA KMA/KPA Trap
always @ (posedge clkcpu) begin
	if(reset) begin 
		//mseq <= 4'h0; H_PC <= 15'h2;
		//mseq <= 4'h0; H_PC <= 15'h200;
		mseq <= 4'he; H_PC <= 15'h2; req_mass <= 1'b1; // Load IPL & Load OML & MASS 
		H_AC <= 16'h0; H_MR <= 1'b0; H_MW <= 1'b0; 
		H_IM <= 1'b0; H_ERR <= 4'b0000; H_CAR <= 1'b0;
		req_ind <= 1'b0; req_jump <= 1'b0; req_kct <= 1'b0;
		req_holt <= 1'b0; req_brk <= 1'h0; req_pcn <= 1'b0; req_trap <= 1'b0; 
		ipldt <= 5'h0; f_intm <= 2'b00; brkcnt <= 4'h0; 
		H_DSEL <= 4'b0000; H_DOPT <= 1'b0; H_DREQ <= 4'b0000;
		end
	else begin
// Fetch cycl
		case(mseq[3:0])
		4'h0: begin 
			if(req_ind) H_MA <= H_MBR[14:0];
			else if(req_jump) begin H_PC <= H_MA; req_jump <= 1'b0; end
			else        H_MA <= H_PC;
			// Read OML -> MASS Tape
			if(req_mass && req_holt) begin
				req_mass <= 1'b0; req_holt <= 1'b0; H_PC <= 15'h20;
			end
			// Step Control
			if(!(req_holt || req_brk) || req_step || req_ind) mseq <= 4'h1; 
			end
		4'h1: begin
			if(req_rrun) begin req_holt <= 1'b0; req_brk <= 1'b0; brkcnt <= 4'h0; end // Step.Clear
			//if(H_PC==15'h61) begin // Count and Stop 
			//	brkcnt <= brkcnt + 4'h1; if(brkcnt==4'h2) req_brk <=1'h1; end
			if(H_PC==15'h1C8) req_brk <= 1'b1;

			if(!req_ind) begin 
				H_IRB <= H_MBR[15:9]; H_AD <= H_MBR[8:0]; 
				if(H_IR[6:5]==2'b00 || H_IR[6:4]==3'b010) begin // Use I,M
					if(H_MBR[9]) H_MA <= {H_PC[14:9],H_MBR[8:0]}; // M=1
					else         H_MA <= {6'h0,H_MBR[8:0]};       // M=0
					if(H_MBR[10]) req_ind <= 1'b1;                // I=1
					if(H_IR[6:2]==5'h08) req_jump <= 1'b1;      // (40) B
					else if(H_IR[6:2]==5'h0b) req_trap <= 1'b1; // (58) TRap
				end	
				if(H_IR[6:2]==5'b01111) req_trap <= 1'b1;      // (78) Trap 
				else if(H_IR[6:2]==5'b01100 ||                 // (60)
					     H_IR[6:4]==3'b101   ||                 // (A0) - (B8)
					     H_IR[6:5]==2'b11) req_trap <= 1'b1;    // (C0) - (F8)

			end else req_ind <= 1'b0;
			mseq <= 4'h2;
			end
		4'h2: begin
			if(req_ind)       mseq <= 4'h0;  
			else if(req_jump) mseq <= 4'h0; 
			else if(req_trap) begin 
				H_ERR[0] <= 1'b1;	req_trap <= 1'b0; 
				if(H_IM) mseq <= 4'h6;
				else     begin H_PC <= H_PC + 15'h1; mseq <= 4'h0; end // Error Skip
				end 
			else              mseq <= 4'h3;
		
			end
// Exec cycl
		4'h3: begin 
			if(H_IR[6:2]==5'b00111) begin H_MBW <= H_AC; H_MW <= 1'b1; end // ST
			else
				if(H_IR[6:2]==5'b01001) begin 
					H_MBW <= H_PC + 15'h1; H_PC <= H_MA; H_MW <= 1'b1; end // BAL (Write Ret.Adr)
			else
				if(H_IR[6:2]==5'b01110) begin // IOC
					H_DSEL <= f_iod;
					if(H_AD[3]) H_DOPT <= 1'b1;
					else        H_DOPT <= 1'b0;
				end
			if(H_IR[6:2]==5'b10011) H_CAR <=1'b0; // For SLA
			mseq <= 4'h4;	
			end
		4'h4: begin
			if(H_MW) H_MW <= 1'b0;
			case(H_IR[6:5])
			2'b00: 
				case(H_IR[4:2])
					3'h0: ; // TRP
					3'h1: H_AC <= H_MBR; // L AC=(M)
					3'h2: {H_CAR,H_AC} <= {1'b0,H_AC} + {1'b0,H_MBR}; // ADD
					3'h3: {H_CAR,H_AC} <= {1'b0,H_AC} - {1'b0,H_MBR}; // SUB
					3'h4: H_AC <= H_AC & H_MBR; // AND
					3'h5: H_AC <= H_AC ^ H_MBR; // EOR
					3'h6: H_AC <= H_AC | H_MBR; // OR
					3'h7: ; // ST
				endcase
			2'b01: 
				case(H_IR[4:2])
					3'b000: ; // B
					3'b001: ; // BAL
					3'b010: begin // KCT
						if(!req_kct) begin
							H_MBW <= H_MBR + 16'h1; H_MW <= 1'b1;
							req_kct <= 1'b1;
						end 
						end
					3'b011: ; // Trap(58)
					3'b100: ; // EX(60)
					3'b101: begin // Kxx - HOLT (68)
						case(H_IR[1:0])
							2'b00: begin // Skip
								case(H_AD[8:7])
									2'b00:
										if(H_AD[6])  // K(N,Z,M,P)(C,A) Skip.on CAR/AC 01101 00 00 1xxxccc 
											if((H_AD[5] && !chkskip) || (!H_AD[5] && chkskip)) // On.Flag,Skip
												req_pcn <= 1'b1; 
										// else = NE 0110 00 00 0xxxxxx
									2'b01: begin// K(P,M,A,O)E Skip.ERR 01101 00 01 CDxeeee
										if(H_AD[6]) H_ERR <= H_ERR & ~H_AD[3:0];
										if((H_AD[5] && !chkerr) || (!H_AD[5] && chkerr)) // On.Err.Skip
											req_pcn <= 1'b1;
										end
									2'b10: H_AC <= {15'h0,H_CAR}; // LCAR 01101 00 10 xxxxxxx
									2'b11: ; // 
								endcase
								end
							2'b01:  // SCAR/LDSW 					01101 01 x0 xxxxxxx
								if(H_AD[8]) H_AC <= H_DSW;    // LDSW 
								else        H_CAR <= H_AC[0]; // SCAR
							2'b10:  // INT       					01101 10 x0 xxxxxxx
								if(H_AD[8]) H_IM <= 1'b0;    // RIM
								else        f_intm <= 2'b01; // SIM(Delay 1cycl)
							2'b11: req_holt <= 1'b1;        // HOLT 	01101 11 10 xxxxxxx
						endcase
						end
					3'b110: begin // IOC(70) 
						if(H_AD[0]) 
							if((H_DRDY & H_DSEL)!=4'b0000) req_pcn <= 1'b1; // I/O.flag=1 Skip.on
						if(H_AD[1]) begin
							H_DREQ <= H_DREQ & ~H_DSEL;         // flag.Clear(if Device==TI Start) 
							H_DSEL <= 4'b0000; H_DOPT <= 1'b0;
							if(H_DSEL==4'b0001) 
								if(!H_AD[4]) H_AC[7:0] <= H_AC[7:0] | H_DIN; // PTR Data.Input
								else         H_AC <= {8'h00,H_DIN}; // if CAC=1 --> Clear.AC ??
							end
						if(H_AD[2]) begin
							if(H_DSEL==4'b0010) H_DOUT <= H_AC[7:0];
							if(H_DSEL==4'b0100) H_AC[7:0] <= H_AC[7:0] | H_DIN;
							if(H_DSEL!=4'b0100) H_DREQ <= H_DREQ | H_DSEL;
							if(H_DSEL==4'b1000) H_DOUT <= H_AC[7:0];
							end
						if(H_AD[3]) begin
							if(H_DSEL==4'b0001) H_AC[1:0] <= H_DIN[1:0]; 
							if(H_DSEL==4'b0010) H_AC[0:0] <= H_DIN[0];
							end
						//H_DSEL <= 4'b0000; H_DOPT <= 1'b0;
						end
				endcase
			2'b10: begin // (80) - (98) 
				case(H_IR[3:2])
					2'b00: H_AC <= H_AC >>  1; // SRL
					2'b01: {H_CAR,H_AC} <= {1'b0,H_AC} <<  1; // SLL Set car
					2'b10: begin H_AC <= {H_AC[0],H_AC[15:1]}; H_CAR <= 1'b0; end // SRA
					2'b11: begin  // SLA
						if(H_AC[15]!=H_AC[14]) H_CAR <= 1'b1;
						H_AC <= {H_AC[14:0],1'b0};
						end
				endcase
				end
			2'b11: ; // (A0) - (B8)
			endcase
			
			if(H_IR[6:4]==3'b100 && H_AD[3:0]!=4'h1) H_AD[3:0] <= H_AD[3:0] - 4'h1; // Sxx 
			else                                     mseq <= 4'h5;
			
			end
		4'h5: begin 
				if(H_IR==7'b10011) H_CAR <= H_AC[15] ^ H_AC[14];
				if(req_kct) begin 
					req_kct <= 1'b0; H_MW <= 1'b0; 
					if(H_MBW==16'h0000) H_PC <= H_PC + 15'h2;
					else                H_PC <= H_PC + 15'h1;
					mseq <= 4'h0;
					end
				else begin 
					if(req_pcn) begin H_PC <= H_PC + 15'h2; req_pcn <= 1'b0; end
					else        H_PC <= H_PC + 15'h1;
					if(H_IM && H_ERR!=4'b0000) mseq <= 4'h6; // Err.Interrupt
					else                       mseq <= 4'h0;
					if(f_intm != 2'b00) begin 
						f_intm <= f_intm + 2'b01;
						if(f_intm == 2'b10) begin H_IM<= 1'b1; f_intm <= 2'b00; end 
						end
				end
			end
// INT cycl
		4'h6: begin
			H_IM <= 1'b0;
			H_MA <= 15'h0; H_MBW <= H_PC; H_MW <= 1'b1;
			mseq <= 4'h7;
			end
		4'h7: begin 
			H_MW <= 1'b0;
			H_PC <= 15'h1;
			mseq <= 4'h8;
			end
		4'h8: mseq <= 4'h0;
// IPL(Test)
		4'he: begin
			case(ipldt)
				5'h00: H_MBW <= 16'h0000; // Work
				5'h01: H_MBW <= 16'h0001; // Store.Addr
				5'h02: H_MBW <= 16'h7024; // STR			Start.HTR
				5'h03: H_MBW <= 16'h8804; // SLL  4		AC << 4
				5'h04: H_MBW <= 16'h3800; // ST   0		0(Adr) <- AC
				5'h05: H_MBW <= 16'h7021; // KTR			if TRF==1 Skip +2 
				5'h06: H_MBW <= 16'h4005; // B *-1		Wait.For.Input
				5'h07: H_MBW <= 16'h7032; // RTR ,C		Clear.AC? & Read.Data -> AC 
				5'h08: H_MBW <= 16'h880C; // SLL			Clear.Hi.4bit & Set.CAR
				5'h09: H_MBW <= 16'h800C; // SRL			Set.Lo.4bit
				5'h0a: H_MBW <= 16'h3000; // O 0			AC = AC or 0(Adr)
				5'h0b: H_MBW <= 16'h6841; // KNC			if CAR==0 Skip +2
				5'h0c: H_MBW <= 16'h4002; // B    2		Jump 2(Adr)
				5'h0d: H_MBW <= 16'h3C01; // ST ,I 1	(1) = AC
				5'h0e: H_MBW <= 16'h5001; // KCT  1		1(Adr)++
				5'h0f: H_MBW <= 16'h6842; // KZA			if AC==0 Start.OML
				5'h10: H_MBW <= 16'h4002; // B    2		Jump 2(Adr)
			endcase
			H_MA <= {10'h0,ipldt}; H_MW <=1'b1; mseq <= 4'hf;
			end
		4'hf: begin
			H_MW <=1'b0;
			if(ipldt==5'h10) mseq <= 4'h0;
			else             mseq <= 4'he;
			ipldt <= ipldt + 5'h1;
			end
		endcase
		//
		if(H_MA[14:12]!=3'b000) H_ERR <= H_ERR | 4'b0010; // Adr.Error
	end
end
// Debug.Key
reg  [2:0]  btnod,btnof;
reg  [11:0] btncnt;
reg         btnmode;
reg  [3:0]  dpdp;
wire [15:0] dp16;
assign dp16 = BTN[2] ? H_PC : dpdp[3] ? H_AC : dpdp[2] ? H_PC : dpdp[1] ? H_MA : H_MBR;
always @ (posedge clkcpu) begin
	if(reset) begin 
		dpdp <= 4'b1000; req_step <= 1'b0; btnod <= 3'b000; btnof <= 3'b000; req_rrun <= 1'b1;
	end else begin
		if(BTN!=btnod) begin btncnt <= 12'h0; btnod <= BTN; end
		else if(!btncnt[11]) btncnt <= btncnt + 12'h1;
		
		if(btncnt==12'h7ff) begin
			if(BTN[2:0]>btnof) begin
				if(BTN[2:1]==2'b11) req_rrun <= !req_rrun;
				else begin
					if(BTN[1]) begin
						dpdp <= dpdp >> 1;
						if(dpdp[3:1]==3'b000) dpdp <= 4'b1000;
					end
					if(BTN[2]) req_step <= 1'b1;
				end
			end
			btnof <= BTN[2:0];
		end else begin
			if(req_step) req_step <= 1'b0;
		end
	end
end

// Dumy.I/O
HTP HTP( 
	.clk(clkcpux2), .reset(reset), .H_DIN(H_DIN), .H_DOUT(H_DOUT), 
	.H_DSEL(H_DSEL), .H_DOPT(H_DOPT), .H_DRDY(H_DRDY), .H_DREQ(H_DREQ) );
// Display.Regs
SSEG SSEG( 
	.clk_50M(CLK_50M), .reset(reset), .data(dp16), .dp_in(~dpdp), .sseg(LED), .an(DIG) );
// VGA.Display
VGA VGA(
	.CLK_50M(CLK_50M), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS) );

endmodule

`default_nettype wire