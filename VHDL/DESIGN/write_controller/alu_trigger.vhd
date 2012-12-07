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
------------------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		3.12.2012	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------------------
--	Todo:
--			need to get the current addr from the alu_addr in order to sent it out (wc_to_rc)
--			adding system status to reset condition
--			write functions(in write controller pkg) thats calc the start and the end addr of the relevant data 
--		
------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


library work ;
use work.write_controller_pkg.all;

------------------------------------------------------------------------------------------------------------
entity alu_trigger is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
--			signal_ram_depth_g		: 	positive  	:=	10;									--depth of RAM
--			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
--			record_depth_g			: 	positive  	:=	10;									--number of bits that is recorded from each signal
			Add_width_g  		    :   positive 	:=  8;      --width of addr word in the RAM
--			num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port (			
		clk							:	 in  std_logic;											--system clk
		reset 						:	 in  std_logic;											--reset
		trigger						:	 in	 std_logic;											--trigger signal
		trigger_position			:	 in  std_logic_vector(  6 downto 0	);					--the percentage of the data to send out
		trigger_type				:	 in  std_logic_vector(  2 downto 0	);					--we specify 5 types of triggers	
		system_status				:	 in  std_logic ; 										--determine if we looking for trigger. 1- we seek trigger rise. 0- we dont 
		trigger_found				:	 out std_logic	;										-- 1  we found the trigger, 0 we have not
		wc_to_rc					:	 out std_logic_vector( 2 * Add_width_g -1 downto 0 )	--the start and end addr of the data that we need to send out to the user
		);																											
end entity alu_trigger;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of alu_trigger is
------------------Constants------
--constant   ram_array_row_c 		: natural :=  up_case(record_depth_g , signal_ram_depth_g); 	--RAM array length 
--constant   ram_array_column_c		: natural :=  up_case(num_of_signals_g + 1, signal_ram_width_g); 	--RAM array width (plus trigger signal)

-------------------------Types------

------------------Signals--------------------

signal	time_since_trig_rise_s 			: integer range 0 to 3 	:=	0	; 	--count the cycles that passed since the trigger was first rise, (change to one when we find first rise) 
--signal		current_array_row_s			: integer range 0 to up_case(record_depth_g , signal_ram_depth_g) ; 	--current row in the RAMS array to enable 
--signal		current_array_col_s			: integer range 0 to ram_array_column_c;	--current column in the RAMS array to send data

------------------	Processes	----------------

begin
	trig_pros	:	process (reset, clk)			--write process, (when trigger found off or we haven't save all the data) 
--	    	variable temp_aout  : std_logic_vector( up_case(record_depth_g , signal_ram_depth_g) -1 downto 0	)	:=(others => '0') ;
		
		begin
			if  reset = Reset_polarity_g then 														--reset is on
------------------------------------reseting all the variables------------------------------------------------------------------------						
			time_since_trig_rise_s	<=	0	;	
			trigger_found 			<= '0'  ;

			elsif rising_edge(clk) then																--reset off, 					
------------------------------------checking if trigger have rised--------------------------------------------------------------------
					case  trigger_type is				--notice between the different types of triggers
						when "000" 	=>					--trig define as rise
							if trigger = '1' then
								trigger_found <= '1' ;
							end if;
						when "001"	=>					--trig define as fall
							if trigger = '0' then
								trigger_found <= '1' ;
							end if;
						when "010"	=>					--trig define as one
							if trigger = '1' then		--trig is up
								if time_since_trig_rise_s = 3 then	--we found 3 cycles that trig is up
									trigger_found <= '1' ;
								else								--less then 3 cycles that trig is up
									time_since_trig_rise_s = time_since_trig_rise_s + 1;	--promote counter
								end if;
							else 									--trig is down, reset counter to 0
								time_since_trig_rise_s = 0;
							end if;
						when "011"	=>				--trig define as zero
							if trigger = '0' then		--trig is up
								if time_since_trig_rise_s = 3 then	--we found 3 cycles that trig is up
									trigger_found <= '1' ;
								else								--less then 3 cycles that trig is up
									time_since_trig_rise_s = time_since_trig_rise_s + 1;	--promote counter
								end if;
							else 									--trig is down, reset counter to 0
								time_since_trig_rise_s = 0;
							end if;
						when "100"	=>								--special trigger, not relevant to us now
							trigger_found <= '0' ;
					end case;
	
			
			
			end if;
	
	end process	trig_pros;

end architecture behave;

--
--