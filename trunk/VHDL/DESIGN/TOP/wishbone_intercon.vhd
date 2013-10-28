-----------------------------------------------------------------------------------------------
-- Model Name 	: Wishbone Intercon 
-- File Name	  :	wishbone_intercon.vhd
-- Generated	  :	13.08.2011
-- Author		    :	Dor Obstbaum and Kami Elbaz
-- Project	   	:	FPGA setting usiing FLASH project
------------------------------------------------------------------------------------------------
-- Description:  The Wishbone Intercon Unit's role is to manage the wishbone communication in the system. 
-- The intercon has the following subunits:
-- 1- A wishbone master Arbiter that is implemented as a final state machine. The arbiter would let only one master to write on the bus.
-- 2- A Master signal router. This subunit will direct the master signals to the clients.
-- 3- A Slave signal router. This subunit will direct the operating slave signal to the right master that makes the transaction.
-- 4- A watchdog timer. If a transaction does not end within (clk_freq_g/watchdog_timer_freq_g) seconds the
--	   master that hold the bus is reset and the transaction ends.
------------------------------------------------------------------------------------------------
-- Revision:
--			Number 		Date	       	Name       			 	Description
--			1.0		   13.08.2011  	Dor Obstbaum	 		Creation
--		  1.1    	16.10.2011   Dor Obstbaum   	Insertion of the chosen_client signal (4 LSB bits of the TGA signal)
--			2.0		   24.09.2012	  Dor Obstbaum			 support pipeline mode. watchdog added.
--			2.1		   03.10.2012	  Dor Obstbaum		  watchdog_en_vector_g added
--			2.2		   05.11.2012	  Dor Obstbaum			 watchdog_en bug fixed
--    3.0     29.05.2013   Netanel Yamin   slave #1 listen to message types 1 AND 2 (changed from 1 only)
------------------------------------------------------------------------------------------------
--	Todo:
--							
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;


