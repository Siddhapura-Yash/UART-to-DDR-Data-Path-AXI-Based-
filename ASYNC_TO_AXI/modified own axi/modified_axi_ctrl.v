// we are using shared address channel so we are supposed to do only write or read at a time

// i have not implemeted any kind of start logic "maybe it's necessary"





module axi(

    //global signals
    input axi_clk,
    input rst,

    //address channels signals we willl provide valurs exteranlly
    input TRIGGER,  //start signal

    input [255:0] data_in,      //data will come from fifo
    input check_empty,          //empty signal from async fifo
    input [6:0]w_count;         //how many no of transaction u want to perfomr in write operation
    output read_enable,         //axi send read enable to the async fifo


//write ADDRESS channel signals will be used for read ADDRESS channel also as it's shared channel
output  reg [7:0]	DDR_AID_0,		//transaction id
output  reg [31:0]	DDR_AADDR_0,	//main address send by master
output  reg [7:0]	DDR_ALEN_0,		//burst length exact number of transfers(beats)
output  reg [2:0]	DDR_ASIZE_0,	//how wide each beat
output  reg [1:0]	DDR_ABURST_0,	//burst type (i.e fixed,wrap.....)
output  reg [1:0]	DDR_ALOCK_0,	//00 for our case
output 	reg		    DDR_AVALID_0,	//valid signal master to slave 
input 		      	DDR_AREADY_0,	//slave responds i'm ready to acccept addresss
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
output  reg		DDR_RREADY_0,		//master ready to accepet read data
input   [1:0] 		DDR_RRESP_0,	//read response 
									//00 → OKAY
									//01 → EXOKAY
									//10 → SLVERR
									//11 → DECERR

//write resnose channel signals 
//here slave confirms write completion
//write is not complete untill BVALID
input   [7:0] 		DDR_BID_0,	//write response id
input 			DDR_BVALID_0,	//Slave → Master high means write response is valid
output  reg		DDR_BREADY_0,	//Master → Slave high means master ready to accept response 


//state and control signals
// output  	[3:0]   o_states,		//curent fsm state for debbugging
// output              o_out_trig,		//goes high when event start (pattern start .....)


//generally it would be from empty from async word fifo
input		i_pause,					//temporarily pause execution (freeze) 


output	reg	o_compare_error	//goes high when data is mismatched
);

// assign read_enable = !check_empty && DDR_WVALID_0;
assign read_enable = (!check_empty) && DDR_WREADY_0 && DDR_WVALID_0;

parameter START_ADDR = 32'h00000000;
parameter STOP_ADDR = 32'h00100000;

localparam 	ASIZE = 3'b101;		//how many bytes per data beat
								// we used 101=5 | 2^5 = 32
localparam ALEN = 3'b100;


//FSM
localparam      IDLE            = 4'b0000;
localparam  	WRITE_ADDR      = 4'b0001;		//sedning address to DDR

localparam  	PRE_WRITE       = 4'b0010;		//prepeate data and counter
localparam  	WRITE           = 4'b0011;		//send data beats
localparam  	POST_WRITE      = 4'b0100;		//waiting for write reponse BVALID

localparam  	READ_ADDR       = 4'b0101;		//send read address
localparam  	PRE_READ        = 4'b0110;		//start accepting read data
localparam  	POST_READ       = 4'b1000;		//finishing read
localparam  	COMPARE_READ    = 4'b1001;		//check read data vs expected

reg [3:0]   r_states;       //holds state

reg     [5:0]read_count;    //used for store data into internal fifo kind of things so we can compare later
reg		[255:0]r_rd_buff[0:63];		//data from read fifo will be used to compare expected vs actual

reg [5:0]write_count = 0;   //used for writing 

reg [255:0]previous_data = 0;   //will be used for comparison and enable while sending data to the DDR

reg diff_data;
// assign diff_data = ~(previous_data && data_in);    //will be one if data is diffrent

reg w_data_enable;  //will be used to confirm no repeattion while sending data and data from aysnc fifo is newer data

// assign w_data_enable = 



//FSM logic
always@(posedge axi_clk or negedge rst) begin
if(!rst) begin
        DDR_AID_0       <=  8'b0;
        DDR_AADDR_0     <= START_ADDR;
        DDR_ALEN_0      <=  8'b0;
        DDR_ASIZE_0     <=  3'b0;
        DDR_ABURST_0    <=  2'b0;
        DDR_ALOCK_0     <=  2'b0;
        DDR_AVALID_0    <=  1'b0;
        DDR_ATYPE_0     <=  1'b0;
        DDR_WID_0       <=  8'b0;
        DDR_WDATA_0     <=  256'b0;
        DDR_WSTRB_0     <= 32'hFFFFFFFF;
		DDR_WLAST_0		<=	1'b0;
		DDR_WVALID_0	<=	1'b0;
        DDR_RREADY_0    <=  1'b0;
        DDR_BREADY_0    <=  1'b0;
        r_states        <=  IDLE;
        o_Start         <=  1'b0;
		o_total_len		<=	16'b0;
		o_loop_n		<=	33'b0;
		r_state_WR_RD0	<=	1'b0;
		r_state_WR_RD1	<=	1'b0;
        read_count      <=  6'b0;
        write_count     <=  w_count;
