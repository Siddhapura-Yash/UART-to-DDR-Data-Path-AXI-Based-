module sync_fifo #(parameter DATA_WIDTH = 4, DEPTH = 4)
  				(input clk,
                 input rst,
                 input r_en,
                 input w_en,
                 input [DATA_WIDTH - 1 : 0]data_in,
                 output reg [DATA_WIDTH - 1 : 0]data_out,
                 output full,
                 output empty);
  
  // One extra bit for wrap
  reg [$clog2(DEPTH) : 0] w_ptr = 0,r_ptr = 0;
  reg [DATA_WIDTH - 1 : 0] mem[0 : DEPTH - 1];

   // Actual memory addresses
   wire [$clog2(DEPTH)-1:0] w_addr = w_ptr[$clog2(DEPTH)-1:0];
   wire [$clog2(DEPTH)-1:0] r_addr = r_ptr[$clog2(DEPTH)-1:0];
  
  //Write data
  always@(posedge clk) begin
    if(!rst) begin
      w_ptr <= 0;
    end
    else begin
      if(w_en && !full) begin
        mem[w_addr] <= data_in;
        w_ptr <= w_ptr + 1;
      end
 	 end
  end
  
  //Read data
  always@(posedge clk) begin
    if (!rst) begin
      r_ptr <= 0;
      data_out <= 0;
    end
    else begin
      if(r_en && !empty) begin
        data_out <= mem[r_addr];
        r_ptr <= r_ptr + 1;
      end
  	end
  end

  assign empty = (r_ptr == w_ptr) ? 1'b1 : 1'b0;
  assign full =  (w_addr == r_addr) && (w_ptr[$clog2(DEPTH)] != r_ptr[$clog2(DEPTH)]);
  
endmodule      