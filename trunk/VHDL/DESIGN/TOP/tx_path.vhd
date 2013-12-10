-----------------------------------------------------------------------------------------------
-- Model Name 	:	Tx Path
-- File Name	:	TX_path.vhd
-- Generated	:	31.7.2011
-- Author		:   Dor Obstbaum and Kami Elbaz
-- Project		:	FPGA setting usiing FLASH project
------------------------------------------------------------------------------------------------
-- Description: 
-- 
------------------------------------------------------------------------------------------------
--  Notes:
--
--
------------------------------------------------------------------------------------------------
-- Revision History:
--			Number 		Date	       	Name       			 	Description
--		    1.0	        02.08.2011		Kami Elbaz				Creation	
--			1.1			01.08.2012		Dor Obstbaum			Error Fix. Changed CRC port map.
--			2.0			01.11.2012		Dor Obstbaum			Upgrade unit to pipleline mode
------------------------------------------------------------------------------------------------
--	Todo:
--			ALL GANARICS 
------------------------------------------------------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity tx_path is 
generic (
	reset_polarity_g		: std_logic := '1'; 	--'0' = Active Low, '1' = Active High
	data_width_g	   		: natural	:=8;	
	Add_width_g    			:   positive := 8;		--width of addr word in the WB
    len_d_g					: positive := 1;		--Length Depth
    type_d_g				: positive := 1;		--Type Depth 
	fifo_d_g				: positive	:= 9;	-- Maximum elements in FIFO
	addr_bits_g		    	: positive 	:= 8;	--Depth of data	(2^10 = 1024 addresses)    
	parity_en_g				: natural	range 0 to 1 := 1; 		--Enable parity bit = 1, parity disabled = 0
	parity_odd_g			: boolean 	:= false;			--TRUE = odd, FALSE = even
	uart_idle_g				: std_logic 	:= '1';				--Idle line value
	baudrate_g				: positive	:= 115200;			--UART baudrate [Hz]
	clkrate_g				: positive	:= 100000000;		--Sys. clock [Hz]
	databits_g				: natural range 5 to 8 := 8		--Number of databits
);			
port   (
	sys_clk  			 : in std_logic; 		    --system clock
	sys_reset     		 : in std_logic;		 	--system reset
	
	----input and output to SLAVE TX from master RX
	DAT_I_S					:in std_logic_vector (data_width_g-1 downto 0) ; 
	ADR_I_S_TX				:in std_logic_vector (Add_width_g-1 downto 0) ; 
	TGA_I_S_TX				:in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0) ; 	--TYPE
	TGD_I_S_TX				:in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0) ; 			--LEN
	WE_I_S_TX				:in std_logic;
	STB_I_S_TX				:in std_logic;
	CYC_I_S_TX				:in std_logic;
	ACK_O_TO_M				:out std_logic;
	DAT_O_TO_M				:out std_logic_vector (data_width_g-1 downto 0) ;
	STALL_O_TO_M			:out std_logic;
	
	----input and output to MASTER TX from client slavr
	DAT_I_CLIENT			:in std_logic_vector (data_width_g-1 downto 0) ; 
	ACK_I_CLIENT			:in std_logic;
	STALL_I_CLIENT			:in std_logic;
	ERR_I_CLIENT			:in std_logic;
	ADR_O_CLIENT 			: out std_logic_vector (Add_width_g-1 downto 0) ;        
    DAT_O_CLIENT          	: out std_logic_vector (data_width_g-1 downto 0) ;
    WE_O_CLIENT           	: out std_logic;
    STB_O_CLIENT          	: out std_logic;
    CYC_O_CLIENT          	: out std_logic;
    TGA_O_CLIENT          	: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0) ;
    TGD_O_CLIENT			: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0) ;
	
	uart_out		    	: out std_logic
);
		 
end entity tx_path;


architecture arc_tx_path of tx_path is
------------------  	Types		-----------------

------------------ Components ------------------------
	
