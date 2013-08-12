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
				enable						:	in std_logic;									--enabling the entity. if (enable = enable_polarity_g) -> start working, else-> do nothing
				data_in						:	in std_logic_vector (num_of_signals_g - 1 downto 0);	--Input data
				trigger						:	in std_logic;											--trigger signal
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
--------RAM signals--------
		dout_valid					:	in std_logic;		 									--Output data from RAM valid
		data_from_ram				:	in std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0);	-- data came from RAM 
		addr_out					:	out std_logic_vector ( record_depth_g - 1 downto 0);	--address send to RAM to output each cycle
		aout_valid					:	out std_logic;											--Output address to RAM is valid
-------- WB signals--------		
		data_out_to_WBM				:	out std_logic_vector (data_width_g - 1 downto 0)		--data out to WBM
	
	);

end component read_controller;
-----------------------------------------------------Constants--------------------------------------------------------------------------

-----------------------------------------------------Types------------------------------------------------------------------------------


----------------------   Signals   ------------------------------
signal addr_in_s					: std_logic_vector (record_depth_g - 1 downto 0) := (others => '0'); 	--Input address
signal data_from_wc_to_ram_s		: std_logic_vector (width_in_g - 1 downto 0) 	:= (others => '0');	--Input data
signal din_valid_s					: std_logic := '0'; 												--Input data valid
signal trigger_position_s			: std_logic_vector( data_width_g -1 downto 0 )	:= (others => '0');
signal trigger_type_s				: std_logic_vector( data_width_g -1 downto 0 )	:= (others => '0');
--signal data_out_s	   				: std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0) := (others => '0');	--Output data
signal dout_valid_s					: std_logic := '0'; 												--Output data valid
signal start_address_s				: std_logic_vector( record_depth_g -1 downto 0 ) := (others => '0');					--start addr that sent to RC
signal write_controller_finish_s	: std_logic := '0';
signal wc_is_config					: std_logic := '0';														-- '1'-> trigger_position_s & trigger_type_s is update according to registers. '0' -> not update
signal read_controller_finish_s		: std_logic := '0';
signal set_config_counter_s			: integer range 0 to 2 := 0;									--use to set the configuration
signal data_out_s					: std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0) := (others => '0');
signal addr_out_s					: std_logic_vector ((addr_bits_g - power2_out_g*power_sign_g) - 1 downto 0)	:= (others => '0'); 		-- RAM output address
signal aout_valid_s					: std_logic := '0';												--RAM output address is valid
--signal reg_addr_s					: std_logic_vector( data_width_g -1 downto 0 );					--address of register to put\take the data

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
											enable				=> enable,		
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
											dout_valid				=> dout_valid_s,
											data_from_ram			=> data_out_s,
											addr_out				=> addr_out_s,
											aout_valid				=> aout_valid_s,
											data_out_to_WBM			=> data_out_core	--will change after WB connected
											);
											
-------------------------------------------------  processes ------------------------------------------------------------
						
------------------------ write controller configurations -> get trigger type + position from registers
set_wc_config_proc	:	process	(clk, rst)
	
	begin
		if rst = reset_polarity_g then				
			trigger_position_s			<= (others => '0') ;
			trigger_type_s				<= (others => '0') ;			
			wc_is_config				<= '0';
			set_config_counter_s		<= 0;
			
		elsif rising_edge(clk)  then				
			if  wc_is_config = '0' then
				if set_config_counter_s = 0 then	--first cycle, set trigg_pos register address
							----- connect registers!!!!
				--reg_addr <= trigger_position_addr
				set_config_counter_s <= 1;
				elsif set_config_counter_s = 1 then	--second cycle, get trigg_pos from register output and set trigg_type register address
					--trigger_position_s <= reg_output;
					trigger_position_s <= DAT_I;
					--reg_addr <= trigger_type_addr
					set_config_counter_s <= 2;
				elsif set_config_counter_s = 2 then	--third cycle, get trigg_type from register output and finish process (wc_is_config = 1)
				--trigger_type_s <= reg_output;
					trigger_type_s <= DAT_I;
					wc_is_config <= '1';
				end if;
			end if;	
		end if;				
end process set_wc_config_proc;

end architecture arc_core;


