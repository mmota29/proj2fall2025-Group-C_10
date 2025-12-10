library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package control_pkg is
  -- ALU operations (4-bit encoding used by the ALU)
  constant ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
  constant ALU_SUB  : std_logic_vector(3 downto 0) := "0001";
  constant ALU_AND  : std_logic_vector(3 downto 0) := "0010";
  constant ALU_OR   : std_logic_vector(3 downto 0) := "0011";
  constant ALU_XOR  : std_logic_vector(3 downto 0) := "0100";
  constant ALU_SLT  : std_logic_vector(3 downto 0) := "0101"; -- signed less-than
  constant ALU_SLTU : std_logic_vector(3 downto 0) := "0110"; -- unsigned less-than
  constant ALU_SLL  : std_logic_vector(3 downto 0) := "0111";
  constant ALU_SRL  : std_logic_vector(3 downto 0) := "1000";
  constant ALU_SRA  : std_logic_vector(3 downto 0) := "1001";
  constant ALU_PASSB: std_logic_vector(3 downto 0) := "1111"; -- pass-through B (used by LUI)

  -- Immediate type selector (3-bit)
  -- 000: none, 001:I, 010:S, 011:B, 100:U, 101:J
  constant IMM_NONE : std_logic_vector(2 downto 0) := "000";
  constant IMM_I    : std_logic_vector(2 downto 0) := "001";
  constant IMM_S    : std_logic_vector(2 downto 0) := "010";
  constant IMM_B    : std_logic_vector(2 downto 0) := "011";
  constant IMM_U    : std_logic_vector(2 downto 0) := "100";
  constant IMM_J    : std_logic_vector(2 downto 0) := "101";

  -- MemToReg: 00=ALU, 01=Load, 10=PC+4
  constant M2R_ALU  : std_logic_vector(1 downto 0) := "00";
  constant M2R_MEM  : std_logic_vector(1 downto 0) := "01";
  constant M2R_PC4  : std_logic_vector(1 downto 0) := "10";

  -- Load size: 00=byte, 01=half, 10=word
  constant LSZ_BYTE : std_logic_vector(1 downto 0) := "00";
  constant LSZ_HALF : std_logic_vector(1 downto 0) := "01";
  constant LSZ_WORD : std_logic_vector(1 downto 0) := "10";

  -- Branch field: 000 none, 001 BEQ, 010 BNE, 011 BLT, 100 BGE, 101 BLTU, 110 BGEU
  constant BR_NONE  : std_logic_vector(2 downto 0) := "000";
  constant BR_BEQ   : std_logic_vector(2 downto 0) := "001";
  constant BR_BNE   : std_logic_vector(2 downto 0) := "010";
  constant BR_BLT   : std_logic_vector(2 downto 0) := "011";
  constant BR_BGE   : std_logic_vector(2 downto 0) := "100";
  constant BR_BLTU  : std_logic_vector(2 downto 0) := "101";
  constant BR_BGEU  : std_logic_vector(2 downto 0) := "110";

  -- PCSel: 00=PC+4, 01=branch_target, 10=jal_target, 11=jalr_target
  constant PC_PC4   : std_logic_vector(1 downto 0) := "00";
  constant PC_BR    : std_logic_vector(1 downto 0) := "01";
  constant PC_JAL   : std_logic_vector(1 downto 0) := "10";
  constant PC_JALR  : std_logic_vector(1 downto 0) := "11";

  -- Opcodes (LSB..MSB)
  constant OP_R     : std_logic_vector(6 downto 0) := "0110011";
  constant OP_I     : std_logic_vector(6 downto 0) := "0010011";
  constant OP_LOAD  : std_logic_vector(6 downto 0) := "0000011";
  constant OP_STORE : std_logic_vector(6 downto 0) := "0100011";
  constant OP_BRANCH: std_logic_vector(6 downto 0) := "1100011";
  constant OP_LUI   : std_logic_vector(6 downto 0) := "0110111";
  constant OP_AUIPC : std_logic_vector(6 downto 0) := "0010111";
  constant OP_JAL   : std_logic_vector(6 downto 0) := "1101111";
  constant OP_JALR  : std_logic_vector(6 downto 0) := "1100111";
  constant OP_SYS   : std_logic_vector(6 downto 0) := "1110011";
end package;
