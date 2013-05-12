------------------------------------------------------------------------------------------------------------
-- File Name	:	alu_trigger.vhd
-- Generated	:	3.12.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------------------
-- Description: 
--				check trigger rise according the configurations.
--
--				kinds of triggers and their simbols:
--
--							rise			fall		one (for 3 clk cyc)			zero(for 3 clk cyc)		special
--							    __		    __			 	   _____						__
--							 __|			  |__			__|								  |_____	 	  ---
--
-- trigger type :			"000"			"001"			"010"						"011"				 "100"
--			
--trigger position: range- 0 to 100 -> the percentage of the data before!! trigger rise that we want to send out
--					therefore in binary the range is between 0000000 to 1100100 
--
--start/end addr:
--	geting values between 0 to depth_of_ram*num_of_row_in_ram_array
--addr 0	*****	*****
--addr 1	*	*	*	*
--addr 2	*	*	*	*
--addr 3	*****	*****
--
--addr 4	*****	*****
--addr 5	*	*	*	*
--addr 6	*	*	*	*
--addr 7	*****	*****
--
--
--
------------------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		3.12.2012	Zvika Pery						Creation		
--			1.01		4.1.2013	zvika pery						adding data_width_g	
--			1.02		12.4.2013	zvika pery						fix trigger rise second time
------------------------------------------------------------------------------------------------------------
--	Todo:
--			
--					
------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;


library work ;
use work.write_controller_pkg.all;

------------------------------------------------------------------------------------------------------------
entity alu_trigger is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM will be 2^(signal_ram_depth_g)
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
		current_array_row_in		:	in 	integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g) ); --the RAM array line which the trigger came from.
		trigger_found				:	out std_logic	;										-- 1  we found the trigger, 0 we have not
		trigger_to_alu_data			:	out std_logic	;										-- 1  we found the trigger, 0 we have not
		wc_to_rc					:	out std_logic_vector( 2 * (signal_ram_depth_g) -1 downto 0 );	--the start and end addr of the data that we need to send out to the user
																								-- 0-add_width-1 => end addr, add_width-2add_width-1 => start addr					
		start_array_row_out			:	out integer range 0 to up_case(2**record_depth_g , 2**signal_ram_depth_g);	--send with the addr to the RC
		end_array_row_out			:	out integer range 0 to up_case(2**record_depth_g , 2**signal_ram_depth_g)	;	--send with the addr to the RC
		work_trig_count_out			:	out integer range 0 to (2**signal_ram_depth_g) * up_case(2**record_depth_g , (2**signal_ram_depth_g))	--how many cycles we continue after trigg found
		);
end entity alu_trigger;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of alu_trigger is
------------------Constants------
constant	total_number_of_rows_c	:	natural := (2**signal_ram_depth_g) * up_case(2**record_depth_g , 2**signal_ram_depth_g)	  ; --number of "lines" in the total RAM array (depth, not width)
constant	last_addr_in_last_ram_c	:	natural :=  ((2**signal_ram_depth_g)) - (total_number_of_rows_c - 2**record_depth_g) -1 	; -- to find the addr of the last word
										-- in the last RAM we take one RAM and subtract to number of total rows minus the rows that we need to save data in
constant	number_of_ram_c			:	natural := up_case(2**record_depth_g , (2**signal_ram_depth_g))	;		--total number of RAM
-------------------------Types------

------------------Signals--------------------

signal	time_since_trig_rise_s 	:	integer range 0 to 3 	; 	--count the cycles that passed since the trigger was first rise, (change to one when we find first rise)
																	--we will use in this signal at value 3 to mark that trigger is found (trigger_found = '1' after   
																	-- 	time_since_trig_rise_s = 3)
signal	rows_to_shift_s			:	integer range 0 to  total_number_of_rows_c	;	--calc how rows we shift according user configuration (trigg position)
--signal	first_cycle_s			:	integer range -1 to 1 ;							-- value -1 if we in the first cycle after reset, 0 other
signal	rise_trig_counter_s		:	integer range -1 to total_number_of_rows_c	;	--when trigger rise, we change that signal to his maximum, because that is the number 
--																					of cycles that we need to wait until all data is sent out from the RAM to the user
--																					and we can check again for trigger rise
------------------	Processes	----------------

