----------------------------------------------------------------------------------
-- Company:        
-- Engineer:       simon.burkhardt
-- 
-- Create Date:    2023-04-21
-- Design Name:    skid buffer testbench
-- Module Name:    tb_skid - bh
-- Project Name:   
-- Target Devices: 
-- Tool Versions:  GHDL 0.37
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

-- this testbench acts as a streaming master, sending bursts of data
-- counting from 1-4

-- the testbench itself acts as a correct streaming master which keeps the data
-- until it is acknowledged by the DUT by asserting tready.

-- the data pattern can be influenced by the user in 2 ways
-- + Tx requests are generated by changing the pattern in p_stimuli_tready
--   the master will try to send data for as long as sim_valid_data = '1'
-- + Rx acknowledgements are generated by changing the pattern in p_stimuli_tready
--   the downstream slave after the DUT will signal ready-to-receive 
--   when sim_ready_data = '1'

-- simulate both with OPT_DATA_REG = True / False
entity tb_skid is
  generic
  (
    DATA_WIDTH   : natural := 8;
    OPT_DATA_REG : boolean := True
  );
end tb_skid;

architecture bh of tb_skid is
  -- DUT component declaration
  component skidbuffer is
    generic (
      DATA_WIDTH   : integer;
      OPT_DATA_REG : boolean
    );
    port (
      s_aclk     : in std_logic;
      s_aresetn  : in std_logic;

      s_valid : in  std_logic;
      s_ready : out std_logic;
      s_data  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);

      m_valid : out std_logic;
      m_ready : in  std_logic;
      m_data  : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
  end component;
  
  constant CLK_PERIOD: TIME := 5 ns;

  signal sim_valid_data  : std_logic := '0';
  signal sim_ready_data  : std_logic := '0';
  signal sim_data        : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal s_axis_tvalid : std_logic := '0';
  signal s_axis_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_axis_tready : std_logic := '0';

  signal m_axis_tvalid : std_logic := '0';
  signal m_axis_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal m_axis_tready : std_logic := '0';

  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';

  signal clk_count : unsigned(7 downto 0) := (others => '0');

  CONSTANT T_START_BURST_1 : integer := 2;
  CONSTANT T_START_BURST_2 : integer := 10;
  CONSTANT T_START_BURST_3 : integer := 20;
  CONSTANT T_START_BURST_4 : integer := 30;
  CONSTANT T_START_BURST_5 : integer := 40;
  CONSTANT T_START_BURST_7 : integer := 50;

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
    wait until rising_edge(clk);
    wait for (CLK_PERIOD / 4);
    rst_n <= '1';
    wait;
  end process;

  -- generate ready signal
  p_stimuli_tready : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        m_axis_tready <= '0';
      else
        m_axis_tready <= sim_ready_data;
        
        -- react to m_valid being asserted
        if clk_count = T_START_BURST_1+1 AND OPT_DATA_REG = False then
          sim_ready_data <= '1';
        end if;
        if clk_count = T_START_BURST_1+2 AND OPT_DATA_REG = True then
          sim_ready_data <= '1';
        end if;

        -- interrupt transfer mid-burst
        if clk_count = T_START_BURST_2+1 then
          sim_ready_data <= '0';
        end if;
        if clk_count = T_START_BURST_2+2 then
          sim_ready_data <= '1';
        end if;

        -- interrupt transfer right before burst -- keep low for min. 2 cycles
        if clk_count = T_START_BURST_3 then
          sim_ready_data <= '0';
        end if;
        if clk_count = T_START_BURST_3+3 then
          sim_ready_data <= '1';
        end if;

        -- interrupt transfer on last beat
        if clk_count = T_START_BURST_4+3 then
          sim_ready_data <= '0';
        end if;
        if clk_count = T_START_BURST_4+4 then
          sim_ready_data <= '1';
        end if;
        if clk_count = T_START_BURST_4+5 AND OPT_DATA_REG = False then
          sim_ready_data <= '0';
        end if;
        if clk_count = T_START_BURST_4+6 AND OPT_DATA_REG = True then
          sim_ready_data <= '0';
        end if;

        -- test if m_ready passes through even if s_valid = 0
        if clk_count = T_START_BURST_5-1 then
          sim_ready_data <= '1';
        end if;
        if clk_count = T_START_BURST_5+5 then
          sim_ready_data <= '0';
        end if;
        
        if clk_count = T_START_BURST_7+2 then
          sim_ready_data <= '1';
        end if;
        if clk_count = T_START_BURST_7+3 then
          sim_ready_data <= '0';
        end if;
        if clk_count = T_START_BURST_7+6 then
          sim_ready_data <= '1';
        end if;
        if clk_count = T_START_BURST_7+7 then
          sim_ready_data <= '0';
        end if;
        if clk_count = T_START_BURST_7+10 then
          sim_ready_data <= '1';
        end if;
        if clk_count = T_START_BURST_7+11 then
          sim_ready_data <= '0';
        end if;
        if clk_count = T_START_BURST_7+14 then
          sim_ready_data <= '1';
        end if;
        if clk_count = T_START_BURST_7+15 then
          sim_ready_data <= '0';
        end if;
        if clk_count = T_START_BURST_7+18 then
          sim_ready_data <= '1';
        end if;

      end if;
    end if;
  end process;

  -- generate valid signal
  p_stimuli_tvalid : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        sim_valid_data <= '0';
      else
        -- test if s_valid passes to m_valid if s_ready = 0
        if clk_count = T_START_BURST_1 then
          sim_valid_data <= '1';
        end if;
        if clk_count = T_START_BURST_1+4 then
          sim_valid_data <= '0';
        end if;

        -- interrupt transfer mid-burst
        if clk_count = T_START_BURST_2 then
          sim_valid_data <= '1';
        end if;
        if clk_count = T_START_BURST_2+5 then
          sim_valid_data <= '0';
        end if;
        
        -- interrupt transfer right before burst
        if clk_count = T_START_BURST_3 then
          sim_valid_data <= '1';
        end if;
        if clk_count = T_START_BURST_3+7 AND OPT_DATA_REG = False then
          sim_valid_data <= '0';
        end if;
        if clk_count = T_START_BURST_3+6 AND OPT_DATA_REG = True then
          sim_valid_data <= '0';
        end if;

        -- interrupt transfer on last beat
        if clk_count = T_START_BURST_4 then
          sim_valid_data <= '1';
        end if;
        if clk_count = T_START_BURST_4+4 then
          sim_valid_data <= '0';
        end if;

        -- test if m_ready passes through even if s_valid = 0
        if clk_count = T_START_BURST_5 then
          sim_valid_data <= '1';
        end if;
        if clk_count = T_START_BURST_5+4 then
          sim_valid_data <= '0';
        end if;

        if clk_count = T_START_BURST_7 then
          sim_valid_data <= '1';
        end if;
        if clk_count = T_START_BURST_7+12 then
          sim_valid_data <= '0';
        end if;

      end if;
    end if;
  end process;

  -- generate counter data when successfully acknowledged (tready) by slave
  p_stimuli_tdata : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        s_axis_tdata <= (others => '0');
        sim_data <= (others => '0');
      else
        if sim_valid_data = '1' then    -- VALID can be controlled
          if s_axis_tready = '1' then   -- READY can be controlled
            if unsigned(s_axis_tdata) = 4 then
              -- restart counter at "1"
              s_axis_tdata(DATA_WIDTH-1 downto 1) <= (others => '0');
              s_axis_tdata(0) <= '1';
              sim_data(DATA_WIDTH-1 downto 1) <= (others => '0');
              sim_data(0) <= '1';
            else
              if (unsigned(sim_data) > unsigned(s_axis_tdata)) and (unsigned(sim_data) < 4) then
                s_axis_tdata <= std_logic_vector(unsigned(sim_data) + 1);
              else
                s_axis_tdata <= std_logic_vector(unsigned(s_axis_tdata) + 1);
              end if;
              
              if unsigned(sim_data) = 4 then
                sim_data(DATA_WIDTH-1 downto 1) <= (others => '0');
                sim_data(0) <= '1';
              else
                sim_data <= std_logic_vector(unsigned(sim_data) + 1);
              end if;
            end if;
          else
            s_axis_tdata <= s_axis_tdata;
            sim_data <= sim_data;
          end if;

          if unsigned(s_axis_tdata) = 0 then
            s_axis_tdata(0) <= '1';
            sim_data(0) <= '1';
          end if;
          s_axis_tvalid <= '1';
        else 
          s_axis_tdata <= (others => '0');
          sim_data <= (others => '0');
          s_axis_tvalid <= '0';
        end if;
      end if;
    end if;
  end process;

-- DUT instance and connections
  skidbuffer_inst : skidbuffer
  generic map (
      DATA_WIDTH   => DATA_WIDTH,
      OPT_DATA_REG => OPT_DATA_REG
  )
  port map (
    s_aclk    => clk,
    s_aresetn => rst_n,

    s_valid => s_axis_tvalid,
    s_ready => s_axis_tready,
    s_data  => s_axis_tdata,

    m_valid => m_axis_tvalid,
    m_ready => m_axis_tready,
    m_data  => m_axis_tdata
  );

end bh;
