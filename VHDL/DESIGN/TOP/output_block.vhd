---------------------------------------------------------------------------------------------------------------
--
-- Title       : output_block
-- Design      : Lzrw3 compression core
-- Author      : Shahar Zuta & Netanel Yamin
-- Company     : Technion High Speed Digital Systems Lab
--
---------------------------------------------------------------------------------------------------------------
--
-- File        : VHDL\DESIGN\LZRW3_un_core\output_block\output_block.vhd
-- Generated   : 05.07.2013
--
---------------------------------------------------------------------------------------------------------------
--
-- Description :
--
--
--
--
--
---------------------------------------------------------------------------------------------------------------
--
-- Revision History : 	Revision Number		Date	     	 Description			               	 
--					             1.0				          10.07.2013	 creation 	        			
--
---------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all ;
 
  entity output_block is
    generic (
				reset_polarity_g	           :	std_logic 	:= '1';	                                              -- '0' - Active Low Reset, '1' Active High Reset.
				byte_size_g			              :	positive 	 := 8  ;          -- One byte				
				data_width_g                :	positive 	 := 8  ;          -- Width of data (8 bits holdes one literal)                  
      -- FIFO generics
        fifo_depth_g 			            : positive 	 := 4;	           -- Maximum elements in FIFO
		    fifo_log_depth_g			         : natural	   := 2;	           -- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
		    fifo_almost_full_g		        : positive	  := 3;   	        -- Rise almost full flag at this number of elements in FIFO
		    fifo_almost_empty_g	 	      : positive	  := 1;	           -- Rise almost empty flag at this number of elements in FIFO				
      -- SHORT FIFO generics
        short_fifo_depth_g 			      : positive 	 := 8;	           -- Maximum elements in FIFO
		    short_fifo_log_depth_g			   : natural	   := 3;	           -- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
		    short_fifo_almost_full_g		  : positive	  := 8;   	        -- Rise almost full flag at this number of elements in FIFO
		    short_fifo_almost_empty_g	 	: positive	  := 1;	           -- Rise almost empty flag at this number of elements in FIFO				     		    
      -- WISHBONE slave generics
--	addr_d_g				: positive := 3;		--Address Depth
			Add_width_g    			:   positive := 8;		--width of addr word in the WB
			len_d_g				                 :	positive   := 1 ;		         -- Length Depth
			type_d_g				                :	positive   := 1 ; 	         -- Type Depth		
      -- WISHBONE master generics
	      addr_bits_g			             	:	positive   := 8	;
	    -- block and client (TX PATH) hand-shake (frames header length = bytes of SOF, ADDR, TYPE, LEN, CRC, EOF )         
	      baudrate_g			               :	positive	  := 115200 ;	 	   -- UART baudrate [Hz]
	      clkrate_g		 	               :	positive	  := 125000000 ;	  -- Sys. clock [Hz]
	      databits_g			              	:	positive   := 8	;
	      parity_en_g                 :	natural	range 0 to 1 := 1 ;
	      tx_fifo_d_g                 : positive	  := 9             -- Maximum elements in TX PATH FIFO 
        	);
		port (
          clk			                   :	in std_logic ;	
          reset			                 :	in std_logic ;	  
          -- data provider side (compressor core)
          data_in                  : in std_logic_vector (byte_size_g -1 downto 0) ;	
          data_in_valid            :	in std_logic ;	 	
          lzrw3_done               :	in std_logic ;                                             -- lzrw3_done for one clock
          client_ready             :	out std_logic ;
          -- wishbone master BUS side
          ADR_O		       	          : out std_logic_vector (Add_width_g-1 downto 0); -- contains the addr word
          WM_DAT_O			              : out std_logic_vector (data_width_g-1 downto 0);            -- contains the data_in word
          WE_O			                  : out std_logic;                                             -- '1' for write, '0' for read
          STB_O			                 : out std_logic;                                             -- '1' for active bus operation, '0' for no bus operation
          CYC_O			                 : out std_logic;                                             -- '1' for bus transmition request, '0' for no bus transmition request
          TGA_O			                 : out std_logic_vector (type_d_g * data_width_g-1 downto 0); -- contains the type word
          TGD_O			                 : out std_logic_vector (len_d_g * data_width_g-1 downto 0);  -- contains the len word
          ACK_I			                 : in std_logic;                                              -- '1' when valid data is recieved from WS or for successfull write operation in WS
          WM_DAT_I		               : in std_logic_vector (data_width_g-1 downto 0);             -- data recieved from WS
	        STALL_I			               : in std_logic;                                              -- STALL - WS is not available for transaction 
	        ERR_I		                  : in std_logic;                              
          -- wishbone slave BUS side
          ADR_I                    : in std_logic_vector (Add_width_g-1 downto 0);	   -- contains the addr word
          DAT_I                    : in std_logic_vector (data_width_g-1 downto 0); 	               -- contains the data_in word
          WE_I                     : in std_logic;                     				                         -- '1' for write, '0' for read
          STB_I                    : in std_logic;                     				                         -- '1' for active bus operation, '0' for no bus operation
          CYC_I                    : in std_logic;                     				                         -- '1' for bus transmition request, '0' for no bus transmition request
          TGA_I                    : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	  -- contains the type word
          TGD_I                    : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	   -- contains the len word
          ACK_O                    : out std_logic;                      				                       -- '1' when valid data is transmited to MW or for successfull write operation 
          DAT_O                    : out std_logic_vector (data_width_g-1 downto 0);   	            -- data transmit to MW
	        STALL_O		                : out std_logic          	 	
        ); 
  end entity output_block;  
  
  architecture arc_output_block of output_block is		      
  
  
  -- COMPONENT AREA --
  
  
  COMPONENT general_fifo  
	generic(	 
		reset_polarity_g	: std_logic	:= '0';	 -- Reset Polarity
		width_g				      : positive	 := 8; 	  -- Width of data
		depth_g 			      : positive 	:= 9;	   -- Maximum elements in FIFO
		log_depth_g			   : natural	  := 4;	   -- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
		almost_full_g		  : positive	 := 8;   	-- Rise almost full flag at this number of elements in FIFO
		almost_empty_g	 	: positive	 := 1 	   -- Rise almost empty flag at this number of elements in FIFO
	     	);
	 port(
		 clk 		     : in 	std_logic;									                          -- Clock
		 rst 		     : in 	std_logic;                                   -- Reset
		 din 		     : in 	std_logic_vector (width_g-1 downto 0);       -- Input Data
		 wr_en 		   : in 	std_logic;                                   -- Write Enable
		 rd_en 	   	: in 	std_logic;                                   -- Read Enable (request for data)
		 flush		    : in	 std_logic;									                          -- Flush data
		 dout 	    	: out 	std_logic_vector (width_g-1 downto 0);	     -- Output Data
		 dout_valid	: out 	std_logic;                                  -- Output data is valid
		 afull  	   : out 	std_logic;                                  -- FIFO is almost full
		 full 		    : out 	std_logic;	                                 -- FIFO is full
		 aempty 	   : out 	std_logic;                                  -- FIFO is almost empty
		 empty 		   : out 	std_logic;                                  -- FIFO is empty
		 used 		    : out 	std_logic_vector (log_depth_g  downto 0) 	  -- Current number of elements is FIFO. Note the range. In case depth_g is 2^x, then the extra bit will be used
      );
  END COMPONENT;
  
  

  COMPONENT wishbone_master 
   generic (
		reset_activity_polarity_g  : std_logic :='1';      -- defines reset active polarity: '0' active low, '1' active high
		data_width_g               : natural := 8 ;        -- defines the width of the data lines of the system
		type_d_g			                :	positive := 1;		      -- Type Depth
--		addr_d_g				: positive := 3;		--Address Depth
		Add_width_g    			:   positive := 8;		--width of addr word in the WB
		len_d_g				                :	positive := 1;		      -- Length Depth
		addr_bits_g				            :	positive := 8	        -- Depth of data in RAM	(2^8 = 256 addresses)
           );
   port
   	   (	 
    sys_clk			     : in std_logic;                                              -- system clock
    sys_reset		    : in std_logic;                                              -- system reset   
	--control unit signals
	  wm_start		     : in std_logic;	                                             -- when '1' WM starts a transaction
	  wr				         : in std_logic;                                              -- determines if the WM will make a read('0') or write('1') transaction
	  type_in		     	: in std_logic_vector (type_d_g * data_width_g-1 downto 0);  -- type is the client which the data is directed to
    len_in			      : in std_logic_vector (len_d_g * data_width_g-1 downto 0);   -- length of the data (in words)
    addr_in			     : in std_logic_vector (Add_width_g-1 downto 0);  -- the address in the client that the information will be written to
	  ram_start_addr	: in std_logic_vector (addr_bits_g-1 downto 0);              -- start address for WM to read from RAM
    wm_end			      : out std_logic;                                             -- when '1' WM ended a transaction or reseted by watchdog ERR_I signal
	--RAM signals
	  ram_addr		     :	out std_logic_vector (addr_bits_g - 1 downto 0);           -- RAM Input address
	  ram_dout		     :	out std_logic_vector (data_width_g - 1 downto 0);	         -- RAM Input data
	  ram_dout_valid	:	out std_logic; 									                                   -- RAM Input data valid
	  ram_aout		     :	out std_logic_vector (addr_bits_g - 1 downto 0);           -- RAM Output address
	  ram_aout_valid	:	out std_logic;								                                    	-- RAM Output address is valid
	  ram_din			     :	in std_logic_vector (data_width_g - 1 downto 0);          	-- RAM Output data
	  ram_din_valid	 :	in std_logic; 									                                    -- RAM Output data valid
	--bus side signals
    ADR_O		       	: out std_logic_vector (Add_width_g-1 downto 0); -- contains the addr word
    DAT_O			       : out std_logic_vector (data_width_g-1 downto 0);            -- contains the data_in word
    WE_O			        : out std_logic;                                             -- '1' for write, '0' for read
    STB_O			       : out std_logic;                                             -- '1' for active bus operation, '0' for no bus operation
    CYC_O			       : out std_logic;                                             -- '1' for bus transmition request, '0' for no bus transmition request
    TGA_O			       : out std_logic_vector (type_d_g * data_width_g-1 downto 0); -- contains the type word
    TGD_O			       : out std_logic_vector (len_d_g * data_width_g-1 downto 0);  -- contains the len word
    ACK_I			       : in std_logic;                                              -- '1' when valid data is recieved from WS or for successfull write operation in WS
    DAT_I			       : in std_logic_vector (data_width_g-1 downto 0);             -- data recieved from WS
	  STALL_I			     : in std_logic;                                              -- STALL - WS is not available for transaction 
	  ERR_I		        : in std_logic                                               -- Watchdog interrupts, resets wishbone master
   	);
  END COMPONENT; 
  
  
  COMPONENT wishbone_slave
  generic (
		reset_activity_polarity_g  	: std_logic :='1';   -- defines reset active polarity: '0' active low, '1' active high
		data_width_g               	: natural   := 8;    -- defines the width of the data lines of the system    
--		addr_d_g				: positive := 3;		--Address Depth
		Add_width_g    			:   positive := 8;		--width of addr word in the WB
		len_d_g				                 :	positive  := 1;		  -- Length Depth
		type_d_g				                :	positive  := 1	 	  -- Type Depth    
		    );	   
   port (
     clk        : in std_logic;		                                                --system clock
     reset      : in std_logic;		                                                --system reset    
	 --bus side signals
     ADR_I          : in std_logic_vector (Add_width_g-1 downto 0);	   -- contains the addr word
     DAT_I          : in std_logic_vector (data_width_g-1 downto 0); 	               -- contains the data_in word
     WE_I           : in std_logic;                     				                         -- '1' for write, '0' for read
     STB_I          : in std_logic;                     				                         -- '1' for active bus operation, '0' for no bus operation
     CYC_I          : in std_logic;                     				                         -- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I          : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	  -- contains the type word
     TGD_I          : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	   -- contains the len word
     ACK_O          : out std_logic;                      				                       -- '1' when valid data is transmited to MW or for successfull write operation 
     DAT_O          : out std_logic_vector (data_width_g-1 downto 0);   	            -- data transmit to MW
	   STALL_O		      : out std_logic;                                                 -- STALL - WS is not available for transaction 
	 --register side signals
     typ			         : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);   -- Type
	   addr	          : out std_logic_vector (Add_width_g-1 downto 0);   -- the beginnig address in the client that the information will be written to
	   len		         	: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);    -- Length
	   wr_en			       : out std_logic;
	   ws_data	       : out std_logic_vector (data_width_g-1 downto 0);                -- data out to registers
	   ws_data_valid	 : out std_logic;	                                                -- data valid to registers
	   reg_data       : in std_logic_vector (data_width_g-1 downto 0); 	               -- data to be transmited to the WM
     reg_data_valid : in std_logic;                                                  -- data to be transmited to the WM validity
	   active_cycle	  : out std_logic;                                                 -- CYC_I outputed to user side
	   stall			       : in std_logic                                                   -- stall - suspend wishbone transaction
	     ); 
  END COMPONENT;  
  
 
   --FIFO in/out State Machines
   type fsm_in_states is (
					buffering_st,		     -- the fifo ready to receive bytes, also could transmit bytes
					transferring_st	    -- the fifo NOT ready to receive bytes, ready for transmit or transmit bytes ONLY
				); 
				
   type fsm_out_states is (
					idle_st,		             -- checking if there is bytes to send
					wm_request_st,	        -- sending request to TX PATH to send data
					send_data_st,          -- sending data
					wait_after_send_st     -- waiting till TX PATH should transfer all the last frame via UART
				); 
							
				 
  
  
  -----   C O N S T A N T S   A R E A  ----
  constant clk_div_factor_c	 : positive := clkrate_g / baudrate_g + 1 ;	    	-- Clock Divide factor + 1 for fraction round
  constant uart_frame_bits_c   : positive := 2 + databits_g + parity_en_g ;    -- start bit + data bits + parity + stop bit
  constant calculated_const_c  : positive := clk_div_factor_c * uart_frame_bits_c ; 
   -----  S I G N A L S   A R E A  ---
     -- counters
  signal requested_bytes    : integer range 256 downto 0 ;                 -- requested bytes to send in fifo
  signal wait_cycles        : integer range ( (256 + tx_fifo_d_g + Add_width_g + len_d_g + type_d_g + 4)* clk_div_factor_c * uart_frame_bits_c)  downto 0 ; -- in count: frame length + bytes already in fifo from previous sending = 1 ==>> (maximum frame size + TX-PATH FIFO maximum usage + frame header bytes (SOF + ADDR + TYPE + LEN + CRC + EOF)  + 1 for confident ) * clock divide factor 
  
     -- FIFO signals
  signal fifo_rd_en 	      	: std_logic;                                   -- Read Enable (request for data)
  signal fifo_dout 	       	:	std_logic_vector (byte_size_g-1 downto 0);   -- Output Data
  signal fifo_dout_valid	   :	std_logic;                                   -- Output data is valid
  signal fifo_full 		       : std_logic;	                                  -- FIFO is full
  signal fifo_empty 		      : std_logic;                                   -- FIFO is empty
  signal fifo_used 		       : std_logic_vector (fifo_log_depth_g  downto 0); 
      
     -- SHORT FIFO signals            
  signal short_fifo_rd_en 	      	: std_logic;                                   -- Read Enable (request for data)
  signal short_fifo_dout 	       	:	std_logic_vector (byte_size_g-1 downto 0);   -- Output Data
  signal short_fifo_dout_valid	   :	std_logic;                                   -- Output data is valid
  signal short_fifo_full 		       : std_logic;	                                  -- FIFO is full
   
      
    -- FSMs states signals
  signal fsm_in_state       : fsm_in_states ;    
  signal fsm_out_state      : fsm_out_states ;
  
    -- FSM STATES enable signals
  signal send_data_st_en    : std_logic ;

    -- LZRW3 CORE interface signals 
  signal data_in_sig        :  std_logic_vector (byte_size_g -1 downto 0) ;	
  signal data_in_valid_sig  :	 std_logic ;	 	
  
    -- WISHBONE master interface with BUS signals
  signal ADR_O_sig          :  std_logic_vector (Add_width_g-1 downto 0);     
  signal WM_DAT_O_sig       :  std_logic_vector (data_width_g-1 downto 0);
  signal WE_O_sig           :  std_logic;   
  signal STB_O_sig          :  std_logic;    
  signal CYC_O_sig          :  std_logic;   
  signal TGA_O_sig          :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);   
  signal TGD_O_sig          :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	  
  signal ACK_I_sig          :  std_logic;   
  signal WM_DAT_I_sig       :  std_logic_vector (data_width_g-1 downto 0); 
  signal STALL_I_sig		      :  std_logic;
  signal ERR_I_sig		        :  std_logic;
  
    --WISHBONE master registers side signals
  signal type_in_sig        :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	  
  signal addr_in_sig        :  std_logic_vector (Add_width_g-1 downto 0);     
  signal ram_start_addr_sig :  std_logic_vector (addr_bits_g-1 downto 0);     
  signal ram_din_sig        :  std_logic_vector (data_width_g-1 downto 0);
  signal len_in_sig         :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	   -- contains the len word        
  signal wr_sig             :  std_logic;                     				                         -- '1' for write, '0' for read
	signal wm_start_sig       :  std_logic;   
   
     -- WISHBONE slave interface with BUS signals
  signal ADR_I_sig          :  std_logic_vector (Add_width_g-1 downto 0);	   -- contains the addr word
  signal DAT_I_sig          :  std_logic_vector (data_width_g-1 downto 0); 	               -- contains the data_in word
  signal WE_I_sig           :  std_logic;                     				                         -- '1' for write, '0' for read
  signal STB_I_sig          :  std_logic;                     				                         -- '1' for active bus operation, '0' for no bus operation
  signal CYC_I_sig          :  std_logic;                     				                         -- '1' for bus transmition request, '0' for no bus transmition request
  signal TGA_I_sig          :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	  -- contains the type word
  signal TGD_I_sig          :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	   -- contains the len word
  signal ACK_O_sig          :  std_logic;                      				                        -- '1' when valid data is transmited to MW or for successfull write operation 
  signal DAT_O_sig          :  std_logic_vector (data_width_g-1 downto 0);   	             -- data transmit to MW
  signal STALL_O_sig		      :  std_logic;
	        
	  -- WISHBONE slave register side signals
  signal typ_sig			         :  std_logic_vector (byte_size_g -1 downto 0) ;                -- Message type
  signal len_sig		         	:  std_logic_vector (byte_size_g-1 downto 0) ;                 -- Length
  signal active_cycle_sig	  :  std_logic ;                                                 -- CYC_I

  begin
 
  short_fifo: general_fifo  
	 GENERIC MAP (	 
		reset_polarity_g	=> reset_polarity_g,
		width_g				     	=> byte_size_g,
		depth_g 			      => short_fifo_depth_g,
		log_depth_g			  	=> short_fifo_log_depth_g,
		almost_full_g		  => short_fifo_almost_full_g,
		almost_empty_g	 	=> short_fifo_almost_empty_g  )
	     	
   PORT MAP (
		 clk 		     => clk,
		 rst 		     => reset,
		 din 		     => data_in_sig ,
		 wr_en 		   => data_in_valid_sig ,
		 rd_en 	   	=> short_fifo_rd_en ,
		 flush		    => '0' ,
		 dout 	    	=> short_fifo_dout ,
		 dout_valid	=> short_fifo_dout_valid,
		 afull  	   => open ,
		 full 		    => short_fifo_full,
		 aempty 	   => open ,
		 empty 		   => open,
		 used 		    => open
      ); 

  fifo: general_fifo  
	 GENERIC MAP (	 
		reset_polarity_g	=> reset_polarity_g,
		width_g				     	=> byte_size_g,
		depth_g 			      => fifo_depth_g,
		log_depth_g			  	=> fifo_log_depth_g,
		almost_full_g		  => fifo_almost_full_g,
		almost_empty_g	 	=> fifo_almost_empty_g  )
	     	
   PORT MAP (
		 clk 		     => clk,
		 rst 		     => reset,
		 din 		     => short_fifo_dout ,
		 wr_en 		   => short_fifo_dout_valid ,
		 rd_en 	   	=> fifo_rd_en ,
		 flush		    => '0' ,
		 dout 	    	=> fifo_dout ,
		 dout_valid	=> fifo_dout_valid,
		 afull  	   => open ,
		 full 		    => fifo_full,
		 aempty 	   => open ,
		 empty 		   => fifo_empty,
		 used 		    => fifo_used 
      );


