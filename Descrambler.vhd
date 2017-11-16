LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY Descrambler IS
PORT
(
  rst           : IN STD_LOGIC;                        -- System reset
  clk           : IN STD_LOGIC;                        -- Input video clock at 74.25MHz nominal
  i             : IN STD_LOGIC_VECTOR(7 DOWNTO 0);    -- Scrambled video input from LVDS I/F
  trs           : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);    -- Input TRS signals
  vout          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)      -- Descrambled input video
);
END ENTITY Descrambler;  

ARCHITECTURE RTL OF Descrambler IS

  SIGNAL t               : STD_LOGIC_VECTOR(7  DOWNTO 0);

  SIGNAL o_d1            : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL o_d2            : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL o_d3            : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL o_d4            : STD_LOGIC_VECTOR(7 DOWNTO 0);
  
  SIGNAL trs_reg         : STD_LOGIC_VECTOR(2  DOWNTO 0);
  
  
BEGIN


  -- Detect trs pattern
PROCESS (rst ,clk)
BEGIN
    IF ( rst = '1' ) THEN
		t   <= (OTHERS => '0');
		trs_reg <= (OTHERS => '0');
    ELSIF RISING_EDGE(clk) THEN
			IF ( i = X"FF" ) THEN
				t(0) <= '1';
			ELSE
				t(0) <= '0';
			END IF;
			IF ( i = X"00" ) AND ( t(0) = '1' ) THEN
				t(1) <= '1';
			ELSE
				t(1) <= '0';
			END IF;
			IF ( i = X"00" ) AND ( t(1) = '1' ) THEN
				t(2) <= '1';
			ELSE
				t(2) <= '0';
			END IF;
			IF ( t(2) = '1' ) THEN
				trs_reg <= i(6 DOWNTO 4);
			END IF;
		
		t(7 downto 3) <= t(6 downto 3) & t(2);
    END IF;
END PROCESS;

  -- Output registers
PROCESS (rst ,clk)
BEGIN
	IF ( rst = '1' ) THEN
		vout <= (OTHERS => '0');
		o_d1 <= (OTHERS => '0');
		o_d2 <= (OTHERS => '0');
		o_d3 <= (OTHERS => '0');
		o_d4 <= (OTHERS => '0');
		trs <= (OTHERS => '0');
    ELSIF RISING_EDGE(clk) THEN
		o_d1 <= i;
		o_d2 <= o_d1;
		o_d3 <= o_d2;
		o_d4 <= o_d3;
      
		vout <= o_d4;

		if (t(3) = '1') and (trs_reg(0) = '1') then
			trs <= trs_reg;
		elsif (t(7) = '1') and (trs_reg(0) = '0') then
			trs <= trs_reg;
		end if;
   
    END IF;
END PROCESS;

END RTL;

