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
		signal_ram_depth_g		: 	positive  	:=	10;									--depth of RAM
		signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
		record_depth_g			: 	positive  	:=	10;									--number of bits that is recorded from each signal
		Add_width_g     		:   positive	:=  8;     								--width of addr word in the RAM
		num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port (			
		clk						:	 in  std_logic;										--system clk
		reset 					:	 in  std_logic;										--reset
		enable					:	in	std_logic;											--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing	
		data_in					:	 in	 std_logic_vector ( num_of_signals_g downto 0);	--miss (-1) on purpose adding the trigger signal
		addr_in_alu				:	 out std_logic_vector( Add_width_g -1 downto 0);	--the addr in the RAM to save the data
		aout_valid_alu			:	 out std_logic_vector( up_case(record_depth_g , signal_ram_depth_g) -1 downto 0	);	--each time we enable entire row	
		data_in_RAM				:	 out std_logic_vector( num_of_signals_g downto 0);	--miss (-1) on purpose adding the triger signal
		current_array_row		:	 out integer range 0 to up_case(record_depth_g , signal_ram_depth_g) --send to alu_trigg to get start place
		);
end entity alu_data;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of alu_data is
------------------Constants------
constant   ram_array_row_c 		: natural :=  up_case(record_depth_g , signal_ram_depth_g); 	--RAM array length 
constant   ram_array_column_c	: natural :=  up_case(num_of_signals_g + 1, signal_ram_width_g); 	--RAM array width (plus trigger signal)

-------------------------Types------

------------------Signals--------------------

signal		current_addr_row_s 	: integer range 0 to signal_ram_depth_g 	; 	--current row in the RAM to write to (in a specific RAM)  
signal		current_array_row_s	: integer range 0 to up_case(record_depth_g , signal_ram_depth_g) ; 	--current row in the RAMS array to enable 

------------------	Processes	----------------

begin
	addr_pros	:	process (reset, clk)			--write process, (when trigger found off or we haven't save all the data) 
	    	variable temp_aout_v  : std_logic_vector( up_case(record_depth_g , signal_ram_depth_g) -1 downto 0	)	:=(others => '0') ;
		
		begin
			if	enable = enable_polarity_g then
				if  reset = Reset_polarity_g then 														--reset is on
					current_addr_row_s <= 0 ;												--set the addr to the first row in the RAM		
					current_array_row_s <= 0;															--set the row that we write to in the RAM array to the first row
					data_in_RAM <= (others => '0') ;													--send zeroes out
					temp_aout_v := (others => '0') ;
					addr_in_alu <= (others => '0') ;
				elsif rising_edge(clk) then																--reset off, start writing the data					
					temp_aout_v := (others => '0') ;													--put zeroes in all unrelevant places 
					temp_aout_v(current_array_row_s) := '1' ;										--enable correct roe in RAM array	
					data_in_ram <= data_in  ;															--transfer data to RAM
					addr_in_alu <= std_logic_vector(to_unsigned(current_addr_row_s, Add_width_g));		--change it from integer to std logic vector

-------------------------------------update the current addr row---------------------------------------------------	

					if current_addr_row_s = signal_ram_depth_g then			--we in the last row in the RAM
						current_addr_row_s <= 0 ;							--next addr is the first row in the next RAM
-----------------------------------promote the current row in the RAM array to the next--------------------------------
						if (current_array_row_s) = (ram_array_row_c ) then 	--we  in the last row =>in that case this is the last RAM in the array
							current_array_row_s <= 0 ;		--go the first RAM in the array
						else	
							current_array_row_s <= current_array_row_s 	+ 1 ;	
						end if;
						
						
					else 
						current_addr_row_s <= current_addr_row_s + 1 ;		--we are not in the last row, just promote addr in one
					end if;
				end if;	
			else
				temp_aout_v := (others => 'X') ;
				current_array_row_s <= current_array_row_s;
			end if;
	
				

-------------------------------------update the outputs---------------------------------------------------------- 
	aout_valid_alu    <= temp_aout_v;									
	current_array_row <= current_array_row_s;	
	 
	end process	addr_pros;


end architecture behave;

--
--