//
//burn_st.v
//
module burn_st(

					input wire CLK,
					input wire RST,
					
					input wire TRIG,

					output reg SEC_ER,
					output reg PROG
	);
parameter end_cnt=24'hffffff;
	
reg [1:0] d_trig;

reg [23:0] cnt;


always @ (posedge CLK or posedge RST)
  if (RST)
    d_trig <= #1 0;
  else
    d_trig <= #1 {d_trig, TRIG};
      
always @ (posedge CLK or posedge RST)
  if (RST)
    SEC_ER <= #1 0;
  else
    SEC_ER <= #1 d_trig[0] & !d_trig[1];
	 
always @ (posedge CLK or posedge RST)
  if (RST)	 
    cnt <= #1 0;
  else if (SEC_ER)
    cnt <= #1 1;
  else if (cnt==end_cnt)
    cnt <= #1 0;
  else
    cnt <= #1 cnt+|cnt;
	 
	 
always @ (posedge CLK or posedge RST)
  if (RST)
    PROG <= #1 0;
  else
    PROG <= #1 (cnt==end_cnt);
    

endmodule	