library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity barrel_shifter is
  port (
    data_in  : in  std_logic_vector(31 downto 0);
    shamt    : in  std_logic_vector(4 downto 0);  -- shift amount (0?31)
    dir      : in  std_logic;  -- 0 = left, 1 = right
    arith    : in  std_logic;  -- 1 = arithmetic right
    data_out : out std_logic_vector(31 downto 0)
  );
end entity;

architecture structural of barrel_shifter is
  signal stage0, stage1, stage2, stage3, stage4 : std_logic_vector(31 downto 0);
  signal rev_in, rev_out : std_logic_vector(31 downto 0);

  -- Reverse bit order (for left shift reuse)
  function reverse_bits(v : std_logic_vector) return std_logic_vector is
    variable r : std_logic_vector(v'range);
  begin
    for i in v'range loop
      r(i) := v(v'low + (v'high - i));
    end loop;
    return r;
  end function;

begin
  --------------------------------------------------------------------
  -- Reverse input for left shifts (bit-reversal trick)
  --------------------------------------------------------------------
  rev_in <= reverse_bits(data_in) when dir = '0' else data_in;

  --------------------------------------------------------------------
  -- Stage 0: shift by 1
  --------------------------------------------------------------------
  process(rev_in, shamt, arith)
  begin
    if shamt(0) = '1' then
      if arith = '1' then
        stage0 <= rev_in(31) & rev_in(31 downto 1);
      else
        stage0 <= '0' & rev_in(31 downto 1);
      end if;
    else
      stage0 <= rev_in;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Stage 1: shift by 2
  --------------------------------------------------------------------
  process(stage0, shamt, arith)
  begin
    if shamt(1) = '1' then
      if arith = '1' then
        stage1 <= (stage0(31) & stage0(31)) & stage0(31 downto 2);
      else
        stage1 <= "00" & stage0(31 downto 2);
      end if;
    else
      stage1 <= stage0;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Stage 2: shift by 4
  --------------------------------------------------------------------
  process(stage1, shamt, arith)
  begin
    if shamt(2) = '1' then
      if arith = '1' then
        stage2 <= (stage1(31) & stage1(31) & stage1(31) & stage1(31)) & stage1(31 downto 4);
      else
        stage2 <= "0000" & stage1(31 downto 4);
      end if;
    else
      stage2 <= stage1;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Stage 3: shift by 8
  --------------------------------------------------------------------
  process(stage2, shamt, arith)
  begin
    if shamt(3) = '1' then
      if arith = '1' then
        -- replicate MSB eight times for arithmetic shift
        stage3 <= (stage2(31) & stage2(31) & stage2(31) & stage2(31) &
                   stage2(31) & stage2(31) & stage2(31) & stage2(31)) & stage2(31 downto 8);
      else
        stage3 <= x"00" & stage2(23 downto 0);
      end if;
    else
      stage3 <= stage2;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Stage 4: shift by 16
  --------------------------------------------------------------------
  process(stage3, shamt, arith)
  begin
    if shamt(4) = '1' then
      if arith = '1' then
        stage4 <= (stage3(31) & stage3(31) & stage3(31) & stage3(31) &
                   stage3(31) & stage3(31) & stage3(31) & stage3(31) &
                   stage3(31) & stage3(31) & stage3(31) & stage3(31) &
                   stage3(31) & stage3(31) & stage3(31) & stage3(31)) & stage3(15 downto 0);
      else
        stage4 <= x"0000" & stage3(15 downto 0);
      end if;
    else
      stage4 <= stage3;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Reverse output for left shifts
  --------------------------------------------------------------------
  rev_out <= reverse_bits(stage4) when dir = '0' else stage4;
  data_out <= rev_out;

end architecture;