end
else begin
    case(r_states)

    IDLE : begin
    		DDR_ALOCK_0     <=2'b0;                                
			DDR_WID_0       <=8'b0;
			DDR_WDATA_0     <=256'b0;
			DDR_WSTRB_0     <=32'hFFFFFFFF;		//out of 4 bytes which byte is valid if all the line contains data then all FF..
			DDR_WVALID_0    <=1'b0;
			DDR_RREADY_0    <=1'b0;
			DDR_BREADY_0    <=1'b0;		       
            if(TRIGGER && !i_pause) begin
                DDR_AVALID_0    <= 1'b1;
                DDR_AADDR_0     <=START_ADDR;
                DDR_ALEN_0      <=ALEN;
                DDR_ASIZE_0     <=ASIZE;
                DDR_ABURST_0    <=2'b01;	//increment type burst					
                DDR_ATYPE_0     <=1'b1;     //cureently we are giving one means writing to DDR later we will change
                r_states        <=WRITE_ADDR;		
            end		
            else begin
                DDR_AADDR_0     <=32'b0;
				DDR_ALEN_0      <=8'b0;
				DDR_ASIZE_0     <=3'b0;                                        
				DDR_ABURST_0    <=2'b0;
				DDR_AVALID_0    <=1'b0;     
				DDR_ATYPE_0     <=1'b0;           
				r_states 		<= IDLE;
            end
    end

    WRITE_ADDR : begin
        if(DDR_AREADY_0) begin  //means slave is ready to accept address
            DDR_AVALID_0    <=  1'b0;   //we are saying now stop to send address slave already got 
                if(DDR_ATYPE_0 == 1'b1) begin   //means master is writing to DDR
                    // DDR_AVALID_0    <=1'b1;
                    DDR_BREADY_0    <=1'b1;         //master is ready to accept response from slave	
                    //should be in write state otherwise it will send data on write addr state
                    DDR_WVALID_0    <=1'b1;         //whatever data we are sending is valid	
                   
                    DDR_WDATA_0     <= data_in;
                        
                        if(DDR_WREADY_0) begin      //slave is ready to accept data

                        write_count <= write_count - 1'b1;  //one data beat is written

                            if(write_count <= 0) begin     //kind of condition which checks if all the data burst is send suuccessfully or not if yes then we have to go for response otherise send data untill all the burst complete
                                r_states <= POST_WRITE; //we send all the burst now take response 
                                DDR_WLAST_0 <= 1'b1;
                                write_count <= 0;
                            end
                            else begin      
                                r_states <= WRITE;
                                DDR_WLAST_0 <= 1'b0;
                            end 
                        end
                        else begin      //if DDR is not ready for data then stay here and wait 
                                r_states <= WRITE;
                        end
                end

                else if(DDR_ATYPE_0 == 1'b0)begin  //means we are reading from DDR
                	DDR_WDATA_0     <='b0;  //no write data
                    DDR_RREADY_0    <=1'b1; // ready to accept read data

                    if(DDR_RVALID_0)begin   //when read data is valid go and read
                        r_rd_buff[read_count] <= DDR_RDATA_0;
                        read_count <= read_count + 1;           //increment after every read opeartion so we can store one by one data 
                    end

                    r_states <= PRE_READ;   //preapre for next read or check data
                    
                    end
     
                    else begin      //stuck in the write addr state if we none of the operation need to perfomr
                        DDR_AVALID_0    <=1'b1;
						DDR_WVALID_0    <=1'b0;
						r_states        <=WRITE_ADDR;
                    end
    end
    end

    WRITE : begin   //master is writing
    //if data stored more than once then use this condition to prevent duplication of data
      diff_data <= (previous_data != data_in);
      previous_data <= data_in;   //stores current data for comparison
            // if(DDR_WREADY_0 && diff_data) begin  //slave is ready to accept data from master
            if(DDR_WREADY_0) begin
                write_count <= write_count - 1'b1;
                DDR_WDATA_0 <= data_in;

                if(write_count <= 0) begin  //if we've send all the number of data then go for response
                    DDR_WLAST_0 <= 1'b1;
                    r_states <= POST_WRITE;
                    write_count <= 0;
                end
                else begin                  //we are still sending data 
                    DDR_WLAST_0 <= 1'b0;
                    r_states <= WRITE;
                end
            end
            else begin
                    write_count <= write_count;
            end
    end

    POST_WRITE : begin  //wait to receive response after writing data
        if(DDR_WREADY_0) begin  //slave has accepted write data
            DDR_WVALID_0 <= 1'b0;
            DDR_WLAST_0 <= 1'b0;
        end
        else    begin
            DDR_WVALID_0 <= DDR_WVALID_0;
            DDR_WLAST_0  <= DDR_WLAST_0;
        end

        if(DDR_BVALID_0) begin  //write response from slave
        DDR_BREADY_0 <= 1'b0;
        r_states <= IDLE;
        end
        else begin
            DDR_BREADY_0 <= 1'b1;
            r_states <= POST_WRITE;
        end
    end

    PRE_READ : begin
        if(DDR_RVALID_0) begin  //data on RDATA is valid
            r_rd_buff[read_count] <= DDR_RDATA_0;
            read_count <= read_count + 1;    

                if(DDR_RLAST_0) begin
                    DDR_RREADY_0 <= 1'b0;
                    r_states <= IDLE;
                end
                else begin
                        DDR_RREADY_0 <= 1'b1;
                        r_states <= PRE_READ;
                end
        end
        // else begin

        // end
    end
    endcase

end
end

endmodule
