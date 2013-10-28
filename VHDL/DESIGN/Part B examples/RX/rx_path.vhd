-----------------------------------------------------------------------------------------------
-- Model Name 	:	RX path
-- File Name	:	rx_path.vhd
-- Generated	:	06.08.2011
-- Author		:	Dor Obstbaum and Kami Elbaz
-- Project		:	FPGA setting usiing FLASH project
------------------------------------------------------------------------------------------------
-- Description: 
-- The RX path unit recieve UART asynchronic transmition at one end and transmit synchronic data using Wishbone protocol at the other end.
-- The unit contains the uart rx, message pack decoder, CRC blocks that recieve the uart transmition and split it into words saved in the RAM block.
-- The message decoder to wishbone master, wishbone master and wishbone slave connect the unit with the system via wishbone bus.
-- The rx path unit also contains an error register which can be read using the wishbone slave.
--
-- reading errors from error_register:
-- the errors that are sampled in the error_register can be read via wishbone bus. the 8 bit word recieved should be decoded as detailed below:
-- data[0] is stop_bit_err
-- data[1] is parity_err
-- data[2] is eof_err
-- data[3] is crc_err
-- data[7..4] is always '0'
------------------------------------------------------------------------------------------------
-- Revision:
--			Number 		Date	       	Name       			 	Description
--			1.0		   	06.08.2011  	Dor Obstbaum	 		Creation
--    		1.1     	16.08.2011   	Dor Obstbaum    		wr_en port added to error_register. we_out port added to wb_slave.
--			2.0			25.09.2012		Dor Obstbaum			Support pipeline mode
--			2.1			03.11.2012		Dor Obstbaum			flash_error port added and connected to error_register
------------------------------------------------------------------------------------------------
--	Todo:
--							
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;

entity rx_path is
   generic (
       -- mutual generics
      reset_polarity_g	:		std_logic  := '1'	;			        -- '0' = Active Low, '1' = Active High
      data_width_g     :  natural    := 8;              -- defines the width of the data lines of the system
			clkrate_g		     	:		positive	  := 100000000;		    -- Sys. clock [Hz]      
       --uart_rx generics
			parity_en_g		    :		natural range 0 to 1 := 0; 		 -- 1 to Enable parity bit, 0 to disable parity bit
			parity_odd_g		   :		boolean 	  := false; 			      -- TRUE = odd, FALSE = even
			uart_idle_g		    :		std_logic 	:= '1';				        -- IDLE_ST line value
			baudrate_g			    :		positive	  := 115200;			      -- UART baudrate [Hz]
			 --mp_dec generics
			len_dec1_g	     	:	boolean     := true;	          -- TRUE - Recieved length is decreased by 1 ,to save 1 bit  --FALSE - Recieved length is the actual length
			sof_d_g				      :	positive    := 1;		            -- SOF Depth
			type_d_g		 	     :	positive    := 1;		            -- Type Depth
			addr_d_g		      	:	positive    := 3;		            -- Address Depth
			len_d_g				      :	positive    := 1;	            	-- Length Depth
			crc_d_g				      :	positive    := 1;		            -- CRC Depth
			eof_d_g			 	     :	positive    := 1;		            -- EOF Depth					
			sof_val_g			     :	natural     := 60;	           	-- (3Ch) SOF block value. Upper block is MSB
			eof_val_g			     :	natural     := 165;		          -- (A5h) EOF block value. Upper block is MSB				
			 --ram_simple_generics
			addr_bits_g		    :	positive   	:= 8;              -- Depth of data	(2^10 = 1024 addresses)  
			 --error_register_generics
      error_register_address_g       : natural   :=0 ;  -- defines the address that should be sent on access to the unit
      led_active_polarity_g          : std_logic :='1'; -- defines the active state of the error signal input: '0' active low, '1' active high
      error_active_polarity_g        : std_logic :='1'; -- defines the polarity which the error signal is active in  
		  code_version_g			             	: natural	  := 0	  -- Hardware code version
           );
   port
   	   (
     sys_clk        : in std_logic;                                                -- system clock
     sys_reset      : in std_logic;                                                -- system reset
     rx_din         : in std_logic;                                                -- input of UART data
     error_led_out  : out std_logic;                                               -- '1' when one of the error bits in the register is high
	   flash_error    : in std_logic;                                                -- error signal from flash client - directed to error register
     --Wishbone Master interface
     ADR_O          : out std_logic_vector (addr_d_g * data_width_g-1 downto 0);   -- contains the addr word
     DAT_O          : out std_logic_vector (data_width_g-1 downto 0);              -- contains the data_in word
     WE_O           : out std_logic;                                               -- '1' for write, '0' for read
     STB_O          : out std_logic;                                               -- '1' for active bus operation, '0' for no bus operation
     CYC_O          : out std_logic;                                               -- '1' for bus transmition request, '0' for no bus transmition request
     TGA_O          : out std_logic_vector (type_d_g * data_width_g-1 downto 0);   -- contains the type word
     TGD_O          : out std_logic_vector (len_d_g * data_width_g-1 downto 0);    -- contains the len word
     ACK_I          : in std_logic;                                                -- '1' when valid data is recieved from WS or for successfull write operation in WS
     DAT_I          : in std_logic_vector (data_width_g-1 downto 0);               -- data recieved from WS
	   STALL_I		      : in std_logic;                                                -- STALL - WS is not available for transaction 
	   ERR_I			       : in std_logic;                                                -- Watchdog interrupts, resets wishbone master	
     --Wishbone Slave interface
     ADR_I          : in std_logic_vector ((data_width_g)*(addr_d_g)-1 downto 0);	 -- contains the addr word
     WE_I           : in std_logic;                     			                       	-- '1' for write, '0' for read
     STB_I          : in std_logic;                     				                       -- '1' for active bus operation, '0' for no bus operation
     CYC_I          : in std_logic;                     				                       -- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I          : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	-- contains the type word
     TGD_I          : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);  	-- contains the len word
     ACK_O          : out std_logic;                      			                     	-- '1' when valid data is transmited to MW or for successfull write operation 
     WS_DAT_O       : out std_logic_vector (data_width_g-1 downto 0);             	-- data transmit to MW  
	   STALL_O	      	: out std_logic                                                -- STALL - WS is not available for transaction 
       );
