--array32_pkg.vhd
library ieee;
use ieee.std_logic_1164.all;

package array32_pkg is
	subtype array32 is std_logic_vector(31 downto 0);
	type array32_array is array (0 to 31) of array32;
end package;