module axi(
    //global signals
    input axi_clk,
    input rst,

    //address channels signals
    input TRIGGER,

    input [255:0] data_in,      //data will come from fifo
    input check_empty,          //empty signal from async fifo
    output read_enable,         //axi send read enable to the async fifo
    input [6:0]w_count,         //how many no of transaction u want to perform in write operation

    //write ADDRESS channel signals
    output  reg [7:0]	DDR_AID_0,		//transaction id
    output  reg [31:0]	DDR_AADDR_0,	//main address send by master
    output  reg [7:0]	DDR_ALEN_0,		//burst length exact number of transfers(beats)
    output  reg [2:0]	DDR_ASIZE_0,	//how wide each beat
    output  reg [1:0]	DDR_ABURST_0,	//burst type (i.e fixed,wrap.....)
    output  reg [1:0]	DDR_ALOCK_0,	//00 for our case
    output reg		    DDR_AVALID_0,	//valid signal master to slave 
    input 		      	DDR_AREADY_0,	//slave responds i'm ready to accept address
    output  reg	       	DDR_ATYPE_0,	//read or write 1 = write 0 = read

    //WRITE data channel signals
    output reg [7:0] 	DDR_WID_0,		//write transaction id
    output reg [255:0]	DDR_WDATA_0,	//actual write data
    output reg [31:0] 	DDR_WSTRB_0,	//write strobe
    output reg 		DDR_WLAST_0,		//last data beat of burst
    output reg 		DDR_WVALID_0,		//high means write data is valid
    input 			DDR_WREADY_0,		//slave says i'm ready to accept data

    //read data channel signals
    input   [7:0] 		DDR_RID_0,		//read trasaction id
    input   [255:0] 	DDR_RDATA_0,	//read data from ddr
    input			DDR_RLAST_0,		//last beat of read burst
    input			DDR_RVALID_0,		//high means read data is valid
    output  reg		DDR_RREADY_0,		//master ready to accept read data
    input   [1:0] 		DDR_RRESP_0,	//read response 
    
    //write response channel signals 
    input   [7:0] 		DDR_BID_0,	//write response id
    input 			DDR_BVALID_0,	//Slave → Master high means write response is valid
    output  reg		DDR_BREADY_0,	//Master → Slave high means master ready to accept response 

    //state and control signals
    input		i_pause,				//temporarily pause execution (freeze) 
    output	reg	o_compare_error	//goes high when data is mismatched 
);

// Read enable logic - read from async FIFO when it has data and AXI is ready to accept
assign read_enable = (!check_empty) && DDR_WREADY_0 && DDR_WVALID_0;

parameter START_ADDR = 32'h00000000;
parameter STOP_ADDR = 32'h00100000;

localparam ASIZE = 3'b101;		//32 bytes per beat (2^5 = 32)
localparam ALEN = 8'b00000011;  //4 beats per burst

//FSM states
localparam IDLE            = 4'b0000;
localparam WRITE_ADDR      = 4'b0001;	//sending address to DDR
localparam WRITE           = 4'b0011;	//send data beats
localparam POST_WRITE      = 4'b0100;	//waiting for write response BVALID
localparam READ_ADDR       = 4'b0101;	//send read address
localparam PRE_READ        = 4'b0110;	//start accepting read data
localparam POST_READ       = 4'b1000;	//finishing read
localparam COMPARE_READ    = 4'b1001;	//check read data vs expected

reg [3:0]   r_states;           //holds current state
reg [5:0]   read_count = 0;     //counter for read operations
reg [5:0]   write_count = 0;    //counter for write operations
reg [31:0]  current_addr;       //current write/read address
reg [255:0] previous_data = 0;  //store previous data for comparison
reg         data_changed;       //flag for data change detection

// Memory for storing read data (for verification)
reg [255:0] r_rd_buff[0:63];

