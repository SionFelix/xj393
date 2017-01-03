//
//top.v
//
module top
  (
  input  wire        CLK_50M,
  input 	wire 			RST,
  
  input wire 			SW,
  
  input wire 			PS2_CK1,
  input wire			PS2_DT1,

  output wire  [3:0] VGA_R,
  output wire  [3:0] VGA_G,
  output wire  [3:0] VGA_B,
  output wire        VGA_HSYNC,
  output wire        VGA_VSYNC,
  output reg [3:0] TSTO,
  
  inout wire CC,
  
  input wire PROG,
  //input wire CHNG_ROM,
  
 // input VCONN1, 
 // input VCONN2,
  
 // output wire SHDN5,
 // output wire EN1_1,
  
  input wire DSW0,
  input wire DSW1,
  input wire DSW2,
  input wire DSW3,
  
  //output EN1_1_2,
  output wire OE,
  output wire OE2,
  
  output wire V1ON,
  output wire V1ON2,
  
  output wire V2ON,
  output wire V2ON2,
/*
	input wire TST_STA,
	output wire TESTER_CMPLT,
	output wire TESTER_BSY,
	output wire TESTER_STOP,
	*/
	input wire SOT,
	
	output wire EOT,
	
	input wire TST_PG,
	
	output wire BIN1,
	output wire BIN2,
	output wire BIN3,
	output wire BIN4,
	output wire BIN5,
	output wire BIN6,
	output wire BIN7,
	output wire BIN8,
	output wire BIN9,
	output wire BIN10,
	
  
  input wire AD_DATA,
  
  output wire AMP_CS,
  output wire AMP_SHDN,
			
	output wire AD_MOSI,
			
	output wire AD_CK,
			
	output wire AD_CONV,
	
	output wire [7:0] LED,
	
	input wire RX_UART,
	output wire TX_UART,
  
  output wire CC2
  
//  input BT_START,
 // input BT_SE,
  //output clk10,
  //input clk10e
//  input TRIM_SEL,
 // output VCONN300K,
//  output wire VCONN_AND
 // output TRIM_START
  );
  
//  IBUF   IBUFT0 (.I(VCONN1), .O(wVCONN1));
 // IBUF   IBUFT1 (.I(VCONN2), .O(wVCONN2));
 /*
 assign EOT=1;
 assign BIN1=1;
 assign BIN2=1;
 assign BIN3=1;
 assign BIN4=1;
 assign BIN5=1;
 assign BIN6=1;
 assign BIN7=1;
 assign BIN8=1;
 assign BIN9=1;
 assign BIN10=1;
 */
  
  wire [9:0] VGA_HC, VGA_VC;//, XPOS, YPOS;
 // assign wVCONN_AND = wVCONN1 & wVCONN2;
assign VCONN_AND = 0;//VCONN1 &  VCONN2;
assign AMP_SHDN=0;


//assign SHDN5=0;
assign EN1_1=1;
assign EN1_1_2=1;
 // OBUF  OBUFT0 (.I(wVCONN_AND), .O(VCONN_AND));

 /*
 wire [9:0] WR_DATA0, WR_DATA1, WR_DATA2, WR_DATA3,
				WR_DATA4, WR_DATA5, WR_DATA6, WR_DATA7,
				WR_DATA8, WR_DATA9, WR_DATAA, WR_DATAB,
				WR_DATAC, WR_DATAD, WR_DATAE, WR_DATAF;
				
 wire [9:0] MM_DATA0, MM_DATA1, MM_DATA2, MM_DATA3,
				MM_DATA4, MM_DATA5, MM_DATA6, MM_DATA7,
				MM_DATA8, MM_DATA9, MM_DATAA, MM_DATAB,
				MM_DATAC, MM_DATAD, MM_DATAE, MM_DATAF;
				
 wire [10:0] MM_ADDR;	
*/
 wire [11:0] TXT_ADDR;
 wire [6:0] WR_TXT_DT, MM_TXT_DT;
 wire [6:0] WR_TXT_DT_RX, WR_ADDR_RX;
 
 wire [6:0] ASCII;
 
 wire [6:0] XPOS;
 wire [4:0] YPOS;
 
 wire [7:0] KCODE;
 
 
 wire CC_H;
 wire DOCTRL_H;
 
 wire [7:0] R_DATA_S, W_DATA_S;
 
 wire [6:0] MM_ADDR, MM_W_DT, MM_R_DT;
 
 wire [239:0] T_DATA, R_DATA;
 
 wire wSOT=DSW3?PROG:SOT;
 

 
 
  
	
 