entity wishbone_intercon is
   generic (
    reset_activity_polarity_g  	: std_logic :='1';        			-- defines reset active polarity: '0' active low, '1' active high
    data_width_g               	: natural   := 8 ;              	-- defines the width of the data lines of the system
    type_d_g			       	: positive  := 1 ;		        	-- Type Depth
	Add_width_g  		    	: positive 	:=  8; 					--width of address word in the WB
    len_d_g				       	: positive  := 1 ;		        	-- Length Depth
	type_slave_1_g             	: std_logic_vector  := "0001";  	-- slave 1 type
    type_slave_2_g             	: std_logic_vector  := "0010";  	-- slave 2 type
    type_slave_3_g             	: std_logic_vector  := "0011";  	-- slave 3 type
    type_slave_4_g             	: std_logic_vector  := "0100";  	-- slave 4 type
    type_slave_5_g             : std_logic_vector  := "0101"; 	-- slave 5 type
    type_slave_6_g             : std_logic_vector  := "0110"; 	-- slave 6 type
    type_slave_7_g             : std_logic_vector  := "0111"; 	-- slave 7 type
	--timer generics
	watchdog_timer_freq_g    	: positive         :=100;       	-- timer tick after (clk_freq_g/watchdog_timer_freq_g) ==> 10msec
    clk_freq_g                 	: positive         :=100000000; 	-- the clock input to the block. this is the clock used in the system containing the timer unit. units: [Hz]
    timer_en_polarity_g        	: std_logic        :='1';       	-- defines the polarity which the timer enable (timer_en) is active on: '0' active low, '1' active high  
	watchdog_en_vector_g	   	: std_logic_vector := "11110111"	-- watchdog enabled for the clients which have '1' on their matching bit in the vector
           );
   port
   	   (
     sys_clk           : in std_logic; --system clock
     sys_reset         : in std_logic; --system reset
     --Wishbone Master 1 interfaces (rx_path)
     ADR_O_M1          : in std_logic_vector (Add_width_g-1 downto 0); --contains the addr word
     DAT_O_M1          : in std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
     WE_O_M1           : in std_logic;                     -- '1' for write, '0' for read
     STB_O_M1          : in std_logic;                     -- '1' for active bus operation, '0' for no bus operation
     CYC_O_M1          : in std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
     TGA_O_M1          : in std_logic_vector (type_d_g * data_width_g-1 downto 0); --contains the type word
     TGD_O_M1          : in std_logic_vector (len_d_g * data_width_g-1 downto 0); --contains the len word
     ACK_I_M1          : out std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
     DAT_I_M1          : out std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
	   STALL_I_M1		      : out std_logic; --STALL - WS is not available for transaction 
	   ERR_I_M1		        : out std_logic;  --Watchdog interrupts, resets wishbone master
    --Wishbone Master 2 interfaces  (tx_path)
     ADR_O_M2          : in std_logic_vector (Add_width_g-1 downto 0); --contains the addr word
     DAT_O_M2          : in std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
     WE_O_M2           : in std_logic;                     -- '1' for write, '0' for read
     STB_O_M2          : in std_logic;                     -- '1' for active bus operation, '0' for no bus operation
     CYC_O_M2          : in std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
     TGA_O_M2          : in std_logic_vector (type_d_g * data_width_g-1 downto 0); --contains the type word
     TGD_O_M2          : in std_logic_vector (len_d_g * data_width_g-1 downto 0); --contains the len word
     ACK_I_M2          : out std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
     DAT_I_M2          : out std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
	   STALL_I_M2		      : out std_logic; --STALL - WS is not available for transaction 
	   ERR_I_M2		        : out std_logic;  --Watchdog interrupts, resets wishbone master
     --Wishbone Master 3 interfaces (core)
     ADR_O_M3          : in std_logic_vector (Add_width_g-1 downto 0); --contains the addr word
     DAT_O_M3          : in std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
     WE_O_M3           : in std_logic;                     -- '1' for write, '0' for read
     STB_O_M3          : in std_logic;                     -- '1' for active bus operation, '0' for no bus operation
     CYC_O_M3          : in std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
     TGA_O_M3          : in std_logic_vector (type_d_g * data_width_g-1 downto 0); --contains the type word
     TGD_O_M3          : in std_logic_vector (len_d_g * data_width_g-1 downto 0); --contains the len word
     ACK_I_M3          : out std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
     DAT_I_M3          : out std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
  	  STALL_I_M3		      : out std_logic; --STALL - WS is not available for transaction 
	   ERR_I_M3		        : out std_logic;  --Watchdog interrupts, resets wishbone master
  	  --Wishbone Slave 1 interfaces (error_register - rx_path)
     ADR_I_S1          : out std_logic_vector (Add_width_g-1 downto 0);	--contains the address word
     DAT_I_S1          : out std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
     WE_I_S1           : out std_logic;                     				-- '1' for write, '0' for read
     STB_I_S1          : out std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
     CYC_I_S1          : out std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I_S1          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
     TGD_I_S1          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
     ACK_O_S1          : in std_logic;                      				--'1' when valid data is transmitted to MW or for successful write operation 
     DAT_O_S1          : in std_logic_vector (data_width_g-1 downto 0);   	--data transmit to MW
	   STALL_O_S1        : in std_logic; --STALL - WS is not available for transaction 
       	  --Wishbone Slave 2 interfaces (tx_path)
     ADR_I_S2          : out std_logic_vector (Add_width_g-1 downto 0);	--contains the addr word
     DAT_I_S2          : out std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
     WE_I_S2           : out std_logic;                     				-- '1' for write, '0' for read
     STB_I_S2          : out std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
     CYC_I_S2          : out std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I_S2          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
     TGD_I_S2          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
     ACK_O_S2          : in std_logic;                      				--'1' when valid data is transmitted to MW or for successful write operation 
     DAT_O_S2          : in std_logic_vector (data_width_g-1 downto 0);   	--data transmit to MW
   	 STALL_O_S2        : in std_logic; --STALL - WS is not available for transaction 
       	  --Wishbone Slave 3 interfaces (core)
     ADR_I_S3          : out std_logic_vector (Add_width_g-1 downto 0);	--contains the address word
     DAT_I_S3          : out std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
     WE_I_S3           : out std_logic;                     				-- '1' for write, '0' for read
     STB_I_S3          : out std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
     CYC_I_S3          : out std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I_S3          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
     TGD_I_S3          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
     ACK_O_S3          : in std_logic;                      				--'1' when valid data is transmitted to MW or for successful write operation 
     DAT_O_S3          : in std_logic_vector (data_width_g-1 downto 0);   	--data transmit to MW
	   STALL_O_S3        : in std_logic; --STALL - WS is not available for transaction 
       	  --Wishbone Slave 4 interfaces (signal generator)
     ADR_I_S4          : out std_logic_vector (Add_width_g-1 downto 0);	--contains the address word
     DAT_I_S4          : out std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
     WE_I_S4           : out std_logic;                     				-- '1' for write, '0' for read
     STB_I_S4          : out std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
     CYC_I_S4          : out std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I_S4          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
     TGD_I_S4          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the length word
     ACK_O_S4          : in std_logic;                      				--'1' when valid data is transmitted to MW or for successful write operation 
     DAT_O_S4          : in std_logic_vector (data_width_g-1 downto 0);   	--data transmit to MW
	   STALL_O_S4        : in std_logic; --STALL - WS is not available for transaction 
       	  --Wishbone Slave 5 interfaces (not in use)
     ADR_I_S5          : out std_logic_vector (Add_width_g-1 downto 0);	--contains the addr word
     DAT_I_S5          : out std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
     WE_I_S5           : out std_logic;                     				-- '1' for write, '0' for read
     STB_I_S5          : out std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
     CYC_I_S5          : out std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I_S5          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
     TGD_I_S5          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
     ACK_O_S5          : in std_logic;                      				--'1' when valid data is transmited to MW or for successfull write operation 
     DAT_O_S5          : in std_logic_vector (data_width_g-1 downto 0);   	--data transmit to MW
	   STALL_O_S5        : in std_logic; --STALL - WS is not available for transaction 
       	  --Wishbone Slave 6 interfaces (not in use)
     ADR_I_S6          : out std_logic_vector (Add_width_g-1 downto 0);	--contains the addr word
     DAT_I_S6          : out std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
     WE_I_S6           : out std_logic;                     				-- '1' for write, '0' for read
     STB_I_S6          : out std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
     CYC_I_S6          : out std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I_S6          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
	 TGD_I_S6          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
     ACK_O_S6          : in std_logic;                      				--'1' when valid data is transmited to MW or for successfull write operation 
     DAT_O_S6          : in std_logic_vector (data_width_g-1 downto 0);   	--data transmit to MW
	   STALL_O_S6        : in std_logic; --STALL - WS is not available for transaction 
       	  --Wishbone Slave 7 interface (not in use)
     ADR_I_S7          : out std_logic_vector (Add_width_g-1 downto 0);	--contains the addr word
     DAT_I_S7          : out std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
     WE_I_S7           : out std_logic;                     				-- '1' for write, '0' for read
     STB_I_S7          : out std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
     CYC_I_S7          : out std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I_S7          : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
     TGD_I_S7          : out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
     ACK_O_S7          : in std_logic;                      				--'1' when valid data is transmited to MW or for successfull write operation 
     DAT_O_S7          : in std_logic_vector (data_width_g-1 downto 0);  	--data transmit to MW
	   STALL_O_S7        : in std_logic --STALL - WS is not available for transaction 
   	   );
