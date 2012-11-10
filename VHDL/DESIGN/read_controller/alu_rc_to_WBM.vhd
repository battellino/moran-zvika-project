------------------------------------------------------------------------------------------------------------
-- File Name	:	alu_rc_to_WBM.vhd
-- Generated	:	9.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------------------
-- Description: 
--				getting the data that come from the RAM (width of signal_ram_width_g), and if its 
--				valid (dout_valid_alu = '1') send it out, if not send out zeroes.
--				the ENTITY is not working with the clk, the output will change if there will be a 
--				change in the incomming data (data_in_rc_alu) or in the validation signal (dout_valid_alu).
------------------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		9.11.2012	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------------------
--	Todo:
--			
------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
------------------------------------------------------------------------------------------------------------


entity alu_rc_to_WBM is
	GENERIC (
			signal_ram_width_g 	:		positive	:=	8	--width of basic word in RAM 	
			);
	port (
	
			dout_valid_alu			:	in std_logic  ;
			data_in_rc_alu			:	in std_logic_vector( signal_ram_width_g -1 downto 0);
			rc_to_WBM_out_alu		:	out std_logic_vector( signal_ram_width_g -1 downto 0)
		);	
end entity alu_rc_to_WBM;

architecture behave of alu_rc_to_WBM is
begin
move_data : process (data_in_rc_alu, dout_valid_alu )                                      --enter process after change in data or in validation
            begin
                if dout_valid_alu = '1' then
                  rc_to_WBM_out_alu <=  data_in_rc_alu  ;
                else
                  rc_to_WBM_out_alu <= (others => '0')  ;
                end if;
            end process move_data;


end architecture behave;