-----------------------------------------------------------------------------------------------------
-- File Name	:	integer_count.vhd
-- Generated	:	9.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
-----------------------------------------------------------------------------------------------------
-- Description: 
--				the input is an integer thats count. if the integer reached the number of 255, wich 
--				is the maximum that allowed, he stuck on 255. otherwise, we get an integer and 
--				output (integer + 1). 
-- 				the signal alu_to_count_in is an ENABLE signal, and the counter is working only when
--				alu_to_count_in = '1', otherwise we do nothing.
--				when we get a reset signal, we resetting the integer counter to '0'.
-----------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		9.11.2012	Zvika Pery						Creation			
-----------------------------------------------------------------------------------------------------
--	Todo:
--			
-----------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
-----------------------------------------------------------------------------------------------------

entity integer_count is
	generic (
			Reset_polarity_g	:	std_logic	:=	'1'					--'1' reset active highe, '0' active low
			);
	port (
			clk						:	in std_logic;					--system clk
			reset					:	in std_logic;					--system reset
			alu_to_count_in			:	in std_logic;					--1 continue counting, 0 stop
			ff_to_count				:	in integer range 0 to 255 ;		--previously counter result 
			count_to_ff				:	out integer range 0 to 255 		--new counter result
		);	
end entity integer_count;

architecture behave of integer_count is
	signal qint_s	:	integer range 0 to 255 ;						--internal signal to keep result
begin
	process(clk , reset)												--start with reset change or clk event
	begin
		if (reset = Reset_polarity_g) then								--resetting the counter to 0
			qint_s <= 0;
		elsif (clk = '1' and clk'event) then							--else->reset is 0 and clk event
			if (alu_to_count_in = '1') then								--counter shold add one
				if (ff_to_count = 255) then								--counter is stuck on max value
					qint_s <= 255;
				else													--counter is not on max value
					qint_s <= ff_to_count + 1;							--add 1 to count
				end if;
			else
				qint_s <= ff_to_count;									--alu_to_count_in = '0', dont count
			end if;
		end if;
	end process;
	count_to_ff <= qint_s;												--place internal signal as output

end architecture behave;