end entity wishbone_intercon;

architecture arc_wishbone_intercon of wishbone_intercon is
--*****************************************************************************************************************************************************************--
---------- Components	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--

component timer is
   generic (
     --timer generics:
     reset_activity_polarity_g  : std_logic :='1';       -- defines reset active polarity: '0' active low, '1' active high
     timer_freq_g               : positive  :=1000;      -- timer_tick will raise for 1 sys_clk period every timer_freq_g. units: [Hz]  
     clk_freq_g                 : positive  :=100000000; -- the clock input to the block. this is the clock used in the system containing the timer unit. units: [Hz]
     timer_en_polarity_g        : std_logic :='1'        -- defines the polarity which the timer enable (timer_en) is active on: '0' active low, '1' active high   
           );
   port
   	   (
     sys_clk       : in std_logic; --system clock
     sys_reset     : in std_logic; --system reset
     timer_en      : in std_logic; --determines if the timer is enabled
     timer_tick    : out std_logic --ticks every [tick_cycle_c] cycles    
   	   );
end component timer;

--*****************************************************************************************************************************************************************--
---------- 	Types	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
-- Arbiter State Machine
type intercon_states is (
					idle_st,		     -- no transaction is requested
					master_1_st,   -- master 1 is using the bus
					master_2_st,   -- master 2 is using the bus
					master_3_st    -- master 3 is using the bus
			 		);