OBUFT  I1 (.I(HOUT), .T(!DOCTRL_H), .O(CC_HP));
IBUF   I2 (.I(CC_HP), .O(CC_H));
PULLUP I3 (.O(CC_HP));
 assign CC = CC_HP;
 
 OBUFT I4 (.I(HOUT), .T(!DOCTRL_H), .O(CC2));
 PULLUP I5 (.O(CC2));
 
 wire [7:0] SPI_TDATA, SPI_WDATA;
 wire [23:0] SPI_RADDR, SPI_WADDR;
 wire [7:0] DT_UART_TX, DT_UART_RX;
 wire [175:0] PG_DATA;
 wire [2:0] PRB_ST;
 wire [23:0] PRB_FL_ADDR;
 
 wire [6:0] PRB_TXT_DT;
 wire [11:0] PRB_TXT_ADDR;
 
 wire [10:0] MUXADDR;
 wire [7:0] ROM_DT, MUX_DT;
  reg [3:0] r1_dsw, r2_dsw;
  
  wire H_EM=PRB_ST==3;//&{r1_dsw,r2_dsw};
  
  reg [24:0] cntwait;
  wire [13:0] AD1_DT;
  wire [17:0] cnt_EOTclr;
  
 // assign LED=AD1_DT[13:6];
 wire clk10;
 reg [8:0] sample;
 
  reg [20:0] sotcnt;
  
always @  (posedge clk10 or posedge RST)
	if (RST)
	  sotcnt <= #1 0;
	else if (wSOT)
     sotcnt <= #1 1;
   else
     sotcnt <= #1 sotcnt+(|sotcnt);	
  
 always @  (posedge clk10 or posedge RST)
	if (RST)
		sample <= #1 0;
	else 
		sample <= #1 sample+1;
 
 adc IADC(
			
					.CLK(clk10),
					.RST(RST),
			
			.AD_DATA(AD_DATA),
			
			.TRIG(&sample),
			
			.AMP_CS(AMP_CS),
			
			.AD_MOSI(AD_MOSI),
			
			.AD_CK(AD_CK),
			
			.AD_CONV(AD_CONV),
			
			.AD1_DT(AD1_DT),
			
			.AD2_DT()
		); 
 
 burn_st IBURN_ST(

					.CLK(clk10),
					.RST(RST),
					
					.TRIG(PROG_TRIG),

					.SEC_ER(SEC_ER),
					.PROG(PROG_STA)
	);
	
