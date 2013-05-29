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
--			conect core_registers -> set_configurations state
--			trigger_position\type is now data_width_g -1 to 0. 
--			connect WB (ACK_I,data_in is a whishbone signal)
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;

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
		trigger_position_in			:	in  std_logic_vector(  data_width_g -1 downto 0	);		--the percentage of the data to send out
		trigger_type_in				:	in  std_logic_vector(  data_width_g -1 downto 0	);		--we specify 5 types of triggers	
		data_out_of_wc				:	out std_logic_vector ( num_of_signals_g -1  downto 0);	--sending the data  to be saved in the RAM. 
		addr_out_to_RAM				:	out std_logic_vector( signal_ram_depth_g -1 downto 0);	--the addr in the RAM to save the data
		write_controller_finish		:	out std_logic;											--'1' ->WC has finish working and saving all the relevant data (RC will start work), '0' ->WC is still working
		start_addr_out				:	out std_logic_vector( signal_ram_depth_g -1 downto 0 );	--the start addr of the data that we need to send out to the user. send now to RC
		start_array_row_out			:	out integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g));	--send with the addr to the RC
		din_valid					:	out std_logic_vector( up_case(2**record_depth_g , (2**signal_ram_depth_g)) -1  downto 0	);	--send to the RAM. each time we enable entire row at the RAM array		
---------whishbone signals----------------------------					
		data_in						:	in	std_logic_vector ( num_of_signals_g -1 downto 0);	--data in. comming from user
		trigger						:	in	std_logic;											--trigger signal
		data_in_valid				:	in	std_logic;											--1-> data in is valid, 0-> data not valid
		trigger_in_valid			:	in	std_logic											--1-> trigger in is valid, 0->  trigger not valid
	);	
end entity write_controller;

architecture behave of write_controller is

------------------Constants------
constant	total_number_of_rows_c	:	natural := (2**signal_ram_depth_g) * up_case(2**record_depth_g , 2**signal_ram_depth_g)	  ; --number of "lines" in the total RAM array (depth, not width)
constant	last_addr_in_last_ram_c	:	natural :=  ((2**signal_ram_depth_g)) - (total_number_of_rows_c - 2**record_depth_g) -1 	; -- to find the addr of the last word
										-- in the last RAM we take one RAM and subtract the number of total rows minus the rows that we need to save data in
constant	number_of_ram_c			:	natural := up_case(2**record_depth_g , (2**signal_ram_depth_g))	;		--total number of RAM
-------------------------Types------
type wc_states is (
	idle,						--initial state,vriables are initialized.
	set_configurations,			--getting all the configurations from the registers (trigger position\type)
	wait_for_enable_rise,		--all the cofigurations are set, waiting for enable rise.
	get_new_data_and_trigger,	--getting the data and the trigger from the WB
	check_for_trigger_rise,		--check according the configurations if trigger rise
	send_out_data_and_addr,		--send the data with the correct address to the RAM and enable the correct RAM array through din_valid
	check_if_all_data_recorded,	--determine if we continue to save data or if we already have all of it
	calc_next_addr_for_data,	--calculate the address of the new data in the RAM 
	send_start_addr_to_rc,		--send the start addr and the start array row to the Read Controller
	write_controller_is_finish		--wc is finish (read controller is working now), wait until enable signal is fall for another configurations
	);
------------------Signals--------------------
signal State: wc_states;
signal		config_set_s			:	std_logic	;							--1 => we get trigger position\type from registers into signals
signal		trigger_position_s		:  	std_logic_vector(  data_width_g -1 downto 0	);	--saving
signal		trigger_type_s			:	std_logic_vector(  data_width_g -1 downto 0	);	
signal		current_data_s			:	std_logic_vector ( num_of_signals_g -1 downto 0);
signal		current_trigger_s		:	std_logic	;
signal		trigger_found_s			:	std_logic	;							--'1' -> trigger found, '0' -> other
signal		trigger_counter_s		:	integer	range 0 to 2 ;					--for trigger rise when defined as 3 ones\zeroes, we need to count until 2 + correct trigger 
signal		current_address_s		:	std_logic_vector( signal_ram_depth_g -1 downto 0);		--the addr in specific RAM to save the data
signal		current_row_s			:	integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g)) ;	--row in RAM array of current address
signal		din_valid_s				:	std_logic_vector( up_case(2**record_depth_g , (2**signal_ram_depth_g)) -1  downto 0	);	---- enable entire row at the RAM array
signal		all_data_rec_count_s	:	integer range 0 to record_depth_g ;		--count from number of data to record after trigger rise to 0
------------------	Processes	----------------

