------------------------------------------------------------------------------------------------
-- File Name	:	internal_logic_analyzer_core_top.vhd
-- Generated	:	18.6.2013
-- Author		:	Moran katz & Zvika pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
-- 			The main entity of the system. The core is assembled by: WBS, registers, write controller, 
--			read controller, RAM, WBM.
--			Initial configurations are input to the registers according user's choice, data and trigger 
--			signals are inputting from the signal generator and sampling (saved in the RAM) every clock cycle.
--			According user configurations the system detect trigger "rise" and in the end the read controller 
--			extract the relevant data from the RAM and send it out through the WBM. 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date			Name							Description			
--			1.00		18.6.2013		Zvika Pery						Creation
--			1.01		03.9.2013		zvika pery						bug fix			
------------------------------------------------------------------------------------------------
--	Todo:
--
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library work ;
use work.ram_generic_pkg.all;


entity internal_logic_analyzer_core_top is
	generic (				
				reset_polarity_g		:	std_logic	:= '1';									--'0' - Active Low Reset, '1' Active High Reset
				enable_polarity_g		:	std_logic	:= '1';									--'1' the entity is active, '0' entity not active
				signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
				signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
				record_depth_g			: 	positive  	:=	4;									--number of bits that is recorded from each signal
				data_width_g            :	positive 	:= 	8;      						    --defines the width of the data lines of the system
				Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
				num_of_signals_g		:	positive	:=	8;									--num of signals that will be recorded simultaneously	(Width of data)
--				addr_bits_g				:	positive 	:= 	4;									--Depth of data	(2^4 = 16 addresses)
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
				ADR_I          		: in std_logic_vector (Add_width_g -1 downto 0);	--contains the addr word
				DAT_I          		: in std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
				WE_I           		: in std_logic;                     				-- '1' for write, '0' for read
				STB_I          		: in std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
				CYC_I          		: in std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
				TGA_I          		: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
				TGD_I          		: in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
				TOP_active_cycle	: out std_logic; --CYC_I outputed to user side
				stall				: in std_logic; -- stall - suspend wishbone transaction
				ACK_O          		: out std_logic;                      							--'1' when valid data is transmited to MW or for successfull write operation 
				WS_DAT_O       		: out std_logic_vector (data_width_g-1 downto 0);   			--data transmit to MW
				STALL_O				: out std_logic; 												--STALL - WS is not available for transaction 
				-- wishbone master control unit signals
				wm_end_out			: out std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
				
				--wm_bus side signals
				ADR_O			: out std_logic_vector (Add_width_g-1 downto 0); --contains the addr word
				WM_DAT_O			: out std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
				WE_O			: out std_logic;                     -- '1' for write, '0' for read
				STB_O			: out std_logic;                     -- '1' for active bus operation, '0' for no bus operation
				CYC_O			: out std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
				TGA_O			: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); --contains the type word
				TGD_O			: out std_logic_vector (len_d_g * data_width_g-1 downto 0); --contains the len word
				ACK_I			: in std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
				DAT_I_WM		: in std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
				STALL_I			: in std_logic; --STALL - WS is not available for transaction 
				ERR_I			: in std_logic  --Watchdog interrupts, resets wishbone master
				
			);
end entity internal_logic_analyzer_core_top;

