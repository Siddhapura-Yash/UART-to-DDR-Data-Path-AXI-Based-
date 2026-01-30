//workingg codee till packer jan-28


module top#(  parameter TB_DATA_WIDTH = 8,
              parameter TB_CLK_FREQ = 80_000_000,  //100 MHz
              parameter TB_BAUD_RATE = 115200,
              parameter TB_DEPTH = 8,
              parameter TB_WORD_WIDTH = 256) 
              (//input tb_clk,
              //input tb_rst,   has been declared as a wire and reset will be high when pll_locked = 1
               input tb_rx,
              //  input async_r_en,  //for simulation we will provide enable so we can see data on data_out pin
              //  input read_clk_async

                //global signals
                input axi_clk,
                //input rstn,
               // input rst,

//axi signals
                input ddr_rstn,
                input check_rstn,

                //input start,

                //input [255:0] data_in,      //data will come from fifo
              //  input check_empty,          //empty signal from async fifo
                //output read_enable,         //axi send read enable to the async fifo

                //Write address channel signals
                output [7:0] aid,           //transaction id
                output reg [31:0] aaddr,    //main address
                output reg [7:0] alen,      //burst length exact number of transfers (beats)
                output reg [2:0] asize,     //how wide each beat
                output reg [1:0] aburst,    //burst type(i.e fixed,wrap......)
                output reg [1:0] alock,     //00 for our case
                output reg avalid,          //valid signal master to slave 
                input aready,               //slave responds i'm ready to acccept addresss
                output reg atype,           //read or write 1 = write 0 = read

                // Write data channel signals
                output [7:0] wid,            //write transaction id
                output reg [255:0] wdata,    //actual write data
                output  [31:0] wstrb,        //write strobe
                output reg wlast,            //last data beat of burst
                output reg wvalid,           //high means write data is valid
                input wready,                //slave says i'm ready to accept data

                // Read data channel signals
                input [7:0] rid,            //read trasaction id
                input [255:0] rdata,        //read data from ddr
                input rlast,                //last beat of read burst
                input rvalid,               //high means read data is valid
                output reg rready,          //master ready to accepet read data
                input [1:0] rresp,          //read response 

                // Write response channel signals                          
                input [7:0] bid,            //write response id
                input bvalid,               //Slave → Master high means write response is valid
                output reg bready,          //Master → Slave high means master ready to accept response 

                //ddr reset sequencer signals
                output ddr_inst1_RSTN,
                output ddr_inst1_CFG_SEQ_RST,
                output ddr_inst1_CFG_SEQ_START,
                
                
                //signals from pll
                input br0_pll_locked,
                input br1_pll_locked,
                input tb_clk_LOCKED,
                input axi_clk_LOCKED,
                
                
                output reg led,
                output ddr_start,    //led to show when to start operation
                output TX_PIN

                          );

wire tb_clk;
assign tb_clk = axi_clk;

