//
//probe_st.v
//
module probe_st(
				input wire CLK,
				input wire RST,
				
				input wire [7:0] ASCII,
				input wire ASCII_EN,
				input wire K_ENTER,
				
				
				output reg [2:0] PRB_ST,
				output reg CLR_XPOS
				);

always @ (posedge CLK or posedge RST)
  if (RST)
    CLR_XPOS <= #1 0;
  else
    CLR_XPOS <= #1 PRB_ST==2;  

always @ (posedge CLK or posedge RST)
  if (RST)
    PRB_ST <= #1 0;
  else if (PRB_ST==0)
    PRB_ST <= #1 {2'd0,(K_ENTER)&&(PRB_ST==3'd0)};
  else if (PRB_ST==1) begin
    if (ASCII_EN)
	   case (ASCII)
		  7'd65: PRB_ST <= #1 2;
		  7'd66: PRB_ST <= #1 3;
		  7'd67: PRB_ST <= #1 4;
		  default: PRB_ST <= #1 PRB_ST;
		  endcase
	 else
	  PRB_ST <= #1 PRB_ST;
	 end
	 /*
  else if (PRB_ST==2)
     PRB_ST <= #1 0;
	  */
  else if (PRB_ST==3||PRB_ST==4)
     PRB_ST <= (ASCII_EN&&ASCII==7'd65)?2:PRB_ST; 
  else
     PRB_ST <= #1 0;  

				
endmodule				