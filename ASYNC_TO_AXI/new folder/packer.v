module packer#(parameter DATA_WIDTH = 8,
               parameter WORD_WIDTH = 256)  // Changed from 128 to 256 to match TOP
             (input [DATA_WIDTH-1:0]data_in,
              input clk,
              input check_empty,
              input word_fifo_full, //mostly would not ever be full
              output reg [WORD_WIDTH-1:0]data_out = 0,
              output reg packed_done = 0,   //work as write enable for word fifo
              output read_enable,  //to read from sync fifo
            output [WORD_WIDTH-1:0]packer_next); //for debugging

    reg [7:0]byte_count = 0;    //counter range 0-31 for 256 bits (32 bytes)
    reg [WORD_WIDTH-1 : 0]internal_data_out = 0;

    always@(posedge clk) begin
        packed_done <= 1'b0;  // Default to 0 each cycle
        
        if(!check_empty && !word_fifo_full) begin
            if(read_enable) begin
                // Shift new byte into the data word
                internal_data_out <= {data_in, internal_data_out[WORD_WIDTH-1:8]};
                data_out <= {data_in, data_out[WORD_WIDTH-1:8]};
                byte_count <= byte_count + 1;
                
                // When we reach 32 bytes (256 bits), mark as packed and reset counter
                if(byte_count == 8'd31) begin  // 0-31 = 32 bytes
                    packed_done <= 1'b1;
                    byte_count <= 8'd0;
                end
            end
        end
    end

    // Read from sync FIFO when it has data, async FIFO not full, and we haven't accumulated 32 bytes yet
    assign read_enable = !check_empty && !word_fifo_full && (byte_count != 8'd32);

    //for debugging purpose only
    assign packer_next = {data_in, internal_data_out[WORD_WIDTH-1:8]};

endmodule