output_block_wm : wishbone_master 
  GENERIC MAP (
    reset_activity_polarity_g  	=> reset_polarity_g,
    data_width_g               	=> data_width_g,
	  type_d_g				               	=> type_d_g,
--	  addr_d_g				               	=> addr_d_g,
	  Add_width_g				=> Add_width_g,
	  len_d_g					               	=> len_d_g,
	  addr_bits_g				            	=> addr_bits_g
    )
  PORT MAP (
     sys_clk        => clk,  
     sys_reset	     => reset,     
	--control unit signals
	   wm_start		     => wm_start_sig,
	   wr				         => wr_sig,
	   type_in			     => type_in_sig,
     len_in			      => len_in_sig,
     addr_in			     => addr_in_sig,
	   ram_start_addr	=> ram_start_addr_sig,
     wm_end			      => open,
	--RAM signals
	   ram_addr		     => open,
	   ram_dout		     => open,
	   ram_dout_valid	=> open,
	   ram_aout		     => open,
	   ram_aout_valid	=> open,
	   ram_din		     	=> ram_din_sig,
	   ram_din_valid	 => '1',
    --bus side signals
     ADR_O	         => ADR_O_sig ,       
     DAT_O          => WM_DAT_O_sig ,
     WE_O           => WE_O_sig ,    
     STB_O          => STB_O_sig ,    
     CYC_O          => CYC_O_sig ,    
     TGA_O          => TGA_O_sig ,    
     TGD_O          => TGD_O_sig ,   
     ACK_I          => ACK_I_sig ,    
     DAT_I          => WM_DAT_I_sig ,
     STALL_I	       => STALL_I_sig ,
	   ERR_I	         => ERR_I_sig
);
				

