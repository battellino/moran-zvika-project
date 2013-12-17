---------------------------------------------------------------------------------------------------------------
--
-- Title       : TOP_REL_3 Testbench
-- Design      : Lzrw3 compression core
-- Author      : Shahar Zuta & Netanel Yamin
-- Company     : Technion High Speed Digital Systems Lab
--
---------------------------------------------------------------------------------------------------------------
--
-- File        : VHDL\DESIGN\TOP\TOP_REL_3\up_to_date\TOP_REL_3_TB.vhd 
-- Generated   : 10.07.2013
--
---------------------------------------------------------------------------------------------------------------
--
-- Description :
--  this file inject data to TOP_REL_3 (rx_path side- UART serial data in ) and recive data from TX PATH UART side
--
--
--
---------------------------------------------------------------------------------------------------------------
--
-- Revision History :     Revision Number        Date         Description                                       
--                        1.0                    10.07.2013   Generated   
--
--
---------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all ;
use ieee.math_real.all;

-- text file handlers part
use ieee.std_logic_textio.all;
library std;
use std.textio.all;
--------------------

-- entity declaration for testbench


  ENTITY top_internal_logic_analyzer_TB is
    generic (
		reset_polarity_g	    		: std_logic := '1';	                				-- '0' - Active Low Reset, '1' Active High Reset.
		enable_polarity_g				: std_logic	:= '1';									--'1' the entity is active, '0' entity not active
	    byte_size_g			           	: positive  := 8  ;                 				-- bits size of the sent comparison bytes.
		-- core generics
	    signal_ram_depth_g				: positive  :=	3;									--depth of RAM
		signal_ram_width_g				: positive 	:=  8;   								--width of basic RAM
		record_depth_g					: positive  :=	6;									--number of bits that is recorded from each signal
		data_width_g            		: positive 	:= 	8;      						    --defines the width of the data lines of the system
		Add_width_g  		    		: positive 	:=  8;     								--width of address word in the WB
		num_of_signals_g				: positive	:=	8;									--number of signals that will be recorded simultaneously	(Width of data)
		en_reg_address_g      		   		: 	natural 	:= 0;
		trigger_type_reg_1_address_g 		: 	natural 	:= 1;
		trigger_position_reg_2_address_g	: 	natural 	:= 2;
		clk_to_start_reg_3_address_g 	   	: 	natural 	:= 3;
		enable_reg_address_4_g 		   		: 	natural 	:= 4;
		power2_out_g					: natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
		power_sign_g					: integer range -1 to 1 	:= 1;					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
		type_d_g						: positive 	:= 	1;									--Type Depth
		len_d_g							: positive 	:= 	1;									--Length Depth
		-- signal generator generics   
		external_en_g					: std_logic	:= 	'0';								-- 1 -> getting the data from an external source . 0 -> dout is a counter
		scene_number_reg_1_address_g 	: natural 	:= 1;
		enable_reg_address_2_g 		   	: natural 	:= 2;
--      -- OUTPUT BLOCK generics
        fifo_depth_g 			      	: positive 	:= 32768;	         -- Maximum elements in FIFO
	    fifo_log_depth_g			   	: natural	:= 15;	            -- (2^25 = 32K) Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
	    fifo_almost_full_g		  		: positive	:= 32767;   	      -- Rise almost full flag at this number of elements in FIFO
	    fifo_almost_empty_g	 			: positive	:= 1;	             -- Rise almost empty flag at this number of elements in FIFO				    
		--  RX PATH (and UART) generics
		clkrate_g		     			: positive	:= 50000000;		                -- Sys. clock [Hz]      
--		addr_d_g		      			: positive  := 3;		            -- Address Depth
	   --uart_rx generics
		parity_en_g		    			: natural range 0 to 1 := 0; 		             -- 1 to Enable parity bit, 0 to disable parity bit
		parity_odd_g		   			: boolean 	:= false; 			                  -- TRUE = odd, FALSE = even
		uart_idle_g		    			: std_logic := '1';				                    -- IDLE_ST line value
		baudrate_g			    		: positive	:= 115200;			                  -- UART baudrate [Hz]
		--mp_dec generics
		len_dec1_g	     				: boolean   := true;	                      -- TRUE - Recieved length is decreased by 1 ,to save 1 bit  --FALSE - Recieved length is the actual length
		sof_d_g				      		: positive  := 1;		                        -- SOF Depth
		crc_d_g				      		: positive  := 1;		                        -- CRC Depth
		eof_d_g			 	     		: positive  := 1;		                        -- EOF Depth					
		sof_val_g			     		: natural   := 60;	                       	-- (3Ch) SOF block value. Upper block is MSB
		eof_val_g			     		: natural   := 165;		                      -- (A5h) EOF block value. Upper block is MSB				
		--ram_simple_generics
		rx_path_addr_bits_g		        : positive  := 8;            -- Depth of data	(2^10 = 1024 addresses)  
		--error_register_generics
		error_register_address_g       	: natural   :=0 ;            -- defines the address that should be sent on access to the unit
		led_active_polarity_g          	: std_logic :='1';           -- defines the active state of the error signal input: '0' active low, '1' active high
		error_active_polarity_g        	: std_logic :='1';           -- defines the polarity which the error signal is active in  
		code_version_g			        : natural	:= 0	;           -- Hardware code version
		--  TX PATH generics				
		fifo_d_g				        : positive	:= 9;	           -- Maximum elements in FIFO
		tx_path_addr_bits_g		        : positive  := 8;           	-- Depth of data	(2^10 = 1024 addresses)    
		databits_g				        : natural range 5 to 8 := 8;  	-- Number of databits								
		-- WISHBONE INTERCON generics      
        type_slave_1_g             		: std_logic_vector  := "0001";     -- slave 1 type
        type_slave_2_g             		: std_logic_vector  := "0010";     -- slave 2 type
        type_slave_3_g             		: std_logic_vector  := "0011";     -- slave 3 type
        type_slave_4_g             		: std_logic_vector  := "0100";     -- slave 4 type
        type_slave_5_g             		: std_logic_vector  := "0101";     -- slave 5 type
        type_slave_6_g             		: std_logic_vector  := "0110";     -- slave 6 type
        type_slave_7_g             		: std_logic_vector  := "0111";     -- slave 7 type
	    --timer generics
	    watchdog_timer_freq_g      		: positive         := 100;         -- timer tick after (clk_freq_g/watchdog_timer_freq_g) ==> 10msec
        timer_en_polarity_g        		: std_logic        := '1';         -- defines the polarity which the timer enable (timer_en) is active on: '0' active low, '1' active high  
	    watchdog_en_vector_g	      	: std_logic_vector := "11111111";  -- watchdog enabled for the clients which have '1' on their matching bit in the vector
		---------------------------------------------------------------------------------------------------------------
		-- UART TX GEN MODEL generics
		file_name_g			            : string           := "uart_tx"; -- File name to be transmitted
		file_extension_g	          	: string		   := "txt";			  -- File extension
		file_max_idx_g	           		: positive	       := 1;				     -- Maximum file index.
		delay_g				            : positive	       := 10;				    -- Number of clock cycles delay between two files transmission			 
		clock_period_g		           	: time		       := 8.68 us;			-- 8.68us = 115,200 Bits/sec
        msb_first_g			            : boolean 	       := false  		 	-- TRUE = MSB First, FALSE = LSB first				
        );
