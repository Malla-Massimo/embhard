library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY LCD_CTL IS
 GENERIC(N : NATURAL := 16);
 PORT(
	-- Avalon interfaces signals
		Clk_i				: IN std_logic;
		nReset_i 		: IN std_logic;
		Address_i 		: IN std_logic;
		ChipSelect_i 	: IN std_logic;
		Write_i 			: IN std_logic;
		WriteData_i 	: IN std_logic_vector (N-1 DOWNTO 0);
		
		
		waitRequest_o	: out std_logic;
		
		-- 8080 interface
		DB_o				: OUT std_logic_vector (N-1 DOWNTO 0);
		D_C_n_o 		 	: out std_logic;
		--RD_n_o 			: out std_logic;
		WR_n_o 			: out std_logic
		--CS_n_o 			: out std_logic;
		--LCS_reset_n_o	: out std_logic;
		--IM0_o				: out std_logic
	);
End LCD_CTL;

ARCHITECTURE comp OF LCD_CTL IS
    -- Déclaration of the signals,components,types and procedures
    -- Components (Nomenclature : name of the component + _c)
    -- Types (Nomenclature : name of the type + _t)
    -- exemple : type state_t is (idle, start, stop);
	 type state_t is (idle, S1, S2,S3);
    -- Signals (Nomenclature : name of the signal + _s)
    -- exemple : signal a : signed(N_bit-1 downto 0);
	 
    signal D_C_n_reg_s : std_logic;
    signal state_pres_s 	  : state_t;
    signal state_fut_s 	  	  : state_t;
    signal DB_reg_s		: std_logic_vector(N-1 DOWNTO 0);
	 
    -- Procedures (Nomenclature : name of the procedure + _p)

begin
    -- Declarations
    -- Process
	reg_wr_process :
	process(Clk_i, nReset_i)
	begin
	  if nReset_i='0' then
			state_pres_s<= idle;
			D_C_n_reg_s<= '0';
			DB_reg_s <= (others => '0');
	  elsif rising_edge(Clk_i) then
			state_pres_s 	<= state_fut_s;
			D_C_n_reg_s 	<= Address_i;
			DB_reg_s 		<= WriteData_i;
	  end if; 
	end process;
	
	decode_state : process(ChipSelect_i,Write_i,state_pres_s)
	begin
	  state_fut_s <= state_pres_s;
	  waitRequest_o <= '1';
	  WR_n_o <= '1';
	  case state_pres_s is
			when IDLE =>
				if ChipSelect_i = '1' and Write_i = '1' then 
					state_fut_s <= S1;
				end if;
			when S1 =>
				state_fut_s <= S2;
				WR_n_o <= '0';
			when S2 =>
				state_fut_s <= S3;
			when S3 =>
				state_fut_s <= IDLE;
				waitRequest_o <= '0';
			when others => 
			state_fut_s <= IDLE;
	  end case;
	end process;

	-- 8080 interface link
	DB_o <= DB_reg_s;
	D_C_n_o <= D_C_n_reg_s;
	--RD_n_o <= '0';
	--CS_n_o <= '0'; 
	--IM0_o <= '0';
	--LCS_reset_n_o <= nReset_i;
	
END comp;