-----------------------------------------------------------------------------------------------
-- Model Name 	: Wishbone Master (WM)
-- File Name	  :	wishbone_master.vhd
-- Generated	  :	29.07.2011
-- Author		    :	Dor Obstbaum and Kami Elbaz
-- Project		   :	FPGA setting usiing FLASH project
------------------------------------------------------------------------------------------------
-- Description: 
-- The Wishbone Master (WM) aims to connect the system's units to the wishbone bus. The WM communicates with
-- Wishbone Slaves (WS) via Wishbone Intercon unit. The WM writes data to units connected via WS or reads data from it.
-- The WM can be used by several units in the system but only one WM at a time can write on the bus. 
-- The wishbone mode supported is pipline mode defined in the Wishbone B4 spec.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number 		Date	       	Name       			   	Description
--			1.0			29.07.2011  	 Dor Obstbaum	 	 	Creation
--			2.0			23.09.2012		  Dor Obstbaum			  support pipeline mode
------------------------------------------------------------------------------------------------
--	Todo:
--							
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity wishbone_master is
   generic (
    reset_activity_polarity_g  : std_logic :='1';      -- defines reset active polarity: '0' active low, '1' active high
    data_width_g               : natural := 8 ;        -- defines the width of the data lines of the system
    type_d_g			                :	positive := 1;	      	-- Type Depth
	  addr_d_g			                :	positive := 3;		      -- Address Depth
	  len_d_g			                	:	positive := 1;		      -- Length Depth
	  addr_bits_g			            	:	positive := 8	        -- Depth of data in RAM	(2^8 = 256 addresses)
           );
   port
   	   (
	 
    sys_clk			     : in std_logic; --system clock
    sys_reset     	: in std_logic; --system reset   
	--control unit signals
	  wm_start		     : in std_logic;	--when '1' WM starts a transaction
	  wr				         : in std_logic;                      --determines if the WM will make a read('0') or write('1') transaction
	  type_in			     : in std_logic_vector (type_d_g * data_width_g-1 downto 0);  --type is the client which the data is directed to
    len_in			      : in std_logic_vector (len_d_g * data_width_g-1 downto 0);  --length of the data (in words)
    addr_in			     : in std_logic_vector (addr_d_g * data_width_g-1 downto 0);  --the address in the client that the information will be written to
	  ram_start_addr	: in std_logic_vector (addr_bits_g-1 downto 0); -- start address for WM to read from RAM
    wm_end		 	     : out std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
	--RAM signals
	  ram_addr		     :	out std_logic_vector (addr_bits_g - 1 downto 0);--RAM Input address
	  ram_dout	     	:	out std_logic_vector (data_width_g - 1 downto 0);	--RAM Input data
	  ram_dout_valid	:	out std_logic; 									--RAM Input data valid
	  ram_aout		     :	out std_logic_vector (addr_bits_g - 1 downto 0);--RAM Output address
	  ram_aout_valid	:	out std_logic;									--RAM Output address is valid
	  ram_din			     :	in std_logic_vector (data_width_g - 1 downto 0);	--RAM Output data
	  ram_din_valid	 :	in std_logic; 									--RAM Output data valid
	--bus side signals
    ADR_O			       : out std_logic_vector (addr_d_g * data_width_g-1 downto 0); --contains the addr word
    DAT_O			       : out std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
    WE_O		 	       : out std_logic;                     -- '1' for write, '0' for read
    STB_O			       : out std_logic;                     -- '1' for active bus operation, '0' for no bus operation
    CYC_O			       : out std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
    TGA_O			       : out std_logic_vector (type_d_g * data_width_g-1 downto 0); --contains the type word
    TGD_O			       : out std_logic_vector (len_d_g * data_width_g-1 downto 0); --contains the len word
    ACK_I			       : in std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
    DAT_I			       : in std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
	  STALL_I	       : in std_logic; --STALL - WS is not available for transaction 
	  ERR_I			       : in std_logic  --Watchdog interrupts, resets wishbone master
   	);
