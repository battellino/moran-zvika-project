------------------------------------------------------------------------------------------------
-- File Name	:	in_out_cordinator.vhd
-- Generated	:	21.9.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
--				cordinate between input data (num_of_signals_g) to output data (data_width_g)
--				in that entity the input < output, 
-- 				meaning num_of_signals_g < data_width_g
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

entity data_input_generic is
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
end entity data_input_generic;

architecture behave of data_input_generic is
	
component data_input_big
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
end component data_input_big;
	
component data_input_small is
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
end component data_input_small;


begin
		cordinator1_proc:
		if (	(in_width_g = out_width_g) or (in_width_g > out_width_g)	) generate
			
			data_big_proc:	data_input_big generic map (
														reset_polarity_g	=>	reset_polarity_g,
														Add_width_g		   	=>	Add_width_g,
														out_width_g         =>	out_width_g,
														in_width_g			=>	in_width_g
																	)
											port map	(
														clk				=> clk,
														reset			=> reset,
														addr_in			=> addr_in,
														data_in			=> data_in,
														data_in_valid	=> data_in_valid,
														addr_out		=> addr_out,
														data_out		=> data_out, 
														data_out_valid	=> data_out_valid	
														);
		end generate cordinator1_proc;
		
		cordinator2_proc:
		if (in_width_g  < out_width_g) generate

			data_small_proc:	data_input_small generic map (
														reset_polarity_g	=>	reset_polarity_g,
														Add_width_g		   	=>	Add_width_g,
														out_width_g         =>	out_width_g,
														in_width_g			=>	in_width_g
																	)
											port map	(
														clk				=> clk,
														reset			=> reset,
														addr_in			=> addr_in,
														data_in			=> data_in,
														data_in_valid	=> data_in_valid,
														addr_out		=> addr_out,
														data_out		=> data_out, 
														data_out_valid	=> data_out_valid	
														);
		end generate cordinator2_proc;
		
		
end architecture behave;