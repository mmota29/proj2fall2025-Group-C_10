library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.control_pkg.all;

entity control_unit is
  port(
    opcode  : in  std_logic_vector(6 downto 0);
    funct3  : in  std_logic_vector(2 downto 0);
    funct7  : in  std_logic_vector(6 downto 0);

    ASel    : out std_logic;
    BSel    : out std_logic;
    ImmSel  : out std_logic_vector(2 downto 0);
    ALUOp   : out std_logic_vector(3 downto 0);

    RegWrite: out std_logic;
    MemRead : out std_logic;
    MemWrite: out std_logic;
    MemToReg: out std_logic_vector(1 downto 0);

    LoadSize: out std_logic_vector(1 downto 0);
    LoadSign: out std_logic;

    Branch  : out std_logic_vector(2 downto 0);
    Jump    : out std_logic;
    Jalr    : out std_logic;
    PCSel   : out std_logic_vector(1 downto 0);

    Halt    : out std_logic
  );
end entity;

architecture rtl of control_unit is
begin
  process(opcode, funct3, funct7)
  begin
    -- Defaults
    ASel     <= '0';
    BSel     <= '0';
    ImmSel   <= IMM_NONE;
    ALUOp    <= ALU_ADD;
    RegWrite <= '0';
    MemRead  <= '0';
    MemWrite <= '0';
    MemToReg <= M2R_ALU;
    LoadSize <= LSZ_WORD;
    LoadSign <= '1';
    Branch   <= BR_NONE;
    Jump     <= '0';
    Jalr     <= '0';
    PCSel    <= PC_PC4;
    Halt     <= '0';

    case opcode is

      -----------------------------------------------------------------------
      -- R-TYPE (add, sub, and, or, xor, slt, sll, srl, sra)
      -----------------------------------------------------------------------
      when OP_R =>
        ASel <= '0'; BSel <= '0'; ImmSel <= IMM_NONE; RegWrite <= '1';
        MemToReg <= M2R_ALU;
        case funct3 is
          when "000" =>
            if funct7 = "0100000" then
              ALUOp <= ALU_SUB;
            else
              ALUOp <= ALU_ADD;
            end if;
          when "111" => ALUOp <= ALU_AND;
          when "110" => ALUOp <= ALU_OR;
          when "100" => ALUOp <= ALU_XOR;
          when "010" => ALUOp <= ALU_SLT;
          when "011" => ALUOp <= ALU_SLTU;
          when "001" => ALUOp <= ALU_SLL;
          when "101" =>
            if funct7 = "0100000" then
              ALUOp <= ALU_SRA;
            else
              ALUOp <= ALU_SRL;
            end if;
          when others => null;
        end case;

      -----------------------------------------------------------------------
      -- I-TYPE (addi, andi, ori, xori, slti, sltiu, slli/srli/srai)
      -----------------------------------------------------------------------
      when OP_I =>
        ASel <= '0'; BSel <= '1'; ImmSel <= IMM_I; RegWrite <= '1';
        MemToReg <= M2R_ALU;
        case funct3 is
          when "000" => ALUOp <= ALU_ADD;
          when "111" => ALUOp <= ALU_AND;
          when "110" => ALUOp <= ALU_OR;
          when "100" => ALUOp <= ALU_XOR;
          when "010" => ALUOp <= ALU_SLT;
          when "011" => ALUOp <= ALU_SLTU;
          when "001" => ALUOp <= ALU_SLL;
          when "101" =>
            if funct7 = "0100000" then
              ALUOp <= ALU_SRA;
            else
              ALUOp <= ALU_SRL;
            end if;
          when others => null;
        end case;

      -----------------------------------------------------------------------
      -- LOADS (lb, lh, lw, lbu, lhu)
      -----------------------------------------------------------------------
      when OP_LOAD =>
        ASel <= '0'; BSel <= '1'; ImmSel <= IMM_I; RegWrite <= '1';
        MemRead <= '1'; MemToReg <= M2R_MEM; ALUOp <= ALU_ADD;
        case funct3 is
          when "000" => LoadSize <= LSZ_BYTE; LoadSign <= '1';
          when "001" => LoadSize <= LSZ_HALF; LoadSign <= '1';
          when "010" => LoadSize <= LSZ_WORD; LoadSign <= '1';
          when "100" => LoadSize <= LSZ_BYTE; LoadSign <= '0';
          when "101" => LoadSize <= LSZ_HALF; LoadSign <= '0';
          when others => null;
        end case;

      -----------------------------------------------------------------------
      -- STORE (sw)
      -----------------------------------------------------------------------
      when OP_STORE =>
        ASel <= '0'; BSel <= '1'; ImmSel <= IMM_S; MemWrite <= '1';
        RegWrite <= '0'; ALUOp <= ALU_ADD;

      -----------------------------------------------------------------------
      -- BRANCH (beq, bne, blt, bge, bltu, bgeu)
      -----------------------------------------------------------------------
      when OP_BRANCH =>
        ASel <= '0'; BSel <= '0'; ImmSel <= IMM_B; RegWrite <= '0';
        ALUOp <= ALU_SUB; PCSel <= PC_BR;
        case funct3 is
          when "000" => Branch <= BR_BEQ;
          when "001" => Branch <= BR_BNE;
          when "100" => Branch <= BR_BLT;
          when "101" => Branch <= BR_BGE;
          when "110" => Branch <= BR_BLTU;
          when "111" => Branch <= BR_BGEU;
          when others => Branch <= BR_NONE;
        end case;

      -----------------------------------------------------------------------
      -- JUMPS (jal, jalr)
      -----------------------------------------------------------------------
      when OP_JAL =>
        ASel <= '1'; BSel <= '1'; ImmSel <= IMM_J; RegWrite <= '1';
        MemToReg <= M2R_PC4; Jump <= '1'; PCSel <= PC_JAL;

      when OP_JALR =>
        ASel <= '0'; BSel <= '1'; ImmSel <= IMM_I; RegWrite <= '1';
        MemToReg <= M2R_PC4; Jalr <= '1'; PCSel <= PC_JALR;

      -----------------------------------------------------------------------
      -- UPPER (lui, auipc)
      -----------------------------------------------------------------------
      when OP_LUI =>
        ASel <= '0'; BSel <= '1'; ImmSel <= IMM_U; RegWrite <= '1';
        MemToReg <= M2R_ALU; ALUOp <= ALU_PASSB;

      when OP_AUIPC =>
        ASel <= '1'; BSel <= '1'; ImmSel <= IMM_U; RegWrite <= '1';
        MemToReg <= M2R_ALU; ALUOp <= ALU_ADD;

      -----------------------------------------------------------------------
      -- SYSTEM / HALT
      -----------------------------------------------------------------------
      when OP_SYS =>
        Halt <= '1';

      -----------------------------------------------------------------------
      when others =>
        null;
    end case;
  end process;
end architecture;
