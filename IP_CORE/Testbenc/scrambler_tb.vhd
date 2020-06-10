library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity scrambler_tb is
	--  Port ( );
end scrambler_tb;

architecture Behavioral of scrambler_tb is

	constant DATA_WIDTH_c : integer := 32;
	constant ADDR_WIDTH_c : integer := 32;

	------------------------------------------------------------------

	signal clk_s : std_logic;
	signal reset_s : std_logic;
	---------------------- Scrambler core's address map-------------------------
	constant RESET_REG_ADDR_C : integer := 0;
	constant START_REG_ADDR_C : integer := 4;
	constant STATUS_REG_ADDR_C : integer := 8;
	---------------------- Ports for BRAM Initialization ----------------------  
	signal tb_a_en_i : std_logic;
	signal tb_a_addr_i : std_logic_vector(ADDR_WIDTH_c - 1 downto 0);
	signal tb_a_data_i : std_logic_vector(DATA_WIDTH_c - 1 downto 0);
	signal tb_a_we_i : std_logic;

	signal tb_c_en_i : std_logic;
	signal tb_c_addr_i : std_logic_vector(ADDR_WIDTH_c - 1 downto 0);
	signal tb_c_data_o : std_logic_vector(DATA_WIDTH_c - 1 downto 0);
	signal tb_c_we_i : std_logic;

	------------------------- Ports to scrambler ---------------------------------
	signal ip_a_en : std_logic;
	signal ip_a_we : std_logic;

	signal ip_a_addr : std_logic_vector(ADDR_WIDTH_c - 1 downto 0);
	signal ip_a_data : std_logic_vector(DATA_WIDTH_c - 1 downto 0);

	signal ip_b_en : std_logic;
	signal ip_b_addr : std_logic_vector(DATA_WIDTH_c - 1downto 0);
	signal ip_b_addr_b : std_logic_vector(DATA_WIDTH_c - 1downto 0);

	signal ip_b_data_i : std_logic_vector(DATA_WIDTH_c - 1 downto 0);
	signal ip_b_data_o : std_logic_vector(DATA_WIDTH_c - 1 downto 0);
	signal ip_b_we : std_logic;
	signal ip_b_we_b : std_logic;
	signal ip_b_en_b : std_logic;
	signal ip_c_en : std_logic;
	signal ip_c_addr : std_logic_vector(ADDR_WIDTH_c - 1 downto 0);
	signal ip_c_data : std_logic_vector(DATA_WIDTH_c - 1 downto 0);
	signal ip_c_we : std_logic;

	------------------- AXI Interfaces signals -------------------
	-- Parameters of Axi-Lite Slave Bus Interface S00_AXI
	constant C_S00_AXI_DATA_WIDTH_c : integer := 32;
	constant C_S00_AXI_ADDR_WIDTH_c : integer := 4;

	-- Ports of Axi-Lite Slave Bus Interface S00_AXI
	signal s00_axi_aclk_s : std_logic := '0';
	signal s00_axi_aresetn_s : std_logic := '1';
	signal s00_axi_awaddr_s : std_logic_vector(C_S00_AXI_ADDR_WIDTH_c - 1 downto 0) := (others => '0');
	signal s00_axi_awprot_s : std_logic_vector(2 downto 0) := (others => '0');
	signal s00_axi_awvalid_s : std_logic := '0';
	signal s00_axi_awready_s : std_logic := '0';
	signal s00_axi_wdata_s : std_logic_vector(C_S00_AXI_DATA_WIDTH_c - 1 downto 0) := (others => '0');
	signal s00_axi_wstrb_s : std_logic_vector((C_S00_AXI_DATA_WIDTH_c/8) - 1 downto 0) := (others => '0');
	signal s00_axi_wvalid_s : std_logic := '0';
	signal s00_axi_wready_s : std_logic := '0';
	signal s00_axi_bresp_s : std_logic_vector(1 downto 0) := (others => '0');
	signal s00_axi_bvalid_s : std_logic := '0';
	signal s00_axi_bready_s : std_logic := '0';
	signal s00_axi_araddr_s : std_logic_vector(C_S00_AXI_ADDR_WIDTH_c - 1 downto 0) := (others => '0');
	signal s00_axi_arprot_s : std_logic_vector(2 downto 0) := (others => '0');
	signal s00_axi_arvalid_s : std_logic := '0';
	signal s00_axi_arready_s : std_logic := '0';
	signal s00_axi_rdata_s : std_logic_vector(C_S00_AXI_DATA_WIDTH_c - 1 downto 0) := (others => '0');
	signal s00_axi_rresp_s : std_logic_vector(1 downto 0) := (others => '0');
	signal s00_axi_rvalid_s : std_logic := '0';
	signal s00_axi_rready_s : std_logic := '0';
