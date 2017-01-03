//
//probe_txt.v
//
module probe_txt(
			input wire CLK,
			input wire RST,
			
			input wire TST_DN,
			
			///////////////
			input wire EOT,
			input wire SOT,
			input wire BIN1,
			input wire BIN2,
			input wire BIN3,
			input wire BIN4,
			
			
			///////////////
			
			input wire CLR_XPOS,
			
			input wire [2:0] PRB_ST,
			
			input wire K_ENTER,
			
			input wire ASCII_EN,
			input wire [6:0] ASCII,
			input wire [6:0] XLOC,
			
			output reg FL_PGRD,
			output reg FL_BTRD,
			output reg [23:0] FL_ADDR,
			input wire [7:0] FL_DT,
			
			output reg [6:0] WR_TXT_DT,
			
			output wire [23:0] ID_DT,		
			output reg [11:0] WR_ADDR,
			output reg WEN

			);

reg flg_clr;
reg [2:0] bit0;
reg [3:0] bit1;
reg [5:0] bit2;

reg [9:0] fl_cnt;

reg [15:0] st_cnt, b1_cnt, b2_cnt, b3_cnt, b4_cnt;

reg [1:0] dbin1, dbin2, dbin3, dbin4;

reg flg_tst, flg_b1, flg_b2, flg_b3, flg_b4;

reg [1:0] rtst_dn;