output_block_ws: wishbone_slave
     GENERIC MAP (
       reset_activity_polarity_g  	=> reset_polarity_g,
       data_width_g               	=> byte_size_g,     
--	  addr_d_g				               	=> addr_d_g,
		Add_width_g				=> Add_width_g,
	     len_d_g				                 => len_d_g,
	     type_d_g				                => type_d_g  
		 )	   
     PORT MAP (
       clk        	=> clk,
       reset      	=> reset,   
	   --bus side signals
       ADR_I        => ADR_I_sig,
       DAT_I        => DAT_I_sig,
       WE_I         => WE_I_sig,
       STB_I        => STB_I_sig,
       CYC_I        => CYC_I_sig,
       TGA_I        => TGA_I_sig,
       TGD_I        => TGD_I_sig,
       ACK_O        => ACK_O_sig,
       DAT_O        => DAT_O_sig,
	   STALL_O	    => STALL_O_sig,
	   --register side signals
       typ			         => typ_sig,
	     addr	          => open,
	     len		         	=> len_sig,
	     wr_en			       => open,
	     ws_data	       => open,
	     ws_data_valid	 => open,
	     reg_data       => fifo_dout,
       reg_data_valid => fifo_dout_valid,
	     active_cycle	  => active_cycle_sig,
	     stall			       => fifo_empty 
	       ); 


 -- P R O C E S S E S     A R E A  --


