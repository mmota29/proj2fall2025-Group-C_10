-- tb_RegFile.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a testbench for RegFile.
--
-- Author: Gage Baker
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_RegFile is

end tb_RegFile;

architecture struct of tb_RegFile is

	signal s_clk	: std_logic;
	signal s_rst	: std_logic; --Clear regs
	signal s_en	: std_logic; --To enable writing to register
	signal s_rs1_ad : std_logic_vector(4 downto 0); --Address of register 1
	signal s_rs2_ad : std_logic_vector(4 downto 0); --Address of register 2
	signal s_rd_ad	: std_logic_vector(4 downto 0); --Read address
	signal s_rd_data : std_logic_vector(31 downto 0); --Read data
	signal s_rs1_data : std_logic_vector(31 downto 0); --Data of register 1
	signal s_rs2_data : std_logic_vector(31 downto 0); --Data of register 2

	constant PERIOD : time := 10 ns;

begin

	DUT: entity work.RegFile
		port map (
			clk	=>	s_clk,
			rst	=>	s_rst,
			en	=>	s_en,
			rs1_ad	=>	s_rs1_ad,
			rs2_ad	=>	s_rs2_ad,
			rd_ad	=>	s_rd_ad,
			rd_data	=>	s_rd_data,
			rs1_data	=>	s_rs1_data,
			rs2_data	=>	s_rs2_data
		);
	clock: process --Got help here
	begin
		while true loop
			s_clk <= '0'; wait for PERIOD / 2;
			s_clk <= '1'; wait for PERIOD / 2;
		end loop;
	end process;

	testbench: process
	begin
		s_rst <= '1';
		s_en <= '0';
		wait for 2*PERIOD;
		s_rst <= '0';
		wait for PERIOD;

		-- TEST CASE 1: write to x1 with 0x12345678
		s_en <= '1'; --enable write to flip flop
		s_rd_ad <= "00001"; --Calling address 1 (x1)
		s_rd_data <= x"12345678"; --Assign data
		wait for PERIOD; --Wait for edge
		s_en <= '0'; --disable write
		s_rs1_ad <= "00001";
		s_rs2_ad <= "00000";
		wait for PERIOD; --Wait again

		--EXPECTED: register 1 (x1) should have value 0x12345678, 
		--and register 2 (x0) should still be empty.

end process;
end struct;