END top_internal_logic_analyzer_TB;    



ARCHITECTURE behavior OF top_internal_logic_analyzer_TB IS
   -- Component Declaration for the Unit Under Test (UUT)
       
       
  COMPONENT top_internal_logic_analyzer is 
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
		en_reg_address_g      		   		: 	natural 	:= 0;
		trigger_type_reg_1_address_g 		: 	natural 	:= 1;
		trigger_position_reg_2_address_g	: 	natural 	:= 2;
		clk_to_start_reg_3_address_g 	   	: 	natural 	:= 3;
		enable_reg_address_4_g 		   		: 	natural 	:= 4;
		power2_out_g					: natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
		power_sign_g					: integer range -1 to 1 	:= 1;					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
		type_d_g						: positive 	:= 	1;									--Type Depth
		len_d_g							: positive 	:= 	1;									--Length Depth
		-- signal generator generics   
		external_en_g					: std_logic	:= 	'0';								-- 1 -> getting the data from an external source . 0 -> dout is a counter
		scene_number_reg_1_address_g 	: natural 	:= 1;
		enable_reg_address_2_g 		   	: natural 	:= 2;
--      -- OUTPUT BLOCK generics
        fifo_depth_g 			      	: positive 	:= 32768;	         -- Maximum elements in FIFO
	    fifo_log_depth_g			   	: natural	:= 15;	            -- (2^25 = 32K) Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
	    fifo_almost_full_g		  		: positive	:= 32767;   	      -- Rise almost full flag at this number of elements in FIFO
	    fifo_almost_empty_g	 			: positive	:= 1;	             -- Rise almost empty flag at this number of elements in FIFO				    
		--  RX PATH (and UART) generics
		clkrate_g		     			: positive	:= 125000000;		                -- Sys. clock [Hz]      
