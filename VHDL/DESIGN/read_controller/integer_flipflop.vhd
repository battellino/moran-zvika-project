------------------------------------------------------------------------------------------------
-- File Name	:	integer_flipflop.vhd
-- Generated	:	9.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--				flip flop that save an integer,
--				the integer is defined as a number between 0 and 255,
-- 				the flipflop is activate with clk rise.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		9.11.2012	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
------------------------------------------------------------------------------------------------

entity integer_flipflop is
	port
	(
		clk	:	in std_logic	;					--system clk
		d	:	in integer range 0 to 255 :=0	;	--save counter result
		q	:	out integer range 0 to 255			--output current count
	);	
end entity integer_flipflop;

architecture behave of integer_flipflop is
begin
	process(clk)									--start with clk change
	begin
		if (clk'event and clk = '1' ) then			--clk rise
			q <= d;									--save new data
		end if;
	end process;

end architecture behave;