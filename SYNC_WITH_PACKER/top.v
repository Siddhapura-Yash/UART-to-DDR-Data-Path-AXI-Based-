`include "rx.v"
`include "byte_fifo.v"
`include "packer.v"

module top#(  parameter TB_DATA_WIDTH = 8,
              parameter TB_CLK_FREQ = 100_000_000,
              parameter TB_BAUD_RATE = 115200,
              parameter TB_DEPTH = 8,
              parameter TB_WORD_WIDTH = 256) 
              (input tb_clk,
               input tb_rx,
               input tb_ren);
  
  //UART signals
  wire [TB_DATA_WIDTH - 1 : 0]rx_result;
  wire rx_done;
  wire sync_full,sync_empty;
  wire tb_wen;
  assign tb_wen = (rx_done && !sync_full) ? 1'b1 : 1'b0; 

  //SYNC FIFO signals
  wire full,empty;
  wire [TB_DATA_WIDTH - 1 :0]sync_out;

  //packer signals
  wire [TB_WORD_WIDTH-1:0]word_out;
  wire word_packed_done;    //will be used for write enable in wword fifo
  wire word_full = 0;
  wire packer_ren;
  
  rx #(.DATA_WIDTH(TB_DATA_WIDTH),.CLK_FREQ(TB_CLK_FREQ),.BAUD_RATE(TB_BAUD_RATE)) RX_DUT (.clk(tb_clk),.rx(tb_rx),.result(rx_result),.done(rx_done));
  
  sync_fifo #(.DATA_WIDTH(TB_DATA_WIDTH),.DEPTH(TB_DEPTH)) SYNC_FIFO_DUT (.clk(tb_clk),.rst(1'b1),.r_en(packer_ren),.w_en(tb_wen),.data_in(rx_result),.data_out(sync_out),.full(sync_full),.empty(sync_empty));
  
  packer #(.DATA_WIDTH(TB_DATA_WIDTH),.WORD_WIDTH(TB_WORD_WIDTH)) PACKER_DUT (.data_in(sync_out),.clk(tb_clk),.check_empty(sync_empty),.word_fifo_full(word_full),.data_out(word_out),.packed_done(word_packed_done),.read_enable(packer_ren));

//   module packer#(parameter DATA_WIDTH = 8,
//                parameter WORD_WIDTH = 128)
//              (input [DATA_WIDTH-1:0]data_in,
//               input clk,
//               input check_empty,
//               input word_fifo_full, //mostly would not ever be full
//               output reg [WORD_WIDTH-1:0]data_out,
//               output reg packed_done,   //work as write enable for word fifo
//               output read_enable);

endmodule