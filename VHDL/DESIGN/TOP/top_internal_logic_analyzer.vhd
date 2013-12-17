--------------------------------------------------------------------------------------------------------------------------
-- Title       : top_internal_logic_analyzer
-- Design      : Lzrw3 compression core
-- Author      : Shahar Zuta & Netanel Yamin
-- Company     : Technion High Speed Digital Systems Lab
--
--------------------------------------------------------------------------------------------------------------------------
--
-- File        : VHDL\DESIGN\TOP\TOP_REL_3\up_to_date\TOP_REL_3.vhd 
-- Generated   : 10.07.2013
--
--------------------------------------------------------------------------------------------------------------------------
--
-- Description :
-- 
--
-- 
--------------------------------------------------------------------------------------------------------------------------
--
-- Revision History : 	Revision Number		Date	     	 Description			               	 
--					             1.0				          10.07.2013	 creation 	        			
--
--------------------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all ;


  entity top_internal_logic_analyzer is
    generic (
		reset_polarity_g	    		: std_logic := '1';	                				-- '0' - Active Low Reset, '1' Active High Reset.
		enable_polarity_g				: std_logic	:= '1';									--'1' the entity is active, '0' entity not active
	    -- core generics
	    signal_ram_depth_g				: positive  :=	3;									--depth of RAM
		signal_ram_width_g				: positive 	:=  8;   								--width of basic RAM
		record_depth_g					: positive  :=	4;									--number of bits that is recorded from each signal
		data_width_g            		: positive 	:= 	8;      						    --defines the width of the data lines of the system
		Add_width_g  		    		: positive 	:=  8;     								--width of address word in the WB
		num_of_signals_g				: positive	:=	8;									--number of signals that will be recorded simultaneously	(Width of data)
		power2_out_g					: natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
		power_sign_g					: integer range -1 to 1 	:= 1;					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
		type_d_g						: positive 	:= 	1;									--Type Depth
		len_d_g							: positive 	:= 	1;									--Length Depth
		en_reg_address_g      		   	: 	natural 	:= 0;
		trigger_type_reg_1_address_g 	: 	natural 	:= 1;
		trigger_position_reg_2_address_g: 	natural 	:= 2;
		clk_to_start_reg_3_address_g 	: 	natural 	:= 3;
		enable_reg_address_4_g 		   	: 	natural 	:= 4;
		-- signal generator generics   
		external_en_g					: std_logic	:= 	'0';								-- 1 -> getting the data from an external source . 0 -> dout is a counter
		scene_number_reg_1_address_g 	: 	natural 	:= 1;
		enable_reg_address_2_g 		   	: 	natural 	:= 2;
--      -- OUTPUT BLOCK generics
        byte_size_g			            : positive 	:= 8;          							-- One byte
		fifo_depth_g 			      	: positive 	:= 32768;	         					-- Maximum elements in FIFO
	    fifo_log_depth_g			   	: natural	:= 15;	            					-- (2^25 = 32K) Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
	    fifo_almost_full_g		  		: positive	:= 32767;   	      					-- Rise almost full flag at this number of elements in FIFO
	    fifo_almost_empty_g	 			: positive	:= 1;	             					-- Rise almost empty flag at this number of elements in FIFO				    
		--  RX PATH (and UART) generics
		clkrate_g		     			: positive	:= 50000000;		                	-- Sys. clock [Hz]      
--		addr_d_g		      			: positive  := 3;		            				-- Address Depth
	   --uart_rx generics
		parity_en_g		    			: natural range 0 to 1 := 0; 		             	-- 1 to Enable parity bit, 0 to disable parity bit
		parity_odd_g		   			: boolean 	:= false; 			                 	-- TRUE = odd, FALSE = even
		uart_idle_g		    			: std_logic := '1';				                    -- IDLE_ST line value
		baudrate_g			    		: positive	:= 115200;			                  	-- UART baudrate [Hz]
		--mp_dec generics
		len_dec1_g	     				: boolean   := true;	                      		-- TRUE - Recieved length is decreased by 1 ,to save 1 bit  --FALSE - Recieved length is the actual length
		sof_d_g				      		: positive  := 1;		                        	-- SOF Depth
		crc_d_g				      		: positive  := 1;		                        	-- CRC Depth
		eof_d_g			 	     		: positive  := 1;		                        	-- EOF Depth					
		sof_val_g			     		: natural   := 60;	                       			-- (3Ch) SOF block value. Upper block is MSB
		eof_val_g			     		: natural   := 165;		                      		-- (A5h) EOF block value. Upper block is MSB				
		--ram_simple_generics
		rx_path_addr_bits_g		        : positive  := 8;            						-- Depth of data	(2^10 = 1024 addresses)  
		--error_register_generics
		error_register_address_g       	: natural   :=0 ;            						-- defines the address that should be sent on access to the unit
		led_active_polarity_g          	: std_logic :='1';           						-- defines the active state of the error signal input: '0' active low, '1' active high
		error_active_polarity_g        	: std_logic :='1';          					 	-- defines the polarity which the error signal is active in  
		code_version_g			        : natural	:= 0	;           					-- Hardware code version
		--  TX PATH generics				
		fifo_d_g				        : positive	:= 9;	           						-- Maximum elements in FIFO
		tx_path_addr_bits_g		        : positive  := 8;           						-- Depth of data	(2^10 = 1024 addresses)    
		databits_g				        : natural range 5 to 8 := 8;  						-- Number of databits								
		-- WISHBONE INTERCON generics      
        type_slave_1_g             		: std_logic_vector  := "0001";     					-- slave 1 type
        type_slave_2_g             		: std_logic_vector  := "0010";     					-- slave 2 type
        type_slave_3_g             		: std_logic_vector  := "0011";     						-- slave 3 type
        type_slave_4_g             		: std_logic_vector  := "0100";     					-- slave 4 type
        type_slave_5_g             		: std_logic_vector  := "0101";     					-- slave 5 type
        type_slave_6_g             		: std_logic_vector  := "0110";     					-- slave 6 type
        type_slave_7_g             		: std_logic_vector  := "0111";     					-- slave 7 type
	    --timer generics
	    watchdog_timer_freq_g      		: positive         := 100;         					-- timer tick after (clk_freq_g/watchdog_timer_freq_g) ==> 10msec
        timer_en_polarity_g        		: std_logic        := '1';         					-- defines the polarity which the timer enable (timer_en) is active on: '0' active low, '1' active high  
	    watchdog_en_vector_g	      	: std_logic_vector := "11111111"   					-- watchdog enabled for the clients which have '1' on their matching bit in the vector
        );
        
    port( 
        clk                 : in std_logic;                                                -- system clock
        reset               : in std_logic;                                                -- system reset
       -- uart interface  (ingrss)       
        rx_din              : in std_logic;                                                -- input of UART data
       -- uart interface  (egress)   
		tx_dout 		    : out std_logic;        
       -- on board LED          
        error_led_out       : out std_logic                                                -- '1' when one of the error bits in the register is high         	        
        ); 
  end entity top_internal_logic_analyzer;  
  
  architecture arc_top_internal_logic_analyzer of top_internal_logic_analyzer is
    
    
------------------------------------------------------------------------------------------------------------------------------------------------------------ 
-----------------------------   C O M P O N E N T    A R E A   -------------------------------------------------------------------------------------------------------   
------------------------------------------------------------------------------------------------------------------------------------------------------------ 