------------------ WTME Components ------------------------	
component bus_to_enc_fsm is
generic	(
  	reset_polarity_g	: std_logic := '0';		--reset active polarity		
	data_width_g		: natural	:=8;		
	Add_width_g    		: positive := 8;		--width of addr word in the WB
	len_d_g				: positive := 1;		--Length Depth
	type_d_g			: positive := 1;		--Type Depth 
	addr_bits_g			: positive := 8	--Depth of data in RAM	(2^8 = 256 addresses) 
 );
port (
	clk				: in std_logic; 		--system clock
	reset   	  	: in std_logic;		 	--system reset
	--Wishbone Slave interface
	typ				: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); -- Type
	addr	        : in std_logic_vector (Add_width_g-1 downto 0);    --the beginnig address in the client that the information will be written to
	ws_data	    	: in std_logic_vector (data_width_g-1 downto 0);    --data out to registers
	ws_data_valid	: in std_logic;	-- data valid to registers
	active_cycle	: in std_logic; --CYC_I outputed to user side
	stall			: out std_logic; -- stall - suspend wishbone transaction
	--Wishbone Master interface
	wm_start		: out std_logic;	--when '1' WM starts a transaction
	wr				: out std_logic;                      --determines if the WM will make a read('0') or write('1') transaction
	type_in			: out std_logic_vector (type_d_g * data_width_g-1 downto 0);  --type is the client which the data is directed to
    len_in			: out std_logic_vector (len_d_g * data_width_g-1 downto 0);  --length of the data (in words)
    addr_in			: out std_logic_vector (Add_width_g-1 downto 0);  --the address in the client that the information will be written to
	ram_start_addr	: out std_logic_vector (addr_bits_g-1 downto 0); -- start address for WM to read from RAM
    wm_end			: in std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
	--Message Pack Encoder interface
	reg_ready		: out std_logic; 											--Registers are ready for reading. MP Encoder can start transmitting
	type_mp_enc		: out std_logic_vector (data_width_g * type_d_g - 1 downto 0);	--Type register
	addr_mp_enc		: out std_logic_vector (Add_width_g - 1 downto 0);	--Address register
	len_mp_enc		: out std_logic_vector (data_width_g * len_d_g - 1 downto 0);	--Length Register
    mp_done			: in std_logic											--Message Pack has been transmitted
);
end component bus_to_enc_fsm ;

------------------mp_enc Components ------------------------	
	component mp_enc
		generic (
		reset_polarity_g	:	std_logic := '0'; 	--'0' = Active Low, '1' = Active High
		len_dec1_g			:	boolean := true;	--TRUE - Recieved length is decreased by 1 ,to save 1 bit
													--FALSE - Recieved length is the actual length
		sof_d_g				:	positive := 1;		--SOF Depth
		type_d_g			:	positive := 1;		--Type Depth
		Add_width_g	    	:   positive := 8;		--width of addr word in the WB
		len_d_g				:	positive := 1;		--Length Depth*   
		crc_d_g				:	positive := 1;		--CRC Depth
		eof_d_g				:	positive := 1;		--EOF Depth		
		sof_val_g			:	natural := 60;		--* (3C -  hex) SOF block value. Upper block is MSB
		eof_val_g			:	natural := 165;		--* (5A -  hex) EOF block value. Upper block is MSB		
		width_g				:	positive := 8		--Data Width (UART = 8 bits)    
		
				);
				
		port	(

		clk			:	in std_logic; 											--Clock
		rst			:	in std_logic; 											--Reset
		fifo_full	:	in std_logic;											--When '0' - Can receive data, When '1' - FIFO Full
		mp_done		:	out std_logic;											--Message Pack has been transmitted
		dout		:	out std_logic_vector (width_g - 1 downto 0); 			--Output data
		dout_valid	:	out std_logic;											--Output data is valid .Goes to 'write_en' of FIFO		
		reg_ready	:	in std_logic; 											--Registers are ready for reading. MP Encoder can start transmitting
		type_reg	:	in std_logic_vector (width_g * type_d_g - 1 downto 0);	--Type register
		addr_reg	:	in std_logic_vector (Add_width_g - 1 downto 0);	--Address register
		len_reg		:	in std_logic_vector (width_g * len_d_g - 1 downto 0);	--Length Register
		
		data_crc_val:	out std_logic; 											--'1' when new data for CRC is valid, '0' otherwise
		data_crc	:	out std_logic_vector (width_g - 1 downto 0); 			--Data to be calculated by CRC
		reset_crc	:	out std_logic; 											--'1' to reset CRC value
		req_crc		:	out std_logic; 											--'1' to request for current caluclated CRC
		crc_in		:	in std_logic_vector (width_g * crc_d_g -1 downto 0); 	--CRC value
		crc_in_val	:	in std_logic;  											--'1' when CRC is valid

		din			:	in std_logic_vector (width_g - 1 downto 0); 			--Input from RAM
		din_valid	:	in std_logic;											--Data from RAM is valid
		read_addr_en:	out std_logic;											--Output RAM address is valid
		read_addr	:	out std_logic_vector (width_g * len_d_g - 1 downto 0) 	--RAM Address

				);
				
	end component mp_enc;
	
