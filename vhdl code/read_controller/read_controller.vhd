
entity width_FlipFlop is
	GENERIC (
		signal_ram_width_g	 : 	positive  :=8  --width of RAM
	);
	port
	(
		clk	:	in std_logic;
		d	:	in std_logic_vector(signal_ram_width_g-1 downto 0);
		q	:	out std_logic_vector (signal_ram_width_g-1 downto 0)
	);	
end entity width_FlipFlop;

architecture behave of width_FlipFlop is
begin
q<=d when (clk'event and clk = '1' );
end architecture behave;
---------------------------------------------------------------------------------------------------------------------


entity alu_addr_out is
	GENERIC (
			Reset_polarity_g	:	std_logic	:=	1;	--'1' reset active highe, '0' active low
			signal_ram_width_g	 : 	positive  	:=	8;		--width of RAM
			Add_width_g 		:	positive 	:=  8   --width of basic word
			);
	port (			
		reset 					:	 in std_logic;
		trigger_found 			:	 in std_logic;										--'1' if we found the trigger, '0' other
		wc_to_rc_alu			:	 in std_logic_vector( (2*Add_width_g) -1 downto 0);	--start and end addr of data that needed to be sent out
		current_addr_out_alu 	:	 in std_logic_vector( Add_width_g -1 downto 0);		--the current addr that we send out
		next_addr_out_alu		:	 out std_logic_vector( Add_width_g -1 downto 0);	--the addr that will be sent next cycle
		alu_to_counter_out		:	 out std_logic										-- '1' if counter is counting, '0' other
		);	
end entity alu_addr_out;

architecture behave of alu_addr_out is
begin
	process (reset)
	begin
		if reset = Reset_polarity_g then 										--reset is on
			next_addr_out_alu <= -- what to put when rseting?
			alu_to_counter_out <= '0' ;
		else 
			if trigger_found = '0' then											--reset off, trigger found off
				next_addr_out_alu <= current_addr_out_alu ; 					--stay in prev state
			else																--reset off, trigger found on 
				next_addr_out_alu <= current_addr_out_alu + signal_ram_width_g;	-------------need to handle with start and finish addr
			end if;
		end if;
	end process;
	q<=d when (clk'event and clk = '1' );
end architecture behave;
-----------------------------------------------------------------------------------------------------------------------


entity alu_rc_to_WBM is
	GENERIC (
			signal_ram_width_g 	:		positive	:=	8	--width of basic word in RAM 	
			);
	port (
	
			dout_valid_alu			:	in std_logic;
			data_in_rc_alu			:	in std_logic_vector( signal_ram_width_g -1 downto 0);
			rc_to_WBM_out_alu		:	out std_logic_vector( signal_ram_width_g -1 downto 0)
		);	
end entity alu_rc_to_WBM;

architecture behave of alu_rc_to_WBM is
begin
	rc_to_WBM_out_alu <= data_in_rc_alu when dout_valid_alu = '1' else
	rc_to_WBM_out_alu <= "00000000" ;	--need to fix- what to do if the data is unvalid? (now we put zeroes in the next word)
						
end architecture behave;

 	