--		addr_d_g		      			: positive  := 3;		            -- Address Depth
	   --uart_rx generics
		parity_en_g		    			: natural range 0 to 1 := 0; 		             -- 1 to Enable parity bit, 0 to disable parity bit
		parity_odd_g		   			: boolean 	:= false; 			                  -- TRUE = odd, FALSE = even
		uart_idle_g		    			: std_logic := '1';				                    -- IDLE_ST line value
		baudrate_g			    		: positive	:= 115200;			                  -- UART baudrate [Hz]
		--mp_dec generics
		len_dec1_g	     				: boolean   := true;	                      -- TRUE - Recieved length is decreased by 1 ,to save 1 bit  --FALSE - Recieved length is the actual length
		sof_d_g				      		: positive  := 1;		                        -- SOF Depth
		crc_d_g				      		: positive  := 1;		                        -- CRC Depth
		eof_d_g			 	     		: positive  := 1;		                        -- EOF Depth					
		sof_val_g			     		: natural   := 60;	                       	-- (3Ch) SOF block value. Upper block is MSB
		eof_val_g			     		: natural   := 165;		                      -- (A5h) EOF block value. Upper block is MSB				
		--ram_simple_generics
		rx_path_addr_bits_g		        : positive  := 8;            -- Depth of data	(2^10 = 1024 addresses)  
		--error_register_generics
		error_register_address_g       	: natural   :=0 ;            -- defines the address that should be sent on access to the unit
		led_active_polarity_g          	: std_logic :='1';           -- defines the active state of the error signal input: '0' active low, '1' active high
		error_active_polarity_g        	: std_logic :='1';           -- defines the polarity which the error signal is active in  
		code_version_g			        : natural	:= 0	;           -- Hardware code version
		--  TX PATH generics				
		fifo_d_g				        : positive	:= 9;	           -- Maximum elements in FIFO
		tx_path_addr_bits_g		        : positive  := 8;           	-- Depth of data	(2^10 = 1024 addresses)    
		databits_g				        : natural range 5 to 8 := 8;  	-- Number of databits								
		-- WISHBONE INTERCON generics      
        type_slave_1_g             		: std_logic_vector  := "0001";     -- slave 1 type
        type_slave_2_g             		: std_logic_vector  := "0010";     -- slave 2 type
        type_slave_3_g             		: std_logic_vector  := "0011";     -- slave 3 type
        type_slave_4_g             		: std_logic_vector  := "0100";     -- slave 4 type
        type_slave_5_g             		: std_logic_vector  := "0101";     -- slave 5 type
        type_slave_6_g             		: std_logic_vector  := "0110";     -- slave 6 type
        type_slave_7_g             		: std_logic_vector  := "0111";     -- slave 7 type
	    --timer generics
	    watchdog_timer_freq_g      		: positive         := 100;         -- timer tick after (clk_freq_g/watchdog_timer_freq_g) ==> 10msec
        timer_en_polarity_g        		: std_logic        := '1';         -- defines the polarity which the timer enable (timer_en) is active on: '0' active low, '1' active high  
	    watchdog_en_vector_g	      	: std_logic_vector := "11111111"   -- watchdog enabled for the clients which have '1' on their matching bit in the vector
        );
    port( 
          clk                 : in std_logic;                                                -- system clock
          reset               : in std_logic;                                                -- system reset
       -- uart interface        
          rx_din              : in std_logic;                                                -- input of UART data
       -- uart interface             
          tx_dout             : out std_logic;
       -- on board LED          
          error_led_out       : out std_logic                                                -- '1' when one of the error bits in the register is high          
        ); 
 END COMPONENT; 
 
 COMPONENT uart_tx_gen_model is 
    generic (
            --File name explanasion:
			-- File name is being named <file_name_g>_<file_idx>.<file_extension_g>
			-- i.e: uart_tx_1.txt, uart_tx_2.txt ....
			-- file_max_idx_g is the maximum index for files. For example: suppose this
			-- parameter is 2, then transmission file order will be:
			-- (1)uart_tx_1.txt (2)uart_tx_2.txt (3) uart_tx_1.txt (4) uart_tx_2.txt ...
			
			file_name_g			   	:		string 		:= "uart_tx"; 	    	-- File name to be transmitted
			file_extension_g		:		string		 := "txt";			        -- File extension
			file_max_idx_g	 		:		positive	:= 1;				           -- Maximum file index.
			delay_g				  	:		positive	:= 10;				          -- Number of clock cycles delay between two files transmission
			 
			clock_period_g	  		:		time		     := 8.68 us;		     -- 8.68us = 115,200 Bits/sec
			parity_en_g			   	:		natural range 0 to 1 := 0; 		-- 1 to Enable parity bit, 0 to disable parity bit
			parity_odd_g		   	:		boolean 	  := false; 			     -- TRUE = odd, FALSE = even
			msb_first_g			   	:		boolean 	  := false; 			     -- TRUE = MSB First, FALSE = LSB first
			uart_idle_g			   	:		std_logic 	:= '1' 				       -- Idle line value
           );
 PORT
	   (
	     system_clk	:	in std_logic  ; 			                     	-- System clock, for Valid for one clock
		   uart_out	  :	out std_logic ;			                       -- Serial data out (UART)
		   value		    :	out std_logic_vector (7 downto 0) ;	     -- Transmitted value (For user convenience - to see the transmitted value)
		   valid		    :	out std_logic  			                       -- Valid value (8 bit) - Active for one clock (For Parallel data simulation)
	   );
 END COMPONENT;      
 
