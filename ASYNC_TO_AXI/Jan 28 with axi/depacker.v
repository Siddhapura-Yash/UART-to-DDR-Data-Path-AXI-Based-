module depacker#(parameter WORD_WIDTH = 256)
               (input clk,
                input rst,
                input [WORD_WIDTH -1 :0]data_in,
                input check_empty,
                input byte_full,
                output reg read_enable,
                output reg [7:0]data_out,
                output reg write_enable,
                input uart_byte_empty,
                output reg valid);
                
localparam byte_count = WORD_WIDTH / 8;
localparam index_width = $clog2(byte_count);

reg [WORD_WIDTH-1:0]internal_store;
reg [index_width-1 : 0]index;
reg active;         //to check if busu or not while sending data

always@(posedge clk or negedge rst) begin
    if(!rst)begin
        data_out <= 'b0; 
        internal_store <= 'b0;
        index <= 'b0;
        data_out <= 'b0;
        active <= 'b0;
        valid <= 'b0;
    end
    else begin
        read_enable <= 0;       //default should be low
        write_enable <= 0;
        valid <= 1'b0;
            //load new word
            if(!check_empty && !active && !read_enable) begin
                read_enable <= 1'b1;
                //internal_store <= data_in;
                //active <= 1'b1;
                index <= 'b0;
             end
             else if(read_enable) begin
                active <= 1'b1;
                internal_store <= data_in;
             end
             else if(active && !byte_full) begin
                data_out <= data_in[(byte_count-1-index)*8 +: 8];
                //data_out <= internal_store[index*8 +: 8];
                write_enable <= 1'b1;
                valid <= 1'b1;
                
                if(index == byte_count - 1) begin
                    active <= 1'b0;
                end
                else begin
                    index <= index + 1'b1;
                end
             end
            end
    end

endmodule        