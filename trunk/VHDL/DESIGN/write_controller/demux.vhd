------------------------------------------------------------------------------------------------
-- File Name	:	demux.vhd
-- Generated	:	13.01.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--				demultiplexor 1 to 2 in (Add_width_g) width:
--											_________
--											|		|------>	y
--							x	---------->	|		|
--											|		|------>	z
--											---------
--									when x=y=z always
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		13.01.2013	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
------------------------------------------------------------------------------------------------

entity dmux is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			Add_width_g  		    :   positive 	:=  8      								--width of addr word in the RAM
			);
	port
	(
		reset 	:	 in  std_logic;										--reset
		x		:	in std_logic_vector (Add_width_g -1 downto 0)	;					
		y		:	out std_logic_vector (Add_width_g -1 downto 0)	;
		z		:	out std_logic_vector (Add_width_g -1 downto 0)				
	);	
end entity dmux;

architecture behave of dmux is
begin
dmux_pros	:	process (reset, x)
	begin
		if  reset = reset_polarity_g then
			y	<=	(others => '0') ;
			z	<= 	(others => '0') ;
		else 
			y	<= x;
			z	<= x;
		end if;
	end process	dmux_pros;
end architecture behave;