--fetch_unit.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.control_pkg.all;

entity fetch_unit is
	generic (
	START_PC : std_logic_vector(31 downto 0) := x"00000100"
	);

	port (
	clk	: in std_logic;
	rst 	: in std_logic;
	pcSel	: in std_logic_vector(1 downto 0);
	branch_tgt	: in std_logic_vector(31 downto 0);
	jalr_tgt	: in std_logic_vector(31 downto 0);
	jump_tgt	: in std_logic_vector(31 downto 0);
	instr	: out std_logic_vector(31 downto 0);
	pc	: out std_logic_vector(31 downto 0)
	);
end fetch_unit;

architecture struct of fetch_unit is
	signal pc_reg : std_logic_vector(31 downto 0) := x"00000100";
	signal pc_next	: std_logic_vector(31 downto 0);

	constant START_ADDR : integer := to_integer(unsigned(START_PC(9 downto 2)));

	type imem_t is array (0 to 255) of std_logic_vector(31 downto 0);

	--This function reads from an instruction file
	impure function init_imem return imem_t is
	file f : text open read_mode is "instruction.hex";
	variable L : line;
	variable temp : std_logic_vector(31 downto 0);
	variable mem : imem_t := (others => (others => '0'));
	variable i : integer := 0;
	begin
	
	while not endfile(f) loop
	readline(f,L);
	hread(L, temp);
	mem(i) := temp;
	i := i + 1;
	end loop;
	return mem;
	end function;
	
	signal imem : imem_t := init_imem;

begin


	process(clk)
	begin
	if rising_edge(clk) then
		if rst = '1' then
			pc_reg <= START_PC;
		else
			pc_reg <= pc_next;
		end if;
	end if;
	end process;
	
	process(pcSel, pc_reg, branch_tgt, jump_tgt, jalr_tgt)
	begin
	case pcSel is
		when PC_PC4 => pc_next <= std_logic_vector(unsigned(pc_reg) + 4);
		when PC_BR => pc_next <= branch_tgt;
		when PC_JAL => pc_next <= jump_tgt;
		when PC_JALR => pc_next <= jalr_tgt;
		when others => pc_next <= std_logic_vector(unsigned(pc_reg) + 4);
	end case;
	end process;
	
	instr <= imem(to_integer(unsigned(pc_reg(9 downto 2))) - START_ADDR);
	pc <= pc_reg;
end struct;
		
	