------------------------------------------------------------------------------------------------
-- File Name	:	in_out_cordinator.vhd
-- Generated	:	21.9.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--				cordinate between input data (num_of_signals_g) to output data (data_width_g)
--				in that entity the input > output, 
-- 				meaning num_of_signals_g > data_width_g
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

entity in_big_out_cordinator is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
			out_width_g           	:	positive 	:= 	3;      						    -- defines the width of the data lines of the system 
			in_width_g				:	positive	:=	8									--number of signals that will be recorded simultaneously
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
end entity in_big_out_cordinator;

architecture behave of in_big_out_cordinator is
	-- SYMBOLIC ENCODED state machine: State
	type State_type is (
	wait_for_valid,										--wait for valid raise to stsrt output data
	output_data										--output the input data out in the correct length
	);

----------------------------------------------------CONSTANTS---------------------------------------------------------------
constant input_data_size_c				: integer range 0 to in_width_g					:=	in_width_g ;
----------------------------------------------------SIGNALS-----------------------------------------------------------------
signal State						: State_type;
signal data_in_to_out_s				: std_logic_vector( in_width_g - 1 downto 0 ) ;		--data that we extract from RAM and send to WBS
signal counter_s					: integer range 0 to 2*in_width_g;

begin
-----------------------------------------------------------------
-- Machine: State
-----------------------------------------------------------------
	State_machine: process (clk, reset)
	
	begin
		if reset = reset_polarity_g then
			State 				<= wait_for_valid;
			data_out			<= (others => '0');				
			data_out_valid	 	<= '0';
			counter_s <= 0;
			data_in_to_out_s	<= (others => '0');
			
		elsif rising_edge(clk) then
			case State is
				when wait_for_valid =>						-- start state. initial all signals and variables
					data_out			<= (others => '0');				
					data_out_valid	 	<= '0';
					counter_s <= 0;
					
					if( data_in_valid = '1') then
						data_in_to_out_s	<= data_in;
						State <= output_data;
					else 
						data_in_to_out_s	<= (others => '0');
						State <= wait_for_valid;
					end if;
					
				when output_data =>		--data_width_g < num_of_signals_g
						if( (counter_s + out_width_g) < in_width_g )  then
							data_out <= data_in_to_out_s(counter_s + out_width_g -  1 downto counter_s);
							counter_s <= counter_s + out_width_g;
							data_out_valid <= '1';
							State <= output_data;
						elsif ((counter_s + out_width_g) = in_width_g  ) then
							data_out <= data_in_to_out_s(counter_s + out_width_g -  1 downto counter_s);
							data_out_valid <= '1';
							State <= wait_for_valid;
						else
							data_out(in_width_g - counter_s - 1 downto 0 ) <= data_in_to_out_s(in_width_g -  1 downto counter_s);
							data_out(out_width_g - 1 downto in_width_g - counter_s ) <= (others => '0');
							data_out_valid <= '1';
							State <= wait_for_valid;
						end if;
			end case;
		end if;
	end process;
	
	
end architecture behave;



