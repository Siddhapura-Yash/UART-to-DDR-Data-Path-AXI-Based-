`include "top.v"

module tb;
  
  parameter TB_DATA_WIDTH = 8;
  parameter TB_CLK_FREQ = 100_000_000;
  parameter TB_BAUD_RATE = 115200;
  parameter TB_DEPTH = 1024;
  
  reg clk;
  reg rx = 1;
  reg r_en;
  wire [TB_DATA_WIDTH - 1:0]data_out;
  wire done;
  integer j;
  
  //internal signals 
  wire [7:0]data;
  
  top #(.TB_DATA_WIDTH(TB_DATA_WIDTH),.TB_CLK_FREQ(TB_CLK_FREQ),.TB_BAUD_RATE(TB_BAUD_RATE),.TB_DEPTH(TB_DEPTH)) DUT(clk,rx,r_en);
  
  localparam integer T = TB_CLK_FREQ / TB_BAUD_RATE;
  
  initial begin
    clk = 0;
  end
  
  always #5 clk = ~clk;
  
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

    //first 128-bits 
        //another byte
    send_uart_byte(8'hA0); //F1
    #(T*20*10);
    //another byte
    send_uart_byte(8'hA1); //F2
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hA2); //F3
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hA3); //F4
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hA4); //F5
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hA5); //F6
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hA6); //F7
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hA7); //F8
    #(T*20*10);
        //another byte
    send_uart_byte(8'hA8); //F9
    #(T*20*10);
    //another byte
    send_uart_byte(8'hA9); //F10
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hAA); //F11
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hAB); //F12
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hAC); //F13
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hAD); //F14
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hAE); //F15
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hAF); //F16
    #(T*20*10);


        //another byte
    send_uart_byte(8'hB0); //F1
    #(T*20*10);
    //another byte
    send_uart_byte(8'hB1); //F2
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hAB); //F3
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hB3); //F4
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hB4); //F5
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hB5); //F6
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hB6); //F7
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hB7); //F8
    #(T*20*10);
        //another byte
    send_uart_byte(8'hB8); //F9
    #(T*20*10);
    //another byte
    send_uart_byte(8'hB9); //F10
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hBA); //F11
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hBB); //F12
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hBC); //F13
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hBD); //F14
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hBE); //F15
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hBF); //F16
    #(T*20*10);

      //another 128-bits 
      //another byte
    send_uart_byte(8'hC0); //F1
    #(T*20*10);
    //another byte
    send_uart_byte(8'hC1); //F2
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hC2); //F3
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hC3); //F4
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hC4); //F5
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hC5); //F6
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hC6); //F7
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hC7); //F8
    #(T*20*10);
        //another byte
    send_uart_byte(8'hC8); //F9
    #(T*20*10);
    //another byte
    send_uart_byte(8'hC9); //F10
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hCA); //F11
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hCB); //F12
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hCC); //F13
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hCD); //F14
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hCE); //F15
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hCF); //F16
    #(T*20*10);


   //another byte
    send_uart_byte(8'hF0); //F1
    #(T*20*10);
    //another byte
    send_uart_byte(8'hF1); //F2
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hF2); //F3
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hF3); //F4
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hF4); //F5
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hF5); //F6
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hF6); //F7
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hF7); //F8
    #(T*20*10);
        //another byte
    send_uart_byte(8'hF8); //F9
    #(T*20*10);
    //another byte
    send_uart_byte(8'hF9); //F10
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hFA); //F11
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hFB); //F12
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hFC); //F13
    #(T*20*10);   
    //another byte
    send_uart_byte(8'hFD); //F14
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hFE); //F15
    #(T*20*10);    
    //another byte
    send_uart_byte(8'hFF); //F16
    #(T*20*10);

    for(j = 0;j< 50;j=j+1) begin
        $display("Reading byte[%0d] %0H",j,DUT.SYNC_FIFO_DUT.mem[j]);
        #(T*20*10);
    end
    // $display("word[1] = %0h",)
    $finish;
  end

endmodule