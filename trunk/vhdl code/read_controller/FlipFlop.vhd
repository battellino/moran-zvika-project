library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;

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

architecture behave of width_FlipFlop is
begin
q<=d when (clk'event and clk = '1' );
end architecture behave;