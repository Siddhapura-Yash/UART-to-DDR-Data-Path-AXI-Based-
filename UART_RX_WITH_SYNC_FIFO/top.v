`include "rx.v"
`include "byte_fifo.v"

module top#(  parameter TB_DATA_WIDTH = 8,
              parameter TB_CLK_FREQ = 100_000_000,
              parameter TB_BAUD_RATE = 115200,
              parameter TB_DEPTH = 8) 
              (input tb_clk,
               input tb_rx,
               input tb_ren);
  
  wire [TB_DATA_WIDTH - 1 : 0]rx_result;
  wire rx_done;
  wire sync_full,sync_empty;
  wire tb_wen;
  assign tb_wen = (rx_done && !sync_full) ? 1'b1 : 1'b0; 

  wire full,empty;
  wire [TB_DATA_WIDTH - 1 :0]sync_out;
  
  rx #(.DATA_WIDTH(TB_DATA_WIDTH),.CLK_FREQ(TB_CLK_FREQ),.BAUD_RATE(TB_BAUD_RATE)) RX_DUT (.clk(tb_clk),.rx(tb_rx),.result(rx_result),.done(rx_done));
  
  sync_fifo #(.DATA_WIDTH(TB_DATA_WIDTH),.DEPTH(TB_DEPTH)) SYNC_FIFO_DUT (.clk(tb_clk),.rst(	),.r_en(tb_ren),.w_en(tb_wen),.data_in(rx_result),.data_out(sync_out),.full(sync_full),.empty(sync_empty));
  
endmodule