--*****************************************************************************************************************************************************************--
---------- SIGNALS	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
--state machine signals:
signal intercon_state  : intercon_states;

--state machine outputs:
signal idle_st_en	    	: std_logic; 
signal master_1_st_en		: std_logic;
signal master_2_st_en		: std_logic; 
signal master_3_st_en	 	: std_logic;

--unit operation signals
signal adr_sig              :  std_logic_vector (Add_width_g-1 downto 0); --contains the addr word
signal dat_sig              :  std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
signal we_sig               :  std_logic;                     -- '1' for write, '0' for read
signal stb_sig              :  std_logic;                     -- '1' for active bus operation, '0' for no bus operation
signal cyc_sig              :  std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
signal tga_sig              :  std_logic_vector (type_d_g * data_width_g-1 downto 0); --contains the type word
signal tgd_sig              :  std_logic_vector (len_d_g * data_width_g-1 downto 0); --contains the len word
signal slave_ack_sig        :  std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
signal slave_dat_sig        :  std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
signal slave_en             :  std_logic_vector (7 downto 0); --enable the slaves to recieve CYC and STB signals from master when accessed to
signal chosen_client        :  std_logic_vector (3 downto 0); -- the chosen client will be picked by the 4 LSB bits of the TGA signal of the operating master
signal slave_stall_sig		:  std_logic; --STALL_I signal from the chosen slave
signal watchdog_interrupt  	:  std_logic; --watchdog resets a WM on a stuck transaction
signal watchdog_en		   	:  std_logic; --enables watchdog interrupt using the watchdog_en_vector_g and the chosen slave
signal watchdog_calc        :  std_logic_vector (7 downto 0); --a calculation signal for watchdog_en
	
begin

watchdog_timer_inst : timer 
   generic map (
     reset_activity_polarity_g  => reset_activity_polarity_g,
     timer_freq_g               => watchdog_timer_freq_g,
     clk_freq_g                 => clk_freq_g,
     timer_en_polarity_g        => timer_en_polarity_g
     )
   port map
   	   (
     sys_clk       => sys_clk,
     sys_reset     => sys_reset,
     timer_en      => cyc_sig,
     timer_tick    => watchdog_interrupt
   	   );
--*****************************************************************************************************************************************************************--
---------- Processes	------------------------------------------------------------------------------------------------------------------------------------------------
--*****************************************************************************************************************************************************************--
chosen_client_direction_proc: -- the chosen client will be picked by the 4 LSB bits of the TGA signal of the operating master. The 4 MSB bits should not be used here.
chosen_client <= tga_sig (3 downto 0);