COMPONENT rx_path is
   generic (
		-- mutual generics
		reset_polarity_g	:		std_logic  := '1'	;			        -- '0' = Active Low, '1' = Active High
		data_width_g     :  natural    := 8;              -- defines the width of the data lines of the system
		clkrate_g		     	:		positive	  := 100000000;		    -- Sys. clock [Hz]      
		--uart_rx generics
		parity_en_g		    :		natural range 0 to 1 := 0; 		 -- 1 to Enable parity bit, 0 to disable parity bit
		parity_odd_g		   :		boolean 	  := false; 			      -- TRUE = odd, FALSE = even
		uart_idle_g		    :		std_logic 	:= '1';				        -- IDLE_ST line value
		baudrate_g			    :		positive	  := 115200;			      -- UART baudrate [Hz]
		--mp_dec generics
		len_dec1_g	     	:	boolean     := true;	          -- TRUE - Recieved length is decreased by 1 ,to save 1 bit  --FALSE - Recieved length is the actual length
		sof_d_g				      :	positive    := 1;		            -- SOF Depth
		type_d_g		 	     :	positive    := 1;		            -- Type Depth
		Add_width_g  		    		: positive 	:=  8;     								--width of address word in the WB
--		addr_d_g		      	:	positive    := 3;		            -- Address Depth
		len_d_g				      :	positive    := 1;	            	-- Length Depth
		crc_d_g				      :	positive    := 1;		            -- CRC Depth
		eof_d_g			 	     :	positive    := 1;		            -- EOF Depth					
		sof_val_g			     :	natural     := 60;	           	-- (3Ch) SOF block value. Upper block is MSB
		eof_val_g			     :	natural     := 165;		          -- (A5h) EOF block value. Upper block is MSB				
		--ram_simple_generics
		addr_bits_g		    :	positive   	:= 8;              -- Depth of data	(2^10 = 1024 addresses)  
		--error_register_generics
		error_register_address_g       : natural   := 0 ; -- defines the address that should be sent on access to the unit
		led_active_polarity_g          : std_logic :='1'; -- defines the active state of the error signal input: '0' active low, '1' active high
		error_active_polarity_g        : std_logic :='1'; -- defines the polarity which the error signal is active in  
		code_version_g			             	: natural	  := 0	  -- Hardware code version
           );
   port
   	   (
		sys_clk        : in std_logic;                                                -- system clock
		sys_reset      : in std_logic;                                                -- system reset
		rx_din         : in std_logic;                                                -- input of UART data
		error_led_out  : out std_logic;                                               -- '1' when one of the error bits in the register is high
		flash_error    : in std_logic;                                                -- error signal from flash client - directed to error register
		--Wishbone Master interface
		ADR_O          : out std_logic_vector (Add_width_g-1 downto 0);   -- contains the addr word
		DAT_O          : out std_logic_vector (data_width_g-1 downto 0);              -- contains the data_in word
		WE_O           : out std_logic;                                               -- '1' for write, '0' for read
		STB_O          : out std_logic;                                               -- '1' for active bus operation, '0' for no bus operation
		CYC_O          : out std_logic;                                               -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_O          : out std_logic_vector (type_d_g * data_width_g-1 downto 0);   -- contains the type word
		TGD_O          : out std_logic_vector (len_d_g * data_width_g-1 downto 0);    -- contains the len word
		ACK_I          : in std_logic;                                                -- '1' when valid data is recieved from WS or for successfull write operation in WS
		DAT_I          : in std_logic_vector (data_width_g-1 downto 0);               -- data recieved from WS
		STALL_I		      : in std_logic;                                                -- STALL - WS is not available for transaction 
		ERR_I			       : in std_logic;                                                -- Watchdog interrupts, resets wishbone master	
		--Wishbone Slave interface
		ADR_I          : in std_logic_vector (Add_width_g-1 downto 0);	 -- contains the addr word
--		WS_DAT_I 	   : in std_logic_vector (data_width_g-1 downto 0);
		WE_I           : in std_logic;                     			                       	-- '1' for write, '0' for read
		STB_I          : in std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
		CYC_I          : in std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I          : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	-- contains the type word
		TGD_I          : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);  	-- contains the len word
		ACK_O          : out std_logic;                      			                     	-- '1' when valid data is transmited to MW or for successfull write operation 
		WS_DAT_O       : out std_logic_vector (data_width_g-1 downto 0);             	-- data transmit to MW  
		STALL_O	      	: out std_logic                                                -- STALL - WS is not available for transaction 
       );
END COMPONENT;

COMPONENT tx_path  
    generic (
	    reset_polarity_g		: std_logic := '1'; 	          --'0' = Active Low, '1' = Active High
	    data_width_g	   		: natural	:=8;	
		Add_width_g  		    		: positive 	:=  8;     								--width of address word in the WB
--	    addr_d_g				      : positive := 3;		             --Address Depth
		len_d_g					      : positive := 1;		             --Length Depth
		type_d_g				      : positive := 1;	             	--Type Depth 
	    fifo_d_g				      : positive	:= 9;	              -- Maximum elements in FIFO
	    addr_bits_g		    	: positive 	:= 8;             	--Depth of data	(2^10 = 1024 addresses)    
	    parity_en_g				   : natural	range 0 to 1 := 1; 		--Enable parity bit = 1, parity disabled = 0
	    parity_odd_g			   : boolean 	:= false;		        	--TRUE = odd, FALSE = even
	    uart_idle_g				   : std_logic 	:= '1';		       		--Idle line value
	    baudrate_g				    : positive	:= 115200;		       	--UART baudrate [Hz]
	    clkrate_g				     : positive	:= 100000000;		     --Sys. clock [Hz]
	    databits_g				    : natural range 5 to 8 := 8	  	--Number of databits
      );			
	port   (
	    sys_clk  			      : in std_logic; 		             --system clock
	    sys_reset     		  : in std_logic;		 	            --system reset
	     ----input and output to SLAVE TX from master RX
	    DAT_I_S			       	: in std_logic_vector (data_width_g-1 downto 0) ; 
	    ADR_I_S_TX				    : in std_logic_vector (Add_width_g-1 downto 0) ; 
	    TGA_I_S_TX				    : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0) ;  	--TYPE
	    TGD_I_S_TX				    : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0) ; 			--LEN
	    WE_I_S_TX				     : in std_logic;
	    STB_I_S_TX				    : in std_logic;
	    CYC_I_S_TX			   	 : in std_logic;
	    ACK_O_TO_M				    : out std_logic;
	    DAT_O_TO_M				    : out std_logic_vector (data_width_g-1 downto 0) ;
	    STALL_O_TO_M		   	: out std_logic;
	     ----input and output to MASTER TX from client slavr
	    DAT_I_CLIENT			   : in std_logic_vector (data_width_g-1 downto 0) ; 
	    ACK_I_CLIENT			   : in std_logic;
	    STALL_I_CLIENT	   : in std_logic;
	    ERR_I_CLIENT			   : in std_logic;
	    ADR_O_CLIENT 		   : out std_logic_vector (Add_width_g-1 downto 0) ;        
		DAT_O_CLIENT      : out std_logic_vector (data_width_g-1 downto 0) ;
		WE_O_CLIENT       : out std_logic;
		STB_O_CLIENT     	: out std_logic;
		CYC_O_CLIENT      : out std_logic;
		TGA_O_CLIENT     	: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0) ;
		TGD_O_CLIENT			   : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0) ;	
	    uart_out		    	   : out std_logic
    );
		 
  END COMPONENT;
 
