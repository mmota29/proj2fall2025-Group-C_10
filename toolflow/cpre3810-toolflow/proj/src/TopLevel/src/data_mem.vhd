--data_mem.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_mem is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    addr     : in  std_logic_vector(31 downto 0);
    wdata    : in  std_logic_vector(31 downto 0);
    write_en : in  std_logic;
    read_en  : in  std_logic;
    size     : in  std_logic_vector(1 downto 0); -- "00"=byte, "01"=half, "10"=word
    sign     : in  std_logic;                    -- '1'=signed load, '0'=unsigned
    rdata    : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of data_mem is
  constant MEM_DEPTH : integer := 1024; -- 4 KB memory (1024 words)
  type mem_array is array (0 to MEM_DEPTH-1) of std_logic_vector(31 downto 0);
  signal mem : mem_array := (others => (others => '0'));

  signal addr_index : integer range 0 to MEM_DEPTH-1;
  signal read_word  : std_logic_vector(31 downto 0);
  signal read_val   : std_logic_vector(31 downto 0);
begin

  -- address index (word aligned)
  addr_index <= to_integer(unsigned(addr(11 downto 2)));

  ------------------------------------------------------------
  -- READ (combinational)
  ------------------------------------------------------------
  read_word <= mem(addr_index);

  process(read_en, size, sign, read_word, addr)
    variable byte_sel : integer range 0 to 3;
    variable tmp8  : std_logic_vector(7 downto 0);
    variable tmp16 : std_logic_vector(15 downto 0);
  begin
    if read_en = '1' then
      byte_sel := to_integer(unsigned(addr(1 downto 0)));
      case size is
        when "00" =>  -- BYTE
          tmp8 := read_word(8*byte_sel+7 downto 8*byte_sel);
          if sign = '1' then
            read_val <= std_logic_vector(resize(signed(tmp8), 32));
          else
            read_val <= std_logic_vector(resize(unsigned(tmp8), 32));
          end if;

        when "01" =>  -- HALFWORD
          if addr(1) = '0' then
            tmp16 := read_word(15 downto 0);
          else
            tmp16 := read_word(31 downto 16);
          end if;
          if sign = '1' then
            read_val <= std_logic_vector(resize(signed(tmp16), 32));
          else
            read_val <= std_logic_vector(resize(unsigned(tmp16), 32));
          end if;

        when others => -- WORD
          read_val <= read_word;
      end case;
    else
      read_val <= (others => '0');
    end if;
  end process;

  rdata <= read_val;

  ------------------------------------------------------------
  -- WRITE (synchronous)
  ------------------------------------------------------------
  process(clk)
    variable tmp : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        mem <= (others => (others => '0'));
      elsif write_en = '1' then
        tmp := mem(addr_index);
        case size is
          when "00" =>  -- BYTE
            case addr(1 downto 0) is
              when "00" => tmp(7 downto 0)   := wdata(7 downto 0);
              when "01" => tmp(15 downto 8)  := wdata(7 downto 0);
              when "10" => tmp(23 downto 16) := wdata(7 downto 0);
              when others => tmp(31 downto 24) := wdata(7 downto 0);
            end case;
          when "01" =>  -- HALFWORD
            if addr(1) = '0' then
              tmp(15 downto 0) := wdata(15 downto 0);
            else
              tmp(31 downto 16) := wdata(15 downto 0);
            end if;
          when others =>  -- WORD
            tmp := wdata;
        end case;
        mem(addr_index) <= tmp;
      end if;
    end if;
  end process;

end architecture;