------------------------------------------------------------------------------------------------
-- File Name	:	flipflop.vhd
-- Generated	:	9.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: flip flop of one signal.
--				
-- 		
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
entity width_FlipFlop is
	GENERIC (
		signal_ram_width_g	 : 	positive  :=8  --width of RAM
	);
	port
	(
		clk	:	in std_logic;
		d	:	in std_logic_vector(signal_ram_width_g-1 downto 0);
		q	:	out std_logic_vector (signal_ram_width_g-1 downto 0)
	);	
end entity width_FlipFlop;
-------------------------------------------architecture-----------------------------------------
architecture behave of width_FlipFlop is
begin
q<=d when (clk'event and clk = '1' );
end architecture behave;