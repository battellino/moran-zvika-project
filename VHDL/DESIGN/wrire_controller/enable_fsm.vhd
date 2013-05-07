------------------------------------------------------------------------------------------------------------
-- File Name	:	alu_data.vhd
-- Generated	:	17.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------------------
-- Description: 
--				calculate the address in the RAM of the current data.
--				take the incomimg data and separate it to the correct RAMs with the correct addr 
--				
--				
--				
------------------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		17.11.2012	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------------------
--	Todo:
--		
--		
--		now the two prosseses of puting the data and advancing the addr are happening in the same time, what we do first?
--		
--		
------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;


library work ;
use work.write_controller_pkg.all;

------------------------------------------------------------------------------------------------------------
entity enable_fsm is
	GENERIC (
		reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active highe, '0' active low
		enable_polarity_g		:	std_logic	:=	'1'								--'1' the entity is active, '0' entity not active
		
			);
	port (			
		clk						:	 in  std_logic;										--system clk
		reset 					:	 in  std_logic;										--reset
		enable					:	 in	 std_logic;										--enabling the entity. if (sytm_stst = Reset_polarity_g) -> start working, else-> do nothing	
		enable_out				:	 out std_logic										 --enable signal that sent to the core 
		);
end entity enable_fsm;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of enable_fsm is
------------------Constants------

-------------------------Types------

------------------Signals--------------------
signal		enable_trig_s		: std_logic;														--replace enable in enable trig -> identify for enable rise
signal		enable_d1_s			: std_logic;														-- delayed enable
signal		enable_s			: std_logic;														-- enable the system
------------------	Processes	----------------

begin
	
		enable_proc	:	process ( reset, clk )
		begin
			if reset = Reset_polarity_g then
				enable_d1_s <= '0';
				enable_trig_s <= '0';
				enable_out <= '0';
				enable_s <= '0';
			elsif rising_edge(clk) then	
				enable_d1_s <= enable;
				enable_trig_s <= (enable) and (not(enable_d1_s)) ;
				if enable_trig_s = '1' then
					enable_s <= '1';
				end if;
			end if;			
		enable_out <= enable_s	;
	end process enable_proc;

--	rise_proc	:	process ( enable_trig_s,reset, clk )
--		begin		
--			if reset = Reset_polarity_g then
--				enable_s <= '0';
--				enable_out <= '0';
--			elsif rising_edge (enable_trig_s) then				--when enable trigger rise -> enable the system
--				enable_s <= '1';
--			end if;
--			enable_out <= enable_s	;
--	end process rise_proc;
	
end architecture behave;









