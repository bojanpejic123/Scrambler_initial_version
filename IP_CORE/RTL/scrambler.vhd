library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity scrambler is
	generic (

		WIDTH : integer := 32 --for input and output data width
	);
	port (
		----------- Clocking and reset interface ---------------

		clk : in std_logic;
		reset : in std_logic;
		------------------ Input data interface -------------------
		a_addr_o : out std_logic_vector(WIDTH - 1 downto 0);
		a_en_o : out std_logic;
		a_data_i : in std_logic_vector(WIDTH - 1 downto 0);
		b_addr_o : out std_logic_vector(WIDTH - 1 downto 0);
		b_addr_o_b : out std_logic_vector(WIDTH - 1 downto 0);

		b_data_i : in std_logic_vector(WIDTH - 1 downto 0);
		b_data_o : out std_logic_vector(WIDTH - 1 downto 0);
		b_en_o_b : out std_logic;

		b_en_o : out std_logic;
		b_wr_o : out std_logic;

		c_addr_o : out std_logic_vector(WIDTH - 1 downto 0);
		c_data_o : out std_logic_vector(WIDTH - 1 downto 0);
		c_en_o : out std_logic;
		c_wr_o : out std_logic;
		--------------------- Command interface --------------------

		start : in std_logic;

		--------------------- Status interface ---------------------

		ready : out std_logic
	);

end entity;

architecture Behavioral of scrambler is

	type state_type is (idle, s1, s2, s3_a, s4, s4_a, s4_b, s4_c, s4_d, s4_e, s4_g, s4_f, s5, s6_a, s7, s7_a, s7_b, s7_c, s7_d, s7_g, s8, s8_a, s9, s9_a);

	signal state_reg, state_next : state_type;
	--------------------------------------------------------------------------------------------------------------------------- 

	-----------------------------------------------------------------------------------------------------------------------------
	--constant in control path and data path
	constant BLOCK_SIZE : integer := 8192;
	constant CHANNEL_BLOCK_SIZE : integer := 8256;
	constant FIRST_BLOCK_DIVISION_SIZE : integer := 128;
	constant SECOND_BLOCK_DIVISION_SIZE : integer := 64;
	constant SECOND_CHANNEL_BLOCK_DIVISION_SIZE : integer := 68;
	constant THIRD_BLOCK_DIVISION_SIZE : integer := 16;
	constant FOURTH_BLOCK_DIVISION_SIZE : integer := 8;
	constant FIFTH_BLOCK_DIVISION_SIZE : integer := 4;
	constant TOTAL_NUM_BIT_WIDTH : integer := 17;
	constant NUM_BIT_WIDTH : integer := 15;

	--------------------------------------------------------------------------------------------------------------------------------- 
	--temporary register after multiplication
	signal n_reg, n_next : integer := 0;
	signal x_reg, x_next : integer := 0;
	signal j_reg, j_next : integer := 1;
	signal q_reg, q_next : integer;
	signal m_reg, m_next : integer := 0;
	signal y_reg, y_next : integer := 0;
	signal k_reg, k_next : integer := 1;
	signal w_reg, w_next : integer;

	signal data_reg, data_next : std_logic_vector(width - 1 downto 0) := (others => '0');
	signal data1_reg, data1_next : std_logic_vector(width - 1 downto 0) := (others => '0');
	signal a_addr_s_reg, a_addr_s_next : std_logic_vector(width - 1 downto 0) := (others => '0');
	signal b_addr_s_reg, b_addr_s_next : std_logic_vector(width - 1 downto 0) := (others => '0');
	signal b_addr_b_s_reg, b_addr_b_s_next : std_logic_vector(width - 1 downto 0) := (others => '0');
	signal c_addr_s_reg, c_addr_s_next : std_logic_vector(width - 1 downto 0) := (others => '0');
