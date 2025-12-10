-- ID_EX_reg.vhd  (template)
library IEEE;
use IEEE.std_logic_1164.all;

entity ID_EX_reg is
  generic(N : integer := 32);
  port(
    iCLK : in std_logic;
    iRST : in std_logic;

    -- From ID stage
    iPC       : in  std_logic_vector(N-1 downto 0);
    iPC4      : in  std_logic_vector(N-1 downto 0);
    iRS1Data  : in  std_logic_vector(N-1 downto 0);
    iRS2Data  : in  std_logic_vector(N-1 downto 0);
    iImm      : in  std_logic_vector(N-1 downto 0);
    iRD       : in  std_logic_vector(4 downto 0);

    iRegWrite : in std_logic;
    iMemRead  : in std_logic;
    iMemWrite : in std_logic;
    iMemToReg : in std_logic_vector(1 downto 0);
    iALUOp    : in std_logic_vector(3 downto 0);
    iALUSrc   : in std_logic;
    iBranch   : in std_logic_vector(2 downto 0);
    iJump     : in std_logic;
    iJalr     : in std_logic;
    iLoadSize : in std_logic_vector(1 downto 0);
    iLoadSign : in std_logic;
    iHalt     : in std_logic;

    -- To EX stage
    oPC       : out std_logic_vector(N-1 downto 0);
    oPC4      : out std_logic_vector(N-1 downto 0);
    oRS1Data  : out std_logic_vector(N-1 downto 0);
    oRS2Data  : out std_logic_vector(N-1 downto 0);
    oImm      : out std_logic_vector(N-1 downto 0);
    oRD       : out std_logic_vector(4 downto 0);

    oRegWrite : out std_logic;
    oMemRead  : out std_logic;
    oMemWrite : out std_logic;
    oMemToReg : out std_logic_vector(1 downto 0);
    oALUOp    : out std_logic_vector(3 downto 0);
    oALUSrc   : out std_logic;
    oBranch   : out std_logic_vector(2 downto 0);
    oJump     : out std_logic;
    oJalr     : out std_logic;
    oLoadSize : out std_logic_vector(1 downto 0);
    oLoadSign : out std_logic;
    oHalt     : out std_logic
  );
end entity;

architecture rtl of ID_EX_reg is
begin
  process(iCLK)
  begin
    if rising_edge(iCLK) then
      if iRST = '1' then
        oPC       <= (others => '0');
        oPC4      <= (others => '0');
        oRS1Data  <= (others => '0');
        oRS2Data  <= (others => '0');
        oImm      <= (others => '0');
        oRD       <= (others => '0');
        oRegWrite <= '0';
        oMemRead  <= '0';
        oMemWrite <= '0';
        oMemToReg <= (others => '0');
        oALUOp    <= (others => '0');
        oALUSrc   <= '0';
        oBranch   <= (others => '0');
        oJump     <= '0';
        oJalr     <= '0';
        oLoadSize <= (others => '0');
        oLoadSign <= '0';
        oHalt     <= '0';
      else
        oPC       <= iPC;
        oPC4      <= iPC4;
        oRS1Data  <= iRS1Data;
        oRS2Data  <= iRS2Data;
        oImm      <= iImm;
        oRD       <= iRD;
        oRegWrite <= iRegWrite;
        oMemRead  <= iMemRead;
        oMemWrite <= iMemWrite;
        oMemToReg <= iMemToReg;
        oALUOp    <= iALUOp;
        oALUSrc   <= iALUSrc;
        oBranch   <= iBranch;
        oJump     <= iJump;
        oJalr     <= iJalr;
        oLoadSize <= iLoadSize;
        oLoadSign <= iLoadSign;
        oHalt     <= iHalt;
      end if;
    end if;
  end process;
end architecture;