component uart_rx
   generic (
			 parity_en_g		    :		natural range 0 to 1 := 0; 	          	-- 1 to Enable parity bit, 0 to disable parity bit
			 parity_odd_g   		:		boolean 	  := false; 			               -- TRUE = odd, FALSE = even
			 uart_idle_g		    :		std_logic 	:= '1';				                 -- IDLE_ST line value
			 baudrate_g			    :		positive	  := 115200;		               	-- UART baudrate [Hz]
			 clkrate_g		     	:		positive	  := 133333333;		             -- Sys. clock [Hz]
			 databits_g			    :		natural range 5 to 8 := 8;		           -- Number of databits
			 reset_polarity_g		:		std_logic 	:= '0'	 			                 -- '0' = Active Low, '1' = Active High
           );
   port
   	   (
			 din				       :	in std_logic;				                               -- Serial data in
			 clk				       :	in std_logic;				                               -- Sys. clock
			 reset			     	:	in std_logic;				                               -- Reset
 			 dout			      	:	out std_logic_vector (databits_g - 1 downto 0); -- Parallel data out
			 valid				     :	out std_logic;				                              -- Parallel data valid
			 parity_err		 	:	out std_logic;			                              	-- parity error
			 stop_bit_err		:	out	std_logic			                               	-- Stop bit error
   	   );
	end component uart_rx;	   
	   
	    
 
 --******************************************************************************************
 --*******************************	CONSTANS	*********************************************
 --******************************************************************************************  
 -- Clock period definitions
 constant clk_period_c      : time := 20 ns; -- 50 Mhz     
 
