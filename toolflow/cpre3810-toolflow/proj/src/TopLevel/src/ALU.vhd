-- ALU.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.control_pkg.all;

entity alu is
  port (
    A      : in  std_logic_vector(31 downto 0);
    B      : in  std_logic_vector(31 downto 0);
    ALUOp  : in  std_logic_vector(3 downto 0);
    Result : out std_logic_vector(31 downto 0);
    Zero   : out std_logic;
    Ovfl   : out std_logic
  );
end entity;

architecture rtl of alu is
  signal A_s, B_s : signed(31 downto 0);
  signal B_u      : unsigned(31 downto 0);
  signal tmp      : std_logic_vector(31 downto 0);
  signal ovfl_int : std_logic;
begin
  A_s <= signed(A);
  B_s <= signed(B);
  B_u <= unsigned(B);

  process(A_s, B_s, B_u, ALUOp)
    variable tmp_v  : std_logic_vector(31 downto 0);
    variable sum_s  : signed(31 downto 0);
    variable ovfl_v : std_logic;
  begin
    ovfl_v := '0';
    tmp_v  := (others => '0');

    case ALUOp is

      when ALU_ADD =>
        sum_s := A_s + B_s;
        tmp_v := std_logic_vector(sum_s);
        -- signed overflow: same sign in, different sign out
        if (A_s(31) = B_s(31)) and (sum_s(31) /= A_s(31)) then
          ovfl_v := '1';
        end if;

      when ALU_SUB =>
        sum_s := A_s - B_s;
        tmp_v := std_logic_vector(sum_s);
        -- signed overflow for A - B:
        -- A and B have different sign, and result sign differs from A
        if (A_s(31) /= B_s(31)) and (sum_s(31) /= A_s(31)) then
          ovfl_v := '1';
        end if;

      when ALU_AND =>
        tmp_v := A and B;

      when ALU_OR =>
        tmp_v := A or B;

      when ALU_XOR =>
        tmp_v := A xor B;

      when ALU_SLT =>  -- signed comparison
        if A_s < B_s then
          tmp_v := (others => '0');
          tmp_v(0) := '1';
        else
          tmp_v := (others => '0');
        end if;

      when ALU_SLTU =>  -- unsigned comparison
        if unsigned(A) < unsigned(B) then
          tmp_v := (others => '0');
          tmp_v(0) := '1';
        else
          tmp_v := (others => '0');
        end if;

      when ALU_SLL =>
        tmp_v := std_logic_vector(
                   shift_left(unsigned(A), to_integer(unsigned(B(4 downto 0))))
                 );

      when ALU_SRL =>
        tmp_v := std_logic_vector(
                   shift_right(unsigned(A), to_integer(unsigned(B(4 downto 0))))
                 );

      when ALU_SRA =>
        tmp_v := std_logic_vector(
                   shift_right(A_s, to_integer(unsigned(B(4 downto 0))))
                 );

      when ALU_PASSB =>
        tmp_v := B;

      when others =>
        tmp_v := (others => '0');
    end case;

    tmp      <= tmp_v;
    ovfl_int <= ovfl_v;
  end process;

  Result <= tmp;
  Zero   <= '1' when tmp = x"00000000" else '0';
  Ovfl   <= ovfl_int;

end architecture;