always@(posedge axi_clk or negedge rst) begin
    if(!rst) begin
        // Initialize all AXI signals
        DDR_AID_0       <= 8'b0;
        DDR_AADDR_0     <= START_ADDR;
        DDR_ALEN_0      <= 8'b0;
        DDR_ASIZE_0     <= 3'b0;
        DDR_ABURST_0    <= 2'b0;
        DDR_ALOCK_0     <= 2'b0;
        DDR_AVALID_0    <= 1'b0;
        DDR_ATYPE_0     <= 1'b0;
        DDR_WID_0       <= 8'b0;
        DDR_WDATA_0     <= 256'b0;
        DDR_WSTRB_0     <= 32'hFFFFFFFF;
        DDR_WLAST_0     <= 1'b0;
        DDR_WVALID_0    <= 1'b0;
        DDR_RREADY_0    <= 1'b0;
        DDR_BREADY_0    <= 1'b0;
        r_states        <= IDLE;
        read_count      <= 6'b0;
        write_count     <= 6'b0;
        current_addr    <= START_ADDR;
        o_compare_error <= 1'b0;
    end
    else begin
        case(r_states)
        
        IDLE : begin
            DDR_AVALID_0    <= 1'b0;
            DDR_WVALID_0    <= 1'b0;
            DDR_RREADY_0    <= 1'b0;
            DDR_BREADY_0    <= 1'b0;
            read_count      <= 6'b0;
            o_compare_error <= 1'b0;
            
            // Wait for TRIGGER and no pause condition
            if(TRIGGER && !i_pause && !check_empty) begin
                DDR_AVALID_0    <= 1'b1;
                DDR_AADDR_0     <= current_addr;
                DDR_ALEN_0      <= ALEN;
                DDR_ASIZE_0     <= ASIZE;
                DDR_ABURST_0    <= 2'b01;  //increment type burst
                DDR_ATYPE_0     <= 1'b1;   //write to DDR
                DDR_AID_0       <= 8'b0;
                write_count     <= w_count;  //load write count from input
                r_states        <= WRITE_ADDR;
            end
        end
        
        WRITE_ADDR : begin
            if(DDR_AREADY_0) begin  //slave accepted address
                DDR_AVALID_0    <= 1'b0;   //stop sending address
                DDR_BREADY_0    <= 1'b1;   //ready to accept write response
                DDR_WVALID_0    <= 1'b1;   //write data is valid
                r_states        <= WRITE;
                write_count     <= write_count; //maintain count
            end
            else begin
                DDR_AVALID_0    <= 1'b1;  //keep valid until accepted
            end
        end
        
        WRITE : begin
            if(DDR_WREADY_0 && DDR_WVALID_0) begin  //slave accepted write data
                DDR_WDATA_0     <= data_in;  //assign new data
                previous_data   <= data_in;
                write_count     <= write_count - 1'b1;
                
                // Check if this is the last beat
                if(write_count == 6'b1) begin  //this is the last data beat
                    DDR_WLAST_0 <= 1'b1;
                    r_states    <= POST_WRITE;
                end
                else begin
                    DDR_WLAST_0 <= 1'b0;
                    r_states    <= WRITE;
                end
            end
            else begin
                r_states <= WRITE;  //wait for slave to be ready
            end
        end
        
        POST_WRITE : begin
            DDR_WVALID_0    <= 1'b0;
            DDR_WLAST_0     <= 1'b0;
            
            if(DDR_BVALID_0) begin  //write response received
                DDR_BREADY_0    <= 1'b0;
                current_addr    <= current_addr + 32'h00000020;  //increment address by 32 bytes
                
                if(current_addr >= STOP_ADDR - 32'h00000020) begin
                    r_states <= IDLE;  //done writing
                end
                else begin
                    r_states <= IDLE;  //return to IDLE for next transaction
                end
            end
            else begin
                DDR_BREADY_0 <= 1'b1;  //keep ready for response
                r_states     <= POST_WRITE;
            end
        end
        
        default : r_states <= IDLE;
        
        endcase
    end
end

endmodule