---------------------------------------------------- Arbiter processes ----------------------------------------------------------------------------------------------
-- Arbiter - State Machine Implementation 
arbiter_state_machine_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
			intercon_state <= idle_st;	 
 		elsif rising_edge(sys_clk) then
	 		case intercon_state is  
				when idle_st =>	
				 	if ((CYC_O_M1 = '0') and (CYC_O_M2 = '0') and (CYC_O_M3 = '0')) then
						intercon_state 	<= idle_st;
					elsif CYC_O_M1 = '1' then
						intercon_state 	<= master_1_st;
					elsif CYC_O_M2 = '1' then
						intercon_state 	<= master_2_st;
					else 
						intercon_state 	<= master_3_st;
					end if;	 	
				when master_1_st =>
				  if ((CYC_O_M1 = '0') and (CYC_O_M2 = '0') and (CYC_O_M3 = '0')) then
						intercon_state 	<= idle_st;
					elsif (CYC_O_M1 = '1') then 
					  intercon_state 	<= master_1_st;
					else
					  intercon_state 	<= master_2_st;
					end if;
				when master_2_st =>
				  if ((CYC_O_M1 = '0') and (CYC_O_M2 = '0') and (CYC_O_M3 = '0')) then
						intercon_state 	<= idle_st;
					elsif (CYC_O_M2 = '1') then 
					  intercon_state 	<= master_2_st;
					else
					  intercon_state 	<= master_3_st;
					end if;
				when master_3_st =>
				  if ((CYC_O_M1 = '0') and (CYC_O_M2 = '0') and (CYC_O_M3 = '0')) then
						intercon_state 	<= idle_st;
					elsif (CYC_O_M3 = '1') then 
					  intercon_state 	<= master_3_st;
					else
					  intercon_state 	<= master_1_st;
					end if;
				end case;
			end if;
end process arbiter_state_machine_proc; 

arbiter_state_machine_outputs_proc:
idle_st_en				<= '1' when  intercon_state = idle_st	    else '0' ; 
master_1_st_en			<= '1' when  intercon_state = master_1_st  	else '0' ;
master_2_st_en		   	<= '1' when  intercon_state = master_2_st  	else '0' ;
master_3_st_en      	<= '1' when  intercon_state = master_3_st  	else '0' ;

---------------------------------------------------- Master signal router process ----------------------------------------------------------------------------------

master_signal_router_proc:
process(sys_clk,sys_reset)
	begin
 		if sys_reset = reset_activity_polarity_g then
 		 adr_sig       <= (others => '0');
     dat_sig       <= (others => '0');
     we_sig        <=  '0';
     stb_sig       <=  '0';
     cyc_sig       <=  '0';
     tga_sig       <= (others => '0');
     tgd_sig       <= (others => '0');
 		elsif rising_edge(sys_clk) then	
			if idle_st_en = '1' then	
			  adr_sig       <= (others => '0');
        dat_sig       <= (others => '0');
        we_sig        <= '0';
        stb_sig       <= '0';
        cyc_sig       <= '0';
        tga_sig       <= (others => '0');
        tgd_sig       <= (others => '0');
      elsif master_1_st_en = '1' then
        adr_sig       <= ADR_O_M1;
        dat_sig       <= DAT_O_M1;
        we_sig        <= WE_O_M1;
        stb_sig       <= STB_O_M1;
        cyc_sig       <= CYC_O_M1;
        tga_sig       <= TGA_O_M1;
        tgd_sig       <= TGD_O_M1;
      elsif master_2_st_en = '1' then
        adr_sig       <= ADR_O_M2;
        dat_sig       <= DAT_O_M2;
        we_sig        <= WE_O_M2;
        stb_sig       <= STB_O_M2;
        cyc_sig       <= CYC_O_M2;
        tga_sig       <= TGA_O_M2;
        tgd_sig       <= TGD_O_M2;
      else
        adr_sig       <= ADR_O_M3;
        dat_sig       <= DAT_O_M3;
        we_sig        <= WE_O_M3;
        stb_sig       <= STB_O_M3;
        cyc_sig       <= CYC_O_M3;
        tga_sig       <= TGA_O_M3;
        tgd_sig       <= TGD_O_M3;
 		  end if;
 		end if;
end process master_signal_router_proc ;  

-- the following processes direct the chosen master signals to all slaves. The right slave will respond by its TGA field (type field).
slave_1_out_proc:
ADR_I_S1 <= adr_sig;       
DAT_I_S1 <= dat_sig;    
WE_I_S1  <= we_sig ;       
STB_I_S1 <= stb_sig and slave_en(1);     
CYC_I_S1 <= cyc_sig and slave_en(1);       
TGA_I_S1 <= tga_sig;      
TGD_I_S1 <= tgd_sig;  
         