end entity rx_path;

architecture arc_rx_path of rx_path is
------------------  	Types		-----------------

------------------ Components ---------------
component uart_rx
   generic (
			 parity_en_g		    :		natural range 0 to 1 := 0; 	          	-- 1 to Enable parity bit, 0 to disable parity bit
			 parity_odd_g   		:		boolean 	  := false; 			               -- TRUE = odd, FALSE = even
			 uart_idle_g		    :		std_logic 	:= '1';				                 -- IDLE_ST line value
			 baudrate_g			    :		positive	  := 115200;		               	-- UART baudrate [Hz]
			 clkrate_g		     	:		positive	  := 133333333;		             -- Sys. clock [Hz]
			 databits_g			    :		natural range 5 to 8 := 8;		           -- Number of databits
			 reset_polarity_g	:		std_logic 	:= '0'	 			                 -- '0' = Active Low, '1' = Active High
           );
   port
   	   (
			 din				       :	in std_logic;				                               -- Serial data in
			 clk				       :	in std_logic;				                               -- Sys. clock
			 reset			     	:	in std_logic;				                               -- Reset
 			 dout			      	:	out std_logic_vector (databits_g - 1 downto 0); -- Parallel data out
			 valid				     :	out std_logic;				                              -- Parallel data valid
			 parity_err		 	:	out std_logic;			                              	-- parity error
			 stop_bit_err		:	out	std_logic			                               	-- Stop bit error
   	   );
	end component uart_rx;
	
