------------------------------------------------------------------------------------------------
-- File Name	:	write_controller.vhd
-- Generated	:	07.01.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--			1.The entity gets the incoming data and trigger signals from the signal generator,
--			calculating the address in the RAM that the data will be saved in, and sending the data and address to the RAM. 
--			2.According the configurations that are saved in the core registers, detecting trigger
--			rise and calculating the start address of the outputing data, and send it to the read controller.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		07.01.2013	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			
--			
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;

library work ;
use work.write_controller_pkg.all;

---------------------------------------------------------------------------------------------------------------------------------------

entity write_controller is
	generic (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM is 2^signal_ram_depth_g
			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
			record_depth_g			: 	positive  	:=	4;									--number of bits that are recorded from each signal is 2^record_depth_g
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
		config_are_set				:	in	std_logic;											--'1'-> configurations from registers are ready to be read (trigger position + type). '0'-> config are not ready
		data_out_of_wc				:	out std_logic_vector ( num_of_signals_g -1  downto 0);	--sending the data  to be saved in the RAM. 
		addr_out_to_RAM				:	out std_logic_vector( Add_width_g -1 downto 0);	--the addr in the RAM to save the data
		write_controller_finish		:	out std_logic;											--'1' ->WC has finish working and saving all the relevant data (RC will start work), '0' ->WC is still working
		start_addr_out				:	out std_logic_vector( Add_width_g -1 downto 0 );	--the start addr of the data that we need to send out to the user. send now to RC
		din_valid					:	out std_logic;	--data in valid
---------whishbone signals----------------------------					
		data_in						:	in	std_logic_vector ( num_of_signals_g -1 downto 0);	--data in. comming from user
		trigger						:	in	std_logic											--trigger signal
	
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
	record_data,				--getting the data and the trigger from the WB
	send_start_addr_to_rc,		--send the start addr and the start array row to the Read Controller
	write_controller_is_finish	--wc is finish (read controller is working now), wait until enable signal is fall for another configurations
	);
------------------Signals--------------------
signal 		State					: 	wc_states;
signal		trigger_position_s		:  	std_logic_vector(  6 downto 0	);
signal		trigger_type_s			:	std_logic_vector(  6 downto 0	);
signal		current_data_s			:	std_logic_vector ( num_of_signals_g -1 downto 0);
signal		trigger_found_s			:	std_logic	;							--'1' -> trigger found, '0' -> other
signal		trigger_counter_s		:	integer	range 0 to 2 ;					--for trigger rise when defined as 3 ones\zeroes, we need to count until 2 + correct trigger 
signal		current_address_s		:	std_logic_vector( signal_ram_depth_g -1 downto 0);		--the addr in specific RAM to save the data
signal		current_row_s			:	integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g)) - 1 ;	--row in RAM array of current address
signal		all_data_rec_count_s	:	integer range -1 to 2**record_depth_g ;		--count from number of data to record after trigger rise to 0
signal		trigger_address_s		:	std_logic_vector( signal_ram_depth_g -1 downto 0);		--the addr of the trigger
signal		trigger_row_s			:	integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g)) - 1 ;	--the row of the trigger
------------------	Processes	----------------

