/*
 ini_host.v
 once pushed the button, host will send device sector erase command for the first 15 sectors,
 after erase finished, host will get firmware from ROM and send it
 to device, byte 0x780-0x783 and data after 0x79F skipped, 73 data packets in total
 
 Yxu, Jan 2015
*/

module ini_host (
input BT_START,  //when push button, start state machine
input BT_SE, //sector erase
input CLK, RSTB, // 10M clock, period=100ns
input ACK, //ACK from device, one2four
input NAK, // NAK from device, one2four
input ER_END, //sector done from device
output reg WRITE_MESSAGE, //write command 
output reg ERASE_MESSAGE, // sector erase command
output reg SE_FIN,//sector erase finish
output reg FINISH2K, // 2K programming finished
output ERR_W, // when timer timeout, send error signal
output ERR_SE, // sector erase timeout error signal

output LPBK_DN,
output CHKSUM_DN,
output LVL_DN,
output reg BIST_CHK,
//////////
////////////


output [7:0] MESSAGE_A0, // to memctl
output [7:0] MESSAGE_A1,
output [7:0] MESSAGE_A2,
input TST_SW,

output [2:0] led_tst
);

parameter pk_len = 5'd27; // maximun length of packet is 27 Bytes
//states of writing
parameter st_idle = 3'd0; 
parameter st_cmdw = 3'd1; // send write command to device
parameter st_sending = 3'd2;  // wait for device response
parameter st_fin = 3'd3;  // 2K finished
parameter st_resend = 3'd4; // resend same packet
parameter st_err = 3'd5; //timeout error state
parameter st_wt = 3'd6;

reg [2:0] st_cnt; //state for writing
reg [2:0] st_se;  //state for sector erase
reg [2:0] tst_st_cnt; //state for writing
reg [2:0] tst_st_se;  //state for sector erase

assign led_tst=tst_st_cnt;

//assign BIST_CHK=tst_st_cnt!=st_idle;

//states of sector erase
parameter se_idle = 3'd0;
parameter se_se = 3'd1;
parameter se_erasing = 3'd2;
parameter se_fin = 3'd3;
parameter se_err = 3'd4;
parameter se_resend = 3'd5;

parameter SIZE = 5'd19;
reg [6:0] pk_cnt; //packet counter
//reg [3:0] se_cnt;
reg [7:0] command;
reg [4:0] length;
reg [14:0] address;

reg [SIZE - 1:0] prog_cnt;// program timer, 3.2s, maximum time for programming
reg [SIZE - 1:0] se_cnt;
reg bt_se_d;

assign MESSAGE_A0 = command;
assign MESSAGE_A1 [7:3] = length;
assign MESSAGE_A1 [2:0] = address [10:8];
assign MESSAGE_A2 = address [7:0];

assign ERR_W = (st_cnt == st_err);
assign ERR_SE = (st_se == se_err);
wire write = (SE_FIN|/*BT_START|*/ st_cnt!= st_idle);// == st_cmdw | st_cnt == st_sending | st_cnt == st_fin | st_cnt == st_resend);
wire serase = (BT_SE | st_se!= se_idle); // == se_se | st_se == se_erasing | st_se == se_fin);
wire [3:0] addrse = address [10:7];

//////////////
wire lpbk=tst_st_se!=se_idle;
wire chksum=tst_st_cnt!=st_idle;

reg [19:0] er_wait;//838ms  // 150ms min
reg [19:0] wr_wait;//6ms //1.75ms min
reg [21:0] cnt_stwt;


always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
	   BIST_CHK <= #1 0;
	  else if  ((cnt_stwt==32)&&(!BIST_CHK)&&(tst_st_cnt!=st_idle))
	    BIST_CHK <= #1 1;
	  else if (BIST_CHK && (cnt_stwt==32) )
	    BIST_CHK <= #1 0;	
     else
	    BIST_CHK <= #1 BIST_CHK;	  

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
	  cnt_stwt <= #1 0;
	else
  	  	  cnt_stwt <= #1 (tst_st_cnt==st_wt||tst_st_se==st_wt)?(~&cnt_stwt)+cnt_stwt:0;

