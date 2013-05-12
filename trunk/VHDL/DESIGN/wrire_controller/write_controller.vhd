------------------------------------------------------------------------------------------------
-- File Name	:	write_controller.vhd
-- Generated	:	07.01.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--			1. The entity getting the data from the WB slave, calculate the correct addres in the RAM
--			and sent it to the RAM to be saved. 
--			2. getting the trigger signal and check if trigger rise had occur (according the configuration) and send the start and end 
--			addres to the read controller.
--			
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		07.01.2013	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			conect core_registers 
--			build clk_to_start in core_registers
--			conect to WB slave
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
--use ieee.std_logic_signed.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_misc.all;
library work ;
use work.write_controller_pkg.all;
---------------------------------------------------------------------------------------------------------------------------------------

entity write_controller is
	GENERIC (
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
		trigger_position_in			:	in  std_logic_vector(  data_width_g -1 downto 0	);					--the percentage of the data to send out
		trigger_type_in				:	in  std_logic_vector(  data_width_g -1 downto 0	);					--we specify 5 types of triggers	
		trigger						:	in	std_logic;											--trigger signal
		data_in						:	in	std_logic_vector ( num_of_signals_g -1 downto 0);	--data in. comming from user
		rc_finish					:	in  std_logic;											--'1' -> read controller finish working, '0' -> system still working
		wc_to_rc_out_wc				:	out std_logic_vector ((2 * signal_ram_depth_g ) - 1 downto 0);	--start and end addr of data needed to output. send to RC
		data_out_of_wc				:	out std_logic_vector ( num_of_signals_g -1  downto 0);		--sending the data  to be saved in the RAM. 
		addr_out_to_RAM				:	out std_logic_vector( signal_ram_depth_g -1 downto 0);		--the addr in the RAM to save the data
		write_controller_finish		:	out std_logic;											--'1' ->WC has finish working and saving all the relevant data (RC will start work), '0' ->WC is still working
		start_array_row_out			:	out integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g));	--send with the addr to the RC
		end_array_row_out			:	out integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g))	;	--send with the addr to the RC
		aout_valid					:	out std_logic_vector( up_case(2**record_depth_g , (2**signal_ram_depth_g)) -1  downto 0	)	--send to the RAM. each time we enable entire row at the RAM array		
					
		
	);	
end entity write_controller;

architecture behave of write_controller is

--------------------------------------------------------------Components------------------------------------------------------------------------------





--   a) calculate the address in the RAM of the current data. 
--	 b) take the incomimg data and separate it to the correct RAMs with the correct addr.
component alu_data
	GENERIC (
		reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
		enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
		signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
		signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
		record_depth_g			: 	positive  	:=	5;									--number of bits that is recorded from each signal
		Add_width_g     		:   positive	:=  8;     								--width of addr word in the RAM
		num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port (			
		clk						:	 in  std_logic;										--system clk
		reset 					:	 in  std_logic;										--reset
		enable					:	 in	 std_logic;											--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing	
		data_in					:	 in	 std_logic_vector ( num_of_signals_g -1 downto 0);	--input data. come from user
		trigger_found_in		:	 in	 std_logic	;										-- 1  we found the trigger, 0 we have not
		work_count				: 	 in	 integer range 0 to 2**record_depth_g ;			--number of cycles that we continue to work after trigger rise
		addr_out_alu_data		:	 out std_logic_vector( signal_ram_depth_g -1 downto 0);	--the addr in the RAM to save the data
		aout_valid_alu			:	 out std_logic_vector( up_case(2**record_depth_g , (2**signal_ram_depth_g)) -1  downto 0	);	--each time we enable entire row at the RAM array
		wc_finish				:	 out std_logic	;										--'1' ->WC has finish working and saving all the relevant data (RC will start work), '0' ->WC is still working
		data_to_RAM				:	 out std_logic_vector( num_of_signals_g -1 downto 0);	--output the data to be saved in the RAM
		current_array_row		:	 out integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g)) --send to alu_trigg to get start place
		);
end component alu_data;

--	a) find trigger rise according configurations.
--	b) calc the start and end addr of request data according configurations.
component alu_trigger
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
			record_depth_g			: 	positive  	:=	5;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			Add_width_g  		    :   positive 	:=  8      								--width of addr word in the RAM
			);
	port (			
		clk							:	in  std_logic;											--system clk
		reset 						:	in  std_logic;											--reset
		enable						:	in	std_logic;											--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing	
		trigger						:	in	std_logic;											--trigger signal
		trigger_position			:	in  std_logic_vector(  data_width_g -1 downto 0	);					--the percentage of the data to send out
		trigger_type				:	in  std_logic_vector(  data_width_g -1 downto 0	);					--we specify 5 types of triggers	
		addr_in_alu_trigger			:	in  std_logic_vector( signal_ram_depth_g -1 downto 0);		--the addr in the RAM whice the trigger came
		current_array_row_in		:	in 	integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g) ); --the RAM array line which the trigger came from. come from ALU_data
		trigger_to_alu_data			:	out std_logic	;
		wc_to_rc					:	out std_logic_vector( 2 * signal_ram_depth_g -1 downto 0 );	--the start and end addr of the data that we need to send out to the user
																								-- 0-add_width-1 => end addr, add_width-2add_width-1 => start addr					
		start_array_row_out			:	out integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g));	--send with the addr to the RC
		end_array_row_out			:	out integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g));		--send with the addr to the RC
		work_trig_count_out			:	out integer range 0 to (2**signal_ram_depth_g) * up_case(2**record_depth_g , (2**signal_ram_depth_g))
		);	
