------------------------------------------------------------------------------------------------
-- File Name	:	internal_logic_analyzer_core_top_tb.vhd
-- Generated	:	11.7.2013
-- Author		:	Moran katz & Zvika pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------
-- Description: 
-- 			core test banch 
--			 in this core we have the write controller and the RAM
--			
------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date			Name							Description			
--			1.00		18.6.2013		Zvika Pery						Creation			
------------------------------------------------------------------------------------------------
--	Todo:
--			(1) connect registers in get_config mode
--
------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work ;
use work.ram_generic_pkg.all;

entity internal_logic_analyzer_core_top_tb is
	generic (				
				read_loop_iter_g		:	positive	:= 150;									--Number of iterations
				
				reset_polarity_g		:	std_logic	:= '1';									--'0' - Active Low Reset, '1' Active High Reset
				enable_polarity_g		:	std_logic	:= '1';								--'1' the entity is active, '0' entity not active
				signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
				signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
				record_depth_g			: 	positive  	:=	5;									--number of bits that is recorded from each signal
				data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system
				Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
				num_of_signals_g		:	positive	:=	8;									--num of signals that will be recorded simultaneously	(Width of data)
				width_in_g				:	positive 	:= 	8;									--Width of data
				addr_bits_g				:	positive 	:= 	4;									--Depth of data	(2^4 = 16 addresses)
				power2_out_g			:	natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
				power_sign_g			:	integer range -1 to 1 	:= 1;					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
				type_d_g				:	positive 	:= 	1;		--Type Depth
				len_d_g					:	positive 	:= 	1		--Length Depth
			);
			
end entity internal_logic_analyzer_core_top_tb;

architecture arc_internal_logic_analyzer_core_top_tb of internal_logic_analyzer_core_top_tb is
---------------------------------components------------------------------------------------------------------------------------------------------

component internal_logic_analyzer_core_top is
	generic (				
				reset_polarity_g		:	std_logic	:= '1';									--'0' - Active Low Reset, '1' Active High Reset
				enable_polarity_g		:	std_logic	:= '1';								--'1' the entity is active, '0' entity not active
				signal_ram_depth_g		: 	positive  	:=	3;									--depth of RAM
				signal_ram_width_g		:	positive 	:=  8;   								--width of basic RAM
				record_depth_g			: 	positive  	:=	5;									--number of bits that is recorded from each signal
				data_width_g            :	positive 	:= 	8;      						    -- defines the width of the data lines of the system
				Add_width_g  		    :   positive 	:=  8;     								--width of addr word in the RAM
				num_of_signals_g		:	positive	:=	8;									--num of signals that will be recorded simultaneously	(Width of data)
				width_in_g				:	positive 	:= 	8;									--Width of data
				addr_bits_g				:	positive 	:= 	4;									--Depth of data	(2^4 = 16 addresses)
				power2_out_g			:	natural 	:= 	0;									--Output width is multiplied by this power factor (2^1). In case of 2: output will be (2^2*8=) 32 bits wide -> our output and input are at the same width
				power_sign_g			:	integer range -1 to 1 	:= 1;					 	-- '-1' => output width > input width ; '1' => input width > output width		(if power2_out_g = 0, it dosn't matter)
				type_d_g				:	positive 	:= 	1;		--Type Depth
				len_d_g					:	positive 	:= 	1		--Length Depth
			);
	port	(
				clk							:	in std_logic;									--System clock
				rst							:	in std_logic;									--System Reset
				-- Signal Generator interface
				data_in						:	in std_logic_vector (num_of_signals_g - 1 downto 0);	--Input data from Signal Generator
				trigger						:	in std_logic;											--trigger signal from Signal Generator
				
				-- wishbone slave interface	(change after connecting WBS)
				registers_address_in_s			: in std_logic_vector (Add_width_g -1 downto 0); 	-- reg address line
				wr_en_s             			: in std_logic; 									-- write enable: '1' for write, '0' for read
				registers_data_in_s 			: in std_logic_vector (data_width_g-1 downto 0); 	-- data sent from WS to registers (trigg pos, trigg type, enable, clk to start)
				registers_valid_in_s			: in std_logic; 									-- validity of the data directed from WS
				
				-- wishbone master interface
				wm_end_out					: 	out std_logic; --when '1' WM ended a transaction or reseted by watchdog ERR_I signal
				
				--wm_bus side signals
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
end component internal_logic_analyzer_core_top;

------- we connect an external wishbone slave to check the outputs from our wishbone master (wich is part of the core)
component wishbone_slave
	generic (
			reset_activity_polarity_g  	:std_logic :='1';      -- defines reset active polarity: '0' active low, '1' active high
			data_width_g               	: natural := 8;         -- defines the width of the data lines of the system    
			Add_width_g    				:   positive := 8;		--width of addr word in the WB
			len_d_g						:	positive := 1;		--Length Depth
			type_d_g					:	positive := 1		--Type Depth    
			);
	port
	(	
			clk    	    	: in std_logic;		 											--system clock
			reset			: in std_logic;		 											--system reset
			--bus side signals
			ADR_I          	: in std_logic_vector (Add_width_g -1 downto 0);				--contains the addr word
			DAT_I          	: in std_logic_vector (data_width_g-1 downto 0); 				--contains the data_in word
			WE_I           	: in std_logic;                     							-- '1' for write, '0' for read
			STB_I          	: in std_logic;                     							-- '1' for active bus operation, '0' for no bus operation
			CYC_I          	: in std_logic;                     							-- '1' for bus transmition request, '0' for no bus transmition request
			TGA_I          	: in std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	--contains the type word
			TGD_I          	: in std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0); 	--contains the len word
			ACK_O          	: out std_logic;                      							--'1' when valid data is transmited to MW or for successfull write operation 
			DAT_O          	: out std_logic_vector (data_width_g-1 downto 0);   			--data transmit to MW
			STALL_O			: out std_logic; 												--STALL - WS is not available for transaction 
			--register side signals
			typ				: out std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); 	-- Type
			addr	        : out std_logic_vector (Add_width_g-1 downto 0);    			--the beginnig address in the client that the information will be written to
			len				: out std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);   --Length
			wr_en			: out std_logic;
			ws_data	    	: out std_logic_vector (data_width_g-1 downto 0); 				--data out to registers
			ws_data_valid	: out std_logic;												-- data valid to registers
			reg_data       	: in std_logic_vector (data_width_g-1 downto 0); 	 			--data to be transmited to the WM
			reg_data_valid 	: in std_logic;   												--data to be transmited to the WM validity
			active_cycle	: out std_logic; 												--CYC_I outputed to user side
			stall			: in std_logic 													-- stall - suspend wishbone transaction
	);

