----------------------------------------------------------------------------------
-- Company:        
-- Engineer:       simon.burkhardt / burkhardt@anapico.com
-- 
-- Create Date:    2024-01-10
-- Design Name:    Generic skidbuffer for AXI
-- Module Name:    skidbuffer
-- Project Name:   
-- Target Devices: 
-- Tool Versions:  GHDL 4.0.0-dev
-- Description:    skidbuffer for pipelining a bus handshake
--                 will always register the TREADY path from M <-- S
--                 option to also register the TDATA/TVALID path from M --> S
--
--                 AMBA AXI & ACE specification A3.1.1 requires:
--                 NO COMBINATORIAL paths between input and output interfaces
--
-- Dependencies:   
-- 
-- Revision: 2.0 - it never really worked until now
-- Additional Comments:
-- 
-- https://pavel-demin.github.io/red-pitaya-notes/axi-interface-buffers/
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

PACKAGE skidbuffer_pkg IS
    COMPONENT skidbuffer is
      generic (
        DATA_WIDTH  : integer := 32;
        OPT_DATA_REG : boolean := True
      );
      port (
        s_aclk    : in  std_logic;
        s_aresetn : in  std_logic;
        s_valid   : in  std_logic;
        s_ready   : out std_logic;
        s_data    : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        m_valid   : out std_logic;
        m_ready   : in  std_logic;
        m_data    : out std_logic_vector(DATA_WIDTH - 1 downto 0)
      );
    end COMPONENT;
END skidbuffer_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.skidbuffer_pkg.all;

entity skidbuffer is
  generic (
    DATA_WIDTH  : integer := 32;
    OPT_DATA_REG : boolean := True
  );
  port (
    s_aclk    : in  std_logic;
    s_aresetn : in  std_logic;
    s_valid   : in  std_logic;
    s_ready   : out std_logic;
    s_data    : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    m_valid   : out std_logic;
    m_ready   : in  std_logic;
    m_data    : out std_logic_vector(DATA_WIDTH - 1 downto 0)
  );
end skidbuffer;

architecture behav of skidbuffer is
  signal s_data_reg : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal o_data : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal o_valid : std_logic := '0';
  signal o_ready : std_logic := '0';
  signal i_ready : std_logic := '0';

  signal s_valid_reg : std_logic := '0';
  signal en_ready : std_logic := '0';

  signal o_data_reg : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal o_valid_reg : std_logic := '0';

begin
  p_reg : process(s_aclk) begin
    if rising_edge(s_aclk) then
      if s_aresetn = '0' then
        s_data_reg <= (others => '0');
        o_ready <= '0';
        s_valid_reg <= '0';
      else
        if o_ready = '1' then
          s_data_reg <= s_data;
          s_valid_reg <= s_valid;
        end if;
        if en_ready = '1' then
          o_ready <= i_ready;
        end if;
      end if;
    end if;
  end process;

  s_ready <= o_ready;
  
  en_ready <= s_valid OR (NOT o_ready);
  o_data <= s_data when o_ready = '1' else s_data_reg;
  o_valid <= s_valid when o_ready = '1' else s_valid_reg;
 
  gen_no_out_register : if not OPT_DATA_REG generate
    m_valid <= o_valid;
    m_data <= o_data;
    i_ready <= m_ready;
  end generate;

  gen_out_register : if OPT_DATA_REG generate

    p_out_reg : process(s_aclk) begin
      if rising_edge(s_aclk) then
        if s_aresetn = '0' then
          o_valid_reg <= '0';
          o_data_reg <= (others => '0');
        else
          if i_ready = '1' then
            o_valid_reg <= o_valid;
            o_data_reg <= o_data;
          end if;
        end if;
      end if;
    end process;

    i_ready <= m_ready OR (NOT o_valid_reg);
    m_data <= o_data_reg;
    m_valid <= o_valid_reg;

  end generate;


end behav;