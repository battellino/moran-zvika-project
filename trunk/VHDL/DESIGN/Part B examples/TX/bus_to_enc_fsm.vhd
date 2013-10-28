------------------------------------------------------------------------------------------------
-- Model Name 	:	BUS to encoder final state machine
-- File Name	:	bus_to_enc_fsm.vhd
-- Generated	:	01.11.2012	
-- Author		:	Dor Obstbaum and Kami Elbaz
-- Project		:	FPGA setting using FLASH project
------------------------------------------------------------------------------------------------
-- Description: The unit is an interface between a Wishbone Bus and the message pack encoder.
-- Once a read request has arrived from WS, the unit asks the WM to read data from the requested
-- client on the bus. WM writes the data to RAM. when data reading is finished the unit asserts
-- the reg_ready signal for the message pack encoder to start reading data from RAM.
------------------------------------------------------------------------------------------------
-- Revision :
--			Number		 Date		        Name		                    Description
--			1.0			 23.10.2012			Dor Obstbaum					Creation
------------------------------------------------------------------------------------------------
--	Todo: 
------------------------------------------------------------------------------------------------


library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


entity bus_to_enc_fsm is
generic	(
  	reset_polarity_g	: std_logic := '0';		--reset active polarity		
	data_width_g		: natural	:=8;		
	addr_d_g			: positive := 3;		--Address Depth
	len_d_g				: positive := 1;		--Length Depth
	type_d_g			: positive := 1;		--Type Depth 
	addr_bits_g			: positive := 8	--Depth of data in RAM	(2^8 = 256 addresses) 
 );
port (
	clk				: in std_logic; 		--system clock
	reset   	  	: in std_logic;		 	--system reset
	--Wishbone Slave interface
	typ				: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); -- Type
	addr	        : in std_logic_vector ((data_width_g)*(addr_d_g)-1 downto 0);    --the beginnig address in the client that the information will be written to
	ws_data	    	: in std_logic_vector (data_width_g-1 downto 0);    --data out to registers
	ws_data_valid	: in std_logic;	-- data valid to registers
	active_cycle	: in std_logic; --CYC_I outputed to user side
	stall			: out std_logic; -- stall - suspend wishbone transaction
	--Wishbone Master interface
	wm_start		: out std_logic;	--when '1' WM starts a transaction
	wr				: out std_logic;                      --determines if the WM will make a read('0') or write('1') transaction
	type_in			: out std_logic_vector (type_d_g * data_width_g-1 downto 0);  --type is the client which the data is directed to
    len_in			: out std_logic_vector (len_d_g * data_width_g-1 downto 0);  --length of the data (in words)
    addr_in			: out std_logic_vector (addr_d_g * data_width_g-1 downto 0);  --the address in the client that the information will be written to
	ram_start_addr	: out std_logic_vector (addr_bits_g-1 downto 0); -- start address for WM to read from RAM
    wm_end			: in std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
	--Message Pack Encoder interface
	reg_ready		: out std_logic; 											--Registers are ready for reading. MP Encoder can start transmitting
	type_mp_enc		: out std_logic_vector (data_width_g * type_d_g - 1 downto 0);	--Type register
	addr_mp_enc		: out std_logic_vector (data_width_g * addr_d_g - 1 downto 0);	--Address register
	len_mp_enc		: out std_logic_vector (data_width_g * len_d_g - 1 downto 0);	--Length Register
    mp_done			: in std_logic											--Message Pack has been transmitted
);
end entity bus_to_enc_fsm ;

architecture arc_bus_to_enc_fsm of bus_to_enc_fsm is

--##################################################################################################--
--#######################                Signals                             #######################--
--##################################################################################################--
--State Machine
type fsm_states is (
	idle_st,			-- no action 
	ws_read_req_st,		-- read request arrived form wishbone slave
	wm_read_st,			-- wishbone master does a read transaction
	sending_packet_st	-- a wait stait while a packet is being sent on uart tx 
);
		
signal fsm_state	        : fsm_states; --FSM current state
-- FSM enable signals:
signal idle_st_en 			: std_logic;
signal ws_read_req_st_en 	: std_logic;
signal wm_read_st_en 		: std_logic;
signal sending_packet_st_en : std_logic;
signal ws_read_req_st_en_sample : std_logic;