COMPONENT wishbone_intercon is
   generic (
		reset_activity_polarity_g  : std_logic :='1';               -- defines reset active polarity: '0' active low, '1' active high
		data_width_g               : natural   := 8 ;               -- defines the width of the data lines of the system
		type_d_g			       : positive  := 1 ;		             -- Type Depth
	    Add_width_g  		       : positive 	:=  8;     								--width of address word in the WB
		len_d_g				       : positive  := 1 ;		             -- Length Depth
	    type_slave_1_g             : std_logic_vector  := "0001";   -- slave 1 type
		type_slave_2_g             : std_logic_vector  := "0010";   -- slave 2 type
		type_slave_3_g             : std_logic_vector  := "0011";   -- slave 3 type
		type_slave_4_g             : std_logic_vector  := "0100";   -- slave 4 type
		type_slave_5_g             : std_logic_vector  := "0101";   -- slave 5 type
		type_slave_6_g             : std_logic_vector  := "0110";   -- slave 6 type
		type_slave_7_g             : std_logic_vector  := "0111";   -- slave 7 type
		--timer generics
	    watchdog_timer_freq_g      : positive         :=100;        -- timer tick after (clk_freq_g/watchdog_timer_freq_g) ==> 10msec
		clk_freq_g                 : positive         :=100000000;  -- the clock input to the block. this is the clock used in the system containing the timer unit. units: [Hz]
		timer_en_polarity_g        : std_logic        :='1';        -- defines the polarity which the timer enable (timer_en) is active on: '0' active low, '1' active high  
	    watchdog_en_vector_g	      : std_logic_vector := "11110111" -- watchdog enabled for the clients which have '1' on their matching bit in the vector
           );
  port
   	   (
		sys_clk           : in std_logic;                                             -- system clock
		sys_reset         : in std_logic;                                             -- system reset
		--Wishbone Master 1 interfaces (rx_path)
		ADR_O_M1          : in std_logic_vector (Add_width_g-1 downto 0); -- contains the address word
		DAT_O_M1          : in std_logic_vector (data_width_g-1 downto 0);            -- contains the data_in word
		WE_O_M1           : in std_logic;                                             -- '1' for write, '0' for read
		STB_O_M1          : in std_logic;                                             -- '1' for active bus operation, '0' for no bus operation
		CYC_O_M1          : in std_logic;                                             -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_O_M1          : in std_logic_vector (type_d_g * data_width_g-1 downto 0); -- contains the type word
		TGD_O_M1          : in std_logic_vector (len_d_g * data_width_g-1 downto 0);  -- contains the len word
		ACK_I_M1          : out std_logic;                                            -- '1' when valid data is recieved from WS or for successful write operation in WS
		DAT_I_M1          : out std_logic_vector (data_width_g-1 downto 0);           -- data recieved from WS
		STALL_I_M1		      : out std_logic;                                            -- STALL - WS is not available for transaction 
		ERR_I_M1		        : out std_logic;                                            -- Watchdog interrupts, resets wishbone master
		--Wishbone Master 2 interfaces  (tx_path)
		ADR_O_M2          : in std_logic_vector (Add_width_g-1 downto 0); -- contains the address word
		DAT_O_M2          : in std_logic_vector (data_width_g-1 downto 0);            -- contains the data_in word
		WE_O_M2           : in std_logic;                                             -- '1' for write, '0' for read
		STB_O_M2          : in std_logic;                                             -- '1' for active bus operation, '0' for no bus operation
		CYC_O_M2          : in std_logic;                                             -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_O_M2          : in std_logic_vector (type_d_g * data_width_g-1 downto 0); -- contains the type word
		TGD_O_M2          : in std_logic_vector (len_d_g * data_width_g-1 downto 0);  -- contains the len word
		ACK_I_M2          : out std_logic;                                            -- '1' when valid data is recieved from WS or for successful write operation in WS
		DAT_I_M2          : out std_logic_vector (data_width_g-1 downto 0);           -- data recieved from WS
		STALL_I_M2		      : out std_logic;                                            -- STALL - WS is not available for transaction 
		ERR_I_M2		        : out std_logic;                                            -- Watchdog interrupts, resets wishbone master
		--Wishbone Master 3 interfaces (output block)
		ADR_O_M3          : in std_logic_vector (Add_width_g-1 downto 0); -- contains the address word
		DAT_O_M3          : in std_logic_vector (data_width_g-1 downto 0);            -- contains the data_in word
		WE_O_M3           : in std_logic;                                             -- '1' for write, '0' for read
		STB_O_M3          : in std_logic;                                             -- '1' for active bus operation, '0' for no bus operation
		CYC_O_M3          : in std_logic;                                             -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_O_M3          : in std_logic_vector (type_d_g * data_width_g-1 downto 0); -- contains the type word
		TGD_O_M3          : in std_logic_vector (len_d_g * data_width_g-1 downto 0);  -- contains the len word
		ACK_I_M3          : out std_logic;                                            -- '1' when valid data is recieved from WS or for successful write operation in WS
		DAT_I_M3          : out std_logic_vector (data_width_g-1 downto 0);           -- data recieved from WS
		STALL_I_M3		      : out std_logic;                                            -- STALL - WS is not available for transaction 
		ERR_I_M3		        : out std_logic;                                            -- Watchdog interrupts, resets wishbone master	
		--Wishbone Slave 1 interfaces (core)
		ADR_I_S1          : out std_logic_vector (Add_width_g-1 downto 0);	 --contains the address word
		DAT_I_S1          : out std_logic_vector (data_width_g-1 downto 0); 	             --contains the data_in word
		WE_I_S1           : out std_logic;                     				                       -- '1' for write, '0' for read
		STB_I_S1          : out std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
		CYC_I_S1          : out std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I_S1          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I_S1          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	 --contains the len word
		ACK_O_S1          : in std_logic;                      				                       --'1' when valid data is transmitted to MW or for successful write operation 
		DAT_O_S1          : in std_logic_vector (data_width_g-1 downto 0);   	            --data transmit to MW
		STALL_O_S1        : in std_logic;                                                 --STALL - WS is not available for transaction 
		--Wishbone Slave 2 interfaces (tx_path)
		ADR_I_S2          : out std_logic_vector (Add_width_g-1 downto 0);	 --contains the address word
		DAT_I_S2          : out std_logic_vector (data_width_g-1 downto 0); 	             --contains the data_in word
		WE_I_S2           : out std_logic;                     				                       -- '1' for write, '0' for read
		STB_I_S2          : out std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
		CYC_I_S2          : out std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I_S2          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I_S2          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	 --contains the len word
		ACK_O_S2          : in std_logic;                      				                       --'1' when valid data is transmited to MW or for successfull write operation 
		DAT_O_S2          : in std_logic_vector (data_width_g-1 downto 0);   	            --data transmit to MW
		STALL_O_S2        : in std_logic;                                                 --STALL - WS is not available for transaction 
		--Wishbone Slave 3 interfaces (output block)
		ADR_I_S3          : out std_logic_vector (Add_width_g-1 downto 0);	 --contains the address word
		DAT_I_S3          : out std_logic_vector (data_width_g-1 downto 0); 	             --contains the data_in word
		WE_I_S3           : out std_logic;                     				                       -- '1' for write, '0' for read
		STB_I_S3          : out std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
		CYC_I_S3          : out std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I_S3          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I_S3          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	 --contains the len word
		ACK_O_S3          : in std_logic;                      				                       --'1' when valid data is transmited to MW or for successfull write operation 
		DAT_O_S3          : in std_logic_vector (data_width_g-1 downto 0);   	            --data transmit to MW
		STALL_O_S3        : in std_logic;                                                 --STALL - WS is not available for transaction 
		--Wishbone Slave 4 interfaces (signal generator)
		ADR_I_S4          : out std_logic_vector (Add_width_g-1 downto 0);	 --contains the address word
		DAT_I_S4          : out std_logic_vector (data_width_g-1 downto 0); 	             --contains the data_in word
		WE_I_S4           : out std_logic;                     				                       -- '1' for write, '0' for read
		STB_I_S4          : out std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
		CYC_I_S4          : out std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I_S4          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I_S4          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	 --contains the len word
		ACK_O_S4          : in std_logic;                      				                       --'1' when valid data is transmited to MW or for successfull write operation 
		DAT_O_S4          : in std_logic_vector (data_width_g-1 downto 0);   	            --data transmit to MW
		STALL_O_S4        : in std_logic;                                                 	--STALL - WS is not available for transaction    
		--Wishbone Slave 5 interfaces (not in use)
		ADR_I_S5          : out std_logic_vector (Add_width_g-1 downto 0);	 --contains the address word
		DAT_I_S5          : out std_logic_vector (data_width_g-1 downto 0); 	             --contains the data_in word
		WE_I_S5           : out std_logic;                     				                       -- '1' for write, '0' for read
		STB_I_S5          : out std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
		CYC_I_S5          : out std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I_S5          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I_S5          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	 --contains the len word
		ACK_O_S5          : in std_logic;                      				                       --'1' when valid data is transmited to MW or for successfull write operation 
		DAT_O_S5          : in std_logic_vector (data_width_g-1 downto 0);   	            --data transmit to MW
		STALL_O_S5        : in std_logic;                                                 --STALL - WS is not available for transaction     
		--Wishbone Slave 6 interfaces (not in use)
		ADR_I_S6          : out std_logic_vector (Add_width_g-1 downto 0);	 --contains the address word
		DAT_I_S6          : out std_logic_vector (data_width_g-1 downto 0); 	             --contains the data_in word
		WE_I_S6           : out std_logic;                     				                       -- '1' for write, '0' for read
		STB_I_S6          : out std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
		CYC_I_S6          : out std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I_S6          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I_S6          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	 --contains the len word
		ACK_O_S6          : in std_logic;                      				                       --'1' when valid data is transmited to MW or for successfull write operation 
		DAT_O_S6          : in std_logic_vector (data_width_g-1 downto 0);   	            --data transmit to MW
		STALL_O_S6        : in std_logic;                                                 --STALL - WS is not available for transaction     
		--Wishbone Slave 7 interface (not in use)
		ADR_I_S7          : out std_logic_vector (Add_width_g-1 downto 0);	 --contains the address word
		DAT_I_S7          : out std_logic_vector (data_width_g-1 downto 0); 	             --contains the data_in word
		WE_I_S7           : out std_logic;                     				                       -- '1' for write, '0' for read
		STB_I_S7          : out std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
		CYC_I_S7          : out std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I_S7          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I_S7          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	 --contains the len word
		ACK_O_S7          : in std_logic;                      				                       --'1' when valid data is transmited to MW or for successfull write operation 
		DAT_O_S7          : in std_logic_vector (data_width_g-1 downto 0);   	            --data transmit to MW
		STALL_O_S7        : in std_logic                                                  --STALL - WS is not available for transaction    
   );
