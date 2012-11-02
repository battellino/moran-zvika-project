library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;


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
	process (reset)				--dose it work just after reset signal will change?
	begin
		if reset = Reset_polarity_g then 										--reset is on
			next_addr_out_alu <= (others => '0') ;								--resetting to zeroes
			alu_to_counter_out <= '0' ;											--dont activate counter
		else 
			if trigger_found = '0' then											--reset off, trigger found off
				next_addr_out_alu <= current_addr_out_alu ; 					--stay in prev state (not necessary)
			else																--reset off, trigger found on 
				next_addr_out_alu <= current_addr_out_alu + signal_ram_width_g;	-------------need to handle with start and finish addr
			end if;
		end if;
	end process;
	q<=d when (clk'event and clk = '1' );
end architecture behave;