------------------------------------------------------------------------------------------------
-- Model Name 	:	Generic RAM TB
-- File Name	:	generic_ram_tb.vhd
-- Generated	:	15.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		15.12.2010	Beeri Schreiber					Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) Extend RAM to use input width > output width
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work ;
use work.write_controller_pkg.all;

entity write_controller_tb is
	generic (
				read_loop_iter_g	:	positive	:= 20;									--Number of iterations
				
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	10;									--depth of RAM
			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
			record_depth_g			: 	positive  	:=	10;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
			num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
end entity write_controller_tb;

architecture arc_write_controller_tb of write_controller_tb is

component write_controller 
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	10;									--depth of RAM
			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
			record_depth_g			: 	positive  	:=	10;									--number of bits that is recorded from each signal
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
		data_in						:	in	std_logic_vector ( num_of_signals_g downto 0);	--miss (-1) on purpose adding the trigger signal. trigger is data_in(0)
		wc_to_rc_out_wc				:	out std_logic_vector ((2 * Add_width_g ) - 1 downto 0);	--start and end addr of data needed to output. send to RC
		data_out_of_wc				:	out std_logic_vector ( num_of_signals_g  downto 0);		--sending the data + trigger to be saved in the RAM. trigger is data_in_RAM(0)
		addr_out_to_RAM				:	out std_logic_vector( Add_width_g -1 downto 0);		--the addr in the RAM to save the data
		trigger_found_out_wc		:	out std_logic;								--'1' ->trigger rise (up for one cycle), '0' ->trigger not rise
		start_array_row_out			:	out integer range 0 to up_case(record_depth_g , signal_ram_depth_g);	--send with the addr to the RC
		end_array_row_out			:	out integer range 0 to up_case(record_depth_g , signal_ram_depth_g)	;	--send with the addr to the RC
		aout_valid					:	out std_logic_vector( up_case(record_depth_g , signal_ram_depth_g) -1  downto 0	)	--send to the RAM. each time we enable entire row at the RAM array		
		
	);	
end component write_controller;

----------------------   Signals   ------------------------------


signal clk			: std_logic := '0';													--System clock
signal reset		: std_logic := '0';	
signal enable		: std_logic := '0';													--System Reset
signal trigger_position_in :  std_logic_vector(  data_width_g -1 downto 0	) := (others => '0'); 	--Input address
signal trigger_type_in				:std_logic_vector(  data_width_g -1 downto 0	) := (others => '0'); 		--Output address
signal trigger			: std_logic := '0';	
signal data_in						:std_logic_vector ( num_of_signals_g downto 0) := (others => '0');	--miss (-1) on purpose adding the trigger signal. trigger is data_in(0)
signal wc_to_rc_out_wc				:	 std_logic_vector ((2 * Add_width_g ) - 1 downto 0) := (others => '0');	--start and end addr of data needed to output. send to RC													--Output address is valid
signal data_out_of_wc				:	std_logic_vector ( num_of_signals_g  downto 0) := (others => '0');		--sending the data + trigger to be saved in the RAM. trigger is data_in_RAM(0)

signal 	trigger_found_out_wc		:	 std_logic := '0';	
signal addr_out_to_RAM				:	 std_logic_vector( Add_width_g -1 downto 0) := (others => '0');		--the addr in the RAM to save the data
signal start_array_row_out:	 integer range 0 to up_case(record_depth_g , signal_ram_depth_g) := 0;	--send with the addr to the RC

signal end_array_row_out:  integer range 0 to up_case(record_depth_g , signal_ram_depth_g) := 0	;	--send with the addr to the RC

signal aout_valid	:  std_logic_vector( up_case(record_depth_g , signal_ram_depth_g) -1  downto 0	):=(others => '0');	--send to the RAM. each time we enable entire row at the RAM array		
												--Output data valid

--Internal Signals
--signal end_din`		: boolean := false;													--TRUE when end of writing to RAM

-------------------  Implementation ----------------------------
begin

			
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
								clk			=> clk,
								reset		=> reset,			
								enable		=> enable,		
								trigger_position_in	=> trigger_position_in,	
								trigger_type_in		=> trigger_type_in	,
								trigger => trigger,
								data_in		=> data_in,		
								wc_to_rc_out_wc	=> wc_to_rc_out_wc,	
								data_out_of_wc	=> data_out_of_wc,	
								addr_out_to_RAM	=> addr_out_to_RAM,
								trigger_found_out_wc	=> trigger_found_out_wc,
								start_array_row_out	=> start_array_row_out,
								end_array_row_out	=> end_array_row_out,
								aout_valid	=> aout_valid
								);

clk_proc : 
	clk <= not clk after 50 ns;
	
res_proc :
	reset <= reset_polarity_g, not reset_polarity_g after 130 ns;
	
en_proc :
	enable <= enable_polarity_g;

	------
trigg_proc :
	trigger <= '0', '1' after 300 ns;

trigg_pos_proc :	
	trigger_position_in <= "01100100" ;

trigg_type_proc :	
	trigger_type_in <= "00000000" ;
	
	data_proc : process 
	begin
		for idx in 0 to read_loop_iter_g  - 1 loop
			wait until rising_edge(clk);
			data_in 	<= std_logic_vector (to_unsigned(idx, num_of_signals_g +1)); 	--Input data 
		end loop;
		wait ;
	end process data_proc;

	------


end architecture arc_write_controller_tb;