end component wishbone_slave;

-----------------------------------------------------Constants--------------------------------------------------------------------------
constant type_of_TX_ws_c	: std_logic_vector (type_d_g * data_width_g - 1 downto 0 )	:= std_logic_vector(to_unsigned( 4 , type_d_g * data_width_g));
constant len_of_data_c		: std_logic_vector (len_d_g * data_width_g - 1 downto 0)	:= std_logic_vector(to_unsigned( 1 , len_d_g * data_width_g));
-----------------------------------------------------Types------------------------------------------------------------------------------


----------------------   Signals   ------------------------------
signal clk							: std_logic		:= '0';									--System clock
signal rst							: std_logic		:= '0';									--System Reset
signal data_in						: std_logic_vector (num_of_signals_g - 1 downto 0)	:=(others => '0');	--Input data from Signal Generator
signal trigger						: std_logic		:= '0';									--trigger signal from Signal Generator
-- wishbone slave interface	(change after connecting WBS to the inputs)
signal registers_address_in_s		: std_logic_vector (Add_width_g -1 downto 0)	:=(others => '0'); 	-- reg address line
signal wr_en_s             			: std_logic		:= '1'; 								-- write enable: '1' for write, '0' for read
signal registers_data_in_s 			: std_logic_vector (data_width_g-1 downto 0)	:=(others => '0'); 	-- data sent from WS to registers (trigg pos, trigg type, enable, clk to start)
signal registers_valid_in_s			: std_logic		:= '0'; 								-- validity of the data directed from WS
-- wishbone master interface----
signal wm_end_out					: std_logic		:= '0'; 								--when '1' WM ended a transaction or reseted by watchdog ERR_I signal

--bus side signals----------------

--connecting core master to external slave signals

signal WM_TO_WS_ADR						: std_logic_vector (Add_width_g-1 downto 0)	:=(others => '0'); --contains the addr word
signal WM_TO_WS_DAT						: std_logic_vector (data_width_g-1 downto 0)	:=(others => '0'); --contains the data_in word
signal WM_TO_WS_WE					: std_logic		:= '0';                     			-- '1' for write, '0' for read
signal WM_TO_WS_STB						: std_logic		:= '0';                     			-- '1' for active bus operation, '0' for no bus operation
signal WM_TO_WS_CYC						: std_logic		:= '0';                     			-- '1' for bus transmition request, '0' for no bus transmition request
signal WM_TO_WS_TGA						: std_logic_vector (type_d_g * data_width_g-1 downto 0)	:=(others => '0'); --contains the type word
signal WM_TO_WS_TGD						: std_logic_vector (len_d_g * data_width_g-1 downto 0)	:=(others => '0'); --contains the len word

