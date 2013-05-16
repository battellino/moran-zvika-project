------------------------------------------------------------------------------------------------------------
-- File Name	:	enable_fsm.vhd
-- Generated	:	9.5.2013
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


------------------------------------------------------------------------------------------------------------
entity enable_fsm is
	GENERIC (
		reset_polarity_g		:	std_logic	:=	'1';								--'1' reset active high, '0' active low
		enable_polarity_g		:	std_logic	:=	'1'								--'1' the core starts working when signal high , '0' working when low
		
			);
	port (			
		clk						:	 in  std_logic;										--system clk
		reset 					:	 in  std_logic;										--reset
		enable					:	 in	 std_logic;										-- the signal is being recieved from the software. enabling the entity. 	
		wc_finish				:	 in	 std_logic;
		rc_finish				:	 in	 std_logic;										--'1' -> read controller finish working, '0' -> system still working
		enable_out				:	 out std_logic										 --enable signal that sent to the core 
		);
end entity enable_fsm;
------------------------------------------------------------------------------------------------------------------------------------------------------------
architecture behave of enable_fsm is
------------------Constants------

-------------------------Types------
type enable_states is (
	idle,					--initial state,vriables are initialized.
	wait_for_enable_rise,	--all the cofigurations are set, waiting for enable rise.
	system_is_enable,		--the data is being recorded,after trigger rise and data recording is finished, waits for the rc to finish.
	write_controller_finish,--write controller finish working, all the data have been recorded. RC start working from now
	read_controller_finish	--rc is finished. the system stops working, waits to enable fall. 
	);
------------------Signals--------------------
signal State: enable_states;
signal		enable_trig_s		: std_logic;														--replace enable in enable trig -> identify for enable rise
signal		enable_d1_s			: std_logic;														-- delayed enable
signal		enable_s			: std_logic;														-- enable the system

------------------	Processes	----------------

begin
	
		
						
	State_machine: process (clk, reset)
	begin
		if reset = reset_polarity_g then
			State <= idle;
			enable_d1_s <= '0';
			enable_trig_s <= '0';
			enable_s <= '0';
			enable_out <= not (enable_polarity_g);
		elsif rising_edge(clk) then
			enable_d1_s <= enable;
			enable_trig_s <= (enable) and (not(enable_d1_s)) ;
			if enable_trig_s = '1' then
				enable_s <= '1';
			elsif ((State = read_controller_finish) and (enable = not (enable_polarity_g)))	then
				enable_s <= '0';
			end if;
		
			
			case State is
				when idle =>		-- start state. 
						State <= wait_for_enable_rise ;
						enable_out <= not (enable_polarity_g);
									
				when wait_for_enable_rise =>		-- waiting for WC to detect trigger rise
					if enable_s = '1' then		--check if signal "enable_s" is '1' to enable the system
						State <= system_is_enable ;
						enable_out <=  (enable_polarity_g);
					else
						State <= wait_for_enable_rise;
						enable_out <= not (enable_polarity_g);
					end if;
				
				when system_is_enable =>
					if wc_finish = '1' then
						State <= write_controller_finish ;
						enable_out <= not (enable_polarity_g);
					else	
						State <= system_is_enable ;
						enable_out <=  (enable_polarity_g);
					end if;
				
				when write_controller_finish =>
					if rc_finish = '1' then
						State <= read_controller_finish ;
						enable_out <= not (enable_polarity_g);
					else
						State <= write_controller_finish ;
						enable_out <= not (enable_polarity_g);
					end if;
				
				when read_controller_finish =>
					if (enable =  not (enable_polarity_g)) then
						State <= idle ;
						enable_out <= not (enable_polarity_g);
					else
						State <= read_controller_finish ;
						enable_out <= not (enable_polarity_g);
					end if;
					
				when others =>
						State <= idle ;
						enable_out <= not (enable_polarity_g);
			end case;							
		end if;		
	end process State_machine;
		
			
	
--------------------------------------------------------------------------

	
end architecture behave;