wire [23:0] ID_DT;	
burnmax IBURNMUX(
					.CLK10(clk10),.CLK25(clk25),
					.RST(RST), .ID_DT(ID_DT),
					
					.ADDR(MUXADDR),.DIN(ROM_DT),
					
					//.VGAIN(MM_W_DT),
					.VGAIN(PRB_TXT_DT),
					
					//.LD_VGA(WR_MM_EN),
					.LD_VGA(PRB_WEN&(PRB_TXT_ADDR[11:7]==5'd9)),
					
					//.CHNG_ROM(r1_dsw!=0&&!H_EM),//.CHNG_ROM(CHNG_ROM),
					.CHNG_ROM(1'b1),
					
					//.VGA_ADDR(MM_ADDR),
					.VGA_ADDR(PRB_TXT_ADDR[6:0]),
					
					.DATA(T_DATA),
					
					.DOUT(MUX_DT)
					
					
					);	
 reg [7:0] tst_dt;
wire [2:0] led_tst;

	
 dcore_spartan IDCORE_spartan ( .led_tst(led_tst),.TST_SW(SW),
 .LVL_DN(TST_DN), .LPBK_DN(LPBK_DN), .CHKSUM_DN(CHKSUM_DN),
  .CLK(clk10), .CLKD(clk10), .PDB(1'b1), .PORB(!(EOT|RST)), .CCIN(CC_H), .CCOUT(HOUT), .DOCTRL(DOCTRL_H), 
  .ANA_CONFIG(), .Vdd3(1'b1), .ANA_CTRLMUX(), .SC(SCOUT), .SD(SDOUT), .SDO(SDO_H), 
  .DMUXOUT(/*DMUXOUT[3:0]*/), .VCONX2(1'b0), .UART_RXD(1'b1), .UART_TXD(UART_TX), .BDO(1'b1),
  .BT_START(PROG_STA), .BT_SE(SEC_ER&!H_EM), .ERR_W(ERR_W), .ERR_SE(ERR_SE), .FINISH2K(FINISH2K), 
  .SE_FIN(SE_FIN),  
  .MUXADDR(MUXADDR), .ROM_DT(ROM_DT),

//	.MUX_DT(tst_dt),
  .MUX_DT(MUX_DT), 
  
  
  .VCONN300K(VCONN300K), .TRIM_SEL(1'b0),
  /*.TRIM_START(TRIM_START) ,*/.VCONN_AND(VCONN_AND)
  //, .T_DATA(T_DATA), 
  , .T_DATA(240'hff008001104f),
  .R_DATA(R_DATA), .H_EM(H_EM), 
  
  .TX_TRIG(H_EM&(&cntwait[23:0]&!cntwait[24])), 
  .RX_TRIG(RX_EN)
  ); 
  
   
 always @ (posedge clk10 or posedge RST)
   if (RST)
		tst_dt <= #1 0;
	else if (wSOT|(|sotcnt))
			tst_dt <= #1 8'hc5;
	else if (CHKSUM_DN)
			tst_dt <= #1 0;
 
 
 vga_cnt IVGA_CNT(.CLK(clk25), .RST(RST), .VGA_HC(VGA_HC), .VGA_VC(VGA_VC));
 vga_sync IVGA_SYNC(.CLK(clk25), .RST(RST), .VGA_HC(VGA_HC), .VGA_VC(VGA_VC),
							.HSYNC(VGA_HSYNC), .VSYNC(VGA_VSYNC));

 vga_txto IVGA_TXTO(.CLK(clk25), .RST(RST), .VGA_HC(VGA_HC), .VGA_VC(VGA_VC), .MM_TXT(MM_TXT_DT),
					.DOUT(VGA_DT));
					
 char2mm ICHAR2MM	(.CLK(clk25), .RST(RST), .VGA_HC(VGA_HC), .VGA_VC(VGA_VC), 
						.WEN(WEN), .WR_ADDR(TXT_ADDR), .WR_TXT_DT(WR_TXT_DT), //.KCNT(XPOS),
						.XPOS(XPOS), .YPOS(5'd0), .ASCII(ASCII), .EN(ASCII_EN));

char2mm_2 ICHAR2MM_2	(.CLK(clk25), .RST(RST), .EN(H_EM&(&cntwait)/*RX_EN&H_EM*/),
							.DATA(R_DATA), .ERASE(!H_EM|(cntwait==100000&&H_EM)), 
							.SOT(wSOT|(|sotcnt)),//20160818 read back judge
							.read_flg(read_flg), //20160818 read back judge
							.WEN(WEN_RX), .WR_ADDR(WR_ADDR_RX),
							.WR_TXT_DT(WR_TXT_DT_RX)
							);
							

 keycode IKEYCODE(.CLK(clk25), .RST(RST), .PS2_CK1(PS2_CK1), .PS2_DT1(PS2_DT1),
							.KCODE(KCODE), .VALID(VALID));
 
 kc_st IKC_ST(.CLK(clk25), .RST(RST), .KCODE(KCODE), .VALID(VALID), .K_ESC(K_ESC), .K_ENTER(K_ENTER),
					.ASCII(ASCII[6:0]), .ASCII_EN(ASCII_EN), .XLOC(XPOS));
					
 
 
always @ (posedge clk10 or posedge RST)
   if (RST)
	  cntwait <= #1 0;
	else if   (PRB_ST!=3 || wSOT)//((r1_dsw!=r2_dsw)|SEC_ER) //20160818 read continuously
	  cntwait <= #1 1;
	else
	  cntwait <= #1 cntwait+|cntwait;
 
 always @ (posedge clk25 or posedge RST)
   if (RST)
    r1_dsw <= #1 0;
	else
	 r1_dsw <= #1 {DSW3, DSW2, DSW1, DSW0};
	 
always @ (posedge clk25 or posedge RST)
   if (RST)
    r2_dsw <= #1 0;
	else
	 r2_dsw <= #1 r1_dsw; 
	 
 
 spi_mm ISPI_MM(.CLK(clk25), .RST(RST), 
					.R_DATA_S(R_DATA_S),.W_DATA_S(W_DATA_S),
					.W_DN_S(W_DN_S),.R_DN_S(R_DN_S),
					
					.MM_ADDR(MM_ADDR), .MM_W_DT(MM_W_DT), .MM_R_DT(MM_TXT_DT),
					 
					.WR_MM_EN(WR_MM_EN), .RD_MM_EN(RD_MM_EN),
					
					.WR_S(WR_S), .RD_S(RD_S),
					
					.WR_FLASH(/*K_ENTER*/1'b0), .RD_FLASH(/*K_ESC*/(r1_dsw!=r2_dsw)|SEC_ER)

		);
 

// wire PRB_WEN = 1'b0;
 
 ram_txt IRAM_TXT(
  .clka(clk25),
  .rsta(RST),
  .wea((WEN&!RD_MM_EN)|WR_MM_EN|WEN_RX|PRB_WEN),
  .addra((WR_MM_EN|RD_MM_EN)?{5'd12,MM_ADDR}:
	(WEN?{5'd5,TXT_ADDR[6:0]}:(WEN_RX?{5'd15,WR_ADDR_RX}:
	(PRB_WEN?PRB_TXT_ADDR:{VGA_VC[8:4],VGA_HC[9:3]})))),
  .dina(WR_MM_EN?MM_W_DT:(WEN_RX?WR_TXT_DT_RX:(PRB_WEN?PRB_TXT_DT:WR_TXT_DT))),
  .douta(MM_TXT_DT)
 );	

 
 probe_st IPROB_ST(.CLK(clk25), .RST(RST), 
							.ASCII(ASCII), .ASCII_EN(ASCII_EN),
							.CLR_XPOS(CLR_XPOS),
							.PRB_ST(PRB_ST), .K_ENTER(K_ENTER)
						);
						
 probe_txt IPROBE_TXT( .TST_DN(TST_DN),
			.EOT(EOT), .BIN1(BIN1), .BIN2(BIN2), .BIN3(BIN3),.BIN4(BIN4), .SOT(wSOT|(|sotcnt)),
			.CLK(clk25), .RST(RST), 
							.ASCII(ASCII), .ASCII_EN(ASCII_EN),
							.CLR_XPOS(CLR_XPOS),
							.PRB_ST(PRB_ST), .K_ENTER(K_ENTER),
							
			.XLOC(XPOS),
			
			.FL_PGRD(PRB_FL_PGRD),
			.FL_BTRD(PRB_FL_BTRD),
			.FL_ADDR(PRB_FL_ADDR),
			.FL_DT(SPI_TDATA),
			
			.WR_TXT_DT(PRB_TXT_DT),
					
			.WR_ADDR(PRB_TXT_ADDR), .ID_DT(ID_DT),
			.WEN(PRB_WEN)

			);

 intf_st INTF_ST( .CC_IN(CC_H),
					.CLK(clk10),
					.RST(RST),
					
					.TST_STA(wSOT|(|sotcnt)),
					.read_flg(read_flg),//20160818 read back judge
					.wSOT(wSOT),//20160823 clr EOT when SOT come
				//input wire CHIP_1ST,
				
				.TRIG(PROG_TRIG),
				
				.PRB_ST(PRB_ST),
				
				.TST_DN(TST_DN),
				
				.LPBK_DN(LPBK_DN), .CHKSUM_DN(CHKSUM_DN),.TST_SW(SW),
				.FINISH2K(FINISH2K), .SE_FIN(SE_FIN), .led_tst(led_tst),
				.sotcnt(sotcnt),
				
				.V1ON(V1ON),
				.V2ON(V2ON),

				//.TESTER_STOP(TESTER_STOP),
				
				//.TESTER_BSY(TESTER_BSY),
				//.TESTER_CMPLT(TESTER_CMPLT)
				.AD_DT(AD1_DT),
				
				.EOT(EOT), 
				
				.BIN1(BIN1),
				.BIN10(BIN10),
				.BIN2(BIN2),
				.BIN3(BIN3),
				.BIN4(BIN4),
				.BIN5(BIN5),
				.BIN6(BIN6),
				.BIN7(BIN7),
				.BIN8(BIN8),
				.BIN9(BIN9),
				
				
				.TST(LED)



			);
			
 spi_intfc3 ISPI_INTFC3(
				.CLK(clk25), .RST(RST), 
					.MISO(SPI_MISO),
			// 1-bit SPI output data
		.MOSI(SPI_MOSI),
			// 1-bit SPI input data
		.CSB(SPI_CSB),
			// 1-bit SPI chip enable
		.READ(READ|PRB_FL_PGRD), .RD_BYTE(RD_BYTE|PRB_FL_BTRD),
		.BUF_WRITE(BUF_WRITE), .PG_PROG(PG_PROG),
		//.ADDR((PRB_FL_PGRD|PRB_FL_BTRD)?PRB_FL_ADDR:((READ|RD_BYTE)?SPI_RADDR:SPI_WADDR)),
		.ADDR(PG_PROG?SPI_WADDR:((PRB_FL_PGRD|PRB_FL_BTRD)?PRB_FL_ADDR:SPI_RADDR)),
		.PG_DATA(PG_DATA),
		.R_DATA(SPI_TDATA), .W_DATA(SPI_WDATA)
			
			);
			
file_tx IFILE_TX(
					.CLK(clk25), .RST(RST), 
					.RXDATA(DT_UART_RX), .SPI_TDATA(SPI_TDATA),
					.R_DONE(R_DONE), .T_DONE(T_DONE),
					.FL_ADDR(SPI_RADDR),
					.TX_TRIG(UART_T_TRIG),
					.SPI_READ(RD_BYTE),
					.PG_READ(READ),
					.TX_DATA(DT_UART_TX),
					.ST_TST(/*LED[3:0]*/)
				);
				
			//	assign LED[3:0]=PRB_ST;
				
file_rx IFILE_RX(
						.CLK(clk25), .RST(RST), 
						.RXDATA(DT_UART_RX), 
						.R_DONE(R_DONE), 
						.FL_ADDR(SPI_WADDR),
						.FL_EN(BUF_WRITE),
						.FL_FLUSH(PG_PROG),
						.FL_DT(SPI_WDATA),
						.PGDATA(PG_DATA),
						.ST_TST(/*LED[7:4]*/)

						);
						
 fileuart IFILEUART(
			.CLK(clk25), .RST(RST),
			.RXD(RX_UART), .TXD(TX_UART),
			.TX_TRIG(UART_T_TRIG),
			.T_DONE(T_DONE), .R_DONE(R_DONE),
			.TST1(U_TST1), .TST2(U_TST2),
			.DT_TX(DT_UART_TX), .DT_RX(DT_UART_RX)
			);
//assign TX_UART=INV_TX_UART;			
 /*
 spi_intfc ISPI_INTFC(.CLK(clk25), .RST(RST), 
					.MISO(SPI_MISO),
			// 1-bit SPI output data
		.MOSI(SPI_MOSI),
			// 1-bit SPI input data
		.CSB(SPI_CSB),
			// 1-bit SPI chip enable
					
					.READ(RD_S), .WRITE(WR_S),
					.VERIFY(1'b0),
					
					.ADDR(24'h0b1000+{8'h00,r1_dsw,12'h0}),
					
					.R_DATA(R_DATA_S), .W_DATA(W_DATA_S),
					
					.W_DN(W_DN_S), .R_DN(R_DN_S),
					.V_DN()
					);		
					*/
 
 SPI_ACCESS #(
.SIM_DEVICE("3S700AN")
) 
	SPI_ACCESS_inst (
		.MISO(SPI_MISO),
			// 1-bit SPI output data
		.MOSI(SPI_MOSI),
			// 1-bit SPI input data
		.CSB(SPI_CSB),
			// 1-bit SPI chip enable
		.CLK(clk25)
			// 1-bit SPI clock input
);
  
 DCM_SP #(
    .CLKIN_DIVIDE_BY_2("TRUE"),
	 .CLKDV_DIVIDE(2.5),
    .CLKIN_PERIOD(20.000))
  DCM_SP_INST (
    .CLKIN(CLK_50M),
    .CLKFB(clk25),
    .RST(1'b0),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSCLK(1'b0),
    .DSSEN(1'b0),
    .CLK0(clknub),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    .CLKDV(clk10a),
    .CLK2X(),
    .CLK2X180(),
    .CLKFX(),
    .CLKFX180(),
    .STATUS(),
    .LOCKED(locked),
    .PSDONE());

  BUFG BG (.I(clknub), .O(clk25)); 
  BUFG BG2 (.I(clk10a), .O(clk10)); 
  //BUFG BG2 (.I(clk10e), .O(clk10));
  
  always@(posedge clk25 or posedge RST)
   if (RST)
	  TSTO[0] <= #1 0;
	else
	  TSTO[0] <= #1 SPI_CSB;//U_TST1;
	 // TSTO[0] <= #1 CC_HP;
	  
always@(posedge clk25 or posedge RST)
   if (RST)
	  TSTO[1] <= #1 0;
	else
	  TSTO[1] <= #1 SPI_MOSI;//U_TST2;
	  
always@(posedge clk25 or posedge RST)
   if (RST)
	  TSTO[2] <= #1 0;
	else
	  TSTO[2] <= #1 PG_PROG;//RX_UART;
always@(posedge clk25 or posedge RST)
   if (RST)
	  TSTO[3] <= #1 0;
	else
	  TSTO[3] <= #1 SPI_MISO;//SPI_MISO;
/*
reg b_flg, h_flg;

always@(posedge clk25 or posedge RST)
   if (RST)	  
	  b_flg <= #1 0;
	else if (SEC_ER)
	  b_flg <= #1 1;
	else if (FINISH2K|H_EM)
	  b_flg <= #1 0;
	else
	  b_flg <= #1 b_flg;
	  
always@(posedge clk25 or posedge RST)
   if (RST)	  
	  h_flg <= #1 0;
	else if (SEC_ER)
	  h_flg <= #1 1;
	else if (RX_EN)
	  h_flg <= #1 0;
	else
	  h_flg <= #1 b_flg;
	  */
		  /*
assign VGA_R=VGA_VC>>192&& r1_dsw!=0?{VGA_VC[9:1]==10448&&VGA_HC[9:3]==XPOS+1,3'd0}:
			((b_flg==0&&VGA_VC>208)||(r1_dsw==0&&(VGA_VC>192&& VGA_VC<=208)||VGA_VC>224)?0:({4{VGA_DT}});*/
assign VGA_R=VGA_VC[9:1]==48?	{VGA_HC[9:3]==XPOS+1,3'd0}:((PRB_ST>0 || VGA_VC<97)?{4{VGA_DT}}:0);		
/*
assign VGA_G=H_EM? ((VGA_VC>208&& VGA_VC<=224)||(h_flg==0&&VGA_VC>224&&VGA_VC<=240)?0:{4{VGA_DT}})
				:(b_flg==0&&VGA_VC>208)||(r1_dsw==0&&VGA_VC>192||VGA_VC>224)?0:{4{VGA_DT}};
				*/
				/*
assign VGA_B=(b_flg==0&&VGA_VC>208)||(r1_dsw==0&&VGA_VC>192||VGA_VC>224)?0:{4{VGA_DT}};
*/
assign VGA_G=(PRB_ST>0 || VGA_VC<97)?{4{VGA_DT}}:0;
assign VGA_B=(PRB_ST>0 || VGA_VC<97)?{4{VGA_DT}}:0;


//assign V1ON=VON;
//assign V2ON=VON;
assign V1ON2=V1ON;
assign V2ON2=V2ON;
assign OE=DOCTRL_H;
assign OE2=DOCTRL_H;

  
 endmodule