slave_2_out_proc:
ADR_I_S2 <= adr_sig;       
DAT_I_S2 <= dat_sig;    
WE_I_S2  <= we_sig ;       
STB_I_S2 <= stb_sig and slave_en(2);     
CYC_I_S2 <= cyc_sig and slave_en(2);       
TGA_I_S2 <= tga_sig;      
TGD_I_S2 <= tgd_sig; 

slave_3_out_proc:
ADR_I_S3 <= adr_sig;       
DAT_I_S3 <= dat_sig;    
WE_I_S3  <= we_sig ;       
STB_I_S3 <= stb_sig and slave_en(3);     
CYC_I_S3 <= cyc_sig and slave_en(3);       
TGA_I_S3 <= tga_sig;      
TGD_I_S3 <= tgd_sig;          

slave_4_out_proc:
ADR_I_S4 <= adr_sig;       
DAT_I_S4 <= dat_sig;    
WE_I_S4  <= we_sig ;       
STB_I_S4 <= stb_sig and slave_en(4);     
CYC_I_S4 <= cyc_sig and slave_en(4);       
TGA_I_S4 <= tga_sig;      
TGD_I_S4 <= tgd_sig; 

slave_5_out_proc:
ADR_I_S5 <= adr_sig;       
DAT_I_S5 <= dat_sig;    
WE_I_S5  <= we_sig ;       
STB_I_S5 <= stb_sig and slave_en(5);     
CYC_I_S5 <= cyc_sig and slave_en(5);       
TGA_I_S5 <= tga_sig;      
TGD_I_S5 <= tgd_sig; 

slave_6_out_proc:
ADR_I_S6 <= adr_sig;       
DAT_I_S6 <= dat_sig;    
WE_I_S6  <= we_sig ;       
STB_I_S6 <= stb_sig and slave_en(6);     
CYC_I_S6 <= cyc_sig and slave_en(6);       
TGA_I_S6 <= tga_sig;      
TGD_I_S6 <= tgd_sig; 

slave_7_out_proc:
ADR_I_S7 <= adr_sig;       
DAT_I_S7 <= dat_sig;    
WE_I_S7  <= we_sig ;       
STB_I_S7 <= stb_sig and slave_en(7);     
CYC_I_S7 <= cyc_sig and slave_en(7);       
TGA_I_S7 <= tga_sig;      
TGD_I_S7 <= tgd_sig; 
----------------------------------------------------Slave signal router processes-----------------------------------------------------------------------------------

-- This process directs the chosen slave signal to the master. this is a mux therefore not a synchronic process.
-- The control signal of the mux is tga_sig which contains the type data - the slave that is being accessed.
slave_signal_router_mux_proc:
process(chosen_client, ACK_O_S1, DAT_O_S1, ACK_O_S2, DAT_O_S2, ACK_O_S3, DAT_O_S3, ACK_O_S4, DAT_O_S4, ACK_O_S5,
		DAT_O_S5, ACK_O_S6, DAT_O_S6, ACK_O_S7, DAT_O_S7, STALL_O_S1, STALL_O_S2, STALL_O_S3, STALL_O_S4, STALL_O_S5
		, STALL_O_S6, STALL_O_S7)
	begin
		if ( (chosen_client = type_slave_1_g) or (chosen_client = type_slave_2_g) or(chosen_client = type_slave_3_g) or (chosen_client = type_slave_4_g) ) then -- S1 or S2 or S4
			if  (chosen_client = type_slave_1_g) or (chosen_client = type_slave_2_g) then -- S1 or S2
	     
 ---------------------- ADAPTION TO INPUT MEMORY BLOCK NEW LINES -----------	     
