-----------------------------------------------------------------------------------------------
-- Model Name 	:	Timer - client
-- File Name	:	timer.vhd
-- Generated	:	10.06.2011
-- Author		:	Dor Obstbaum and Kami Elbaz
-- Project		:	FPGA setting usiing FLASH project
------------------------------------------------------------------------------------------------
-- Description: 
-- The block generates a signal (timer_tick) every 'tick_cycle_c' cycles by counting system clock signal.
------------------------------------------------------------------------------------------------
-- Revision History:
--			Number 		Date	       	Name       			 	Description
--			1.0		   10.06.2011  	Dor Obstbaum	 		Creation
------------------------------------------------------------------------------------------------
--	Todo:
--							
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;

entity timer is
   generic (
     --timer generics:
     reset_activity_polarity_g  : std_logic :='1';      -- defines reset active polarity: '0' active low, '1' active high
     timer_freq_g               : positive  :=1000;    -- timer_tick will raise for 1 sys_clk period every timer_freq_g. units: [Hz]  
     clk_freq_g                 : positive  :=100000000; -- the clock input to the block. this is the clock used in the system containing the timer unit. units: [Hz]
     timer_en_polarity_g        : std_logic :='1'     -- defines the polarity which the timer enable (timer_en) is active on: '0' active low, '1' active high   
           );
   port
   	   (
     sys_clk       : in std_logic; --system clock
     sys_reset     : in std_logic; --system reset
     timer_en      : in std_logic; --determines if the timer is enabled
     timer_tick    : out std_logic --ticks every [tick_cycle_c] cycles    
   	   );
end entity timer;

architecture arc_timer of timer is

------------------  	Constants	------
constant tick_cycle_c       : natural := clk_freq_g/timer_freq_g; -- the number of sys_clk cycles counted in order to recieve a tick 

------------------  	Types		------

------------------  SIGNALS --------------------

signal counter                 : natural range 0 to tick_cycle_c;  -- the timer's internal count 

------------------	Processes	----------------
---------------------------------------------
begin  
	      
timer_proc : process(sys_clk, sys_reset)
	 begin
		 if sys_reset=reset_activity_polarity_g then --counter reset
		   counter <=0;
		   timer_tick <='0'; 
		 elsif rising_edge(sys_clk)then
		     if timer_en = timer_en_polarity_g then 
		       if counter = tick_cycle_c then
		        timer_tick <= '1';
		         counter <=0;
		       else
		         timer_tick <= '0';
		         counter <= counter +1;
		       end if;
		     else
		       counter <= 0;
		       timer_tick <='0';
		     end if; 
     end if;
end process timer_proc;
	
end architecture arc_timer;