assign ID_DT={2'd0, bit2, 4'd0, bit1, 5'ha, bit0};

wire wbin1=EOT&BIN1;
wire wbin2=EOT&BIN2;
wire wbin3=EOT&BIN3;
wire wbin4=EOT&BIN4;


wire [7:0] waddr1={bit2,2'b0}+bit2;
wire [8:0] waddr2={waddr1,1'b0}+bit1;
wire [11:0] waddr3={waddr2, 3'd0}+bit0;

wire [11:0] wpage=~waddr3;	

wire [15:0] wst_cnt=flg_tst? st_cnt:(flg_b1? b1_cnt:(flg_b2? b2_cnt:(flg_b3?b3_cnt:b4_cnt)));


always @ (posedge CLK or posedge RST)
  if (RST)
    rtst_dn <= #1 0;
  else
    rtst_dn <= #1 {rtst_dn, SOT};//TST_DN};  
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    dbin1 <= #1 0;
  else
    dbin1 <= #1 {dbin1, wbin1}; 

always @ (posedge CLK or posedge RST)
  if (RST)
    dbin2 <= #1 0;
  else
    dbin2 <= #1 {dbin2, wbin2}; 

always @ (posedge CLK or posedge RST)
  if (RST)
    dbin3 <= #1 0;
  else
    dbin3 <= #1 {dbin3, wbin3}; 

always @ (posedge CLK or posedge RST)
  if (RST)
    dbin4 <= #1 0;
  else
    dbin4 <= #1 {dbin4, wbin4}; 
 	 

always @ (posedge CLK or posedge RST)
  if (RST)
    b1_cnt <= #1 0;
  else if (PRB_ST!=4)
    b1_cnt <= #1 0; 
  else
    b1_cnt <= #1 b1_cnt+(dbin1[0]&!dbin1[1]);  
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    b2_cnt <= #1 0;
  else if (PRB_ST!=4)
    b2_cnt <= #1 0; 
  else
    b2_cnt <= #1 b2_cnt+(dbin2[0]&!dbin2[1]);  
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    b3_cnt <= #1 0;
  else if (PRB_ST!=4)
    b3_cnt <= #1 0; 
  else
    b3_cnt <= #1 b3_cnt+(dbin3[0]&!dbin3[1]);  
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    b4_cnt <= #1 0;
  else if (PRB_ST!=4)
    b4_cnt <= #1 0; 
  else
    b4_cnt <= #1 b4_cnt+(dbin4[0]&!dbin4[1]);  
	 
	 
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    st_cnt <= #1 0;
  else if (PRB_ST!=4)
    st_cnt <= #1 0; 
  else
    st_cnt <= #1 st_cnt+(rtst_dn[0]&!rtst_dn[1]);  	 

always @ (posedge CLK or posedge RST)
  if (RST)
    bit2 <= #1 0;
  else if (CLR_XPOS)
    bit2 <= #1 0;  
  else if (!ASCII_EN || XLOC!=1 || PRB_ST!=0)
    bit2 <= #1 bit2;
  else if (ASCII>=8'h30 && ASCII<=8'h39) 
    bit2 <= #1 ASCII+8'h10;
  else if (ASCII>=8'h41 && ASCII<=8'h48)
    bit2 <= #1 ASCII+8'hc9;
  else if (ASCII>=8'h4a && ASCII<=8'h4e)
    bit2 <= #1 ASCII+8'hc8;
  else if (ASCII>=8'h50 && ASCII<=8'h55) 
    bit2 <= #1 ASCII+8'hc7;
  else if (ASCII>=8'h57 && ASCII<=8'h5a) 
    bit2 <= #1 ASCII+8'hc6;
  else
    bit2 <= #1 bit2; 
	 
	 always @ (posedge CLK or posedge RST)
  if (RST)
    bit1 <= #1 0;
  else if (CLR_XPOS)
    bit1 <= #1 0;  	 
  else if (!ASCII_EN || XLOC!=2 || PRB_ST!=0)
    bit1 <= #1 bit1;	 
  else if (ASCII>=8'h30 && ASCII<=8'h39) 
    bit1 <= #1 ASCII+8'h10;	
  else
    bit1 <= #1 bit1;

always @ (posedge CLK or posedge RST)
  if (RST)
    bit0 <= #1 0;
  else if (CLR_XPOS)
    bit0 <= #1 0;  	 
  else if (!ASCII_EN || XLOC!=3 || PRB_ST!=0)
    bit0 <= #1 bit0;	 
  else if (ASCII>=8'h30 && ASCII<=8'h37) 
    bit0 <= #1 ASCII+8'h10;	
  else
    bit0 <= #1 bit0;


always @ (posedge CLK or posedge RST)
  if (RST)	
    FL_ADDR <= #1 0;
  else 	 
    FL_ADDR <= #1 {3'd0, wpage, 9'd0};

always @ (posedge CLK or posedge RST)
  if (RST)	
    FL_PGRD <= #1 0;
  else
	 FL_PGRD <= #1 (K_ENTER)&&(PRB_ST==0);
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    fl_cnt <= #1 0;
  else if	((K_ENTER)&&(PRB_ST==0))
    fl_cnt <= #1 1; 
  else if (fl_cnt>0 && fl_cnt<600)
    fl_cnt <= #1 fl_cnt+1;  
  else
    fl_cnt <= #1 0;  
	 
always @ (posedge CLK or posedge RST)
  if (RST)	
    FL_BTRD <= #1 0;
  else
    FL_BTRD <= #1 fl_cnt[9]&(!fl_cnt[0]); 

always @ (posedge CLK or posedge RST)
  if (RST)			
    flg_tst <= #1 1;	 
  else if ((rtst_dn[0]&!rtst_dn[1]))
    flg_tst <= #1 1;	
  else if (WR_ADDR[3])
    flg_tst <= #1 0;  
  else
    flg_tst <= #1 flg_tst;
	 
always @ (posedge CLK or posedge RST)
  if (RST)			
    flg_b1 <= #1 1;	 
  else if ((dbin1[0]&!dbin1[1]))
    flg_b1 <= #1 1;	
  else if (WR_ADDR[3])
    flg_b1 <= #1 0;  
  else
    flg_b1 <= #1 flg_b1;
	 
always @ (posedge CLK or posedge RST)
  if (RST)			
    flg_b2 <= #1 1;	 
  else if ((dbin2[0]&!dbin2[1]))
    flg_b2 <= #1 1;	
  else if (WR_ADDR[3])
    flg_b2 <= #1 0;  
  else
    flg_b2 <= #1 flg_b2;
	 
always @ (posedge CLK or posedge RST)
  if (RST)			
    flg_b3 <= #1 1;	 
  else if ((dbin3[0]&!dbin3[1]))
    flg_b3 <= #1 1;	
  else if (WR_ADDR[3])
    flg_b3 <= #1 0;  
  else
    flg_b3 <= #1 flg_b3;
	 
always @ (posedge CLK or posedge RST)
  if (RST)			
    flg_b4 <= #1 1;	 
  else if ((dbin4[0]&!dbin4[1]))
    flg_b4 <= #1 1;	
  else if (WR_ADDR[3])
    flg_b4 <= #1 0;  
  else
    flg_b4 <= #1 flg_b4;
	 
	 
	 
      

always @ (posedge CLK or posedge RST)
  if (RST)			
    flg_clr <= #1 0;
  else if (CLR_XPOS)
    flg_clr <= #1 1;
  else if (WEN && (WR_ADDR=={5'd17, 7'd110}))
    flg_clr <= #1 0;
  else
	 flg_clr <= #1 flg_clr;  
	 
always @ (posedge CLK or posedge RST)
  if (RST)	 
    WEN <= #1 0;
  else if (flg_clr)
    WEN <= #1 1; 
	else if ((fl_cnt>=10'd514)&&(fl_cnt<10'd558))
    WEN <= #1 1;  
	 
  else 
    WEN <= #1 flg_tst|flg_b1|flg_b2|flg_b3|flg_b4;  

always @ (posedge CLK or posedge RST)
  if (RST)	 
    WR_ADDR <= #1 {5'd10,7'd0};
  else if (CLR_XPOS)
    WR_ADDR <= #1 {5'd5,7'd0};
  else if (flg_clr) begin
	if (WR_ADDR[6:0]==7'd110)
	  case(WR_ADDR[11:7])
	    5: WR_ADDR <= {5'd9,7'd0};
		 9: WR_ADDR <= {5'd15,7'd0};
		 default: WR_ADDR <= {5'd17,7'd0};
		 endcase
	else
		WR_ADDR <= #1 WR_ADDR+1;
  end
  else if (FL_PGRD)
    WR_ADDR <= #1 {5'd9,7'd0};
  else if ((fl_cnt>=514)&&(fl_cnt<558) )
    WR_ADDR <= #1 WR_ADDR+1;
  else if ((rtst_dn[0]&!rtst_dn[1]))
		WR_ADDR <= {5'd17,7'd16};
	else if ((dbin1[0]&!dbin1[1]))	
		WR_ADDR <= {5'd17,7'd24};	
	else if ((dbin2[0]&!dbin2[1]))	
		WR_ADDR <= {5'd17,7'd32};	
	else if ((dbin3[0]&!dbin3[1]))	
		WR_ADDR <= {5'd17,7'd40};	
	else if ((dbin4[0]&!dbin4[1]))	
		WR_ADDR <= {5'd17,7'd48};	
		
   else if (flg_tst|flg_b1|flg_b2|flg_b3|flg_b4)
		WR_ADDR <= #1 WR_ADDR+1;
  else		
     WR_ADDR <= #1 WR_ADDR;
	  
	  
 always @ (posedge CLK or posedge RST)
  if (RST)
     WR_TXT_DT <= #1 0;
  else if (flg_clr)	
     WR_TXT_DT <= #1 0;
  else if ((fl_cnt>=514)&&(fl_cnt<558) )  
     WR_TXT_DT <= #1 fl_cnt[0]? ((FL_DT[3:0]>9)?FL_DT[3:0]+7'd55:FL_DT[3:0]+7'h30)
								:((FL_DT[7:4]>9)?FL_DT[7:4]+7'd55:FL_DT[7:4]+7'h30);
								/*
  else if (flg_tst)
    WR_TXT_DT <= #1(WR_ADDR[2:0]==3'd2)? (st_cnt[15:12]>9?st_cnt[15:12]+7'd55:st_cnt[15:12]+7'h30):
							(WR_ADDR[2:0]==3'd3)? (st_cnt[11:8]>9?st_cnt[11:8]+7'd55:st_cnt[11:8]+7'h30):
							(WR_ADDR[2:0]==3'd4)? (st_cnt[7:4]>9?st_cnt[7:4]+7'd55:st_cnt[7:4]+7'h30):
							(WR_ADDR[2:0]==3'd5)? (st_cnt[3:0]>9?st_cnt[3:0]+7'd55:st_cnt[3:0]+7'h30):0;
							*/
	else if (flg_tst|flg_b1|flg_b2|flg_b3|flg_b4)
    WR_TXT_DT <= #1(WR_ADDR[2:0]==3'd2)? (wst_cnt[15:12]>9?wst_cnt[15:12]+7'd55:wst_cnt[15:12]+7'h30):
							(WR_ADDR[2:0]==3'd3)? (wst_cnt[11:8]>9?wst_cnt[11:8]+7'd55:wst_cnt[11:8]+7'h30):
							(WR_ADDR[2:0]==3'd4)? (wst_cnt[7:4]>9?wst_cnt[7:4]+7'd55:wst_cnt[7:4]+7'h30):
							(WR_ADDR[2:0]==3'd5)? (wst_cnt[3:0]>9?wst_cnt[3:0]+7'd55:wst_cnt[3:0]+7'h30):0;						
  else
    WR_TXT_DT <= #1 0; 

	 
  
			
endmodule			