--registers
signal type_reg 	:std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);
signal addr_reg		:std_logic_vector ((data_width_g)*(addr_d_g)-1 downto 0) ; 
signal len_reg		:std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0) ; 

--others
signal active_cycle_sample	:std_logic; --sample of the active_cycle signal
begin
--##################################################################################################--
--#######################                Processes                          #######################--
--##################################################################################################--
-------------------------------------------------------------------
----------------------	state_machine_proc	-----------------------
-------------------------------------------------------------------
state_machine_proc:
process(clk,reset)
	begin
 		if reset = reset_polarity_g then
			fsm_state <= idle_st;	 
 		elsif rising_edge(clk) then
	 		case fsm_state is  
				when idle_st =>	
				 	if (active_cycle = '1' and ws_data_valid = '1') then
						fsm_state 	<= ws_read_req_st;
					else
						fsm_state 	<= idle_st;
					end if;	 	
				
				when ws_read_req_st =>
					fsm_state <= wm_read_st;
					
				when wm_read_st =>
					if (wm_end = '1') then
						fsm_state <= sending_packet_st;
					else
						fsm_state <= wm_read_st;
					end if;
					
				when sending_packet_st =>
					if (mp_done = '1') then
						if (active_cycle = '1') then
							fsm_state 	<= ws_read_req_st;
						else
							fsm_state 	<= idle_st;
						end if;	 	
					else
						fsm_state <= sending_packet_st;
					end if;
				
				when others => --this should never happen
					fsm_state <= idle_st;	
			end case;
		end if;
end process state_machine_proc; 

-------------------------------------------------------------------
----------------------	fsm_enable_signals_proc	-------------------
-------------------------------------------------------------------
fsm_enable_signals_proc:
idle_st_en	    		<= '1' when  fsm_state = idle_st			else '0' ; 
ws_read_req_st_en	    <= '1' when  fsm_state = ws_read_req_st		else '0' ; 
wm_read_st_en	    	<= '1' when  fsm_state = wm_read_st			else '0' ; 
sending_packet_st_en	<= '1' when  fsm_state = sending_packet_st	else '0' ; 

-------------------------------------------------------------------
----------------------	registers_proc			-------------------
--registers are sampled on active_cycle rising edge
-------------------------------------------------------------------
registers_proc:  process (clk, reset)
begin
	if (reset = reset_polarity_g) then
		type_reg	<= (others => '0');	
		addr_reg	<= (others => '0');	
		len_reg		<= (others => '0');	
	elsif rising_edge(clk) then
		if(idle_st_en = '1' ) then --or ws_read_req_st_en = '1') then
		  if (active_cycle_sample = '0' and active_cycle = '1') then 
			  type_reg(2 downto 0)	<= typ((data_width_g)*(type_d_g)-1 downto (data_width_g)*(type_d_g)-3 );	
			  addr_reg				<= addr;	
			  len_reg					<= ws_data;
		  end if;	
		end if;
	end if;
end process registers_proc;

-------------------------------------------------------------------
----------------------	st_en_sample_proc		-------------------
-------------------------------------------------------------------
st_en_sample_proc:  process (clk, reset)
begin
	if (reset = reset_polarity_g) then
		ws_read_req_st_en_sample	<= '0';
		active_cycle_sample			<= '0';
	elsif rising_edge(clk) then
		ws_read_req_st_en_sample	<= ws_read_req_st_en;
		active_cycle_sample			<= active_cycle;
	end if;
end process st_en_sample_proc;

-------------------------------------------------------------------
----------------------	wm_ws_proc					-------------------
-------------------------------------------------------------------
wm_ws_proc:
wm_start	<= '1' when ws_read_req_st_en_sample='1' and wm_read_st_en = '1' else '0';
wr			<= '0';		
type_in		<= "00000100"; -- type 4 --type_reg;
addr_in		<= (others => '0');--addr_reg;
len_in		<= len_reg;
ram_start_addr	<= (others => '0');
stall		<=	wm_read_st_en or sending_packet_st_en;

-------------------------------------------------------------------
----------------------	mp_enc_proc				-------------------
-------------------------------------------------------------------
mp_enc_proc:
reg_ready 	<= wm_end;
type_mp_enc	<= type_reg;
addr_mp_enc	<= addr_reg;
len_mp_enc	<= len_reg;

end architecture arc_bus_to_enc_fsm;