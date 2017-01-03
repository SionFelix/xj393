//
//intf_st.v
//
module intf_st(
				input wire CLK,
				input wire RST,
				
				input wire TST_STA,
				input wire read_flg,//20160818 read back judge
				input wire wSOT,    //20160823 clr EOT when SOT come
				//input wire CHIP_1ST,
				
				output reg TRIG,
				
				input wire [2:0] PRB_ST,
				
				input wire TST_DN,
				
				//output reg VON,
				input wire LPBK_DN,
				
				input wire CHKSUM_DN,
				
				input wire FINISH2K,
				input wire SE_FIN,
				
				input wire [13:0] AD_DT,
				
				input wire CC_IN,
				
				input [2:0] led_tst,
				
				input wire TST_SW,
				
				input wire [20:0] sotcnt,//20160810,add EOT signal when test failed
			
				output reg EOT,
				output reg V1ON,
				output reg V2ON,
				
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
				
				output wire [7:0] TST

		);
//reg [9:0] cnt;//100us
reg [18:0] cnt;//20161102 51.2ms
//reg [4:0] cnt2;
reg [23:0] cnt2;

reg [14:0] cntx, cnty, cntz; //3.2ms

reg [19:0] cnta;
reg [24:0] cnt_SEFIN;//20160902 3200ms after TST_STA,send EOT when communicate fail
reg [25:0] cnt_rd_flg;//20161010 3600ms read_flg change,cnt_rd_flg==26'h23FFFFF
reg [21:0] cnt_bin_after_EOT;//20161018 409.6ms
reg BIN3_read;//20161010 judge for BIN3 read statement,if read fail BIN3_read==1
reg [5:0] d_ccin;

reg pass, f_lpbk, f_chksum, f_lvl;

////Yiwei Wang, change 11/3/2016
reg f_timeout;

reg [25:0] cnt_6s;//20160810,add EOT signal when test failed, 26bit, wait for 6.7s

assign BIN1=f_timeout ? 1'b0 : pass;//if timeout=1 then bin1=1
//assign BIN1=pass;
assign BIN2=f_lpbk;
assign BIN3=f_chksum&!f_lpbk;
//assign BIN3=(f_chksum&!f_lpbk) | (PRB_ST == 3 && !pass);//20160818 read back judge(BIN3 always high)
//assign BIN3=(f_chksum&!f_lpbk) | BIN3_read;//20161010 read back judge
assign BIN4=f_lvl&(!f_lpbk)&!f_chksum;
//assign BIN4=read_flg;//20101017 signal test

assign BIN5=    //if any of BIN2,BIN3,BIN4 =1,BIN5=0; else bin5=f_timeout
       (f_lpbk | (f_chksum&!f_lpbk) | (f_lvl&(!f_lpbk)&!f_chksum)) ? 1'b0 : f_timeout;
//assign BIN5=f_timeout;//0; 

assign BIN6=0;
assign BIN7=0;
assign BIN8=0;
assign BIN9=0;
assign BIN10=0;

