-----------------------------------------------------------------------------------------------
-- Model Name 	:	Wishbone Slave
-- File Name	  :	WB_slave.vhd
-- Generated	  :	8.2.2011
-- Author	  	  : Kami Elbaz
-- Project		   :	FPGA setting usiing FLASH project
------------------------------------------------------------------------------------------------
-- Description: 
-- 
------------------------------------------------------------------------------------------------
--  Notes:
------------------------------------------------------------------------------------------------
-- Revision History:
--			Number 		Date	       	   Name       			 	Description
--			         3.8.2011        							     compilation done
--             4.8.2011       							      simulation	- write cycel DONE!!
--		           5.8.2011        						      simulation	- read cycel DONE!!
--      		     28/8/2011      							      to wb simulation
--			1.1		    08/01/2012			Dor Obstbaum			Error fix. reset_activity_polarity_g instead of '1' in stb_sample process
--			2.0		    24/09/2012			Dor Obstbaum			support pipeline mode (based on runlen project WS)	 	
--			2.1		    25/10/2012			Dor Obstbaum			typ and len ports added on registers side
------------------------------------------------------------------------------------------------
--	Todo: update typ and len ports in all units using WS
-----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;


entity wb_slave is
   generic (
     reset_activity_polarity_g  	: std_logic :='1';   -- defines reset active polarity: '0' active low, '1' active high
     data_width_g               	: natural   := 8;    -- defines the width of the data lines of the system    
	   addr_d_g			                	:	positive  := 3;		  -- Address Depth
	   len_d_g				                 :	positive  := 1;		  -- Length Depth
	   type_d_g				                :	positive  := 1	 	  -- Type Depth    
		   );	   
   port
   	   (
     sys_clk        : in std_logic;		 --system clock
     sys_reset      : in std_logic;		 --system reset    
	 --bus side signals
     ADR_I          : in std_logic_vector ((data_width_g)*(addr_d_g)-1 downto 0);	   -- contains the addr word
     DAT_I          : in std_logic_vector (data_width_g-1 downto 0); 	               -- contains the data_in word
     WE_I           : in std_logic;                     				                         -- '1' for write, '0' for read
     STB_I          : in std_logic;                     				                         -- '1' for active bus operation, '0' for no bus operation
     CYC_I          : in std_logic;                     				                         -- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I          : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	  -- contains the type word
     TGD_I          : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	   -- contains the len word
     ACK_O          : out std_logic;                      				                       -- '1' when valid data is transmited to MW or for successfull write operation 
     DAT_O          : out std_logic_vector (data_width_g-1 downto 0);   	            -- data transmit to MW
	   STALL_O		      : out std_logic;                                                 -- STALL - WS is not available for transaction 
	 --register side signals
     typ			         : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);   -- Type
	   addr	          : out std_logic_vector ((data_width_g)*(addr_d_g)-1 downto 0);   -- the beginnig address in the client that the information will be written to
	   len		         	: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);    -- Length
	   wr_en			       : out std_logic;
	   ws_data	       : out std_logic_vector (data_width_g-1 downto 0);                -- data out to registers
	   ws_data_valid	 : out std_logic;	                                                -- data valid to registers
	   reg_data       : in std_logic_vector (data_width_g-1 downto 0); 	               -- data to be transmited to the WM
     reg_data_valid : in std_logic;                                                  -- data to be transmited to the WM validity
	   active_cycle	  : out std_logic;                                                 -- CYC_I outputed to user side
	   stall			       : in std_logic                                                   -- stall - suspend wishbone transaction
	  );
end entity wb_slave;

architecture arc_wb_slave of wb_slave is

  ---------------------------------  Signals	----------------------------------
  signal cyc_active	:	std_logic;	--Whishbone cycle is active
  
  ---------------------------------  Implementation	------------------------------
begin
	
	--Cycle is in progress, and requesting for data (read / write)
	cyc_proc:
	cyc_active	<=	CYC_I and STB_I;
	
	--Type to registers
	type_proc:
	typ			<=	TGA_I;

	
	--Address to registers
	addr_proc:
	addr		<=	ADR_I;
	
	--Length to registers
	len 		<=	TGD_I;
	
	--Wishbone Slave data to registers
	ws_data_proc:
	ws_data		<=	DAT_I;
	
	--Wishbone Slave data valid to registers
	ws_data_valid_proc:
	ws_data_valid <= cyc_active and STB_I;
	
	--Input data to registers is valid
	wr_en_proc:
	wr_en	<=	cyc_active and WE_I;
	
	--Output data from register
	DAT_O_proc:
	DAT_O	<=	reg_data;
	
	--Stall command 
	stall_proc:
	STALL_O <= stall;
	
	--ACK_O
	ACK_O_proc:
	ACK_O	<=	reg_data_valid when ((CYC_I = '1') and (WE_I = '0'))	             -- ack data read from registers (Read)
					else (cyc_active and WE_I) when ((CYC_I = '1') and ((WE_I = '1')))	-- ack data written to registers (Write)
					else '0';
	--ACK_O	<=	(cyc_active and WE_I) when ((CYC_I = '1') and ((WE_I = '1')))	-- ack data written to registers (Write)
					--else '0';					  
	
	--active_cycle_proc:
	active_cycle <= CYC_I;
						
end architecture arc_wb_slave;
