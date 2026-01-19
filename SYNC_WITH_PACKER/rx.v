module rx #(parameter DATA_WIDTH = 8,parameter CLK_FREQ = 100_000_000,parameter BAUD_RATE = 115200)
           (input clk,
            input rx,
            output reg [DATA_WIDTH - 1 : 0]result,
            output reg done);
  
  reg [31:0]count; //for couting baud rate
  reg [2:0]state = 0;
  reg [7:0]index;
  reg [7:0]internal_result = 0;
  
  reg [1:0] rx_sampled = 0;
    
    // initial begin
    //     result  = 0;
    //     done = 0;
    // end
  
  localparam integer T = CLK_FREQ / BAUD_RATE;
  
  always @(posedge clk) begin
        //IDLE and checking start bit
        if(state == 0) begin
            rx_sampled[1] <= rx_sampled[0];
            rx_sampled[0] <= rx;
            count <= 0;
            index <= 0;
            // result  <= 0;
            done <= 0;
            if(rx_sampled == 2'b10) state <= 1; 
        end
    
    //waiting for T/2 cycles to capture data at mid 
    if(state == 1) begin
      count <= count + 1;
      if(count == T/2) begin
        state <= 2;
        count <= 0;
      end
    end
    
    //receive data
    if(state == 2) begin
      count <= count + 1;
        if(count == T) begin
              if(index <= 7) begin
                internal_result[index] <= rx;
                index <= index + 1;
                count <= 0;
                state <= 2;
              end
              if(index > 7) begin
                result <= {rx,internal_result[6:0]};  
                count <= 0;
                index <= 0;
                state <= 3;
                // done <= 1;
              end
     	 end
    end
                            
	//stop bits
	if(state == 3) begin
		count <= count + 1;
        result <= internal_result;
      if(count == T) begin
        if(index != 1) begin
          state <= 3;
          index <= index + 1;
          count <= 0;
        end
        if(index == 1) begin
          count <= 0;
          index <= 0;
          state <= 4;
        end
      end
	end
  
    //send done signal and go to idle
    if(state == 4) begin
   		 count <= count + 1;
      if(count == 10) begin
           done <= 1;
      end
      if(count == 11) begin
          count <= 0;
          state <= 0;
          internal_result <= 0;
          index <= 0;
          rx_sampled <= 0;
          done <= 0;
      end
    end

end
                                    
endmodule