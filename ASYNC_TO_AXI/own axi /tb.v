// --------------------------------------------working properly---------------------------------------
`timescale 1ns/1ps

`include "top.v"

module tb;
  
  parameter TB_DATA_WIDTH = 8;
  parameter TB_CLK_FREQ = 100_000_000;
  parameter TB_BAUD_RATE = 115200;
  parameter TB_DEPTH = 1024;

  localparam real HALF_PERIOD_NS = 1e9 / (2 * TB_CLK_FREQ);

  reg clk;
  reg rst;
  reg read_clk_async;
  reg rx = 1;
  reg r_en = 0;
  wire [TB_DATA_WIDTH - 1:0]data_out;
  wire done;
  integer j = 0;
  integer k;
  integer k_data = 8'hA0;
  
  //internal signals 
  wire [7:0]data;
  
  top #(.TB_DATA_WIDTH(TB_DATA_WIDTH),.TB_CLK_FREQ(TB_CLK_FREQ),.TB_BAUD_RATE(TB_BAUD_RATE),.TB_DEPTH(TB_DEPTH)) DUT(clk,rst,rx,r_en,read_clk_async);
  
  localparam integer T = TB_CLK_FREQ / TB_BAUD_RATE;
  
  initial begin
    clk = 0;
    read_clk_async = 0;
  end
  
  // always #10 clk = ~clk;\
integer c = 0;
initial clk = 0;

  always #1 begin
    c = c + 1;
    if (c == HALF_PERIOD_NS) begin
      clk = ~clk;
      c = 0;
    end
  end

  always #3 read_clk_async = ~read_clk_async;
  
  task send_uart_byte(input [TB_DATA_WIDTH - 1:0]data);
    integer i;
    begin
      rx <= 0;	//start bit
      #(T*10);
      
      for(i=0;i<TB_DATA_WIDTH;i=i+1) begin
        rx <= data[i];
        #(T*10);
      end
      
      rx <= 1;
      #(T*10);
      rx <= 1;
      #(T*10);
    end
  endtask
      
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb);
    
    #(T*20*10);
    $display("Sending first byte");
    
  //   send_uart_byte(8'b10101010); //AA
  //   r_en = 1;
	// // Wait for done
  //   #(T*20*10);
  //   r_en = 0;

	// // another byte
  //   send_uart_byte(8'b01010101); //55
  //   r_en = 1;
  //   #(T*20*10);
  //   r_en = 0;
        
	// //another byte
  //   send_uart_byte(8'b00110101); //35
  //   #(T*20*10);

  //   //another byte
  //   send_uart_byte(8'h); //F0
  //   #(T*20*10);


    repeat(5) @(posedge clk);  rst <= 1'b0;
    repeat(10) @(posedge clk);  rst <= 1'b1;

    //first 128-bits 
    //sending data through loopo
    // hA0
    for(k = 0; k<16; k = k + 1) begin
      send_uart_byte(k_data);
      k_data = k_data + 1;
      #(T*20*10);
    end

    // B0
     for(k = 0; k<16; k = k + 1) begin
      send_uart_byte(k_data);
      k_data = k_data + 1;
      #(T*20*10);
    end

    //C0
     for(k = 0; k<16; k = k + 1) begin
      send_uart_byte(k_data);
      k_data = k_data + 1;
      #(T*20*10);
    end

    // D0
     for(k = 0; k<16; k = k + 1) begin
      send_uart_byte(k_data);
      k_data = k_data + 1;
      #(T*20*10);
    end

    // E0
     for(k = 0; k<16; k = k + 1) begin
      send_uart_byte(k_data);
      k_data = k_data + 1;
      #(T*20*10);
    end

    // F0
     for(k = 0; k<16; k = k + 1) begin
      send_uart_byte(k_data);
      k_data = k_data + 1;
      #(T*20*10);
    end


    //long delay before reading
    #(T*200*10);

    r_en = 1;
    #(T*200*10);
    r_en = 0;

    r_en = 1;
    #(T*200*10);
    r_en = 0;

    r_en = 1;
    #(T*20*10);
    r_en = 0;

    for(j = 0;j< 5;j=j+1) begin
        $display("reading byte [%0d] %0H",j,DUT.ASYNC_DUT.mem.mem[0]);
        #(T*20*10);
    end

    for(j = 0;j< 96;j=j+1) begin
        $display("Reading byte[%0d] %0H",j,DUT.SYNC_FIFO_DUT.mem[j]);
        #(T*20*10);
    end
    // $display("word[1] = %0h",)
    $finish;
  end

endmodule