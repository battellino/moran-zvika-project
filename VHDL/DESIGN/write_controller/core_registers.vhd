-----------------------------------------------------------------------------------------------
-- File Name	:	Core Registers.vhd
-- Generated	:	04.1.2013
-- Author		:	Moran Kats and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description:  The Led Registers unit recieves data from the wishbone slaves, samples it, and transmits it to the led blocks. the data can be read anytime by wishbone
-- slave when asked to. When reset is activated no led should be enabled. The register's addreesses are defined by generics.
-- The unit contains five registers which are configed as follow:
-- en_reg(0) = led_1 enable
-- en_reg(1) = led_1 freq_en
-- en_reg(2) = led_2 enable
-- en_reg(3) = led_2 freq_en
-- en_reg(4) = led_3 enable
-- en_reg(5) = led_3 freq_en
-- en_reg(6) = led_4 enable
-- en_reg(7) = led_4 freq_en 
-- freq_reg_1 = led_1 frequency  
-- freq_reg_2 = led_2 frequency  
-- freq_reg_3 = led_3 frequency  
-- freq_reg_4 = led_4 frequency  
------------------------------------------------------------------------------------------------
-- Revision:
--			Number 		Date	       	Name       			 	Description
--			1.0		   04.1.2013  		zvika pery	 		Creation
--		    
--			
------------------------------------------------------------------------------------------------
--	Todo:
--							
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity core_registers is
   generic (
			reset_polarity_g			   :	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			enable_polarity_g			   :	std_logic	:=	'1';								--'1' the entity is active, '0' entity not active
			signal_ram_depth_g			   : 	positive  	:=	10;									--depth of RAM
			record_depth_g				   : 	positive  	:=	10;									--number of bits that is recorded from each signal
			data_width_g           		   :	natural 	:= 8;         							-- the width of the data lines of the system    (width of bus)
			addr_d_g					   :	positive 	:= 3;									--Address Depth
			Add_width_g  		   		   :    positive 	:=  8;     								--width of addr word in the RAM
			en_reg_address_g      		   : 	natural :=0;
			trigger_type_reg_1_address_g 	   : 	natural :=1;
			trigger_position_reg_2_address_g : 	natural :=2;
			clk_to_start_reg_3_address_g 	   : 	natural :=3;
			enable_reg_address_4_g 		   : 	natural :=4
           );
   port
   	   (
     clk			   : in std_logic; --system clock
     reset   		   : in std_logic; --system reset
     -- wishbone slave interface
	 address_in        : in std_logic_vector (data_width_g * addr_d_g -1 downto 0); -- address line
	 wr_en             : in std_logic; -- write enable: '1' for write, '0' for read
	 data_in           : in std_logic_vector (data_width_g-1 downto 0); -- data sent from WS
     valid_in          : in std_logic; -- validity of the data directed from WS
     data_out          : out std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
     valid_data_out    : out std_logic; -- validity of data directed to WS
     -- led blocks interface
     en_out            : out std_logic_vector (data_width_g-1 downto 0); -- enable data sent to trigger pos, triiger type, clk to stars, enable
     trigger_type_out_1        : out std_logic_vector (data_width_g-1 downto 0); -- trigger type
     trigger_positionout_2        : out std_logic_vector (data_width_g-1 downto 0); -- trigger pos
     clk_to_start_out_3        : out std_logic_vector (data_width_g-1 downto 0); -- count cycles that passed since trigger rise
     enable_out_4        : out std_logic_vector (data_width_g-1 downto 0)  -- enable sent by yhe GUI
   	   );
end entity core_registers;

architecture behave of core_registers is

--*****************************************************************************************************************************************************************--
---------- Constants	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
constant en_reg_address_c     : std_logic_vector(data_width_g * addr_d_g -1 downto 0) := conv_std_logic_vector(en_reg_address_g, data_width_g * addr_d_g);
constant trigger_type_reg_1_address_c : std_logic_vector(data_width_g * addr_d_g -1 downto 0) := conv_std_logic_vector(trigger_type_reg_1_address_g, data_width_g * addr_d_g);
constant trigger_position_reg_2_address_c : std_logic_vector(data_width_g * addr_d_g -1 downto 0) := conv_std_logic_vector(trigger_position_reg_2_address_g, data_width_g * addr_d_g);
constant clk_to_start_reg_3_address_c : std_logic_vector(data_width_g * addr_d_g -1 downto 0) := conv_std_logic_vector(clk_to_start_reg_3_address_g, data_width_g * addr_d_g);
constant enable_reg_4_address_c : std_logic_vector(data_width_g * addr_d_g -1 downto 0) := conv_std_logic_vector(enable_reg_address_4_g, data_width_g * addr_d_g);
--*****************************************************************************************************************************************************************--
---------- 	Types	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--

