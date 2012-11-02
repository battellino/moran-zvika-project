library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
------------------------------------------------------------------------------------------

entity width_flipflop is
	GENERIC (
		signal_ram_width_g	 : 	positive  :=8  --width of RAM
	);
	port
	(
		clk	:	in std_logic;
		d	:	in std_logic_vector(signal_ram_width_g-1 downto 0);
		q	:	out std_logic_vector (signal_ram_width_g-1 downto 0)
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