--******************************************************************************************
 --*******************************	SIGNALS	*********************************************
 --****************************************************************************************** 
 -- Declare INPUT ports and initialize them
 -- mutual signals
 signal  clk			              :	 std_logic := '0' ;
 signal  reset			            :	 std_logic := '0' ;	 	

 -- Declare OUTPUT ports and initialize them (DUT RESULT)
 -- UART  side 
 signal  error_led_out       :  std_logic := '0' ;                      				                       
 
 -- Other signals 
 -- File handler signals (output)
 signal endoffile : bit := '0';
 signal linenumber : integer:=1;

 -- connectors signals   
 -- UART  gen to TOP REL 3   
 -- INPUT
 signal  din_sig             :  std_logic  ;
 -- OUTPUT
 signal  dout_sig            :  std_logic  ; 
 
 -- uart rx for TB output signals
 signal byte_out_sig         :  std_logic_vector (byte_size_g -1 downto 0);
 signal byte_out_valid_sig   :  std_logic  ;   
    
 

--******************************************************************************************
 --*******************************	INITIATIONS	*********************************************
 --****************************************************************************************** 
 
  BEGIN 
    
    
uut: top_internal_logic_analyzer 
    GENERIC MAP (
		reset_polarity_g            => reset_polarity_g,	        
		enable_polarity_g           => enable_polarity_g,        
		-- CORE generics
		signal_ram_depth_g          => signal_ram_depth_g,         
	    signal_ram_width_g          => signal_ram_width_g,                      
        record_depth_g         		=> record_depth_g,	     
        data_width_g           		=> data_width_g,      	
		Add_width_g                 => Add_width_g,      			           
		num_of_signals_g    		=> num_of_signals_g,
	    en_reg_address_g      		   		=>	en_reg_address_g,
		trigger_type_reg_1_address_g 		=>	trigger_type_reg_1_address_g,
		trigger_position_reg_2_address_g	=>	trigger_position_reg_2_address_g,
		clk_to_start_reg_3_address_g 	   	=>	clk_to_start_reg_3_address_g,
		enable_reg_address_4_g 		   		=>	enable_reg_address_4_g,
		power2_out_g               	=> power2_out_g,         
	    power_sign_g	        	=> power_sign_g,                   
		type_d_g       				=> type_d_g,			
		len_d_g      				=> len_d_g,			                      
		-- signal generator generics  
	    external_en_g			    => external_en_g,
		scene_number_reg_1_address_g => scene_number_reg_1_address_g,
		enable_reg_address_2_g 		=> enable_reg_address_2_g,
	    -- OUTPUT BLOCK generics
		fifo_depth_g				=> fifo_depth_g,	       
	    fifo_log_depth_g			=> fifo_log_depth_g,      
        fifo_almost_full_g			=> fifo_almost_full_g, 
		fifo_almost_empty_g			=> fifo_almost_empty_g, 		 
        --  RX PATH (and UART) generics
        clkrate_g 			     	=> clkrate_g,
		--uart_rx generics
		parity_en_g		            => parity_en_g,	
		parity_odd_g		        => parity_odd_g,	
		uart_idle_g		            => uart_idle_g,	
		baudrate_g			        => baudrate_g,	
		--mp_dec generics
		len_dec1_g	                =>	len_dec1_g,
		sof_d_g				        => sof_d_g,	
        crc_d_g				        => crc_d_g,	
		eof_d_g			 	     	=> eof_d_g,	
		sof_val_g			        => sof_val_g,	
		eof_val_g			     	=> eof_val_g,	
		--ram_simple_generics
		rx_path_addr_bits_g		    => rx_path_addr_bits_g,	        
		--error_register_generics
        error_register_address_g	=> error_register_address_g,	     
        led_active_polarity_g       => led_active_polarity_g,	        
        error_active_polarity_g     => error_active_polarity_g,	        
		code_version_g			    =>	code_version_g,            
		--  TX PATH generics				
	    fifo_d_g				    => fifo_d_g,
	    tx_path_addr_bits_g		    => tx_path_addr_bits_g, 	   
	    databits_g				    => databits_g,   						
      -- WISHBONE INTERCON generics      
        type_slave_1_g              => type_slave_1_g,	          
        type_slave_2_g              => type_slave_2_g,             
        type_slave_3_g              => type_slave_3_g,             
        type_slave_4_g              => type_slave_4_g,            
        type_slave_5_g              => type_slave_5_g,            
        type_slave_6_g              => type_slave_6_g,            
        type_slave_7_g              => type_slave_7_g,            
	    --timer generics
	    watchdog_timer_freq_g       => watchdog_timer_freq_g,     
        timer_en_polarity_g         => timer_en_polarity_g,       
	    watchdog_en_vector_g	    => watchdog_en_vector_g    		
        )
        
    PORT MAP( 
        clk                       	=> clk,         
        reset                     	=> reset,  
		-- uart interface         
        rx_din                    	=> din_sig,  
		-- uart interface    
	    tx_dout 		    	    => dout_sig,               
		-- on board LED          
        error_led_out             	=> error_led_out 

        );         