---- core master bus side signals (inputs that are not connected to the slave)

signal WM_ACK_I						: std_logic		:= '0';                      			--'1' when valid data is recieved from WS or for successfull write operation in WS
signal WM_DAT_I						: std_logic_vector (data_width_g-1 downto 0)	:=(others => '0');   --data recieved from WS
signal WM_STALL_I					: std_logic		:= '0'; 								--STALL - WS is not available for transaction 
signal WM_ERR_I						: std_logic		:= '0';  								--Watchdog interrupts, resets wishbone master

----- external slave bus side signals (outputs that we check for correct process)

signal WS_ACK_O        	:  std_logic;                      				--'1' when valid data is transmited to MW or for successfull write operation 
signal WS_DAT_O     	:  std_logic_vector (data_width_g-1 downto 0);   	--data transmit to MW
signal WS_STALL_O		:  std_logic; --STALL - WS is not available for transaction 

----- external slave register side signals

signal WS_active_cycle_s	:  std_logic; --CYC_I outputed to user side
signal WS_typ_s				:  std_logic_vector ((data_width_g)*(type_d_g)-1 downto 0); -- Type
signal WS_addr_s	        :  std_logic_vector (Add_width_g-1 downto 0);    --the beginnig address in the client that the information will be written to
signal WS_len_s				:  std_logic_vector ((data_width_g)*(len_d_g)-1 downto 0);    --Length
signal WS_wr_en				:  std_logic;
signal WS_data	    		:  std_logic_vector (data_width_g-1 downto 0);    --data out to registers
signal WS_data_valid		:  std_logic;	-- data valid to registers
signal WS_reg_data       	:  std_logic_vector (data_width_g-1 downto 0); 	 --data to be transmited to the WM
signal WS_reg_data_valid 	:  std_logic;   --data to be transmited to the WM validity
signal WS_stall				:  std_logic; -- stall - suspend wishbone transaction

-------------------------------------------------  Implementation ------------------------------------------------------------

begin

internal_logic_analyzer_core_top_inst : internal_logic_analyzer_core_top generic map (
												reset_polarity_g		=>	reset_polarity_g,
												enable_polarity_g		=>	enable_polarity_g,
												signal_ram_depth_g		=>	signal_ram_depth_g,
												signal_ram_width_g		=>	signal_ram_width_g,
												record_depth_g			=>	record_depth_g,
												data_width_g            =>	data_width_g,
												Add_width_g  		    =>	Add_width_g,
												num_of_signals_g		=>	num_of_signals_g,
												width_in_g				=>	data_width_g,
												power2_out_g			=>	power2_out_g,
												power_sign_g			=>	power_sign_g,
												type_d_g				=>	type_d_g,
												len_d_g					=>	len_d_g,
												addr_bits_g				=>	record_depth_g
												
												
												)
										port map (
												clk						=>	clk,
												rst						=>	rst,
												data_in					=>	data_in,
												trigger					=>	trigger,
												registers_address_in_s	=>	registers_address_in_s,
												wr_en_s             	=>	wr_en_s,
												registers_data_in_s 	=>	registers_data_in_s,
												registers_valid_in_s	=>	registers_valid_in_s,
												wm_end_out				=>	wm_end_out,
												
												ADR_O					=>	WM_TO_WS_ADR,
												DAT_O					=>	WM_TO_WS_DAT,
												WE_O					=>	WM_TO_WS_WE,
												STB_O					=>	WM_TO_WS_STB,
												CYC_O					=>	WM_TO_WS_CYC,
												TGA_O					=>	WM_TO_WS_TGA,
												TGD_O					=>	WM_TO_WS_TGD,
												
												ACK_I					=>	WM_ACK_I,
												DAT_I					=>	WM_DAT_I,
												STALL_I					=>	WM_STALL_I,
												ERR_I					=>	WM_ERR_I
												);

