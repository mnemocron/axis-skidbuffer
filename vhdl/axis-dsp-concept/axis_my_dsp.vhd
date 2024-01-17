----------------------------------------------------------------------------------
-- Company:        
-- Engineer:       simon.burkhardt
-- 
-- Create Date:    
-- Design Name:    
-- Module Name:    
-- Project Name:   
-- Target Devices: 
-- Tool Versions:  
-- Description:    
-- 
-- Dependencies:   
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_my_dsp is
  generic (
    C_S_AXIS_TDATA_WIDTH  : integer := 32
  );
  port (
    AXIS_ACLK : in std_logic;

    S_AXIS_TVALID : in  std_logic;
    S_AXIS_TDATA  : in  std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    S_AXIS_TREADY : out std_logic;

    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TREADY : in  std_logic
  );
end axis_my_dsp;

architecture arch_imp of axis_my_dsp is
  component skidbuffer is
    generic (
      DATA_WIDTH   : integer;
      OPT_DATA_REG : boolean
    );
    port (
      clock     : in std_logic;
      reset_n   : in std_logic;

      s_valid_i : in  std_logic;
      s_last_i  : in  std_logic;
      s_ready_o : out std_logic;
      s_data_i  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);

      m_valid_o : out std_logic;
      m_last_o  : out std_logic;
      m_ready_i : in  std_logic;
      m_data_o  : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
  end component;

  -- signals
  signal s_tvalid_skd : std_logic := '0';
  signal s_tdata_skd  : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
  signal s_tready_skd : std_logic := '0';

  signal m_tvalid_skd : std_logic := '0';
  signal m_tdata_skd  : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
  signal m_tready_skd : std_logic := '0';

  type tap_t is array (0 to 3) of signed(C_S_AXIS_TDATA_WIDTH-1 downto 0);
  signal taps : tap_t := (OTHERS => (OTHERS => '0'));
  type valid_t is array (0 to 3) of std_logic;
  signal valid_chain : valid_t := (OTHERS => '0');

begin

  upstream_buffer : skidbuffer
    generic map (
      DATA_WIDTH   => C_S_AXIS_TDATA_WIDTH,
      OPT_DATA_REG => True
    )
    port map (
      clock     => AXIS_ACLK,
      reset_n   => '1',
      s_valid_i => S_AXIS_TVALID,
      s_last_i  => '0',
      s_ready_o => S_AXIS_TREADY,
      s_data_i  => S_AXIS_TDATA,
      m_valid_o => s_tvalid_skd,
      m_last_o  => open,
      m_ready_i => s_tready_skd,
      m_data_o  => s_tdata_skd
    );

  s_tready_skd <= m_tready_skd;

  p_dsp_algorithm : process(AXIS_ACLK)
  begin 
    if rising_edge(AXIS_ACLK) then
      valid_chain(0) <= s_tvalid_skd;
      for i in 0 to 2 loop
        valid_chain(i+1) <= valid_chain(i);
      end loop;

      if s_tvalid_skd='1' and m_tready_skd='1' then
        taps(0) <= signed(s_tdata_skd)+1;
      end if;

      if valid_chain(0)='1' and m_tready_skd='1' then
        taps(1) <= taps(0) +1;
      end if;
      if valid_chain(1)='1' and m_tready_skd='1' then
        taps(2) <= taps(1) +1;
      end if;
      if valid_chain(2)='1' and m_tready_skd='1' then
        taps(3) <= taps(2) +1;
      end if;
    end if;
  end process;

  m_tdata_skd <= std_logic_vector(taps(3));
  m_tvalid_skd <= valid_chain(3);

  downstream_buffer : skidbuffer
    generic map (
      DATA_WIDTH   => C_S_AXIS_TDATA_WIDTH,
      OPT_DATA_REG => True
    )
    port map (
      clock     => AXIS_ACLK,
      reset_n   => '1',
      s_valid_i => m_tvalid_skd,
      s_last_i  => '0',
      s_ready_o => m_tready_skd,
      s_data_i  => m_tdata_skd,
      m_valid_o => M_AXIS_TVALID,
      m_last_o  => open,
      m_ready_i => M_AXIS_TREADY,
      m_data_o  => M_AXIS_TDATA
    );

end arch_imp;
