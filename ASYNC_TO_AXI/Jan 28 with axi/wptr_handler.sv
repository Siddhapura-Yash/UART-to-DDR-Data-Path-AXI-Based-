module wptr_handler #(parameter PTR_WIDTH = 3)
  (input wclk,wrst,w_en,
   input [PTR_WIDTH : 0]g_rptr_sync,
   output reg [PTR_WIDTH : 0]b_wptr,g_wptr,
   output reg full,
   output wfull);
  
  
  reg [PTR_WIDTH : 0]b_wptr_next;
  reg [PTR_WIDTH : 0]g_wptr_next;
  
  reg wrap_around;
  // wire wfull;
  
  assign b_wptr_next = b_wptr + (w_en & !full);
  assign g_wptr_next = (b_wptr_next	 >> 1) ^ b_wptr_next;
  // always@(*) begin
  // b_wptr_next <= b_wptr + (w_en & !full);
  // g_wptr_next <= (b_wptr_next	 >> 1) ^ b_wptr_next;
  // end
  
  always@(posedge wclk or negedge wrst) begin
    if(!wrst) begin
      b_wptr <= '0;
      g_wptr <= '0;
    end
    else begin
      b_wptr <= b_wptr_next;
      g_wptr <= g_wptr_next;
    end
  end
  
  always@(posedge wclk or negedge wrst) begin
    if(!wrst) begin
      full <= 0;
    end
    else begin
      full <= wfull;
    end
  end
  
  assign wfull = (g_wptr_next == {~g_rptr_sync[PTR_WIDTH : PTR_WIDTH - 1],g_rptr_sync[PTR_WIDTH - 2 : 0]}) ? 1'b1 : 1'b0;
  
endmodule