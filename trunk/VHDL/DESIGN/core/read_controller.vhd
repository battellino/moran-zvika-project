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
--library ieee ;
--use ieee.std_logic_1164.all ;
--use ieee.std_logic_signed.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_misc.all;
--use ieee.numeric_std.all;

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;
library work ;
use work.ram_generic_pkg.all;


---------------------------------------------------------------------------------------------------------------------------------------

entity read_controller is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
--			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
--			signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
--			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
			record_depth_g			: 	positive  	:=	4;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
--			Add_width_g  		    :   positive 	:=  8;     								--width of address word in the RAM
--			num_of_signals_g		:	positive	:=	8;									--number of signals that will be recorded simultaneously
			width_in_g				:	positive 	:= 	8;									--Width of data
			power2_out_g			:	natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
			power_sign_g			:	integer range -1 to 1 	:= 1					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
	);
	port
	(
		clk							:	in std_logic;											--system clock
		reset						:	in std_logic;											--system reset
--		enable						:	in std_logic;											--enabling the entity. if (enable = enable_polarity_g) -> start working, else-> do nothing
		start_addr_in				:	in std_logic_vector( record_depth_g -1 downto 0 );		--the start address of the data that we need to send out to the user
		write_controller_finish		:	in std_logic;											--start output data after wc_finish -> 1
		read_controller_finish		:	out std_logic;											--1-> rc is finish, 0-> other. needed to the enable FSM
--------RAM signals--------
		dout_valid					:	in std_logic;		 									--Output data from RAM valid
		data_from_ram				:	in std_logic_vector (data_wcalc(width_in_g, power2_out_g, power_sign_g) - 1 downto 0);	-- data came from RAM 
		addr_out					:	out std_logic_vector ( record_depth_g - 1 downto 0);	--address send to RAM to output each cycle
		aout_valid					:	out std_logic;											--Output address to RAM is valid
-------- WB signals--------		
		data_out_to_WBM				:	out std_logic_vector (data_width_g - 1 downto 0);		--data out to WBM
		data_out_to_WBM_valid		:	out std_logic											--data out to WBM is valid
	);	
end entity read_controller;

architecture behave of read_controller is
	-- SYMBOLIC ENCODED state machine: State
	type State_type is (
	idle,										--first state, initial all signals
	wait_for_start_address,						--wait for write controller to send the start address
	send_current_address_to_ram,				--calculate the next address which will be sent to the RAM
	get_data_from_ram_and_calc_next_address,	--get the data who come from the RAM
	send_data_to_wbm							--output the data that came from the RAM back to the user via WBS
	);

----------------------------------------------------CONSTANTS---------------------------------------------------------------
constant last_address_c				: std_logic_vector( record_depth_g -1 downto 0 )					:= (others => '1');

----------------------------------------------------SIGNALS-----------------------------------------------------------------
signal State						: State_type;
signal read_controller_counter_s	: integer range 0 to 2**record_depth_g ;
signal current_address_s			: std_logic_vector( record_depth_g -1 downto 0 ) ;		--address of data that is been send to RAM
signal data_from_ram_to_wbs_s		: std_logic_vector( data_width_g - 1 downto 0 ) ;		--data that we extract from RAM and send to WBS
--signal next_address_s				: std_logic_vector( record_depth_g -1 downto 0 ) ;
	
begin
-----------------------------------------------------------------
-- Machine: State
-----------------------------------------------------------------
	State_machine: process (clk, reset)
	
--	variable	cuurent_addr_as_int_v				: 	integer range 0 to 2**record_depth_g ;		--converting the address as integer for easy calculations
	
	begin
		if reset = reset_polarity_g then
			State <= idle;
			read_controller_counter_s <= 0;
			current_address_s <= (others => '0');
			addr_out	<= (others => '0');
			aout_valid <= '0';
			data_out_to_WBM	<= (others => '0');
			data_out_to_WBM_valid <= '0';
			data_from_ram_to_wbs_s 	<= (others => '0');
			read_controller_finish <= '0';
--			next_address_s <= (others => '0');
--			cuurent_addr_as_int_v := 0;
			
		elsif rising_edge(clk) then
--			cuurent_addr_as_int_v := 0;
			
			case State is
				when idle =>						-- start state. initial all signals and variables
					State <= wait_for_start_address ;
					read_controller_counter_s <=  2**record_depth_g ;
					current_address_s <= (others => '0');
					addr_out	<= (others => '0');
					aout_valid <= '0';
					data_out_to_WBM	<= (others => '0');
					data_out_to_WBM_valid <= '0';
					data_from_ram_to_wbs_s 	<= (others => '0');
					read_controller_finish <= '0';
--					next_address_s <= (others => '0');
--					cuurent_addr_as_int_v := 0;
					
				when wait_for_start_address =>		-- write controller finish working. sample the start addr into next_addr_s
					if write_controller_finish = '1' then
						current_address_s <= start_addr_in ;						--getting the start address from the write controller
						State <= send_current_address_to_ram ;
					end if;
				
				when send_current_address_to_ram =>
					data_out_to_WBM_valid <= '0';									--initialize data to WBM valid after (send_data_to_wbm) state
					addr_out <= current_address_s;
					aout_valid <= '1';
					State <= get_data_from_ram_and_calc_next_address ;
					
				when get_data_from_ram_and_calc_next_address =>
					aout_valid <= '0';												--don't continue to sent out an address to the RAM
--					read_controller_counter_s <= read_controller_counter_s - 1 ;	--reduce one from the counter
					if dout_valid = '1' then										--data that came from the RAM is valid (according current_address_s)
						data_from_ram_to_wbs_s <= data_from_ram ;					--sample the data that come from the RAM
						State <= send_data_to_wbm ;
						-- calculating the new address
						if current_address_s = last_address_c then					--current_address_s was the last address	
							current_address_s <= (others => '0');
						else		
							current_address_s <= std_logic_vector( to_unsigned( to_integer( unsigned( current_address_s ) ) + 1 , record_depth_g));	--promote address in one
						end if;
						
					end if;
					
				when send_data_to_wbm =>											--send correct data and change valid to 1
					if read_controller_counter_s = 0 then
						read_controller_finish <= '1';
						State <= idle ;
					else
						data_out_to_WBM_valid <= '1';
						data_out_to_WBM <= data_from_ram_to_wbs_s;
						read_controller_counter_s <= read_controller_counter_s - 1 ;
						State <= send_current_address_to_ram ;
					end if;
			
			end case;
		end if;
	end process;
	
	
end architecture behave;
