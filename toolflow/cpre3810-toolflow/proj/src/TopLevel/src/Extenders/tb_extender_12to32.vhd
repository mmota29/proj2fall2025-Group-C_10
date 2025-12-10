--tb_extender_12to32.vhd
library ieee;
use ieee.std_logic_1164.all;

entity tb_extender_12to32 is
end tb_extender_12to32;

architecture struct of tb_extender_12to32 is
	signal s_imm12	: std_logic_vector(11 downto 0);
	signal s_sign_sel	: std_logic;
	signal s_imm32	: std_logic_vector(31 downto 0);
	constant PERIOD : time := 100 ns;
begin
	UUT: entity work.extender_12to32
	port map (
	imm12 => s_imm12,
	sign_sel => s_sign_sel,
	imm32 => s_imm32
	);

	testbench: process
	begin
	--Test 1: sign extending positive 7
	s_imm12 <= "000000000111";
	s_sign_sel <= '1';
	wait for PERIOD;
	--EXPECTED: imm32 should contain "00000000 | 00000000 | 00000000 | 00000111"

	--Test 2: sign extending negative 7
	s_imm12 <= "111111111011";
	s_sign_sel <= '1'; --doesnt matter
	wait for PERIOD;

	--Test 3: zero extend negative 7
	s_imm12 <= "111111111011";
	s_sign_sel <= '0';
	wait for PERIOD;
	
	wait;
end process;
end struct;