begin
							
	State_machine: process (clk, reset)
	
	variable	start_addr_as_int_v				: 	integer range 0 to 2 * total_number_of_rows_c := 0;		--saving the address as integer for easy calculations
	variable	current_address_as_int_v		: 	integer range 0 to 2 * total_number_of_rows_c := 0;		--saving the address as integer for easy calculations
	variable	start_ram_row_v					:	integer range 0 to number_of_ram_c 			  := 0;
	
	begin
		if reset = reset_polarity_g then
			State <= idle;
			data_out_of_wc				<= (others => '0') ;
			addr_out_to_RAM				<= (others => '0') ;
			write_controller_finish		<= '0';	
			start_addr_out				<= (others => '0') ;
			start_array_row_out			<= 0;
			din_valid					<= (others => '0') ;
			config_set_s				<= '0';
			trigger_position_s			<= (others => '0') ;
			trigger_type_s				<= (others => '0') ;
			current_data_s				<= (others => '0') ;
			current_trigger_s			<= '0';
			trigger_found_s				<= '0';
			trigger_counter_s			<= 0;
			current_address_s			<= (others => '0') ;
			current_row_s				<= 0;
			din_valid_s					<= (others => '0') ;
			all_data_rec_count_s		<= 0;
			
		elsif rising_edge(clk) then
						
			case State is
				when idle =>		-- start state. 
						State <= set_configurations ;
									
				when set_configurations =>		-- getting config from registers
					trigger_position_s 	<= 	trigger_position_in;
					trigger_type_s		<=	trigger_type_in;
					State <= wait_for_enable_rise ;
					all_data_rec_count_s <= record_depth_g * ( 1 - to_integer( unsigned( trigger_position_in(7 downto 0))) / 100 );	--counter initial value.
															--	the number of clk cycles that we need to continue working in order to save all the data
						
					
				when wait_for_enable_rise =>
					if enable = enable_polarity_g then
						State <= get_new_data_and_trigger ;
					else
						state <= wait_for_enable_rise;
					end if;
					
				when get_new_data_and_trigger =>
					if (data_in_valid = '1') and (trigger_in_valid = '1') then
						current_data_s <= data_in;
						current_trigger_s <= trigger;
						State <= check_for_trigger_rise ;
					else
						State <= get_new_data_and_trigger ;
					end if;
					
				when check_for_trigger_rise =>
					--checking if trigger needs to be rise
					case  trigger_type_s(2 downto 0) is				--notice between the different types of triggers
						
						when "000" 	=>					--trig define as rise!! (not one)
							if current_trigger_s = '0' then			--for trigger rise, we need at first that trigger will be low
								trigger_counter_s	<= 1 ;
								State <= send_out_data_and_addr ;
							elsif (trigger_counter_s = 1) and (current_trigger_s = '1') then		--we found rise. (prev trigger was 0 and now its 1)
								trigger_counter_s	<= 0 ;
								trigger_found_s 	<= '1' ;
								State <= send_out_data_and_addr ; 
							else
								trigger_counter_s	<= 0 ;
								State <= send_out_data_and_addr ; 
							end if;
						
						when "001"	=>					--trig define as fall
							if current_trigger_s = '1' then			--for trigger fall, we need at first that trigger will be high
								trigger_counter_s	<= 1 ;
								State <= send_out_data_and_addr ;  
							elsif (trigger_counter_s = 1) and (current_trigger_s = '0') then		--we found rise. (prev trigger was 0 and now its 1)
								trigger_counter_s	<= 0 ;
								trigger_found_s 	<= '1' ;
								State <= send_out_data_and_addr ;
							else
								trigger_counter_s	<= 0 ;
								State <= send_out_data_and_addr ;
							end if;
						
						when "010"	=>					--trig define as three times high
							if current_trigger_s = '1' then
								if trigger_counter_s = 2 then		--trigger is now high and was high in the last two cycles
									trigger_counter_s	<= 0 ;
									trigger_found_s 	<= '1' ;
									State <= send_out_data_and_addr ;
								else								--trigger is high but not 3 times sequential
									trigger_counter_s	<= trigger_counter_s + 1 ;
									State <= send_out_data_and_addr ;
								end if;
							else									--trigger low, reset trigger counter
								trigger_counter_s	<= 0 ;
								State <= send_out_data_and_addr ;
							end if;
							
						when "011"	=>				--trig define as three times low
							if current_trigger_s = '0' then
								if trigger_counter_s = 2 then		--trigger is now low and was low in the last two cycles
									trigger_counter_s	<= 0 ;
									trigger_found_s 	<= '1' ;
									State <= send_out_data_and_addr ;
								else								--trigger is low but not 3 times sequential 
									trigger_counter_s	<= trigger_counter_s + 1 ;
									State <= send_out_data_and_addr ;
								end if;
							else									--trigger high, reset trigger counter
								trigger_counter_s	<= 0 ;
								State <= send_out_data_and_addr ;
							end if;
							
						when "100"	=>								--special trigger, not relevant to us now
							trigger_counter_s	<= 0 ;
							State <= send_out_data_and_addr ;
						
						when others =>								--not valid!! 
							trigger_counter_s	<= 0 ;
							State <= send_out_data_and_addr ;
					
					end case;
					
				when send_out_data_and_addr =>
					data_out_of_wc <= data_in ;
					addr_out_to_RAM <= current_address_s ;
					din_valid <= din_valid_s ;
					State <= check_if_all_data_recorded ;
				
				when check_if_all_data_recorded =>
					din_valid <= (others => '0') ;
					if (all_data_rec_count_s = 0) and (trigger_found_s = '1') then	--trigger was found and we dont need to save more data
						State <= send_start_addr_to_rc ;
					elsif (trigger_found_s = '1') then								--trigger found but we did not finish to save all the data
						State <= calc_next_addr_for_data ;
						all_data_rec_count_s <= all_data_rec_count_s - 1 ;
					else															--trigger was not found
						State <= calc_next_addr_for_data ;
					end if;
					
				when calc_next_addr_for_data =>										-- calc next address and RAM array row
					
					if (current_row_s = number_of_ram_c - 1) and (current_address_s = std_logic_vector(to_unsigned(last_addr_in_last_ram_c, signal_ram_depth_g))) then --we in last permitted address
						current_row_s <= 0;								--getting first address in the array
						current_address_s <= (others => '0');
						State <= get_new_data_and_trigger ;
										
					elsif (to_integer( unsigned( current_address_s ) ) = signal_ram_depth_g - 1) then
						current_address_s <= (others => '0') ;
						current_row_s <= current_row_s + 1 ;
						State <= get_new_data_and_trigger ;

					else
						current_address_s <= std_logic_vector( to_unsigned( to_integer( unsigned( current_address_s ) ) + 1 , signal_ram_depth_g));
						State <= get_new_data_and_trigger ;

					end if;
					
					din_valid(current_row_s) <= '1' ;					-- update din valid according new array row
					
				when send_start_addr_to_rc =>
					current_address_as_int_v := current_row_s * (2**signal_ram_depth_g) + to_integer( unsigned( current_address_s)) ;
					start_addr_as_int_v := current_address_as_int_v + total_number_of_rows_c * ( to_integer( unsigned( trigger_position_in(7 downto 0))) / 100 ) ;
					
					if start_addr_as_int_v > total_number_of_rows_c then
						start_addr_as_int_v := start_addr_as_int_v - total_number_of_rows_c ;
					end if;
					
					start_ram_row_v := up_case( start_addr_as_int_v, 2**signal_ram_depth_g );	--calc the ram row of the address send to the RC
					start_addr_as_int_v := start_addr_as_int_v - start_ram_row_v * (2**signal_ram_depth_g) ; --start address in single ram (as integer)
					
					start_addr_out <= std_logic_vector(to_unsigned(start_addr_as_int_v, signal_ram_depth_g));
					start_array_row_out <= start_ram_row_v ; 
					State <= write_controller_is_finish ;

				when write_controller_is_finish =>
					write_controller_finish <= '1' ;
					if enable = '0' then
						State <= idle ;
					else
						State <= write_controller_is_finish ;
					end if;
						
				when others =>
						State <= idle ;

			end case;
		end if;
	end process State_machine;
--------------------------------------------------------------------------
end architecture behave;