component mp_dec
   generic (
				reset_polarity_g	:	std_logic := '0'; 	-- '0' = Active Low, '1' = Active High
				len_dec1_g			:	boolean := true;	      -- TRUE  - Recieved length is decreased by 1 ,to save 1 bit
															                -- FALSE - Recieved length is the actual length				
				sof_d_g				:	positive := 1;	  	-- SOF Depth
				type_d_g			:	positive := 1;	  	-- Type Depth
				addr_d_g			:	positive := 3;	  	-- Address Depth
				len_d_g				:	positive := 2;		  -- Length Depth
				crc_d_g				:	positive := 1;		  -- CRC Depth
				eof_d_g				:	positive := 1;		  -- EOF Depth
				sof_val_g		:	natural  := 100;		-- (64h) SOF block value. Upper block is MSB
				eof_val_g		:	natural  := 200;	 -- (C8h) EOF block value. Upper block is MSB	
				width_g				:	positive := 8;		  -- Data Width (UART = 8 bits)
				ram_size_g	:	positive := 8	 	  -- RAM size in bytes(2^8 = 256bytes)
           );
   port
   	   (
				--Inputs
				clk			:	in std_logic; 	                             --Clock
				rst			:	in std_logic;	                              --Reset
				din			:	in std_logic_vector (width_g - 1 downto 0); --Input data_d_g
				valid	:	in std_logic;	                              --Data valid
				
				--Message Pack Status
				mp_done		:	out std_logic;	--Message Pack has been recieved
				eof_err		:	out std_logic;	--EOF has not found
				crc_err		:	out std_logic;	--CRC error
				
				--Registers
				type_reg	:	out std_logic_vector (width_g * type_d_g - 1 downto 0);
				addr_reg	:	out std_logic_vector (width_g * addr_d_g - 1 downto 0);
				len_reg		:	out std_logic_vector (width_g * len_d_g - 1 downto 0);

				--CRC / CheckSum
				data_crc_val:	out std_logic;                                   -- '1' when new data for CRC is valid, '0' otherwise
				data_crc	:	out std_logic_vector (width_g - 1 downto 0);        -- Data to be calculated by CRC
				reset_crc	:	out std_logic;                                     -- '1' to reset CRC value
				req_crc		:	out std_logic;                                      -- '1' to request for current caluclated CRC
				crc_in		:	in std_logic_vector (width_g * crc_d_g -1 downto 0); -- CRC value
				crc_in_val	:	in std_logic;                                     -- '1' when CRC is valid
				
				--Data (Payload)
				write_en	:	out std_logic;                                           --'1' = Data is available (width_g length)
				write_addr	:	out std_logic_vector (width_g * len_d_g - 1 downto 0); --RAM Address
				dout		:	out std_logic_vector (width_g - 1 downto 0)                 --Data to RAM
   	   );
	end component mp_dec;
	
component crc_gen
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
	end component crc_gen;
	
component ram_simple
	generic (
				reset_polarity_g	:	std_logic 	:= '0';	                        --'0' - Active Low Reset, '1' Active High Reset
				width_in_g			:	positive 	:= 8;	                               --Width of data
				addr_bits_g			:	positive 	:= 10	                              --Depth of data	(2^10 = 1024 addresses)
			);
	port	(
				clk			     :	in std_logic;							                           		--System clock
				rst		   	  :	in std_logic;								       	                    --System Reset
				addr_in	  	:	in std_logic_vector (addr_bits_g - 1 downto 0);  --Input address
				addr_out  	:	in std_logic_vector (addr_bits_g - 1 downto 0);  --Output address
				aout_valid	:	in std_logic;									                           --Output address is valid
				data_in		  :	in std_logic_vector (width_in_g - 1 downto 0);  	--Input data
				din_valid	 :	in std_logic; 								                         	 --Input data valid
				data_out	  :	out std_logic_vector (width_in_g - 1 downto 0); 	--Output data
				dout_valid	:	out std_logic 								                        	  --Output data valid
			);
	end component ram_simple;


