-----------------------------------------------------------------------------------------------
-- Model Name 	: Led Registers
-- File Name	:	led_registers.vhd
-- Generated	:	15.08.2011
-- Author		:	Dor Obstbaum and Kami Elbaz
-- Project		:	FPGA setting using FLASH project
------------------------------------------------------------------------------------------------
-- Description: The Core Registers unit receives data from the wishbone slaves, samples it, and transmits it to the core blocks. 
--  			When reset is activated no register should be enabled. The register's addresses are defined by generics.
-- 				The unit contains four registers which are configed as follow: 
-- 				trigger_type_reg_1 		= trigger_type
-- 				trigger_position_reg_2 	= trigger_position
-- 				clk_to_start_reg_3 		= clk_to_start
-- 				enable_reg_4 			= enable 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number 		Date	       	Name       			 	Description
--			1.0		   04.1.2013  		zvika pery	 		Creation
--		    
--			
------------------------------------------------------------------------------------------------
--	Todo:
--			connect to wb_slave	
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity core_registers is
   generic (
			reset_polarity_g			   		:	std_logic	:= '1';								--'1' reset active high, '0' active low
			enable_polarity_g					:	std_logic	:= '1';								--'1' the entity is active, '0' entity not active
			data_width_g           		   		:	natural 	:= 8;         							-- the width of the data lines of the system    (width of bus)
			Add_width_g  		   		   		:   positive	:= 8;     								--width of address word in the WB
			en_reg_address_g      		   		: 	natural 	:= 0;
			trigger_type_reg_1_address_g 		: 	natural 	:= 1;
			trigger_position_reg_2_address_g	: 	natural 	:= 2;
			clk_to_start_reg_3_address_g 	   	: 	natural 	:= 3;
			enable_reg_address_4_g 		   		: 	natural 	:= 4
           );
   port
   	   (
     clk			  		 	: in std_logic; --system clock
     reset   		   			: in std_logic; --system reset
     -- wishbone slave interface
	 address_in       		 	: in std_logic_vector (Add_width_g -1 downto 0); 	-- address line
	 wr_en           		  	: in std_logic; 									-- write enable: '1' for write, '0' for read
	 data_in_reg      		 	: in std_logic_vector ( data_width_g - 1 downto 0); 	-- data sent from WS
     valid_in          			: in std_logic; 									-- validity of the data directed from WS
	 rc_finish					: in std_logic;										--  1 -> reset enable register
	 wc_finish					: in std_logic;										
     -- core blocks interface
     en_out            			: out std_logic ; 			-- enable data sent to trigger pos, triiger type, clk to stars, enable
     trigger_type_out_1        	: out std_logic_vector (6 downto 0); 	-- trigger type
     trigger_positionout_2      : out std_logic_vector (6 downto 0); 	-- trigger pos
     clk_to_start_out_3        	: out std_logic_vector (6 downto 0);	-- count cycles that passed since trigger rise
     enable_out_4        		: out std_logic								  		-- enable sent by the GUI
   	   );
end entity core_registers;

architecture behave of core_registers is

--*****************************************************************************************************************************************************************--
---------- Constants	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
constant en_reg_address_c     				: std_logic_vector(Add_width_g -1 downto 0) := conv_std_logic_vector(en_reg_address_g, Add_width_g);
constant trigger_type_reg_1_address_c 		: std_logic_vector(Add_width_g -1 downto 0)	:= conv_std_logic_vector(trigger_type_reg_1_address_g, Add_width_g);
constant trigger_position_reg_2_address_c 	: std_logic_vector(Add_width_g -1 downto 0)	:= conv_std_logic_vector(trigger_position_reg_2_address_g, Add_width_g);
constant clk_to_start_reg_3_address_c 		: std_logic_vector(Add_width_g -1 downto 0) := conv_std_logic_vector(clk_to_start_reg_3_address_g, Add_width_g);
constant enable_reg_4_address_c 			: std_logic_vector(Add_width_g -1 downto 0) := conv_std_logic_vector(enable_reg_address_4_g, Add_width_g);
constant register_size_c     				: integer range 0 to 7 := 7;
--*****************************************************************************************************************************************************************--
---------- 	Types	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--

--*****************************************************************************************************************************************************************--
---------- SIGNALS	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
-- registers:
signal en_reg            			: std_logic_vector( 6 downto 0 ); 	-- enable data of registers
signal trigger_type_reg_1			: std_logic_vector( 6 downto 0 );	--type of trigger
signal trigger_position_reg_2       : std_logic_vector( 6 downto 0 );	--determine from where we start to send data out to the user after we detect trigger rise
signal clk_to_start_reg_3        	: std_logic_vector( 6 downto 0 ); 	-- count clk cycles since system start to work until trigger rise
signal enable_reg_4        			: std_logic_vector( 6 downto 0 );	-- enable data to core

begin

--*****************************************************************************************************************************************************************--
---------- Processes	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--

regs_outputs_proc:
en_out 					<= en_reg(0);
trigger_type_out_1 		<= trigger_type_reg_1;
trigger_positionout_2 	<= trigger_position_reg_2;
clk_to_start_out_3 		<= clk_to_start_reg_3;
enable_out_4 			<= enable_reg_4(0);					--we take only the last bit of the word as the ENABLE signal

---------------------------------------------------- registers process ----------------------------------------------------------------------------------
en_reg_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
 		  		en_reg(0) <= not (enable_polarity_g);
				en_reg(6 downto 1) <= (others => '0');
 		elsif rising_edge(clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = en_reg_address_c) ) then
 		       en_reg <= data_in_reg(6 downto 0);
 		   elsif (wc_finish = '1' ) then
				en_reg(0) <= not (enable_polarity_g);
		   else
 		     en_reg <= en_reg;
      end if; 			
    end if;
end process en_reg_proc;

trigger_type_reg_1_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
 		  		 trigger_type_reg_1 <= (others => '0');
 		elsif rising_edge(clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = trigger_type_reg_1_address_c) ) then
				trigger_type_reg_1 <= data_in_reg(6 downto 0);
		   else
 		     trigger_type_reg_1 <= trigger_type_reg_1;
       end if; 			
    end if;
end process trigger_type_reg_1_proc;

trigger_position_reg_2_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
 		  		 trigger_position_reg_2 <= (others => '0');
 		elsif rising_edge(clk) then
			if ( (valid_in = '1') and (wr_en = '1') and (address_in = trigger_position_reg_2_address_c) ) then
				trigger_position_reg_2 <= data_in_reg(6 downto 0);
			else
 		     trigger_position_reg_2 <= trigger_position_reg_2;
			end if;
	   end if;
end process trigger_position_reg_2_proc;

clk_to_start_reg_3_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
 		  	clk_to_start_reg_3 <= (others => '0');
 		elsif rising_edge(clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = clk_to_start_reg_3_address_c) ) then
 		       clk_to_start_reg_3 <= data_in_reg(6 downto 0);
 		   else
 		     clk_to_start_reg_3 <= clk_to_start_reg_3;
       end if; 			
    end if;
end process clk_to_start_reg_3_proc;

enable_reg_4_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
 		  	enable_reg_4(0) <= not (enable_polarity_g);
			enable_reg_4(6 downto 1) <= (others => '0');
 		elsif rising_edge(clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = enable_reg_4_address_c) ) then
				enable_reg_4 <= data_in_reg(6 downto 0);
 		   elsif (rc_finish = '1' ) then
				enable_reg_4(0) <= not (enable_polarity_g);
		   else
 		     enable_reg_4 <= enable_reg_4;
       end if; 			
    end if;
end process enable_reg_4_proc;

end architecture behave;