begin
							
	State_machine: process (clk, reset)
	
	variable	start_addr_as_int_v				: 	integer range 0 to 2 * total_number_of_rows_c + 2 ;		--saving the address as integer for easy calculations
	variable	trigger_address_as_int_v		: 	integer range 0 to total_number_of_rows_c ;		--saving the address as integer for easy calculations
	variable	rows_to_shift_v					:	integer range 0 to total_number_of_rows_c;		--how many addresses we need to shift from trigger rise to get the start address
	
	begin
		if reset = reset_polarity_g then
			State <= idle;
			data_out_of_wc				<= (others => '0') ;
			addr_out_to_RAM				<= (others => '0') ;
			write_controller_finish		<= '0';	
			start_addr_out				<= (others => '0') ;
			din_valid					<= '0' ;
			trigger_position_s			<= (others => '0') ;
			trigger_type_s				<= (others => '0') ;
			current_data_s				<= (others => '0') ;
			trigger_found_s				<= '0';
			trigger_counter_s			<= 0;
			current_address_s			<= (others => '0') ;
			current_row_s				<= 0;
			all_data_rec_count_s		<= -1;
			trigger_address_s 			<= (others => '0') ;
			trigger_row_s 				<= 0 ;
			start_addr_as_int_v			:= 0 ;
			trigger_address_as_int_v	:= 0 ;
			rows_to_shift_v				:= 0 ;
			
		elsif rising_edge(clk) then
			start_addr_as_int_v			:= 0 ;
			trigger_address_as_int_v	:= 0 ;
			rows_to_shift_v				:= 0 ;
			
			case State is
				when idle =>		-- start state. 
					data_out_of_wc				<= (others => '0') ;
					addr_out_to_RAM				<= (others => '0') ;
					write_controller_finish		<= '0';	
					start_addr_out				<= (others => '0') ;
					din_valid					<=  '0' ;
					trigger_position_s			<= (others => '0') ;
					trigger_type_s				<= (others => '0') ;
					current_data_s				<= (others => '0') ;
					trigger_found_s				<= '0';
					trigger_counter_s			<= 0;
					current_address_s			<= (others => '0') ;
					current_row_s				<= 0;
					all_data_rec_count_s		<= -1;
					trigger_address_s 			<= (others => '0') ;
					trigger_row_s 				<= 0 ;
					start_addr_as_int_v			:= 0 ;
					trigger_address_as_int_v	:= 0 ;
					rows_to_shift_v				:= 0 ;
					State <= set_configurations ;
									
				when set_configurations =>		-- getting config from registers
					if config_are_set = enable_polarity_g then
						trigger_position_s 	<= 	trigger_position_in;
						trigger_type_s		<=	trigger_type_in;
						State <= wait_for_enable_rise ;
						all_data_rec_count_s <= (2**record_depth_g) - (2**record_depth_g) * to_integer( unsigned( trigger_position_in)) / 100 ;	--counter initial value.
																--	the number of bits that we need to record after trigger rise	
					end if;
					
				when wait_for_enable_rise =>
					if enable = enable_polarity_g then
						State <= record_data ;
					else
						state <= wait_for_enable_rise;
					end if;
					
				when record_data =>
					din_valid					<= '1' ;			--enable ram at the start	
					-------getting the data signal 
					current_data_s <= data_in;
					-------check if trigger rise
					if trigger_found_s = '0' then
					--checking if trigger needs to be rise
						case  trigger_type_s(2 downto 0) is				--notice between the different types of triggers
							
							when "000" 	=>					--trig define as rise!! (not one)
								if trigger = '0' then			--for trigger rise, we need at first that trigger will be low
									trigger_counter_s	<= 1 ;
								elsif (trigger_counter_s = 1) and (trigger = '1') then		--we found rise. (prev trigger was 0 and now its 1)
									trigger_counter_s	<= 0 ;
									trigger_found_s 	<= '1' ;
									trigger_address_s 	<= current_address_s ;
									trigger_row_s 		<= current_row_s ;
								else
									trigger_counter_s	<= 0 ;
								end if;
							
							when "001"	=>					--trig define as fall
								if trigger = '1' then			--for trigger fall, we need at first that trigger will be high
									trigger_counter_s	<= 1 ;
								elsif (trigger_counter_s = 1) and (trigger = '0') then		--we found rise. (prev trigger was 0 and now its 1)
									trigger_counter_s	<= 0 ;
									trigger_found_s 	<= '1' ;
									trigger_address_s 	<= current_address_s ;
									trigger_row_s 		<= current_row_s ;
								else
									trigger_counter_s	<= 0 ;
								end if;
							
							when "010"	=>					--trig define as three times high
								if trigger = '1' then
									if trigger_counter_s = 2 then		--trigger is now high and was high in the last two cycles
										trigger_counter_s	<= 0 ;
										trigger_found_s 	<= '1' ;
										trigger_address_s 	<= current_address_s ;
										trigger_row_s 		<= current_row_s ;
									else								--trigger is high but not 3 times sequential
										trigger_counter_s	<= trigger_counter_s + 1 ;
									end if;
								else									--trigger low, reset trigger counter
									trigger_counter_s	<= 0 ;
								end if;
								
							when "011"	=>				--trig define as three times low
								if trigger = '0' then
									if trigger_counter_s = 2 then		--trigger is now low and was low in the last two cycles
										trigger_counter_s	<= 0 ;
										trigger_found_s 	<= '1' ;
										trigger_address_s 	<= current_address_s ;
										trigger_row_s 		<= current_row_s ;
									else								--trigger is low but not 3 times sequential 
										trigger_counter_s	<= trigger_counter_s + 1 ;
									end if;
								else									--trigger high, reset trigger counter
									trigger_counter_s	<= 0 ;
								end if;
								
							when "100"	=>								--special trigger, not relevant to us now
								trigger_counter_s	<= 0 ;
								
							when others =>								--not valid!! 
								trigger_counter_s	<= 0 ;
						
						end case;
					end if;
					
					--send out data and address to be save in the RAM
					data_out_of_wc <= current_data_s ;
					addr_out_to_RAM <= std_logic_vector( to_unsigned( to_integer( unsigned( current_address_s ) ) + ( (2**signal_ram_depth_g) *  current_row_s ) , record_depth_g));
					
					-- calc next address and RAM array row
					if (current_row_s = (number_of_ram_c - 1) ) and (current_address_s = std_logic_vector(to_unsigned(last_addr_in_last_ram_c, signal_ram_depth_g))) then --we in last permitted address
						current_row_s <= 0;								--getting first address in the array
						current_address_s <= (others => '0');
										
					elsif (to_integer( unsigned( current_address_s ) ) = (2**signal_ram_depth_g - 1) ) then
						current_address_s <= (others => '0') ;
						current_row_s <= current_row_s + 1 ;

					else
						current_address_s <= std_logic_vector( to_unsigned( to_integer( unsigned( current_address_s ) ) + 1 , signal_ram_depth_g));
					end if;
				
					--check if we need to continue save data
					if ((all_data_rec_count_s = -1) and (trigger_found_s = '1')) then	--trigger was found and we dont need to save more data
						State <= send_start_addr_to_rc ;
						din_valid <= '0' ;
					elsif (trigger_found_s = '1') then								--trigger found but we did not finish to save all the data
						all_data_rec_count_s <= all_data_rec_count_s - 1 ;
						State <= record_data ;
						din_valid <= '1' ;
					else															--trigger not found, continue save data
						State <= record_data ;
						din_valid <= '1' ;
					end if;	
					
					
				when send_start_addr_to_rc =>
				
					rows_to_shift_v := total_number_of_rows_c - (total_number_of_rows_c *  to_integer( unsigned( trigger_position_s ) ) ) / 100 ;
					trigger_address_as_int_v := trigger_row_s * (2**signal_ram_depth_g) + to_integer( unsigned( trigger_address_s)) ;
					start_addr_as_int_v := trigger_address_as_int_v + rows_to_shift_v + 2 ;					-- +2 comes from delay that we have in the addresses
					
					if ( (start_addr_as_int_v) > (total_number_of_rows_c - 1 ) ) then
						start_addr_as_int_v := start_addr_as_int_v - total_number_of_rows_c ;					--make a cyclec addresses
					end if;
					
					start_addr_out <= std_logic_vector(to_unsigned(start_addr_as_int_v, Add_width_g));
					State <= write_controller_is_finish ;

				when write_controller_is_finish =>
					write_controller_finish <= '1' ;
						State <= idle ;
						
				when others =>
						State <= idle ;

			end case;
		end if;
	end process State_machine;
--------------------------------------------------------------------------
end architecture behave;