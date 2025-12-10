--riscv_cpu.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.control_pkg.all;

entity riscv_cpu is
  port (
    clk : in  std_logic;
    rst : in  std_logic
  );
end entity;

architecture rtl of riscv_cpu is

  -- FETCH
  signal instr  : std_logic_vector(31 downto 0);
  signal pc     : std_logic_vector(31 downto 0);

  -- DECODE fields
  signal opcode : std_logic_vector(6 downto 0);
  signal funct3 : std_logic_vector(2 downto 0);
  signal funct7 : std_logic_vector(6 downto 0);
  signal rs1_ad : std_logic_vector(4 downto 0);
  signal rs2_ad : std_logic_vector(4 downto 0);
  signal rd_ad  : std_logic_vector(4 downto 0);

  -- CONTROL outputs (match control_unit)
  signal ASel_sig, BSel_sig : std_logic;
  signal ImmSel_sig         : std_logic_vector(2 downto 0);
  signal ALUOp_sig          : std_logic_vector(3 downto 0);
  signal RegWrite_sig       : std_logic;
  signal MemRead_sig        : std_logic;
  signal MemWrite_sig       : std_logic;
  signal MemToReg_sig       : std_logic_vector(1 downto 0);
  signal LoadSize_sig       : std_logic_vector(1 downto 0);
  signal LoadSign_sig       : std_logic;
  signal Branch_sig         : std_logic_vector(2 downto 0);
  signal Jump_sig, Jalr_sig : std_logic;
  signal PCSel_ctrl         : std_logic_vector(1 downto 0);
  signal Halt_sig           : std_logic;

  -- Register file signals
  signal rs1_data, rs2_data : std_logic_vector(31 downto 0);
  signal wb_data            : std_logic_vector(31 downto 0);

  -- Immediate
  signal imm_out : std_logic_vector(31 downto 0);

  -- ALU signals (match ALU entity)
  signal ALU_A, ALU_B       : std_logic_vector(31 downto 0);
  signal ALU_Result         : std_logic_vector(31 downto 0);
  signal ALU_Zero           : std_logic;

  -- Data memory
  signal dmem_rdata : std_logic_vector(31 downto 0);

  -- PC selection runtime (after branch decision)
  signal PCSel_final : std_logic_vector(1 downto 0);

  -- Targets
  signal branch_tgt, jalr_tgt, jump_tgt : std_logic_vector(31 downto 0);

