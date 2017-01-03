/*
 trim300k.v
 Send 8 Bytes BMC encoded "55" at 300kbps, totally 5 times, interval between each burst is 20us minimun
 5555555555555555-------20us----------5555555555555555-------20us----------5555555555555555-------20us----------5555555555555555-------20us----------5555555555555555
 
 Yxu, April 2015
*/

module trim300k(
input TRIM_START,  //when push button, start state machine
input CLK, RSTB, // 10M clock, period=100ns
output wire VCONN300K, //for VCONN, single pulse
output reg BIT300K, //binary input for bmcenc300k
output reg BVLD300K,//BVLD, level
output reg BEN300K,  // BEN single pulse each bit
output TRIM_FIN,// After sending 55, wait for 2ms, then send TRIM_FIN to ini_host
input VCONN_AND
);


//states
reg [2:0] st_trim; //
parameter trim_idle = 3'd0; 
parameter trim_wait = 3'd4; // 
parameter trim_burst = 3'd1;  //
parameter trim_fin = 3'd5;  // 
parameter trim_zero = 3'd2;  // 
parameter trim_one = 3'd3;  // 
parameter trim_vconn = 3'd6;


//parameter period = 33;  //actual period is 34, 0-33, 294k at 10M clock
parameter period = 97;//100;
parameter wait_time = 300; //20us //30us
parameter wait_2ms = 20000;

assign VCONN300K = TRIM_START;



//counter
reg [6:0] period_cnt;//count 34
reg [7:0] bits_cnt; //count 64 bit
reg [8:0] wait_cnt;  // count 200
reg [3:0] burst_cnt; // count 5
reg [15:0] fin_cnt;

reg trim_start_d;
reg [3:0] st_trim_d;

wire burst_fin = bits_cnt == 64;
wire wait_fin = wait_cnt == wait_time;
//assign TRIM_FIN = st_trim == trim_fin;
assign TRIM_FIN = (fin_cnt == wait_2ms);
wire start = TRIM_START;
reg vconn_and_d;

//state machine for sending 55, lsb first, ...010101->
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		st_trim <= #1 trim_idle;
	else if (start)
		st_trim <= #1 trim_burst;
	else 
		case (st_trim)
		trim_idle: 
			 	st_trim <= #1 trim_idle;
		
		
		trim_burst: 			
			    	st_trim <= #1 trim_one;
		trim_one:  if (period_cnt >= period)
				st_trim <= #1 trim_zero;
			    else st_trim <= #1 trim_one;
		trim_zero:   if (period_cnt >= period)
				if (burst_fin)
					st_trim <= #1 (burst_cnt == 5)? trim_vconn : trim_wait;
			    		
				else st_trim <= #1  trim_one;
				
			    else st_trim <= #1 trim_zero;
			    
		trim_wait:  if (wait_fin)
				st_trim <= #1 trim_one;
			   else
			   	st_trim <= #1  trim_wait;
					
		trim_vconn:	if (!VCONN_AND && !vconn_and_d) 
							st_trim <= #1 trim_fin;
						else
							st_trim <= #1 trim_vconn;
							
		trim_fin:	if (fin_cnt == wait_2ms) 
							st_trim <= #1 trim_idle;
						else
							st_trim <= #1 trim_fin;
		
		default: st_trim <= #1 trim_idle;
		endcase

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		st_trim_d <= #1 1'b0;
	else 	st_trim_d <= #1 st_trim;

always @ (posedge CLK or negedge RSTB) // error timer 6.4s
	if (!RSTB)
		BIT300K <= #1 0;
	else if (st_trim != trim_zero && st_trim != trim_one)
		BIT300K <= #1 0;
	else if (st_trim == trim_zero)
		BIT300K <= #1 0;
	else if (st_trim == trim_one)
		BIT300K <= #1 1;
	else	BIT300K <= #1 BIT300K;
	

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		 BEN300K <= #1 0;
   	else if (st_trim == trim_zero || st_trim == trim_one)
		 BEN300K <= #1 1;
	else	 BEN300K <= #1 0;

wire zero_pedge = (st_trim == trim_zero) && (st_trim_d != trim_zero);
wire one_pedge = (st_trim == trim_one) && (st_trim_d != trim_one);
		
always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		BVLD300K <= #1 0;
	else 
		BVLD300K <= #1  (zero_pedge || one_pedge);
	

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		period_cnt <= #1 0;
	else if(period_cnt >= period)
		period_cnt <= #1 period_cnt-period;
	else if (st_trim == trim_zero || st_trim == trim_one)
		period_cnt <= #1 period_cnt + 3;
	else	period_cnt <= #1 0;
	
			
			
always @ (posedge CLK or negedge RSTB)  //count 64 bits
	if (!RSTB)
		bits_cnt <= #1 0;
	else if (st_trim == trim_wait || st_trim == trim_fin)
		bits_cnt <= #1 0;
	else if  (zero_pedge|| one_pedge)
		bits_cnt <= #1 bits_cnt + 1;
	else 	bits_cnt <= #1 bits_cnt;
	
always @ (posedge CLK or negedge RSTB)  //count 20us
	if (!RSTB)
		wait_cnt <= #1 0;
	else if (st_trim == trim_wait)
		wait_cnt <= #1 wait_cnt + 1;
	else	wait_cnt <= #1 0;

always @ (posedge CLK or negedge RSTB)//count 5 
	if (!RSTB)
		burst_cnt <= #1 0;
	else if (st_trim == trim_burst)
		burst_cnt <= #1 1;
	else if (st_trim == trim_wait && st_trim_d != trim_wait)
		burst_cnt <= #1 burst_cnt + 1;
	else 	burst_cnt <= #1 burst_cnt;
	
always @ (posedge CLK or negedge RSTB)  //count 2ms
	if (!RSTB)
		fin_cnt <= #1 0;
	else if (fin_cnt == wait_2ms)
		fin_cnt <= #1 0;
	else if (st_trim == trim_fin)
		fin_cnt <= #1 fin_cnt + 1;
	else	fin_cnt <= #1 0;
	

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		trim_start_d <= #1 1'b0;
	else 	trim_start_d <= #1 TRIM_START;

always @ (posedge CLK or negedge RSTB)
	if (!RSTB)
		vconn_and_d <= #1 1'b0;
	else 	vconn_and_d <= #1 VCONN_AND;
	
endmodule
	
