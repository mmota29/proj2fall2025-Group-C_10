--mux32to1_32.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array32_pkg.all;

entity mux32to1_32 is

port (
	sel : in std_logic_vector(4 downto 0);
	m_in : in array32_array;
	m_out: out std_logic_vector(31 downto 0)
	);
end entity;

architecture struct of mux32to1_32 is

begin

	m_out <= m_in(to_integer(unsigned(sel)));

end struct;