-- The FSM change state when the compressor core 
-- finish to send compressed data, then NOT accept to receive new data
-- till send operation end.
fsm_in_process: process(clk, reset)
  begin
    if(reset = reset_polarity_g) then
      fsm_in_state <= buffering_st ;
    elsif rising_edge(clk)then
      case fsm_in_state is
        when buffering_st =>  
          if (lzrw3_done = '1') then
            fsm_in_state <= transferring_st ;
          end if;
        when transferring_st =>    -- till the send operation end
          if (fifo_empty = '1') then
            fsm_in_state <= buffering_st ;
          end if;
      end case;
    end if;
  end process fsm_in_process; 

-- to lzrw3 core depends on FSM_in state
client_ready  <= '1' when ( (fsm_in_state = buffering_st) and (short_fifo_full = '0') ) else '0' ; 
  
          


-- this FSM determine the requierd bytes to send to TX PATH and
-- initialize hand shake with TX PATH to transffer bytes
-- from FIFO 
fsm_out_process: process(clk, reset)
  begin
    if(reset = reset_polarity_g) then
      fsm_out_state <= idle_st ;
    elsif rising_edge(clk)then
      case fsm_out_state is       
            
        when idle_st =>
          if (fsm_in_state = buffering_st) then
            fsm_out_state <= idle_st ;          -- if FIFO still receive data - wait 
          else
            fsm_out_state <= wm_request_st ;    -- FIFO ready to transfer data                
          end if;
                    
        when wm_request_st =>
          if (ACK_I = '1'and STALL_I = '0') then -- WM receives ack --and TX PATH ready for new transaction
              fsm_out_state <= send_data_st;
          elsif (active_cycle_sig = '1' and typ_sig = "00000100" and len_sig = ram_din_sig ) then -- case that TX PATH was at sending and recognize read request so stall still on high value and request ack without stall not accepted          
               fsm_out_state <= send_data_st;                                                         -- in this case: recognize if read request from fifo start 
          else
            fsm_out_state <= wm_request_st;
          end if;
          
        when send_data_st => 
          if (requested_bytes = 0) then
            fsm_out_state <= wait_after_send_st;
          else
            fsm_out_state <= send_data_st;            
          end if;
          
        when wait_after_send_st =>
          if(wait_cycles = 0) then
            fsm_out_state <= idle_st;
          else
            fsm_out_state <= wait_after_send_st;
          end if;
          
        when others =>
          fsm_out_state <= idle_st ; 
                             
      end case;
    end if;
  end process fsm_out_process; 
         