END COMPONENT;  

COMPONENT output_block is
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
--	      addr_d_g			                 :	positive   := 3 ;		         -- Address Depth
	    Add_width_g  		    			:   positive 	:=  8;     								--width of addr word in the RAM
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
--          data_in                  : in std_logic_vector (byte_size_g -1 downto 0) ;	
--         data_in_valid            :	in std_logic ;	 	
--          lzrw3_done               :	in std_logic ;                                             -- lzrw3_done for one clock
--          client_ready             :	out std_logic ;
        -- data input side (compatible to WB SLAVE)
		wm_end_2				: in std_logic; 										--when '1' WM ended a transaction or reseted by watchdog ERR_I signal
		ADR_I_2                 : in std_logic_vector (Add_width_g-1 downto 0);	   -- contains the addr word
        DAT_I_2                 : in std_logic_vector (data_width_g-1 downto 0); 	               -- contains the data_in word
        WE_I_2              	: in std_logic;                     				                         -- '1' for write, '0' for read
        STB_I_2                 : in std_logic;                     				                         -- '1' for active bus operation, '0' for no bus operation
        CYC_I_2                 : in std_logic;                     				                         -- '1' for bus transmition request, '0' for no bus transmition request
        TGA_I_2                 : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	  -- contains the type word
        TGD_I_2                 : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	   -- contains the len word
        ACK_O_2                 : out std_logic;                      				                       -- '1' when valid data is transmited to MW or for successfull write operation 
        DAT_O_2                 : out std_logic_vector (data_width_g-1 downto 0);   	            -- data transmit to MW
	    STALL_O_2		        : out std_logic;
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
END COMPONENT;

COMPONENT internal_logic_analyzer_core_top 
    generic (				
		reset_polarity_g		:	std_logic	:= '1';									--'0' - Active Low Reset, '1' Active High Reset
		enable_polarity_g		:	std_logic	:= '1';									--'1' the entity is active, '0' entity not active
		signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
		signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
		record_depth_g			: 	positive  	:=	4;									--number of bits that is recorded from each signal
		data_width_g            :	positive 	:= 	8;      						    --defines the width of the data lines of the system
		Add_width_g  		    :   positive 	:=  8;     								--width of address word in the RAM
		num_of_signals_g		:	positive	:=	8;									--num of signals that will be recorded simultaneously	(Width of data)
		en_reg_address_g      		   		: 	natural 	:= 0;
		trigger_type_reg_1_address_g 		: 	natural 	:= 1;
		trigger_position_reg_2_address_g	: 	natural 	:= 2;
		clk_to_start_reg_3_address_g 	   	: 	natural 	:= 3;
		enable_reg_address_4_g 		   		: 	natural 	:= 4;
		power2_out_g			:	natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
		power_sign_g			:	integer range -1 to 1 	:= 1;					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
		type_d_g				:	positive 	:= 	1;									--Type Depth
		len_d_g					:	positive 	:= 	1									--Length Depth
			);
	port	(
		clk							:	in std_logic;									--System clock
		rst							:	in std_logic;									--System Reset
		
		-- Signal Generator interface
		data_in						:	in std_logic_vector (num_of_signals_g - 1 downto 0);	--Input data from Signal Generator
		trigger						:	in std_logic;											--trigger signal from Signal Generator
				
		-- wishbone slave interface	
		ADR_I          		: in std_logic_vector (Add_width_g -1 downto 0);	--contains the address word
		DAT_I          		: in std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
		WE_I           		: in std_logic;                     				-- '1' for write, '0' for read
		STB_I          		: in std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
		CYC_I          		: in std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
		TGA_I          		: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I          		: in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
		ACK_O          		: out std_logic;                      							--'1' when valid data is transmited to MW or for successfull write operation 
		WS_DAT_O       		: out std_logic_vector (data_width_g-1 downto 0);   			--data transmit to MW
		STALL_O				: out std_logic; 												--STALL - WS is not available for transaction 
		-- wishbone master control unit signals
		wm_end_out			: out std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
--		TOP_active_cycle	: out std_logic; --CYC_I outputed to user side
--		stall				: in std_logic; -- stall - suspend wishbone transaction
		--wm_bus side signals
		ADR_O			: out std_logic_vector (Add_width_g-1 downto 0); --contains the address word
		WM_DAT_O			: out std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
		WE_O			: out std_logic;                     -- '1' for write, '0' for read
		STB_O			: out std_logic;                     -- '1' for active bus operation, '0' for no bus operation
		CYC_O			: out std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
		TGA_O			: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); --contains the type word
		TGD_O			: out std_logic_vector ((len_d_g )*(data_width_g)-1 downto 0); --contains the len word
		ACK_I			: in std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
		DAT_I_WM		: in std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
		STALL_I			: in std_logic; --STALL - WS is not available for transaction 
		ERR_I			: in std_logic  --Watchdog interrupts, resets wishbone master
			
			);
  END COMPONENT;

