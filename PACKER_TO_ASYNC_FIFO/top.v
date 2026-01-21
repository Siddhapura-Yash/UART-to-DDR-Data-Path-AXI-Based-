`include "rx.v"
`include "byte_fifo.v"
`include "packer.v"
`include "async_top.sv"

module top#(  parameter TB_DATA_WIDTH = 8,
              parameter TB_CLK_FREQ = 100_000_000,
              parameter TB_BAUD_RATE = 115200,
              parameter TB_DEPTH = 8,
              parameter TB_WORD_WIDTH = 256) 
              (input tb_clk,
               input tb_rx,
               input async_r_en,  //for simulation we will provide enable so we can see data on data_out pin
               input read_clk_async);
  
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
  wire word_full;
  wire packer_ren;
  // assign packer_ren = (!sync_empty) ? 1'b0: 1'b1;

  //async signal for axi inteface
  wire [TB_WORD_WIDTH-1 : 0]async_out;
  wire async_empty;
  
  rx #(.DATA_WIDTH(TB_DATA_WIDTH),.CLK_FREQ(TB_CLK_FREQ),.BAUD_RATE(TB_BAUD_RATE)) RX_DUT (.clk(tb_clk),.rx(tb_rx),.result(rx_result),.done(rx_done));
  
  sync_fifo #(.DATA_WIDTH(TB_DATA_WIDTH),.DEPTH(TB_DEPTH)) SYNC_FIFO_DUT (.clk(tb_clk),.rst(1'b1),.r_en(packer_ren),.w_en(tb_wen),.data_in(rx_result),.data_out(sync_out),.full(sync_full),.empty(sync_empty));
  
  packer #(.DATA_WIDTH(TB_DATA_WIDTH),.WORD_WIDTH(TB_WORD_WIDTH)) PACKER_DUT (.data_in(sync_out),.clk(tb_clk),.check_empty(sync_empty),.word_fifo_full(word_full),.data_out(word_out),.packed_done(word_packed_done),.read_enable(packer_ren));

  async_top #(.DEPTH(TB_DEPTH),.DATA_WIDTH(TB_WORD_WIDTH)) ASYNC_DUT (.wclk(tb_clk),.wrst(1'b0),.rclk(read_clk_async),.rrst(1'b0),.w_en(word_packed_done),.r_en(async_r_en),.data_in(word_out),.data_out(async_out),.full(word_full),.empty(async_empty));


endmodule