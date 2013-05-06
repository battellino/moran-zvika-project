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
			signal_ram_depth_g		: 	positive  	:=	3									--depth of RAM will be 2^(signal_ram_depth_g)
			);
	port
	(
		x		:	in std_logic_vector (signal_ram_depth_g -1 downto 0)	;						--input signal
		y		:	out std_logic_vector (signal_ram_depth_g -1 downto 0)	;						--output1 <= input
		z		:	out std_logic_vector (signal_ram_depth_g -1 downto 0)							--output2 <= input
	);	
end entity dmux;

architecture behave of dmux is
begin
dmux_pros	:	process (x)
	begin
		
			y	<= x;
			z	<= x;
			
	end process	dmux_pros;
end architecture behave;