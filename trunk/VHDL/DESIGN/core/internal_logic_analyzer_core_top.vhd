------------------------------------------------------------------------------------------------
-- File Name	:	internal_logic_analyzer_core_top.vhd
-- Generated	:	18.6.2013
-- Author		:	Moran katz & Zvika pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
-- 			Craeating an array of RAMs 
--			(using generic_ram from RunLen Project, of Beeri Schreiber and Alon Yavich) 
--			that will save the data.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date			Name							Description			
--			1.00		18.6.2013		Zvika Pery						Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) connect registers in get_config mode
--
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

library work ;
use work.ram_generic_pkg.all;


entity internal_logic_analyzer_core_top is
	generic (				
				reset_polarity_g		:	std_logic	:= '1';									--'0' - Active Low Reset, '1' Active High Reset
				enable_polarity_g		:	std_logic	:= '1';								--'1' the entity is active, '0' entity not active
				signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
				signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
				record_depth_g			: 	positive  	:=	5;									--number of bits that is recorded from each signal
				data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system
				Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
				num_of_signals_g		:	positive	:=	8;									--num of signals that will be recorded simultaneously	(Width of data)
				width_in_g				:	positive 	:= 	8;									--Width of data
				addr_bits_g				:	positive 	:= 	4;									--Depth of data	(2^4 = 16 addresses)
				power2_out_g			:	natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
				power_sign_g			:	integer range -1 to 1 	:= 1					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
			);
	port	(
				clk							:	in std_logic;									--System clock
				rst							:	in std_logic;									--System Reset
--				enable						:	in std_logic;									--enabling the entity. if (enable = enable_polarity_g) -> start working, else-> do nothing
				-- Signal Generator interface
				data_in						:	in std_logic_vector (num_of_signals_g - 1 downto 0);	--Input data from Signal Generator
				trigger						:	in std_logic;											--trigger signal from Signal Generator
				-- wishbone slave interface
				registers_address_in		: in std_logic_vector (Add_width_g -1 downto 0); 	-- reg address line
				wr_en             			: in std_logic; 									-- write enable: '1' for write, '0' for read
				registers_data_in  			: in std_logic_vector (data_width_g-1 downto 0); 	-- data sent from WS to registers (trigg pos, trigg type, enable, clk to start)
				registers_valid_in 			: in std_logic; 									-- validity of the data directed from WS
				--     data_out          		: out std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
				--     valid_data_out    		: out std_logic; -- validity of data directed to WS
				
				-- wishbone master interface
				DAT_I       			    : 	in std_logic_vector (data_width_g-1 downto 0); 		--contains the data_in word
--				addr_out					:	in std_logic_vector ((record_depth_g - power2_out_g*power_sign_g) - 1 downto 0); 		--Output address
--				aout_valid					:	in std_logic;									--Output address is valid
				data_out_core				:	out std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0)	--Output data 
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
			record_depth_g			: 	positive  	:=	5;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
			num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port
	(	
		clk							:	in  std_logic;											--system clock
		reset						:	in  std_logic;											--system reset
		enable						:	in	std_logic;											--enabling the entity. if (enable = enable_polarity_g) -> start working, else-> do nothing
		trigger_position_in			:	in  std_logic_vector(  data_width_g -1 downto 0	);		--the percentage of the data to send out
		trigger_type_in				:	in  std_logic_vector(  data_width_g -1 downto 0	);		--we specify 5 types of triggers	
		config_are_set				:	in	std_logic;											--configurations from registers are ready to be read
		data_out_of_wc				:	out std_logic_vector ( num_of_signals_g -1  downto 0);	--sending the data  to be saved in the RAM. 
		addr_out_to_RAM				:	out std_logic_vector( record_depth_g -1 downto 0);	--the addr in the RAM to save the data
		write_controller_finish		:	out std_logic;											--'1' ->WC has finish working and saving all the relevant data (RC will start work), '0' ->WC is still working
		start_addr_out				:	out std_logic_vector( record_depth_g -1 downto 0 );	--the start addr of the data that we need to send out to the user. send now to RC
		din_valid					:	out std_logic;	--data in valid
---------whishbone signals----------------------------					
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
			record_depth_g			: 	positive  	:=	10;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			num_of_signals_g		:	positive	:=	8;									--number of signals that will be recorded simultaneously
			width_in_g				:	positive 	:= 	8;									--Width of data
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
		data_from_ram				:	in std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0);	-- data came from RAM 
		addr_out					:	out std_logic_vector ( record_depth_g - 1 downto 0);	--address send to RAM to output each cycle
		aout_valid					:	out std_logic;											--Output address to RAM is valid
