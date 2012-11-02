---------------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
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
	rc_to_WBM_out_alu <= (others => '0') ;								--resetting value to zeroes
						
end architecture behave;

 	