library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity EX_MEM_reg is
  generic(N : integer := DATA_WIDTH);
  port(
    clk        : in  std_logic;
    rst        : in  std_logic;

    i_ALUOut   : in  std_logic_vector(N-1 downto 0);
    i_rs2_data : in  std_logic_vector(N-1 downto 0);
    i_rd       : in  std_logic_vector(4 downto 0);

    i_RegWrite : in  std_logic;
    i_MemRead  : in  std_logic;
    i_MemWrite : in  std_logic;
    i_MemToReg : in  std_logic_vector(1 downto 0);
    i_Halt     : in  std_logic;

    o_ALUOut   : out std_logic_vector(N-1 downto 0);
    o_rs2_data : out std_logic_vector(N-1 downto 0);
    o_rd       : out std_logic_vector(4 downto 0);

    o_RegWrite : out std_logic;
    o_MemRead  : out std_logic;
    o_MemWrite : out std_logic;
    o_MemToReg : out std_logic_vector(1 downto 0);
    o_Halt     : out std_logic
  );
end entity EX_MEM_reg;

architecture rtl of EX_MEM_reg is
  signal r_ALUOut   : std_logic_vector(N-1 downto 0);
  signal r_rs2_data : std_logic_vector(N-1 downto 0);
  signal r_rd       : std_logic_vector(4 downto 0);

  signal r_RegWrite : std_logic;
  signal r_MemRead  : std_logic;
  signal r_MemWrite : std_logic;
  signal r_MemToReg : std_logic_vector(1 downto 0);
  signal r_Halt     : std_logic;
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r_ALUOut   <= (others => '0');
        r_rs2_data <= (others => '0');
        r_rd       <= (others => '0');

        r_RegWrite <= '0';
        r_MemRead  <= '0';
        r_MemWrite <= '0';
        r_MemToReg <= (others => '0');
        r_Halt     <= '0';
      else
        r_ALUOut   <= i_ALUOut;
        r_rs2_data <= i_rs2_data;
        r_rd       <= i_rd;

        r_RegWrite <= i_RegWrite;
        r_MemRead  <= i_MemRead;
        r_MemWrite <= i_MemWrite;
        r_MemToReg <= i_MemToReg;
        r_Halt     <= i_Halt;
      end if;
    end if;
  end process;

  o_ALUOut   <= r_ALUOut;
  o_rs2_data <= r_rs2_data;
  o_rd       <= r_rd;

  o_RegWrite <= r_RegWrite;
  o_MemRead  <= r_MemRead;
  o_MemWrite <= r_MemWrite;
  o_MemToReg <= r_MemToReg;
  o_Halt     <= r_Halt;

end architecture rtl;
