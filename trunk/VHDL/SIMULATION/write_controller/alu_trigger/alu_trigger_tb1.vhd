LIBRARY ieee  ; 
LIBRARY std  ; 
LIBRARY work  ; 
USE ieee.NUMERIC_STD.all  ; 
USE ieee.std_logic_1164.all  ; 
USE ieee.STD_LOGIC_SIGNED.all  ; 
USE ieee.std_logic_textio.all  ; 
USE ieee.STD_LOGIC_UNSIGNED.all  ; 
USE ieee.std_logic_unsigned.all  ; 
USE std.textio.all  ; 
USE work.write_controller_pkg.all  ; 
ENTITY alu_trigger_tb1  IS 
  GENERIC (
    reset_polarity_g  : STD_LOGIC   := '1' ;  
    record_depth_g  : POSITIVE   := 10 ;  
    Add_width_g  : POSITIVE   := 8 ;  
    signal_ram_depth_g  : POSITIVE   := 10 ); 
END ; 
 
ARCHITECTURE alu_trigger_tb1_arch OF alu_trigger_tb1 IS
  SIGNAL system_status   :  STD_LOGIC  ; 
  SIGNAL addr_in_alu   :  std_logic_vector (Add_width_g - 1 downto 0)  ; 
  SIGNAL reset   :  STD_LOGIC  ; 
  SIGNAL end_array_row_out   :  INTEGER  ; 
  SIGNAL trigger   :  STD_LOGIC  ; 
  SIGNAL trigger_type   :  std_logic_vector (2 downto 0)  ; 
  SIGNAL trigger_position   :  std_logic_vector (6 downto 0)  ; 
  SIGNAL wc_to_rc   :  std_logic_vector (2 * Add_width_g - 1 downto 0)  ; 
  SIGNAL start_array_row_in   :  INTEGER  ; 
  SIGNAL clk   :  STD_LOGIC  ; 
  SIGNAL start_array_row_out   :  INTEGER  ; 
  SIGNAL trigger_found   :  STD_LOGIC  ; 
  COMPONENT alu_trigger  
    GENERIC ( 
      reset_polarity_g  : STD_LOGIC ; 
      record_depth_g  : POSITIVE ; 
      Add_width_g  : POSITIVE ; 
      signal_ram_depth_g  : POSITIVE  );  
    PORT ( 
      system_status  : in STD_LOGIC ; 
      addr_in_alu  : in std_logic_vector (Add_width_g - 1 downto 0) ; 
      reset  : in STD_LOGIC ; 
      end_array_row_out  : out INTEGER ; 
      trigger  : in STD_LOGIC ; 
      trigger_type  : in std_logic_vector (2 downto 0) ; 
      trigger_position  : in std_logic_vector (6 downto 0) ; 
      wc_to_rc  : out std_logic_vector (2 * Add_width_g - 1 downto 0) ; 
      start_array_row_in  : in INTEGER ; 
      clk  : in STD_LOGIC ; 
      start_array_row_out  : out INTEGER ; 
      trigger_found  : out STD_LOGIC ); 
  END COMPONENT ; 
BEGIN
  DUT  : alu_trigger  
    GENERIC MAP ( 
      reset_polarity_g  => reset_polarity_g  ,
      record_depth_g  => record_depth_g  ,
      Add_width_g  => Add_width_g  ,
      signal_ram_depth_g  => signal_ram_depth_g   )
    PORT MAP ( 
      system_status   => system_status  ,
      addr_in_alu   => addr_in_alu  ,
      reset   => reset  ,
      end_array_row_out   => end_array_row_out  ,
      trigger   => trigger  ,
      trigger_type   => trigger_type  ,
      trigger_position   => trigger_position  ,
      wc_to_rc   => wc_to_rc  ,
      start_array_row_in   => start_array_row_in  ,
      clk   => clk  ,
      start_array_row_out   => start_array_row_out  ,
      trigger_found   => trigger_found   ) ; 



-- "Constant Pattern"
-- Start Time = 0 ps, End Time = 1 ns, Period = 0 ps
  Process
	Begin
	 reset  <= '0'  ;
	wait for 1 ns ;
-- dumped values till 1 ns
	wait;
 End Process;


-- "Constant Pattern"
-- Start Time = 0 ps, End Time = 1 ns, Period = 0 ps
  Process
	Begin
	 trigger_position  <= "0000000"  ;
	wait for 1 ns ;
-- dumped values till 1 ns
	wait;
 End Process;


-- "Constant Pattern"
-- Start Time = 0 ps, End Time = 1 ns, Period = 0 ps
  Process
	Begin
	 trigger_type  <= "010"  ;
	wait for 1 ns ;
-- dumped values till 1 ns
	wait;
 End Process;


-- "Constant Pattern"
-- Start Time = 0 ps, End Time = 1 ns, Period = 0 ps
  Process
	Begin
	 system_status  <= '1'  ;
	wait for 1 ns ;
-- dumped values till 1 ns
	wait;
 End Process;


-- "Counter Pattern"(Range-Up) : step = 1 Range(00000000-11111111)
-- Start Time = 0 ps, End Time = 1 ns, Period = 100 ps
  Process
	variable VARaddr_in_alu  : std_logic_vector (7 downto 0);
	Begin
	VARaddr_in_alu  := "00000000" ;
	for repeatLength in 1 to 10
	loop
	    addr_in_alu  <= VARaddr_in_alu  ;
	   wait for 100 ps ;
	   VARaddr_in_alu  := VARaddr_in_alu  + 1 ;
	end loop;
-- 1 ns, periods remaining till edit start time.
	wait;
 End Process;


-- "Repeater Pattern" Repeat Forever
-- Start Time = 0 ps, End Time = 2 ns, Period = 270 ps
  Process
	Begin
	for Z in 1 to 3
	loop
	    trigger  <= '1'  ;
	   wait for 270 ps ;
	    trigger  <= '0'  ;
	   wait for 270 ps ;
-- 1620 ps, repeat pattern in loop.
	end  loop;
	    trigger  <= '1'  ;
	   wait for 270 ps ;
-- 1890 ps, periods remaining till edit start time.
	 trigger  <= '0'  ;
	wait for 110 ps ;
-- dumped values till 2 ns
	wait;
 End Process;
END;
