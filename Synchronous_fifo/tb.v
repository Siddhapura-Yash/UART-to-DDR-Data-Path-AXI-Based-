// `define DATA_WIDTH 8
// `define DEPTH 8

`include "sync_fifo.v"

module tb;
  
  localparam DATA_WIDTH = 8;
  localparam DEPTH = 8;
  
  reg clk,rst,r_en,w_en;
  reg [DATA_WIDTH - 1 : 0]data_in;
  wire [DATA_WIDTH - 1 : 0]data_out;
  wire full;
  wire empty;
  
  sync_fifo #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH)) DUT (clk,rst,r_en,w_en,data_in,data_out,full,empty);
  
  initial clk = 0;
  always #5 clk = ~clk;
  
  initial begin
    #3 rst = 0;	w_en = 0;	r_en = 0;
    #5 rst = 1;
    //Writing data into fifo
    #10 data_in = 8'd32; w_en = 1; 
    #10 data_in = 8'd41; w_en = 1;
    #10 data_in = 8'd51; w_en = 1;
	#10 data_in = 8'd12; w_en = 1;	r_en = 1;	//simultaenously read & write
    #10 data_in = 8'd73; w_en = 0;	r_en = 0;
	#10 data_in = 8'd43; w_en = 1;
    #10 data_in = 8'd84; w_en = 1;
	#10 data_in = 8'd01; w_en = 1;
	#10 data_in = 8'd99; w_en = 1;
    #10;
    //reading from fifo
    #10 r_en = 1;	w_en = 0;
	#10 r_en = 1;
    #10 r_en = 1;
    #10 r_en = 1;
    #10 r_en = 1;
    #10 r_en = 1;
    #10 r_en = 1;
    #10 r_en = 1;
    #50;
    $display("Reading and Writing is completed");
    $finish;
  end
  
  initial begin
    $monitor("data_in = %d | w_en = %b | data_out = %d | r_en = %b | full = %b | empty = %b",data_in,w_en,data_out,r_en,full,empty);
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
  end
  
endmodule