architecture arc_core of internal_logic_analyzer_core_top is
---------------------------------components------------------------------------------------------------------------------------------------------
component write_controller
	generic (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
			record_depth_g			: 	positive  	:=	4;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
			num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port
	(	
		clk							:	in  std_logic;											--system clock
		reset						:	in  std_logic;											--system reset
		enable						:	in	std_logic;											--enabling the entity. if (enable = enable_polarity_g) -> start working, else-> do nothing
		trigger_position_in			:	in  std_logic_vector(  6 downto 0	);		--the percentage of the data to send out
		trigger_type_in				:	in  std_logic_vector(  6 downto 0	);		--we specify 5 types of triggers	
		config_are_set				:	in	std_logic;											--configurations from registers are ready to be read
		data_out_of_wc				:	out std_logic_vector ( num_of_signals_g -1  downto 0);	--sending the data  to be saved in the RAM. 
		addr_out_to_RAM				:	out std_logic_vector( record_depth_g -1 downto 0);	--the addr in the RAM to save the data
		write_controller_finish		:	out std_logic;											--'1' ->WC has finish working and saving all the relevant data (RC will start work), '0' ->WC is still working
		start_addr_out				:	out std_logic_vector( record_depth_g -1 downto 0 );	--the start addr of the data that we need to send out to the user. send now to RC
		din_valid					:	out std_logic;	--data in valid
				
		data_in						:	in	std_logic_vector ( num_of_signals_g -1 downto 0);	--data in. comming from user
		trigger						:	in	std_logic											--trigger signal
	
	);

end component write_controller;

component ram_generic 
	generic (
				reset_polarity_g	:	std_logic 				:= '1';	--'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 				:= 8;	--Width of data
				addr_bits_g			:	positive 				:= 4;	--Depth of data	(2^4 = 16 addresses)
				power2_out_g		:	natural 				:= 0;	--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide
				power_sign_g		:	integer range -1 to 1 	:= 1 	-- '-1' => output width > input width ; '1' => input width > output width
			);
	port	(
				clk			:	in std_logic;									--System clock
				rst			:	in std_logic;									--System Reset
				addr_in		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
				addr_out	:	in std_logic_vector ((addr_bits_g - power2_out_g*power_sign_g) - 1 downto 0); 		--Output address
				aout_valid	:	in std_logic;									--Output address is valid
				data_in		:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
				din_valid	:	in std_logic; 									--Input data valid
				data_out	:	out std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0);	--Output data
				dout_valid	:	out std_logic 									--Output data valid
			);
end component ram_generic;

component read_controller
	generic (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
			record_depth_g			: 	positive  	:=	4;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			num_of_signals_g		:	positive	:=	8;
			power2_out_g			:	natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
			power_sign_g			:	integer range -1 to 1 	:= 1					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
			);
	port
	(	
		clk							:	in std_logic;											--system clock
		reset						:	in std_logic;											--system reset
		start_addr_in				:	in std_logic_vector( record_depth_g -1 downto 0 );		--the start address of the data that we need to send out to the user
		write_controller_finish		:	in std_logic;											--start output data after wc_finish -> 1
		read_controller_finish		:	out std_logic;											--1-> rc is finish, 0-> other. needed to the enable FSM
--------RAM signals--------
		dout_valid					:	in std_logic;		 									--Output data from RAM valid
		data_from_ram				:	in std_logic_vector (num_of_signals_g - 1 downto 0);	-- data came from RAM 
		addr_out					:	out std_logic_vector ( record_depth_g - 1 downto 0);	--address send to RAM to output each cycle
		aout_valid					:	out std_logic;											--Output address to RAM is valid
-------- WB signals--------		
		data_out_to_WBM				:	out std_logic_vector (data_width_g - 1 downto 0);		--data out to WBM
		data_out_to_WBM_valid		:	out std_logic											--data out to WBM is valid
	);

end component read_controller;

component wishbone_master
	generic (
			reset_activity_polarity_g  	: std_logic := '1';     -- defines reset active polarity: '0' active low, '1' active high
			data_width_g        		: 	natural	 := 8;      -- defines the width of the data lines of the system
			type_d_g					:	positive := 6;		--Type Depth
			Add_width_g    				:   positive := 8;		--width of addr word in the WB
			len_d_g						:	positive := 1		--Length Depth
			);
	port
	(	
			sys_clk			: in std_logic; --system clock
			sys_reset		: in std_logic; --system reset   
			--control unit signals
			wm_start		: in std_logic;	--when '1' WM starts a transaction
			wr				: in std_logic;                      --determines if the WM will make a read('0') or write('1') transaction
			type_in			: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);  --type is the client which the data is directed to
			len_in			: in std_logic_vector (len_d_g * data_width_g-1 downto 0);  --length of the data (in words)
			addr_in			: in std_logic_vector (Add_width_g-1 downto 0);  --the address in the client that the information will be written to
			wm_end			: out std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
			--Read Controller signals
			rc_din			: in std_logic_vector (data_width_g - 1 downto 0);	--RC Output data
