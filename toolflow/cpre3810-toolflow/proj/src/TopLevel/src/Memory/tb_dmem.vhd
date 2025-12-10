--tb_dmem.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dmem is
end tb_dmem;

architecture struct of tb_dmem is

	constant DATA_WIDTH : natural := 32;
	constant ADDR_WIDTH : natural := 10;

	signal clk	: std_logic := '0';
	signal addr	: std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal data	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal we	: std_logic := '0';
	signal q	: std_logic_vector(DATA_WIDTH-1 downto 0);

	constant PERIOD : time := 100 ns;

begin
dmem: entity work.mem
	generic map (
	DATA_WIDTH => DATA_WIDTH,
	ADDR_WIDTH => ADDR_WIDTH
	)
	port map (
	clk => clk,
	addr => addr,
	data => data,
	we => we,
	q => q
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

	variable temp_vals : std_logic_vector(31 downto 0); -- needed for the looping through each hex value
	
	begin

	for i in 0 to 9 loop -- Reading initial 10 memory values (0x000 to 0x009)
		addr <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
		we <= '0';
		wait for PERIOD;
	end loop;

	for i in 0 to 9 loop -- Writing values back (0x100 to 0x109)
		addr <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
		we <= '0';
		wait for PERIOD;
		temp_vals := q;
	
		addr <= std_logic_vector(to_unsigned(256 + i, ADDR_WIDTH)); --0x100 = 256
		data <= temp_vals;
		we <= '1';
		wait for PERIOD;
		we <= '0';
	end loop;
	
	for i in 0 to 9 loop -- Reading values back (0x100 to 0x109)
		addr <= std_logic_vector(to_unsigned(256 + i, ADDR_WIDTH));
		we <= '0';
		wait for PERIOD;
	end loop;
	wait;
end process;
end struct;