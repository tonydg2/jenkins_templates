-------------------------------------------------------------------------------
-- Title      : Generic CRC
-- Project    : 
-------------------------------------------------------------------------------
-- File       : generic_crc.vhd
-- Author     : Anthony Goodwin
-- Company    : 
-- Created    : 2021-02-24
-- Last update: 2021-02-24
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Generic CRC
-- Generic to polynomial value and length, data length, initial conditions, 
-- direct/nondirect methods, input data byte refelection, checksum reflection, 
-- final XOR, checksums per frame.
-------------------------------------------------------------------------------
-- Copyright (c) 2021 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-02-24  1.0      adg	    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

entity generic_crc is
  generic (
    Polynomial        : std_logic_vector  := "100000111"; -- default = z^8 + z^2 + z + 1
    InitialConditions : std_logic_vector  := "0";         --
    DirectMethod      : std_logic         := '1';         -- more efficient, zero shifts not needed as in non-direct
    ReflectInputBytes : std_logic         := '0';         --
    ReflectChecksums  : std_logic         := '0';         --
    FinalXOR          : std_logic_vector  := "0";         --
    ChecksumsPerFrame : integer           := 1            -- N/A
    );
  port (
    clk               : in  std_logic;
    rst               : in  std_logic;
    crc_en            : in  std_logic;
    data              : in  std_logic_vector;
    checksum          : out std_logic_vector; -- length of polynomial - 1
    checksum_rdy      : out std_logic
    );
end generic_crc;

architecture rtl of generic_crc is
-- components

