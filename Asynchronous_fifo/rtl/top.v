`include "2_ff_synchronizer.v"
`include "memory.v"
`include "wptr_handler.v"
`include "rptr_handler.v"

module top #(parameter DEPTH = 8, DATA_WIDTH = 8)
  (input wclk,wrst,
   input rclk,rrst,
   input w_en,r_en,
   input [DATA_WIDTH - 1 : 0]data_in,
   output reg [DATA_WIDTH - 1 : 0]data_out,
   output reg full,empty);
  
  parameter PTR_WIDTH = $clog2(DEPTH);
  
  reg [PTR_WIDTH:0] g_wptr_sync, g_rptr_sync;
  reg [PTR_WIDTH:0] b_wptr, b_rptr;
  reg [PTR_WIDTH:0] g_wptr, g_rptr;

  wire [PTR_WIDTH-1:0] waddr, raddr;
  
  sync #(PTR_WIDTH) sync_wptr (rclk, rrst, g_wptr, g_wptr_sync); //write pointer to read clock domain
  sync #(PTR_WIDTH) sync_rptr (wclk, wrst, g_rptr, g_rptr_sync); //read pointer to write clock domain 
  
  wptr_handler #(PTR_WIDTH) wptr_h(wclk, wrst, w_en,g_rptr_sync,b_wptr,g_wptr,full);
  rptr_handler #(PTR_WIDTH) rptr_h(rclk, rrst, r_en,g_wptr_sync,b_rptr,g_rptr,empty);
  memory #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH),.PTR_WIDTH(PTR_WIDTH)) mem(rclk, wclk, w_en,r_en, full, empty, b_wptr, b_rptr, data_in,data_out);
  
endmodule