end component alu_trigger;

-- we need to send the cuurent addr to alu_trigger and to output it to the RAM, so we use in dmultiplexor
component dmux is
	GENERIC (
			signal_ram_depth_g  		    :   positive 	:=  3      								--width of addr word in the RAM
			);
	port
	(
		x	:	in std_logic_vector (signal_ram_depth_g -1 downto 0)	;					
		y	:	out std_logic_vector (signal_ram_depth_g -1 downto 0)	;
		z	:	out std_logic_vector (signal_ram_depth_g -1 downto 0)				
	);	
end component dmux;

--make an internal enable signal according the enable that send from the GUI
component enable_fsm is
	GENERIC (
		reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
		enable_polarity_g		:	std_logic	:=	'1'								--'1' the entity is active, '0' entity not active
		
			);
	port (			
		clk						:	 in  std_logic;										--system clk
		reset 					:	 in  std_logic;										--reset
		enable					:	 in	 std_logic;										--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing	
		rc_finish				:	 in	 std_logic;										--'1' -> read controller finish working, '0' -> system still working
		enable_out				:	 out std_logic										 --enable signal that sent to the core 
		);
end component enable_fsm;

-------------------------------------------------------	signals	--------------------------------------------------------------------------
----signals between ALUs									
signal current_array_row_s				:   integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g));
signal count							: 	integer range 0 to 2**record_depth_g ;			--number of cycles that we continue to work after trigger rise
signal trig_to_alu						:	std_logic ;
signal en_s								:	std_logic ;									--enable signal, sent to the other core parts as an enable signal
----signals from dmux to ALU
signal addr_from_alu_data_to_dmux_s		:	std_logic_vector( signal_ram_depth_g -1 downto 0);
signal addr_from_dmux_to_alu_trigger_s	:	std_logic_vector( signal_ram_depth_g -1 downto 0);

-------------------------------------------------------	Implementation	------------------------------------------------------------------
begin
		enable_ins	:	enable_fsm 	generic map (
											reset_polarity_g 	=>	reset_polarity_g,								--'1' reset active highe, '0' active low
											enable_polarity_g	=>	enable_polarity_g							--'1' the entity is active, '0' entity not active
									)
									port map (			
									clk		=> clk,															--system clk
									reset	=>	reset,														--reset
									enable	=>	enable,												--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing		
									rc_finish => rc_finish,
									enable_out	=> en_s												 --enable signal that sent to the core 
									);

		
		dmux_ins	:	dmux generic map (
											signal_ram_depth_g			=>	signal_ram_depth_g
									)
									port map 	(
											x	=>	addr_from_alu_data_to_dmux_s,					
											y	=>	addr_from_dmux_to_alu_trigger_s,
											z	=>	addr_out_to_RAM
									);
				
		alu_data_inst : alu_data generic map (
											reset_polarity_g 	=>	reset_polarity_g,
											enable_polarity_g	=>	enable_polarity_g,
											signal_ram_depth_g	=>	signal_ram_depth_g,
											signal_ram_width_g 	=>	signal_ram_width_g,
											record_depth_g  	=>	record_depth_g,
											Add_width_g			=>	Add_width_g,
											num_of_signals_g	=>	num_of_signals_g
									)
									port map 	(
									clk	=> clk,															--system clk
									reset	=>	reset,														--reset
									enable	=>	en_s,							--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing	
									data_in	=>	data_in,				--incomming data
									trigger_found_in => trig_to_alu,
									work_count => count,		--number of cycles that we continue to work after trigger rise
									addr_out_alu_data	=>	addr_from_alu_data_to_dmux_s,	--the addr in the RAM to save the data
									aout_valid_alu		=>	aout_valid,			--each time we enable entire row at the RAM array
									wc_finish			=>	write_controller_finish,	--
									data_to_RAM			=>	data_out_of_wc,		--output data to the RAM to be saved
									current_array_row	=>	current_array_row_s	--the current row in the RAM array
									);
		
		alu_trigger_inst : alu_trigger generic map (
									reset_polarity_g	=>		reset_polarity_g,	--'1' reset active highe, '0' active low
									enable_polarity_g	=>		enable_polarity_g,							--'1' the entity is active, '0' entity not active
									signal_ram_depth_g	=>		signal_ram_depth_g,						--depth of RAM
									record_depth_g		=>		record_depth_g,					--number of bits that is recorded from each signal
									data_width_g   		=>		data_width_g,		    -- defines the width of the data lines of the system 
									Add_width_g  		=>		Add_width_g
									)
									port map 	(
									clk		=> 	clk,								--system clk		
									reset	=>	reset, 								--reset
									enable	=>	en_s,								--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing	
									trigger	=>	trigger,							--trigger signal
									trigger_position		=>	trigger_position_in,		--input from core_registers
									trigger_type			=>	trigger_type_in,		--input from core_registers	
									addr_in_alu_trigger		=>	addr_from_dmux_to_alu_trigger_s,	--sent from alu_data
									current_array_row_in	=>	current_array_row_s,
									end_array_row_out		=>	end_array_row_out,
									start_array_row_out		=>	start_array_row_out,
									trigger_to_alu_data 	=> trig_to_alu,
									wc_to_rc				=>	wc_to_rc_out_wc,
									work_trig_count_out		=> count
									);
					
		
 
end architecture behave;
