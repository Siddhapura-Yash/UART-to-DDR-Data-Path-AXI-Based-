module axi_ctrl(
//gloval signals
input   axi_clk,
input   rstn,

//address channels signals we'll provide signals
input   [511:0]     INADDR,			//external address feeded 
input               TRIGGER,		//start signal 
input	[31:0]	    LOOP_N,			//counter for loop
input   [3:0]       PATTERN_NUMBER,	
input   [15:0]      IN_PATTERN,		//operation type 0 = read 1 = write 


//write ADDRESS channel signals
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

//==========================================================
//state and control signals
output  	[3:0]   o_states,		//curent fsm state for debbugging
output              o_out_trig,		//goes high when event start (pattern start .....)

// input 		[255:0]	i_pattern_len,		//input pattern length 
// output reg 	[6:0]   o_pattern_cnt,		//pattern counter (index of current pattern)
// output         		o_pattern_done,		//shows pattern completes
output reg 			o_Start,			//internal start flag
output reg 	[63:0] 	o_time_counter,		//timer counter used to how long execution took for future calculation 
output reg 	[7:0] 	o_write_cnt,		//counts number of writes operations remaining 
output reg 	[63:0] 	o_total_len,		//Counts total amount of data transferred.
output reg	[32:0]	o_loop_n,			//how many times patten looped
// input 		[127:0]	i_lfsr_seed,		//starting random pattern
// output		[127:0]	r_lfsr_1P,			//current LFSR output
input		i_pause,					//temporarily pause execution (freeze) 

output	reg	o_compare_error	//goes high when data is mismatched detected

);
parameter START_ADDR = 32'h00000000; 
parameter STOP_ADDR = 32'h00100000;

localparam 	ASIZE = 3'b101;		//how many bytes per data beat
								// we used 101=5 | 2^5 = 32

localparam      IDLE            = 4'b0000;
localparam  	WRITE_ADDR      = 4'b0001;		//sedning address to DDR

localparam  	PRE_WRITE       = 4'b0010;		//prepeate data and counter
localparam  	WRITE           = 4'b0011;		//send data beats
localparam  	POST_WRITE      = 4'b0100;		//waiting for write reponse BVALID

localparam  	READ_ADDR       = 4'b0101;		//send read address
localparam  	PRE_READ        = 4'b0110;		//start accepting read data
localparam  	POST_READ       = 4'b1000;		//finishing read
localparam  	COMPARE_READ    = 4'b1001;		//check read data vs expected

reg [3:0]   r_states;			//cureent fsm
// reg         r_pattern_done;		
reg 		r_trig_state0;		// both used to detect trigger edge 
reg 		r_trig_state1;

// reg		[127:0]r_lfsr_1P;
// reg		[127:0]r_lfsr_2P;

// reg 	r_state_WR_RD0;
// reg 	r_state_WR_RD1;

reg		[255:0]r_rd_buff;		//data from read fifo will be used to compare expected vs actual

// wire 	w_fb_0P;

// we need this and have to enable during read operation to check if incoming data is right or not
// wire	[255:0]w_compare_buff;

// assign o_pattern_done  	= r_pattern_done;
assign o_states 		= r_states;
assign o_out_trig 		= ~r_trig_state1 & r_trig_state0;

//below both lines are not useful in our case
// assign w_fb_0P = r_lfsr_1P[98] ^~ r_lfsr_1P[100] ^~ r_lfsr_1P[125] ^~ r_lfsr_1P[127];	//XNOR LSFR 128 

// we need this and have to enable during read operation to check if incoming data is right or not
// assign w_compare_buff = {r_lfsr_2P,r_lfsr_2P};


always@(posedge axi_clk or negedge rstn)
begin
    if(~rstn)
    begin
        r_trig_state0 <=1'b0;
        r_trig_state1 <=1'b0;        
    end
    else
    begin
        if(TRIGGER)		//checks start condition 
            r_trig_state0 <=1'b1;            
        else                            
            r_trig_state0 <=1'b0;
            r_trig_state1 <=1'b0;
        
        r_trig_state1 <=r_trig_state0;
    end
end

//used to count time take to complete operation for future calculation 
//we are not changing this right now
always @ (posedge axi_clk or negedge rstn)
begin
    if(~rstn)
    begin
        o_time_counter         <=  64'b0;
    end
    else
    begin
        if(o_Start)
		begin
			if(i_pause)
				o_time_counter	<=  o_time_counter;
			else
				o_time_counter 	<=  o_time_counter +1'b1;
		end
            
    end
