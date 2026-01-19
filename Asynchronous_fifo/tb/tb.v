`include "top.v"

module tb;
  
  parameter TB_DATA_WIDTH = 8;
  parameter TB_DEPTH = 8;
  
  reg wclk,rclk;
  reg wrst,rrst;
  reg w_en,r_en;
  reg [TB_DATA_WIDTH - 1 : 0]data_in;
  wire [TB_DATA_WIDTH - 1 : 0]data_out;
  wire full,empty;
  
  top #(.DEPTH(TB_DEPTH),.DATA_WIDTH(TB_DATA_WIDTH)) DUT(.wclk(wclk),.wrst(wrst),.rclk(rclk),.rrst(rrst),.w_en(w_en),.r_en(r_en),.data_in(data_in),.data_out(data_out),.full(full),.empty(empty));
  
  initial begin
    rclk = 0;
    wclk = 0;
    rrst = 1;
    wrst = 1;
  end
  
  always #10 rclk = ~rclk;
  always #35 wclk = ~wclk;
  
initial begin
  wrst = 0; rrst = 0;
  w_en = 0; r_en = 0;
  data_in = 0;

// Async FIFO has a pipeline of flip-flops:
// binary ptr → gray ptr → sync FF1 → sync FF2 → flag logic
// So reset must be held for multiple clock edges to clear all stages.
// If reset is released in only one cycle, some FFs still keep old/unknown values → FULL/EMPTY become wrong.
  repeat(5) @(posedge wclk); wrst = 1;
  repeat(5) @(posedge rclk); rrst = 1;

  // WRITE
  repeat(9) begin
    @(posedge wclk);
    if(!full) begin
      w_en <= 1;
      data_in <= $urandom;
    end
  end
  w_en <= 0;

  // READ
  repeat(9) begin
    @(posedge rclk);
    if(!empty)
      r_en <= 1;
  end
  r_en <= 0;
  /////////////////////////Second iteration//////////////////////////
  //write
  repeat(10) begin
    @(posedge wclk);
    if(!full) begin
      w_en <= 1;
      data_in <= $urandom;
    end
  end
  w_en <= 0;
  
      // READ
  repeat(10) begin
    @(posedge rclk);
    if(!empty)
      r_en <= 1;
  end
  r_en <= 0;

  #1000 $finish;
end
    
  initial begin
    $monitor("w_en = %b | r_en = %b | full = %b | data_in = %d",w_en,r_en,full,data_in);
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
  end
  
endmodule