------------------uart_tx Components ------------------------	
	component uart_tx
		generic (
		parity_en_g		:		natural	range 0 to 1 := 1; 		--Enable parity bit = 1, parity disabled = 0
		parity_odd_g		:		boolean 	:= false;			--TRUE = odd, FALSE = even
		uart_idle_g		:		std_logic 	:= '1';				--Idle line value
		baudrate_g			:		positive	:= 115200;			--UART baudrate [Hz]
		clkrate_g			:		positive	:= 133000000;		--Sys. clock [Hz]
		databits_g			:		natural range 5 to 8 := 8;		--Number of databits
		reset_polarity_g	:		std_logic	:= '0'	
				);
				
		port	(
		din					:	in std_logic_vector (databits_g -1 downto 0);		--Parallel data in
		clk					:	in std_logic;						--Sys. clock
		reset				:	in std_logic;						--Reset
		fifo_empty			:	in std_logic;						--FIFO is not empty
		fifo_din_valid		:   in std_logic;						--FIFO Ready to transmitte new data to tx
		fifo_rd_en			:	out std_logic;						--Controls FIFO rd_en 
		dout				:	out std_logic			
				);
	end component uart_tx;
	
------------------ram_simple Constants	-----------------
	component ram_simple
		generic (
		reset_polarity_g	:	std_logic 	:= '0';	--'0' - Active Low Reset, '1' Active High Reset
		width_in_g			:	positive 	:= 8;	--Width of data
		addr_bits_g			:	positive 	:= 10	--Depth of data	(2^10 = 1024 addresses)	
	 
				);
				
		port	(
		clk			:	in std_logic;									--System clock
		rst			:	in std_logic;									--System Reset
		addr_in		:	in std_logic_vector (addr_bits_g - 1 downto 0); --Input address
		addr_out	:	in std_logic_vector (addr_bits_g - 1 downto 0); --Output address
		aout_valid	:	in std_logic;									--Output address is valid
		data_in		:	in std_logic_vector (width_in_g - 1 downto 0);	--Input data
		din_valid	:	in std_logic; 									--Input data valid
		data_out	:	out std_logic_vector (width_in_g - 1 downto 0);	--Output data
		dout_valid	:	out std_logic  
				);
	end component ram_simple;

------------------crc_gen Constants	-----------------
component crc_gen IS 
   generic (
     reset_activity_polarity_g  : std_logic :='0'   -- defines reset active polarity: '0' active low, '1' active high
           );
   PORT(           
           clock      : IN  STD_LOGIC; 
           reset      : IN  STD_LOGIC; 
           soc        : IN  STD_LOGIC; 
           data       : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); 
           data_valid : IN  STD_LOGIC; 
           eoc        : IN  STD_LOGIC; 
           crc        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
           crc_valid  : OUT STD_LOGIC 
       );
