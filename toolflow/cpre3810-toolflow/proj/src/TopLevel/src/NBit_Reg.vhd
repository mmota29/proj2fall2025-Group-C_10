--NBit_Reg.vhd
library ieee;
use ieee.std_logic_1164.all;

entity NBit_Reg is
	port (
		clk : in std_logic;
		rst : in std_logic;
		we	: in std_logic;
		d	: in std_logic_vector(31 downto 0);
		q	: out std_logic_vector(31 downto 0)
	);
end NBit_Reg;

architecture struct of NBit_Reg is
begin
	gen_dffs : for i in 0 to 31 generate
		dff : entity work.dffg
			port map (
			i_CLK => clk,
			i_RST => rst,
			i_WE => we,
			i_D => d(i),
			O_Q => q(i)
		);
	end generate;
end struct;
