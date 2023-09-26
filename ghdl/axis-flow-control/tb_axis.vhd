----------------------------------------------------------------------------------
-- Company:        
-- Engineer:       simon.burkhardt
-- 
-- Create Date:    2023-04-21
-- Design Name:    skid buffer testbench
-- Module Name:    tb_axis - bh
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
-- counting from 1-4, also asserting tlast on the 4th data packet

-- the testbench itself acts as a correct streaming master which keeps the data
-- until it is acknowledged by the DUT by asserting tready.

-- the data pattern can be influenced by the user in 2 ways
-- + Tx requests are generated by changing the pattern in p_stimuli_tready
--   the master will try to send data for as long as sim_valid_data = '1'
-- + Rx acknowledgements are generated by changing the pattern in p_stimuli_tready
--   the downstream slave after the DUT will signal ready-to-receive 
--   when sim_ready_data = '1'

-- simulate both with OPT_DATA_REG = True / False
entity tb_axis is
  generic
  (
    DATA_WIDTH   : natural := 8;
    OPT_DATA_REG : boolean := True
  );
end tb_axis;

architecture bh of tb_axis is
  -- DUT component declaration
  component axis_flow_control is
    generic (
      C_S_AXIS_TDATA_WIDTH  : integer := 32
    );
    port (
      AXIS_ACLK : in std_logic;
      AXIS_ARESETN  : in std_logic;
 
      S_AXIS_TVALID : in  std_logic;
      S_AXIS_TDATA  : in  std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
      S_AXIS_TSTRB  : in  std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      S_AXIS_TLAST  : in  std_logic;
      S_AXIS_TREADY : out std_logic;
 
      M_AXIS_TVALID : out std_logic;
      M_AXIS_TDATA  : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
      M_AXIS_TSTRB  : out std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      M_AXIS_TLAST  : out std_logic;
      M_AXIS_TREADY : in  std_logic;

      xon  : in std_logic;
      xoff : in std_logic
    );
  end component;
  
  constant CLK_PERIOD: TIME := 5 ns;

  signal sim_valid_data  : std_logic := '0';
  signal sim_ready_data  : std_logic := '1';
  signal sim_data        : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal s_axis_tvalid : std_logic := '0';
  signal s_axis_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal s_axis_tstrb  : std_logic_vector((DATA_WIDTH/8)-1 downto 0);
  signal s_axis_tlast  : std_logic;
  signal s_axis_tready : std_logic;

  signal m_axis_tvalid : std_logic;
  signal m_axis_tdata  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal m_axis_tstrb  : std_logic_vector((DATA_WIDTH/8)-1 downto 0);
  signal m_axis_tlast  : std_logic;
  signal m_axis_tready : std_logic := '0';

  signal fifo_full  : std_logic;
  signal fifo_empty : std_logic;

  signal clk   : std_logic;
  signal rst_n : std_logic;

  signal clk_count : std_logic_vector(7 downto 0) := (others => '0');
  signal xfer_count : std_logic_vector(7 downto 0) := (others => '0');
begin

  -- generate clk signal
  p_clk_gen : process
  begin
   clk <= '1';
   wait for (CLK_PERIOD / 2);
   clk <= '0';
   wait for (CLK_PERIOD / 2);
   clk_count <= std_logic_vector(unsigned(clk_count) + 1);
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

  -- count transations
  p_xfer_cnt : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        xfer_count <= (others => '0');
      else
        if m_axis_tvalid = '1' and m_axis_tready = '1' then
          xfer_count <= m_axis_tdata;

        --  if unsigned(xfer_count) = 4 then
        --    xfer_count <= "00000001";
        --  else
        --    xfer_count <= std_logic_vector( unsigned(xfer_count) +1 );
        --  end if;
        
        end if;
      end if;
    end if;
  end process;

  -- generate ready signal
  p_stimuli_fifo : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        fifo_full <= '0';
        fifo_empty <= '1';
      else
        if unsigned(clk_count) = 40 then
          fifo_empty <= '0';
        end if;
        if unsigned(clk_count) = 48 then
          fifo_full <= '1';
        end if;
        if unsigned(clk_count) = 58 then
          fifo_full <= '0';
        end if;
        if unsigned(clk_count) = 65 then
          fifo_empty <= '1';
        end if;

      end if;
    end if;
  end process;

  -- generate ready signal
  p_stimuli_tready : process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        m_axis_tready <= '1';
      else
        m_axis_tready <= sim_ready_data;
        if unsigned(clk_count) = 2 then
          sim_ready_data <= '1';
        end if;
        if unsigned(clk_count) = 7 then
          sim_ready_data <= '0';
        end if;
        if unsigned(clk_count) = 8 then
          sim_ready_data <= '1';
        end if;
        if unsigned(clk_count) = 11 then
          sim_ready_data <= '0';
        end if;
        if unsigned(clk_count) = 13 then
          sim_ready_data <= '1';
        end if;
        if unsigned(clk_count) = 14 then
          sim_ready_data <= '0';
        end if;
        if unsigned(clk_count) = 15 then
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
        if unsigned(clk_count) = 2 then
          sim_valid_data <= '1';
        end if;
        if unsigned(clk_count) = 18 then
          sim_valid_data <= '0';
        end if;
        if unsigned(clk_count) = 21 then
          sim_valid_data <= '1';
        end if;
        if unsigned(clk_count) = 23 then
          sim_valid_data <= '0';
        end if;
        if unsigned(clk_count) = 24 then
          sim_valid_data <= '1';
        end if;
        if unsigned(clk_count) = 26 then
          sim_valid_data <= '0';
        end if;

        if unsigned(clk_count) = 32 then
          sim_valid_data <= '1';
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
        s_axis_tstrb <= (others => '0');
        sim_data <= (others => '0');
        s_axis_tlast <= '0';
      else
        if sim_valid_data = '1' then    -- VALID can be controlled
          if s_axis_tready = '1' then   -- READY can be controlled
            if unsigned(s_axis_tdata) = 3 then
              s_axis_tlast <= '1';
            else 
              s_axis_tlast <= '0';
            end if;

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
          s_axis_tvalid <= '1';
          s_axis_tstrb <= "1";
        else 
          s_axis_tvalid <= '0';
          s_axis_tstrb <= "0";
          s_axis_tlast <= '0';
          s_axis_tdata <= (others => '0');
          sim_data <= sim_data;
        end if;
      end if;
    end if;
  end process;

-- DUT instance and connections
  skidbuffer_inst : axis_flow_control
  generic map (
    C_S_AXIS_TDATA_WIDTH  => DATA_WIDTH
  )
  port map (
    AXIS_ACLK     => clk,
    AXIS_ARESETN  => rst_n,

    S_AXIS_TVALID => s_axis_tvalid,
    S_AXIS_TDATA  => s_axis_tdata, 
    S_AXIS_TSTRB  => s_axis_tstrb, 
    S_AXIS_TLAST  => s_axis_tlast, 
    S_AXIS_TREADY => s_axis_tready, 

    M_AXIS_TVALID => m_axis_tvalid, 
    M_AXIS_TDATA  => m_axis_tdata, 
    M_AXIS_TSTRB  => m_axis_tstrb, 
    M_AXIS_TLAST  => m_axis_tlast, 
    M_AXIS_TREADY => m_axis_tready,

    xon  => fifo_empty, 
    xoff => fifo_full
  );

end bh;