--*****************************************************************************************************************************************************************--
---------- SIGNALS	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
-- registers:
signal en_reg            : std_logic_vector (data_width_g-1 downto 0); -- enable data of led_1, led_2, led_3, led_4
signal trigger_type_reg_1				: std_logic_vector( data_width_g -1 downto 0 );					--type of trigger
signal trigger_position_reg_2        : std_logic_vector( data_width_g -1 downto 0 );					--the percentage of the data to send out
signal clk_to_start_reg_3        		: std_logic_vector( data_width_g -1 downto 0 ); 					-- count clk cycles since system start to work until trigger rise
signal enable_reg_4        			: std_logic_vector( data_width_g -1 downto 0 );					-- '0' system off, '1' we looking for a trigger rise

begin

--*****************************************************************************************************************************************************************--
---------- Processes	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
regs_outputs_proc:
en_out <= en_reg;
trigger_type_out_1 <= trigger_type_reg_1;
trigger_positionout_2 <= trigger_position_reg_2;
clk_to_start_out_3 <= clk_to_start_reg_3;
enable_out_4 <= enable_reg_4;

---------------------------------------------------- registers process ----------------------------------------------------------------------------------
en_reg_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
 		  		 en_reg <= (others => '0');
 		elsif rising_edge(sys_clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = en_reg_address_c) ) then
 		       en_reg <= data_in;
 		   else
 		     en_reg <= en_reg;
       end if; 			
    end if;
end process en_reg_proc;

trigger_type_reg_1_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
 		  		 trigger_type_reg_1 <= (others => '0');
 		elsif rising_edge(sys_clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = trigger_type_reg_1_address_c) ) then
 		       trigger_type_reg_1 <= data_in;
 		   else
 		     trigger_type_reg_1 <= trigger_type_reg_1;
       end if; 			
    end if;
end process freq_reg_1_proc;

trigger_position_reg_2_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
 		  		 trigger_position_reg_2 <= (others => '0');
 		elsif rising_edge(sys_clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = trigger_position_reg_2_address_c) ) then
 		       trigger_position_reg_2 <= data_in;
 		   else
 		     trigger_position_reg_2 <= trigger_position_reg_2;
       end if; 			
    end if;
end process freq_reg_2_proc;

clk_to_start_reg_3_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
 		  		 clk_to_start_reg_3 <= (others => '0');
 		elsif rising_edge(sys_clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = clk_to_start_reg_3_address_c) ) then
 		       clk_to_start_reg_3 <= data_in;
 		   else
 		     clk_to_start_reg_3 <= clk_to_start_reg_3;
       end if; 			
    end if;
end process freq_reg_3_proc;

enable_reg_4_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
 		  		 enable_reg_4 <= (others => '0');
 		elsif rising_edge(sys_clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = enable_reg_4_address_c) ) then
 		       enable_reg_4 <= data_in;
 		   else
 		     enable_reg_4 <= enable_reg_4;
       end if; 			
    end if;
end process freq_reg_4_proc;

---------------------------------------------------- read data process ----------------------------------------------------------------------------------

read_data_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
 		  		 data_out <= (others => '0');
 		  		 valid_data_out <= '0';
 		elsif rising_edge(sys_clk) then
 		   if ( (valid_in = '1') and (wr_en = '0') ) then -- the wishbone slaves requests to read
 		     if (address_in = en_reg_address_c)  then
 		       data_out <= en_reg;
 		       valid_data_out <= '1';
 		     elsif  (address_in = trigger_type_reg_1_address_c) then
 		       data_out <= trigger_type_reg_1;
 		       valid_data_out <= '1';
 		     elsif  (address_in = trigger_position_reg_2_address_c) then
 		       data_out <= trigger_position_reg_2;
 		       valid_data_out <= '1';
 		     elsif  (address_in = clk_to_start_reg_3_address_c) then
 		       data_out <= clk_to_start_reg_3;
 		       valid_data_out <= '1';
 		     elsif  (address_in = enable_reg_4_address_c) then
 		       data_out <= enable_reg_4;
 		       valid_data_out <= '1';
 		     else
 		       data_out <= ( others => '0');
 		       valid_data_out <= '0';
 		     end if;
 		   else
 		     data_out <= ( others => '0');
 		     valid_data_out <= '0';
       end if; 			
    end if;
end process read_data_proc;

end architecture behave;