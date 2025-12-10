-- RegFile.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a 32-bit array of registers.
--
-- Author: Gage Baker
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.array32_pkg.all;

entity RegFile is

port(
	clk	: in std_logic;
	rst	: in std_logic; --Clear regs
	en	: in std_logic; --To enable writing to register
	rs1_ad : in std_logic_vector(4 downto 0); --Address of register 1
	rs2_ad : in std_logic_vector(4 downto 0); --Address of register 2
	rd_ad	: in std_logic_vector(4 downto 0); --Read address
	rd_data	: in std_logic_vector(31 downto 0); --Read data
	rs1_data : out std_logic_vector(31 downto 0); --Data of register 1
	rs2_data : out std_logic_vector(31 downto 0); --Data of register 2
	reg_out : out array32_array
);

end RegFile;

architecture mixed of RegFile is

signal reg : array32_array;

begin
process (clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			for i in 0 to 31 loop
				reg(i) <= (others => '0'); -- Assign all to 0 if reset
			end loop;
		elsif en = '1' and rd_ad /= "00000" then --If not x0 and en is 1:
			reg(to_integer(unsigned(rd_ad))) <= rd_data;
		end if;
	end if;
end process;

rs1_data <= (others => '0') when rs1_ad = "00000" else
	reg(to_integer(unsigned(rs1_ad)));
rs2_data <= (others => '0') when rs2_ad = "00000" else
	reg(to_integer(unsigned(rs2_ad)));

reg_out <= reg;

end mixed;