component wishbone_master is
   generic (
    reset_activity_polarity_g  : std_logic :='1';      -- defines reset active polarity: '0' active low, '1' active high
    data_width_g               : natural := 8 ;        -- defines the width of the data lines of the system
    type_d_g			                :	positive := 1;		      -- Type Depth
	  addr_d_g			                :	positive := 3;		      -- Address Depth
	  len_d_g			                	:	positive := 1;		      -- Length Depth
	  addr_bits_g		            		:	positive := 8        	-- Depth of data in RAM	(2^8 = 256 addresses)
           );
   port
   	   (
	 
    sys_clk			     : in std_logic;                                               --system clock
    sys_reset	    	: in std_logic;                                               --system reset   
	--control unit signals
	  wm_start		     : in std_logic;	                                              --when '1' WM starts a transaction
	  wr				         : in std_logic;                                               --determines if the WM will make a read('0') or write('1') transaction
	  type_in			     : in std_logic_vector (type_d_g * data_width_g-1 downto 0);   --type is the client which the data is directed to
    len_in			      : in std_logic_vector (len_d_g * data_width_g-1 downto 0);    --length of the data (in words)
    addr_in			     : in std_logic_vector (addr_d_g * data_width_g-1 downto 0);   --the address in the client that the information will be written to
	  ram_start_addr	: in std_logic_vector (addr_bits_g-1 downto 0);               -- start address for WM to read from RAM
    wm_end		      	: out std_logic;                                              --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
	--RAM signals
	  ram_addr		     :	out std_logic_vector (addr_bits_g - 1 downto 0);            --RAM Input address
	  ram_dout		     :	out std_logic_vector (data_width_g - 1 downto 0);	          --RAM Input data
	  ram_dout_valid	:	out std_logic; 									                                    --RAM Input data valid
	  ram_aout	     	:	out std_logic_vector (addr_bits_g - 1 downto 0);            --RAM Output address
	  ram_aout_valid	:	out std_logic;									                                     --RAM Output address is valid
	  ram_din			     :	in std_logic_vector (data_width_g - 1 downto 0);           	--RAM Output data
	  ram_din_valid	 :	in std_logic; 									                                     --RAM Output data valid
	--bus side signals
    ADR_O			       : out std_logic_vector (addr_d_g * data_width_g-1 downto 0);   --contains the addr word
    DAT_O		       	: out std_logic_vector (data_width_g-1 downto 0);              --contains the data_in word
    WE_O			        : out std_logic;                                               -- '1' for write, '0' for read
    STB_O		       	: out std_logic;                                               -- '1' for active bus operation, '0' for no bus operation
    CYC_O		       	: out std_logic;                                               -- '1' for bus transmition request, '0' for no bus transmition request
    TGA_O			       : out std_logic_vector (type_d_g * data_width_g-1 downto 0);   --contains the type word
    TGD_O		       	: out std_logic_vector (len_d_g * data_width_g-1 downto 0);    --contains the len word
    ACK_I		       	: in std_logic;                                                --'1' when valid data is recieved from WS or for successfull write operation in WS
    DAT_I			       : in std_logic_vector (data_width_g-1 downto 0);               --data recieved from WS
	  STALL_I			     : in std_logic;                                                --STALL - WS is not available for transaction 
	  ERR_I			       : in std_logic                                                 --Watchdog interrupts, resets wishbone master
   	);
end component wishbone_master;
  	
  	component error_register is
   generic (
     reset_activity_polarity_g  : std_logic :='1';    -- defines reset active polarity: '0' active low, '1' active high
     error_register_address_g   : natural   :=0 ;     -- defines the address that should be sent on access to the unit
     data_width_g               : natural   := 8 ;    -- defines the width of the data lines of the system
     address_width_g            : natural   := 8;     -- defines the width of the address lines of the system
     led_active_polarity_g      : std_logic :='1';    -- defines the active state of the error signal input: '0' active low, '1' active high
     error_active_polarity_g    : std_logic :='1';    -- defines the polarity which the error signal is active in
	 code_version_g				           : natural	  := 0	     -- Hardware code version
           );
   port
   	   (
     sys_clk           : in std_logic;                                       --system clock
     sys_reset         : in std_logic;                                       --system reset
     --error signals
     error_in          : in std_logic_vector (data_width_g-1 downto 0); 
     error_led_out     : out std_logic;                                      -- '1' when one of the error bits in the register is high
     --wishbone slave comunication signals
     data_out          : out std_logic_vector (data_width_g-1 downto 0);     -- data sent to WS
     valid_data_out    : out std_logic;                                      -- validity of data directed to WS
     address_in         : in std_logic_vector (address_width_g-1 downto 0);  -- address line. only "00000000" is recieved in the error_register because there is only one address.
     valid_in          : in std_logic;                                       -- validity of the address directed from WS
     wr_en             : in std_logic                                        -- enables reading the error register
   	   );
end component error_register;