begin
---------------------------write process, (when trigger found off or we haven't save all the data)-------------------------------------	
	find_trig_pros	:	process (reset, clk)			
		variable trigger_found_v		:	std_logic	:= '0'	;
		variable time_since_trig_rise_v	:	integer range 0 to 3	:= 0 	;
		variable rise_trig_counter_v	:	integer range -1 to total_number_of_rows_c	:=0	;
		
		begin												
			if  reset = Reset_polarity_g then 														--reset is on
				--reseting all the variables						
	
				trigger_found_v 		:= '0'  ;
				time_since_trig_rise_v := 0;
				rise_trig_counter_v := 0;
				rows_to_shift_s <=	0	;
--				time_since_trig_rise_s	<=	0	;
--				trigger_found	<= 	'0';
--				trigger_to_alu_data	<= 	'0';
--				rise_trig_counter_s <= (-1)	;
			elsif rising_edge(clk) then																--reset off, 					
					--check if trigger was rised in previous cycle
					rows_to_shift_s <=	(to_integer( unsigned( trigger_position(7 downto 0))) * total_number_of_rows_c) / 100	;
				if	enable = enable_polarity_g then					--enable is on
					if (trigger_found_v = '1') and (rise_trig_counter_s > 0) then -- first cycle after trigger found, down trig rise
--						time_since_trig_rise_s	<=	0	;	
						time_since_trig_rise_v	:=	0	;
						trigger_found_v			:= '0'  ;
						rise_trig_counter_v := rise_trig_counter_s -1 ;
--						rise_trig_counter_s <= rise_trig_counter_s -1 ;
					elsif (trigger_found_v = '0') and (rise_trig_counter_s > 0) then 			-- wait until search again for trigger
--						rise_trig_counter_s <= rise_trig_counter_s -1 ;					--every cycle, counter decrease in one
						rise_trig_counter_v	:= rise_trig_counter_s -1 ;
					else
						--checking if trigger needs to be rise
						case  trigger_type(2 downto 0) is				--notice between the different types of triggers
							when "000" 	=>					--trig define as rise
								if trigger = '1' then
									rise_trig_counter_v	:= total_number_of_rows_c ;
									time_since_trig_rise_v := 3 ;
									trigger_found_v := '1' ;
--									time_since_trig_rise_s <= 3 ;
--									rise_trig_counter_s <= total_number_of_rows_c ; 
								end if;
							when "001"	=>					--trig define as fall
								if trigger = '0' then
									time_since_trig_rise_v := 3 ;
									rise_trig_counter_v := total_number_of_rows_c ;
									trigger_found_v := '1' ;
--									time_since_trig_rise_s <= 3 ;
--									rise_trig_counter_s <= total_number_of_rows_c ;
								end if;
							when "010"	=>					--trig define as one
								if trigger = '1' then		--trig is up
									if time_since_trig_rise_s = 2 then	--we found 3 cycles that trig is up
										trigger_found_v := '1' ;
										time_since_trig_rise_v := time_since_trig_rise_s + 1;
										rise_trig_counter_v := total_number_of_rows_c ;
--										time_since_trig_rise_s <= time_since_trig_rise_s + 1;
--										rise_trig_counter_s <= total_number_of_rows_c ;
									else								--less then 3 cycles that trig is up
--										time_since_trig_rise_s <= time_since_trig_rise_s + 1;	--promote counter
										time_since_trig_rise_v := time_since_trig_rise_s + 1;
									end if;
								else 									--trig is down, reset counter to 0
--									time_since_trig_rise_s <= 0;
									time_since_trig_rise_v := 0;
								end if;
							when "011"	=>				--trig define as zero
								if trigger = '0' then		--trig is up
									if time_since_trig_rise_s = 2 then	--we found 3 cycles that trig is up
										trigger_found_v := '1' ;
										time_since_trig_rise_v := time_since_trig_rise_s + 1;
										rise_trig_counter_v := total_number_of_rows_c ;
--										time_since_trig_rise_s <= time_since_trig_rise_s + 1;
--										rise_trig_counter_s <= total_number_of_rows_c ;
									else								--less then 3 cycles that trig is up
--										time_since_trig_rise_s <= time_since_trig_rise_s + 1;	--promote counter
										time_since_trig_rise_v := time_since_trig_rise_s + 1;
									end if;
								else 									--trig is down, reset to 0
--									time_since_trig_rise_s <= 0;
									time_since_trig_rise_v := 0;
								end if;
							when "100"	=>								--special trigger, not relevant to us now
								trigger_found_v := '0' ;
							when others =>								--error!! 
								trigger_found_v := '0'  ;
						end case;
					end if;
				
				else															--Enable is off
--				time_since_trig_rise_s	<=	0	;	
				time_since_trig_rise_v 	:= 0;
				rise_trig_counter_v 	:= 0 ;
				trigger_found_v 		:= '0'  ;
				end if;
			time_since_trig_rise_s <= time_since_trig_rise_v;
			rise_trig_counter_s <= rise_trig_counter_v ;
			trigger_found	<= 	trigger_found_v;
			work_trig_count_out <= 2**record_depth_g - rows_to_shift_s;
			trigger_to_alu_data <= trigger_found_v;
			end if;	
	
	end process	find_trig_pros;

	
---------------------------calculate start and end addr after founding trigger-------------------------------------	
	calc_trig_addr_proc	: process (reset, clk)
		
		variable	start_addr		: 	integer range 0 to  total_number_of_rows_c := 0; 	--saving the addr as an integer for easy calculations
		--an addr is the number of the row including transfer between the array rows.
		variable	start_addr_out_v		: 	integer range 0 to 2 * total_number_of_rows_c := 0;	--saving the addr as an integer for easy calculations (as showen in line 22)
		variable	start_array_row_out_v	:	integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g))	:=0	;
		variable	end_array_row_out_v	:	integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g))	:=0	;
		variable	start_addr_in_single_ram_v		:	integer range 0 to  2**signal_ram_depth_g  :=0	;	--the addr (in integer) inside a specific ram of the start addr
		variable	end_addr_in_single_ram_v		:	integer range 0 to  2**signal_ram_depth_g  :=0	;	--the addr (in integer) inside a specific ram of the end addr
		
		
		begin
			if	reset = Reset_polarity_g then													--enabling the entity
				--reseting all the variables						
					wc_to_rc	<=	(others => '0') ;	
					start_addr := 0;
					start_array_row_out_v := 0;
					end_array_row_out_v := 0;
					start_addr_out_v	:= 0;
					start_addr_in_single_ram_v := 0;
					end_addr_in_single_ram_v := 0;
					start_array_row_out <= 0;
					end_array_row_out	<=	0;
		--			first_cycle_s <= (1);
			elsif rising_edge(clk)  then									--clk rise and trigger found
				if  enable = enable_polarity_g then 															--reset is off
					start_addr := (current_array_row_in * (2**signal_ram_depth_g)) + to_integer( unsigned( addr_in_alu_trigger ) )  ; 
					--first we take the decimal value of the addr. the number of cuurent ram * how many addresses there are in each ram + the cuurent address in a singal ram
					start_addr_out_v := start_addr + rows_to_shift_s ;	--we shift the initial addr according the trigger position
					
					if( start_addr_out_v > total_number_of_rows_c ) then	--check if we exceed from the total number of the rows that we save
						start_addr_out_v := start_addr_out_v - total_number_of_rows_c;
					end if;
	 
					start_array_row_out_v := (start_addr_out_v ) / ((2**signal_ram_depth_g)); -- return the row of the addr in the ram array
					start_addr_in_single_ram_v := start_addr_out_v - start_array_row_out_v * (2**signal_ram_depth_g);	--getting the addr according one RAM
					
					------------------- check if incomming start address is the last address relevant in the last RAM -> make a cyclec memory