COMPONENT signal_generator_top  
    generic (
	    reset_polarity_g	:	std_logic	:=	'1';										-- '1' reset active high, '0' active low
		enable_polarity_g	:	std_logic	:= '1';											--'1' the entity is active high, '0' entity is active low
		data_width_g        :	positive 	:= 	8;      						    		-- defines the width of the data lines of the system 
		num_of_signals_g	:	positive	:=	4;											-- number of signals that will be recorded simultaneously
		external_en_g		:	std_logic	:= 	'0';										-- 1 -> getting the data from an external source . 0 -> dout is a counter
		Add_width_g    		:   positive 	:= 	8;											-- width of address word in the WB
		len_d_g				:	positive 	:= 	1;											-- Length Depth
		type_d_g			:	positive 	:= 	1;											-- Type Depth 
		scene_number_reg_1_address_g 		: 	natural 	:= 1;
		enable_reg_address_2_g 		   		: 	natural 	:= 2
      );			
	port   (
	    clk					:	in  std_logic;												--system clock
		reset				:	in  std_logic;												--system reset
		-----signal generator signals
		data_in				:	in	std_logic_vector ( num_of_signals_g -1 downto 0);		-- in case that we want to store a data from external source
		trigger_in			:	in	std_logic;												--trigger in external signal
		data_out			:	out	std_logic_vector ( num_of_signals_g -1 downto 0);		--data out
		trigger_out			:	out	std_logic;												--trigger out signal
		--bus side signals
		ADR_I          	: in std_logic_vector (Add_width_g -1 downto 0);				--contains the address word
		DAT_I          	: in std_logic_vector (data_width_g-1 downto 0); 				--contains the data_in word
		WE_I           	: in std_logic;                     							-- '1' for write, '0' for read
		STB_I          	: in std_logic;                     							-- '1' for active bus operation, '0' for no bus operation
		CYC_I          	: in std_logic;                     							-- '1' for bus transition request, '0' for no bus transition request
		TGA_I          	: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I          	: in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the length word
		ACK_O          	: out std_logic;                      							--'1' when valid data is transmitted to MW or for successful write operation 
		DAT_O          	: out std_logic_vector (data_width_g-1 downto 0);   			--data transmit to MW
		STALL_O			: out std_logic; 												--STALL - WS is not available for transaction 
		--register side signals
		rc_finish		: in std_logic										--  1 -> reset enable register
--		typ				: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	-- Type
--		addr	    	: out std_logic_vector (Add_width_g-1 downto 0);    			--the beginnig address in the client that the information will be written to
--		len				: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);   --Length
--		wr_en			: out std_logic;
--		ws_data	    	: out std_logic_vector (data_width_g-1 downto 0);   			--data out to registers
--		ws_data_valid	: out std_logic;												-- data valid to registers
--		reg_data       	: in std_logic_vector (data_width_g-1 downto 0); 	 			--data to be transmitted to the WM
--		reg_data_valid 	: in std_logic;   												--data to be transmitted to the WM validity
--		active_cycle	: out std_logic; 												--CYC_I outputted to user side
--		stall			: in std_logic 													-- stall - suspend wishbone transaction
    );
		 
  END COMPONENT;

---------------------------------------------------------------------------------------------------------------------------------------------------
----------------------  S I G N A L S   A R E A  -------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------------------------------------------         


----------------------- C O N N E C T O R S-------------------------------------------------------------------------------------------------------- 


-- interface in signals (ingress)
signal rx_din_sig                 : std_logic ;
signal error_led_out_sig          : std_logic ;

-- internal connectors signals (RX PATH to INTERCON)
-- master signals
signal ADR_O_M1_sig               :  std_logic_vector (Add_width_g - 1 downto 0);           
signal DAT_O_M1_sig               :  std_logic_vector (data_width_g-1 downto 0);          
signal WE_O_M1_sig                :  std_logic;            
signal STB_O_M1_sig               :  std_logic;            
signal CYC_O_M1_sig               :  std_logic;            
signal TGA_O_M1_sig               :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);          
signal TGD_O_M1_sig               :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);         
signal ACK_I_M1_sig               :  std_logic;          
signal DAT_I_M1_sig               :  std_logic_vector (data_width_g-1 downto 0);          
signal STALL_I_M1_sig             :  std_logic;		
signal ERR_I_M1_sig               :  std_logic;		
-- slave signals
signal ADR_I_S1_sig               :  std_logic_vector (Add_width_g-1 downto 0);              
signal DAT_I_S1_sig               :  std_logic_vector (data_width_g-1 downto 0);        
signal WE_I_S1_sig                :  std_logic;        
signal STB_I_S1_sig               :  std_logic;           
signal CYC_I_S1_sig               :  std_logic;              				                     
signal TGA_I_S1_sig               :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);
signal TGD_I_S1_sig               :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);
signal ACK_O_S1_sig               :  std_logic;
signal DAT_O_S1_sig               :  std_logic_vector (data_width_g-1 downto 0);  
signal STALL_O_S1_sig             :  std_logic;   

-- internal connectors signals (TX PATH to INTERCON)
-- master signals
signal ADR_O_M2_sig               :  std_logic_vector (Add_width_g-1 downto 0);           
signal DAT_O_M2_sig               :  std_logic_vector (data_width_g-1 downto 0);          
signal WE_O_M2_sig                :  std_logic;            
signal STB_O_M2_sig               :  std_logic;            
signal CYC_O_M2_sig               :  std_logic;            
signal TGA_O_M2_sig               :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);          
signal TGD_O_M2_sig               :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);         
signal ACK_I_M2_sig               :  std_logic;          
signal DAT_I_M2_sig               :  std_logic_vector (data_width_g-1 downto 0);          
signal STALL_I_M2_sig             :  std_logic;		
signal ERR_I_M2_sig               :  std_logic;	
-- slave signals
signal ADR_I_S2_sig               :  std_logic_vector (Add_width_g-1 downto 0);              
signal DAT_I_S2_sig               :  std_logic_vector (data_width_g-1 downto 0);        
signal WE_I_S2_sig                :  std_logic;        
signal STB_I_S2_sig               :  std_logic;           
signal CYC_I_S2_sig               :  std_logic;              				                     
signal TGA_I_S2_sig               :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);
signal TGD_I_S2_sig               :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);
signal ACK_O_S2_sig               :  std_logic;
signal DAT_O_S2_sig               :  std_logic_vector (data_width_g-1 downto 0);  
signal STALL_O_S2_sig             :  std_logic; 

-- internal connectors signals (OUTPUT BLOCK to INTERCON)
-- master signals
signal ADR_O_M3_sig               :  std_logic_vector (Add_width_g-1 downto 0);           
signal DAT_O_M3_sig               :  std_logic_vector (data_width_g-1 downto 0);          
signal WE_O_M3_sig                :  std_logic;            
signal STB_O_M3_sig               :  std_logic;            
signal CYC_O_M3_sig               :  std_logic;            
signal TGA_O_M3_sig               :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);          
signal TGD_O_M3_sig               :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);         
signal ACK_I_M3_sig               :  std_logic;          
signal DAT_I_M3_sig               :  std_logic_vector (data_width_g-1 downto 0);          
signal STALL_I_M3_sig             :  std_logic;		
signal ERR_I_M3_sig               :  std_logic;	
-- slave signals
signal ADR_I_S3_sig               :  std_logic_vector (Add_width_g-1 downto 0);              
signal DAT_I_S3_sig               :  std_logic_vector (data_width_g-1 downto 0);        
signal WE_I_S3_sig                :  std_logic;        
signal STB_I_S3_sig               :  std_logic;           
signal CYC_I_S3_sig               :  std_logic;              				                     
signal TGA_I_S3_sig               :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);
signal TGD_I_S3_sig               :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);
signal ACK_O_S3_sig               :  std_logic;
signal DAT_O_S3_sig               :  std_logic_vector (data_width_g-1 downto 0);  
signal STALL_O_S3_sig             :  std_logic; 

-- internal connectors signals (CORE to INTERCON)
-- slave signals
signal ADR_I_S5_sig               :  std_logic_vector (Add_width_g-1 downto 0);              
signal DAT_I_S5_sig               :  std_logic_vector (data_width_g-1 downto 0);        
signal WE_I_S5_sig                :  std_logic;        
signal STB_I_S5_sig               :  std_logic;           
signal CYC_I_S5_sig               :  std_logic;              				                     
signal TGA_I_S5_sig               :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);
signal TGD_I_S5_sig               :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);
signal ACK_O_S5_sig               :  std_logic;
signal DAT_O_S5_sig               :  std_logic_vector (data_width_g-1 downto 0);  
signal STALL_O_S5_sig             :  std_logic;   

-- internal connectors signals (SIGNAL GENERATOR to INTERCON)
-- slave signals
signal ADR_I_S4_sig               :  std_logic_vector (Add_width_g-1 downto 0);              
signal DAT_I_S4_sig               :  std_logic_vector (data_width_g-1 downto 0);        
signal WE_I_S4_sig                :  std_logic;        
signal STB_I_S4_sig               :  std_logic;           
signal CYC_I_S4_sig               :  std_logic;              				                     
signal TGA_I_S4_sig               :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);
signal TGD_I_S4_sig               :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);
signal ACK_O_S4_sig               :  std_logic;
signal DAT_O_S4_sig               :  std_logic_vector (data_width_g-1 downto 0);  
signal STALL_O_S4_sig             :  std_logic; 