--			rc_din_valid	: in std_logic; 									--RC Output data valid
			--bus side signals
			ADR_O			: out std_logic_vector (Add_width_g-1 downto 0); --contains the addr word
			DAT_O			: out std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
			WE_O			: out std_logic;                     -- '1' for write, '0' for read
			STB_O			: out std_logic;                     -- '1' for active bus operation, '0' for no bus operation
			CYC_O			: out std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
			TGA_O			: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); --contains the type word
			TGD_O			: out std_logic_vector (len_d_g * data_width_g-1 downto 0); --contains the len word
			ACK_I			: in std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
			DAT_I			: in std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
			STALL_I			: in std_logic; --STALL - WS is not available for transaction 
			ERR_I			: in std_logic  --Watchdog interrupts, resets wishbone master
	);

end component wishbone_master;

component core_registers
	generic (
			reset_polarity_g			   		:	std_logic	:= '1';								--'1' reset active highe, '0' active low
			enable_polarity_g					:	std_logic	:= '1';								--'1' the entity is active, '0' entity not active
			data_width_g           		   		:	natural 	:= 8;         							-- the width of the data lines of the system    (width of bus)
			Add_width_g  		   		   		:   positive	:= 8;     								--width of addr word in the WB
			en_reg_address_g      		   		: 	natural 	:= 0;
			trigger_type_reg_1_address_g 		: 	natural 	:= 1;
			trigger_position_reg_2_address_g	: 	natural 	:= 2;
			clk_to_start_reg_3_address_g 	   	: 	natural 	:= 3;
			enable_reg_address_4_g 		   		: 	natural 	:= 4
			);
	port
	(	
			clk			   			: in std_logic; --system clock
			reset   		   			: in std_logic; --system reset
	-- wishbone slave interface
			address_in       			: in std_logic_vector (Add_width_g -1 downto 0); -- address line
			wr_en            			: in std_logic; 									-- write enable: '1' for write, '0' for read
			data_in_reg        			: in std_logic_vector (6 downto 0); -- data sent from WS
			valid_in          			: in std_logic; 									-- validity of the data directed from WS
			rc_finish					: in std_logic;										--  1 -> reset enable register
			wc_finish			: in std_logic;										
--     		data_out          : out std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
--     		valid_data_out    : out std_logic; -- validity of data directed to WS
    -- write controller interface
			en_out            			: out std_logic;						 			-- enable data sent to trigger pos, triiger type, clk to stars, enable
			trigger_type_out_1        	: out std_logic_vector ( 6 downto 0); 	-- trigger type
			trigger_positionout_2      	: out std_logic_vector ( 6 downto 0); 	-- trigger pos
			clk_to_start_out_3        	: out std_logic_vector (6 downto 0);	-- count cycles that passed since trigger rise
			enable_out_4        		: out std_logic								  		-- enable sent by the GUI
	
	);

end component core_registers;

component wishbone_slave
	generic (
			reset_activity_polarity_g  	:std_logic :='1';      -- defines reset active polarity: '0' active low, '1' active high
			data_width_g               	: natural := 8;         -- defines the width of the data lines of the system    
			Add_width_g    				:   positive := 8;		--width of addr word in the WB
			len_d_g						:	positive := 1;		--Length Depth
			type_d_g					:	positive := 6		--Type Depth    
			);
	port
	(	
			clk    	    	: in std_logic;		 											--system clock
			reset			: in std_logic;		 											--system reset
			--bus side signals
			ADR_I          	: in std_logic_vector (Add_width_g -1 downto 0);				--contains the addr word
			DAT_I          	: in std_logic_vector (data_width_g-1 downto 0); 				--contains the data_in word
			WE_I           	: in std_logic;                     							-- '1' for write, '0' for read
			STB_I          	: in std_logic;                     							-- '1' for active bus operation, '0' for no bus operation
			CYC_I          	: in std_logic;                     							-- '1' for bus transmition request, '0' for no bus transmition request
			TGA_I          	: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
			TGD_I          	: in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
			ACK_O          	: out std_logic;                      							--'1' when valid data is transmited to MW or for successfull write operation 
			DAT_O          	: out std_logic_vector (data_width_g-1 downto 0);   			--data transmit to MW
			STALL_O			: out std_logic; 												--STALL - WS is not available for transaction 
			--register side signals
			typ				: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	-- Type
			addr	        : out std_logic_vector (Add_width_g-1 downto 0);    			--the beginnig address in the client that the information will be written to
			len				: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);   --Length
			wr_en			: out std_logic;
			ws_data	    	: out std_logic_vector (data_width_g-1 downto 0); 				--data out to registers
			ws_data_valid	: out std_logic;												-- data valid to registers
			reg_data       	: in std_logic_vector (data_width_g-1 downto 0); 	 			--data to be transmited to the WM
			reg_data_valid 	: in std_logic;   												--data to be transmited to the WM validity
			active_cycle	: out std_logic; 												--CYC_I outputed to user side
			stall			: in std_logic 													-- stall - suspend wishbone transaction
	);

