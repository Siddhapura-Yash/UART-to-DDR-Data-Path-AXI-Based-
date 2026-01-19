module sync #(parameter DATA_WIDTH = 3)(input clk,
                                        input rst,
                                        input [DATA_WIDTH:0]data_in,
                                        output reg [DATA_WIDTH:0]data_out);
  
  reg [DATA_WIDTH : 0]q;
  
  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      data_out <= 'b0;
      q <= 'b0;
    end
    else begin
      q <= data_in;
      data_out <= q;
    end
  end
  
endmodule
