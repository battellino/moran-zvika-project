------------------------------------------------------------------------------------------------------------
-- File Name	:	alu_data.vhd
-- Generated	:	17.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------------------
-- Description: 
--				calculate the address in the RAM of the current data.
--				take the incomimg data and separate it to the correct RAMs with the correct addr 
--				
--				
--				
------------------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		17.11.2012	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------------------
--	Todo:
--		
--		
--		now the two prosseses of puting the data and advancing the addr are happening in the same time, what we do first?
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
entity alu_data is
	GENERIC (
		reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
		enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
		signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM will be 2^(signal_ram_depth_g)
		signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
		record_depth_g			: 	positive  	:=	5;									--number of bits that is recorded from each signal
		Add_width_g     		:   positive	:=  8;     								--width of addr word in the WB
		num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port (			
		clk						:	 in  std_logic;										--system clk
		reset 					:	 in  std_logic;										--reset
		enable					:	 in	 std_logic;											--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing	
		data_in					:	 in	 std_logic_vector ( num_of_signals_g -1 downto 0);	--data in from user
		trigger_found_in		:	 in	 std_logic	;										-- 1  we found the trigger, 0 we have not
		work_count				: 	 in	 integer range 0 to 2**record_depth_g ;			--number of cycles that we continue to work after trigger rise
		addr_out_alu_data		:	 out std_logic_vector( signal_ram_depth_g -1 downto 0);	--the addr in the RAM to save the data
		aout_valid_alu			:	 out std_logic_vector( up_case(2**record_depth_g , (2**signal_ram_depth_g)) -1  downto 0	);	--each time we enable entire row at the RAM array
		wc_finish				:	 out std_logic	;										--'1' ->WC has finish working and saving all the relevant data (RC will start work), '0' ->WC is still working
		data_to_RAM				:	 out std_logic_vector( num_of_signals_g -1 downto 0);	--data out to save in RAM
		current_array_row		:	 out integer range 0 to up_case(2**record_depth_g , 2**signal_ram_depth_g) --send to alu_trigg to get start place
		);
end entity alu_data;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of alu_data is
------------------Constants------
constant   	ram_array_row_c			: natural :=  up_case(2**record_depth_g , 2**signal_ram_depth_g) -1 ; 	--RAM array length, (-1 becuse we start to count from 0 -> n rows is 0 to n-1) 
constant	total_number_of_rows_c	: natural :=  2**signal_ram_depth_g * up_case(2**record_depth_g , 2**signal_ram_depth_g)	  ; --number of "lines" in the total RAM array (depth, not width)
-------------------------Types------

------------------Signals--------------------

signal		current_addr_row_s 	: integer range 0 to 2**signal_ram_depth_g 	; 	--current row in the RAM to write to (in a specific RAM)  
signal		current_array_row_s	: integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g))  ; 	--current row in the RAMS array to enable 
--signal		rows_to_shift_s		: integer range 0 to  total_number_of_rows_c	;	--calc how rows we shift according user configuration (trigg position)
signal		wc_finish_s			: std_logic ;									--1- wc still working, 0 wc end working-> rc start working
------------------	Processes	----------------

begin
	addr_pros	:	process (reset, clk)			--write process, (when trigger found off or we haven't save all the data) 
	    	variable temp_aout_v  : std_logic_vector( up_case(2**record_depth_g , (2**signal_ram_depth_g)) -1   downto 0	)	:=(others => '0') ;
			variable work_trig_count_v 		: integer range -1 to 2**record_depth_g := -1 ;
			variable addr_out_alu_data_v	: std_logic_vector( signal_ram_depth_g -1 downto 0)	:= (others => '0') ;
			variable current_addr_row_v		: integer range 0 to 2**signal_ram_depth_g := 0	;
			variable current_array_row_v	: integer range 0 to up_case(2**record_depth_g , (2**signal_ram_depth_g)) := 0	;
		begin		
			if  reset = Reset_polarity_g then 														--reset is on
				current_addr_row_v := 0 ;												--set the addr to the first row in the RAM		
				current_array_row_v := 0;															--set the row that we write to in the RAM array to the first row
				temp_aout_v := (others => '0') ;
				addr_out_alu_data <= (others => '0') ;											--initial to (-1), meaning trigger have not found yet
				work_trig_count_v := (-1);
				wc_finish_s <= '0';

			elsif rising_edge(clk) then																--reset off, start writing the data					
				if	enable = enable_polarity_g then
					if	(trigger_found_in = '1') then						--trigger was rise, initialize counter
						work_trig_count_v := work_count -1;						--we take (-1) becouse it take one clk cycle to the signal to move from ALU TRIGG to ALU DATA and its not synchronized								
					end if;
								
					if (  wc_finish_s = '0'  ) then			--wc is still working
						temp_aout_v := (others => '0') ;													--put zeroes in all unrelevant places 
						temp_aout_v(current_array_row_s) := '1' ;										--enable correct row in RAM array	
						addr_out_alu_data <= std_logic_vector(to_unsigned(current_addr_row_s, signal_ram_depth_g));		--change it from integer to std logic vector
		-------------------------------------update the current addr row---------------------------------------------------	
						if current_addr_row_s = (2**signal_ram_depth_g -1) then			--we in the last row in the RAM
								current_addr_row_v := 0 ;							--next addr is the first row in the next RAM
		-----------------------------------promote the current row in the RAM array to the next--------------------------------
							if (current_array_row_s) = (ram_array_row_c ) then 	--we  in the last row =>in that case this is the last RAM in the array
								current_array_row_v := 0 ;		--go the first RAM in the array
							else	
								current_array_row_v := current_array_row_s 	+ 1 ;	
							end if;
						elsif (current_addr_row_s = (2**signal_ram_depth_g - (total_number_of_rows_c - 2**record_depth_g) -1 ) )  and (current_array_row_s = ram_array_row_c ) then --the last relevant word, we have a cyclec memory	
							current_addr_row_v := 0 ;
							current_array_row_v := 0 ;
						else 
							current_addr_row_v := current_addr_row_s + 1 ;		--we are not in the last row, just promote addr in one
						end if;
					else									-- WC is finish working
						temp_aout_v := (others => '0') ;
					end if;
						

					if (work_trig_count_v > 0) then			--count down
						work_trig_count_v := work_trig_count_v -1 ;
					elsif (work_trig_count_v = 0) then	
						wc_finish_s <= '1' ;
					end if;
					
					if	((trigger_found_in = '1') and (work_count = 0 ) ) then		--in case that trigger found and we already saved all the data-> stop working
						temp_aout_v := (others => '0') ;
						wc_finish_s <= '1' ;
					end if;

				else										--enable is off
					temp_aout_v := (others => '0') ;
					current_array_row_v := 0;
					work_trig_count_v := (-1);
					wc_finish_s <= '0';
				end if;
			
				
-------------------------------------update the outputs---------------------------------------------------------- 
			data_to_ram 		<= data_in  ;															--transfer data to RAM
			aout_valid_alu    	<= temp_aout_v;									
			current_array_row_s	<= current_array_row_v;
			current_array_row 	<= current_array_row_v;	
			wc_finish		  	<= wc_finish_s;
			current_addr_row_s	<= current_addr_row_v;
			end if;
end process	addr_pros;


end architecture behave;