end component wishbone_slave;

component enable_fsm is
	GENERIC
	(
		reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
		enable_polarity_g		:	std_logic	:=	'1'									--'1' the core starts working when signal high , '0' working when low
		
	);
	port 
	(			
		clk						:	 in  std_logic;										--system clk
		reset 					:	 in  std_logic;										--reset
		enable					:	 in	 std_logic;										-- the signal is being recieved from the software. enabling the entity. 	
		wc_finish				:	 in	 std_logic;
		rc_finish				:	 in	 std_logic;										--'1' -> read controller finish working, '0' -> system still working
		enable_out				:	 out std_logic										 --enable signal that sent to the core 
	);
end component enable_fsm;

component in_out_cordinator_generic is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
			out_width_g           	:	positive 	:= 	3;      						    -- defines the width of the data lines of the system 
			in_width_g				:	positive	:=	8									--number of signals that will be recorded simultaneously
	);
	port
	(
		clk							:	in std_logic;											--system clock
		reset						:	in std_logic;											--system reset
		data_in						:	in std_logic_vector (in_width_g - 1 downto 0);	-- data came from RAM 
		data_in_valid				:	in std_logic;											--data in valid
		data_out					:	out std_logic_vector (out_width_g - 1 downto 0);		--data out to WBM
		data_out_valid				:	out std_logic											--data out valid
	);	
end component in_out_cordinator_generic;

component data_input_generic is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
			Add_width_g		   		:   positive	:= 	8;     								--width of addr word in the WB
			out_width_g           	:	positive 	:= 	3;      						    -- defines the width of the data lines of the system 
			in_width_g				:	positive	:=	8									--number of signals that will be recorded simultaneously
	);
	port
	(
		clk							:	in std_logic;											--system clock
		reset						:	in std_logic;											--system reset
		addr_in						:	in std_logic_vector (Add_width_g - 1 downto 0);
		data_in						:	in std_logic_vector (in_width_g - 1 downto 0);	-- data came from RAM 
		data_in_valid				:	in std_logic;											--data in valid
		addr_out					:	out std_logic_vector (Add_width_g - 1 downto 0);
		data_out					:	out std_logic_vector (out_width_g - 1 downto 0);		--data out to WBM
		data_out_valid				:	out std_logic											--data out valid
	);	
end component data_input_generic;

-----------------------------------------------------Constants--------------------------------------------------------------------------
constant len_of_data_c		: std_logic_vector (len_d_g * data_width_g - 1 downto 0)	:= std_logic_vector(to_unsigned( 1 , len_d_g * data_width_g));
constant type_of_TX_ws_c	: std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0)	:= std_logic_vector(to_unsigned( 4 , type_d_g * data_width_g));
constant type_of_CORE_ws_c	: std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0)	:= std_logic_vector(to_unsigned( 3 , type_d_g * data_width_g));
constant size_of_register_c	: integer range 0 to 7 := 7;
-----------------------------------------------------Types------------------------------------------------------------------------------


