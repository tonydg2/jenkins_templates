--
--
library ieee, crc_lib;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
use std.env.finish;

entity generic_crc_tb is
end entity generic_crc_tb;

architecture bhv of generic_crc_tb is
-- constants

-- procedures

-- types
  --type unc_slv is array (integer range <>) of std_logic_vector;
-- signals
signal clk          : std_logic := '0';
signal clk_n        : std_logic;
signal rst          : std_logic := '1';
signal crc_en       : std_logic := '0';

signal checksum_rdy : std_logic;

--signal  poly         : std_logic_vector(9 downto 0) := "1100000111";
signal  data          : std_logic_vector(7 downto 0) := x"f7";
signal checksum       : std_logic_vector(7 downto 0);
--signal checksum_verify: std_logic_vector(7 downto 0);
----------------------------------------------------------------------------------------------------
begin  -- architecture
----------------------------------------------------------------------------------------------------
clk   <= not clk after 2.5 ns;        -- 200mhz
clk_n <= not clk;



stimulus : process  
  procedure re (
  	signal sig : in std_logic) is
  begin
  	wait until rising_edge(sig);
  end;
  
  procedure fe (
  	signal sig : in std_logic) is
  begin
  	wait until falling_edge(sig);
  end;

  procedure wf (
    time_in : time) is
  begin
    wait for time_in;
  end;

  procedure crcProc (
  	data_i	: in std_logic_vector) is
  begin 
  	data <= data_i;
  	re(clk);
  	fe(clk);
  	crc_en <= '1';
  	fe(clk);
  	crc_en <= '0';
  end;
begin
  wf(100 ns);
  rst <= not rst;
  
  wf(20 ns);crcProc("10101111");-- 44
  wf(58 ns);crcProc("10101110");-- 43
  wf(58 ns);crcProc("10111110");-- 33
  wf(58 ns);crcProc("11101110");-- 84

  wait on checksum_rdy;
  wf(10 ns);

  report "Test: OK" severity note;
  finish; -- VHDL-2008

 -- if poly'ascending = true then
 --   report "*** true*****";
 -- else
 --   report "*** false*****";
 -- end if;
  --wait;
end process;

self_checker : process
  variable checksum_verify: std_logic_vector(7 downto 0);
begin
  wait on crc_en;
  
  case data is
    when "10101111" => checksum_verify := x"44"; --  44
    when "10101110" => checksum_verify := x"43"; --  43
    when "10111110" => checksum_verify := x"33"; --  33
    when "11101110" => checksum_verify := x"84"; --  84
    when others     => checksum_verify := x"00"; --  
  end case;
    
  wait on checksum_rdy;
  
  assert (checksum = checksum_verify)
    report "CRC FAIL"
    severity failure;
  
end process;



-- 63ns delay from crc_en --> checksum_rdy
generic_crc : entity crc_lib.generic_crc
  generic map (
    Polynomial        => "100000111",   -- std_logic_vector := "100000111";-- default = z^8 + z^2 + z + 1
    InitialConditions => "0",           -- std_logic_vector := "0";
    DirectMethod      => '1',           -- std_logic := '0';
    ReflectInputBytes => '0',           -- std_logic := '0';
    ReflectChecksums  => '0',           -- std_logic := '0';
    FinalXOR          => "0",           -- std_logic_vector := "0";
    ChecksumsPerFrame => 1              -- integer := 1
    )
  port map (
    clk               => clk,           -- in  std_logic;
    rst               => rst,           -- in  std_logic;
    crc_en            => crc_en,        -- in  std_logic;
    data              => data,          -- in  std_logic_vector(7 downto 0);
    checksum          => checksum,      -- out std_logic_vector(7 downto 0);
    checksum_rdy      => checksum_rdy   -- out std_logic
    );






end architecture bhv;

