
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv_cpu_sw is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    instr    : in  std_logic_vector(31 downto 0);
    imem_addr: out std_logic_vector(31 downto 0);

    daddr     : out std_logic_vector(31 downto 0);
    dwdata    : out std_logic_vector(31 downto 0);
    drdata    : in  std_logic_vector(31 downto 0);
    dwrite    : out std_logic
  );
end entity;

architecture rtl of riscv_cpu_sw is

  signal pc, next_pc : std_logic_vector(31 downto 0);

  signal opcode : std_logic_vector(6 downto 0);
  signal funct3 : std_logic_vector(2 downto 0);
  signal funct7 : std_logic_vector(6 downto 0);

  signal rs1_ad, rs2_ad, rd_ad : std_logic_vector(4 downto 0);
  signal rs1_data, rs2_data    : std_logic_vector(31 downto 0);
  signal imm                   : std_logic_vector(31 downto 0);

  signal ASel, BSel : std_logic;
  signal ALUOp      : std_logic_vector(3 downto 0);
  signal RegWrite   : std_logic;
  signal MemRead    : std_logic;
  signal MemWrite   : std_logic;
  signal MemToReg   : std_logic_vector(1 downto 0);
  signal Branch     : std_logic_vector(1 downto 0);
  signal Jump       : std_logic;

  signal ALU_A, ALU_B, ALU_Result : std_logic_vector(31 downto 0);
  signal Zero : std_logic;

begin

  --------------------------------------------------------------------------
  -- FETCH
  --------------------------------------------------------------------------
  imem_addr <= pc;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        pc <= x"00000000";
      else
        pc <= next_pc;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- INSTRUCTION DECODE
  --------------------------------------------------------------------------
  opcode <= instr(6 downto 0);
  funct3 <= instr(14 downto 12);
  funct7 <= instr(31 downto 25);

  rs1_ad <= instr(19 downto 15);
  rs2_ad <= instr(24 downto 20);
  rd_ad  <= instr(11 downto 7);

  --------------------------------------------------------------------------
  -- CONTROL
  --------------------------------------------------------------------------
  U_CTRL: entity work.control_unit_sw
    port map (
      opcode => opcode,
      funct3 => funct3,
      funct7 => funct7,

      ASel    => ASel,
      BSel    => BSel,
      ImmSel  => open, -- this SW version uses imm_gen alone
      ALUOp   => ALUOp,
      RegWrite=> RegWrite,
      MemRead => MemRead,
      MemWrite=> MemWrite,
      MemToReg=> MemToReg,
      Branch  => Branch,
      Jump    => Jump
    );

  --------------------------------------------------------------------------
  -- IMMEDIATE
  --------------------------------------------------------------------------
  U_IMM: entity work.imm_gen
    port map (
      instr   => instr,
      imm_out => imm
    );

  --------------------------------------------------------------------------
  -- REGISTER FILE
  --------------------------------------------------------------------------
  U_REG: entity work.RegFile
    port map (
      clk => clk,
      rst => rst,
      en  => RegWrite,
      rs1_ad => rs1_ad,
      rs2_ad => rs2_ad,
      rd_ad  => rd_ad,
      rd_data => ALU_Result,
      rs1_data => rs1_data,
      rs2_data => rs2_data
    );

  --------------------------------------------------------------------------
  -- ALU INPUT MUXES
  --------------------------------------------------------------------------
  ALU_A <= pc when ASel = '1' else rs1_data;
  ALU_B <= imm when BSel = '1' else rs2_data;

  U_ALU: entity work.ALU
    port map (
      A => ALU_A,
      B => ALU_B,
      ALUOp => ALUOp,
      Result => ALU_Result,
      Zero => Zero
    );

  --------------------------------------------------------------------------
  -- DATA MEMORY
  --------------------------------------------------------------------------
  daddr <= ALU_Result;
  dwdata <= rs2_data;
  dwrite <= MemWrite;

  --------------------------------------------------------------------------
  -- NEXT PC
  --------------------------------------------------------------------------
  process(pc, imm, Zero, Branch, Jump)
  begin
    if Jump = '1' then
      next_pc <= std_logic_vector(unsigned(pc) + unsigned(imm));
    elsif Branch = "01" and Zero = '1' then
      next_pc <= std_logic_vector(unsigned(pc) + unsigned(imm));
    else
      next_pc <= std_logic_vector(unsigned(pc) + 4);
    end if;
  end process;

end architecture;