----------------------   Signals   ------------------------------
signal addr_in_s					: std_logic_vector (record_depth_g - 1 downto 0); 	--Input address
signal data_from_wc_to_ram_s		: std_logic_vector (num_of_signals_g - 1 downto 0);		--Input data
signal din_valid_s					: std_logic;										--Input data valid
signal trigger_position_s			: std_logic_vector( 6 downto 0 );
signal trigger_type_s				: std_logic_vector( 6 downto 0 );
signal dout_valid_s					: std_logic;										--Output data valid
signal start_address_s				: std_logic_vector( record_depth_g -1 downto 0 );	--start addr that sent to RC
signal write_controller_finish_s	: std_logic;
signal wc_is_config					: std_logic;										-- '1'-> trigger_position_s & trigger_type_s is update according to registers. '0' -> not update
signal read_controller_finish_s		: std_logic;
signal data_out_s					: std_logic_vector (num_of_signals_g - 1 downto 0);
signal addr_out_s					: std_logic_vector ((record_depth_g - power2_out_g*power_sign_g) - 1 downto 0); 		-- RAM output address
signal aout_valid_s					: std_logic;										--RAM output address is valid
signal clk_to_start_s				: std_logic_vector ( 6 downto 0 );
signal enable_s						: std_logic;										--enabling the entity. if (enable = enable_polarity_g) -> start working, else-> do nothing
signal enable_register_s			: std_logic;										--enable register
signal data_from_cordinator_to_wm_s			: std_logic_vector (data_width_g - 1 downto 0);
signal data_from_cordinator_to_wm_valid_s	: std_logic;
signal data_from_rc_to_cordinator_s			: std_logic_vector (num_of_signals_g - 1 downto 0);
signal data_from_rc_to_cordinator_valid_s	: std_logic;
signal data_in_reg_valid_s					: std_logic;
signal data_in_reg_s						: std_logic_vector (size_of_register_c - 1 downto 0);
------- wishbone slave to data_in signals-----------
signal ws_to_add_in_s				: std_logic_vector (Add_width_g -1 downto 0); 	-- reg address line
signal wr_en_s             			: std_logic; 									-- write enable: '1' for write, '0' for read
signal ws_to_din_s 					: std_logic_vector (data_width_g-1 downto 0);	-- data sent from WS to registers (trigg pos, trigg type, enable, clk to start)
signal ws_to_din_valid_s			: std_logic; 									-- validity of the data directed from WS
signal typ_s						: std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	-- Type
signal len_s						: std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);   --Length
-------  data_in to registers signals-----------
signal add_in_to_registers_s		: std_logic_vector (Add_width_g -1 downto 0); 	-- reg address line
signal din_to_registers_s 			: std_logic_vector (size_of_register_c - 1 downto 0);
signal din_to_registers_valid_s		: std_logic; 									-- validity of the data 
-------------------------------------------------  Implementation ------------------------------------------------------------

begin

RAM_inst : ram_generic generic map (
								reset_polarity_g	=> reset_polarity_g,	
                                width_in_g			=> num_of_signals_g,
                                addr_bits_g			=> record_depth_g,			
                                power2_out_g		=> power2_out_g,
								power_sign_g		=> power_sign_g
								)
						port map (
								clk			=> clk,
								rst			=> rst,			
								addr_in		=> addr_in_s,		
								addr_out	=> addr_out_s,	
								aout_valid	=> aout_valid_s,	
								data_in		=> data_from_wc_to_ram_s,		
								din_valid	=> din_valid_s,	
								data_out	=> data_out_s,	
								dout_valid	=> dout_valid_s		
								);

enable_fsm_inst : enable_fsm generic map (
								reset_polarity_g	=> reset_polarity_g,	
                                enable_polarity_g	=> enable_polarity_g
								)
						port map (
								clk			=> clk,
								reset		=> rst,
								enable		=> enable_register_s,
								wc_finish	=> write_controller_finish_s,
								rc_finish	=> read_controller_finish_s,
								enable_out	=> enable_s
								);
								