end entity wishbone_master;

architecture arc_wishbone_master of wishbone_master is

--##################################################################################################--
--#######################                Constants                           #######################--
--##################################################################################################--
constant ram_size_c     : natural  := 2**addr_bits_g ; --Size of RAM
--##################################################################################################--
--#######################                Types                               #######################--
--##################################################################################################--
--State Machine
type wm_states is (
					idle_st,		-- no transaction is requested
					initiate_st,	-- start of transaction: type,addr,len signals are sampled to registers
			 		write_st,		-- write state: WM transmits the data on the wishbone bus and waits for ACK
					stall_wr_st,	-- wait while slave is unavailable for a write transaction
					get_acks_wr_st,	-- recieve remaining acks on a write transaction
					read_st,		-- read state: data is read from WS via wishbone bus, waiting for ACK
					stall_rd_st,	-- wait while slave is unavailable for a read transaction
					get_acks_rd_st	-- recieve remaining acks on a read transaction
				);

--##################################################################################################--
--#######################                Signals                             #######################--
--##################################################################################################--
--state machine signals:
signal wm_state         : wm_states;

--state machine outputs:
signal	idle_st_en			: std_logic; 
signal	initiate_st_en		: std_logic;
signal	write_st_en			: std_logic;
signal	stall_wr_st_en		: std_logic;
signal	get_acks_wr_st_en	: std_logic;
signal 	read_st_en			: std_logic;
signal 	stall_rd_st_en		: std_logic;
signal 	get_acks_rd_st_en	: std_logic;

--state machine outputs samples:
signal get_acks_wr_st_sample		: std_logic;
signal get_acks_rd_st_sample		: std_logic;

--register signals
signal type_reg : std_logic_vector (type_d_g * data_width_g-1 downto 0);
signal addr_reg : natural range 0 to 2**(addr_d_g*data_width_g);
signal len_reg  : std_logic_vector (len_d_g * data_width_g-1 downto 0);
signal len_cnt 	: natural range 0 to 2**(len_d_g*data_width_g);
signal ack_cnt	: natural range 0 to 2**(len_d_g*data_width_g);
signal addr_rd	: natural range 0 to 2**(addr_bits_g);
signal ram_addr_sig : natural range 0 to 2**(addr_d_g*data_width_g);
signal len_reg_int	: natural range 0 to 2**(len_d_g*data_width_g);

--other signals
signal wr_sig	: std_logic; --samples the wr input when wm_start assertion

begin 
--##################################################################################################--
--#######################                Processes                             #######################--
--##################################################################################################--   

-------------------------------------------------------------------
----------------------	state_machine_proc	-----------------------
-------------------------------------------------------------------
wishbone_master_state_machine_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
			wm_state <= idle_st;	 
 		elsif rising_edge(sys_clk) then
			if (ERR_I = '1') then
				wm_state <= idle_st;
			else
				case wm_state is  
					when idle_st =>	
						if (wm_start = '0') then
							wm_state 	<= idle_st;
						else
							wm_state 	<= initiate_st;
						end if;	 	
					when initiate_st =>
						if (wr_sig = '0' and STALL_I = '0') then --determines if the state machine enters read mode or write mode
							wm_state <=  read_st; 
						elsif (wr_sig = '0' and STALL_I = '1') then
							wm_state <=  stall_rd_st; 
						elsif (wr_sig = '1' and STALL_I = '0') then
							wm_state <= write_st;
						else --(wr_sig = '1' and STALL_I = '1')
							wm_state <= stall_wr_st;
						end if;			  
	--state machine write states
					when write_st =>
						if (STALL_I = '1') then
							wm_state <= stall_wr_st;
						elsif (len_cnt = len_reg_int) then
							wm_state <= get_acks_wr_st;
						else
							wm_state <= write_st;
						end if;
					when stall_wr_st =>
						if (STALL_I = '1') then
							wm_state <= stall_wr_st;
						else
							wm_state <= write_st;
						end if;
					when get_acks_wr_st =>
						if (ack_cnt = len_reg_int+1) then
							wm_state <= idle_st;
						else
							wm_state <= get_acks_wr_st;
						end if;
	--state machine read states
					when read_st =>
						if (STALL_I = '1') then
							wm_state <= stall_rd_st;
						elsif (len_cnt = len_reg_int) then
							wm_state <= get_acks_rd_st;
						else
							wm_state <= read_st;
						end if;
					when stall_rd_st =>
						if (STALL_I = '1') then
							wm_state <= stall_rd_st;
						else
							wm_state <= read_st;
						end if;
					when get_acks_rd_st =>
						if (ack_cnt = len_reg_int+1) then
							wm_state <= idle_st;
						else
							wm_state <= get_acks_rd_st;
						end if;
				end case;
			end if;
		end if;
