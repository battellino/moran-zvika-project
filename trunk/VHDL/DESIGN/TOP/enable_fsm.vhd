------------------------------------------------------------------------------------------------------------
-- File Name	:	enable_fsm.vhd
-- Generated	:	9.5.2013
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------------------
-- Description: 
--				State Machine for enabling write controller.
--				determine when to enable the WC. 
--				RC enable is through WC_finish signal
--				
------------------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		9.5.2013	Moran Katz						Creation			
------------------------------------------------------------------------------------------------------------
--	Todo:
--		
--		
------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;

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
------------------------Constants------
-------------------------Types---------
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
signal		not_enable_trig_s	: std_logic;
signal		enable_d1_s			: std_logic;														-- delayed enable

------------------	Processes	----------------

begin
							
	State_machine: process (clk, reset)
	begin
		if reset = reset_polarity_g then
			State <= idle;
			enable_d1_s <= not (enable_polarity_g);
			enable_trig_s <= '0';
			enable_out <= not (enable_polarity_g);
		elsif rising_edge(clk) then
			enable_d1_s <= enable;
			enable_trig_s <= (enable) and (not(enable_d1_s)) ;
			not_enable_trig_s <= ( not (enable)) and (enable_d1_s) ;
			
			case State is
				when idle =>		-- start state. 
						State <= wait_for_enable_rise ;
						enable_out <= not (enable_polarity_g);
									
				when wait_for_enable_rise =>		-- waiting for WC to detect trigger rise
					if enable_polarity_g = '1' then
						if enable_trig_s = '1' then		--check if enable_trigger has rised => meaning that enable rise
							State <= system_is_enable ;
							enable_out <=  (enable_polarity_g);
						else
							State <= wait_for_enable_rise;
							enable_out <= not (enable_polarity_g);
						end if;
					else
						if not_enable_trig_s = '1' then		--check if enable_trigger has rised => meaning that enable rise
							State <= system_is_enable ;
							enable_out <=  (enable_polarity_g);
						else
							State <= wait_for_enable_rise;
							enable_out <= not (enable_polarity_g);
						end if;
					end if;
						
				when system_is_enable =>
					if wc_finish = '1' then
						State <= write_controller_finish ;
						enable_out <= not (enable_polarity_g);
					else	
						State <= system_is_enable ;
						enable_out <=  enable_polarity_g;
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