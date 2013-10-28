------------------------------------------------------------------------------------------------
-- File Name	:	in_out_cordinator.vhd
-- Generated	:	21.9.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--				coordinate between input data (num_of_signals_g) to output data (data_width_g)
--				if input < output use in_small_out_cordinator, 
-- 				if input = output use in_equal_out_cordinator,
-- 				else (input > output) use in_big_out_cordinator.
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

entity in_out_cordinator_generic is
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
end entity in_out_cordinator_generic;

architecture behave of in_out_cordinator_generic is
	
component in_equal_out_cordinator
		GENERIC (
		reset_polarity_g			:	std_logic	:=	'1';
		out_width_g            		:	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
		in_width_g					:	positive	:=	8									--number of signals that will be recorded simultaneously
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
end component in_equal_out_cordinator;
	
component in_small_out_cordinator is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
			out_width_g            	:	positive 	:= 	8;      						    -- defines the width of the data lines of the system 
			in_width_g				:	positive	:=	4									--number of signals that will be recorded simultaneously
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
end component in_small_out_cordinator;

component in_big_out_cordinator is
	GENERIC (
			reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
			out_width_g            	:	positive 	:= 	4;      						    -- defines the width of the data lines of the system 
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
end component in_big_out_cordinator;

begin
		cordinator1_proc:
		if (out_width_g = in_width_g) generate
			equal_cordenator_proc:	in_equal_out_cordinator generic map (
																		reset_polarity_g 	=> reset_polarity_g,
																		out_width_g	=> out_width_g,						
																		in_width_g			=> in_width_g
																	)
														port map	(
																		clk				=> clk,
																		reset			=> reset,
																		data_in			=> data_in,
																		data_in_valid	=> data_in_valid,
																		data_out		=> data_out, 
																		data_out_valid	=> data_out_valid	
																	);
		end generate cordinator1_proc;
		
		cordinator2_proc:
		if (out_width_g < in_width_g) generate
			big_cordenator_proc:	in_big_out_cordinator generic map (
																		reset_polarity_g 	=> reset_polarity_g,
																		out_width_g		=> out_width_g,						
																		in_width_g	=> in_width_g
																	)
														port map	(
																		clk				=> clk,
																		reset			=> reset,
																		data_in			=> data_in,
																		data_in_valid	=> data_in_valid,
																		data_out		=> data_out, 
																		data_out_valid	=> data_out_valid	
																	);
		end generate cordinator2_proc;
		
		cordinator3_proc:
		if (out_width_g > in_width_g) generate
			small_cordenator_proc:	in_small_out_cordinator generic map (
																		reset_polarity_g 	=> reset_polarity_g,
																		out_width_g		=> out_width_g,						
																		in_width_g	=> in_width_g
																	)
														port map	(
																		clk				=> clk,
																		reset			=> reset,
																		data_in			=> data_in,
																		data_in_valid	=> data_in_valid,
																		data_out		=> data_out, 
																		data_out_valid	=> data_out_valid	
																	);
		
		end generate cordinator3_proc;
end architecture behave;