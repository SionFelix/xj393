//
//char2mm_2.v
//
module char2mm_2(
					input wire CLK,
					input wire RST,
					
					input wire EN,
					input wire [239:0] DATA,
					
					input wire ERASE,
					
					input wire SOT,	    //20160818 read back judge
					
					output reg read_flg,  //20160818 read back judge
					
					output reg [6:0] WR_TXT_DT,
					
					output reg [6:0] WR_ADDR,
					output reg WEN
					);

reg [1:0] r_en, r_erase;

reg flg_en, flg_erase;

reg [239:0] tmp;

parameter [175:0] WDATA = 176'h000828527231FFFF00000BAE18002C5BFF008041514F;//20160818 read back judge
//20160818 read back judge
//read_flg != WDATA : 1
//read_flg == WDATA : 0
always @ (posedge CLK or posedge RST)
  if (RST)
    read_flg <= #1 1;
  else if(r_en[0]&!r_en[1])
    read_flg <= #1 DATA[175:0] != WDATA;//char num:44
  else
    read_flg <= #1 SOT ? 1 : read_flg;
//--

always @ (posedge CLK or posedge RST)
  if (RST)
    tmp <= #1 0;
  else if (r_en[0]&!r_en[1])
    tmp <= #1 DATA;
  else if (WR_ADDR[0])
    tmp <= #1 {8'd0, tmp[239:8]};
  else
    tmp <= #1 tmp;

always @ (posedge CLK or posedge RST)
  if (RST)
    r_en <= #1 0;
  else
    r_en <= #1 {r_en, EN};
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    flg_en <= #1 0;
  else
    flg_en <= #1 	r_en[0]&!r_en[1]; 
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    r_erase <= #1 0;
  else
    r_erase <= #1 {r_erase, ERASE};
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    flg_erase <= #1 0;
  else if (r_erase[0]&!r_erase[1])
    flg_erase <= #1 1; 
  else if (&WR_ADDR)
    flg_erase <= #1 0;
  else
    flg_erase <= #1  flg_erase;
	 
	 
					
always @ (posedge CLK or posedge RST)
  if (RST)		
   WR_ADDR <= #1 0;
  else if (flg_en|(r_erase[0]&!r_erase[1]))
   WR_ADDR <= #1 1;
  else 
   WR_ADDR <= #1 WR_ADDR+|WR_ADDR;  

always @ (posedge CLK or posedge RST)
  if (RST)
    WEN <= #1 0;
  else
    WEN <= #1 flg_en||(WR_ADDR>=1&&WR_ADDR<44);
	 //flg_en||WR_ADDR>=1;//WR_ADDR>=2&&WR_ADDR<100;//(|WR_ADDR)| (flg_en|flg_erase);