//state machine for writing
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		st_cnt <= #1 st_idle;
	else if (BT_SE)
		st_cnt <= #1 st_idle;
	else 
		case (st_cnt)
		st_idle: if (SE_FIN)//(BT_START)
				st_cnt <= #1 st_cmdw;
			 else 
			 	st_cnt <= #1 st_idle;
		st_cmdw: st_cnt <= #1 st_sending;
		
		st_sending: 
		
				if (&prog_cnt)
				 //st_cnt <= #1 st_err; 
				 st_cnt <= #1 st_resend;
				 
			    else if (NAK)
				 st_cnt <= #1 st_resend;
				 else if (ACK/*|| (&prog_cnt)*/)
			
				 /*
				 ////////////////
			    if (&wr_wait)*/ begin
					if (pk_cnt < 73 )
						st_cnt <= #1 st_cmdw;
					else
						st_cnt <= #1 st_fin;
						end
			    else
			    		st_cnt <= #1 st_sending;
		st_fin:	 st_cnt <= #1 st_idle;
		st_resend: st_cnt <= #1 st_sending;
		st_err:  st_cnt <= #1 st_idle;
		default: st_cnt <= #1 st_idle;
		endcase
		  
//state machine for writing
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		tst_st_cnt <= #1 st_idle;
	else if (BT_SE)
		tst_st_cnt <= #1 st_idle;
	else 
		case (tst_st_cnt)
		 st_idle: if (LPBK_DN)//(BT_START)
				tst_st_cnt <= #1 st_wt;//st_cmdw;
			 else 
			 	tst_st_cnt <= #1 st_idle;
		st_wt: 	tst_st_cnt <= #1 (&cnt_stwt)? st_cmdw:st_wt;	
		st_cmdw: tst_st_cnt <= #1 st_sending;
		
		st_sending: 
		/*
				if (&prog_cnt)
				 //st_cnt <= #1 st_err; 
				 st_cnt <= #1 st_resend;
			    else if (NAK)
				 st_cnt <= #1 st_resend;
				 else if (ACK)
				 */
				 
				 ////////////////
			    if (&wr_wait) begin
					if (pk_cnt < 2)//(pk_cnt < 73)
						tst_st_cnt <= #1 st_resend;//st_cmdw;
					else
						tst_st_cnt <= #1 st_fin;
						end
			    else
			    		tst_st_cnt <= #1 st_sending;
		st_fin:	 tst_st_cnt <= #1 st_idle;
		st_resend: tst_st_cnt <= #1 st_wt;//st_cmdw;//st_sending;
		st_err:  tst_st_cnt <= #1 st_idle;
		default: tst_st_cnt <= #1 st_idle;
		endcase
		
always @ (posedge CLK or negedge RSTB) 
	if (!RSTB)
	  wr_wait <= #1 0;
	else if (tst_st_cnt==st_sending)
	  wr_wait <= #1 wr_wait+(~&wr_wait);
	else 
	  wr_wait <= #1 0;		

