--FirstDatapath.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.array32_pkg.all;

entity FirstDatapath is
	port (
	clk	: in std_logic;
	rst	: in std_logic;
	en	: in std_logic;
	n_AddSub	: in std_logic;
	ALUSrc	: in std_logic;
	rs1_addr	: in std_logic_vector(4 downto 0);
	rs2_addr	: in std_logic_vector(4 downto 0);
	rd_addr	: in std_logic_vector(4 downto 0);
	imm	: in std_logic_vector(31 downto 0);
	reg_out : out array32_array;
	result	: out std_logic_vector(31 downto 0)
	);
end FirstDatapath;

architecture datapath of FirstDatapath is
	signal rs1_data : std_logic_vector(31 downto 0);
	signal rs2_data : std_logic_vector(31 downto 0);
	signal alu_inb : std_logic_vector(31 downto 0);
	signal alu_out : std_logic_vector(31 downto 0);

begin
	DUT0: entity work.RegFile
		port map (
		clk => clk,
		rst => rst,
		en => en,
		rs1_ad => rs1_addr,
		rs2_ad => rs2_addr,
		rd_ad => rd_addr,
		rd_data => alu_out,
		rs1_data => rs1_data,
		rs2_data => rs2_data,
		reg_out => reg_out
		);

	process(ALUSrc, rs2_data, imm)
	begin

		if ALUSrc = '0' then
			alu_inb <= rs2_data;
		else
			alu_inb <= imm;
		end if;
	end process;

	process(rs1_data, alu_inb, n_AddSub)
	begin
		if n_AddSub = '0' then
			alu_out <= std_logic_vector(signed(rs1_data) + signed(alu_inb));
		else
			alu_out <= std_logic_vector(signed(rs1_data) - signed(alu_inb));
		end if;
	end process;

	result <= alu_out;

end datapath;