write_controller_inst : write_controller generic map (
											reset_polarity_g	=>	reset_polarity_g,
											enable_polarity_g	=>	enable_polarity_g,								
											signal_ram_depth_g	=>	signal_ram_depth_g,									
											signal_ram_width_g	=>	signal_ram_width_g,  								
											record_depth_g		=>	record_depth_g,									
											data_width_g        =>  data_width_g,         						    
											Add_width_g  		=>  Add_width_g,        								
											num_of_signals_g	=>	num_of_signals_g
											)
										port map (
											clk					=> clk,
											reset				=> rst,			
											enable				=> enable_s,		
											trigger_position_in	=> trigger_position_s,	
											trigger_type_in		=> trigger_type_s	,
											config_are_set		=> wc_is_config,
											trigger 			=> trigger,
											data_in				=> data_in,		
											start_addr_out		=> start_address_s,								
											data_out_of_wc		=> data_from_wc_to_ram_s,	
											addr_out_to_RAM		=> addr_in_s,
											write_controller_finish	=> write_controller_finish_s,
											din_valid			=> din_valid_s
											);								

read_controller_inst : read_controller generic map (
											reset_polarity_g	=>	reset_polarity_g,
											record_depth_g		=>	record_depth_g,
											data_width_g		=>	data_width_g,
											num_of_signals_g	=>	num_of_signals_g,
											power2_out_g		=>	power2_out_g,
											power_sign_g		=>	power_sign_g
											)
										port map (
											clk						=> clk,
											reset					=> rst,
											start_addr_in			=> start_address_s,
											write_controller_finish	=> write_controller_finish_s,
											read_controller_finish	=> read_controller_finish_s,
											dout_valid				=> dout_valid_s,
											data_from_ram			=> data_out_s,
											addr_out				=> addr_out_s,
											aout_valid				=> aout_valid_s,
											data_out_to_WBM			=> data_from_rc_to_cordinator_s,
											data_out_to_WBM_valid	=> data_from_rc_to_cordinator_valid_s
											);

wishbone_master_inst : wishbone_master generic map (
											reset_activity_polarity_g  	=>	reset_polarity_g,
											data_width_g        		=>	data_width_g,
											type_d_g					=>	type_d_g,				--Type Depth. type is the client which the data is directed to
											Add_width_g    				=>	Add_width_g,			--width of addr word in the WB
											len_d_g						=>	len_d_g					--Length Depth. length of the data (in words)
											
											)
										port map (
											sys_clk			=> clk,								--system clock
											sys_reset		=> rst, 							--system reset   
		
											wm_start		=> write_controller_finish_s,								--when '1' WM starts a transaction
											wr				=> '1',                      			--determines if the WM will make a read('0') or write('1') transaction
											type_in			=> type_of_TX_ws_c,  								--type is the client which the data is directed to
											len_in			=> len_of_data_c,  								--length of the data (in words)
											addr_in			=> (others => '0'),  								--the address in the client(registers) that the information will be written to
											wm_end			=> wm_end_out, 								--when '1' WM ended a transaction or reseted by watchdog ERR_I signal
											
											rc_din			=> data_from_cordinator_to_wm_s,			--RC Output data
--											rc_din_valid	=> data_from_rc_to_wm_valid_s, 		--RC Output data valid
											ADR_O			=> ADR_O, 							--contains the addr word
											DAT_O			=> WM_DAT_O, 							--contains the data_in word
											WE_O			=> WE_O,                     		-- '1' for write, '0' for read
											STB_O			=> STB_O,                     		-- '1' for active bus operation, '0' for no bus operation
											CYC_O			=> CYC_O,                     		-- '1' for bus transmition request, '0' for no bus transmition request
											TGA_O			=> TGA_O, 							--contains the type word
											TGD_O			=> TGD_O, 							--contains the len word
											ACK_I			=> ACK_I,                     		--'1' when valid data is recieved from WS or for successfull write operation in WS
											DAT_I			=> DAT_I_WM,   						--data recieved from WS
											STALL_I			=> STALL_I, 						--STALL - WS is not available for transaction 
											ERR_I			=> ERR_I							--Watchdog interrupts, resets wishbone master
											);

data_in_ins : data_input_generic generic map (
											reset_polarity_g	=>	reset_polarity_g,
											Add_width_g		   	=>	Add_width_g,
											out_width_g         =>	size_of_register_c,
											in_width_g			=>	data_width_g
											)
								port map	(
											clk				=> clk,
											reset			=> rst,
											addr_in			=> ws_to_add_in_s,
											data_in			=> ws_to_din_s,
											data_in_valid	=> ws_to_din_valid_s,
											addr_out		=> add_in_to_registers_s,
											data_out		=> din_to_registers_s, 
											data_out_valid	=> din_to_registers_valid_s	
											);											

											
											
