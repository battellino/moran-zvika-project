------------------------------------------------------------------------------------------------
-- File Name	:	signal_generator.vhd
-- Generated	:	07.01.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--			The entity inject  
--			
--			
--			
--			
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		26.08.2013	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			
--			
--			connect WB 
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;

library work ;
use work.write_controller_pkg.all;
---------------------------------------------------------------------------------------------------------------------------------------

entity signal_generator is
	generic (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g		:	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM is 2^signal_ram_depth_g
			signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
			record_depth_g			: 	positive  	:=	4;									--number of bits that are recorded from each signal is 2^record_depth_g
			data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
			trigger_type_g			:	positive 	:= 	3;									--Trigger type
			num_of_signals_g		:	positive	:=	8									--num of signals that will be recorded simultaneously
			);
	port
	(
		clk							:	in  std_logic;											--system clock
		reset						:	in  std_logic;											--system reset
--		enable						:	in	std_logic;											--enabling the entity
		trigger_type    		    : 	in std_logic_vector (data_width_g * addr_d_g -1 downto 0); -- address line
		din							:	in	std_logic_vector ( num_of_signals_g -1 downto 0);	-- in case that we want to store a data from external source
		trigger_in					:	in	std_logic											--trigger in external signal
		din_valid					:	in	std_logic;											-- 1 -> getting the data from an external source (dout = din). 0 -> dout is a counter
		dout						:	out	std_logic_vector ( num_of_signals_g -1 downto 0);	--data out. counter that start counting after reset fall
		trigger_out					:	out	std_logic											--trigger signal
---------whishbone signals----------------------------					
--		dout						:	out	std_logic_vector ( num_of_signals_g -1 downto 0);	--data out. counter that start counting after reset fall
--		trigger_out					:	out	std_logic											--trigger signal
	
	);
end entity signal_generator;

architecture behave of signal_generator is

------------------Constants------
constant	total_number_of_rows_c	:	natural := (2**signal_ram_depth_g) * up_case(2**record_depth_g , 2**signal_ram_depth_g)	  ; --number of "lines" in the total RAM array (depth, not width)
-------------------------Types------

------------------Signals--------------------
signal 	dout_s					:	std_logic_vector ( num_of_signals_g -1 downto 0);
signal	trigger_s				:  	std_logic;
signal	counter_s				:	integer range 0 to 1000; 
------------------	Processes	----------------

begin
							
	data_out: process (clk, reset)
	
	begin
		if reset = reset_polarity_g then
			dout_s		<= (others => '0') ;
			trigger_s	<= '0';
			counter_s	<= 1;
			
		elsif rising_edge(clk) then
			
			case State is
				when idle =>
					din_valid					<=  '0' ;
						
				when others =>
						State <= idle ;

			end case;
		counter_s	<= 0 	when  counter_s = 1000	else counter_s + 1 ;
		dout_s 		<= std_logic_vector( to_unsigned( counter_s , num_of_signals_g)); 
		end if;
	end process data_out;
	
dout_proc	:
	dout		<= din 			when  din_valid = '1'		else dout_s ;
	trigger_out	<= trigger_in 	when  trigger_valid = '1'	else trigger_s ;
--------------------------------------------------------------------------
end architecture behave;