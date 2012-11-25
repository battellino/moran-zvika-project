------------------------------------------------------------------------------------------------------------
-- File Name	:	alu_data.vhd
-- Generated	:	17.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------------------
-- Description: 
--				calculate the address in the RAM of the current data.
--				
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
			reset_polarity_g	:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			signal_ram_depth_g	: 	positive  	:=	10;									--depth of RAM
			signal_ram_width_g	:	positive 	:=  8;   								--width of basic RAM
			record_depth_g		: 	positive  	:=	10;									--number of bits that is recorded from each signal
			num_of_signals_g	:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port (			
		clk						:	 in std_logic;										--system clk
		reset 					:	 in std_logic;										--reset
		addr_in_alu				:	 out std_logic_vector( Add_width_g -1 downto 0);	--the addr in the RAM to save the data
		aout_valid_alu			:	 out std_logic_vector( up_case(record_depth_g , signal_ram_depth_g) -1 downto 0	)	--each time we enable entire row	
		);																											--so we only need to save the number of rows
end entity alu_data;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of alu_data is
------------------Constants------
constant 	ram_array_row_c 		: natural :=  up_case(record_depth_g , signal_ram_depth_g); 	--RAM array length 
			ram_array_column_c		: natural :=  up_case(num_of_signals_g , signal_ram_width_g); 	--RAM array width 

-------------------------Types------

------------------Signals--------------------

signal	current_addr_row_s 		: integer range 0 to signal_ram_depth_g	; 	--current row in the RAM to write to (in a specific RAM) 
--		current_addr_col_s		: integer range 0 to num_of_signals_g	; 	--current column in the RAM to write to (in a specific RAM) 
		current_array_row_s		: integer range 0 to up_case(record_depth_g , signal_ram_depth_g); 	--current row in the RAMS array to enable 
		current_array_col_s		: integer range 0 to up_case(num_of_signals_g , signal_ram_width_g);	--current column in the RAMS array to enable
------------------	Processes	----------------

begin
addr_pros	:	process (reset, clk)																		--start process with clk event or reset change

	begin
		if reset = Reset_polarity_g then 														--reset is on
			current_addr_row_s := (others => '0') ;													--resetting to zeroes		
			current_array_row_s := 0;
--			current_array_col_s := 0;
			for idx in 0 to up_case(record_depth_g , signal_ram_depth_g) -1 loop		--build aout_valid vector
				if ind = current_addr_row_s then						--enable this row-> put '1' in a out alu in that index
					aout_valid_alu(index) <= '1';
				else
					aout_valid_alu(index) <= '0';
				end if;
			end loop;
			
			
		elsif rising_edge(clk)then 
			if trigger_found = '0' then													--reset off, trigger found off
				next_addr_out_alu <= current_addr_out_alu ; 							--stay in prev state (not necessary)
			else																		--reset off, trigger found on 
				next_addr_out_alu <= current_addr_out_alu + signal_ram_width_g;	-------------need to handle with start and finish addr
			end if;
		end if;
end process	addr_pros;
	
mux_pros	:	process (reset, clk)
	begin
		if	reset	=	Reset_polarity_g then
			aout_valid_alu <= (others => '0') ;	--don't enable any RAM
			current_array_row_s <= '0' ;		--resetting for the first row in array
			current_array_col_s <= '0' ;		--resetting for the first col in array
		elsif rising_edge(clk)	then								--reset is off
			if current_array_col_s == ram_array_column_c then	--we in the last RAM in that col
				if current_array_row_s == ram_array_row_c then 	--we also in the last row =>in that case this is the last RAM in the array
					current_array_row_s <= '0' ;		--go the first RAM in the array
					current_array_col_s <= '0' ;
				else	--we in the last col of that row, but not in the last row
					current_array_row_s <= current_array_row_s 	=	'1' ;	
					current_array_col_s <= '0'	;	--start from the first RAM in the new array
				end if;
			else --just promote the col
end process mux_pros;

aout_valid_alu <= int2bin(current_array_row_s, up_case(record_depth_g , signal_ram_depth_g) ) ;		--enable the RAMS of the current row

end architecture behave;