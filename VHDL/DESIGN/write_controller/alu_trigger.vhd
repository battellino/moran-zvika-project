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
------------------------------------------------------------------------------------------------------------
--	Todo:
--			trigger_position work only if "0000000"
--			
--			
--			
------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;


library work ;
use work.write_controller_pkg.all;

------------------------------------------------------------------------------------------------------------
entity alu_trigger is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	10;									--depth of RAM
			record_depth_g			: 	positive  	:=	10;									--number of bits that is recorded from each signal
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
		addr_in_alu_trigger			:	in  std_logic_vector( Add_width_g -1 downto 0);		--the addr in the RAM whice the trigger came
		start_array_row_in			:	in 	integer range 0 to up_case(record_depth_g , signal_ram_depth_g ); --the RAM array line which the trigger came from.
		trigger_found				:	out std_logic	;										-- 1  we found the trigger, 0 we have not
		wc_to_rc					:	out std_logic_vector( 2 * Add_width_g -1 downto 0 );	--the start and end addr of the data that we need to send out to the user
																								-- 0-add_width-1 => end addr, add_width-2add_width-1 => start addr					
		start_array_row_out			:	out integer range 0 to up_case(record_depth_g , signal_ram_depth_g);	--send with the addr to the RC
		end_array_row_out			:	out integer range 0 to up_case(record_depth_g , signal_ram_depth_g)		--send with the addr to the RC
		);																						
end entity alu_trigger;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of alu_trigger is
------------------Constants------
constant	total_number_of_rows_c	:	natural := signal_ram_depth_g * up_case(record_depth_g , signal_ram_depth_g)	  ; --number of "lines" in the registers (depth, not width)
-------------------------Types------

------------------Signals--------------------

signal	time_since_trig_rise_s 	:	integer range 0 to 3 	; 	--count the cycles that passed since the trigger was first rise, (change to one when we find first rise)
																	--we will use in this signal at value 3 to mark that trigger is found (trigger_found = '1' after   
																	-- 	time_since_trig_rise_s = 3)
signal	rows_to_shift_s			:	integer range 0 to  total_number_of_rows_c	;	--calc how rows we shift according user configuration (trigg position)																	
------------------	Processes	----------------

