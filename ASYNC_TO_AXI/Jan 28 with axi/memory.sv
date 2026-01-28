module memory #(parameter DATA_WIDTH = 4, DEPTH = 4, PTR_WIDTH = 3)
  (input rclk,
   input wclk,
   input w_en,
   input r_en,
   input full,empty,
   input [PTR_WIDTH : 0]b_wptr,b_rptr,
   input [DATA_WIDTH - 1 : 0]data_in,
   output reg [DATA_WIDTH - 1 : 0]data_out);
  
  reg [DATA_WIDTH - 1 : 0]mem[0 : DEPTH-1]; 

  //for debugging only
  // wir [DATA_WIDTH-1 : 0]debug_out;
  
  //read operation
  always@(posedge rclk) begin
    if(r_en && !empty) begin
      data_out <= mem[b_rptr[PTR_WIDTH - 1 : 0]];
    end
  end
  
  //write operation
  always@(posedge wclk) begin
    if(w_en && !full) begin
      //we didn't used MSB, it'll be used for detection empty and full
      mem[b_wptr[PTR_WIDTH - 1 : 0]] <= data_in;
    end
  end
  
endmodule