library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity IF_ID_reg is
  generic(N : integer := DATA_WIDTH);
  port(
    clk       : in  std_logic;
    rst       : in  std_logic;
    iPC_plus4 : in  std_logic_vector(N-1 downto 0);
    iInst     : in  std_logic_vector(N-1 downto 0);
    oPC_plus4 : out std_logic_vector(N-1 downto 0);
    oInst     : out std_logic_vector(N-1 downto 0)
  );
end entity IF_ID_reg;

architecture rtl of IF_ID_reg is
  signal rPC_plus4 : std_logic_vector(N-1 downto 0);
  signal rInst     : std_logic_vector(N-1 downto 0);
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rPC_plus4 <= (others => '0');
        rInst     <= (others => '0');
      else
        rPC_plus4 <= iPC_plus4;
        rInst     <= iInst;
      end if;
    end if;
  end process;

  oPC_plus4 <= rPC_plus4;
  oInst     <= rInst;

end architecture rtl;
