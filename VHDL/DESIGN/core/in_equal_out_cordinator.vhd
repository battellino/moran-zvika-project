------------------------------------------------------------------------------------------------
-- File Name	:	in_out_cordinator.vhd
-- Generated	:	21.9.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--				coordinate between input data (num_of_signals_g) to output data (data_width_g)
--				in that entity the input = output, 
-- 				meaning num_of_signals_g = data_width_g
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date			Name							Description			
--			1.0			21.9.2013		Zvika Pery						Creation	
--			
------------------------------------------------------------------------------------------------
--	Todo:
--			
------------------------------------------------------------------------------------------------


library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;

---------------------------------------------------------------------------------------------------------------------------------------

entity in_equal_out_cordinator is
	GENERIC (
		out_width_g            		:	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
		in_width_g					:	positive	:=	8									--number of signals that will be recorded simultaneously
	);
	port
	(
		clk							:	in std_logic;											--system clock
		reset						:	in std_logic;											--system reset
		data_in						:	in std_logic_vector (in_width_g - 1 downto 0);	-- data came from RAM 
		data_in_valid				:	in std_logic;											--data in valid
		data_out					:	out std_logic_vector (out_width_g - 1 downto 0);		--data out to WBM
		data_out_valid				:	out std_logic											--data out valid
	);	
end entity in_equal_out_cordinator;

architecture behave of in_equal_out_cordinator is

begin
	in_out_proc : process (clk, reset)
		begin
			if reset = reset_polarity_g then
				data_out			<= (others => '0');				
				data_out_valid		<= '0';
			elsif rising_edge(clk) then
				data_out <= data_in;
				data_out_valid <= data_in_valid;
			end if;
		end process in_out_proc;
		
end architecture behave;