-------- WB signals--------		
		data_out_to_WBM				:	out std_logic_vector (data_width_g - 1 downto 0)		--data out to WBM
	
	);

end component read_controller;

component core_registers
	generic (
			reset_polarity_g			   		:	std_logic	:= '1';								--'1' reset active highe, '0' active low
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
			data_in           			: in std_logic_vector (data_width_g-1 downto 0); -- data sent from WS
			valid_in          			: in std_logic; 									-- validity of the data directed from WS
--     		data_out          : out std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
--     		valid_data_out    : out std_logic; -- validity of data directed to WS
    -- core blocks interface
			en_out            			: out std_logic;						 			-- enable data sent to trigger pos, triiger type, clk to stars, enable
			trigger_type_out_1        	: out std_logic_vector (data_width_g-1 downto 0); 	-- trigger type
			trigger_positionout_2      : out std_logic_vector (data_width_g-1 downto 0); 	-- trigger pos
			clk_to_start_out_3        	: out std_logic_vector (data_width_g-1 downto 0);	-- count cycles that passed since trigger rise
			enable_out_4        		: out std_logic								  		-- enable sent by the GUI
	
	);

end component core_registers;

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

-----------------------------------------------------Constants--------------------------------------------------------------------------

-----------------------------------------------------Types------------------------------------------------------------------------------


----------------------   Signals   ------------------------------
signal addr_in_s					: std_logic_vector (record_depth_g - 1 downto 0) := (others => '0'); 	--Input address
signal data_from_wc_to_ram_s		: std_logic_vector (width_in_g - 1 downto 0) 	:= (others => '0');	--Input data
signal din_valid_s					: std_logic := '0'; 												--Input data valid
signal trigger_position_s			: std_logic_vector( data_width_g -1 downto 0 )	:= (others => '0');
signal trigger_type_s				: std_logic_vector( data_width_g -1 downto 0 )	:= (others => '0');
signal dout_valid_s					: std_logic := '0'; 												--Output data valid
signal start_address_s				: std_logic_vector( record_depth_g -1 downto 0 ) := (others => '0');					--start addr that sent to RC
signal write_controller_finish_s	: std_logic := '0';
signal wc_is_config					: std_logic := '0';														-- '1'-> trigger_position_s & trigger_type_s is update according to registers. '0' -> not update
signal read_controller_finish_s		: std_logic := '0';
signal set_config_counter_s			: integer range 0 to 2 := 0;									--use to set the configuration
signal data_out_s					: std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0) := (others => '0');
signal addr_out_s					: std_logic_vector ((addr_bits_g - power2_out_g*power_sign_g) - 1 downto 0)	:= (others => '0'); 		-- RAM output address
signal aout_valid_s					: std_logic := '0';												--RAM output address is valid
signal clk_to_start_s				: std_logic_vector ( data_width_g -1 downto 0 )	:= (others => '0');
signal enable_s						: std_logic	:= '0';									--enabling the entity. if (enable = enable_polarity_g) -> start working, else-> do nothing
signal enable_register_s			: std_logic	:= '0';									--enabe register

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
											width_in_g			=>	width_in_g,
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
											data_out_to_WBM			=> data_out_core	--will change after WB connected
											);

core_registers_inst : core_registers generic map (

											reset_polarity_g					=>	reset_polarity_g,
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
											address_in        		=> registers_address_in,
											wr_en             		=> wr_en,
											data_in           		=> registers_data_in,
											valid_in          		=> registers_valid_in,
									--     data_out          		=>
									--     valid_data_out    		=>
											----- core blocks interface----------
											en_out            		=> wc_is_config,		--all registers are ready to be read from
											trigger_type_out_1      => trigger_type_s,
											trigger_positionout_2   => trigger_position_s,
											clk_to_start_out_3      => clk_to_start_s,
											enable_out_4        	=> enable_register_s
											);
											
-------------------------------------------------  processes ------------------------------------------------------------
						

end architecture arc_core;