begin
	reset_s <= not s00_axi_aresetn_s; --reset for BRAM

	clk_gen : process is
	begin
		clk_s <= '0', '1' after 50 ns;
		wait for 100 ns;
	end process;
	stimulus_generator : process
	begin
		report "Start !";

		-- reset AXI-lite interface. Reset will be 10 clock cycles wide
		s00_axi_aresetn_s <= '0';
		-- wait for 5 falling edges of AXI-lite clock signal
		for i in 1 to 5 loop
			wait until falling_edge(clk_s);
		end loop;
		-- release reset
		s00_axi_aresetn_s <= '1';
		wait until falling_edge(clk_s);
		-----local reset for scrambler module----------
		s00_axi_awaddr_s <= conv_std_logic_vector(RESET_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
		s00_axi_awvalid_s <= '1';
		s00_axi_wdata_s <= conv_std_logic_vector(1, C_S00_AXI_DATA_WIDTH_c);
		s00_axi_wvalid_s <= '1';
		s00_axi_wstrb_s <= "1111";
		s00_axi_bready_s <= '1';
		wait until s00_axi_awready_s = '1';
		wait until s00_axi_awready_s = '0';
		wait until falling_edge(clk_s);
		s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
		s00_axi_awvalid_s <= '0';
		s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
		s00_axi_wvalid_s <= '0';
		s00_axi_wstrb_s <= "0000";
		wait until s00_axi_bvalid_s = '0';
		wait until falling_edge(clk_s);
		s00_axi_bready_s <= '0';
		wait until falling_edge(clk_s);
		---------hold reset for 5 clock cycles.
		for i in 1 to 5 loop
			wait until falling_edge(clk_s);
		end loop;

		-------------release local reset---------------
		s00_axi_awaddr_s <= conv_std_logic_vector(RESET_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
		s00_axi_awvalid_s <= '1';
		s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
		s00_axi_wvalid_s <= '1';
		s00_axi_wstrb_s <= "1111";
		s00_axi_bready_s <= '1';
		wait until s00_axi_awready_s = '1';
		wait until s00_axi_awready_s = '0';
		wait until falling_edge(clk_s);
		s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
		s00_axi_awvalid_s <= '0';
		s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
		s00_axi_wvalid_s <= '0';
		s00_axi_wstrb_s <= "0000";
		wait until s00_axi_bvalid_s = '0';
		wait until falling_edge(clk_s);
		s00_axi_bready_s <= '0';
		wait until falling_edge(clk_s);

		------------Loading elements values into the core------------
		report "Loading elements values into the core!";
		wait until falling_edge(clk_s);
		for i in 1 to 8192 loop
			wait until falling_edge(clk_s);
			tb_a_en_i <= '1';
			tb_a_addr_i <= conv_std_logic_vector(i * 4, ADDR_WIDTH_c); --STAVLJAMO *4 ZBOG BRAMA
			tb_a_data_i <= conv_std_logic_vector(i, DATA_WIDTH_c);
			tb_a_we_i <= '1';

			wait until rising_edge(clk_s);
			tb_a_en_i <= '0';
			tb_a_we_i <= '0';
		end loop;
		tb_a_en_i <= '0';
		tb_a_we_i <= '0';

		-----------Start for scrambler module-------------
		wait until falling_edge(clk_s);
		s00_axi_awaddr_s <= conv_std_logic_vector(START_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
		s00_axi_awvalid_s <= '1';
		s00_axi_wdata_s <= conv_std_logic_vector(1, C_S00_AXI_DATA_WIDTH_c);
		s00_axi_wvalid_s <= '1';
		s00_axi_wstrb_s <= "1111";
		s00_axi_bready_s <= '1';
		wait until s00_axi_awready_s = '1';
		wait until s00_axi_awready_s = '0';
		wait until falling_edge(clk_s);
		s00_axi_awaddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
		s00_axi_awvalid_s <= '0';
		s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
		s00_axi_wvalid_s <= '0';
		s00_axi_wstrb_s <= "0000";
		wait until s00_axi_bvalid_s = '0';
		wait until falling_edge(clk_s);
		s00_axi_bready_s <= '0';
		wait until falling_edge(clk_s);
		-- wait for 5 falling edges of AXI-lite clock signal
		for i in 1 to 5 loop
			wait until falling_edge(clk_s);
		end loop;
		report "Clearing the start bit!";
		--------------release start bit------------
		wait until falling_edge(clk_s);
		s00_axi_awaddr_s <= conv_std_logic_vector(START_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
		s00_axi_awvalid_s <= '1';
		s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
		s00_axi_wvalid_s <= '1';
		s00_axi_wstrb_s <= "1111";
		s00_axi_bready_s <= '1';
		wait until s00_axi_awready_s = '1';
		wait until s00_axi_awready_s = '0';
		wait until falling_edge(clk_s);
		s00_axi_awaddr_s <= conv_std_logic_vector(4, C_S00_AXI_ADDR_WIDTH_c);
		s00_axi_awvalid_s <= '0';
		s00_axi_wdata_s <= conv_std_logic_vector(0, C_S00_AXI_DATA_WIDTH_c);
		s00_axi_wvalid_s <= '0';
		s00_axi_wstrb_s <= "0000";
		wait until s00_axi_bvalid_s = '0';
		wait until falling_edge(clk_s);
		s00_axi_bready_s <= '0';
		wait until falling_edge(clk_s);

		report "Waiting for the convolution process to complete!";
		loop
			-- Read the content of the Status register
			wait until falling_edge(clk_s);
			s00_axi_araddr_s <= conv_std_logic_vector(STATUS_REG_ADDR_C, C_S00_AXI_ADDR_WIDTH_c);
			s00_axi_arvalid_s <= '1';
			s00_axi_rready_s <= '1';
			wait until s00_axi_arready_s = '1';
			wait until s00_axi_arready_s = '0';
			wait until falling_edge(clk_s);
			s00_axi_araddr_s <= conv_std_logic_vector(0, C_S00_AXI_ADDR_WIDTH_c);
			s00_axi_arvalid_s <= '0';
			s00_axi_rready_s <= '0';

			-- Check is the 1st bit of the Status register set to one
			if (s00_axi_rdata_s(0) = '1') then
				-- convolution process completed
				exit;
			else
				wait for 1000 ns;
			end if;
		end loop;

		-- report "Reading the results of the C bram!";

		for k in 1 to 8192 loop
			wait until falling_edge(clk_s);
			tb_c_en_i <= '1';
			tb_c_we_i <= '0';
			tb_c_addr_i <= conv_std_logic_vector (k * 4, ADDR_WIDTH_c);

			wait until rising_edge(clk_s);
		end loop;

		tb_c_en_i <= '0';
		report "Finished!";
		wait;
	end process;

	---------------------------------------------------------------------------
	---- DUT --
	---------------------------------------------------------------------------
	uut : entity work. scrambler_axi_ip_v1_0(arch_imp)
		generic map(
			WIDTH => DATA_WIDTH_c,
			ADDR_WIDTH => ADDR_WIDTH_c
		)
		port map(
			-- Interface to the BRAM A module
			ena => ip_a_en,
			addra => ip_a_addr,
			douta => ip_a_data,
			reseta => open,
			clka => open,

			-- Interface to the BRAM B module

			enb => ip_b_en,
			enb_b => ip_b_en_b,
			web => ip_b_we,

			addrb => ip_b_addr,
			addrb_b => ip_b_addr_b,

			dinb => ip_b_data_o,
			doutb => ip_b_data_i,
			resetb => open,
			clkb => open,

			--Interface to the BRAM C module
			enc => ip_c_en,
			wec => ip_c_we,
			addrc => ip_c_addr,
			dinc => ip_c_data,
			resetc => open,
			clkc => open,

			-- Ports of Axi Slave Bus Interface S00_AXI
			s00_axi_aclk => clk_s,
			s00_axi_aresetn => s00_axi_aresetn_s,
			s00_axi_awaddr => s00_axi_awaddr_s,
			s00_axi_awprot => s00_axi_awprot_s,
			s00_axi_awvalid => s00_axi_awvalid_s,
			s00_axi_awready => s00_axi_awready_s,
			s00_axi_wdata => s00_axi_wdata_s,
			s00_axi_wstrb => s00_axi_wstrb_s,
			s00_axi_wvalid => s00_axi_wvalid_s,
			s00_axi_wready => s00_axi_wready_s,
			s00_axi_bresp => s00_axi_bresp_s,
			s00_axi_bvalid => s00_axi_bvalid_s,
			s00_axi_bready => s00_axi_bready_s,
			s00_axi_araddr => s00_axi_araddr_s,
			s00_axi_arprot => s00_axi_arprot_s,
			s00_axi_arvalid => s00_axi_arvalid_s,
			s00_axi_arready => s00_axi_arready_s,
			s00_axi_rdata => s00_axi_rdata_s,
			s00_axi_rresp => s00_axi_rresp_s,
			s00_axi_rvalid => s00_axi_rvalid_s,
			s00_axi_rready => s00_axi_rready_s);

	Bram_A : entity work.bram(beh)
		generic map(
			WIDTH => DATA_WIDTH_c,
			WADDR => ADDR_WIDTH_c
		)
		port map(
			clka => clk_s,
			clkb => clk_s,
			reseta => reset_s,
			ena => tb_a_en_i,
			wea => tb_a_we_i,
			addra => tb_a_addr_i,
			dia => tb_a_data_i,
			doa => open,

			resetb => reset_s,
			enb => ip_a_en,
			web => ip_a_we,
			addrb => ip_a_addr,
			dib => (others => '0'),
			dob => ip_a_data
		);
	Bram_B : entity work.bram(beh)
		generic map(
			WIDTH => DATA_WIDTH_c,
			WADDR => ADDR_WIDTH_c
		)
		port map(
			clka => clk_s,
			clkb => clk_s,
			reseta => reset_s,
			ena => ip_b_en,
			wea => ip_b_we,
			addra => ip_b_addr,
			dia => ip_b_data_o,
			doa => open,

			resetb => reset_s,
			enb => ip_b_en_b,
			web => ip_b_we_b,
			addrb => ip_b_addr_b,
			dib => (others => '0'),
			dob => ip_b_data_i
		);
	Bram_C : entity work.bram(beh)
		generic map(
			WIDTH => DATA_WIDTH_c,
			WADDR => ADDR_WIDTH_c
		)
		port map(
			clka => clk_s,
			clkb => clk_s,
			reseta => reset_s,
			ena => tb_c_en_i,
			wea => tb_c_we_i,
			addra => tb_c_addr_i,
			dia => (others => '0'),
			doa => tb_c_data_o,

			resetb => reset_s,
			enb => ip_c_en,
			web => ip_c_we,
			addrb => ip_c_addr,
			dib => ip_c_data,
			dob => open
		);
end Behavioral;
