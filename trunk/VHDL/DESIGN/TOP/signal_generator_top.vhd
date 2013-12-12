------------------------------------------------------------------------------------------------
-- File Name	:	signal_generator_top.vhd
-- Generated	:	11.10.2013
-- Author		:	Moran katz & Zvika pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
-- 			Get the user chosen signals scene through the WBS and generate data out and trigger signals 
--			
--			 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date			Name							Description			
--			1.00		11.10.2013		Zvika Pery						Creation
--			1.01		08.12.2013		zvika pery	 					Reading from registers			
------------------------------------------------------------------------------------------------
--	Todo:
--
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;


entity signal_generator_top is
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
	port	(
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
			 TGD_I          	: in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
			 ACK_O          	: out std_logic;                      							--'1' when valid data is transmitted to MW or for successful write operation 
			 DAT_O          	: out std_logic_vector (data_width_g-1 downto 0);   			--data transmit to MW
			 STALL_O			: out std_logic; 												--STALL - WS is not available for transaction 
			 --register side signals
			 rc_finish			: in std_logic										--  1 -> reset enable register
--			 typ				: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	-- Type
--			 addr	        	: out std_logic_vector (Add_width_g-1 downto 0);    			--the beginnig address in the client that the information will be written to
--			 len				: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);   --Length
--			 wr_en				: out std_logic;
--			 ws_data	    	: out std_logic_vector (data_width_g-1 downto 0);   			--data out to registers
--			 ws_data_valid		: out std_logic;												-- data valid to registers
--			 reg_data       	: in std_logic_vector (data_width_g-1 downto 0); 	 			--data to be transmitted to the WM
--			 reg_data_valid 	: in std_logic;   												--data to be transmitted to the WM validity
--			 active_cycle		: out std_logic; 												--CYC_I outputted to user side
--			 stall				: in std_logic 													-- stall - suspend wishbone transaction
			);
end entity signal_generator_top;

architecture arc_core of signal_generator_top is
---------------------------------components------------------------------------------------------------------------------------------------------
component signal_generator
	generic (
			reset_polarity_g	:	std_logic	:=	'1';										--'1' reset active high, '0' active low
			data_width_g        :	positive 	:= 	8;      						    		--defines the width of the data lines of the system 
			num_of_signals_g	:	positive	:=	4;											--number of signals that will be recorded simultaneously
			external_en_g		:	std_logic	:= 	'0'											-- 1 -> getting the data from an external source . 0 -> dout is a counter
			);
	port
	(
			clk					:	in  std_logic;												--system clock
			reset				:	in  std_logic;												--system reset
			scene_number_in		:	in	std_logic_vector ( data_width_g - 1 downto 0);			--type of trigger scene
			enable				:	in	std_logic;												--scene in is valid
			data_in				:	in	std_logic_vector ( num_of_signals_g -1 downto 0);		-- in case that we want to store a data from external source
			trigger_in			:	in	std_logic;												--trigger in external signal
			data_out			:	out	std_logic_vector ( num_of_signals_g -1 downto 0);		--data out
			trigger_out			:	out	std_logic												--trigger out signal
	
	);

end component signal_generator;

component signal_generator_registers is
   generic (
			reset_polarity_g			   		:	std_logic	:= '1';								--'1' reset active high, '0' active low
			enable_polarity_g					:	std_logic	:= '1';								--'1' the entity is active, '0' entity not active
			data_width_g           		   		:	natural 	:= 8;         							-- the width of the data lines of the system    (width of bus)
			Add_width_g  		   		   		:   positive	:= 8;     								--width of address word in the WB
			scene_number_reg_1_address_g 		: 	natural 	:= 1;
			enable_reg_address_2_g 		   		: 	natural 	:= 2
           );
   port
   	   (
     clk			  		 	: in std_logic; --system clock
     reset   		   			: in std_logic; --system reset
     -- wishbone slave interface
	 address_in       		 	: in std_logic_vector (Add_width_g -1 downto 0); 	-- address line
	 wr_en           		  	: in std_logic; 									-- write enable: '1' for write, '0' for read
	 data_in_reg      		 	: in std_logic_vector ( data_width_g - 1 downto 0); -- data sent from WS
     valid_in          			: in std_logic; 									-- validity of the data directed from WS								
     data_out          			: out std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
     valid_data_out    			: out std_logic; -- validity of data directed to WS
	 rc_finish					: in std_logic;										--  1 -> reset enable register
	 -- core blocks interface
     scene_number_out_1        	: out std_logic_vector (6 downto 0); 				-- scene number
     enable_out_2        		: out std_logic								  		-- enable sent by the GUI
   	   );
