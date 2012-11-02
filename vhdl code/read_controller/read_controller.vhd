library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
---------------------------------------------------------------------------------------------------------------------------------------

entity read_controller is
	GENERIC (
		Reset_polarity_g	 :	std_logic :=1  ;	--'1' reset active highe, '0' active low
		signal_ram_width_g	 : 	positive  :=8  ;	--width of RAM
		addr_width_g		 : 	positive  :=8  ;	--addr width of WB
		data_width_g		 : 	positive  :=8  		--width of basic word in WB
	);
	port
	(
		clk				:	in std_logic;											--system clock
		reset			:	in std_logic;											--system reset
		trigger_found	:	in std_logic	:= 0	;								--trigger rise was found
		wc_to_rc		:	in std_logic_vector((2*addr_width_g) - 1 downto 0);		--start and end addr of data needed to output
		data_in_rc		:	in std_logic_vector(signal_ram_width_g - 1 downto 0);	--one word of data send to WBM
		dout_valid		:	in std_logic	:= 0	;								--output data valid
		clk_to_start	:	out integer range 0 to 255	;							--count clk cycles since trigger rise
		rc_to_WBM		:	out std_logic_vector (data_width_g - 1 downto 0);		--data out to WBM
		addr_out		:	out std_logic_vector (signal_ram_width_g - 1 downto 0)	--addr send to RAM to output
	);	
end entity read_controller;

architecture behave of read_controller is

-------------------------------------------------------	Components	------------------------------------------------------------------

--1. save data that come from RAM 2. save the next addr that will be send to the RAM
component width_flipflop
	GENERIC (
		signal_ram_width_g	 : 	positive  :=8 										--width of RAM
	);
	port
	(
		clk	:	in std_logic;														--system clock
		d	:	in std_logic_vector(signal_ram_width_g-1 downto 0);					--input
		q	:	out std_logic_vector (signal_ram_width_g-1 downto 0)				--output
	);	
end component width_flipflop;

--save the clk cycle of counter
component integer_flipflop
	port
	(
		clk	:	in std_logic;														--system clock
		d	:	in integer range 0 to 255 ;											--input
		q	:	out integer range 0 to 255											--output
	);	
end component integer_flipflop;

--calculate the addr that need to be send to the RAM in the next cycle
component alu_addr_out is
	GENERIC (
			Reset_polarity_g	:	std_logic	:=	1;								--'1' reset active highe, '0' active low
			signal_ram_width_g	: 	positive  	:=	8;								--width of RAM
			Add_width_g 		:	positive 	:=  8   							--width of basic word
			);
	port (			
		reset 					:	 in std_logic;
		trigger_found 			:	 in std_logic;										--'1' if we found the trigger, '0' other
		wc_to_rc_alu			:	 in std_logic_vector( (2*Add_width_g) -1 downto 0);	--start and end addr of data that needed to be sent out
		current_addr_out_alu 	:	 in std_logic_vector( Add_width_g -1 downto 0);		--the current addr that we send out
		next_addr_out_alu		:	 out std_logic_vector( Add_width_g -1 downto 0);	--the addr that will be sent next cycle
		alu_to_count_out		:	 out std_logic										-- '1' if counter is counting, '0' other
		);	
end component alu_addr_out;

--send the data to the WBM if the data is valid
component alu_rc_to_WBM is
	GENERIC (
			signal_ram_width_g 	:		positive	:=	8										--width of basic word in RAM 	
			);
	port (
			dout_valid_alu			:	in std_logic;											--enable the data
			data_in_rc_alu			:	in std_logic_vector( signal_ram_width_g -1 downto 0);	--data in from RAM
			rc_to_WBM_out_alu		:	out std_logic_vector( signal_ram_width_g -1 downto 0)	--data out to WBM
		);	
end component alu_rc_to_WBM;

--count cycles that passed since trigger rise (in integer) 
component integer_count is
	GENERIC (
			Reset_polarity_g	:	std_logic	:=	1								--'1' reset active highe, '0' active low
			);
	port (
			clk						:	in std_logic;
			reset					:	in std_logic;
			alu_to_count_in			:	in std_logic;
			ff_to_count				:	in integer range 0 to 255 ;
			count_to_ff				:	out integer range 0 to 255 ;
		);	
end component integer_count;

-------------------------------------------------------	signals	--------------------------------------------------------------------------
signal ff_to_count_s	:	integer range 0 to 255;												--Internal FF to counter
signal count_to_ff_s	:	integer range 0 to 255;												--Internal counter to FF
signal current_addr_s	:	std_logic_vector( Add_width_g -1 downto 0);							--Internal FF to addr_ALU 
signal next_addr_s		:	std_logic_vector( Add_width_g -1 downto 0);							--Internal addr_ALU to FF 
signal data_s			:	std_logic_vector( signal_ram_width_g -1 downto 0);					--Internal data_ALU to FF 
signal alu_to_counter_s :	std_logic 

-------------------------------------------------------	Implementation	------------------------------------------------------------------
begin

	shift_data:
	if( dout_valid = '1' ) generate 
		alu_inst_width_ff : alu_rc_to_WBM generic map (							
											signal_ram_width_g	=> signal_ram_width_g
									)
									port map 	(
									dout_valid_alu		=> dout_valid,
									data_in_rc_alu		=> data_in_rc,
									rc_to_WBM_out_alu	=> data_s
									);
		
		width_ff_inst_WBM : width_flipflop generic map (							
									signal_ram_width_g	=> signal_ram_width_g
									)
									port map 	(
									clk		=> clk,
									d		=> data_s,
									q		=> rc_to_WBM
									);
				
	end generate shift_data;

	calc_new_addr:
	if( trigger_found = '1' ) generate
		alu_inst_counter : alu_addr_out generic map(
										Reset_polarity_g	=> Reset_polarity_g,							--'1' reset active highe, '0' active low
										signal_ram_width_g	=> signal_ram_width_g,							--width of RAM
										Add_width_g 		=> Add_width_g
										)
										port map	(
										reset					=>	reset,
										trigger_found			=>	trigger_found,
										wc_to_rc_alu			=>	wc_to_rc,
										current_addr_out_alu	=>	current_addr_s,
										next_addr_out_alu		=>	next_addr_s,
										alu_to_counter_out		=>	alu_to_counter_s
										);
										
		width_ff_inst_addr_out : width_flipflop generic map (
												signal_ram_width_g	=> signal_ram_width_g
												)
												port map	(
												clk	=> clk,													--system clk
												d	=> next_addr_s,											--signal betwin ALU and ff
												q	=> addr_out												--addr send to the RAM
												);
												
		counter	:	integer_count	generic map (
												Reset_polarity_g	=> Reset_polarity_g
									)
									port map	(
									clk				=>	clk,
									reset			=>	reset,
									alu_to_count_in	=>	alu_to_counter_s,
									ff_to_count		=>	ff_to_count_s,
									count_to_ff		=>	count_to_ff_s
									);
		ff_inst_clk_to_start	:	integer_flipflop	port map	(
														clk	=>	clk,
														d	=>	count_to_ff_s,
														q	=>	clk_to_start
														);


end architecture behave;
---------------------------------------------------------------------------------------------------------------------