END component crc_gen; 

	
------------------general_fifo Constants	-----------------
	component general_fifo
		generic (
     	reset_polarity_g	: std_logic	:= '0';	-- Reset Polarity
		width_g				: positive	:= 8; 	-- Width of data
		depth_g 			: positive	:= 9;	-- Maximum elements in FIFO
		log_depth_g			: natural	:= 4;	-- Logarithm of depth_g (Number of bits to represent depth_g. 2^4=16 > 9)
		almost_full_g		: positive	:= 8; 	-- Rise almost full flag at this number of elements in FIFO
		almost_empty_g		: positive	:= 1 	-- Rise almost empty flag at this number of elements in FIFO

				);
				
		port	(
		 clk 		: in 	std_logic;									-- Clock
		 rst 		: in 	std_logic;                                  -- Reset
		 din 		: in 	std_logic_vector (width_g-1 downto 0);      -- Input Data
		 wr_en 		: in 	std_logic;                                  -- Write Enable
		 rd_en 		: in 	std_logic;                                  -- Read Enable (request for data)
		 flush		: in	std_logic;									-- Flush data
		 dout 		: out 	std_logic_vector (width_g-1 downto 0);	    -- Output Data
		 dout_valid	: out 	std_logic;                                  -- Output data is valid
		 afull  	: out 	std_logic;                                  -- FIFO is almost full
		 full 		: out 	std_logic;	                                -- FIFO is full
		 aempty 	: out 	std_logic;                                  -- FIFO is almost empty
		 empty 		: out 	std_logic;                                  -- FIFO is empty
		 used 		: out 	std_logic_vector (log_depth_g  downto 0) 	-- Current number of elements is FIFO. Note the range. In case depth_g is 2^x, then the extra bit will be used
	   
				);
	end component general_fifo;

------------------wishbone Slave Constants	-----------------
component wishbone_slave is
   generic (
     reset_activity_polarity_g  	:std_logic :='1';      -- defines reset active polarity: '0' active low, '1' active high
     data_width_g               	: natural := 8;         -- defines the width of the data lines of the system    
	 Add_width_g    				:   positive := 8;		--width of addr word in the WB
	 len_d_g						:	positive := 1;		--Length Depth
	 type_d_g						:	positive := 6		--Type Depth 
		   );	   
   port
   	   (
     clk        	: in std_logic;		 --system clock
     reset		 	: in std_logic;		 --system reset    
	 --bus side signals
     ADR_I          : in std_logic_vector (Add_width_g-1 downto 0);	--contains the addr word
     DAT_I          : in std_logic_vector (data_width_g-1 downto 0); 	--contains the data_in word
     WE_I           : in std_logic;                     				-- '1' for write, '0' for read
     STB_I          : in std_logic;                     				-- '1' for active bus operation, '0' for no bus operation
     CYC_I          : in std_logic;                     				-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I          : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
     TGD_I          : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
     ACK_O          : out std_logic;                      				--'1' when valid data is transmited to MW or for successfull write operation 
     DAT_O          : out std_logic_vector (data_width_g-1 downto 0);   	--data transmit to MW
	 STALL_O		: out std_logic; --STALL - WS is not available for transaction 
	 --register side signals
     typ			: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); -- Type
	 addr	        : out std_logic_vector (Add_width_g-1 downto 0);    --the beginnig address in the client that the information will be written to
	 len			: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);    --Length
	 wr_en			: out std_logic;
	 ws_data	    : out std_logic_vector (data_width_g-1 downto 0);    --data out to registers
	 ws_data_valid	: out std_logic;	-- data valid to registers
	 reg_data       : in std_logic_vector (data_width_g-1 downto 0); 	 --data to be transmited to the WM
     reg_data_valid : in std_logic;   --data to be transmited to the WM validity
	 active_cycle	: out std_logic; --CYC_I outputed to user side
	 stall			: in std_logic -- stall - suspend wishbone transaction
	  );