--				slave_ack_sig   <= ACK_O_S1; -- messages TYPE 1 or 2 routes to slave #1 
--				slave_dat_sig   <= DAT_O_S1;
--				slave_stall_sig <= STALL_O_S1;
--				slave_en        <= "00000010";
          
 ---------------------- ORIGINAL CODE --------------------------------------
 
				if chosen_client = type_slave_1_g then -- S1
					slave_ack_sig <= ACK_O_S1;
					slave_dat_sig <= DAT_O_S1;
					slave_stall_sig <= STALL_O_S1;
					slave_en <= "00000010";
				else -- S2
					slave_ack_sig <= ACK_O_S2;
					slave_dat_sig <= DAT_O_S2;
					slave_stall_sig <= STALL_O_S2;
					slave_en <= "00000100";
				end if;
 ---------------------------------------------------------------------------
			else -- TYP3 3 OR 4 
				if chosen_client = type_slave_3_g then -- S3
					slave_ack_sig   <= ACK_O_S3; -- messages TYPE 3 routes to slave #3 (TX PATH slave) 
					slave_dat_sig   <= DAT_O_S3;
					slave_stall_sig <= STALL_O_S3;
					slave_en <= "00001000";  -- slave 3
				-----------------------CHANGED FROM S2 TO S4------------------------------
				else -- TYPE 4 DIRECTS DATA FROM SLAVE 2 (OUTPUT BLOCK)
					slave_ack_sig <= ACK_O_S4;    -- messages TYPE 4 routes to slave #2 (output block slave)
					slave_dat_sig <= DAT_O_S4;
					slave_stall_sig <= STALL_O_S4;
					slave_en <= "00010000";  -- slave 4 
				end if;
			end if;       
	    else --S5 or S6 or S7 or no slave			(for us - NO SLAVE!!)
	    	if  (chosen_client = type_slave_5_g) or (chosen_client = type_slave_6_g) then -- S5 or S6
		    	if chosen_client = type_slave_5_g then -- S5
		       		slave_ack_sig <= ACK_O_S5;
					slave_dat_sig <= DAT_O_S5;
					slave_stall_sig <= STALL_O_S5;
	            	slave_en <= "00100000";
	         	else -- S6
					slave_ack_sig <= ACK_O_S6;
					slave_dat_sig <= DAT_O_S6;
			   		slave_stall_sig <= STALL_O_S6;
					slave_en <= "01000000";
	         	end if;
	   	else -- S7 or no slave
	         	if chosen_client = type_slave_7_g then -- S7
			        slave_ack_sig <= ACK_O_S7;
					slave_dat_sig <= DAT_O_S7;
					slave_stall_sig <= STALL_O_S7;
					slave_en <= "10000000";
				else -- no slave
					slave_ack_sig <= '0';
					slave_dat_sig <= (others => '0');
					slave_stall_sig <= '0';
					slave_en <= "00000000";
         		end if;
	    end if; 	      
	end if; 
end process slave_signal_router_mux_proc ;

watchdog_calc <= watchdog_en_vector_g and slave_en;
watchdog_en <= '0' when watchdog_calc = "00000000" else '1';

-- slave signal sent to master: only the chosen master receives the ACK_I sign. the others receives '0' until the end of the cycle
master_1_out_proc:
ACK_I_M1   <= slave_ack_sig and master_1_st_en;     
DAT_I_M1   <= slave_dat_sig;        
STALL_I_M1 <= (slave_stall_sig or not(master_1_st_en)) and not(idle_st_en) ;
ERR_I_M1   <= '1' when (master_1_st_en='1') and (watchdog_interrupt='1') and (watchdog_en = '1') else '0';

master_2_out_proc:
ACK_I_M2   <= slave_ack_sig and master_2_st_en;     
DAT_I_M2   <= slave_dat_sig;
STALL_I_M2 <= (slave_stall_sig or not(master_2_st_en)) and not(idle_st_en);
ERR_I_M2   <= '1' when (master_2_st_en='1') and (watchdog_interrupt='1') and (watchdog_en = '1') else '0';

master_3_out_proc:
ACK_I_M3   <= slave_ack_sig and master_3_st_en;     
DAT_I_M3   <= slave_dat_sig;
STALL_I_M3 <= (slave_stall_sig or not(master_3_st_en)) and not(idle_st_en);
ERR_I_M3   <= '1' when (master_3_st_en='1') and (watchdog_interrupt='1') and (watchdog_en = '1') else '0';

end architecture arc_wishbone_intercon;