component wb_slave is
   generic (
     reset_activity_polarity_g  	:std_logic :='1';                           -- defines reset active polarity: '0' active low, '1' active high
     data_width_g               	: natural  := 8;                            -- defines the width of the data lines of the system    
	   addr_d_g				                :	positive := 3;		                          -- Address Depth
	   len_d_g				                 :	positive := 1;	                           -- Length Depth
	   type_d_g			                	:	positive := 1		                           -- Type Depth    
		   );	   
   port
   	   (
     sys_clk        : in std_logic;		                                               --system clock
     sys_reset      : in std_logic;		                                               --system reset    
	 --bus side signals
     ADR_I          : in std_logic_vector ((data_width_g)*(addr_d_g)-1 downto 0);  	-- contains the addr word
     DAT_I          : in std_logic_vector (data_width_g-1 downto 0); 	              -- contains the data_in word
     WE_I           : in std_logic;                     				                        -- '1' for write, '0' for read
     STB_I          : in std_logic;                     		                      	  	-- '1' for active bus operation, '0' for no bus operation
     CYC_I          : in std_logic;                     		                        		-- '1' for bus transmition request, '0' for no bus transmition request
     TGA_I          : in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);   -- contains the type word
     TGD_I          : in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	  -- contains the len word
     ACK_O          : out std_logic;                      				                      -- '1' when valid data is transmited to MW or for successfull write operation 
     DAT_O          : out std_logic_vector (data_width_g-1 downto 0);   	           -- data transmit to MW
	   STALL_O	      	: out std_logic;                                                -- STALL - WS is not available for transaction 
	 --register side signals
	   typ			         : out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0);  -- Type
	   addr	          : out std_logic_vector ((data_width_g)*(addr_d_g)-1 downto 0);  -- the beginnig address in the client that the information will be written to
	   len		         	: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);   -- Length
	   wr_en			       : out std_logic;
	   ws_data	       : out std_logic_vector (data_width_g-1 downto 0);               -- data out to registers
	   ws_data_valid 	: out std_logic;	                                               -- data valid to registers
	   reg_data       : in std_logic_vector (data_width_g-1 downto 0); 	              -- data to be transmited to the WM
     reg_data_valid : in std_logic;                                                 -- data to be transmited to the WM validity
	   active_cycle  	: out std_logic;                                                -- CYC_I outputed to user side
	   stall		        : in std_logic                                                  -- stall - suspend wishbone transaction
	  );
end component wb_slave;
------------------  	Constants	-----------------
constant zero_vector_c       : std_logic_vector (data_width_g -1 downto 0) := (others => '0');
constant addr_zero_vector_c  : std_logic_vector (addr_bits_g -1 downto 0) := (others => '0');

------------------  SIGNALS --------------------
-- uart_rx <-> mp_dec signals
signal uart_rx_mp_dec_din    : std_logic_vector(data_width_g-1 downto 0); 
signal uart_rx_mp_dec_valid  : std_logic;  
-- mp_dec <-> CRC signals
signal data_crc_val_sig      : std_logic;  
signal data_crc_sig          : std_logic_vector(data_width_g-1 downto 0);  
signal reset_crc_sig         : std_logic;  
signal req_crc_sig           : std_logic;  
signal crc_calc_sig          : std_logic_vector(data_width_g-1 downto 0); 
signal crc_calc_val_sig      : std_logic;  
-- mp_dec <-> RAM signals
signal mp_dec_RAM_valid      : std_logic;  
signal mp_dec_RAM_address    : std_logic_vector(addr_bits_g-1 downto 0);
signal mp_dec_RAM_data       : std_logic_vector(data_width_g-1 downto 0); 
-- mp_dec <-> WM signals
signal mp_dec2wm_start       : std_logic;  
signal mp_dec2wm_type        : std_logic_vector(type_d_g * data_width_g-1 downto 0);  
signal mp_dec2wm_addr        : std_logic_vector(addr_d_g * data_width_g-1 downto 0); 
signal mp_dec2wm_len         : std_logic_vector(len_d_g * data_width_g-1 downto 0);
-- WM <->RAM signals
signal wm2RAM_val_adress     : std_logic;  
signal wm2RAM_adress         : std_logic_vector(addr_bits_g-1 downto 0); 
signal RAM2wm_val_data       : std_logic;  
signal RAM2wm_data           : std_logic_vector(data_width_g-1 downto 0);
--error_register <-> wishbone_slave signals
signal err_reg2ws_data       : std_logic_vector(data_width_g-1 downto 0);
signal err_reg2ws_val_data   : std_logic;
signal ws2err_reg_adress     : std_logic_vector(addr_d_g * data_width_g-1 downto 0); 
signal ws2err_reg_valid      : std_logic;
signal ws2err_reg_wr_en      : std_logic;
--error signal:
signal rx_error_sig          : std_logic_vector(data_width_g-1 downto 0);
------------------	Processes	----------------

