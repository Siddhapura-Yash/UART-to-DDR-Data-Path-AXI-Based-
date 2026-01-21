module rptr_handler #(parameter PTR_WIDTH = 3)
  (input rclk,rrst,r_en,
   input [PTR_WIDTH : 0]g_wptr_sync,
   output reg [PTR_WIDTH : 0]b_rptr = 0,g_rptr = 0,
   output reg empty = 0);
  
//   while incrementing we use all the bits
  reg [PTR_WIDTH : 0]b_rptr_next;
  reg [PTR_WIDTH : 0]g_rptr_next;
  reg rempty;
  
  // assign b_rptr_next = b_rptr + (r_en & !empty);
  // assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;
  // assign rempty = (g_wptr_sync == g_rptr_next) ? 1'b1 : 1'b0;

  always@(*) begin
    b_rptr_next = b_rptr + ((r_en & !empty) ? 1'b1 : 1'b0);
    g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;
    rempty = (g_wptr_sync == g_rptr_next) ? 1'b1 : 1'b0;
  end
  
  always@(posedge rclk or negedge rrst) begin
    if(!rrst) begin
      b_rptr <= 0;
      g_rptr <= 0;
//       empty <= 1'b1;
    end
    else begin
      b_rptr <= b_rptr_next;
	    g_rptr <= g_rptr_next;
//       rempty <= (g_wptr_sync == g_rptr_next);
    end
  end
  
  always@(posedge rclk or negedge rrst) begin
    if(!rrst) begin
      empty <= 1;
    end
    else begin
      empty <= rempty;
    end
  end
  
endmodule