data_transmitter: uart_tx_gen_model
    GENERIC MAP (
		file_name_g			  		=> file_name_g,
		file_extension_g	        => file_extension_g,
		file_max_idx_g			    => file_max_idx_g,
		delay_g					  	=> delay_g,
		clock_period_g	 	        => clock_period_g,	
		parity_en_g			 	    => parity_en_g,
		parity_odd_g			    => parity_odd_g,
		msb_first_g			  	    => msb_first_g,
		uart_idle_g			   	    => uart_idle_g
       )
       
 PORT MAP (
		system_clk	    	       	=> clk, 
		uart_out	      	        => din_sig,
		value	           	    	=> open,
		valid		          		=> open
	   );
	   

uart_rx_tb_inst : uart_rx 
  generic map
    (
  		parity_en_g       			=> parity_en_g,
		parity_odd_g	     		=> parity_odd_g,
		uart_idle_g	     			=> uart_idle_g,
		baudrate_g		     		=> baudrate_g	,
		clkrate_g		      		=> clkrate_g,
		databits_g	     			=> data_width_g,
		reset_polarity_g	 		=> reset_polarity_g 
    )
  port map 
    (
		din		        			=> dout_sig,
		clk		       				=> clk,
		reset			     		=> reset,
 		dout				      	=> byte_out_sig, 
		valid			      		=> byte_out_valid_sig, 
		parity_err					=> open,
		stop_bit_err	 			=> open
    ); 
 	    
	   

--******************************************************************************************
 --*******************************	PROCESSES	*********************************************
 --******************************************************************************************     
   -- Clock process definitions, clock with 50% duty cycle is generated here
   -- Colck period defined to 8 ns.
   clk_process : process
     begin
       clk <= '0';
       wait for clk_period_c/2;  -- For 4 ns signal is '0'.
       clk <= '1';
       wait for clk_period_c/2;  -- For next 4 ns signal is '1'.
     end process clk_process;
 
 
  tester_proc: process 
  begin
    while (true) loop   
      wait for 10 ns ;
      reset <=  reset_polarity_g;              -- Start test with reset active  
      wait for 10 ns ;    
      reset <=  not reset_polarity_g; 
      while (true) loop
        wait for 10 ns ;
      end loop;
    end loop;
  end process; 
    
			
-- This process writes data out to the file only when data_out is valid 
writind_data_out_to_file_proc : process(reset, clk)
  file      outfile  : text is out "TOP_internal_logic_analyzer_OUT.txt";   -- declare the output file
  variable  outline  : line;                              -- line number declaration  
begin
  if rising_edge(clk) then
    if(byte_out_valid_sig = '1') then
      if(endoffile='0') then                 
        write(outline, to_integer(unsigned(byte_out_sig)));
        writeline(outfile, outline);
      else
        null;
      end if;
    end if;
  end if;
end process writind_data_out_to_file_proc;   
   

END ARCHITECTURE behavior;   

---------------------------------     			    
    