end component wishbone_slave;

------------------wishbone master Constants	-----------------

component wishbone_master is
   generic (
    reset_activity_polarity_g  	: 	std_logic :='1';      -- defines reset active polarity: '0' active low, '1' active high
    data_width_g               	: 	natural := 8 ;        -- defines the width of the data lines of the system
    type_d_g					:	positive := 1;		--Type Depth
	Add_width_g 				:   positive := 8;		--width of addr word in the WB
	len_d_g						:	positive := 1;		--Length Depth
	addr_bits_g					:	positive := 8	--Depth of data in RAM	(2^8 = 256 addresses)
           );
   port
   	   (
	 
    sys_clk			: in std_logic; --system clock
    sys_reset		: in std_logic; --system reset   
	--control unit signals
	wm_start		: in std_logic;	--when '1' WM starts a transaction
	wr				: in std_logic;                      --determines if the WM will make a read('0') or write('1') transaction
	type_in			: in std_logic_vector (type_d_g * data_width_g-1 downto 0);  --type is the client which the data is directed to
    len_in			: in std_logic_vector (len_d_g * data_width_g-1 downto 0);  --length of the data (in words)
    addr_in			: in std_logic_vector (Add_width_g-1 downto 0);  --the address in the client that the information will be written to
	ram_start_addr	: in std_logic_vector (addr_bits_g-1 downto 0); -- start address for WM to read from RAM
    wm_end			: out std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
	--RAM signals
	ram_addr		:	out std_logic_vector (addr_bits_g - 1 downto 0);--RAM Input address
	ram_dout		:	out std_logic_vector (data_width_g - 1 downto 0);	--RAM Input data
	ram_dout_valid	:	out std_logic; 									--RAM Input data valid
	ram_aout		:	out std_logic_vector (addr_bits_g - 1 downto 0);--RAM Output address
	ram_aout_valid	:	out std_logic;									--RAM Output address is valid
	ram_din			:	in std_logic_vector (data_width_g - 1 downto 0);	--RAM Output data
	ram_din_valid	:	in std_logic; 									--RAM Output data valid
	--bus side signals
    ADR_O			: out std_logic_vector (Add_width_g-1 downto 0); --contains the addr word
    DAT_O			: out std_logic_vector (data_width_g-1 downto 0); --contains the data_in word
    WE_O			: out std_logic;                     -- '1' for write, '0' for read
    STB_O			: out std_logic;                     -- '1' for active bus operation, '0' for no bus operation
    CYC_O			: out std_logic;                     -- '1' for bus transmition request, '0' for no bus transmition request
    TGA_O			: out std_logic_vector (type_d_g * data_width_g-1 downto 0); --contains the type word
    TGD_O			: out std_logic_vector (len_d_g * data_width_g-1 downto 0); --contains the len word
    ACK_I			: in std_logic;                      --'1' when valid data is recieved from WS or for successfull write operation in WS
    DAT_I			: in std_logic_vector (data_width_g-1 downto 0);   --data recieved from WS
	STALL_I			: in std_logic; --STALL - WS is not available for transaction 
	ERR_I			: in std_logic  --Watchdog interrupts, resets wishbone master
   	);
end component wishbone_master;


------------------  	Constants	-----------------
constant zero_vector_c       : std_logic_vector (data_width_g -1 downto 0) := (others => '0');
constant addr_zero_vector_c  : std_logic_vector (addr_bits_g -1 downto 0)  := (others => '0');