--					if ( (to_integer( unsigned(addr_in_alu_trigger)) = last_addr_in_last_ram_c ) and (current_array_row_in = number_of_ram_c -1)) then
--						start_addr_in_single_ram_v := 0 ;
--						start_array_row_out_v := 0 ; 
--					end if;	
					
					
					--calculating the end addr ( the addr in specific ram and the row in the ram array)
					-- end addr is one addr " before" the start addr
					if start_addr_in_single_ram_v = 0 then	--we in the first addr of the specific RAM
						if start_array_row_out_v = 0 then	--we also at the first row in the array
							end_array_row_out_v := number_of_ram_c - 1; --getting the last row of the array (the maximal one)	
							end_addr_in_single_ram_v := last_addr_in_last_ram_c ;	--see calc in WC doc
						else
							end_array_row_out_v := (start_array_row_out_v - 1) ; --we in the last addr, of the previous row
							end_addr_in_single_ram_v := ((signal_ram_depth_g) - 1 ); --getting the last addr in the previous RAM.(if we have 10 addresses, there number is between 0-9)
						end if;						
					else
						end_array_row_out_v := start_array_row_out_v ;	--we still in the same RAM
						end_addr_in_single_ram_v := ( start_addr_in_single_ram_v - 1 ) ;	--but just in the previous addr
					end if;
					
					
						

				else	--Enable is off
					start_array_row_out_v := 0;
					end_array_row_out_v := 0;
					start_addr_in_single_ram_v := 0;
					end_addr_in_single_ram_v := 0;

				end if;
			----------------------------update all the outputs---------------------------------------
			start_array_row_out <= start_array_row_out_v;
			end_array_row_out	<=	end_array_row_out_v;
			wc_to_rc(2 * (signal_ram_depth_g) -1 downto (signal_ram_depth_g))	<= std_logic_vector(to_unsigned(start_addr_in_single_ram_v, signal_ram_depth_g));
			wc_to_rc( (signal_ram_depth_g) -1 downto 0)	<= std_logic_vector(to_unsigned(end_addr_in_single_ram_v, signal_ram_depth_g));	
			
			
			end if;
	end process calc_trig_addr_proc;
		
	
end architecture behave;