begin
---------------------------write process, (when trigger found off or we haven't save all the data)-------------------------------------	
	find_trig_pros	:	process (reset, clk)			
		variable trigger_found_v	: std_logic	:= '0'	;
		
		begin												
			if  reset = Reset_polarity_g then 														--reset is on
				--reseting all the variables						
				time_since_trig_rise_s	<=	0	;	
				trigger_found_v 		:= '0'  ;
				trigger_found	<= 	trigger_found_v;
				rows_to_shift_s <=	(to_integer( unsigned( trigger_position(7 downto 0))) *signal_ram_depth_g) / 100	;
			elsif rising_edge(clk) then																--reset off, 					
					--check if trigger was rised in previous cycle
					rows_to_shift_s <=	(to_integer( unsigned( trigger_position(7 downto 0))) *signal_ram_depth_g) / 100	;
				if	enable = enable_polarity_g then					--enable is on
					if trigger_found_v = '1' then
						time_since_trig_rise_s	<=	0	;	
						trigger_found_v			:= '0'  ;
					else
						--checking if trigger needs to be rise
						case  trigger_type(2 downto 0) is				--notice between the different types of triggers
							when "000" 	=>					--trig define as rise
								if trigger = '1' then
									trigger_found_v := '1' ;
									time_since_trig_rise_s <= 3 ;
								end if;
							when "001"	=>					--trig define as fall
								if trigger = '0' then
									trigger_found_v := '1' ;
									time_since_trig_rise_s <= 3 ;
								end if;
							when "010"	=>					--trig define as one
								if trigger = '1' then		--trig is up
									if time_since_trig_rise_s = 2 then	--we found 3 cycles that trig is up
										trigger_found_v := '1' ;
										time_since_trig_rise_s <= time_since_trig_rise_s + 1;
									else								--less then 3 cycles that trig is up
										time_since_trig_rise_s <= time_since_trig_rise_s + 1;	--promote counter
									end if;
								else 									--trig is down, reset counter to 0
									time_since_trig_rise_s <= 0;
								end if;
							when "011"	=>				--trig define as zero
								if trigger = '0' then		--trig is up
									if time_since_trig_rise_s = 2 then	--we found 3 cycles that trig is up
										trigger_found_v := '1' ;
										time_since_trig_rise_s <= time_since_trig_rise_s + 1;
									else								--less then 3 cycles that trig is up
										time_since_trig_rise_s <= time_since_trig_rise_s + 1;	--promote counter
									end if;
								else 									--trig is down, reset counter to 0
									time_since_trig_rise_s <= 0;
								end if;
							when "100"	=>								--special trigger, not relevant to us now
								trigger_found_v := '0' ;
							when others =>								--error!! 
								trigger_found_v := '0'  ;
						end case;
					end if;
				
				else															--Enable is off
				time_since_trig_rise_s	<=	0	;	
				trigger_found_v 		:= '0'  ;
				end if;
			trigger_found	<= 	trigger_found_v;
			end if;	
	
	end process	find_trig_pros;
---------------------------calculate start and end addr after founding trigger-------------------------------------	
	calc_trig_addr_proc	: process (reset, clk)
		
		variable	start_addr		: 	integer range 0 to  total_number_of_rows_c := 0; 	--saving the addr as an integer for easy calculations
		--an addr is the number of the row including transfer between the array rows.
		variable	start_addr_out_v		: 	integer range 0 to 2 * total_number_of_rows_c := 0;	--saving the addr as an integer for easy calculations (as showen in line 22)
		variable	start_array_row_out_v	:	integer range 0 to up_case(record_depth_g , signal_ram_depth_g)	:=0	;
		variable	end_array_row_out_v	:	integer range 0 to up_case(record_depth_g , signal_ram_depth_g)	:=0	;
		variable	start_addr_in_single_ram_v		:	integer range 0 to  signal_ram_depth_g  :=0	;	--the addr (in integer) inside a specific ram of the start addr
		variable	end_addr_in_single_ram_v		:	integer range 0 to  signal_ram_depth_g  :=0	;	--the addr (in integer) inside a specific ram of the end addr
		
		
		begin
			if	reset = Reset_polarity_g then													--enabling the entity
				--reseting all the variables						
					wc_to_rc	<=	(others => '0') ;	
					start_array_row_out_v := 0;
					end_array_row_out_v := 0;
					start_addr_out_v	:= 0;
					start_addr_in_single_ram_v := 0;
					end_addr_in_single_ram_v := 0;
					start_array_row_out <= start_array_row_out_v;
					end_array_row_out	<=	end_array_row_out_v;
					wc_to_rc(2 * Add_width_g -1 downto Add_width_g)	<= std_logic_vector(to_unsigned(start_addr_in_single_ram_v, Add_width_g));
					wc_to_rc( Add_width_g -1 downto 0)	<= std_logic_vector(to_unsigned(end_addr_in_single_ram_v, Add_width_g));
			elsif rising_edge(clk)  then									--clk rise and trigger found
				if  enable = enable_polarity_g then 															--reset is on
					start_addr := (start_array_row_in * signal_ram_depth_g) + to_integer( unsigned( addr_in_alu_trigger ) ) ;
					start_addr_out_v := start_addr + rows_to_shift_s;
					if( start_addr_out_v > total_number_of_rows_c ) then	--check if we exceed from the total number of the rows
						start_addr_out_v := start_addr_out_v - total_number_of_rows_c;
					end if;
				
					start_array_row_out_v := (start_addr_out_v ) / signal_ram_depth_g; --need to check, return the row of the addr in the ram array
					start_addr_in_single_ram_v := start_addr_out_v - start_array_row_out_v * signal_ram_depth_g;	--getting the addr according one RAM
					--calculating the end addr ( the addr in specific ram and the row in the ram array)
					-- end addr is one addr " before" the start addr
					if start_addr_in_single_ram_v = 0 then	--we in the first addr of the specific RAM
						if start_array_row_out_v = 0 then	--we also at the first row in the array
							end_array_row_out_v := up_case(record_depth_g , signal_ram_depth_g); --getting the last row of the array (the maximal one)	
						else
							end_array_row_out_v := (start_array_row_out_v - 1) ; --we in the last addr, of the previous row
						end if;
						end_addr_in_single_ram_v := ( signal_ram_depth_g - 1 ); --getting the last addr in the previous RAM.(if we have 10 addresses, there number is between 0-9)
					else
						end_array_row_out_v := start_array_row_out_v ;	--we still in the same RAM
						end_addr_in_single_ram_v := ( start_addr_in_single_ram_v - 1 ) ;	--but just in the previous addr
					end if;
						----------------------------update all the outputs---------------------------------------
					start_array_row_out <= start_array_row_out_v;
					end_array_row_out	<=	end_array_row_out_v;
					wc_to_rc(2 * Add_width_g -1 downto Add_width_g)	<= std_logic_vector(to_unsigned(start_addr_in_single_ram_v, Add_width_g));
					wc_to_rc( Add_width_g -1 downto 0)	<= std_logic_vector(to_unsigned(end_addr_in_single_ram_v, Add_width_g));	
				else	--Enable is off
					start_array_row_out_v := 0;
					end_array_row_out_v := 0;
					start_addr_in_single_ram_v := 0;
					end_addr_in_single_ram_v := 0;
					start_array_row_out <= start_array_row_out_v;
					end_array_row_out	<=	end_array_row_out_v;
					wc_to_rc(2 * Add_width_g -1 downto Add_width_g)	<= std_logic_vector(to_unsigned(start_addr_in_single_ram_v, Add_width_g));
					wc_to_rc( Add_width_g -1 downto 0)	<= std_logic_vector(to_unsigned(end_addr_in_single_ram_v, Add_width_g));
				end if;
			end if;
	end process calc_trig_addr_proc;
	
end architecture behave;
