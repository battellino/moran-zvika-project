------------------------------------------------------------------------------------------------
-- Model Name 	:	Core registers TB
-- File Name	:	Core_registers_tb.vhd
-- Generated	:	15.12.2010
-- Author		:	Beeri Schreiber and Alon Yavich
-- Project		:	RunLen Project
------------------------------------------------------------------------------------------------
-- Description: 
-- 		
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		15.12.2010	Beeri Schreiber					Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) Extend RAM to use input width > output width
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work ;
use work.write_controller_pkg.all;

entity core_registers_tb is
	generic (
				read_loop_iter_g	:	positive	:= 20;									--Number of iterations
				
			reset_polarity_g			   :	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			data_width_g           		   :	natural 	:= 8;         							-- the width of the data lines of the system    (width of bus)
			Add_width_g  		   		   :    positive 	:=  8;     								--width of addr word in the WB
--			en_reg_address_g      		   : 	natural :=0;
			trigger_type_reg_1_address_g 	   : 	natural :=1;
			trigger_position_reg_2_address_g : 	natural :=2;
			clk_to_start_reg_3_address_g 	   : 	natural :=3;
			enable_reg_address_4_g 		   : 	natural :=4									--num of signals that will be recorded simultaneously
			);
end entity core_registers_tb;

architecture arc_core_registers_tb of core_registers_tb is

component core_registers 
	 generic (
			reset_polarity_g			   :	std_logic	:=	'1';								--'1' reset active highe, '0' active low
			data_width_g           		   :	natural 	:= 8;         							-- the width of the data lines of the system    (width of bus)
			Add_width_g  		   		   :    positive 	:=  8;     								--width of addr word in the WB
--			en_reg_address_g      		   : 	natural :=0;
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
	 address_in        : in std_logic_vector (Add_width_g -1 downto 0); -- address line
	 wr_en             : in std_logic; -- write enable: '1' for write, '0' for read
	 data_in           : in std_logic_vector (data_width_g-1 downto 0); -- data sent from WS
     valid_in          : in std_logic; -- validity of the data directed from WS
     data_out          : out std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
     valid_data_out    : out std_logic; -- validity of data directed to WS
     -- core blocks interface
 --    en_out            : out std_logic_vector (data_width_g-1 downto 0); -- enable data sent to trigger pos, triiger type, clk to stars, enable
     trigger_type_out_1        : out std_logic_vector (data_width_g-1 downto 0); -- trigger type
     trigger_positionout_2        : out std_logic_vector (data_width_g-1 downto 0); -- trigger pos
     clk_to_start_out_3        : out std_logic_vector (data_width_g-1 downto 0); -- count cycles that passed since trigger rise
     enable_out_4        : out std_logic_vector (data_width_g-1 downto 0)  -- enable sent by yhe GUI
   	   );	
end component core_registers;

----------------------   Signals   ------------------------------


signal clk							: std_logic := '0'	;													--System clock
signal reset						: std_logic := '0'	;	
signal address_in        :  std_logic_vector (Add_width_g -1 downto 0)	:= (others => '0')	; -- address line												--System Reset
signal wr_en             :  std_logic	:= '1'	; 	--Input address
signal data_in           :  std_logic_vector (data_width_g-1 downto 0) := (others => '0')	; 		--Output address
signal valid_in          :  std_logic := '0'	;	
signal data_out          :  std_logic_vector (data_width_g-1 downto 0)	:= (others => '0')	;
signal valid_data_out    :  std_logic := '0'	;	--start and end addr of data needed to output. send to RC													--Output address is valid
signal trigger_type_out_1        :  std_logic_vector (data_width_g-1 downto 0) := (others => '0');		--sending the data + trigger to be saved in the RAM. trigger is data_in_RAM(0)
signal trigger_positionout_2        :  std_logic_vector (data_width_g-1 downto 0) := (others => '0');	
signal clk_to_start_out_3        :  std_logic_vector (data_width_g-1 downto 0) := (others => '0');		--the addr in the RAM to save the data
signal enable_out_4        :  std_logic_vector (data_width_g-1 downto 0) := (others => '0');	--send with the addr to the RC

-------------------  Implementation ----------------------------
begin

			
core_registers_inst : core_registers generic map (
											trigger_type_reg_1_address_g 	 =>	trigger_type_reg_1_address_g,
											trigger_position_reg_2_address_g	=>	trigger_position_reg_2_address_g,
											clk_to_start_reg_3_address_g	=>	clk_to_start_reg_3_address_g,
											enable_reg_address_4_g =>	enable_reg_address_4_g,
											reset_polarity_g	=>	reset_polarity_g,
											data_width_g        =>  data_width_g,         						    
											Add_width_g  		=>  Add_width_g        								
											
								)
						port map (
								clk			=> clk,
								reset		=> reset,				
								address_in      =>  address_in,
								wr_en           =>  wr_en,
								data_in         => data_in,
								valid_in        =>  valid_in,
								data_out        =>  data_out,
								valid_data_out  =>  valid_data_out,
								trigger_type_out_1	=> trigger_type_out_1,
								trigger_positionout_2 => trigger_positionout_2,
								clk_to_start_out_3 => clk_to_start_out_3,
								enable_out_4 => enable_out_4
								);

clk_proc : 
	clk <= not clk after 50 ps;
	
res_proc :
	reset <= reset_polarity_g, not reset_polarity_g after 130 ps;
	


	------
write_proc :
	wr_en <= '1', '0' after 1000 ps;

addr_proc :	
	address_in <= "00000000", "00000001" after 200 ps, "00000010" after 400 ps, "00000011" after 600 ps, "00000100" after 800 ps,
	"00000001" after 1000 ps, "00000010" after 1200 ps, "00000011" after 1400 ps, "00000100" after 1600 ps ;

valid_proc :	
	valid_in <= '1' ;
	
	data_proc : process 
	begin
		for idx in 0 to read_loop_iter_g  - 1 loop
			wait until rising_edge(clk);
			data_in 	<= std_logic_vector (to_unsigned(idx, data_width_g)); 	--Input data 
		end loop;
		wait ;
	end process data_proc;

end architecture arc_core_registers_tb;
