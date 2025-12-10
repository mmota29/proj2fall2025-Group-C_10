--imm_gen.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.control_pkg.all;

entity imm_gen is
  port (
    instr   : in  std_logic_vector(31 downto 0);
    ImmSel  : in  std_logic_vector(2 downto 0);
    imm_out : out std_logic_vector(31 downto 0)
  );
end entity;

architecture struct of imm_gen is
begin
  process(instr, ImmSel)
    variable imm_v : signed(31 downto 0);
  begin
    imm_v := (others => '0');

    case ImmSel is

      when IMM_I =>
        imm_v := resize(signed(instr(31 downto 20)), 32);

      when IMM_S =>
        imm_v := resize(signed(instr(31 downto 25) & instr(11 downto 7)), 32);

      when IMM_B =>
        imm_v := resize(signed(instr(31) & instr(7) &
                               instr(30 downto 25) &
                               instr(11 downto 8) & '0'), 32);

      when IMM_U =>
        imm_v := signed(instr(31 downto 12) & x"000");

      when IMM_J =>
        imm_v := resize(signed(instr(31) &
                               instr(19 downto 12) &
                               instr(20) &
                               instr(30 downto 21) & '0'), 32);

      when others =>
        imm_v := (others => '0');
    end case;

    imm_out <= std_logic_vector(imm_v);
  end process;
end struct;
