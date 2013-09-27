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

entity data_input_small is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
			Add_width_g		   		:   positive	:= 	8;     								--width of addr word in the WB
			out_width_g           	:	positive 	:= 	3;      						    -- defines the width of the data lines of the system 
			in_width_g				:	positive	:=	8									--number of signals that will be recorded simultaneously
	);
	port
	(
		clk							:	in std_logic;											--system clock
		reset						:	in std_logic;											--system reset
		addr_in						:	in std_logic_vector (Add_width_g - 1 downto 0);
		data_in						:	in std_logic_vector (in_width_g - 1 downto 0);	-- data came from RAM 
		data_in_valid				:	in std_logic;											--data in valid
		addr_out					:	out std_logic_vector (Add_width_g - 1 downto 0);
		data_out					:	out std_logic_vector (out_width_g - 1 downto 0);		--data out to WBM
		data_out_valid				:	out std_logic											--data out valid
	);	
end entity data_input_small;

architecture behave of data_input_small is
	-- SYMBOLIC ENCODED state machine: State
	type State_type is (
	wait_for_valid,										--wait for valid raise to stsrt output data
	break_data,
	output_data										--output the input data out in the correct length
	);

----------------------------------------------------CONSTANTS---------------------------------------------------------------
constant input_data_size_c				: integer range 0 to in_width_g					:=	in_width_g ;
----------------------------------------------------SIGNALS-----------------------------------------------------------------
signal State						: State_type;
signal data_in_to_out_s				: std_logic_vector( in_width_g - 1 downto 0 ) ;		--data that we extract from RAM and send to WBS
signal counter_s					: integer range 0 to 2*out_width_g;
signal add_s						: std_logic_vector (Add_width_g - 1 downto 0);
signal data_finish_s				: std_logic_vector (out_width_g - 1 downto 0);


begin
-----------------------------------------------------------------
-- Machine: State
-----------------------------------------------------------------
	State_machine: process (clk, reset)
	
	begin
		if reset = reset_polarity_g then
			State 				<= wait_for_valid;
			addr_out			<= (others => '0');
			data_out			<= (others => '0');				
			data_out_valid	 	<= '0';
			counter_s <= 0;
			data_in_to_out_s	<= (others => '0');
			add_s				<= (others => '0');
			data_finish_s		<= (others => '0');
			
		elsif rising_edge(clk) then
			case State is
				when wait_for_valid =>						-- start state. initial all signals and variables
					data_out			<= (others => '0');				
					data_out_valid	 	<= '0';
					counter_s <= 0;
					data_finish_s		<= (others => '0');
					
					if( data_in_valid = '1') then
						data_in_to_out_s	<= data_in;
						add_s				<= addr_in;
						State <= break_data;
					else 
						data_in_to_out_s	<= (others => '0');
						add_s				<= (others => '0');
						State <= wait_for_valid;
					end if;
					
				when break_data =>		--data_width_g < num_of_signals_g
						if( (counter_s + out_width_g) < in_width_g )  then
							data_finish_s <= data_in_to_out_s(counter_s + out_width_g -  1 downto counter_s);
							counter_s <= counter_s + out_width_g;
							State <= break_data;
						elsif ((counter_s + out_width_g) = in_width_g  ) then
							data_finish_s <= data_in_to_out_s(counter_s + out_width_g -  1 downto counter_s);
							State <= output_data;
						else
							data_finish_s(in_width_g - counter_s - 1 downto 0 ) <= data_in_to_out_s(in_width_g -  1 downto counter_s);
							data_finish_s(out_width_g - 1 downto in_width_g - counter_s ) <= (others => '0');
							State <= output_data;
						end if;
				
				when output_data =>
					addr_out <= add_s;
					data_out <= data_finish_s;
					data_out_valid <= '1';				
					State <= wait_for_valid;
					
			end case;
		end if;
	end process;
	
	
end architecture behave;