---------------------------------------------
begin 
-------------------Instantiations-------------------- 
  uart_rx_inst : uart_rx 
  generic map
    (
  			 parity_en_g       => parity_en_g,
			 parity_odd_g	     => parity_odd_g,
			 uart_idle_g	     	=> uart_idle_g,
			 baudrate_g		     	=> baudrate_g	,
			 clkrate_g		      	=> clkrate_g,
			 databits_g	     		=> data_width_g,
			 reset_polarity_g	 => reset_polarity_g 
    )
  port map 
    (
  			 din		        	=> rx_din,
			 clk		       		=> sys_clk,
			 reset			     	=> sys_reset,
 			 dout				      => uart_rx_mp_dec_din, 
			 valid			      => uart_rx_mp_dec_valid, 
			 parity_err			 => rx_error_sig(1),
			 stop_bit_err	 => rx_error_sig(0)
    ); 
 
    
      mp_dec_inst : mp_dec 
  generic map
    (
				reset_polarity_g	=> reset_polarity_g,
				len_dec1_g	     	=>	len_dec1_g,			
				sof_d_g				      => sof_d_g,
				type_d_g			      => type_d_g,
				addr_d_g			      => addr_d_g,
				len_d_g			      	=> len_d_g,
				crc_d_g			       => crc_d_g,
				eof_d_g				      => eof_d_g,
				sof_val_g			     => sof_val_g,
				eof_val_g		     	=>	eof_val_g,
				width_g				      => data_width_g,  
				ram_size_g				   =>addr_bits_g
    )
  port map 
    (
				clk		       	=> sys_clk,
				rst		       	=> sys_reset,
				din		       	=> uart_rx_mp_dec_din, 
				valid	      	=>	uart_rx_mp_dec_valid, 
				mp_done	    	=>  mp_dec2wm_start, 
				eof_err	    	=> rx_error_sig(2),
				crc_err	    	=>	rx_error_sig(3),
				type_reg	    => mp_dec2wm_type, 
				addr_reg    	=> mp_dec2wm_addr, 
				len_reg	    	=> mp_dec2wm_len,  
				data_crc_val => data_crc_val_sig,
				data_crc	    => data_crc_sig,
				reset_crc	   => reset_crc_sig,
				req_crc		    => req_crc_sig,
				crc_in		     => crc_calc_sig,
				crc_in_val  	=>	crc_calc_val_sig,
				write_en	    => mp_dec_RAM_valid,
				write_addr  	=> mp_dec_RAM_address,
				dout		       => mp_dec_RAM_data
    ); 
    
    
      crc_gen_inst : crc_gen
  generic map  (
	   reset_activity_polarity_g  => reset_polarity_g
					)
	port map 
    (
           clock      => sys_clk,
           reset      => sys_reset,
           soc        => reset_crc_sig,
           data       => data_crc_sig,
           data_valid => data_crc_val_sig,
           eoc        => req_crc_sig,
           crc        => crc_calc_sig,
           crc_valid  => crc_calc_val_sig
    ); 
    
      ram_simple_inst : ram_simple
  generic map
    (
    				reset_polarity_g	 => reset_polarity_g,
				width_in_g	     	 => data_width_g,
				addr_bits_g		  	  => addr_bits_g
    )
  port map 
    (
    			clk		      	=> sys_clk,
				rst		     	=> sys_reset,
				addr_in	  	=> mp_dec_RAM_address,
				addr_out	  => wm2RAM_adress ,     
				aout_valid	=> wm2RAM_val_adress , 
				data_in		  => mp_dec_RAM_data, 
				din_valid	 => mp_dec_RAM_valid,
				data_out	  => RAM2wm_data,
				dout_valid	=> RAM2wm_val_data
    ); 
 
   