end process wishbone_master_state_machine_proc; 

-------------------------------------------------------------------
---------------	State Machine Outputs process	-------------------
-------------------------------------------------------------------
wishbone_master_state_machine_outputs_proc:
idle_st_en			<= '1' when  wm_state = idle_st			else '0' ; 
initiate_st_en		<= '1' when  wm_state = initiate_st	else '0' ;
write_st_en			<= '1' when  wm_state = write_st		else '0' ;	
stall_wr_st_en		<= '1' when  wm_state = stall_wr_st		else '0' ;	
get_acks_wr_st_en	<= '1' when  wm_state = get_acks_wr_st	else '0' ;	
read_st_en			<= '1' when  wm_state = read_st			else '0' ;	
stall_rd_st_en		<= '1' when  wm_state = stall_rd_st		else '0' ;	
get_acks_rd_st_en	<= '1' when  wm_state = get_acks_rd_st	else '0' ;	

-------------------------------------------------------------------
-------------------	Wishbone outputs process	-------------------
-------------------------------------------------------------------
ADR_O_proc:
ADR_O <= conv_std_logic_vector(addr_reg,addr_d_g * data_width_g);


DAT_O_proc:
DAT_O <= ram_din;

WE_O_proc:
WE_O <= write_st_en  ;		

STB_O_proc:
STB_O <= initiate_st_en or write_st_en or stall_wr_st_en or read_st_en or  stall_rd_st_en ;		

CYC_O_proc:
CYC_O <= initiate_st_en or write_st_en or stall_wr_st_en or get_acks_wr_st_en or read_st_en or  stall_rd_st_en or get_acks_rd_st_en;
  
TGA_O_proc:
TGA_O <= type_reg;

TGD_O_proc:
TGD_O <= len_reg;

-------------------------------------------------------------------
-------------------	type,addr,len registers process	---------------
-------------------------------------------------------------------  
registers_proc:
  process(sys_clk,sys_reset)
    begin
      if sys_reset = reset_activity_polarity_g then
        type_reg <= (others => '0');
        addr_reg <= 0;
        len_reg  <= (others => '0');
      elsif rising_edge(sys_clk) then
        if ( (idle_st_en = '1') and (wm_start = '1') ) then
          type_reg <= type_in;
          addr_reg <= conv_integer(UNSIGNED(addr_in));
          len_reg  <= len_in;
		  wr_sig   <= wr;
        elsif ( write_st_en = '1' ) then
		  addr_reg <= addr_reg + 1;
		elsif ( read_st_en = '1') then
		  addr_reg <= addr_reg + 1;
		else
		  type_reg <= type_reg;
		  addr_reg <= addr_reg;
		  len_reg  <= len_reg;
		  wr_sig   <= wr_sig;
        end if;
      end if;
end process registers_proc;
 
