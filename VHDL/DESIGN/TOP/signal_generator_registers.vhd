-----------------------------------------------------------------------------------------------
-- Model Name 	: Signal Generator Registers
-- File Name	:	signal_generator_registers.vhd
-- Generated	:	14.10.2013
-- Author		:	zvika pery and moran katz
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: The Signal Generator Registers unit receives data from the wishbone slaves, samples it, and transmits it to the signal generator blocks. 
--  			When reset is activated no register should be enabled. The register's addresses are defined by generics.
-- 				The unit contains two registers which are configed as follow: 
-- 				scene_number_reg_1 		= scene number
-- 				enable_reg_2 			= enable the generator 
------------------------------------------------------------------------------------------------
-- Revision:
--			Number 		Date	       	Name       			 	Description
--			1.00	   	14.10.2013 		zvika pery	 			Creation
--		    1.01		08.12.2013		zvika pery	 			Reading from registers
--			
------------------------------------------------------------------------------------------------
--	Todo:
--			
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity signal_generator_registers is
   generic (
			reset_polarity_g			   		:	std_logic	:= '1';								--'1' reset active high, '0' active low
			enable_polarity_g					:	std_logic	:= '1';								--'1' the entity is active, '0' entity not active
			data_width_g           		   		:	natural 	:= 8;         							-- the width of the data lines of the system    (width of bus)
			Add_width_g  		   		   		:   positive	:= 8;     								--width of address word in the WB
			scene_number_reg_1_address_g 		: 	natural 	:= 1;
			enable_reg_address_2_g 		   		: 	natural 	:= 2
           );
   port
   	   (
     clk			  		 	: in std_logic; --system clock
     reset   		   			: in std_logic; --system reset
     -- wishbone slave interface
	 address_in       		 	: in std_logic_vector (Add_width_g -1 downto 0); 	-- address line
	 wr_en           		  	: in std_logic; 									-- write enable: '1' for write, '0' for read
	 data_in_reg      		 	: in std_logic_vector ( data_width_g - 1 downto 0); -- data sent from WS
     valid_in          			: in std_logic; 									-- validity of the data directed from WS								
     data_out          			: out std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
     valid_data_out    			: out std_logic; -- validity of data directed to WS
	 rc_finish					: in std_logic;										--  1 -> reset enable register
	 -- core blocks interface
     scene_number_out_1        	: out std_logic_vector (6 downto 0); 				-- scene number
     enable_out_2        		: out std_logic								  		-- enable sent by the GUI
   	   );
end entity signal_generator_registers;

architecture behave of signal_generator_registers is

--*****************************************************************************************************************************************************************--
---------- Constants	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
--constant en_reg_address_c     				: std_logic_vector(Add_width_g -1 downto 0) := conv_std_logic_vector(en_reg_address_g, Add_width_g);
constant scene_number_reg_1_address_c 		: std_logic_vector(Add_width_g -1 downto 0)	:= conv_std_logic_vector(scene_number_reg_1_address_g, Add_width_g);
constant enable_reg_2_address_c 			: std_logic_vector(Add_width_g -1 downto 0)	:= conv_std_logic_vector(enable_reg_address_2_g, Add_width_g);
constant register_size_c     				: integer range 0 to 7 := 7;
constant next_last_address_c				: std_logic_vector(Add_width_g -1 downto 0) := conv_std_logic_vector(enable_reg_address_2_g + 1, Add_width_g);
--*****************************************************************************************************************************************************************--
---------- 	Types	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--

--*****************************************************************************************************************************************************************--
---------- SIGNALS	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
-- registers:
signal scene_number_reg_1			: std_logic_vector( 6 downto 0 );	--scene_number
signal enable_reg_2        			: std_logic_vector( 6 downto 0 );	-- enable signal generator

begin

--*****************************************************************************************************************************************************************--
---------- Processes	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--

regs_outputs_proc:
scene_number_out_1 		<= scene_number_reg_1;
enable_out_2 			<= enable_reg_2(0);					--we take only the last bit of the word as the ENABLE signal

---------------------------------------------------- registers process ----------------------------------------------------------------------------------

scene_number_reg_1_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
 		  		 scene_number_reg_1 <= (others => '0');
 		elsif rising_edge(clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = scene_number_reg_1_address_c) ) then
				scene_number_reg_1 <= data_in_reg(6 downto 0);
		   else
				scene_number_reg_1 <= scene_number_reg_1;
       end if; 			
    end if;
end process scene_number_reg_1_proc;

enable_reg_2_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
 		  	enable_reg_2(0) <= not (enable_polarity_g);
			enable_reg_2(6 downto 1) <= (others => '0');
 		elsif rising_edge(clk) then
 		   if ( (valid_in = '1') and (wr_en = '1') and (address_in = enable_reg_2_address_c) ) then
				enable_reg_2 <= data_in_reg(6 downto 0);
		   elsif (rc_finish = '1' ) then
				enable_reg_2(0) <= not (enable_polarity_g);
		   else
				enable_reg_2 <= enable_reg_2;
       end if; 			
    end if;
end process enable_reg_2_proc;

---------------------------------------------------- read data process ----------------------------------------------------------------------------------

read_data_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
 		  	data_out <= (others => '0');
 		  	valid_data_out <= '0';
 		elsif rising_edge(clk) then
			if ( (valid_in = '1') and (wr_en = '0') ) then -- the wishbone slaves requests to read
				if (address_in = scene_number_reg_1_address_c)  then
					data_out(register_size_c - 1 downto 0) <= scene_number_reg_1;
					data_out(data_width_g - 1 downto register_size_c) <= (others => '0');
					valid_data_out <= '1';
				elsif  (address_in = enable_reg_2_address_c) then
					data_out(register_size_c - 1 downto 0) <= enable_reg_2;
					data_out(data_width_g - 1 downto register_size_c) <= (others => '0');
					valid_data_out <= '1';
				elsif  (address_in = next_last_address_c) then
					data_out <= (others => '0');
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