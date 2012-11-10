------------------------------------------------------------------------------------------------
-- File Name	:	width_flipflop.vhd
-- Generated	:	9.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--				flip flop that save couple of signals each time,
--				number of signals to save defined as signal_ram_width_g GENERIC,
-- 				the flipflop activate with clk rise.
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

entity width_flipflop is
	GENERIC (
		signal_ram_width_g	: 	positive  :=8  											--width of RAM
	);
	port
	(
		clk					:	in std_logic;											--system clk
		d					:	in std_logic_vector(signal_ram_width_g-1 downto 0);		--input signal
		q					:	out std_logic_vector (signal_ram_width_g-1 downto 0)	--output signal
	);	
end entity width_flipflop;

architecture behave of width_flipflop is
begin
	process(clk)									--start with clk change
	begin
		if (clk'event and clk = '1' ) then			--clk rise
			q <= d;									--save new data
		end if;
	end process;

end architecture behave;