------------------  SIGNALS --------------------
--FSM <--> mp_enc
signal enc_reg_ready_sig 	:std_logic;   --frame ok
signal type_out_sig				:std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);
signal add_out_sig				:std_logic_vector (Add_width_g-1 downto 0);
signal len_out_sig				:std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);
signal mp_done_sig				:std_logic;
--FSM <--> WS
signal typ_sig				:  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); -- Type
signal addr_sig	        :  std_logic_vector (Add_width_g-1 downto 0);    --the beginnig address in the client that the information will be written to
signal ws_data_sig	    	:  std_logic_vector (data_width_g-1 downto 0);    --data out to registers
signal ws_data_valid_sig	:  std_logic;	-- data valid to registers
signal active_cycle_sig	:  std_logic; --CYC_I outputed to user side
signal stall_sig			:  std_logic; -- stall - suspend wishbone transaction

--FSM <--> WM  
signal wm_start_sig		:  std_logic;	--when '1' WM starts a transaction
signal wr_sig				:  std_logic;                      --determines if the WM will make a read('0') or write('1') transaction
signal type_in_sig			:  std_logic_vector (type_d_g * data_width_g-1 downto 0);  --type is the client which the data is directed to
signal len_in_sig			:  std_logic_vector (len_d_g * data_width_g-1 downto 0);  --length of the data (in words)
signal addr_in_sig			:  std_logic_vector (Add_width_g-1 downto 0);  --the address in the client that the information will be written to
signal ram_start_addr_sig	:  std_logic_vector (addr_bits_g-1 downto 0); -- start address for WM to read from RAM
signal wm_end_sig			:  std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
	
--RAM write
signal ram_wr_en			:std_logic;
signal ram_data_wr			:std_logic_vector (data_width_g-1 downto 0) ;
signal ram_addr_wr				:std_logic_vector (addr_bits_g-1 downto 0);		--wtme ram_addr_in
--RAM read
signal ram_addr_rd		:std_logic_vector (addr_bits_g - 1 downto 0);   -- read_addr mpe  (red)
signal ram_aout_valid_rd			:std_logic;		--from read_addr_an mpe (green)
signal ram_data_rd			:std_logic_vector (data_width_g- 1 downto 0);		
signal ram_data_valid_rd		:std_logic;

--CRC
signal crc_to_mpe			:std_logic_vector(data_width_g-1 downto 0); 
signal crc_mpe_in_val		:std_logic;
signal crc_data_sig				:std_logic_vector(data_width_g-1 downto 0); 
signal crc_rst_sig				:std_logic;
signal crc_request_sig		:std_logic;
signal crc_mpe_out_val		:std_logic;

--FIFO
signal fifo_is_full			:std_logic;
signal mpe_data_to_fifo		:std_logic_vector(data_width_g-1 downto 0); 
signal fifo_is_empty		:std_logic;
signal fifo_out_val		:std_logic;
signal fifo_data_to_uart	:std_logic_vector(data_width_g-1 downto 0);
signal fifo_read_en_sig		:std_logic;
signal fifo_wr_en_sig      :std_logic;

 
------------------	Processes	----------------
-----------------------------------------------

begin 

-------------------wtme Instantiations------------------
bus_to_enc_fsm_inst : bus_to_enc_fsm
generic map	(
  	reset_polarity_g	=> reset_polarity_g,
	data_width_g		=> data_width_g,
	Add_width_g			=> Add_width_g,
	len_d_g				=> len_d_g,
	type_d_g			=> type_d_g,
	addr_bits_g			=> addr_bits_g
 )
port map (
	clk				=> sys_clk,
	reset   	  	=> sys_reset,
	--Wishbone Slave interface
	typ				=> typ_sig,
	addr	        => addr_sig,
	ws_data	    	=> ws_data_sig,
	ws_data_valid	=> ws_data_valid_sig,
	active_cycle	=> active_cycle_sig,
	stall			=> stall_sig,
	--Wishbone Master interface
	wm_start		=> wm_start_sig,
	wr				=> wr_sig,
	type_in			=> type_in_sig,
    len_in			=> len_in_sig,
    addr_in			=> addr_in_sig,
	ram_start_addr	=> ram_start_addr_sig,
    wm_end			=> wm_end_sig,
	--Message Pack Encoder interface
	reg_ready		=> enc_reg_ready_sig,
	type_mp_enc		=> type_out_sig,
	addr_mp_enc		=> add_out_sig,
	len_mp_enc		=> len_out_sig,
    mp_done			=> mp_done_sig
);