-- internal connectors signals (SIGNAL GENERATOR to CORE)
signal trigger_sig				  :  std_logic ;
signal data_in_sig        		  :  std_logic_vector (num_of_signals_g - 1 downto 0) ;    
--signal rc_finish_s				  :	 std_logic;
-- internal connectors signals (CORE to OUTPUT_BLOCK)
signal wm_end_sig				  :  std_logic;
signal ADR_O_sig               	  :  std_logic_vector (Add_width_g-1 downto 0);           
signal DAT_O_sig               	  :  std_logic_vector (data_width_g-1 downto 0);          
signal WE_O_sig                	  :  std_logic;            
signal STB_O_sig               	  :  std_logic;            
signal CYC_O_sig               	  :  std_logic;            
signal TGA_O_sig               	  :  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);          
signal TGD_O_sig               	  :  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);         
signal ACK_I_sig               	  :  std_logic;          
signal DAT_I_sig               	  :  std_logic_vector (data_width_g-1 downto 0);          
signal STALL_I_sig             	  :  std_logic;		
signal ERR_I_sig               	  :  std_logic;	

-- data output (UART)
signal uart_out_sig               :  std_logic ;


--------------------- C O N S T A N T S --------------------------------------------------------------------------------------------------------------------------------------------

constant zero_bit_c                  : std_logic := '0';
constant zero_vector_ADR_c           : std_logic_vector (Add_width_g-1 downto 0) 	:= (others => '0'); 
constant zero_vector_DAT_c           : std_logic_vector (data_width_g-1 downto 0)              	:= (others => '0'); 
constant zero_vector_TGA_c           : std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0) 	:= (others => '0'); 
constant zero_vector_TGD_c           : std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0) 	:= (others => '0');
constant zero_vector_DATA_IN_c       : std_logic_vector (num_of_signals_g-1 downto 0) 			:= (others => '0');

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ 
--------------------  P O R T    M A P   A R E A  ---------------------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
  
  begin
    

rx_path_unit: rx_path
   GENERIC MAP (
		-- mutual generics
		reset_polarity_g          	=>	reset_polarity_g,
		data_width_g              	=>	data_width_g,	   
		clkrate_g                 	=>	clkrate_g,		     	     
		--uart_rx generics
		parity_en_g					=>	parity_en_g,	    
		parity_odd_g	          	=> 	parity_odd_g,		   
		uart_idle_g		            =>	uart_idle_g,
		baudrate_g			        =>	baudrate_g,
		--mp_dec generics
		len_dec1_g	               	=> 	len_dec1_g,
		sof_d_g				        => 	sof_d_g,	
		type_d_g		 	        =>	type_d_g,
		Add_width_g		      	    => 	Add_width_g,	
		len_d_g				        =>	len_d_g,   
		crc_d_g				        => 	crc_d_g,	 
		eof_d_g			 	        => 	eof_d_g,						
		sof_val_g			        => 	sof_val_g,	
		eof_val_g			        =>	eof_val_g, 		
		--ram_simple_generics
		addr_bits_g		           	=> 	rx_path_addr_bits_g, 	   
		--error_register_generics
		error_register_address_g  	=> 	error_register_address_g,     
		led_active_polarity_g     	=> 	led_active_polarity_g,       
		error_active_polarity_g   	=> 	error_active_polarity_g,     
		code_version_g			    => 	code_version_g   	
           )
   PORT MAP( 
		sys_clk 		         	=>	clk, 
		sys_reset 		            => 	reset,   
		rx_din      		        => 	rx_din_sig,
		error_led_out 		        => 	error_led_out_sig, 
		flash_error 		        => 	zero_bit_c,  
		--Wishbone Master interface
		ADR_O    		            => 	ADR_O_M1_sig,      
		DAT_O     		            => 	DAT_O_M1_sig,      
		WE_O           	           	=> 	WE_O_M1_sig,
		STB_O         	            => 	STB_O_M1_sig,
		CYC_O      		            => 	CYC_O_M1_sig,     
		TGA_O       	            => 	TGA_O_M1_sig, 
		TGD_O      		            => 	TGD_O_M1_sig,   
		ACK_I       	            => 	ACK_I_M1_sig,                    
		DAT_I       	            => 	DAT_I_M1_sig, 
		STALL_I		   		        => 	STALL_I_M1_sig,
		ERR_I			    		=> 	ERR_I_M1_sig,  
		--Wishbone Slave interface
		ADR_I               		=> ADR_I_S1_sig,           
--        DAT_I              		 	=> DAT_I_S1_sig,           
        WE_I                		=> WE_I_S1_sig,           
        STB_I              	 		=> STB_I_S1_sig,                               				                       
        CYC_I               		=> CYC_I_S1_sig,                               				                     
        TGA_I               		=> TGA_I_S1_sig,          
        TGD_I               		=> TGD_I_S1_sig,           
        ACK_O               		=> ACK_O_S1_sig,                       				                     
        WS_DAT_O               		=> DAT_O_S1_sig,           	            
	    STALL_O		     			=> STALL_O_S1_sig 
       );    
     
    
  