-------------------------------------------------------------------
-------------------	ram_addr_sig process	---------------
-------------------------------------------------------------------  
 ram_addr_sig_proc:
  process(sys_clk,sys_reset)
    begin
      if sys_reset = reset_activity_polarity_g then
		ram_addr_sig <= 0;
      elsif rising_edge(sys_clk) then
        if ( (idle_st_en = '1') and (wm_start = '1') ) then
		  ram_addr_sig <= conv_integer(UNSIGNED(ram_start_addr));
        elsif ( write_st_en = '1' or (stall_wr_st_en = '1' and STALL_I = '0' ) or initiate_st_en = '1' ) then
			if (len_cnt = len_reg_int or STALL_I = '1') then
				ram_addr_sig <= ram_addr_sig;
			else
				ram_addr_sig <= ram_addr_sig + 1;
			end if;
		else
		  ram_addr_sig <= ram_addr_sig;
        end if;
      end if;
end process ram_addr_sig_proc;

-------------------------------------------------------------------
-------------------	RAM interface process	-----------------------
------------------------------------------------------------------- 
ram_proc:
ram_addr	<= conv_std_logic_vector(addr_rd,addr_bits_g);
ram_dout	<= DAT_I;
ram_dout_valid	<= ACK_I and (read_st_en or stall_rd_st_en or get_acks_rd_st_en);
ram_aout	<= conv_std_logic_vector(ram_addr_sig,addr_bits_g);
ram_aout_valid	<=  '1' when ((initiate_st_en = '1' and wr_sig = '1') or write_st_en = '1' or stall_wr_st_en = '1' ) else '0';

-------------------------------------------------------------------
-------------------	length counter process	-----------------------
-------------------------------------------------------------------
len_cnt_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
			len_cnt	<= 0 ;	
 		elsif rising_edge(sys_clk) then	
			if (idle_st_en = '1') then
				len_cnt <= 0;
			elsif (write_st_en='1' or read_st_en='1') then
				len_cnt <= len_cnt + 1;
			else
				len_cnt <= len_cnt;
			end if;
 		end if ;
end process len_cnt_proc; 

-------------------------------------------------------------------
-------------------	ack counter process	---------------------------
-------------------------------------------------------------------
ack_cnt_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
			ack_cnt	<= 0 ;	
 		elsif rising_edge(sys_clk) then	
			if (idle_st_en = '1') then
				ack_cnt <= 0;
			elsif (ACK_I = '1') then
				ack_cnt <= ack_cnt + 1;
			else
				ack_cnt <= ack_cnt;
			end if;
 		end if ;
end process ack_cnt_proc;

-------------------------------------------------------------------
-------------------	addr_rd process	---------------------------
-------------------------------------------------------------------
addr_rd_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
			addr_rd	<= 0 ;	
 		elsif rising_edge(sys_clk) then	
			if (idle_st_en = '1') then
				addr_rd <= 0;
			elsif (initiate_st_en = '1') then
				addr_rd	<= conv_integer(UNSIGNED(ram_start_addr));
			elsif (ACK_I = '1') then
				if (addr_rd = ram_size_c-1) then
					addr_rd <= 0;
				else
					addr_rd <= addr_rd + 1;
				end if;
			end if;
 		end if ;
end process addr_rd_proc;

-------------------------------------------------------------------
-------------------	Sample process	-------------------------------
-------------------------------------------------------------------
sample_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
			get_acks_wr_st_sample	<= '0' ;	
			get_acks_rd_st_sample	<= '0' ;
 		elsif rising_edge(sys_clk) then	
			get_acks_wr_st_sample	<= get_acks_wr_st_en ;	
			get_acks_rd_st_sample	<= get_acks_rd_st_en ;
 		end if ;
end process sample_proc ; 

-------------------------------------------------------------------
-------------------	wm_end process	-------------------------------
------------------------------------------------------------------- 
wm_end_proc:
wm_end <= idle_st_en and (get_acks_wr_st_sample or get_acks_rd_st_sample);

-------------------------------------------------------------------
-------------------	len_reg_int_proc	-------------------------------
------------------------------------------------------------------- 
len_reg_int_proc:
len_reg_int <= conv_integer(UNSIGNED(len_reg));
  
end architecture arc_wishbone_master;