-- This process counts the bytes needed to be sent to 
-- TX PATH according to fifo uased bytes 
 requested_bytes_to_send_proc: process (clk,reset)
  begin
    if(reset = reset_polarity_g) then
      requested_bytes <= 0;
    elsif rising_edge(clk)then
      if(fsm_out_state = idle_st ) then -- counter update only before request_st
        if(fifo_used > 255) then
          requested_bytes <= 256 ;      -- 256 bytes should transmit
        else
          requested_bytes <= to_integer(unsigned(fifo_used)) ;
        end if;
      elsif(fsm_out_state = send_data_st) then
        if(STB_I_sig = '1') then        -- count wishbone slave acks     
          if(requested_bytes = 0 or (requested_bytes - 1  = 0)) then
            requested_bytes <= 0;       -- minimum value
          else
            requested_bytes <= requested_bytes - 1 ;
          end if;
        end if;
      else
        requested_bytes <= requested_bytes;
      end if;
    end if;
  end process requested_bytes_to_send_proc;


-- This process maintain a counter that represents the
-- clock cycles remain to output_block client (TX PATH)
-- to transfer amount of bytes that transfer to him.
 wait_counter_proc: process (clk,reset)
  begin
    if(reset = reset_polarity_g) then
      wait_cycles <= 0;
    elsif rising_edge(clk)then
      if(fsm_out_state = idle_st ) then
        wait_cycles <= 0;
      elsif(fsm_out_state = wm_request_st ) then -- counter update in request_st to new transferring data size 
        wait_cycles <= ( requested_bytes + tx_fifo_d_g + Add_width_g + len_d_g + type_d_g + 4 ) * calculated_const_c  ; -- (data size in bits + TX-PATH FIFO maximum usage + frames header length (bytes of SOF, ADDR, TYPE, LEN, CRC, EOF) + 1 for confident) * uart frame length (in bits) for each byte * clock cycles to transmit each bit   
      elsif(fsm_out_state = wait_after_send_st) then -- countdown to 0 
        if(wait_cycles > 0) then 
          wait_cycles <= wait_cycles - 1 ;
        else
          wait_cycles <= 0;
        end if;
      end if;
    end if;
  end process wait_counter_proc;
        
        