-- constants
constant dataLen        : integer := (data'length - 1);
constant checksumLen    : integer := (Polynomial'length - 2);

-- types
type crc_sm_type is (IDLE, SHIFT, NONDIRECT_FLUSH, DIRECT_END);
signal crc_sm : crc_sm_type;

-- signals
signal data_r           : std_logic_vector(dataLen downto 0);
signal data_i           : std_logic_vector(dataLen downto 0);
signal crc_en_sr        : std_logic_vector(1 downto 0);
signal b                : std_logic;
signal data_idx         : integer range 0 to (dataLen + 1);
signal crc_calc_en      : std_logic;
signal checksum_i       : std_logic_vector(checksumLen downto 0);
signal checksum_reflect : std_logic_vector(checksumLen downto 0);
signal pre_checksum_rdy : std_logic;
signal checksum_rdy_i   : std_logic;
signal poly             : std_logic_vector((Polynomial'length - 1) downto 0);-- := "100000111";-- z^8 + z^2 + z + 1
signal d                : std_logic_vector((poly'length - 2) downto 0);

----------------------------------------------------------------------------------------------------
begin  -- architecture
-------------------------------------------------------------------------------------------------       

--**!! instead of checking index format and flipping bits, use an alias instead: 
--    alias Constrained_Port : std_logic_vector(Unconstrained_Port'length -1 downto 0) is Unconstrained_Port ; 
-- see my stack overflow answer (simulate to verify first)

-- Unconstrained std_logic_vectors (if not explicit in the declared signal of the higher level
-- entity where this component is instantiated) are default increasing index (0 to x, instead of x downto 0), 
-- so flip the Polynomial and data vectors first to be in decreasing index "downto" format. Check if the 
-- polynomial is ascending index and flip it.
AscendingPolyGen : if (Polynomial'ascending = true) generate -- (0 to x) format? If so, flip the vector
  PolyFlipGen : for i in 0 to (Polynomial'length - 1) generate
    poly(i) <= Polynomial((Polynomial'length - 1) - i);
  end generate;
--else generate -- vhdl 2008 only
--  poly <= polynomial;
end generate;

-- if/else generate supported in vhdl 2008, older versions need two generate statements
DescendingPolyGen : if (Polynomial'ascending = false) generate
  poly <= Polynomial;
end generate;

-- Same as above but with data, make sure in descending index format.
AscendingDataGen : if (data'ascending = true) generate
  DataFlipGen : for i in 0 to (data'length - 1) generate
    data_r(i) <= data((data'length - 1) - i);
  end generate;
  --else generate -- vhdl 2008 only
  --  data_r    <= data;
end generate;

-- if/else generate supported in vhdl 2008, older versions need two generate statements
DescendingDataGen : if (data'ascending = false) generate
  data_r    <= data;
end generate;

-- top IO
checksum     <= checksum_i;
checksum_rdy <= checksum_rdy_i;


-- reflect input data
-- this might have redundancy due to the above flipping operation, but...gonna leave it, synthesis tools 
-- will optimize.
ReflectInputBytesGen : if (ReflectInputBytes = '1') generate
  DataReflectGen : for i in 0 to (data_r'length - 1) generate
    data_i(i) <= data_r((data_r'length - 1) - i);
  end generate;
  --else generate -- vhdl 2008
  -- data_i <= data_r;
end generate;

ReflectInputBytesGen2 : if (ReflectInputBytes = '0') generate
  data_i <= data_r;
end generate;


-- serialize input data vector
serialize_data : process(clk)
begin
  if rst = '1' then -- async, change to sync
    b                <= '0';
    data_idx         <= dataLen;
    crc_calc_en      <= '0';
    pre_checksum_rdy <= '0';
    crc_sm           <= IDLE;
    crc_en_sr        <= (others => '0');
  elsif rising_edge(clk) then
    pre_checksum_rdy <= '0';
    crc_en_sr        <= crc_en_sr(0) & crc_en; -- shift reg for edge detect
    case crc_sm is
      when IDLE =>
        if crc_en_sr = "01" then  -- rising edge
          crc_calc_en <= '1';
          crc_sm      <= SHIFT;
          b           <= data_i(data_idx);
          data_idx    <= dataLen - 1;
        end if;

      when SHIFT =>
        b <= data_i(data_idx);
        if (data_idx = 0) then
          data_idx <= dataLen + 1;
          if (DirectMethod = '0') then
            crc_sm  <= NONDIRECT_FLUSH;
          else
            crc_sm  <= DIRECT_END;
          end if;
        else
          data_idx <= data_idx - 1;
        end if;

      -- NonDirect method, flush with zero's.
      when NONDIRECT_FLUSH => 
        b <= '0';
        if (data_idx = 0) then
          crc_calc_en      <= '0';
          crc_sm           <= IDLE;
          pre_checksum_rdy <= '1';
          data_idx         <= dataLen;
        else
          data_idx <= data_idx - 1;
        end if;

      -- Direct method, no flush.
      when DIRECT_END => 
        b                <= '0';
        crc_calc_en      <= '0';
        crc_sm           <= IDLE;
        pre_checksum_rdy <= '1';
        data_idx         <= dataLen;

    end case;
  end if;
end process;

-- Requires at least 1 full clk cycle after coming out of reset to allow initial conditions to update.
NonDirect_method : if (DirectMethod = '0') generate 
  crc_direct : process(clk)
  begin
    if rst = '1' then
      d <= (others => '0');
    elsif rising_edge(clk) then
      if crc_calc_en = '1' then
        -- first shift is always constant
        d(0) <= b xor d(d'length - 1); -- z^0
        -- remaining shifts depend on polynomial
        poly_shift_gen : for i in 1 to (d'length - 1) loop -- z^1 ...
          d(i) <= d(i-1) xor (d(d'length - 1) and poly(i));
        end loop;
      else
        if InitialConditions = "0" then
          d <= (others => '0');
        elsif InitialConditions = "1" then
          d <= (others => '1');
        elsif (InitialConditions'length /= d'length) then
          report "InitialConditions vector length mismatch" severity failure;
        else
          d <= InitialConditions;
        end if;
      end if;
    end if;
  end process;
end generate;


-- Requires at least 1 full clk cycle after coming out of reset to allow initial conditions to update.
Direct_method : if (DirectMethod = '1') generate 
  crc_direct : process(clk)
  begin
    if rst = '1' then
      d <= (others => '0');
    elsif rising_edge(clk) then
      if crc_calc_en = '1' then
        -- first shift is always constant
        d(0) <= b xor d(d'length - 1); -- z^0
        -- remaining shifts depend on polynomial
        poly_shift_gen : for i in 1 to (d'length - 1) loop -- z^1 ...
          d(i) <= d(i-1) xor (d(d'length - 1) and poly(i)) xor (b and poly(i));
        end loop;
      else
        if InitialConditions = "0" then
          d <= (others => '0');
        elsif InitialConditions = "1" then
          d <= (others => '1');
        elsif (InitialConditions'length /= d'length) then
          report "InitialConditions vector length mismatch" severity failure;
        else
          d <= InitialConditions;
        end if;
      end if;
    end if;
  end process;
end generate;


-- reflect checksum before final XOR
ReflectChecksumGen : if (ReflectChecksums = '1') generate
  ReflectChecksumBitsGen : for i in 0 to (d'length - 1) generate
    checksum_reflect(i) <= d((d'length - 1) - i);
  end generate;
  --else generate -- vhdl 2008
  -- checksum_reflect <= d;
end generate;

ReflectChecksumGen2 : if (ReflectChecksums = '0') generate
  checksum_reflect <= d;
end generate;


-- final XOR, latch checksum value, and pulse ready strobe
checksum_latch : process(clk)
begin
  if rst = '1' then
    checksum_i     <= (others => '0');
    checksum_rdy_i <= '0';
  elsif rising_edge(clk) then
    checksum_rdy_i <= pre_checksum_rdy;  -- 1clk delay
    if pre_checksum_rdy = '1' then
      if FinalXOR = "1" then
        checksum_i <= checksum_reflect xor x"ff";
      elsif FinalXOR = "0" then
        checksum_i <= checksum_reflect;
      elsif (FinalXOR'length /= checksum_i'length) then
        report "FinalXOR vector length mismatch" severity failure;
      else
        checksum_i <= checksum_reflect xor FinalXOR;
      end if;
    end if;
  end if;
end process;


----------------------------------------------------------------------------------------------------
-- parallel
----------------------------------------------------------------------------------------------------

--p(7) <= b xor data_i()



end architecture rtl;



-- 1021 = 
-- 1 0001 0000 0010 0001 = 
-- 
-- z^16 + z^12 + z^5 + 1
-- 
--   next_crc(0)  <= data_in(7) xor data_in(0) xor crc_reg(4) xor crc_reg(11);
--   next_crc(1)  <= data_in(1) xor crc_reg(5);
--   next_crc(2)  <= data_in(2) xor crc_reg(6);
--   next_crc(3)  <= data_in(3) xor crc_reg(7);
--   next_crc(4)  <= data_in(7) xor data_in(5) xor data_in(0) xor crc_reg(4) xor crc_reg(9) xor crc_reg(11);
--   next_crc(6)  <= data_in(6) xor data_in(1) xor crc_reg(5) xor crc_reg(10);
--   next_crc(7)  <= data_in(7) xor data_in(2) xor crc_reg(6) xor crc_reg(11);
--   next_crc(8)  <= data_in(3) xor crc_reg(0) xor crc_reg(7);
--   next_crc(9)  <= data_in(4) xor crc_reg(1) xor crc_reg(8);
--   next_crc(10) <= data_in(5) xor crc_reg(2) xor crc_reg(9);
--   next_crc(11) <= data_in(6) xor crc_reg(3) xor crc_reg(10);