end component signal_generator_registers;

component wishbone_slave
	generic (
		reset_activity_polarity_g  	: std_logic :='1';      										-- defines reset active polarity: '0' active low, '1' active high
		data_width_g               	: natural := 8;         										-- defines the width of the data lines of the system    
		Add_width_g    				: positive := 8;												--width of address word in the WB
		len_d_g						: positive := 1;												--Length Depth
		type_d_g					: positive := 6													--Type Depth    
			);
	port
	(	
		clk    	    				: in std_logic;		 											--system clock
		reset						: in std_logic;		 											--system reset
		--bus side signals
		ADR_I          				: in std_logic_vector (Add_width_g -1 downto 0);				--contains the address word
		DAT_I          				: in std_logic_vector (data_width_g-1 downto 0); 				--contains the data_in word
		WE_I           				: in std_logic;                     							-- '1' for write, '0' for read
		STB_I          				: in std_logic;                     							-- '1' for active bus operation, '0' for no bus operation
		CYC_I          				: in std_logic;                     							-- '1' for bus transition request, '0' for no bus transition request
		TGA_I          				: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
		TGD_I          				: in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
		ACK_O          				: out std_logic;                      							--'1' when valid data is transmitted to MW or for successful write operation 
		DAT_O          				: out std_logic_vector (data_width_g-1 downto 0);   			--data transmit to MW
		STALL_O						: out std_logic; 												--STALL - WS is not available for transaction 
		--register side signals
		typ							: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	-- Type
		addr	       				: out std_logic_vector (Add_width_g-1 downto 0);    			--the beginnig address in the client that the information will be written to
		len							: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);   --Length
		wr_en						: out std_logic;
		ws_data	    				: out std_logic_vector (data_width_g-1 downto 0); 				--data out to registers
		ws_data_valid				: out std_logic;												-- data valid to registers
		reg_data       				: in std_logic_vector (data_width_g-1 downto 0); 	 			--data to be transmitted to the WM
		reg_data_valid 				: in std_logic;   												--data to be transmitted to the WM validity
		active_cycle				: out std_logic; 												--CYC_I outputted to user side
		stall						: in std_logic 													-- stall - suspend wishbone transaction
	);

end component wishbone_slave;

-----------------------------------------------------Constants--------------------------------------------------------------------------

-----------------------------------------------------Types------------------------------------------------------------------------------

-----------------------------------------------------Signals----------------------------------
------- wishbone slave to registers signals-----------
signal addr_s		       				:	std_logic_vector (Add_width_g-1 downto 0);
signal we_s								: 	std_logic; 									-- write enable
signal ws_to_registers_data_s 			: 	std_logic_vector (data_width_g-1 downto 0);	-- data sent from WS to registers (trigg pos, trigg type, enable, clk to start)
signal ws_to_registers_enable_s			: 	std_logic; 									-- validity of the data directed from WS
------- Registers to wishbone slave signals-----------
signal registers2ws_data_s          : std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
signal registers2ws_val_data_s      : std_logic; -- validity of data directed to WS
------- registers to signal generator signals-----------
signal scene_number_s					:	std_logic_vector(6 downto 0);
signal enable_s							: 	std_logic; 
-------------------------------------------------  Implementation ------------------------------------------------------------

begin
										
