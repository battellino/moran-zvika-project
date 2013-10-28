-----------------------------------------------------------------------------------------------
-- Model Name 	:	Error Register
-- File Name	:	error_register.vhd
-- Generated	:	02.08.2011
-- Author		:	Dor Obstbaum and Kami Elbaz
-- Project		:	FPGA setting usiing FLASH project
------------------------------------------------------------------------------------------------
-- Description: 
-- The error register is made for allowing a host to recieve the error status .The unit samples an error signal vector  
-- When such an error signal recieves '1'(could be defined by generic) the data is saved in the error register. A signal named error_led_out will be directed to a led
-- when one of the error bits in the register is high. When data is read by the wishbone slave it is connected to, then the register 
-- will reset itself. 
-- The unit is addressed with the address 0 but could be changed by generic.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number 		Date	       	Name       			 	Description
--			1.0		   02.08.2011  	Dor Obstbaum	 		Creation
--		    1.1		   16.08.2011   Dor Obstbaum		    wr_en port added
--			1.2		   03.10.2012	Dor Obstbaum			code_version register added
------------------------------------------------------------------------------------------------
--	Todo:
--							
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use ieee.std_logic_misc.all;

entity error_register is
   generic (
     reset_activity_polarity_g  : std_logic :='1';    -- defines reset active polarity: '0' active low, '1' active high
     error_register_address_g    : natural :=0 ;       -- defines the address that should be sent on access to the unit
     data_width_g               : natural := 8 ;      -- defines the width of the data lines of the system
     address_width_g             : natural := 8;       -- defines the width of the address lines of the system
     led_active_polarity_g      : std_logic :='1';     -- defines the active state of the error signal input: '0' active low, '1' active high
     error_active_polarity_g    : std_logic :='1';     -- defines the polarity which the error signal is active in
	 code_version_g				: natural	:= 0	   -- Hardware code version
           );
   port
   	   (
     sys_clk           : in std_logic; --system clock
     sys_reset         : in std_logic; --system reset
     --error signals
     error_in          : in std_logic_vector (data_width_g-1 downto 0); 
     error_led_out     : out std_logic; -- '1' when one of the error bits in the register is high
     --wishbone slave comunication signals
     data_out          : out std_logic_vector (data_width_g-1 downto 0); -- data sent to WS
     valid_data_out    : out std_logic; -- validity of data directed to WS
     address_in        : in std_logic_vector (address_width_g-1 downto 0); -- address line. only "00000000" is recieved in the error_register because there is only one address.
     valid_in          : in std_logic; -- validity of the address directed from WS
     wr_en             : in std_logic  -- enables reading the error register
   	   );
end entity error_register;

architecture arc_error_register of error_register is

------------------  	Constants	-----------------
constant address_c : std_logic_vector(address_width_g-1 downto 0) := conv_std_logic_vector(error_register_address_g, address_width_g);
constant zero_c    : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
constant code_version_c : std_logic_vector(data_width_g-1 downto 0) := conv_std_logic_vector(code_version_g, data_width_g);
constant version_address_c : std_logic_vector(address_width_g-1 downto 0) := conv_std_logic_vector(error_register_address_g+1, address_width_g);
------------------  	Types		--------------------
------------------  SIGNALS --------------------
signal err_reg     : std_logic_vector (data_width_g-1 downto 0);
signal read_sig    : std_logic;
------------------------------------------------

begin
------------------	Processes	------------------ 
error_register_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
 		  	 err_reg <= (others => '0');
 		elsif rising_edge(sys_clk) then	
 		  if ( error_active_polarity_g = '1') then
        if (read_sig = '0') then
          err_reg <= err_reg or error_in;
		    elsif (read_sig = '1' and valid_in = '0') then
		      err_reg <= zero_c or error_in;
        end if;
 		  else
 	      if (read_sig = '0') then
          err_reg <= err_reg and error_in;
		    else
		      err_reg <= not(zero_c) and error_in;
        end if;
 		 end if; 
 	end if;
end process error_register_proc;

read_proc:  
process(sys_clk,sys_reset)
	begin
		if sys_reset = reset_activity_polarity_g then
 		  	 read_sig <= '0';
 		elsif rising_edge(sys_clk) then	
	    if ((address_in = address_c) and (valid_in = '1') and (wr_en = '0')) then
 		      read_sig <= '1';
 		    else
 		      read_sig <= '0';
        end if;
    end if;
end process read_proc;


ws_out_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
			valid_data_out  <= '0';
			data_out <= (others => '0');
 		elsif rising_edge(sys_clk) then	
 		if (address_in = address_c and valid_in = '1') then
          valid_data_out  <= '1';
		  data_out <= err_reg; 
		elsif (address_in = version_address_c and valid_in = '1') then
		  valid_data_out  <= '1';
		  data_out <= code_version_c; 
        else
          valid_data_out  <= '0';
		  data_out <= (others => '0');
        end if;
    end if;
end process ws_out_proc;

error_led_out_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
     error_led_out <= not(led_active_polarity_g);
 		elsif rising_edge(sys_clk) then
 		    if ( error_active_polarity_g = '1') then
 		       if ( or_reduce(err_reg) = '1') then	
 		          error_led_out <= led_active_polarity_g;
 		       else
 		          error_led_out <= not(led_active_polarity_g);
 		       end if;
 		    else
 		       if ( and_reduce(err_reg) = '0') then	
 		          error_led_out <= led_active_polarity_g;
 		       else
 		          error_led_out <= not(led_active_polarity_g);
 		       end if;
 		    end if;
    end if;
end process error_led_out_proc;

end architecture arc_error_register;