intercon: wishbone_intercon 
  GENERIC MAP (
    reset_activity_polarity_g  => reset_polarity_g,
    data_width_g               => data_width_g,                
    type_d_g                   => type_d_g, 			              
	Add_width_g                => Add_width_g, 			               
    len_d_g                    => len_d_g, 				               
	type_slave_1_g             => type_slave_1_g,            
    type_slave_2_g             => type_slave_2_g,               
    type_slave_3_g             => type_slave_3_g,            
    type_slave_4_g             => type_slave_4_g,              
    type_slave_5_g             => type_slave_5_g,             
    type_slave_6_g             => type_slave_6_g,             
    type_slave_7_g             => type_slave_7_g,              
	--timer generics
	watchdog_timer_freq_g      => watchdog_timer_freq_g,    
    clk_freq_g                 => clkrate_g,                    
    timer_en_polarity_g        => timer_en_polarity_g,        
	watchdog_en_vector_g       => watchdog_en_vector_g	       
           )
  PORT MAP(  
     sys_clk                   => clk,        
     sys_reset                 => reset,         
     --Wishbone Master 1 interfaces (rx_path)
     ADR_O_M1                  => ADR_O_M1_sig,           
     DAT_O_M1                  => DAT_O_M1_sig,          
     WE_O_M1                   => WE_O_M1_sig,            
     STB_O_M1                  => STB_O_M1_sig,            
     CYC_O_M1                  => CYC_O_M1_sig,            
     TGA_O_M1                  => TGA_O_M1_sig,          
     TGD_O_M1                  => TGD_O_M1_sig,         
     ACK_I_M1                  => ACK_I_M1_sig,          
     DAT_I_M1                  => DAT_I_M1_sig,          
	 STALL_I_M1                => STALL_I_M1_sig,		      
	 ERR_I_M1                  => ERR_I_M1_sig,	        
    --Wishbone Master 2 interfaces (tx path)
     ADR_O_M2                  => ADR_O_M2_sig,          
     DAT_O_M2                  => DAT_O_M2_sig,          
     WE_O_M2                   => WE_O_M2_sig,           
     STB_O_M2                  => STB_O_M2_sig,          
     CYC_O_M2                  => CYC_O_M2_sig,          
     TGA_O_M2                  => TGA_O_M2_sig,          
     TGD_O_M2                  => TGD_O_M2_sig,                          
     ACK_I_M2                  => ACK_I_M2_sig,         
     DAT_I_M2                  => DAT_I_M2_sig,          
	 STALL_I_M2                => STALL_I_M2_sig,		      
	 ERR_I_M2                  => ERR_I_M2_sig,		        
     --Wishbone Master 3 interfaces (output block) 
     ADR_O_M3                  => ADR_O_M3_sig,          
     DAT_O_M3                  => DAT_O_M3_sig,         
     WE_O_M3                   => WE_O_M3_sig,          
     STB_O_M3                  => STB_O_M3_sig,         
     CYC_O_M3                  => CYC_O_M3_sig,          
     TGA_O_M3                  => TGA_O_M3_sig,          
     TGD_O_M3                  => TGD_O_M3_sig,          
     ACK_I_M3                  => ACK_I_M3_sig,          
     DAT_I_M3                  => DAT_I_M3_sig,          
  	 STALL_I_M3                => STALL_I_M3_sig,		      
	 ERR_I_M3                  => ERR_I_M3_sig,	
	 --Wishbone Slave 1 interfaces (rx_path)
     ADR_I_S1                  => ADR_I_S1_sig, 
--     DAT_I_S1                  => DAT_I_S1_sig,          
     WE_I_S1                   => WE_I_S1_sig,          
     STB_I_S1                  => STB_I_S1_sig,       
     CYC_I_S1                  => CYC_I_S1_sig,        
     TGA_I_S1                  => TGA_I_S1_sig,          
     TGD_I_S1                  => TGD_I_S1_sig,          
     ACK_O_S1                  => ACK_O_S1_sig,           
     DAT_O_S1                  => DAT_O_S1_sig,          
	 STALL_O_S1                => STALL_O_S1_sig,       
     --Wishbone Slave 2 interfaces (tx_path) 
     ADR_I_S2                  => ADR_I_S2_sig,          
     DAT_I_S2                  => DAT_I_S2_sig,           
     WE_I_S2                   => WE_I_S2_sig,            
     STB_I_S2                  => STB_I_S2_sig,           
     CYC_I_S2                  => CYC_I_S2_sig,           
     TGA_I_S2                  => TGA_I_S2_sig,           
     TGD_I_S2                  => TGD_I_S2_sig,           
     ACK_O_S2                  => ACK_O_S2_sig,            
     DAT_O_S2                  => DAT_O_S2_sig,          
   	 STALL_O_S2                => STALL_O_S2_sig,         
     --Wishbone Slave 3 interfaces (output block) 
     ADR_I_S3                  => ADR_I_S3_sig,          
     DAT_I_S3                  => DAT_I_S3_sig,           
     WE_I_S3                   => WE_I_S3_sig,            
     STB_I_S3                  => STB_I_S3_sig,           
     CYC_I_S3                  => CYC_I_S3_sig,           
     TGA_I_S3                  => TGA_I_S3_sig,           
     TGD_I_S3                  => TGD_I_S3_sig,           
     ACK_O_S3                  => ACK_O_S3_sig,            
     DAT_O_S3                  => DAT_O_S3_sig,          
   	 STALL_O_S3                => STALL_O_S3_sig,   	 
 	   --Wishbone Slave 4 interfaces (SIGNAL GENERATOR) 
     ADR_I_S4                  => ADR_I_S4_sig,
     DAT_I_S4                  => DAT_I_S4_sig,     
     WE_I_S4                   => WE_I_S4_sig,      
     STB_I_S4                  => STB_I_S4_sig,      
     CYC_I_S4                  => CYC_I_S4_sig,
     TGA_I_S4                  => TGA_I_S4_sig,           
     TGD_I_S4                  => TGD_I_S4_sig,           
     ACK_O_S4                  => ACK_O_S4_sig,            
     DAT_O_S4                  => DAT_O_S4_sig,          
   	 STALL_O_S4                => STALL_O_S4_sig,  
     --Wishbone Slave 5 interfaces (CORE) 
     ADR_I_S5                  => ADR_I_S5_sig,
     DAT_I_S5                  => DAT_I_S5_sig,     
     WE_I_S5                   => WE_I_S5_sig,      
     STB_I_S5                  => STB_I_S5_sig,      
     CYC_I_S5                  => CYC_I_S5_sig,
     TGA_I_S5                  => TGA_I_S5_sig,           
     TGD_I_S5                  => TGD_I_S5_sig,           
     ACK_O_S5                  => ACK_O_S5_sig,            
     DAT_O_S5                  => DAT_O_S5_sig,          
   	 STALL_O_S5                => STALL_O_S5_sig,
     --Wishbone Slave 6 interfaces (NOT in use) 
     ADR_I_S6                  => open,
     DAT_I_S6                  => open,           
     WE_I_S6                   => open,            
     STB_I_S6                  => open,           
     CYC_I_S6                  => open,           
     TGA_I_S6                  => open,           
     TGD_I_S6                  => open,           
     ACK_O_S6                  => zero_bit_c,            
     DAT_O_S6                  => zero_vector_DAT_c,          
   	 STALL_O_S6                => zero_bit_c,  
     --Wishbone Slave 7 interface (NOT in use)
     ADR_I_S7                  => open,          
     DAT_I_S7                  => open,           
     WE_I_S7                   => open,            
     STB_I_S7                  => open,           
     CYC_I_S7                  => open,           
     TGA_I_S7                  => open,           
     TGD_I_S7                  => open,           
     ACK_O_S7                  => zero_bit_c,            
     DAT_O_S7                  => zero_vector_DAT_c,          
   	 STALL_O_S7                => zero_bit_c  
 );
      	  
core_inst: internal_logic_analyzer_core_top 
    GENERIC MAP (
		reset_polarity_g		=>	reset_polarity_g,
		enable_polarity_g		=>	enable_polarity_g,
		signal_ram_depth_g		=>	signal_ram_depth_g,
		signal_ram_width_g		=>	signal_ram_width_g,
		record_depth_g			=>	record_depth_g,
		data_width_g            =>	data_width_g,
		Add_width_g  		    =>	Add_width_g,
		num_of_signals_g		=>	num_of_signals_g,
		en_reg_address_g      		   		=>	en_reg_address_g,
		trigger_type_reg_1_address_g 		=>	trigger_type_reg_1_address_g,
		trigger_position_reg_2_address_g	=>	trigger_position_reg_2_address_g,
		clk_to_start_reg_3_address_g 	   	=>	clk_to_start_reg_3_address_g,
		enable_reg_address_4_g 		   		=>	enable_reg_address_4_g,
		power2_out_g			=>	power2_out_g,
		power_sign_g			=>	power_sign_g,
		type_d_g				=>	type_d_g,
		len_d_g					=>	len_d_g
        )
    PORT MAP(  
        clk			        => 	clk,
        rst			        => 	reset,               		
	   -- WISHBONE slave BUS interface
        ADR_I               => 	ADR_I_S5_sig,              
        DAT_I               => 	DAT_I_S5_sig,           
        WE_I                => 	WE_I_S5_sig,             
        STB_I               => 	STB_I_S5_sig,               
        CYC_I               => 	CYC_I_S5_sig,                  				                     
        TGA_I               => 	TGA_I_S5_sig,
        TGD_I               => 	TGD_I_S5_sig,
        ACK_O               => 	ACK_O_S5_sig,
        WS_DAT_O            => 	DAT_O_S5_sig,
	    STALL_O		        => 	STALL_O_S5_sig,
		-- DATA TO OUTPUT BLOCK (WISHBONE master BUS interface)
	    ADR_O    		    => 	ADR_O_sig,      
		WM_DAT_O   		    => 	DAT_O_sig,      
		WE_O           	    => 	WE_O_sig,
		STB_O         	    => 	STB_O_sig,
		CYC_O      		    =>	CYC_O_sig,     
		TGA_O       	    => 	TGA_O_sig, 
		TGD_O      		    => 	TGD_O_sig,   
		ACK_I       	    => 	ACK_I_sig,                    
		DAT_I_WM       	    => 	DAT_I_sig, 
		STALL_I		   		=> 	STALL_I_sig,
		ERR_I			    => 	zero_bit_c,                                           
		-- SIGNAL GENERATOR to CORE interface
		data_in				=>	data_in_sig,
		trigger				=>	trigger_sig,
		-- WISHBONE MASTER control unit signals
--		TOP_active_cycle	=>	open,
--		stall				=>	zero_bit_c,
		wm_end_out			=>	wm_end_sig
	  );
   
