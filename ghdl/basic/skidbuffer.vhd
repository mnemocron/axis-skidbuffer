----------------------------------------------------------------------------------
-- Company:        
-- Engineer:       simon.burkhardt
-- 
-- Create Date:    2023-04-21
-- Design Name:    Generic skidbuffer for AXI
-- Module Name:    skidbuffer
-- Project Name:   
-- Target Devices: 
-- Tool Versions:  GHDL 0.37
-- Description:    skidbuffer for pipelining a bus handshake
-- 
-- Dependencies:   
-- 
-- Revision: 1.0 - Fixed fundamental flaw when m_tready='0' at start of transaction 
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
  -- register signals
  signal reg_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal reg_valid : std_logic;
  signal reg_ready : std_logic;

  -- skid buffer signals (only used when OPT_DATA_REG = '1')
  signal skd_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal skd_valid : std_logic;

  -- output signals for output multiplexer
  signal out_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal out_valid : std_logic;

begin
  -- I/O connections assignments
  s_ready <= reg_ready;

  -- ready is always registered in skidbuffer
  p_reg_ready : process(s_aclk)
  begin
    if rising_edge(s_aclk) then 
      if s_aresetn = '0' then
        reg_ready <= '0';
      else
        reg_ready <= m_ready;
      end if;
    end if;
  end process;

  -- output of the skidbuffer (either registered or bypass)
  out_data  <= skd_data  when (reg_ready = '0') else s_data;
  out_valid <= skd_valid when (reg_ready = '0') else s_valid;

  -- actual skidbuffer register
  p_reg : process (s_aclk)
  begin
    if rising_edge(s_aclk) then 
      if s_aresetn = '0' then
        skd_data  <= (others => '0');
        skd_valid <= '0';
      else
        if reg_ready = '1' then
          skd_data <= s_data;
          skd_valid <= s_valid;
        else
          skd_data <= skd_data;
          skd_valid <= skd_valid;
        end if;
      end if;
    end if;
  end process;

-- NOT REGISTERED OUTPUT -------------------------------------------------------
  gen_no_register : if not OPT_DATA_REG generate
    -- output multiplexer
    m_valid <= out_valid;
    m_data  <= out_data;
  end generate;

-- FULLY REGISTERED OUTPUT -----------------------------------------------------
  gen_data_register : if OPT_DATA_REG generate
    process(s_aclk) begin
      if rising_edge(s_aclk) then
        if m_ready = '1' then
          -- if: m_ is ready, continue feeding stream
          m_data <= out_data;
          m_valid <= out_valid; 
          -- else: hold value until m_ acknowledges transaction
        end if;
      end if;
    end process;
  end generate;

end behav;
