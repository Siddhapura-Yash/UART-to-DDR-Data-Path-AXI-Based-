module packer #(
    parameter DATA_WIDTH = 8,
    parameter WORD_WIDTH = 128
)(
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire                  clk,
    input  wire                  check_empty,
    input  wire                  word_fifo_full,

    output reg  [WORD_WIDTH-1:0] data_out,
    output reg                   packed_done,
    output wire                  read_enable,

    output wire [WORD_WIDTH-1:0] packer_next   // debug only
);

    reg [4:0] byte_count;

    // READ CONTROL (simple and correct)
    assign read_enable =
        !check_empty &&
        !word_fifo_full &&
        (byte_count != 5'd15);

    // NEXT VALUE (debug)
    assign packer_next = {data_in, data_out[WORD_WIDTH-1:8]};

    // PACKING LOGIC
    always @(posedge clk) begin
        packed_done <= 1'b0;

        if (read_enable) begin
            data_out <= packer_next;

            if (byte_count == 5'd15) begin
                packed_done <= 1'b1;
                byte_count  <= 5'd0;
            end else begin
                byte_count <= byte_count + 1'b1;
            end
        end
    end

endmodule