signal_generator_inst: signal_generator_top 
    GENERIC MAP (
		reset_polarity_g	=>	reset_polarity_g,
		enable_polarity_g	=>	enable_polarity_g,
		data_width_g        =>	data_width_g,
		num_of_signals_g	=>	num_of_signals_g,
		external_en_g		=>	external_en_g,
		Add_width_g    		=>	Add_width_g,
		len_d_g				=>	len_d_g,
		type_d_g			=>	type_d_g,
		scene_number_reg_1_address_g	=>	scene_number_reg_1_address_g,
		enable_reg_address_2_g			=>	enable_reg_address_2_g
		
        )        
    PORT MAP(  
        clk					=> 	clk,   	
        reset				=> 	reset,                  		
		-----signal generator signals
		data_in				=>	zero_vector_DATA_IN_c,
		trigger_in			=>	zero_bit_c,
		data_out			=>	data_in_sig,
		trigger_out			=>	trigger_sig,
		-- WISHBONE slave BUS interface
        ADR_I               => 	ADR_I_S4_sig,              
        DAT_I               => 	DAT_I_S4_sig,           
        WE_I                => 	WE_I_S4_sig,             
        STB_I               => 	STB_I_S4_sig,               
        CYC_I               => 	CYC_I_S4_sig,                  				                     
        TGA_I               => 	TGA_I_S4_sig,
        TGD_I               => 	TGD_I_S4_sig,
        ACK_O               => 	ACK_O_S4_sig,
        DAT_O               => 	DAT_O_S4_sig,
	    STALL_O		        => 	STALL_O_S4_sig,
		--register side signals
		rc_finish			=> 	wm_end_sig
--		typ					=>	open,
--		len					=>	open,
--		reg_data       		=>	zero_vector_DAT_c,
--		reg_data_valid 		=>	zero_bit_c,
--		active_cycle		=>	open,
--		stall				=>	zero_bit_c
        ); 

output_block_unit: output_block 
    GENERIC MAP (
		reset_polarity_g	=> reset_polarity_g,                                           
		byte_size_g			=> byte_size_g,       				
		data_width_g        => data_width_g,                   
		-- FIFO generics 
        fifo_depth_g 		=> fifo_depth_g,  
		fifo_log_depth_g	=> fifo_log_depth_g,  
		fifo_almost_full_g	=> fifo_almost_full_g,	  
		fifo_almost_empty_g =>	fifo_almost_empty_g, 	 			
		-- WISHBONE slave generics
--	    addr_d_g			=> addr_d_g,        
	    len_d_g				=> len_d_g,       
	    type_d_g			=> type_d_g,
		-- WISHBONE master generics
	    addr_bits_g			=> tx_path_addr_bits_g	,
	    -- block and client hand-shake          
	    baudrate_g			=> baudrate_g ,
	    clkrate_g		 	=> clkrate_g ,
	    databits_g			=> databits_g ,
	    parity_en_g         => parity_en_g ,
	    tx_fifo_d_g         => fifo_d_g  	    -- gets the RX path FIFO usage       	             
		)
    PORT MAP( 
        clk			        => clk,        
        reset			    => reset,         
        -- data provider side (compressor core)
--        data_in             => data_out_sig,          
--        data_in_valid       => data_out_valid_sig,          	
--        lzrw3_done          => lzrw3_done_sig,                                             
--        client_ready        => client_ready_sig,          
        -- data input side (compatible to WB SLAVE)
		wm_end_2			=> wm_end_sig,
		ADR_I_2             => ADR_O_sig,
        DAT_I_2             => DAT_O_sig,
        WE_I_2              => WE_O_sig,
        STB_I_2             => STB_O_sig,
        CYC_I_2             => CYC_O_sig,
        TGA_I_2             => TGA_O_sig,
        TGD_I_2             => TGD_O_sig,
        ACK_O_2             => ACK_I_sig,
        DAT_O_2             => DAT_I_sig,
	    STALL_O_2		    => STALL_I_sig,
		-- wishbone master BUS side
        ADR_O		        => ADR_O_M3_sig, 	        
        WM_DAT_O			=> DAT_O_M3_sig,         
        WE_O			    => WE_O_M3_sig,       
        STB_O			    => STB_O_M3_sig,                                        
        CYC_O			    => CYC_O_M3_sig,                                               
        TGA_O			    => TGA_O_M3_sig,          
        TGD_O			    => TGD_O_M3_sig,        
        ACK_I			    => ACK_I_M3_sig,         
        WM_DAT_I		    => DAT_I_M3_sig,         
	    STALL_I			    => STALL_I_M3_sig,                                                   
	    ERR_I		        => ERR_I_M3_sig,                                      
        -- wishbone slave BUS side
        ADR_I               => ADR_I_S3_sig,           
        DAT_I               => DAT_I_S3_sig,           
        WE_I                => WE_I_S3_sig,           
        STB_I               => STB_I_S3_sig,                               				                       
        CYC_I               => CYC_I_S3_sig,                               				                     
        TGA_I               => TGA_I_S3_sig,          
        TGD_I               => TGD_I_S3_sig,           
        ACK_O               => ACK_O_S3_sig,                       				                     
        DAT_O               => DAT_O_S3_sig,           	            
	    STALL_O		     	=> STALL_O_S3_sig                   	 	
        );
		
tx_path_unit: tx_path  
    GENERIC MAP (
	    reset_polarity_g	=> 	reset_polarity_g,
	    data_width_g	   	=> 	data_width_g,		        		        		
	    Add_width_g			=> 	Add_width_g, 
		len_d_g				=> 	len_d_g, 
		type_d_g			=> 	type_d_g,   
	    fifo_d_g			=> 	fifo_d_g,  
	    addr_bits_g		   	=> 	tx_path_addr_bits_g,     
	    parity_en_g			=> 	parity_en_g, 
	    parity_odd_g		=> 	parity_odd_g,  
	    uart_idle_g			=> 	uart_idle_g, 
	    baudrate_g			=> 	baudrate_g,
	    clkrate_g			=> 	clkrate_g,  
	    databits_g			=> 	databits_g 
      )		
    PORT MAP( 
	    sys_clk 			=> 	clk,
	    sys_reset 			=> 	reset,
	    -- input and output to TX PATH SLAVE
	    DAT_I_S			  	=> 	DAT_I_S2_sig,
	    ADR_I_S_TX			=> 	ADR_I_S2_sig, 
	    TGA_I_S_TX			=> 	TGA_I_S2_sig,
	    TGD_I_S_TX			=> 	TGD_I_S2_sig,
	    WE_I_S_TX			=> 	WE_I_S2_sig,
	    STB_I_S_TX			=> 	STB_I_S2_sig,
	    CYC_I_S_TX			=> 	CYC_I_S2_sig,
	    ACK_O_TO_M			=> 	ACK_O_S2_sig,
	    DAT_O_TO_M			=> 	DAT_O_S2_sig,
	    STALL_O_TO_M		=> 	STALL_O_S2_sig,	   	     
	    -- input and output to TX PATH MASTER  
	    DAT_I_CLIENT		=> 	DAT_I_M2_sig, 
	    ACK_I_CLIENT		=> 	ACK_I_M2_sig,
	    STALL_I_CLIENT	  	=> 	STALL_I_M2_sig,
	    ERR_I_CLIENT		=> 	ERR_I_M2_sig,
	    ADR_O_CLIENT 		=> 	ADR_O_M2_sig,      
		DAT_O_CLIENT     	=> 	DAT_O_M2_sig,
		WE_O_CLIENT     	=> 	WE_O_M2_sig,
		STB_O_CLIENT    	=> 	STB_O_M2_sig,
		CYC_O_CLIENT     	=> 	CYC_O_M2_sig,
		TGA_O_CLIENT     	=> 	TGA_O_M2_sig,
		TGD_O_CLIENT		=> 	TGD_O_M2_sig,
		-- UART OUTPUT
	    uart_out		    => 	uart_out_sig
    );

--------------------- PROCESSES --------------------------------------------------------------------------------------------------------------------------------------------
 
	-- interface to computer
	-- (TOP input)         
	rx_din_sig    	<= 	rx_din ; -- UART data IN (framed, raw) 
	-- (TOP output)	 
	tx_dout        	<= 	uart_out_sig  ;-- UART data OUT (framed, compressed)
	-- receive success without error (when off)
	error_led_out  	<= 	error_led_out_sig ;	
      
end architecture arc_top_internal_logic_analyzer;