------------------- mp_enc Instantiations--------------------
tx_mpe_inst : mp_enc
	  generic map  (
		reset_polarity_g 	=> reset_polarity_g,
		width_g 			=> data_width_g,
		len_dec1_g 			=> false,				--for reading registers out.TXT
		type_d_g			=> type_d_g,
		Add_width_g			=> Add_width_g, 
		len_d_g    => len_d_g
		
					)

	  port map		(	   		

		clk					=> sys_clk,		
		rst					=> sys_reset,
		fifo_full			=> fifo_is_full,		
		reg_ready			=> enc_reg_ready_sig,								
		type_reg			=> type_out_sig,
		addr_reg			=> add_out_sig,
		len_reg				=> len_out_sig, 
		crc_in				=> crc_to_mpe,
		crc_in_val			=> crc_mpe_in_val,
		din					=> ram_data_rd,
		din_valid			=> ram_data_valid_rd,
		
		mp_done				=> mp_done_sig,		
		dout				=> mpe_data_to_fifo,
		dout_valid			=> fifo_wr_en_sig,		
		data_crc_val		=> crc_mpe_out_val,
		data_crc			=> crc_data_sig,
		reset_crc			=> crc_rst_sig,				
		req_crc				=> crc_request_sig,	
		
		read_addr_en		=> ram_aout_valid_rd,
		read_addr			=> ram_addr_rd

					);	  
				
------------------- uart Instantiations--------------------
tx_uart_inst : uart_tx
  generic map  (
	 parity_en_g		    => parity_en_g, 
	 parity_odd_g		   => parity_odd_g,
	 uart_idle_g		    => uart_idle_g, 
	 baudrate_g		    	=> baudrate_g,
	 clkrate_g		      => clkrate_g,
	 databits_g		    	=> data_width_g,--databits_g,
	 reset_polarity_g	=> reset_polarity_g
					)

	  port map		(
		din		   		=> fifo_data_to_uart,			
		clk			=> sys_clk,		
		reset			=>	sys_reset,
		fifo_empty		=> fifo_is_empty,	
		fifo_din_valid	=> fifo_out_val,	
		fifo_rd_en		=> fifo_read_en_sig,	
		dout			=> uart_out	
	  
					);	  
					
-------------------ram_simple Instantiations--------------------
tx_ram_inst : ram_simple
	  generic map  (
	  reset_polarity_g  => reset_polarity_g,
	  width_in_g  => data_width_g,
	  addr_bits_g	 => addr_bits_g
					)

	  port map		(
		clk			=> sys_clk,		
		rst			=> sys_reset,
		addr_in		=> ram_addr_wr,
		addr_out	=> ram_addr_rd,
		aout_valid	=> ram_aout_valid_rd,
		data_in		=> ram_data_wr,
		din_valid	=> ram_wr_en,
		data_out	=> ram_data_rd,
		dout_valid  => ram_data_valid_rd
	  
					);	  
									
------------------- crc_gen Instantiations--------------------
tx_crc_inst : crc_gen
	  generic map  (
	   reset_activity_polarity_g  => reset_polarity_g
					)

	  port map		(

	    clock   	=> sys_clk, 
        reset       => sys_reset,
        soc       	=> crc_rst_sig,
        data       	=> crc_data_sig,
        data_valid  => crc_mpe_out_val,
        eoc			=> crc_request_sig,        
        crc        	=> crc_to_mpe,
        crc_valid 	=> crc_mpe_in_val
					);	  
										
