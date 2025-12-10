-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- RISCV_Processor.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a skeleton of a RISCV_Processor  
-- implementation.

-- 01/29/2019 by H3::Design created.
-- 04/10/2025 by AP::Coverted to RISC-V.
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(
    iCLK      : in std_logic;
    iRST      : in std_logic;
    iInstLd   : in std_logic;
    iInstAddr : in std_logic_vector(N-1 downto 0);
    iInstExt  : in std_logic_vector(N-1 downto 0);
    oALUOut   : out std_logic_vector(N-1 downto 0)
  );
end RISCV_Processor;

architecture structure of RISCV_Processor is

  ---------------------------------------------------------------------------
  -- Required data memory signals
  ---------------------------------------------------------------------------
  signal s_DMemWr   : std_logic;
  signal s_DMemAddr : std_logic_vector(N-1 downto 0);
  signal s_DMemData : std_logic_vector(N-1 downto 0);
  signal s_DMemOut  : std_logic_vector(N-1 downto 0);

  ---------------------------------------------------------------------------
  -- Required register file signals
  ---------------------------------------------------------------------------
  signal s_RegWr     : std_logic;
  signal s_RegWrAddr : std_logic_vector(4 downto 0);
  signal s_RegWrData : std_logic_vector(N-1 downto 0);

  ---------------------------------------------------------------------------
  -- Required instruction memory signals
  ---------------------------------------------------------------------------
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- do not drive directly
  signal s_NextInstAddr : std_logic_vector(N-1 downto 0); -- "PC"
  signal s_Inst         : std_logic_vector(N-1 downto 0);

  ---------------------------------------------------------------------------
  -- Required halt / overflow
  ---------------------------------------------------------------------------
  signal s_Halt : std_logic := '0';
  signal s_Ovfl : std_logic := '0';

  ---------------------------------------------------------------------------
  -- mem component
  ---------------------------------------------------------------------------
  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
      clk  : in  std_logic;
      addr : in  std_logic_vector((ADDR_WIDTH-1) downto 0);
      data : in  std_logic_vector((DATA_WIDTH-1) downto 0);
      we   : in  std_logic := '1';
      q    : out std_logic_vector((DATA_WIDTH-1) downto 0)
    );
  end component;

  ---------------------------------------------------------------------------
  -- Simple internal register file (32 x N)
  ---------------------------------------------------------------------------
  type regfile_t is array (31 downto 0) of std_logic_vector(N-1 downto 0);
  signal s_regfile : regfile_t := (others => (others => '0'));

  -- ID-stage read values
  signal s_RS1Data_ID, s_RS2Data_ID : std_logic_vector(N-1 downto 0);

  ---------------------------------------------------------------------------
  -- Pipeline registers and datapath signals
  ---------------------------------------------------------------------------

  -- IF stage
  signal s_PC_F      : std_logic_vector(N-1 downto 0) := (others => '0');
  signal s_PCPlus4_F : std_logic_vector(N-1 downto 0);

  -- IF/ID
  signal s_IFID_PC   : std_logic_vector(N-1 downto 0) := (others => '0');
  signal s_IFID_Inst : std_logic_vector(N-1 downto 0) := (others => (others => '0'));

  -- ID decode fields
  signal s_opcode_ID : std_logic_vector(6 downto 0);
  signal s_rd_ID     : std_logic_vector(4 downto 0);
  signal s_rs1_ID    : std_logic_vector(4 downto 0);
  signal s_rs2_ID    : std_logic_vector(4 downto 0);
  signal s_funct3_ID : std_logic_vector(2 downto 0);
  signal s_funct7_ID : std_logic_vector(6 downto 0);

  -- ID control signals
  signal s_RegWr_ID     : std_logic;
  signal s_MemRead_ID   : std_logic;
  signal s_MemWrite_ID  : std_logic;
  signal s_MemToReg_ID  : std_logic_vector(1 downto 0);  -- 00: ALU, 01: MEM, 10: PC+4
  signal s_ALUSrc_ID    : std_logic;                     -- 0: rs2, 1: imm
  signal s_ALUCtrl_ID   : std_logic_vector(3 downto 0);
  signal s_Branch_ID    : std_logic;
  signal s_Jump_ID      : std_logic;
  signal s_Jalr_ID      : std_logic;
  signal s_Halt_ID      : std_logic;
  signal s_Imm_ID       : std_logic_vector(N-1 downto 0);

  -- ID/EX pipeline regs
  signal s_IDEX_PC       : std_logic_vector(N-1 downto 0);
  signal s_IDEX_PCPlus4  : std_logic_vector(N-1 downto 0);
  signal s_IDEX_RS1Data  : std_logic_vector(N-1 downto 0);
  signal s_IDEX_RS2Data  : std_logic_vector(N-1 downto 0);
  signal s_IDEX_Imm      : std_logic_vector(N-1 downto 0);
  signal s_IDEX_rd       : std_logic_vector(4 downto 0);
  signal s_IDEX_RegWr    : std_logic;
  signal s_IDEX_MemRead  : std_logic;
  signal s_IDEX_MemWrite : std_logic;
  signal s_IDEX_MemToReg : std_logic_vector(1 downto 0);
  signal s_IDEX_ALUSrc   : std_logic;
  signal s_IDEX_ALUCtrl  : std_logic_vector(3 downto 0);
  signal s_IDEX_Branch   : std_logic;
  signal s_IDEX_Jump     : std_logic;
  signal s_IDEX_Jalr     : std_logic;
  signal s_IDEX_Halt     : std_logic;

  -- EX stage
  signal s_ALU_A_EX, s_ALU_B_EX : std_logic_vector(N-1 downto 0);
  signal s_ALUResult_EX         : std_logic_vector(N-1 downto 0);
  signal s_Zero_EX              : std_logic;
  signal s_BranchTarget_EX      : std_logic_vector(N-1 downto 0);
  signal s_JalrTarget_EX        : std_logic_vector(N-1 downto 0);

  -- EX/MEM pipeline regs
  signal s_EXMEM_PCPlus4  : std_logic_vector(N-1 downto 0);
  signal s_EXMEM_ALURes   : std_logic_vector(N-1 downto 0);
  signal s_EXMEM_RS2Data  : std_logic_vector(N-1 downto 0);
  signal s_EXMEM_BrTarget : std_logic_vector(N-1 downto 0);
  signal s_EXMEM_JalrTgt  : std_logic_vector(N-1 downto 0);
  signal s_EXMEM_rd       : std_logic_vector(4 downto 0);
  signal s_EXMEM_RegWr    : std_logic;
  signal s_EXMEM_MemRead  : std_logic;
  signal s_EXMEM_MemWrite : std_logic;
  signal s_EXMEM_MemToReg : std_logic_vector(1 downto 0);
  signal s_EXMEM_Branch   : std_logic;
  signal s_EXMEM_Jump     : std_logic;
  signal s_EXMEM_Jalr     : std_logic;
  signal s_EXMEM_Zero     : std_logic;
  signal s_EXMEM_Halt     : std_logic;

  -- MEM/WB pipeline regs
  signal s_MEMWB_PCPlus4 : std_logic_vector(N-1 downto 0);
  signal s_MEMWB_ALURes  : std_logic_vector(N-1 downto 0);
  signal s_MEMWB_MemData : std_logic_vector(N-1 downto 0);
  signal s_MEMWB_rd      : std_logic_vector(4 downto 0);
  signal s_MEMWB_RegWr   : std_logic;
  signal s_MEMWB_MemToReg: std_logic_vector(1 downto 0);

  -- Writeback mux output
  signal s_WBData : std_logic_vector(N-1 downto 0);

  -- Next PC logic
  signal s_TakeBranch : std_logic;
  signal s_NextPC     : std_logic_vector(N-1 downto 0);

  ---------------------------------------------------------------------------
  -- ALU control encodings (choose arbitrarily, just be consistent)
  ---------------------------------------------------------------------------
  constant ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
  constant ALU_SUB  : std_logic_vector(3 downto 0) := "0001";
  constant ALU_AND  : std_logic_vector(3 downto 0) := "0010";
  constant ALU_OR   : std_logic_vector(3 downto 0) := "0011";
  constant ALU_XOR  : std_logic_vector(3 downto 0) := "0100";
  constant ALU_SLT  : std_logic_vector(3 downto 0) := "0101";
  constant ALU_SLTU : std_logic_vector(3 downto 0) := "0110";
  constant ALU_SLL  : std_logic_vector(3 downto 0) := "0111";
  constant ALU_SRL  : std_logic_vector(3 downto 0) := "1000";
  constant ALU_SRA  : std_logic_vector(3 downto 0) := "1001";