core_registers_inst : core_registers generic map (

											reset_polarity_g					=>	reset_polarity_g,
											enable_polarity_g					=>	enable_polarity_g,
											data_width_g           		   		=>	data_width_g,
											Add_width_g  		   		   		=>	Add_width_g,
											en_reg_address_g      		   		=>	0,
											trigger_type_reg_1_address_g 		=>	1,
											trigger_position_reg_2_address_g	=>	2,
											clk_to_start_reg_3_address_g 	   	=>	3,
											enable_reg_address_4_g 		   		=>	4
										)
										port map (
											clk						=> clk,
											reset					=> rst,
											------ wishbone slave interface------
											address_in        		=> add_in_to_registers_s,
											wr_en             		=> wr_en_s,
											data_in_reg        		=> din_to_registers_s,
											valid_in          		=> din_to_registers_valid_s,
											rc_finish				=> read_controller_finish_s,
											wc_finish				=> write_controller_finish_s,									
											----- core blocks interface----------
											en_out            		=> wc_is_config,		--all registers are ready to be read from
											trigger_type_out_1      => trigger_type_s,
											trigger_positionout_2   => trigger_position_s,
											clk_to_start_out_3      => clk_to_start_s,
											enable_out_4        	=> enable_register_s
										);
										
wishbone_slave_inst : wishbone_slave generic map (
											reset_activity_polarity_g  	=>	reset_polarity_g,
											data_width_g        		=>	data_width_g,
											type_d_g					=>	type_d_g,				--Type Depth. type is the client which the data is directed to
											Add_width_g    				=>	Add_width_g,			--width of addr word in the WB
											len_d_g						=>	len_d_g					--Length Depth. length of the data (in words)
										)
										port map (
											clk			=> clk,								--system clock
											reset		=> rst, 							--system reset   
		
											ADR_I          	=> ADR_I,							--contains the addr word
											DAT_I          	=> DAT_I,							--contains the data_in word
											WE_I           	=> WE_I,                 			-- '1' for write, '0' for read
											STB_I          	=> STB_I,                   		-- '1' for active bus operation, '0' for no bus operation
											CYC_I          	=> CYC_I,                   		-- '1' for bus transmition request, '0' for no bus transmition request
											TGA_I          	=> TGA_I,							--contains the type word
											TGD_I          	=> TGD_I,							--contains the len word
											ACK_O          	=> ACK_O,        					--'1' when valid data is transmited to MW or for successfull write operation 
											DAT_O          	=> WS_DAT_O,							--data transmit to MW
											STALL_O			=> STALL_O,
											
											typ				=> typ_s, -- Type
											addr	        => ws_to_add_in_s,  --the address of the relevant register
											len				=> len_s,   --Length
											wr_en			=> wr_en_s,
											ws_data	    	=> ws_to_din_s,   --data out to registers
											ws_data_valid	=> ws_to_din_valid_s,	-- data valid to registers
											-- we do not send data out from the registers
											reg_data       	=> (others => '0'),	 --data to be transmited to the WM
											reg_data_valid 	=> '0',  --data to be transmited to the WM validity
											active_cycle	=> TOP_active_cycle,	--CYC_I outputed to user side
											stall			=> stall
										);
						
data_out_size_inst: in_out_cordinator_generic generic map (
													reset_polarity_g		=> reset_polarity_g,
													out_width_g           	=> data_width_g,
													in_width_g				=> num_of_signals_g
											)
											port map
											(
													clk							=>	clk,
													reset						=>	rst,
													data_in						=>	data_from_rc_to_cordinator_s,
													data_in_valid				=>	data_from_rc_to_cordinator_valid_s,
													data_out					=>	data_from_cordinator_to_wm_s,
													data_out_valid				=>	data_from_cordinator_to_wm_valid_s
											);
						

						
						
-------------------------------------------------  processes ------------------------------------------------------------

end architecture arc_core;
