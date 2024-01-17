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


entity tb_axis_my_dsp is
  generic
  (
    DATA_WIDTH   : natural := 8;
    OPT_DATA_REG : boolean := True
  );
end tb_axis_my_dsp;

architecture bh of tb_axis_my_dsp is
  -- DUT component declaration
  component axis_my_dsp is
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
  end component;
  
  constant CLK_PERIOD: TIME := 5 ns;

  signal sim_valid_data  : std_logic := '0';
  signal sim_ready_data  : std_logic := '1';

  signal s_axis_tvalid : std_logic := '0';
  signal s_axis_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal s_axis_tready : std_logic := '0';

  signal m_axis_tvalid : std_logic := '0';
  signal m_axis_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal m_axis_tready : std_logic := '0';

  signal clk   : std_logic;
  signal rst_n : std_logic;

  signal clk_count : unsigned(7 downto 0) := (others => '0');
  signal sim_value  : unsigned(7 downto 0) := (others => '0');
begin

  -- generate clk signal
  p_clk_gen : process
  begin
   clk <= '1';
   wait for (CLK_PERIOD / 2);
   clk <= '0';
   wait for (CLK_PERIOD / 2);
   clk_count <= clk_count + 1;
  end process;

  -- generate initial reset
  p_reset_gen : process
  begin 
    rst_n <= '0';
    wait until rising_edge(clk);
    wait for (CLK_PERIOD / 4);
    rst_n <= '1';
    wait;
  end process;

  -- generate ready signal
  p_stimuli_tready : process(clk)
  begin
    if rising_edge(clk) then
      if clk_count = 3 then
        m_axis_tready <= '1';
      end if;

      if clk_count = 24 then
        m_axis_tready <= '0';
      end if;
      if clk_count = 25 then
        m_axis_tready <= '1';
      end if;
      if clk_count = 30 then
        m_axis_tready <= '0';
      end if;
      if clk_count = 32 then
        m_axis_tready <= '1';
      end if;
    end if;
  end process;

  -- generate valid signal
  p_stimuli_tvalid : process(clk)
  begin
    if rising_edge(clk) then
      if clk_count = 5 then
        sim_valid_data <= '1';
      end if;
      if clk_count = 6 then
        sim_valid_data <= '0';
      end if;

      if clk_count = 10 then
        sim_valid_data <= '1';
      end if;
      if clk_count = 12 then
        sim_valid_data <= '0';
      end if;

      if clk_count = 20 then
        sim_valid_data <= '1';
      end if;
    end if;
  end process;

  -- generate counter data when successfully acknowledged (tready) by slave
  p_stimuli_tdata : process(clk)
  begin
    if rising_edge(clk) then
      if sim_valid_data = '1' then
        s_axis_tvalid <= '1';
        if s_axis_tready = '1' then
          s_axis_tdata <= std_logic_vector(sim_value);
          sim_value <= sim_value+1;
        end if;
      else
        s_axis_tvalid <= '0';
      end if;
    end if;
  end process;

-- DUT instance and connections
  skidbuffer_inst : axis_my_dsp
  generic map (
    C_S_AXIS_TDATA_WIDTH  => DATA_WIDTH
  )
  port map (
    AXIS_ACLK     => clk,

    S_AXIS_TVALID => s_axis_tvalid,
    S_AXIS_TDATA  => s_axis_tdata, 
    S_AXIS_TREADY => s_axis_tready, 

    M_AXIS_TVALID => m_axis_tvalid, 
    M_AXIS_TDATA  => m_axis_tdata, 
    M_AXIS_TREADY => m_axis_tready
  );

end bh;
