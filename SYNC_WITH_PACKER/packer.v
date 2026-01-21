module packer#(parameter DATA_WIDTH = 8,
               parameter WORD_WIDTH = 128)
             (input [DATA_WIDTH-1:0]data_in,
              input clk,
              input check_empty,
              input word_fifo_full, //mostly would not ever be full
              output reg [WORD_WIDTH-1:0]data_out = 0,
              output reg packed_done,   //work as write enable for word fifo
              output read_enable,  //to read from sync fifo
            output [WORD_WIDTH-1:0]packer_next); //for debugging

    reg [6:0]byte_count = 0;    //counter range will be increment in 256 bits
    reg [WORD_WIDTH-1 : 0]internal_data_out = 0;
    // reg waste_one_cycle = 0;

    always@(posedge clk) begin
        packed_done <= 0;
            if(!check_empty && !word_fifo_full) begin
                        if(read_enable) begin
                            internal_data_out <= {data_in, internal_data_out[WORD_WIDTH-1:8]};
                            data_out <= {data_in, data_out[WORD_WIDTH-1:8]};
                                // if(byte_count == 5'd15) begin
                                //     // data_out <= internal_data_out;
                                //     // data_out <= {data_in,data_out[WORD_WIDTH-1:8]};
                                //     packed_done <= 1'b1;
                                //     byte_count <= 0;
                                // end
                                // else begin
                                byte_count <= byte_count + 1;
                                // end
                        end
                end
                else if(byte_count == 7'd32) begin      //counter will be 32 incase of 256 pakcet [for 128 bits use 16]
                    packed_done <= 1'b1;
                    byte_count <= 0;
                    data_out <= {data_in, data_out[WORD_WIDTH-1:8]};
                end
    end

    // assign read_enable = (!check_empty && (byte_count != 5'd16));
    // assign read_enable = !check_empty && !word_fifo_full;
    assign read_enable = !check_empty && !word_fifo_full && (byte_count != 7'd32);      //here count will also change incase of 256 bits [for 128 bits use 16]

    //for debugging purpose only
    assign packer_next = {data_in, internal_data_out[WORD_WIDTH-1:8]};

endmodule