begin
	process (reset, clk)
	begin
		--reseting everything
		--reset for BRAM is on HIGH, on AXI is LOW!!!
		if reset = '1' then
			state_reg <= idle;
			n_reg <= 0;
			x_reg <= 0;
			j_reg <= 1;
			q_reg <= 0;
			m_reg <= 0;
			y_reg <= 0;
			k_reg <= 1;
			w_reg <= 0;
			data_reg <= (others => '0');
			data1_reg <= (others => '0');
			a_addr_s_reg <= (others => '0');
			b_addr_s_reg <= (others => '0');
			c_addr_s_reg <= (others => '0');
			b_addr_b_s_reg <= (others => '0');
		elsif (clk'EVENT and clk = '1') then
			state_reg <= state_next;
			n_reg <= n_next;
			x_reg <= x_next;
			j_reg <= j_next;
			q_reg <= q_next;
			m_reg <= m_next;
			y_reg <= y_next;
			k_reg <= k_next;
			w_reg <= w_next;
			data_reg <= data_next;
			data1_reg <= data1_next;
			a_addr_s_reg <= a_addr_s_next;
			b_addr_s_reg <= b_addr_s_next;
			c_addr_s_reg <= c_addr_s_next;
			b_addr_b_s_reg <= b_addr_b_s_next;

		end if;
	end process;
	--treba dodati konstante iz masine stanja u proces u listu osetljivosti(BLOCK_SIZE,CHANEL_BLOCK_SIZE ....itd)
	process (start, b_data_i, state_reg, a_data_i, x_reg, x_next, y_reg, y_next, n_reg, n_next, j_reg, j_next, q_reg, q_next, m_reg, m_next, y_reg, y_next, k_reg, k_next, w_reg, w_next, data_reg, data_next, data1_reg, data1_next, a_addr_s_reg, a_addr_s_next, b_addr_s_reg, b_addr_s_next, c_addr_s_reg, c_addr_s_next, b_addr_b_s_reg, b_addr_b_s_next)

	begin
		--default assignments
		n_next <= n_reg;
		x_next <= x_reg;
		j_next <= j_reg;
		q_next <= q_reg;
		m_next <= m_reg;
		y_next <= y_reg;
		k_next <= k_reg;
		w_next <= w_reg;
		data_next <= data_reg;
		data1_next <= data1_reg;
		a_addr_s_next <= a_addr_s_reg;
		b_addr_s_next <= b_addr_s_reg;
		c_addr_s_next <= c_addr_s_reg;
		b_addr_b_s_next <= b_addr_b_s_reg;
		ready <= '0';
		a_en_o <= '0';
		b_en_o <= '0';
		c_en_o <= '0';
		b_en_o_b <= '0';
		c_wr_o <= '0';
		b_wr_o <= '0';
		a_addr_o <= a_addr_s_reg;
		b_addr_o <= b_addr_s_reg;
		b_addr_o_b <= b_addr_b_s_reg;
		c_addr_o <= c_addr_s_reg;

		c_data_o <= data1_reg;

		b_data_o <= data_reg;
		case state_reg is

			when idle =>
				ready <= '1';

				if start = '1' then -- start the IP core
					state_next <= s2;
				else
					state_next <= idle;
				end if;
			when s2 =>
				n_next <= 0;
				x_next <= 0;
				j_next <= 1;
				state_next <= s3_a;
			when s3_a =>
				n_next <= n_reg + SECOND_BLOCK_DIVISION_SIZE;
				x_next <= x_reg + FIRST_BLOCK_DIVISION_SIZE;
				state_next <= s4;
			when s4 =>
				q_next <= n_reg - SECOND_BLOCK_DIVISION_SIZE + 1;

				state_next <= s4_a;
			when s4_a =>
				--a_addr_o <= std_logic_vector(to_unsigned((CHANNEL_BLOCK_SIZE - x_reg + q_reg)*4, 32));
				--b_addr_o <= std_logic_vector(to_unsigned(q_reg*4, 32));

				state_next <= s4_b;
			when s4_b =>
				a_en_o <= '1';
				a_addr_s_next <= std_logic_vector(to_unsigned((CHANNEL_BLOCK_SIZE - x_reg + q_reg) * 4, 32));
				b_addr_s_next <= std_logic_vector(to_unsigned(q_reg * 4, 32));

				state_next <= s4_g;
			when s4_g =>
				a_en_o <= '1';
				a_addr_o <= a_addr_s_next;
				state_next <= s4_c;
			when s4_c =>
				a_en_o <= '0';
				data_next <= a_data_i;

				b_en_o <= '1';
				b_addr_o <= b_addr_s_next;

				state_next <= s4_e;
				---channel_scrambled1(q_reg) <= channel_test(CHANNEL_BLOCK_SIZE - x_reg + q_reg);
			when s4_e =>
				b_en_o <= '0';
				b_wr_o <= '1';

				b_data_o <= data_next;
				q_next <= q_reg + 1;

				state_next <= s4_f;
			when s4_f =>
				if (q_reg <= n_reg) then
					state_next <= s4_a;
				else
					state_next <= s5;
				end if;
			when s5 =>
				m_next <= 0;
				y_next <= 0;
				k_next <= 1;
				state_next <= s6_a;
			when s6_a =>
				m_next <= m_reg + FIFTH_BLOCK_DIVISION_SIZE;
				y_next <= y_reg + FOURTH_BLOCK_DIVISION_SIZE;
				state_next <= s7;
			when s7 =>
				w_next <= 1 + n_reg - SECOND_CHANNEL_BLOCK_DIVISION_SIZE + m_reg;
				state_next <= s7_a;
			when s7_a =>
				b_en_o_b <= '1';

				b_addr_b_s_next <= std_logic_vector(to_unsigned((SECOND_CHANNEL_BLOCK_DIVISION_SIZE - y_reg + w_reg) * 4, 32));
				c_addr_s_next <= std_logic_vector(to_unsigned(w_reg * 4, 32));
				b_addr_o_b <= std_logic_vector(to_unsigned((SECOND_CHANNEL_BLOCK_DIVISION_SIZE - y_reg + w_reg) * 4, 32));

				state_next <= s7_g;
			when s7_g =>
				b_en_o_b <= '1';

				b_addr_o_b <= b_addr_b_s_next;
				state_next <= s7_b;
			when s7_b =>
				b_en_o_b <= '0';

				data1_next <= b_data_i;
				c_addr_o <= std_logic_vector(to_unsigned(w_reg * 4, 32));

				state_next <= s7_c;

				--channel_scrambled(w_reg) <= channel_scrambled1(SECOND_CHANNEL_BLOCK_DIVISION_SIZE - y_reg + w_reg);
			when s7_c =>
				c_wr_o <= '1';
				c_en_o <= '0';

				c_data_o <= data1_next;
				w_next <= w_reg + 1;
				state_next <= s7_d;
			when s7_d =>

				if (w_reg <= 1 + n_reg - (SECOND_BLOCK_DIVISION_SIZE + 1) + m_reg) then
					state_next <= s7_a;
				else
					state_next <= s8;
				end if;

			when s8 =>
				k_next <= k_reg + 1;
				state_next <= s8_a;
			when s8_a =>
				if (k_reg <= THIRD_BLOCK_DIVISION_SIZE) then
					state_next <= s6_a;
				else
					state_next <= s9;
				end if;
			when s9 =>
				j_next <= j_reg + 1;
				state_next <= s9_a;
			when s9_a =>
				if (j_reg <= FIRST_BLOCK_DIVISION_SIZE) then
					state_next <= s3_a;
				else
					state_next <= idle;
				end if;
			when others =>
				state_next <= idle;

		end case;
	end process;

end Behavioral;