reg axi_start_reg;


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
  
  //axi signals
  wire r_enable;  //axi gives read enable signal to the async fifo

  //ddr signals
    wire	[0:0]w_check_rstn;
    wire	[0:0]w_pll_rstni;
    wire	[3:0]w_axi0_states;
    wire	[3:0]w_axi1_states;
    
    
    //axi receiving buffer_full
    wire receiving_full;
    wire receiving_byte_count;
    
    
    //receive sync fifo signals
    wire receive_sync_enable;
    wire receive_sync_r_enable;
    
    wire [TB_WORD_WIDTH-1:0]receive_sync_out;
    wire receive_sync_full;
    wire receive_sync_empty; 
    
    assign receive_sync_enable = (rvalid && !receive_sync_full) == 1'b1 ? 1 : 0;
    
    //depacker signals
    wire depacker_w_enable;
    wire [TB_DATA_WIDTH-1:0]depacker_out;
    wire check_byte_full;    
    wire uart_byte_empty;    
    
    //signals which are used between uart byte fifo and uart tx
    wire [TB_DATA_WIDTH-1 : 0]uart_byte_fifo_out;
    wire uart_tx_active;
    wire uart_tx_done;
    wire byte_enable;
    assign byte_enable = !uart_tx_active && uart_tx_done && !uart_byte_empty;
    wire byte_valid;
    assign byte_valid = byte_enable;

    

    wire ddr_rstn_seq, ddr_cfg_seq_rst, ddr_cfg_seq_start;

    assign ddr_inst1_RSTN = ddr_rstn_seq;
    assign ddr_inst1_CFG_SEQ_RST = ddr_cfg_seq_rst;
    assign ddr_inst1_CFG_SEQ_START = ddr_cfg_seq_start;

    assign br0_pll_rstn = w_pll_rstni[0];
    //assign br1_pll_rstn = pll_rstni;
    assign br1_pll_rstn = 1'b1;

    //wire pll_locked;
    //assign pll_locked = ddr_cfg_seq_start;
    wire axi_start;
    //assign pll_locked = br0_pll_locked & axi_clk_LOCKED;

    wire fail_0, done_0, fail_1, done_1;
    assign pass = !(fail_0 | fail_1);
    assign done = done_0 & done_1;
    
    reg [34:0] count = 0;
   // reg led_value = 0;
   
    
    always@(posedge axi_clk or negedge check_rstn) begin
        if(!check_rstn) begin
            count <= 'b0;
            led <= 'b0;
        end
        else begin
            if(count > 35'd12500000) begin
                led <= ~led;
                count <= 'b0;
               // led_value <= ~led_value;
            end
            else begin
                count <= count + 1;
            end
        end
    end
    
  rx RX_DUT ( .i_Clock(axi_clk),
                                                                                            .i_Rx_Serial(tb_rx),
                                                                                            .o_Rx_Byte(rx_result),
                                                                                            .o_Rx_DV(rx_done));
                                                                                            
     // assign led = (rx_done) ? 1'b1 : 1'b0;
  
  sync_fifo #(.DATA_WIDTH(TB_DATA_WIDTH),.DEPTH(TB_DEPTH)) SYNC_FIFO_DUT (.clk(axi_clk),
                                                                          .rst(check_rstn),
                                                                          .r_en(packer_ren),
                                                                          .w_en(tb_wen),
                                                                          .data_in(rx_result),
                                                                          .data_out(sync_out),
                                                                          .full(sync_full),
                                                                          .empty(sync_empty));
  
  packer #(.DATA_WIDTH(TB_DATA_WIDTH),.WORD_WIDTH(TB_WORD_WIDTH)) PACKER_DUT (.data_in(sync_out),
                                                                              .rst(check_rstn),
                                                                              .clk(axi_clk),
                                                                              .check_empty(sync_empty),
                                                                              .word_fifo_full(word_full),
                                                                              .data_out(word_out),
                                                                              .packed_done(word_packed_done),
                                                                              .read_enable(packer_ren));

  async_top #(.DEPTH(TB_DEPTH),.DATA_WIDTH(TB_WORD_WIDTH)) ASYNC_DUT (  .wclk(axi_clk),
                                                                        .wrst(check_rstn),
                                                                        .rclk(axi_clk),
                                                                        .rrst(check_rstn),
                                                                        .w_en(word_packed_done),
                                                                        .r_en(r_enable),
                                                                        .data_in(word_out),
                                                                        .data_out(async_out),
                                                                        .full(word_full),
                                                                        .empty(async_empty));

  axi AXI_DUT(.axi_clk(axi_clk),
              .rstn(check_rstn),
              .start(axi_start_reg),
              .data_in(async_out),
              .check_empty(async_empty),
              .read_enable(r_enable),
              .aid(aid),
              .aaddr(aaddr),
              .alen(alen),
              .asize(asize),
              .aburst(aburst),
              .alock(alock),
              .avalid(avalid),
              .aready(aready),
              .atype(atype),
              .wid(wid),
              .wdata(wdata),
              .wstrb(wstrb),
              .wlast(wlast),
              .wvalid(wvalid),
              .wready(wready),
              .rid(rid),
              .rdata(rdata),
              .rlast(rlast),
              .rvalid(rvalid),
              .rready(rready),
              .rresp(rresp),
              .bid(bid),
              .bvalid(bvalid),
              .bready(bready));

ddr_reset_sequencer ddr_reset_sequencer_inst (
          .ddr_rstn_i		(ddr_rstn),
          .clk		(axi_clk),
          .ddr_rstn		(ddr_rstn_seq),
          .ddr_cfg_seq_rst	(ddr_cfg_seq_rst),
          .ddr_cfg_seq_start	(ddr_cfg_seq_start),
          .ddr_init_done(axi_start)
);
                                                                        
  sync_fifo #(.DATA_WIDTH(TB_WORD_WIDTH),.DEPTH(TB_DEPTH*5)) RECEIVE_SYNC_FIFO_DUT (.clk(axi_clk),
                                                                          .rst(check_rstn),
                                                                          .r_en(receive_sync_r_enable),
                                                                          .w_en(receive_sync_enable),
                                                                          .data_in(rdata),
                                                                          .data_out(receive_sync_out),
                                                                          .full(receive_sync_full),
                                                                          .empty(receive_sync_empty));
                                                                          
   depacker #(.WORD_WIDTH(TB_WORD_WIDTH)) DEPACKER_DUT(.clk(axi_clk),
                                                       .rst(check_rstn),
                                                       .data_in(receive_sync_out),
                                                       .check_empty(receive_sync_empty),
                                                       .byte_full(check_byte_full),
                                                       .read_enable(receive_sync_r_enable),
                                                       .data_out(depacker_out),
                                                       .write_enable(depacker_w_enable));


  sync_fifo #(.DATA_WIDTH(TB_DATA_WIDTH),.DEPTH(TB_DEPTH*8)) UART_BYTE_FIFO(.clk(axi_clk),
                                                                            .rst(check_rstn),
                                                                            .r_en(byte_enable),
                                                                            .w_en(depacker_w_enable),
                                                                            .data_in(depacker_out),
                                                                            .data_out(uart_byte_fifo_out),
                                                                            .full(check_byte_full),
                                                                            .empty(uart_byte_empty));
                                                                            
              
  uart_tx UART_TX_DUT(.i_Clock(axi_clk),
           .i_Tx_DV(byte_valid),
           .i_Tx_Byte(uart_byte_fifo_out),
           .o_Tx_Active(uart_tx_active),
           .o_Tx_Serial( ),
           .o_Tx_Done(uart_tx_done));
                             

assign ddr_start = axi_start;
assign axi_start_reg = word_packed_done;

endmodule