wire [14:0] wtmp=15'h2000+{1'b0,AD_DT[13:0]};
wire [14:0] wtmp2=(AD_DT==14'h2000)? 15'h7fff:(15'h1+~wtmp);

wire high=wtmp2[14:7]>8'h90;//8'hd4;

wire [2:0] sum_cc=d_ccin[5]+d_ccin[4]+d_ccin[3]+d_ccin[2]+d_ccin[1]+d_ccin[0]+CC_IN;
wire wCC_IN=sum_cc>3;

assign TST={led_tst,BIN1, BIN2, BIN3, BIN4};//wtmp2[14:7];
/*
always @ (posedge CLK or posedge RST)
  if (RST)
    VON <= #1 0;
  else if (PRB_ST==3)	
    VON <= #1 1;  
  else if (!TST_STA)
    VON <= #1 1;
  else if (TST_DN)
    VON <= #1 0;
  else
    VON <= #1 VON; 
	 */  
	 
	 
always @ (posedge CLK or posedge RST)
  if (RST)	
    d_ccin <= #1 0;
  else
    d_ccin <= #1 {d_ccin,CC_IN};  
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    cnta <= #1 0;
  else if ((FINISH2K|TST_SW) && (cnta==0))
    cnta <= #1 1;
  else
    cnta <= #1 cnta + |cnta;	 
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    cntx <= #1 0;
  else if (LPBK_DN)
    cntx <= #1 1;
  else
    cntx <= #1 cntx + |cntx;
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    cnty <= #1 0;
  else if (CHKSUM_DN)
    cnty <= #1 1;
  else
    cnty <= #1 cnty + |cnty;
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    cntz <= #1 0;
  else if (TST_DN || cnt_6s == 26'h3FF_FFFF //20160810,add EOT signal when test failed, wait for 6.7s
                  //|| &cnt_SEFIN				  //20160902 3200ms after TST_STA,send EOT when communicate fail
						|| cnt_rd_flg == 26'h23FFFFF)//20161010,after 3600ms,get read pass data  					)      
    cntz <= #1 1;
  else
    cntz <= #1 cntz + |cntz;

//20160902 3200ms after TST_STA,send EOT when communicate fail
reg SE_FIN_r;
always @ (posedge CLK or posedge RST)
  if (RST)
    SE_FIN_r <= #1 0;
  else
    SE_FIN_r <= #1 SE_FIN;

always @ (posedge CLK or posedge RST)
  if (RST)
    cnt_SEFIN <= #1 0;
  else if (PRB_ST == 4 && TST_STA)//20161010 only trig on PRB_ST == 4 
    cnt_SEFIN <= #1 1;
  else if(SE_FIN && !SE_FIN_r)  //high pulse,sucsess
    cnt_SEFIN <= #1 0;
  else
    cnt_SEFIN <= #1 cnt_SEFIN + |cnt_SEFIN; 	 
	 
//--
	 
//20161010 3600ms read_flg change,cnt_rd_flg==26'h23FFFFF 
always @ (posedge CLK or posedge RST)
  if (RST)
    cnt_rd_flg <= #1 0;
  else if (PRB_ST == 3 && TST_STA)
    cnt_rd_flg <= #1 1;
  else if(cnt_rd_flg == 26'h23FFFFF)  //read_flg change
    cnt_rd_flg <= #1 0;
  else
    cnt_rd_flg <= #1 cnt_rd_flg + |cnt_rd_flg; 
//--	 

//20161010  judge for BIN3 read statement,if read fail BIN3_read==1
always @ (posedge CLK or posedge RST)
  if (RST)
    BIN3_read <= #1 0;
  else if(&cnt)
    BIN3_read <= #1 0;
  else if(cnt_rd_flg == 26'h23F_FFFF && PRB_ST == 3 && !pass)
    BIN3_read <= #1 1;
  else
    BIN3_read <= #1 BIN3_read;
//--


//20161018  
always @ (posedge CLK or posedge RST)
  if (RST)
    cnt_bin_after_EOT <= #1 0;
  else if(&cnt)
    cnt_bin_after_EOT <= #1 1;
  else
    cnt_bin_after_EOT <= #1 cnt_bin_after_EOT + |cnt_bin_after_EOT;
//--


always @ (posedge CLK or posedge RST)
  if (RST)
    V1ON <= #1 0;
  else if (PRB_ST==3)	
    V1ON <= #1 1;  
  else if (TST_STA|TST_SW)
    V1ON <= #1 1;
  else if (cntx==32||(cnta[14:0]==32&&(&cnta[19:15])))//(cntx==32)//(&cntx)
    V1ON <= #1 0;
  else if ((&cnta)||(&cnty))//(&cnty)//(CHKSUM_DN)
    V1ON <= #1 1;
  else if (&cnt[5:0])//(&cntz)
    V1ON <= #1 0;
  else if (PRB_ST==2)
     V1ON <= #1 0; 
  else
    V1ON <= #1 V1ON;

always @ (posedge CLK or posedge RST)
  if (RST)
    V2ON <= #1 0;
//  else if (PRB_ST==3)	
//    V1ON <= #1 1;  
//  else if (TST_STA)
//    V1ON <= #1 1;
	else if (TST_STA)
    V2ON <= #1 1;
	else if (cnta==32)
	 V2ON <= #1 0;
  else if (&cntx)
    V2ON <= #1 1;
//  else if (CHKSUM_DN)
//    V1ON <= #1 1;
  else if (cnty==32||(&cnt[5:0]))//(&cnt[5:0])//(&cntz)
    V2ON <= #1 0;
  else
    V2ON <= #1 V2ON;

	 

always @ (posedge CLK or posedge RST)
  if (RST)
    cnt2 <= #1 0;
  else if (TST_STA)	
    cnt2 <= #1 1;
  else
    cnt2 <= #1 cnt2+(|cnt2);  

/*
always @ (posedge CLK or posedge RST)
  if (RST)
    TESTER_BSY <= #1 1;
  else if (TST_STA)
    TESTER_BSY <= #1 0;
  else if (TST_DN)
     TESTER_BSY <= #1 1;
  else
    TESTER_BSY <= #1 TESTER_BSY;
	 */
	
//20160810,add EOT signal when test failed, 26bit, wait for 6.7s	
always @ (posedge CLK or posedge RST)
  if (RST) 
	 cnt_6s <= #1 0;
  else if (EOT)
    cnt_6s <= #1 0;
  else if(sotcnt)	 
    cnt_6s <= #1 1;
  else
    cnt_6s <= #1 cnt_6s +(|cnt_6s);
//--

always @ (posedge CLK or posedge RST)
  if (RST)
    cnt <= #1 0;
  else if (&cntz)//(TST_DN) 
    cnt <= #1 1;
  else
    cnt <= #1 cnt +(|cnt);
	

always @ (posedge CLK or posedge RST)
  if (RST)
	EOT <= #1 0;
  else if (&cntz) 
   EOT <= #1 1;
  //20160822 else if (&cnt[17:0]) //use part of the top cnt to clear EOT, change if needed
  else if (&cnt) //origin
	EOT <= #1 0;
  else
	EOT <= #1 EOT;

always @ (posedge CLK or posedge RST)
  if (RST)
	f_lpbk <= #1 0;
  else if (TST_STA)
	f_lpbk <= #1 0;
  else if (cntx==16)//(&cntx)
   f_lpbk <= #1 wCC_IN;//high;
	
//20161206
  else if(cnt_6s > 26'h3FF_FF00 && PRB_ST != 3)//20160810,add EOT signal when test failed.Incase bin2 enable
          ////&cnt_SEFIN | 
   f_lpbk <= #1 1;
	
  //else if(&cnt) //2016 0822clear after ~0.1ms of EOT go low, duration based on EOT part
  //else if(&cnt_bin_after_EOT)//20161018 time test
   //f_lpbk <= #1 0;
  else
   f_lpbk <= #1 f_lpbk;
	
always @ (posedge CLK or posedge RST)
  if (RST)
	f_chksum <= #1 0;
  else if (TST_STA)
	f_chksum <= #1 0;
  else if (cnty==16)
   f_chksum <= #1 wCC_IN;//high;
  //else if(&cnt_bin_after_EOT)//20161018 time test
   //f_chksum <= #1 0;	
  else
   f_chksum <= #1 f_chksum;
	
	
 always @ (posedge CLK or posedge RST)
  if (RST)  
   f_lvl <= #1 0;
  else if (TST_STA)	
   f_lvl <= #1 0;
  else if (cntz==12'hff8)
   f_lvl <= #1 !wCC_IN;//!high;
  //else if(&cnt_bin_after_EOT)//20161018 time test
   //f_lvl <= #1 0;		
  else
   f_lvl <= #1 f_lvl;  


///Yiwei Wang change 11/3/2016
always @ (posedge CLK or posedge RST)
  if (RST)  
   pass <= #1 	0;
	//change the line below 
  else if (FINISH2K)//(TST_STA)	//(cntz==12'hfff && !(f_lvl | f_chksum | f_lpbk | (PRB_ST == 3 && !read_flg)))//20160914 when it real pass,high
   pass <= #1 1;
  //else if (f_lvl | f_chksum |f_lpbk) //orig
  //else if (f_lvl | f_chksum | f_lpbk | (PRB_ST == 3 && read_flg)) //20160818 read back judge
  //change the line below 
  else if (f_lvl | f_chksum | f_lpbk)
 // else if (f_lvl | f_chksum | f_lpbk | //&cnt_SEFIN //20161018 when &cnt_SEFIN,fail
 //        |(cnt_rd_flg==26'h23FFFFF && PRB_ST == 3 && read_flg)) //20161010 read back judge
   pass <= #1 0;
  //else if(&cnt) //2016 0822clear after ~0.1ms of EOT go low, duration based on EOT part
  //else if(&cnt_bin_after_EOT)//20161018 time test
   //pass <= #1 0;
  else
   pass <= #1 pass; 
	
always @ (posedge CLK or posedge RST)
  if (RST) 
    f_timeout <= #1 0;
  else if (TST_STA)	 
    f_timeout <= #1 1;
  else if (TST_DN)	 
   f_timeout <= #1 0;
  else	
   f_timeout <= #1 f_timeout;	
	
/*	
always @ (posedge CLK or posedge RST)
  if (RST)  
   pass <= #1 	0;
  else if (TST_STA)	//(cntz==12'hfff && !(f_lvl | f_chksum | f_lpbk | (PRB_ST == 3 && !read_flg)))//20160914 when it real pass,high
   pass <= #1 1;
  //else if (f_lvl | f_chksum |f_lpbk) //orig
  //else if (f_lvl | f_chksum | f_lpbk | (PRB_ST == 3 && read_flg)) //20160818 read back judge
  else if (f_lvl | f_chksum | f_lpbk | //&cnt_SEFIN //20161018 when &cnt_SEFIN,fail
         |(cnt_rd_flg==26'h23FFFFF && PRB_ST == 3 && read_flg)) //20161010 read back judge
   pass <= #1 0;
  //else if(&cnt) //2016 0822clear after ~0.1ms of EOT go low, duration based on EOT part
  //else if(&cnt_bin_after_EOT)//20161018 time test
   //pass <= #1 0;
  else
   pass <= #1 pass;  
	*/
////////end change 11/3/2016

/*
always @ (posedge CLK or posedge RST)
  if (RST)
	TESTER_CMPLT <= #1 1;
  else if (TST_DN)
   TESTER_CMPLT <= #1 0;
  else if (&cnt)
   TESTER_CMPLT <= #1 1;
  else
   TESTER_CMPLT <= #1 TESTER_CMPLT;  
	


always @ (posedge CLK or posedge RST)
  if (RST)
	TESTER_STOP <= #1 0;
  else 
   TESTER_STOP <= #1 PRB_ST==4;  
	*/
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    TRIG <= #1 0;
  else 
    TRIG <= #1 cnt2>=24'h1_8f_ff_c0;//cnt2>=2;//&cnt2;//!TST_STA;  
	 
		
endmodule		