begin

  -----------------------------------------------------------------------------
  -- Instruction memory address mux (given by skeleton)
  -----------------------------------------------------------------------------
  with iInstLd select
    s_IMemAddr <= s_NextInstAddr when '0',
                  iInstAddr      when others;

  -----------------------------------------------------------------------------
  -- Instruction memory
  -----------------------------------------------------------------------------
  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
      clk  => iCLK,
      addr => s_IMemAddr(11 downto 2),
      data => iInstExt,
      we   => iInstLd,
      q    => s_Inst
    );

  -----------------------------------------------------------------------------
  -- Data memory
  -----------------------------------------------------------------------------
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(
      clk  => iCLK,
      addr => s_DMemAddr(11 downto 2),
      data => s_DMemData,
      we   => s_DMemWr,
      q    => s_DMemOut
    );

  -----------------------------------------------------------------------------
  -- Program Counter (IF stage)
  -----------------------------------------------------------------------------
  process(iCLK)
  begin
    if rising_edge(iCLK) then
      if iRST = '1' then
        s_PC_F <= (others => '0');
      else
        s_PC_F <= s_NextPC;
      end if;
    end if;
  end process;

  s_PCPlus4_F   <= std_logic_vector(unsigned(s_PC_F) + 4);
  s_NextInstAddr <= s_PC_F;  -- feed into instruction memory

  -----------------------------------------------------------------------------
  -- IF/ID pipeline registers
  -----------------------------------------------------------------------------
  process(iCLK)
  begin
    if rising_edge(iCLK) then
      if iRST = '1' then
        s_IFID_PC   <= (others => '0');
        s_IFID_Inst <= (others => '0');
      else
        s_IFID_PC   <= s_PC_F;
        s_IFID_Inst <= s_Inst;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- ID stage: decode instruction fields
  -----------------------------------------------------------------------------
  s_opcode_ID <= s_IFID_Inst(6 downto 0);
  s_rd_ID     <= s_IFID_Inst(11 downto 7);
  s_funct3_ID <= s_IFID_Inst(14 downto 12);
  s_rs1_ID    <= s_IFID_Inst(19 downto 15);
  s_rs2_ID    <= s_IFID_Inst(24 downto 20);
  s_funct7_ID <= s_IFID_Inst(31 downto 25);

  -----------------------------------------------------------------------------
  -- Internal register file (synchronous write, combinational read)
  -----------------------------------------------------------------------------
  -- writeback
  process(iCLK)
  begin
    if rising_edge(iCLK) then
      if iRST = '1' then
        s_regfile <= (others => (others => '0'));
      else
        if s_RegWr = '1' and s_RegWrAddr /= "00000" then
          s_regfile(to_integer(unsigned(s_RegWrAddr))) <= s_RegWrData;
        end if;
      end if;
    end if;
  end process;

  -- read in ID stage
  s_RS1Data_ID <= (others => '0') when s_rs1_ID = "00000" else
                  s_regfile(to_integer(unsigned(s_rs1_ID)));
  s_RS2Data_ID <= (others => '0') when s_rs2_ID = "00000" else
                  s_regfile(to_integer(unsigned(s_rs2_ID)));

  -----------------------------------------------------------------------------
  -- Immediate generation (I, S, B, U, J types)
  -----------------------------------------------------------------------------
  process(s_IFID_Inst, s_opcode_ID)
    variable imm : signed(N-1 downto 0);
  begin
    imm := (others => '0');

    case s_opcode_ID is
      -- I-type (e.g., ADDI, LW, JALR)
      when "0010011" | "0000011" | "1100111" =>
        imm(11 downto 0)  := signed(s_IFID_Inst(31 downto 20));
        imm(31 downto 12) := (others => imm(11));

      -- S-type (SW)
      when "0100011" =>
        imm(4 downto 0)   := signed(s_IFID_Inst(11 downto 7));
        imm(11 downto 5)  := signed(s_IFID_Inst(31 downto 25));
        imm(31 downto 12) := (others => imm(11));

      -- B-type (BEQ/BNE/etc.)
      when "1100011" =>
        imm(0)            := '0';
        imm(4 downto 1)   := signed(s_IFID_Inst(11 downto 8));
        imm(10 downto 5)  := signed(s_IFID_Inst(30 downto 25));
        imm(11)           := s_IFID_Inst(7);
        imm(12)           := s_IFID_Inst(31);
        imm(31 downto 13) := (others => imm(12));

      -- U-type (LUI/AUIPC)
      when "0110111" | "0010111" =>
        imm(31 downto 12) := signed(s_IFID_Inst(31 downto 12));
        imm(11 downto 0)  := (others => '0');

      -- J-type (JAL)
      when "1101111" =>
        imm(0)            := '0';
        imm(10 downto 1)  := signed(s_IFID_Inst(30 downto 21));
        imm(11)           := s_IFID_Inst(20);
        imm(19 downto 12) := signed(s_IFID_Inst(19 downto 12));
        imm(20)           := s_IFID_Inst(31);
        imm(31 downto 21) := (others => imm(20));

      when others =>
        imm := (others => '0');
    end case;

    s_Imm_ID <= std_logic_vector(imm);
  end process;

  -----------------------------------------------------------------------------
  -- Control unit (very simple subset)
  -----------------------------------------------------------------------------
  process(s_opcode_ID, s_funct3_ID, s_funct7_ID)
  begin
    -- defaults
    s_RegWr_ID    <= '0';
    s_MemRead_ID  <= '0';
    s_MemWrite_ID <= '0';
    s_MemToReg_ID <= "00";  -- ALU
    s_ALUSrc_ID   <= '0';
    s_ALUCtrl_ID  <= ALU_ADD;
    s_Branch_ID   <= '0';
    s_Jump_ID     <= '0';
    s_Jalr_ID     <= '0';
    s_Halt_ID     <= '0';

    case s_opcode_ID is

      -----------------------------------------------------------------------
      -- R-type: ADD, SUB, AND, OR, XOR, SLT, SLTU
      -----------------------------------------------------------------------
      when "0110011" =>
        s_RegWr_ID   <= '1';
        s_ALUSrc_ID  <= '0';
        s_MemToReg_ID<= "00";

        case s_funct3_ID is
          when "000" =>  -- ADD/SUB
            if s_funct7_ID = "0100000" then
              s_ALUCtrl_ID <= ALU_SUB;
            else
              s_ALUCtrl_ID <= ALU_ADD;
            end if;
          when "111" => s_ALUCtrl_ID <= ALU_AND;   -- AND
          when "110" => s_ALUCtrl_ID <= ALU_OR;    -- OR
          when "100" => s_ALUCtrl_ID <= ALU_XOR;   -- XOR
          when "010" => s_ALUCtrl_ID <= ALU_SLT;   -- SLT
          when "011" => s_ALUCtrl_ID <= ALU_SLTU;  -- SLTU
          when others => s_ALUCtrl_ID <= ALU_ADD;
        end case;

      -----------------------------------------------------------------------
      -- I-type ALU (ADDI, SLTI, ANDI, ORI, XORI)
      -----------------------------------------------------------------------
      when "0010011" =>
        s_RegWr_ID   <= '1';
        s_ALUSrc_ID  <= '1';
        s_MemToReg_ID<= "00";

        case s_funct3_ID is
          when "000" => s_ALUCtrl_ID <= ALU_ADD;   -- ADDI
          when "010" => s_ALUCtrl_ID <= ALU_SLT;   -- SLTI
          when "011" => s_ALUCtrl_ID <= ALU_SLTU;  -- SLTIU
          when "111" => s_ALUCtrl_ID <= ALU_AND;   -- ANDI
          when "110" => s_ALUCtrl_ID <= ALU_OR;    -- ORI
          when "100" => s_ALUCtrl_ID <= ALU_XOR;   -- XORI
          when others => s_ALUCtrl_ID <= ALU_ADD;
        end case;

      -----------------------------------------------------------------------
      -- Load (LW)
      -----------------------------------------------------------------------
      when "0000011" =>
        s_RegWr_ID    <= '1';
        s_MemRead_ID  <= '1';
        s_MemToReg_ID <= "01"; -- from memory
        s_ALUSrc_ID   <= '1';
        s_ALUCtrl_ID  <= ALU_ADD; -- base + offset

      -----------------------------------------------------------------------
      -- Store (SW)
      -----------------------------------------------------------------------
      when "0100011" =>
        s_RegWr_ID    <= '0';
        s_MemWrite_ID <= '1';
        s_ALUSrc_ID   <= '1';
        s_ALUCtrl_ID  <= ALU_ADD;

      -----------------------------------------------------------------------
      -- Branch (BEQ/BNE/etc.)
      -----------------------------------------------------------------------
      when "1100011" =>
        s_RegWr_ID   <= '0';
        s_Branch_ID  <= '1';
        s_ALUSrc_ID  <= '0';
        s_ALUCtrl_ID <= ALU_SUB; -- compare

      -----------------------------------------------------------------------
      -- JAL
      -----------------------------------------------------------------------
      when "1101111" =>
        s_RegWr_ID    <= '1';
        s_MemToReg_ID <= "10";  -- PC+4
        s_Jump_ID     <= '1';
        s_ALUSrc_ID   <= '1';   -- use immediate for target calc
        s_ALUCtrl_ID  <= ALU_ADD;

      -----------------------------------------------------------------------
      -- JALR
      -----------------------------------------------------------------------
      when "1100111" =>
        s_RegWr_ID    <= '1';
        s_MemToReg_ID <= "10";  -- PC+4
        s_Jalr_ID     <= '1';
        s_ALUSrc_ID   <= '1';
        s_ALUCtrl_ID  <= ALU_ADD;

      -----------------------------------------------------------------------
      -- SYSTEM / WFI used as HALT (opcode 1110011)
      -----------------------------------------------------------------------
      when "1110011" =>
        s_Halt_ID <= '1';

      when others =>
        null;
    end case;
  end process;

  -----------------------------------------------------------------------------
  -- ID/EX pipeline registers
  -----------------------------------------------------------------------------
  process(iCLK)
  begin
    if rising_edge(iCLK) then
      if iRST = '1' then
        s_IDEX_PC       <= (others => '0');
        s_IDEX_PCPlus4  <= (others => '0');
        s_IDEX_RS1Data  <= (others => '0');
        s_IDEX_RS2Data  <= (others => '0');
        s_IDEX_Imm      <= (others => '0');
        s_IDEX_rd       <= (others => '0');
        s_IDEX_RegWr    <= '0';
        s_IDEX_MemRead  <= '0';
        s_IDEX_MemWrite <= '0';
        s_IDEX_MemToReg <= "00";
        s_IDEX_ALUSrc   <= '0';
        s_IDEX_ALUCtrl  <= ALU_ADD;
        s_IDEX_Branch   <= '0';
        s_IDEX_Jump     <= '0';
        s_IDEX_Jalr     <= '0';
        s_IDEX_Halt     <= '0';
      else
        s_IDEX_PC       <= s_IFID_PC;
        s_IDEX_PCPlus4  <= s_PCPlus4_F;
        s_IDEX_RS1Data  <= s_RS1Data_ID;
        s_IDEX_RS2Data  <= s_RS2Data_ID;
        s_IDEX_Imm      <= s_Imm_ID;
        s_IDEX_rd       <= s_rd_ID;
        s_IDEX_RegWr    <= s_RegWr_ID;
        s_IDEX_MemRead  <= s_MemRead_ID;
        s_IDEX_MemWrite <= s_MemWrite_ID;
        s_IDEX_MemToReg <= s_MemToReg_ID;
        s_IDEX_ALUSrc   <= s_ALUSrc_ID;
        s_IDEX_ALUCtrl  <= s_ALUCtrl_ID;
        s_IDEX_Branch   <= s_Branch_ID;
        s_IDEX_Jump     <= s_Jump_ID;
        s_IDEX_Jalr     <= s_Jalr_ID;
        s_IDEX_Halt     <= s_Halt_ID;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- EX stage: ALU operands
  -----------------------------------------------------------------------------
  s_ALU_A_EX <= s_IDEX_RS1Data;
  s_ALU_B_EX <= s_IDEX_Imm when s_IDEX_ALUSrc = '1' else s_IDEX_RS2Data;

  -----------------------------------------------------------------------------
  -- EX stage: ALU operation + overflow
  -----------------------------------------------------------------------------
  process(s_ALU_A_EX, s_ALU_B_EX, s_IDEX_ALUCtrl)
    variable a_s, b_s, r_s : signed(N-1 downto 0);
    variable a_u, b_u      : unsigned(N-1 downto 0);
  begin
    a_s := signed(s_ALU_A_EX);
    b_s := signed(s_ALU_B_EX);
    a_u := unsigned(s_ALU_A_EX);
    b_u := unsigned(s_ALU_B_EX);
    r_s := (others => '0');
    s_Ovfl <= '0';

    case s_IDEX_ALUCtrl is
      when ALU_ADD =>
        r_s := a_s + b_s;
        -- signed add overflow
        if (a_s(N-1) = b_s(N-1)) and (r_s(N-1) /= a_s(N-1)) then
          s_Ovfl <= '1';
        end if;

      when ALU_SUB =>
        r_s := a_s - b_s;
        if (a_s(N-1) /= b_s(N-1)) and (r_s(N-1) /= a_s(N-1)) then
          s_Ovfl <= '1';
        end if;

      when ALU_AND =>
        s_ALUResult_EX <= s_ALU_A_EX and s_ALU_B_EX;
        s_Zero_EX <= '1' when s_ALU_A_EX and s_ALU_B_EX = (others => '0') else '0';
        return;

      when ALU_OR =>
        s_ALUResult_EX <= s_ALU_A_EX or s_ALU_B_EX;
        s_Zero_EX <= '1' when s_ALU_A_EX or s_ALU_B_EX = (others => '0') else '0';
        return;

      when ALU_XOR =>
        s_ALUResult_EX <= s_ALU_A_EX xor s_ALU_B_EX;
        s_Zero_EX <= '1' when s_ALU_A_EX xor s_ALU_B_EX = (others => '0') else '0';
        return;

      when ALU_SLT =>
        if a_s < b_s then
          r_s := (others => '0');
          r_s(0) := '1';
        else
          r_s := (others => '0');
        end if;

      when ALU_SLTU =>
        if a_u < b_u then
          r_s := (others => '0');
          r_s(0) := '1';
        else
          r_s := (others => '0');
        end if;

      when others =>
        r_s := (others => '0');
    end case;

    s_ALUResult_EX <= std_logic_vector(r_s);
    if std_logic_vector(r_s) = (others => '0') then
      s_Zero_EX <= '1';
    else
      s_Zero_EX <= '0';
    end if;
  end process;

  -- Branch / JAL target from EX stage
  s_BranchTarget_EX <= std_logic_vector(unsigned(s_IDEX_PC) + unsigned(s_IDEX_Imm));
  s_JalrTarget_EX   <= std_logic_vector( (unsigned(s_IDEX_RS1Data) + unsigned(s_IDEX_Imm)) and
                                         (not 1u(N-1 downto 1) & '0') );  -- clear bit 0

  -----------------------------------------------------------------------------
  -- EX/MEM pipeline registers
  -----------------------------------------------------------------------------
  process(iCLK)
  begin
    if rising_edge(iCLK) then
      if iRST = '1' then
        s_EXMEM_PCPlus4  <= (others => '0');
        s_EXMEM_ALURes   <= (others => '0');
        s_EXMEM_RS2Data  <= (others => '0');
        s_EXMEM_BrTarget <= (others => '0');
        s_EXMEM_JalrTgt  <= (others => '0');
        s_EXMEM_rd       <= (others => '0');
        s_EXMEM_RegWr    <= '0';
        s_EXMEM_MemRead  <= '0';
        s_EXMEM_MemWrite <= '0';
        s_EXMEM_MemToReg <= "00";
        s_EXMEM_Branch   <= '0';
        s_EXMEM_Jump     <= '0';
        s_EXMEM_Jalr     <= '0';
        s_EXMEM_Zero     <= '0';
        s_EXMEM_Halt     <= '0';
      else
        s_EXMEM_PCPlus4  <= s_IDEX_PCPlus4;
        s_EXMEM_ALURes   <= s_ALUResult_EX;
        s_EXMEM_RS2Data  <= s_IDEX_RS2Data;
        s_EXMEM_BrTarget <= s_BranchTarget_EX;
        s_EXMEM_JalrTgt  <= s_JalrTarget_EX;
        s_EXMEM_rd       <= s_IDEX_rd;
        s_EXMEM_RegWr    <= s_IDEX_RegWr;
        s_EXMEM_MemRead  <= s_IDEX_MemRead;
        s_EXMEM_MemWrite <= s_IDEX_MemWrite;
        s_EXMEM_MemToReg <= s_IDEX_MemToReg;
        s_EXMEM_Branch   <= s_IDEX_Branch;
        s_EXMEM_Jump     <= s_IDEX_Jump;
        s_EXMEM_Jalr     <= s_IDEX_Jalr;
        s_EXMEM_Zero     <= s_Zero_EX;
        s_EXMEM_Halt     <= s_IDEX_Halt;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- MEM stage: connect to data memory
  -----------------------------------------------------------------------------
  s_DMemWr   <= s_EXMEM_MemWrite;
  s_DMemAddr <= s_EXMEM_ALURes;
  s_DMemData <= s_EXMEM_RS2Data;

  -----------------------------------------------------------------------------
  -- MEM/WB pipeline registers
  -----------------------------------------------------------------------------
  process(iCLK)
  begin
    if rising_edge(iCLK) then
      if iRST = '1' then
        s_MEMWB_PCPlus4  <= (others => '0');
        s_MEMWB_ALURes   <= (others => '0');
        s_MEMWB_MemData  <= (others => '0');
        s_MEMWB_rd       <= (others => '0');
        s_MEMWB_RegWr    <= '0';
        s_MEMWB_MemToReg <= "00";
      else
        s_MEMWB_PCPlus4  <= s_EXMEM_PCPlus4;
        s_MEMWB_ALURes   <= s_EXMEM_ALURes;
        s_MEMWB_MemData  <= s_DMemOut;
        s_MEMWB_rd       <= s_EXMEM_rd;
        s_MEMWB_RegWr    <= s_EXMEM_RegWr;
        s_MEMWB_MemToReg <= s_EXMEM_MemToReg;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- WB stage: writeback mux and connections to "required" signals
  -----------------------------------------------------------------------------
  with s_MEMWB_MemToReg select
    s_WBData <= s_MEMWB_ALURes   when "00",
                s_MEMWB_MemData  when "01",
                s_MEMWB_PCPlus4  when "10",
                (others => '0')  when others;

  s_RegWr     <= s_MEMWB_RegWr;
  s_RegWrAddr <= s_MEMWB_rd;
  s_RegWrData <= s_WBData;

  -----------------------------------------------------------------------------
  -- Branch / jump decision and next PC
  -----------------------------------------------------------------------------
  s_TakeBranch <= '1' when (s_EXMEM_Branch = '1' and s_EXMEM_Zero = '1') else '0';

  process(s_PCPlus4_F, s_EXMEM_BrTarget, s_EXMEM_JalrTgt,
          s_EXMEM_Jump, s_EXMEM_Jalr, s_TakeBranch)
  begin
    if s_TakeBranch = '1' then
      s_NextPC <= s_EXMEM_BrTarget;
    elsif s_EXMEM_Jump = '1' then
      s_NextPC <= s_EXMEM_BrTarget; -- same immediate
    elsif s_EXMEM_Jalr = '1' then
      s_NextPC <= s_EXMEM_JalrTgt;
    else
      s_NextPC <= s_PCPlus4_F;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Halt signal (from EX/MEM stage)
  -----------------------------------------------------------------------------
  s_Halt <= s_EXMEM_Halt;

  -----------------------------------------------------------------------------
  -- ALU output for synthesis visibility
  -----------------------------------------------------------------------------
  oALUOut <= s_EXMEM_ALURes;

end structure;