wishbone_slave_inst : wishbone_slave generic map (
											reset_activity_polarity_g  	=>	reset_polarity_g,
											data_width_g        		=>	data_width_g,
											type_d_g					=>	type_d_g,			--Type Depth. type is the client which the data is directed to
											Add_width_g    				=>	Add_width_g,		--width of addr word in the WB
											len_d_g						=>	len_d_g				--Length Depth. length of the data (in words)
										)
										port map (
											clk			=> clk,									--system clock
											reset		=> reset, 								--system reset   
		
											ADR_I          	=> ADR_I,							--contains the addr word
											DAT_I          	=> DAT_I,							--contains the data_in word
											WE_I           	=> WE_I,                 			-- '1' for write, '0' for read
											STB_I          	=> STB_I,                   		-- '1' for active bus operation, '0' for no bus operation
											CYC_I          	=> CYC_I,                   		-- '1' for bus transmition request, '0' for no bus transmition request
											TGA_I          	=> TGA_I,							--contains the type word
											TGD_I          	=> TGD_I,							--contains the len word
											ACK_O          	=> ACK_O,        					--'1' when valid data is transmited to MW or for successfull write operation 
											DAT_O          	=> DAT_O,							--data transmit to MW
											STALL_O			=> STALL_O,
											
											typ				=> open, 															-- Type
											addr	        => addr_s,  															--the address of the relevant register
											len				=> open,   															--Length
											wr_en			=> we_s,
											ws_data	    	=> ws_to_registers_data_s,   								--data out to registers
											ws_data_valid	=> ws_to_registers_enable_s,									-- data valid to registers
											reg_data       	=> registers2ws_data_s,	 --data to be transmited to the WM
											reg_data_valid 	=> registers2ws_val_data_s,  --data to be transmited to the WM validity
											active_cycle	=> open,												--CYC_I outputed to user side
											stall			=> '0'
										);
						
signal_generator_inst: signal_generator generic map (
											reset_polarity_g		=>	reset_polarity_g,								--'1' reset active high, '0' active low
											data_width_g        	=>	data_width_g,      						    	--defines the width of the data lines of the system 
											num_of_signals_g		=>	num_of_signals_g,								--number of signals that will be recorded simultaneously
											external_en_g			=>	external_en_g									-- 1 -> getting the data from an external source . 0 -> dout is a counter
											)
											port map
											(
											clk							=>	clk,
											reset						=>	reset,										--system reset
											scene_number_in				=>	scene_number_s,				--type of trigger scene
											enable						=>	enable_s,				--scene in is valid
											data_in						=>	data_in,									-- in case that we want to store a data from external source
											trigger_in					=>	trigger_in,									--trigger in external signal
											data_out					=>	data_out,									--data out
											trigger_out					=>	trigger_out									--trigger out signal
											);
						
registers_inst: signal_generator_registers generic map (
											reset_polarity_g		=>	reset_polarity_g,								--'1' reset active high, '0' active low
											enable_polarity_g		=>	enable_polarity_g,
											data_width_g        	=>	data_width_g,      						    	--defines the width of the data lines of the system 
											Add_width_g				=>	Add_width_g,								
											scene_number_reg_1_address_g	=>	scene_number_reg_1_address_g,
											enable_reg_address_2_g			=>	enable_reg_address_2_g
											)
											port map
											(
												clk							=>	clk,
												reset						=>	reset,										--system reset
												address_in       		 	=>	addr_s,									 	-- address line
												wr_en           		  	=>	we_s, 										-- write enable: '1' for write, '0' for read
												data_in_reg      		 	=>	ws_to_registers_data_s,						-- data sent from WS
												valid_in          			=>	ws_to_registers_enable_s,					-- validity of the data directed from WS								
												data_out          			=> registers2ws_data_s,
												valid_data_out    			=> registers2ws_val_data_s,
												rc_finish					=>	rc_finish,
												scene_number_out_1        	=>	scene_number_s,				 				-- scene number
												enable_out_2        		=>	enable_s							  		-- enable sent by the GUI
											);
											
-------------------------------------------------  processes ------------------------------------------------------------

end architecture arc_core;
