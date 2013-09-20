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
use ieee.numeric_std.all;
library work ;
use work.ram_generic_pkg.all;


---------------------------------------------------------------------------------------------------------------------------------------

entity read_controller is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
			record_depth_g			: 	positive  	:=	4;									--number of bits that is recorded from each signal
			data_width_g            :	positive 	:= 	6;      						    -- defines the width of the data lines of the system 
			num_of_signals_g		:	positive	:=	8;									--number of signals that will be recorded simultaneously
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
		data_from_ram				:	in std_logic_vector (num_of_signals_g - 1 downto 0);	-- data came from RAM 
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
constant size_of_input_data_c		: integer range 0 to num_of_signals_g								:= num_of_signals_g;
constant size_of_output_data_c		: integer range 0 to data_width_g									:= data_width_g;
----------------------------------------------------SIGNALS-----------------------------------------------------------------
signal State						: State_type;
signal read_controller_counter_s	: integer range 0 to 2**record_depth_g ;
signal current_address_s			: std_logic_vector( record_depth_g -1 downto 0 ) ;		--address of data that is been send to RAM
signal data_from_ram_to_wbs_s		: std_logic_vector( data_width_g - 1 downto 0 ) ;		--data that we extract from RAM and send to WBS
signal remain_length_s				: integer range 0 to num_of_signals_g ;
signal next_output_s				: integer range 0 to num_of_signals_g ;
	
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
			remain_length_s <= 0;
			next_output_s <= 0;
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
					remain_length_s <= 0;
					next_output_s <= 0;
					
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
					if dout_valid = '1' then										--data that came from the RAM is valid (according current_address_s)
						if (size_of_input_data_c = size_of_output_data_c) then
								data_from_ram_to_wbs_s <= data_from_ram ;					--sample the data that come from the RAM	
						elsif ( size_of_input_data_c < size_of_output_data_c) then
							for i in 0 to size_of_input_data_c  - 1 loop
								data_from_ram_to_wbs_s(i) <= data_from_ram(i)  ;
								data_from_ram_to_wbs_s(data_width_g -1 downto num_of_signals_g) <= (others => '0') ;
							end loop;
						else										--output data is smaller then input data
							remain_length_s <= size_of_input_data_c;
							next_output_s <= 0;
						end if;
						
						-- calculating the new address
						if current_address_s = last_address_c then					--current_address_s was the last address	
							current_address_s <= (others => '0');
						else		
							current_address_s <= std_logic_vector( to_unsigned( to_integer( unsigned( current_address_s ) ) + 1 , record_depth_g));	--promote address in one
						end if;
					State <= send_data_to_wbm ;
					end if;
					
				when send_data_to_wbm =>											--send correct data and change valid to 1
					if read_controller_counter_s = 0 then
						read_controller_finish <= '1';
						State <= idle ;
					
					elsif (remain_length_s > 0) then								--output data is smaller then input data
						
						if remain_length_s = size_of_output_data_c then				--we finish to output the current input data
							data_out_to_WBM_valid <= '1';
							data_out_to_WBM <= data_from_ram(size_of_input_data_c -1 downto remain_length_s);
							read_controller_counter_s <= read_controller_counter_s - 1 ;
							remain_length_s <= 0;
							next_output_s <= 0;
							State <= send_current_address_to_ram ;
					
						elsif remain_length_s < size_of_output_data_c then				--we finish to output the data but need to fill in 0 to get valid output length
							data_out_to_WBM_valid <= '1';
							read_controller_counter_s <= read_controller_counter_s - 1 ;
							
							for i in 0 to remain_length_s  - 1 loop
							data_out_to_WBM(i) <= data_from_ram(next_output_s + i) ;
							end loop;
							data_out_to_WBM(size_of_output_data_c - 1 downto remain_length_s) <= (others => '0');
							remain_length_s <= 0;
							next_output_s <= 0;
							State <= send_current_address_to_ram ;
							
						else								-- we do not finish to output the data (remain_length_s > size_of_output_data_c)
							data_out_to_WBM_valid <= '1';
							data_out_to_WBM <= data_from_ram(size_of_output_data_c + next_output_s - 1 downto next_output_s  );
							remain_length_s <= remain_length_s - size_of_output_data_c;
							next_output_s <= next_output_s + size_of_output_data_c;
							State <= send_data_to_wbm ;									--stay in output data state
						end if;
						
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
