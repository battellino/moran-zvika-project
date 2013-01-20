------------------------------------------------------------------------------------------------------------
-- File Name	:	write_controller_pkg.vhd
-- Generated	:	25.11.2012
-- Author		:	Moran Katz and Zvika Pery
-- Project		:	Internal Logic Analyzer
------------------------------------------------------------------------------------------------------------
-- Description: 
--				functions that will be used in the write controller.			
--				
------------------------------------------------------------------------------------------------------------
-- Revision:
--			Number		Date		Name							Description			
--			1.00		25.11.2012	Zvika Pery						Creation			
------------------------------------------------------------------------------------------------------------
--	Todo:
--		end function int2bin
--		check if row 60 is legal
--		
--		
------------------------------------------------------------------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------------------------------------------
package write_controller_pkg is

	--------------------------------------------------------------------------------------
	---------------			Function up_case		--------------------------------------
	--------------------------------------------------------------------------------------
	-- The function map a real number, that come as a fraction,  to the largest previous or the smallest following integer.
	--	up		:	numerator of the input
	--	down	:	denominator of the input
	--
	-- examples: 
	--up_case(4, 5) = 1
	--up_case(5, 5) = 1
	--up_case(6, 5) = 2
	--up_case(13, 5) = 3
	--------------------------------------------------------------------------------------
	function up_case (		constant up 	: in positive ; 				--the numerator of the fraction
							constant down	: in positive				--the denominator of the fraction
						) return positive;


	--------------------------------------------------------------------------------------
	---------------			Function int2bin		--------------------------------------
	--------------------------------------------------------------------------------------
	-- The function calculate the binary value of an integer.
	--	temp		:	input number in integer
	--
	-- examples: 
	--
	--
	--
	--
	--------------------------------------------------------------------------------------
--	function int2bin (   constant up 	: 	in natural ;				--the numerator of the fraction
--							         constant leng	:	in positive					--the length of the binary number
--						        )  return std_logic_vector ;		--is it legal??
						
end ;

package body write_controller_pkg is

	--------------------------------------------------------------------------------------
	---------------			Function up_case		--------------------------------------
	--------------------------------------------------------------------------------------
	function up_case (		constant up 	: in positive ; 			--the numerator of the fraction
		              		constant down	: in positive				--the denominator of the fraction
						        ) return positive is
						
						
	begin
		if (up = down) or (up < down) then
			return 1 ;
		else
			return 1 + up_case(up - down, down);
		end if;
	end function ;
--------------------------------------------------------------------------------------
	---------------			Function int2bin		--------------------------------------
	--------------------------------------------------------------------------------------

-- function int2bin (   constant up 	: 	in natural ;				--the numerator of the fraction
--							        constant leng	:	in positive					--the length of the binary number
--	         				  	)   return std_logic_vector is
--      variable  result      : std_logic_vector( leng - downto 0 );
--      variable  current_bit : std_logic;

--  begin
  
  
--    return result;
  
--  end function ;

--use ieee.numeric_std.all;
--my_slv <= std_logic_vector(to_unsigned(my_integer, my_slv'length));




end package body write_controller_pkg;

