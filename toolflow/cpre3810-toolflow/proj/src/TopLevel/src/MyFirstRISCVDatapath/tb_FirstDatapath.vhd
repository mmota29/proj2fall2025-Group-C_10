--tb_FirstDatapath.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array32_pkg.all;

entity tb_FirstDatapath is
end tb_FirstDatapath;

architecture sim of tb_FirstDatapath is
	signal clk	: std_logic := '0';
	signal rst	: std_logic := '0';
	signal en	: std_logic;
	signal n_AddSub	: std_logic;
	signal ALUSrc	: std_logic;
	signal rs1_addr : std_logic_vector(4 downto 0);
	signal rs2_addr	: std_logic_vector(4 downto 0);
	signal rd_addr	: std_logic_vector(4 downto 0);
	signal imm	: std_logic_vector(31 downto 0);
	signal reg_out	: array32_array;
	signal result	: std_logic_vector(31 downto 0);
	
	constant PERIOD : time := 100 ns;

begin
	UUT: entity work.FirstDatapath
		port map (
		clk => clk,
		rst => rst,
		en => en,
		n_AddSub => n_AddSub,
		ALUSrc => ALUSrc,
		rs1_addr => rs1_addr,
		rs2_addr => rs2_addr,
		rd_addr => rd_addr,
		imm => imm,
		reg_out => reg_out,
		result => result
		);

	clock: process
	begin
	while true loop
		clk <= '0';
		wait for PERIOD / 2;
		clk <= '1';
		wait for PERIOD / 2;
	end loop;
	end process;

	testbench: process
	begin
		-- initialize
		rst <= '1';
		en <= '0';
		wait for PERIOD;
		rst <= '0';
		
		--addi x1, x0, 1
		en <= '1';
		n_AddSub <= '0';
		ALUSrc <= '1';
		rs1_addr <= "00000";
		rs2_addr <= "00000";
		rd_addr <= "00001";
		imm <= x"00000001";
		wait for PERIOD;

		--addi x2, x0, 2
		rd_addr <= "00010";
		imm <= x"00000002";
		wait for PERIOD;

		--addi x3, x0, 3
		rd_addr <= "00011";
		imm <= x"00000003";
		wait for PERIOD;

		--addi x4, x0, 4
		rd_addr <= "00100";
		imm <= x"00000004";
		wait for PERIOD;

		--addi x5, x0, 5
		rd_addr <= "00101";
		imm <= x"00000005";
		wait for PERIOD;

		--addi x6, x0, 6
		rd_addr <= "00110";
		imm <= x"00000006";
		wait for PERIOD;

		--addi x7, x0, 7
		rd_addr <= "00111";
		imm <= x"00000007";
		wait for PERIOD;

		--addi x8, x0, 8
		rd_addr <= "01000";
		imm <= x"00000008";
		wait for PERIOD;

		--addi x9, x0, 9
		rd_addr <= "01001";
		imm <= x"00000009";
		wait for PERIOD;


		--addi x10, x0, 10
		rd_addr <= "01010";
		imm <= x"0000000a";
		wait for PERIOD;

		--add x11, x1, x2
		n_AddSub <= '0';
		ALUSrc <= '0';
		rs1_addr <= "00001";
		rs2_addr <= "00010";
		rd_addr <= "01011";
		imm <= x"00000000";
		wait for PERIOD;
		--x11 = 1 + 2 = 3

		--sub x12, x11, x3
		n_AddSub <= '1';
		rs1_addr <= "01011";
		rs2_addr <= "00011";
		rd_addr <= "01100";
		wait for PERIOD;
		--x12 = 3 - 3 = 0

		--add x13, x12, x4
		n_AddSub <= '0';
		rs1_addr <= "01100";
		rs2_addr <= "00100";
		rd_addr <= "01101";
		wait for PERIOD;
		--x13 = 0 + 4 = 4

		--sub x14, x13, x5
		n_AddSub <= '1';
		rs1_addr <= "01101";
		rs2_addr <= "00101";
		rd_addr <= "01110";
		wait for PERIOD;
		--x14 = 4 - 5 = -1

		--add x15, x14, x6
		n_AddSub <= '0';
		rs1_addr <= "01110";
		rs2_addr <= "00110";
		rd_addr <= "01111";
		wait for PERIOD;
		--x15 = -1 + 6 = 5

		--sub x16, x15, x7
		n_AddSub <= '1';
		rs1_addr <= "01111";
		rs2_addr <= "00111";
		rd_addr <= "10000";
		wait for PERIOD;
		--x16 = 5 - 7 = -2

		--add x17, x16, x8
		n_AddSub <= '0';
		rs1_addr <= "10000";
		rs2_addr <= "01000";
		rd_addr <= "10001";
		wait for PERIOD;
		--x17 = -2 + 8 = 6

		--sub x18, x17, x9
		n_AddSub <= '1';
		rs1_addr <= "10001";
		rs2_addr <= "01001";
		rd_addr <= "10010";
		wait for PERIOD;
		--x18 = 6 - 9 = -3

		--add x19, x18, x10
		n_AddSub <= '0';
		rs1_addr <= "10010";
		rs2_addr <= "01010";
		rd_addr <= "10011";
		wait for PERIOD;
		--x19 = -3 + 10 = 7
		
		--addi x20, zero, -35
		ALUSrc <= '1';
		n_AddSub <= '0';
		rs1_addr <= "00000";
		rs2_addr <= "00000";
		rd_addr <= "10100";
		imm <= x"FFFFFFDC";
		wait for PERIOD;
		--x20 = -35

		--add x21, x19, x20
		ALUSrc <= '0';
		rs1_addr <= "10011";
		rs2_addr <= "10100";
		rd_addr <= "10101";
		imm <= x"00000000";
		wait for PERIOD;
		--x21 = 7 + -35 = -28 = 0xFFFFFFE3

		en <= '0'; -- stop writing
		wait;
	end process;
end sim;