always @ (posedge CLK or posedge RST)
  if (RST)	 
	 WR_TXT_DT <= #1 0;
  else if (flg_erase)
	 WR_TXT_DT <= #1 0;  
  else if ((|WR_ADDR)| (flg_en))
     WR_TXT_DT <= #1 WR_ADDR[0]?(tmp[3:0]>9?tmp[3:0]+55:tmp[3:0]+48):
									(tmp[7:4]>9?tmp[7:4]+55:tmp[7:4]+48);
  /*
    case(WR_ADDR)
		0: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   1: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		2: WR_TXT_DT <= #1 DATA[15:12]>9?DATA[15:12]+55:DATA[15:12]+48;
	   3: WR_TXT_DT <= #1 DATA[11:8]>9?DATA[11:8]+55:DATA[11:8]+48;
		4: WR_TXT_DT <= #1 DATA[23:20]>9?DATA[23:20]+55:DATA[23:20]+48;
	   5: WR_TXT_DT <= #1 DATA[19:16]>9?DATA[19:16]+55:DATA[19:16]+48;
		6: WR_TXT_DT <= #1 DATA[31:28]>9?DATA[31:28]+55:DATA[31:28]+48;
	   7: WR_TXT_DT <= #1 DATA[27:24]>9?DATA[27:24]+55:DATA[27:24]+48;
		8: WR_TXT_DT <= #1 DATA[39:36]>9?DATA[39:36]+55:DATA[39:36]+48;
	   9: WR_TXT_DT <= #1 DATA[35:32]>9?DATA[35:32]+55:DATA[35:32]+48;
		10: WR_TXT_DT <= #1 DATA[47:44]>9?DATA[47:44]+55:DATA[47:44]+48;
	   11: WR_TXT_DT <= #1 DATA[43:40]>9?DATA[43:40]+55:DATA[43:40]+48;
		12: WR_TXT_DT <= #1 DATA[55:52]>9?DATA[55:52]+55:DATA[55:52]+48;
	   13: WR_TXT_DT <= #1 DATA[51:48]>9?DATA[51:48]+55:DATA[51:48]+48;
		14: WR_TXT_DT <= #1 DATA[63:60]>9?DATA[63:60]+55:DATA[63:60]+48;
	   15: WR_TXT_DT <= #1 DATA[59:56]>9?DATA[59:56]+55:DATA[59:56]+48;
		16: WR_TXT_DT <= #1 DATA[71:68]>9?DATA[71:68]+55:DATA[71:68]+48;
	   17: WR_TXT_DT <= #1 DATA[67:64]>9?DATA[67:64]+55:DATA[67:64]+48;
		18: WR_TXT_DT <= #1 DATA[79:76]>9?DATA[79:76]+55:DATA[79:76]+48;
	   19: WR_TXT_DT <= #1 DATA[75:72]>9?DATA[75:72]+55:DATA[75:72]+48;
		20: WR_TXT_DT <= #1 DATA[87:84]>9?DATA[87:84]+55:DATA[87:84]+48;
	   21: WR_TXT_DT <= #1 DATA[83:80]>9?DATA[83:80]+55:DATA[83:80]+48;
		22: WR_TXT_DT <= #1 DATA[95:92]>9?DATA[95:92]+55:DATA[95:92]+48;
	   23: WR_TXT_DT <= #1 DATA[91:88]>9?DATA[91:88]+55:DATA[91:88]+48;
		24: WR_TXT_DT <= #1 DATA[103:100]>9?DATA[103:100]+55:DATA[103:100]+48;
	   25: WR_TXT_DT <= #1 DATA[99:96]>9?DATA[99:96]+55:DATA[99:96]+48;
		26: WR_TXT_DT <= #1 DATA[111:108]>9?DATA[111:108]+55:DATA[111:108]+48;
	   27: WR_TXT_DT <= #1 DATA[107:104]>9?DATA[107:104]+55:DATA[107:104]+48;
		28: WR_TXT_DT <= #1 DATA[119:116]>9?DATA[119:116]+55:DATA[119:116]+48;
	   29: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		30: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   31: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		32: WR_TXT_DT <= #1 DATA[15:12]>9?DATA[15:12]+55:DATA[15:12]+48;
	   33: WR_TXT_DT <= #1 DATA[11:8]>9?DATA[11:8]+55:DATA[11:8]+48;
		34: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   35: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		36: WR_TXT_DT <= #1 DATA[15:12]>9?DATA[15:12]+55:DATA[15:12]+48;
	   37: WR_TXT_DT <= #1 DATA[11:8]>9?DATA[11:8]+55:DATA[11:8]+48;
		38: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   39: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		40: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   41: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		42: WR_TXT_DT <= #1 DATA[15:12]>9?DATA[15:12]+55:DATA[15:12]+48;
	   43: WR_TXT_DT <= #1 DATA[11:8]>9?DATA[11:8]+55:DATA[11:8]+48;
		44: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   45: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		46: WR_TXT_DT <= #1 DATA[15:12]>9?DATA[15:12]+55:DATA[15:12]+48;
	   47: WR_TXT_DT <= #1 DATA[11:8]>9?DATA[11:8]+55:DATA[11:8]+48;
		48: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   49: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		50: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   51: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		52: WR_TXT_DT <= #1 DATA[15:12]>9?DATA[15:12]+55:DATA[15:12]+48;
	   53: WR_TXT_DT <= #1 DATA[11:8]>9?DATA[11:8]+55:DATA[11:8]+48;
		54: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   55: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		56: WR_TXT_DT <= #1 DATA[15:12]>9?DATA[15:12]+55:DATA[15:12]+48;
	   57: WR_TXT_DT <= #1 DATA[11:8]>9?DATA[11:8]+55:DATA[11:8]+48;
		58: WR_TXT_DT <= #1 DATA[7:4]>9?DATA[7:4]+55:DATA[7:4]+48;
	   59: WR_TXT_DT <= #1 DATA[3:0]>9?DATA[3:0]+55:DATA[3:0]+48;
		default: 
			 WR_TXT_DT <= #1 0;
	 
	 endcase
	 */
  
  else
	 WR_TXT_DT <= #1 0;
	 
endmodule					
					