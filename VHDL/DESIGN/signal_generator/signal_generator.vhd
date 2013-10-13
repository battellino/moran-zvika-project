------------------------------------------------------------------------------------------------
-- File Name	:	signal_generator.vhd
-- Generated	:	07.01.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--			The entity generates a trigger and data signals according the chosen scene
--			The user chose one of different scenes that are defined in the entity, (we have 5 scenes for now)
--			The output data is a cyclic counter that change between 0 to 2^record_depth_g
--			We can also get the data and trigger signals from an external source 
--			
--			Scene description:
--			scene 1:	first half- high					second half- low
--			scene 2:	first half- low						second half- high
--			scene 3:	first/forth quarter- high			second/third  quarter- low
--			scene 4:	first/forth quarter- low			second/third  quarter- high
--			scene 5:	cyclic (one duty cycle = 4 clock cycles)
--
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		26.08.2013	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			
--			
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
---------------------------------------------------------------------------------------------------------------------------------------

entity signal_generator is
	generic (
			reset_polarity_g		:	std_logic	:=	'1';									--'1' reset active high, '0' active low
			data_width_g            :	positive 	:= 	8;      						    	--defines the width of the data lines of the system 
			num_of_signals_g		:	positive	:=	4;										--number of signals that will be recorded simultaneously
			external_en_g			:	std_logic	:=	'0'										-- 1 -> getting the data from an external source . 0 -> dout is a counter
			);
	port
	(
		clk							:	in  std_logic;											--system clock
		reset						:	in  std_logic;											--system reset
		scene_number_in				:	in	std_logic_vector ( data_width_g - 1 downto 0);						--type of trigger scene
		scene_valid					:	in	std_logic;											--scene in is valid
		data_in						:	in	std_logic_vector ( num_of_signals_g -1 downto 0);	-- in case that we want to store a data from external source
		trigger_in					:	in	std_logic;											--trigger in external signal
--		external_en					:	in	std_logic;											-- 1 -> getting the data from an external source . 0 -> dout is a counter
--		generator_finish			:	in	std_logic;											--read controller is finish -> ready to read a new scene
		data_out					:	out	std_logic_vector ( num_of_signals_g -1 downto 0);	--data out
		trigger_out					:	out	std_logic											--trigger out signal
	
	);
end entity signal_generator;

architecture behave of signal_generator is

-- SYMBOLIC ENCODED state machine: State
	type State_type is (
	idle,										--first state, initial all signals
	wait_for_scene_number,						--wait for receiving a scene number
	output_data									--output the data and the trigger according the chosen scene
	);
	
------------------Constants------
constant ex_enable_c	:	std_logic									:= external_en_g;
constant max_counter_c	:	positive 									:= 2**num_of_signals_g	- 1  ;					--maximum value of counter
constant scene_1_c 		: 	std_logic_vector(data_width_g - 1 downto 0)	:= conv_std_logic_vector(1, data_width_g);		-- 0 is saved for initialize
constant scene_2_c 		: 	std_logic_vector(data_width_g - 1 downto 0)	:= conv_std_logic_vector(2, data_width_g);
constant scene_3_c 		: 	std_logic_vector(data_width_g - 1 downto 0)	:= conv_std_logic_vector(3, data_width_g);
constant scene_4_c 		: 	std_logic_vector(data_width_g - 1 downto 0)	:= conv_std_logic_vector(4, data_width_g);
constant scene_5_c 		: 	std_logic_vector(data_width_g - 1 downto 0)	:= conv_std_logic_vector(5, data_width_g);
-------------------------Types------

------------------Signals--------------------
signal 	State					: 	State_type;
signal 	data_out_s				:	std_logic_vector ( num_of_signals_g -1 downto 0);
signal	trigger_s				:  	std_logic;
signal	data_counter_s			:	integer range 0 to  2**num_of_signals_g ; 
signal 	scene_number_s			:	std_logic_vector ( data_width_g - 1 downto 0);
------------------	Processes	----------------

begin
	State_machine: process (clk, reset)
		
	begin
		if reset = reset_polarity_g then
			State <= idle;
			data_out <= (others => '0');
			trigger_out <= '0';
			data_out_s	<= (others => '0');
			trigger_s <= '0';
			scene_number_s 	<= (others => '0');
			data_counter_s <= 0;
		elsif rising_edge(clk) then
			case State is
				when idle =>						-- start state. initial all signals and variables
					State <= wait_for_scene_number;
					data_out <= (others => '0');
					trigger_out <= '0';
					data_out_s	<= (others => '0');
					trigger_s <= '0';
					scene_number_s 	<= (others => '0');
					data_counter_s <= 0;
					
				when wait_for_scene_number =>		
					if scene_valid = '1' then
						scene_number_s <= scene_number_in ;						
						State <= output_data ;
					else
						State <= wait_for_scene_number ;
					end if;
				
				when output_data =>
--					if generator_finish = '1' then																	--return to initial state
--						State <= idle ;
--					else																					--continue output the data
						State 		<= output_data ;
						data_out_s 	<= std_logic_vector( to_unsigned( data_counter_s , num_of_signals_g));
						if data_counter_s = max_counter_c then												--counter receive maximum value
							data_counter_s	<= 0 ;
						else
							data_counter_s	<= data_counter_s + 1 ;
						end if;
					
						------send data out
						if ex_enable_c = '1' then				--get the data from an external source
							data_out		<= data_in;
							trigger_out		<= trigger_in;
						else									--get the data from internal counter
							data_out		<=  data_out_s ;
							trigger_out		<=  trigger_s ;
						end if;
					---------determine trigger scene
						if (scene_number_s = scene_1_c) then				---scene 1
							if (	(data_counter_s < (2**num_of_signals_g)/2 )	)	 then
								trigger_s <= '1';
							else
								trigger_s <= '0';
							end if;

						elsif (scene_number_s = scene_2_c) then				---scene 2
							if (	(data_counter_s > (2**num_of_signals_g)/2 )	)	 then
								trigger_s <= '1';
							else
								trigger_s <= '0';
							end if;
						
						elsif (scene_number_s = scene_3_c) then				---scene 3
							if (	((data_counter_s > 0 )and(data_counter_s < (2**num_of_signals_g)/4 ))	or	(data_counter_s > (2**num_of_signals_g)*(3/4) )	) then
								trigger_s <= '1';
							else
								trigger_s <= '0';
							end if;
						
						elsif (scene_number_s = scene_4_c) then				---scene 4
							if (	((data_counter_s > 0 )and(data_counter_s < (2**num_of_signals_g)/4 ))	or	(data_counter_s > (2**num_of_signals_g)*(3/4) )	) then
								trigger_s <= '0';
							else
								trigger_s <= '1';
							end if;
						
						elsif (scene_number_s = scene_5_c) then				---scene 5
							if (	(data_counter_s mod 4) = 0 	) then
								trigger_s <= not trigger_s;
							else
								trigger_s <= trigger_s;
							end if;
						
						else
							trigger_s <= '0';
						end if;
--					end if;
			end case;
		end if;
	end process;				
	
end architecture behave;