wishbone_slave_inst : wishbone_slave generic map (
											reset_activity_polarity_g  	=>	reset_polarity_g,
											data_width_g        		=>	data_width_g,
											type_d_g					=>	1,					--Type Depth. type is the client which the data is directed to
											Add_width_g    				=>	Add_width_g,		--width of addr word in the WB
											len_d_g						=>	1					--Length Depth. length of the data (in words)
										)
										port map (
											clk				=> clk,								--system clock
											reset			=> rst, 							--system reset   
		
											ADR_I          	=> WM_TO_WS_ADR,							--contains the addr word
											DAT_I          	=> WM_TO_WS_DAT,							--contains the data_in word
											WE_I           	=> WM_TO_WS_WE,                 			-- '1' for write, '0' for read
											STB_I          	=> WM_TO_WS_STB,                   		-- '1' for active bus operation, '0' for no bus operation
											CYC_I          	=> WM_TO_WS_CYC,                   		-- '1' for bus transmition request, '0' for no bus transmition request
											TGA_I          	=> WM_TO_WS_TGA,							--contains the type word
											TGD_I          	=> WM_TO_WS_TGD,							--contains the len word
											ACK_O          	=> WS_ACK_O,        					--'1' when valid data is transmited to MW or for successfull write operation 
											DAT_O          	=> WS_DAT_O,							--data transmit to MW
											STALL_O			=> WS_STALL_O,
--											
											typ				=> WS_typ_s, 	-- Type	
											addr	        => WS_addr_s,  --the beginnig address in the client that the information will be written to
											len				=> WS_len_s,   --Length
											wr_en			=> WS_wr_en,
											ws_data	    	=> WS_data,   --data out to registers
											ws_data_valid	=> WS_data_valid,	-- data valid to registers
											reg_data       	=> WS_reg_data,	 --data to be transmited to the WM
											reg_data_valid 	=> WS_reg_data_valid,  --data to be transmited to the WM validity
											active_cycle	=> WS_active_cycle_s,	--CYC_I outputed to user side
											stall			=> WS_stall
										);												
												
												
-------------------------------------------------  processes ------------------------------------------------------------

clk_proc : 
	clk <= not clk after 50 ns;
	
res_proc :
	rst <= reset_polarity_g, not reset_polarity_g after 120 ns ;
	
registers_proc :
	wr_en_s             	<= '1';				-- write enable: '1' for write, '0' for read
	registers_address_in_s	<= std_logic_vector(to_unsigned( 1 , Add_width_g)), std_logic_vector(to_unsigned( 2 , Add_width_g)) after 400 ns, std_logic_vector(to_unsigned( 3 , Add_width_g)) after 700 ns, std_logic_vector(to_unsigned( 0 , Add_width_g)) after 1000 ns,std_logic_vector(to_unsigned( 4 , Add_width_g)) after 1400 ns;	-- reg address line
	registers_data_in_s 	<= std_logic_vector(to_unsigned( 1 , data_width_g)), std_logic_vector(to_unsigned( 50 , data_width_g)) after 400 ns, std_logic_vector(to_unsigned( 7 , data_width_g)) after 700 ns, std_logic_vector(to_unsigned( 1 , data_width_g)) after 1000 ns; 	-- data sent from WS to registers (trigg pos, trigg type, enable, clk to start)
	registers_valid_in_s	<= '0','1' after 200 ns,'0' after 300 ns,'1' after 400 ns,'0' after 500 ns, '1' after 700 ns,'0' after 800 ns, '1' after 1000 ns,'0' after 1100 ns, '1' after 1300 ns, '0' after 1400 ns,'1' after 2500 ns, '0' after 2600 ns; 
	
trigg_proc :
	trigger <= '0','1' after 780 ns, '0' after 1000 ns, '1' after 3100 ns, '0' after 5300 ns, '1' after 7500 ns;

data_proc : process 
	begin
		for idx in 0 to read_loop_iter_g  - 1 loop
			wait until rising_edge(clk);
			data_in 	<= std_logic_vector (to_unsigned(idx, num_of_signals_g )); 	--Input data 
		end loop;
		wait;
	end process data_proc;	

WM_BUS_proc :	--(we do not get the data from WS)
	WM_ACK_I				<= '0';            	--'1' when valid data is recieved from WS or for successfull write operation in WS
	WM_DAT_I				<= (others => '0'); --data recieved from WS
	WM_STALL_I				<= '0';  			--STALL - WS is not available for transaction 
	WM_ERR_I				<= '0';   			--Watchdog interrupts, resets wishbone master

WS_register_side_input_proc :
--- we do not output data to another WM
	WS_reg_data       	<= (others => '0'); 	 --data to be transmited to the WM
	WS_reg_data_valid 	<=  '0';   --data to be transmited to the WM validity
	WS_stall			<=  '0'; -- stall - suspend wishbone transaction

end architecture arc_internal_logic_analyzer_core_top_tb;