begin

  ----------------------------------------------------------------------------
  -- FETCH UNIT
  ----------------------------------------------------------------------------
  U_FETCH : entity work.fetch_unit
    generic map ( START_PC => x"00000100" )
    port map (
      clk      => clk,
      rst      => rst,
      pcSel    => PCSel_final,
      branch_tgt => branch_tgt,
      jalr_tgt   => jalr_tgt,
      jump_tgt   => jump_tgt,
      instr    => instr,
      pc       => pc
    );

  ----------------------------------------------------------------------------
  -- DECODE: extract fields
  ----------------------------------------------------------------------------
  opcode <= instr(6 downto 0);
  funct3 <= instr(14 downto 12);
  funct7 <= instr(31 downto 25);
  rs1_ad <= instr(19 downto 15);
  rs2_ad <= instr(24 downto 20);
  rd_ad  <= instr(11 downto 7);

  ----------------------------------------------------------------------------
  -- CONTROL UNIT
  ----------------------------------------------------------------------------
  U_CTRL : entity work.control_unit
    port map (
      opcode  => opcode,
      funct3  => funct3,
      funct7  => funct7,

      ASel    => ASel_sig,
      BSel    => BSel_sig,
      ImmSel  => ImmSel_sig,
      ALUOp   => ALUOp_sig,

      RegWrite=> RegWrite_sig,
      MemRead => MemRead_sig,
      MemWrite=> MemWrite_sig,
      MemToReg=> MemToReg_sig,

      LoadSize=> LoadSize_sig,
      LoadSign=> LoadSign_sig,

      Branch  => Branch_sig,
      Jump    => Jump_sig,
      Jalr    => Jalr_sig,
      PCSel   => PCSel_ctrl,

      Halt    => Halt_sig
    );

  ----------------------------------------------------------------------------
  -- REGISTER FILE (match your RegFile interface)
  ----------------------------------------------------------------------------
  U_REGFILE : entity work.RegFile
    port map (
      clk      => clk,
      rst      => rst,
      en       => RegWrite_sig,
      rs1_ad   => rs1_ad,
      rs2_ad   => rs2_ad,
      rd_ad    => rd_ad,
      rd_data  => wb_data,
      rs1_data => rs1_data,
      rs2_data => rs2_data,
      reg_out  => open
    );

  ----------------------------------------------------------------------------
  -- IMM GEN
  ----------------------------------------------------------------------------
  U_IMM : entity work.imm_gen
    port map (
      instr   => instr,
      ImmSel  => ImmSel_sig,
      imm_out => imm_out
    );

  ----------------------------------------------------------------------------
  -- ALU inputs
  -- ASel: if '1' use PC as A, else use register rs1 (common pattern)
  -- BSel (BSel_sig) controls B = imm when '1' else rs2
  ----------------------------------------------------------------------------
  ALU_A <= pc when ASel_sig = '1' else rs1_data;
  ALU_B <= imm_out when BSel_sig = '1' else rs2_data;

  U_ALU : entity work.ALU
    port map (
      A          => ALU_A,
      B          => ALU_B,
      ALUControl => ALUOp_sig,
      ALUOut     => ALU_Result,
      zero       => ALU_Zero
    );

  ----------------------------------------------------------------------------
  -- Data memory
  ----------------------------------------------------------------------------
  U_DMEM : entity work.data_mem
    port map (
      clk      => clk,
      rst      => rst,
      addr     => ALU_Result,
      wdata    => rs2_data,
      write_en => MemWrite_sig,
      read_en  => MemRead_sig,
      size     => LoadSize_sig,
      sign     => LoadSign_sig,
      rdata    => dmem_rdata
    );

  ----------------------------------------------------------------------------
  -- WRITEBACK MUX -> wb_data drives RegFile.rd_data
  ----------------------------------------------------------------------------
  wb_data <= ALU_Result when MemToReg_sig = M2R_ALU else
             dmem_rdata when MemToReg_sig = M2R_MEM else
             std_logic_vector(unsigned(pc) + 4) when MemToReg_sig = M2R_PC4 else
             (others => '0');

  ----------------------------------------------------------------------------
  -- Compute branch/jump targets
  ----------------------------------------------------------------------------
  branch_tgt <= std_logic_vector(unsigned(pc) + unsigned(imm_out));
  jump_tgt   <= std_logic_vector(unsigned(pc) + unsigned(imm_out));
  jalr_tgt   <= std_logic_vector( (unsigned(rs1_data) + unsigned(imm_out)) and x"FFFFFFFE");

  ----------------------------------------------------------------------------
  -- Branch decision logic (set PCSel_final)
  ----------------------------------------------------------------------------
  process(Branch_sig, rs1_data, rs2_data, ALU_Zero, Jump_sig, Jalr_sig)
    variable s1, s2 : signed(31 downto 0);
    variable u1, u2 : unsigned(31 downto 0);
    variable take   : std_logic := '0';
  begin
    take := '0';
    s1 := signed(rs1_data);
    s2 := signed(rs2_data);
    u1 := unsigned(rs1_data);
    u2 := unsigned(rs2_data);

    case Branch_sig is
      when BR_BEQ  => if rs1_data = rs2_data then take := '1'; end if;
      when BR_BNE  => if rs1_data /= rs2_data then take := '1'; end if;
      when BR_BLT  => if s1 < s2 then take := '1'; end if;
      when BR_BGE  => if s1 >= s2 then take := '1'; end if;
      when BR_BLTU => if u1 < u2 then take := '1'; end if;
      when BR_BGEU => if u1 >= u2 then take := '1'; end if;
      when others  => take := '0';
    end case;

    if take = '1' then
      PCSel_final <= PC_BR;
    elsif Jump_sig = '1' then
      PCSel_final <= PC_JAL;
    elsif Jalr_sig = '1' then
      PCSel_final <= PC_JALR;
    else
      PCSel_final <= PC_PC4;
    end if;
  end process;

end architecture;