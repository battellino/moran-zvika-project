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
--		check if ram_array_row_c\ram_array_column_c getting right values (upper complete value)
--		now the two prosseses of puting the data and advancing the addr are happening in the same time, what we do first?
--		build function to change a number from integer to binary-> int2bin(integer)
------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;

library work ;
use work.write_controller_pkg.all;

------------------------------------------------------------------------------------------------------------
entity alu_data is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			signal_ram_depth_g		: 	positive  	:=	10;									--depth of RAM
			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
			record_depth_g			: 	positive  	:=	10;									--number of bits that is recorded from each signal
			num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port (			
		clk							:	 in  std_logic;										--system clk
		reset 						:	 in  std_logic;										--reset
		data_in						:	 in	 std_logic_vector ( num_of_signals_g downto 0);	--miss (-1) on purpose adding the triger signal
		addr_in_alu					:	 out std_logic_vector( Add_width_g -1 downto 0);	--the addr in the RAM to save the data
		aout_valid_alu				:	 out std_logic_vector( up_case(record_depth_g , signal_ram_depth_g) -1 downto 0	);	--each time we enable entire row	
		data_in_RAM					:	 out std_logic_vector( up_case(num_of_signals_g + 1, signal_ram_width_g)*signal_ram_width_g -1 downto 0)--each cycle we write to couple of RAMs in parallel  
		);																											--so we need to send all of the data in one output
end entity alu_data;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of alu_data is
------------------Constants------
constant 	ram_array_row_c 		: natural :=  up_case(record_depth_g , signal_ram_depth_g); 	--RAM array length 
			ram_array_column_c		: natural :=  up_case(num_of_signals_g + 1, signal_ram_width_g); 	--RAM array width (plus trigger signal)

-------------------------Types------

------------------Signals--------------------

signal	current_addr_row_s 			: integer range 0 to signal_ram_depth_g	; 	--current row in the RAM to write to (in a specific RAM) 
--delete--		current_addr_col_s			: integer range 0 to num_of_signals_g	; 	--current column in the RAM to write to (in a specific RAM) 
		current_array_row_s			: integer range 0 to up_case(record_depth_g , signal_ram_depth_g); 	--current row in the RAMS array to enable 
		current_array_col_s			: integer range 0 to ram_array_column_c;	--current column in the RAMS array to send data

------------------	Processes	----------------

begin
addr_pros	:	process (reset, clk)			--write process, (when trigger found off or we haven't save all the data) 

	begin
		if  reset = Reset_polarity_g then 														--reset is on
			current_addr_row_s := (others => '0') ;												--set the addr to the first row in the RAM		
			current_array_row_s := 0;															--set the row that we write to in the RAM array to the first row
--			current_array_col_s := 0;
			data_in_RAM <= (others => '0') ;													--send zeroes out
		elsif rising_edge(clk) then																--reset off, start writing the data					
			aout_valid_alu := (others => '0') ;													--put zeroes in all unrelevant places 
			aout_valid_alu(current_array_row_s) := '1' ;										--enable correct roe in RAM array
			for idx in 0 to ram_array_column_c  loop		--disassemble the incomming data for one "word" at the time
				data_in_ram := data_in(idx*signal_ram_width_g to (idx + 1)*signal_ram_width_g ) ; 
			-----how to send the data in parallel to the entire row?
			end loop;
			addr_in_alu := int2bin(current_addr_row_s);		--change it from integer to binary
			--promote the current row and col
			if current_array_col_s = ram_array_column_c then	--we in the last RAM in that col
				if current_array_row_s = ram_array_row_c then 	--we also in the last row =>in that case this is the last RAM in the array
					current_array_row_s <= 0 ;		--go the first RAM in the array
					current_array_col_s <= 0 ;
				else	--we in the last col of that row, but not in the last row
					current_array_row_s <= current_array_row_s 	+ 1 ;	
					current_array_col_s <= 0	;	--start from the first RAM in the new array
				end if;
			else current_array_col_s <= current_array_col_s + 1 ;
			
			end if;
		
-------------------------------------update the current addr row---------------------------------------------------		
		if current_addr_row_s = signal_ram_depth_g then			--we in the last row in the RAM
			current_addr_row_s <= 0 ;
		else current_addr_row_s <= current_addr_row_s +1 ;		--we are not in the last row, just promote addr in one
		end if;
end process	addr_pros;

end architecture behave;