wishbone_master_inst : wishbone_master
   generic map(
     reset_activity_polarity_g    => reset_polarity_g,
     data_width_g                 => data_width_g,
     type_d_g			                  => type_d_g,
	   addr_d_g			                  => addr_d_g,
	   len_d_g			                  	=> len_d_g,
	   addr_bits_g		                => addr_bits_g
    )
   port map
   	   (
    sys_clk          => sys_clk,
    sys_reset        => sys_reset,
    --control unit signals
	  wm_start		       => mp_dec2wm_start,
 	  wr				           => '1',
	  type_in			       => mp_dec2wm_type,
    len_in			        => mp_dec2wm_len,
    addr_in		       	=> mp_dec2wm_addr,
	  ram_start_addr  	=> addr_zero_vector_c,--(others => '0'),
    wm_end		        	=> open,
	--RAM signals
	  ram_addr		       => open,
	  ram_dout		       => open,
	  ram_dout_valid	  => open,
	  ram_aout	       	=> wm2RAM_adress,
	  ram_aout_valid	  => wm2RAM_val_adress,
   	ram_din			       => RAM2wm_data,
	  ram_din_valid	   => RAM2wm_val_data,
	--bus side signals
    ADR_O            => ADR_O,
    DAT_O            => DAT_O,
    WE_O             => WE_O,
    STB_O            => STB_O,
    CYC_O            => CYC_O,
    TGA_O            => TGA_O,
    TGD_O            => TGD_O,
    ACK_I            => ACK_I,
    DAT_I            => DAT_I,
	  STALL_I		       	=> STALL_I,
   	ERR_I		         	=> ERR_I
   	);
   	   
  	error_register_inst :  error_register
   generic map (
     reset_activity_polarity_g  => reset_polarity_g,
     error_register_address_g   => error_register_address_g,
     data_width_g               => data_width_g,
     address_width_g            => addr_d_g * data_width_g,
     led_active_polarity_g      => led_active_polarity_g,
     error_active_polarity_g    => error_active_polarity_g,
	 code_version_g			           	=> code_version_g
           )
   port map
   	   (
     sys_clk           => sys_clk,
     sys_reset         => sys_reset,
     error_in          => rx_error_sig,
     error_led_out     => error_led_out,
     data_out          => err_reg2ws_data,
     valid_data_out    => err_reg2ws_val_data,
     address_in        => ws2err_reg_adress,
     valid_in          => ws2err_reg_valid,
     wr_en             => ws2err_reg_wr_en
   	   );
    
    wb_slave_inst : wb_slave
   generic map (
     reset_activity_polarity_g  => reset_polarity_g,
     data_width_g               => data_width_g,
     type_d_g			                => type_d_g,
		 addr_d_g			                => addr_d_g,
		 len_d_g			                	=> len_d_g   
		   )	   
   port map
   	   (
     sys_clk          => sys_clk,
     sys_reset        => sys_reset,  
	 --bus side signals
     ADR_I            => ADR_I,
     DAT_I            => zero_vector_c,
     WE_I             => WE_I,
     STB_I            => STB_I,
     CYC_I            => CYC_I,
     TGA_I            => TGA_I,
     TGD_I            => TGD_I,
     ACK_O            => ACK_O, 
     DAT_O            => WS_DAT_O, 
	   STALL_O	      	  => STALL_O,
	 --user side signals
     typ			           => open,
	   addr	            => ws2err_reg_adress,
	   len			           => open,
	   wr_en		         	=> ws2err_reg_wr_en,
	   ws_data	         => open,
	   ws_data_valid   	=> ws2err_reg_valid,
	   reg_data         => err_reg2ws_data,
     reg_data_valid   => err_reg2ws_val_data,
	   active_cycle	    => open,
	   stall			         => '0'
	  );

----------------------------------------------------
-------------------Signal placement-----------------
rx_error_sig (data_width_g-1 downto data_width_g-3 ) <= ( others => not(error_active_polarity_g) );
rx_error_sig (4) <= error_active_polarity_g when flash_error = '1' else not(error_active_polarity_g) ;
----------------------------------------------------
-------------------Processes------------------------
	      	
end architecture arc_rx_path;