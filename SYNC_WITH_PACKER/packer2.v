module packer2 #(
    parameter DATA_WIDTH = 8,
    parameter WORD_WIDTH = 128
)(
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire                  clk,
    input  wire                  check_empty,
    input  wire                  word_fifo_full,

    output reg  [WORD_WIDTH-1:0] data_out,
    output reg                   packed_done,
    output wire                  read_enable
);

    reg [4:0] byte_count;   // counts how many bytes are ALREADY packed

    always @(posedge clk) begin
        // default
        packed_done <= 1'b0;

        if (!check_empty && !word_fifo_full) begin
            // pack current byte
            data_out <= {data_in, data_out[WORD_WIDTH-1:8]};

            if (byte_count == 5'd15) begin
                // this byte completes 128-bit word
                packed_done <= 1'b1;
                byte_count  <= 5'd0;
            end
            else begin
                byte_count <= byte_count + 1'b1;
            end
        end
    end

    // read only when we can safely accept a byte
    assign read_enable =
        (!check_empty) &&
        (!word_fifo_full) &&
        (byte_count != 5'd15);

endmodule
