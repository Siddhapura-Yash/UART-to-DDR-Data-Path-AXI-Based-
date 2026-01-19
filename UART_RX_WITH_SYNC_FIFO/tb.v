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
    
    send_uart_byte(8'b10101010); //AA
    r_en = 1;
	// Wait for done
    #(T*20*10);
    r_en = 0;

	// another byte
    send_uart_byte(8'b01010101); //55
    r_en = 1;
    #(T*20*10);
    r_en = 0;
        
	//another byte
    send_uart_byte(8'b00110101); //35
    #(T*20*10);

    //another byte
    send_uart_byte(8'b00001001); //09
    #(T*20*10);
    
    for(j = 0;j< 5;j=j+1) begin
        $display("Reading byte[%0d] %0H",j,DUT.SYNC_FIFO_DUT.mem[j]);
        #(T*20*10);
    end

    $finish;
  end
  
initial begin
  $monitor("At time %t, Data Out: %d, Done: %b",$time,data_out,done);
end

endmodule