end

//used to compare actual data with expected 
always @ (posedge axi_clk or negedge rstn)
begin
	if(~rstn)
	begin
		o_compare_error	<=1'b0;
	end
	else
	begin
		if(w_compare_buff!=r_rd_buff)
			o_compare_error	<=1'b1;
	end
end


//real fsm logic starts from here 
always @ (posedge axi_clk or negedge rstn)
begin
    if(~rstn)
    begin
        DDR_AID_0       <=  8'b0;
        DDR_AADDR_0     <= START_ADDR;
        DDR_ALEN_0      <=  8'b0;
        DDR_ASIZE_0     <=  3'b0;
        DDR_ABURST_0    <=  2'b0;
        DDR_ALOCK_0     <=  2'b0;
        DDR_AVALID_0    <=  1'b0;
        DDR_ATYPE_0     <=  1'b0;
        DDR_WID_0       <=  8'b0;
        DDR_WDATA_0     <=256'b0;
        DDR_WSTRB_0     <= 32'hFFFFFFFF;
		DDR_WLAST_0		<=	1'b0;
		DDR_WVALID_0	<=	1'b0;
        DDR_RREADY_0    <=  1'b0;
        DDR_BREADY_0    <=  1'b0;
        o_pattern_cnt   <=  5'b0;
        r_pattern_done  <=  1'b1;
		r_lfsr_1P		<= i_lfsr_seed;
		r_lfsr_2P		<= i_lfsr_seed;
		r_rd_buff		<= {i_lfsr_seed,i_lfsr_seed};
        r_states        <=  IDLE;
        o_Start         <=  1'b0;
		o_total_len		<=	16'b0;
		o_loop_n		<=	33'b0;
		r_state_WR_RD0	<=	1'b0;
		r_state_WR_RD1	<=	1'b0;
    end
    else
    begin		
		if(o_loop_n <= LOOP_N)
		begin

			if(o_pattern_cnt <= PATTERN_NUMBER)
			begin
				r_pattern_done<= 1'b0;                      				 

				if(r_states == IDLE)					//actual transaction starts from here
				begin                                                                
					DDR_ALOCK_0     <=2'b0;                                
					DDR_WID_0       <=8'b0;
					DDR_WDATA_0     <=256'b0;
					DDR_WSTRB_0     <=32'hFFFFFFFF;		//out of 4 bytes which byte is valid if all the line contains data then all FF..
					DDR_WVALID_0    <=1'b0;
					DDR_RREADY_0    <=1'b0;
					DDR_BREADY_0    <=1'b0;					

					// r_state_WR_RD0	<=IN_PATTERN[o_pattern_cnt];				

					if(r_state_WR_RD0 != IN_PATTERN[o_pattern_cnt])		
						r_lfsr_1P	<=i_lfsr_seed;
					else
						r_lfsr_1P	<=r_lfsr_1P;

					if(o_out_trig || o_Start)
					begin
						o_Start           <=1'b1;
						
						if(i_pause)
						begin
							r_states        <=IDLE;
							DDR_AVALID_0    <=1'b0;
						end
						else
						begin
							r_states        <=WRITE_ADDR;
							DDR_AVALID_0    <=1'b1;
						end
						
						DDR_AADDR_0     <=INADDR[(o_pattern_cnt*32)+:32];    
						// DDR_AADDR_0 <= START_ADDR;   		//we are trying to use our start address not predefined
						DDR_ALEN_0      <=i_pattern_len[(o_pattern_cnt*8)+:8];
						DDR_ASIZE_0     <=ASIZE;
						DDR_ABURST_0    <=2'b01;						
						DDR_ATYPE_0     <=IN_PATTERN[o_pattern_cnt];						
						o_write_cnt     <=i_pattern_len[(o_pattern_cnt*8)+:8];					                    
					end
					else
					begin
						DDR_AADDR_0     <=32'b0;
						DDR_ALEN_0      <=8'b0;
						DDR_ASIZE_0     <=3'b0;                                        
						DDR_ABURST_0    <=2'b0;
						DDR_AVALID_0    <=1'b0;     
						DDR_ATYPE_0     <=1'b0;           
						r_states 		<= IDLE;
					end
				end
				else if(r_states == WRITE_ADDR)
				begin
					if(DDR_AREADY_0)    
					begin
						DDR_AVALID_0    <=1'b0;                               
										
						if(DDR_ATYPE_0 == 1'b1)	//means master is writing
						begin						
							
							DDR_BREADY_0    <=1'b1;
							DDR_WVALID_0    <=1'b1;							
							
							r_lfsr_1P		<= {r_lfsr_1P[126:0], w_fb_0P};
							DDR_WDATA_0     <= {r_lfsr_1P,r_lfsr_1P};							

							if(DDR_WREADY_0)
							begin
								
								o_write_cnt	<=o_write_cnt-1'b1;

								if(o_write_cnt <= 1'b0)  
								begin                
									DDR_WLAST_0 <=1'b1;                        
									r_states    <=POST_WRITE;
								end
								else
								begin
									DDR_WLAST_0 <=1'b0;
									r_states    <=WRITE;
								end
							end
							else
							begin
								r_states      <=WRITE;
							end
						end
						else		//reading
						begin	

							DDR_WDATA_0     <=1'b0;
							DDR_RREADY_0    <=1'b1;

							if(DDR_RVALID_0)
							begin

								r_lfsr_1P		<= {r_lfsr_1P[126:0], w_fb_0P};
								r_lfsr_2P		<= r_lfsr_1P;

								r_rd_buff		<= DDR_RDATA_0;

							end

							r_states          <=PRE_READ;
						end
					end
					else
					begin
						DDR_AVALID_0    <=1'b1;
						DDR_WVALID_0    <=1'b0;
						r_states        <=WRITE_ADDR;
					end
				end
				else if(r_states == WRITE)	//sending actual data
				begin
					if(DDR_WREADY_0)
					begin
					
						o_write_cnt		<=o_write_cnt -1'b1;
						r_lfsr_1P		<= {r_lfsr_1P[126:0], w_fb_0P};
						DDR_WDATA_0     <={r_lfsr_1P,r_lfsr_1P};

						if(o_write_cnt <= 1'b0)  
						begin
							DDR_WLAST_0		<=1'b1;					
							r_states      	<=POST_WRITE;
						end
						else
						begin						
							DDR_WLAST_0 	<=1'b0;                					
							r_states      	<=WRITE;
						end  
					end
					else
					begin
						o_write_cnt		<=o_write_cnt;
					end
				end
				else if(r_states == POST_WRITE)	//wait for receive response after writing data
				begin
					
					if(DDR_WREADY_0)    //slave is ready to accept data
					begin
						DDR_WVALID_0    <= 1'b0;		//data is not valid on data bus
						DDR_WLAST_0     <= 1'b0;		
					end
					else
					begin
						DDR_WVALID_0    <= DDR_WVALID_0;
						DDR_WLAST_0     <= DDR_WLAST_0;
					end
					
				
					if(DDR_BVALID_0)   	
					begin			
						DDR_BREADY_0    <= 1'b0;
						o_pattern_cnt 	<= o_pattern_cnt +1'b1;
						r_states        <= IDLE;
						o_total_len		<= o_total_len+(DDR_ALEN_0+1'b1);
					end
					else
					begin			
						DDR_BREADY_0 	<= 1'b1;
						o_pattern_cnt 	<= o_pattern_cnt;
						r_states  		<= POST_WRITE;					
					end
				end
				else if(r_states == PRE_READ)
				begin				
					if(DDR_RVALID_0)       
					begin						
						
						r_lfsr_1P		<= {r_lfsr_1P[126:0], w_fb_0P};
						r_lfsr_2P		<= r_lfsr_1P;						

						r_rd_buff		<= DDR_RDATA_0;						

						if(DDR_RLAST_0)
						begin
							DDR_RREADY_0    <=1'b0;                    
							o_pattern_cnt 	<= o_pattern_cnt +1'b1;
							r_states        <= IDLE;
							o_total_len		<= o_total_len+(DDR_ALEN_0+1'b1);
						end
						else
						begin							
							DDR_RREADY_0    <=1'b1;
							r_states        <=PRE_READ;
						end
					end
				end				
			end
			else
			begin 
				o_pattern_cnt		<=7'b0;								
				o_loop_n			<=o_loop_n+1'b1;
			end
		end
		else
		begin
			r_lfsr_1P			<= i_lfsr_seed;
			r_pattern_done		<= 1'b1;
			o_Start				<= 1'b0;
		end
    end
end


endmodule // axi_ctrl