-- SHORT FIFO signals
short_fifo_rd_en <= '1' when (fifo_full = '0') else '0' ;
       
send_data_st_en <= '1' when fsm_out_state = send_data_st else '0';
fifo_rd_en <= (CYC_I_sig and STB_I_sig) when (send_data_st_en = '1') else '0' ;
--wishbone master inputs for request 
wm_start_sig <= '1' when(fsm_out_state = wm_request_st) else '0' ;

-- all others inputs with meaning only if wm_start_sig = '1'
--type_in_sig         <= "00000011" ;             --  TYPE 03
type_in_sig         <= "00000010" ;             --  TX TYPE (2)
ram_din_sig         <= std_logic_vector(to_unsigned(requested_bytes-1, ram_din_sig'length)) ;
len_in_sig          <= (others => '0') ;        -- len = data length -1 (and data is allways one byte = request bytes to send - 1)
wr_sig              <= '1';                     -- allways writes data to TX PATH slave
addr_in_sig         <= (others => '0') ;
ram_start_addr_sig  <= (others => '0') ;



-- OUTPUT BLOCK - LZRW3 CORE interface connections

data_in_sig       <= data_in ;       
data_in_valid_sig <= data_in_valid ;     	 	     


-- OUTPUT BLOCK - BUS interface connections

  -- wishbone MASTER BUS side
  -- to intercon (BUS)
  ADR_O		       	 <= ADR_O_sig ;
  WM_DAT_O			     <= WM_DAT_O_sig ;
  WE_O			         <= WE_O_sig  ;
  STB_O			        <= STB_O_sig ;                                         
  CYC_O			        <= CYC_O_sig ;
  TGA_O			        <= TGA_O_sig ;
  TGD_O			        <= TGD_O_sig ;
  -- from intercon (BUS)  
  ACK_I_sig       <= ACK_I	;
  WM_DAT_I_sig    <= WM_DAT_I	;
  STALL_I_sig     <= STALL_I	;
  ERR_I_sig       <= ERR_I	;                   
          
  -- wishbone SLAVE BUS side
  -- from intercon (BUS)   
  ADR_I_sig       <= ADR_I	;
  DAT_I_sig       <= DAT_I	;
  WE_I_sig        <= WE_I	 ;
  STB_I_sig       <= STB_I	;
  CYC_I_sig       <= CYC_I	;
  TGA_I_sig       <= TGA_I	;
  TGD_I_sig       <= TGD_I	;
  -- to intercon (BUS)    
  ACK_O           <= ACK_O_sig   ;                   				                   
  DAT_O           <= DAT_O_sig   ; 
  STALL_O		       <= STALL_O_sig ;     				     

end architecture arc_output_block ;
  