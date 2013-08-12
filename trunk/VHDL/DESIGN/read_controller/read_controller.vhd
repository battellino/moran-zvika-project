------------------------------------------------------------------------------------------------
-- File Name	:	read_controller.vhd
-- Generated	:	9.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--				The read controller get the start and end addr of the valid data that was calculated in the write controller (wc_to_rc).
--				and extract the correct data from the RAM and send it out through the WBM
-- 					
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date			Name							Description			
--			1.0			9.11.2012		Zvika Pery						Creation	
--			1.1			22.1.2013		Zvika Pery						adapting to WC signals
------------------------------------------------------------------------------------------------
--	Todo:
--			
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
library work ;
use work.write_controller_pkg.all;
---------------------------------------------------------------------------------------------------------------------------------------

entity read_controller is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
			record_depth_g			: 	positive  	:=	10;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
			num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
	);
	port
	(
		clk							:	in std_logic;											--system clock
		reset						:	in std_logic;											--system reset
		enable						:	in std_logic;											--enabling the entity. if (enable = enable_polarity_g) -> start working, else-> do nothing
		trigger_found				:	in std_logic;											--trigger rise was found
		wc_to_rc					:	in std_logic_vector((2*(2**signal_ram_depth_g)) - 1 downto 0);		--start and end addr of data needed to output
		start_array_row_in			:	in integer range 0 to up_case(record_depth_g , signal_ram_depth_g);	--send with the addr to the RC
		end_array_row_in			:	in integer range 0 to up_case(record_depth_g , signal_ram_depth_g);		--send with the addr to the RC
		data_in_rc					:	in std_logic_vector(data_width_g - 1 downto 0);	-- getting data from RAM according calc addr
		dout_valid					:	in std_logic;									--output data valid
		data_out_to_WBM				:	out std_logic_vector (data_width_g - 1 downto 0);		--data out to WBM
		addr_out					:	out std_logic_vector ((2**signal_ram_depth_g) - 1 downto 0)		--addr send to RAM to output each cycle
	);	
end entity read_controller;

architecture behave of read_controller is
	-- SYMBOLIC ENCODED state machine: State
	type State_type is (
	idle, wait_for_trigger, set_st_ed_addr, send_add_to_ram, get_data_from_ram,calc_next_addr
	);

signal State: State_type;
	
	
begin
-----------------------------------------------------------------
-- Machine: State
-----------------------------------------------------------------
	State_machine: process (clk, reset)
	begin
		if reset = '1' then
			State <= idle;
		elsif rising_edge(clk) then
			
			case State is
				when idle =>		-- start state. cheack reset and enable
					if (enable = enable_polarity_g) and (reset != reset_polarity_g) then
						State <= wait_for_trigger ;
					end if;
				
				when wait_for_trigger =>		-- waiting for WC to detect trigger rise
					if reset = reset_polarity_g then
						State <= idle ;
					elsif trigger_found = 1 then
						State <= set_st_ed_addr ;
					end if;
				
				when set_st_ed_addr =>
					if reset = reset_polarity_g then
						State <= idle ;
					else		--get start and end addresses
						
						State <= send_add_to_ram ;
					end if;
					
				when send_add_to_ram =>
					if reset = reset_polarity_g then
						State <= idle ;
					elsif dout_valid = '1' then
						State <= get_data_from_ram ;
					end if;
					
				when get_data_from_ram =>
					if reset = reset_polarity_g then
						State <= idle ;
					elsif ACK_I = '1' then
						State <= calc_next_addr ;
					end if;
					
				when calc_next_addr =>
					if reset = reset_polarity_g then
						State <= idle ;
					elsif --curent addr = end addr then
						State <= wait_for_trigger ;
					else 
						State <= send_add_to_ram ;
					end if;
	end process;
	
	
end architecture behave;