//state machine for sector erase
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		st_se <= #1 se_idle;
	else if (BT_SE)
		st_se <= #1 se_se;//se_fin;//se_se;
	else 
		case (st_se)
		se_idle: /*if (BT_SE)
				st_se <= #1 se_se;
			 else */
			 	st_se <= #1 se_idle;
		se_se: st_se <= #1 se_erasing;
		
		se_erasing: 
		
			    if (&se_cnt)
			    	//st_se <= #1 se_err;
					st_se <= #1 se_resend;
					
				 else if (NAK)
					st_se <= #1 se_resend;
			    else if (ER_END/*||(&se_cnt)*/)
			    	if (address [10:7] == 4'he)
					st_se <= #1 se_fin;
			        else
			    		st_se <= #1 se_se;
						/*
				 if (&er_wait) begin
					 if (address [10:7] == 4'he)
						st_se <= #1 se_fin;
			        else
			    		st_se <= #1 se_se;
				 end */
				/////////////////////	
			    else	st_se <= #1 se_erasing;
		se_fin:	 st_se <= #1 se_idle;
		se_resend: st_se <= #1 se_erasing;
		se_err:  st_se <= #1 se_idle;
		default: st_se <= #1 se_idle;
		endcase


//state machine for sector erase
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		tst_st_se <= #1 se_idle;
	else if (BT_SE)
		tst_st_se <= #1 se_idle;//se_fin;//se_se;
		/*
	else if (FINISH2K)
		tst_st_se <= #1 st_wt;//se_se;	
		*/
	else 
		case (tst_st_se)
		se_idle: /*if (BT_SE)
				st_se <= #1 se_se;
			 else */
			 	tst_st_se <= #1 (FINISH2K|TST_SW)? st_wt:se_idle;
		st_wt: 	tst_st_se <= #1 (&cnt_stwt)? se_se:st_wt;			
		se_se: tst_st_se <= #1 se_erasing;
		
		se_erasing: 
		/*
			    if (&se_cnt)
			    	//st_se <= #1 se_err;
					st_se <= #1 se_resend;
				 else if (NAK)
					st_se <= #1 se_resend;
			    else if (ER_END)
			    	if (address [10:7] == 4'he)
					st_se <= #1 se_fin;
			        else
			    		st_se <= #1 se_se;
						*/
				 if (&er_wait) begin
		//			 if (address [10:7] == 4'he)
						tst_st_se <= #1 se_fin;
			//        else
			  //  		st_se <= #1 se_se;
				 end
				/////////////////////	
			    else	tst_st_se <= #1 se_erasing;
		se_fin:	 tst_st_se <= #1 se_idle;
		se_resend: tst_st_se <= #1 se_erasing;
		se_err:  tst_st_se <= #1 se_idle;
		default: tst_st_se <= #1 se_idle;
		endcase

always @ (posedge CLK or negedge RSTB) 
	if (!RSTB)
	  er_wait <= #1 0;
	else if (tst_st_se==se_erasing)
	  er_wait <= #1 er_wait+(~&er_wait);
	else 
	  er_wait <= #1 0;

always @ (posedge CLK or negedge RSTB) // error timer 6.4s
	if (!RSTB)
		prog_cnt <= #1 0;
	else if (ACK|NAK|SE_FIN)
		prog_cnt <= #1 0;
	else if (/*st_cnt == st_cmdw | st_cnt == st_resend |*/st_cnt == st_sending)
		prog_cnt <= #1 prog_cnt + (~&prog_cnt);
	else	prog_cnt <= #1 0;		

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		se_cnt <= #1 0;
   else if (ER_END | NAK |BT_SE)
		se_cnt <= #1 0;
	else if (/*st_se == se_se | st_se == se_resend | */st_se == se_erasing)
		se_cnt <= #1 se_cnt + (~&se_cnt);
	else	se_cnt <= #1 0;
		
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		WRITE_MESSAGE <= #1 1'b0;
	else if (st_cnt == st_cmdw | st_cnt == st_resend 
			| tst_st_cnt==st_cmdw /*| tst_st_cnt == st_resend |tst_st_se==se_se*/ )
		WRITE_MESSAGE <= #1 1'b1;
	else	WRITE_MESSAGE <= #1 1'b0;

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		ERASE_MESSAGE <= #1 1'b0;
	else if (st_se == se_se | st_se == se_resend | tst_st_se==se_se)
		ERASE_MESSAGE <= #1 1'b1;
	else	ERASE_MESSAGE <= #1 1'b0;

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		FINISH2K <= #1 1'b0;
	else if (st_cnt == st_fin)
		FINISH2K <= #1 1'b1;
	else	FINISH2K <= #1 1'b0;	

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		SE_FIN <= #1 1'b0;
	else if (st_se == se_fin)
		SE_FIN <= #1 1'b1;
	else	SE_FIN <= #1 1'b0;

	
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		pk_cnt <= #1 7'd0;
	else if (BT_SE|st_cnt == st_fin | st_cnt == st_err|LPBK_DN)//(st_cnt == st_idle | st_cnt == st_fin | st_cnt == st_err)
		pk_cnt <= #1 7'd0;
	else if (st_cnt == st_cmdw)
			if (pk_cnt == 73)
				pk_cnt <= #1 0;
			else
				pk_cnt <= #1 pk_cnt + 1;
	else if (tst_st_cnt == st_cmdw)
			if (pk_cnt == 2)
				pk_cnt <= #1 0;
			else
				pk_cnt <= #1 pk_cnt + 1;
		
	else	pk_cnt <= #1 pk_cnt;
	
/*
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		command <= #1 8'd0;
	else if (write)
		command <= #1 8'h8f;
	else if  (serase)
		command <= #1 8'h2f;
	else 	command <= #1 8'd0;
	*/
	/*
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		command <= #1 8'd0;
	else if (lpbk)
		command <= #1 8'hdf;
	else if  (chksum)
		command <= #1 8'hbf;
	else 	command <= #1 8'd0;	
	*/
	
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		command <= #1 8'h8f;
	else if  (serase)
		command <= #1 8'h2f;	
	else	
			command <= #1 8'h8f;
			
	/*
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		length <= #1 5'd0;
	else if (st_cnt == st_fin | st_cnt == st_err)
			length <= #1 5'd0;
	else if (st_cnt == st_cmdw)
	
			if (pk_cnt == 71)
				length <= #1 5'd3;
			
			else	length <= #1 pk_len;
		
	else if (serase)
		if (st_se == se_fin | st_se == se_err )
			length <= #1 5'd0;
		else
			length <= #1 5'd2;
	else 
		length <= #1 length;
		*/
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		length <= #1 5'd0;
	else if (st_cnt == st_fin | st_cnt == st_err)
			length <= #1 5'd0;
	else if (st_cnt == st_cmdw)
	
			if (pk_cnt == 71)
				length <= #1 5'd3;
			
			else	length <= #1 pk_len;
		
	else if (serase)
		if (st_se == se_fin | st_se == se_err )
			length <= #1 5'd0;
		else
			length <= #1 5'd2;
	else if (lpbk)
		length <= #1 5'h1b;
	else if (chksum)
		length <= #1 5'h17;	
	else 
		length <= #1 length;
				
		
		/*
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		length <= #1 5'h1f;
	else if (write)
		length <= #1 5'h17;
	else if  (serase)
		length <= #1 5'h1b;
	else	
	   length <= #1 5'h1f;
		*/
		
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		bt_se_d <= #1 1'b0;
	else 	bt_se_d <= #1 BT_SE;

reg se_fin_d;
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		se_fin_d <= #1 1'b0;
	else 	se_fin_d <= #1 SE_FIN;

/*
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		address <= #1 11'd0;
	else if (st_cnt == st_fin | st_cnt == st_err)
			address <= #1 11'd0;
	else if (st_cnt == st_cmdw)
			if (se_fin_d)//(pk_cnt == 0)
		    		address <= #1 11'd0;
					
			else if (pk_cnt == 72)
				address <= #1 11'h784;
			else if (pk_cnt == 73) // 73 data packets in total
		     		address <= #1 address;
			else 	address <= #1 address + pk_len;
		
	else if (st_se == se_fin | st_se == se_err)
			address <= #1 11'd0;
	else if (st_se == se_se)
			if (bt_se_d)
				address <= #1 0;
			else if (address[10:7] == 4'hf)
				address <= #1 address;
			else
				address[10:7] <= #1 address [10:7] + 1;
		
	else		address <= #1 address;
	*/
	
	/*
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		address <= #1 11'h7ff;
   else		
		address <= #1 11'h7ff;			
		*/
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		address <= #1 11'd0;
	else if (st_cnt == st_fin | st_cnt == st_err)
			address <= #1 11'd0;
	else if (st_cnt == st_cmdw)
			if (se_fin_d)//(pk_cnt == 0)
		    		address <= #1 11'd0;
					
			else if (pk_cnt == 72)
				address <= #1 11'h784;
			else if (pk_cnt == 73) // 73 data packets in total
		     		address <= #1 address;
			else 	address <= #1 address + pk_len;
		
	else if (st_se == se_fin | st_se == se_err)
			address <= #1 11'd0;
	else if (st_se == se_se)
			if (bt_se_d)
				address <= #1 0;
			else if (address[10:7] == 4'hf)
				address <= #1 address;
			else
				address[10:7] <= #1 address [10:7] + 1;
	else if (lpbk|chksum)
		address <= #1 11'h7ff;	
	else		address <= #1 address;


assign LPBK_DN = tst_st_se == se_fin;
assign CHKSUM_DN = tst_st_cnt == st_resend;
assign LVL_DN = tst_st_cnt == st_fin;
endmodule
	