------------------- general_fifo Instantiations--------------------
tx_fifo_inst : general_fifo
	  generic map  (
	  reset_polarity_g  => reset_polarity_g,
	  width_g  =>data_width_g,
	  depth_g  => fifo_d_g
					)

	  port map		(

		 clk 			=> sys_clk, 
		 rst 			=> sys_reset,
		 din 			=> mpe_data_to_fifo,
		 wr_en 			=> fifo_wr_en_sig,
		 rd_en 			=> fifo_read_en_sig,
		 flush			=> '0', 
		 dout 			=> fifo_data_to_uart,
		 dout_valid		=> fifo_out_val,
		 afull			=>  open,
		 full 			=> fifo_is_full,
		 aempty 		=> open, --fifo_is_empty,	
		 empty 			=> fifo_is_empty,
		 used	 		=> open
					);	  

------------------wishbone Slave Instantiations	-----------------
wb_slave_inst : wishbone_slave 
   generic map (
     reset_activity_polarity_g	=> reset_polarity_g,
     data_width_g				=> data_width_g,
	 Add_width_g				=> Add_width_g,
	 len_d_g					=> len_d_g,
	 type_d_g					=> type_d_g
           )
		   
   port map
   	   (
    clk			=> sys_clk,  
    reset		=> sys_reset,         
	--bus side signals
    ADR_I       => ADR_I_S_TX,
    DAT_I       => DAT_I_S,
    WE_I		=> WE_I_S_TX,           
    STB_I       => STB_I_S_TX,  
    CYC_I       => CYC_I_S_TX,
    TGA_I       => TGA_I_S_TX,  
    TGD_I		=> TGD_I_S_TX,	 
    ACK_O       => ACK_O_TO_M,   
    DAT_O 		=> DAT_O_TO_M,  
	STALL_O		=> STALL_O_TO_M,
	--user side signals
	typ				=> typ_sig,
	addr	    	=> addr_sig,
	len				=> open,
	wr_en			=> open,
	ws_data	    	=> ws_data_sig,
	ws_data_valid	=> ws_data_valid_sig,
	reg_data     	=> addr_zero_vector_c,--(others => '0'),
    reg_data_valid	=> '0',
	active_cycle	=> active_cycle_sig,
	stall			=> stall_sig
);
	  

------------------wishbone master Instantiations	-----------------

wishbone_master_inst : wishbone_master 

   generic map (
    reset_activity_polarity_g  	=> reset_polarity_g,
    data_width_g            	=> data_width_g,
	type_d_g					=> type_d_g,
	Add_width_g					=> Add_width_g,
	len_d_g						=> len_d_g,
	addr_bits_g					=> addr_bits_g
)
   port map
   	   (
     sys_clk       => sys_clk,  
     sys_reset	   => sys_reset,     
	--control unit signals
	wm_start		=> wm_start_sig,
	wr				=> wr_sig,
	type_in			=> type_in_sig,
    len_in			=> len_in_sig,
    addr_in			=> addr_in_sig,
	ram_start_addr	=> ram_start_addr_sig,
    wm_end			=> wm_end_sig,
	--RAM signals
	ram_addr		=> ram_addr_wr,
	ram_dout		=> ram_data_wr,
	ram_dout_valid	=> ram_wr_en,
	ram_aout		=> open,
	ram_aout_valid	=> open,
	ram_din			=> zero_vector_c,--(others => '0'),
	ram_din_valid	=> '0',
    --bus side signals
    ADR_O	   => ADR_O_CLIENT,       
    DAT_O      => DAT_O_CLIENT,
    WE_O       => WE_O_CLIENT,    
    STB_O      => STB_O_CLIENT,    
    CYC_O      => CYC_O_CLIENT,    
    TGA_O      => TGA_O_CLIENT,    
    TGD_O      => TGD_O_CLIENT,   
    ACK_I      => ACK_I_CLIENT,    
    DAT_I      => DAT_I_CLIENT,
    STALL_I	   => STALL_I_CLIENT,
	ERR_I	   => ERR_I_CLIENT
);

end architecture arc_tx_path;			