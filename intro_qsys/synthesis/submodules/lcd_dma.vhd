-------------------------------------------------------------------------------
-- HES-SO Master, projet du cours de EmbHard 
--
-- File         : DMA.vhd
-- Description  : The file contain a implementation of a DMA component
--                
--
-- Author       : Antonin Kenzi
-- Date         : 03.10.2024
-- Version      : 1.1
--
-- Dependencies : LDC_CTL.vhd
--
--| Modifications |------------------------------------------------------------
-- Version   Author Date               Description
-- 1.0       AKI    18.10.2024          Creation of the file
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DMA_LCD_ctrl is
	port (
		clk_i                 : in    std_logic                    ;
		reset_n_i             : in    std_logic                    ;         
		-- master interface
 		master_address_o	    : out  std_logic_vector(31 downto 0);
		master_read_o         	: out std_logic;
		master_readdata_i	    : in std_logic_vector(15 downto 0) ;
		master_waitrequest_i  	: in std_logic;
		
		-- IRQ generation
		end_of_transaction_irq_o : out std_logic;		
		
		-- slave interface 
		avalon_address_i    : in    std_logic_vector(2 downto 0) ;
		avalon_cs_i         : in    std_logic                   ;  
		avalon_wr_i         : in    std_logic                    ;  
		avalon_write_data_i : in    std_logic_vector(31 downto 0);
		avalon_rd_i         : in    std_logic                    ; 
		avalon_waitrequest_o         : out    std_logic ;  
		avalon_read_data_o  : out    std_logic_vector(31 downto 0);
		
		-- LCD interface
		LCD_data_o      : out std_logic_vector(15 downto 0) ;
		LCD_CS_n_o	  : out    std_logic ;		
		LCD_WR_n_o	  : out    std_logic ;				
		LCD_D_C_n_o	  : out    std_logic 
	);
end entity DMA_LCD_ctrl;

architecture rtl of DMA_LCD_ctrl is
    -- Déclaration of the signals,components,types and procedures
    -- Components (Nomenclature : name of the component + _c)
    -- TODO add LCD_DMA_c
    -- Types (Nomenclature : name of the type + _t)
	type state_ctl_t is (IDLE, MASTER_S1, MASTER_S2,MASTER_CNT_INC,MASTER_WAITREQUEST);
	type state_LCD_t is (IDLE, S1, S2,S3);
    -- exemple : type state_t is (idle, start, stop);
	
    -- Signals (Nomenclature : name of the signal + _s)
    -- exemple : signal a : signed(N_bit-1 downto 0);
    signal state_reg_ctl_s : state_ctl_t;
    signal state_fut_ctl_s : state_ctl_t;
	
    signal pointer_reg_s : std_logic_vector(31 downto 0);
    signal size_reg_s : std_logic_vector(31 downto 0);
    signal status_reg_s : std_logic_vector(31 downto 0);
    signal cnt_reg_s	: std_logic_vector(31 downto 0);
    signal irq_acknoledge_s : std_logic;
    signal start_DMA_s : std_logic;

    signal D_C_n_reg_s 			: std_logic;
    signal D_C_n_fut_s 			: std_logic;
    signal state_reg_LCD_s 	  	: state_LCD_t;
    signal state_fut_LCD_s 	  	: state_LCD_t;
	signal start_lcd_s			: std_logic;
	signal start_lcd_DMA_s		: std_logic;
    signal WR_n_reg_s 	  	  	: std_logic;
    signal WR_n_fut_s 	  	  	: std_logic;
    signal waitRequest_s		: std_logic;
	
    signal DB_reg_s				: std_logic_vector(15 DOWNTO 0);
    signal DB_fut_s				: std_logic_vector(15 DOWNTO 0);
	
    -- Procedures (Nomenclature : name of the procedure + _p)
	-- Déclaration of the signals,components,types and procedures
    -- Components (Nomenclature : name of the component + _c)
    -- Signals (Nomenclature : name of the signal + _s)
    -- exemple : signal a : signed(N_bit-1 downto 0);
	 

begin
    -- Declarations
    -- Process
    --===================== avalon slave ============================
	--
	Slave_p : process(Clk_i,reset_n_i)
	begin
		if reset_n_i='0' then
			pointer_reg_s <= (others => '0');
			size_reg_s <= (others => '0');
			irq_acknoledge_s <= '0'; 
			start_DMA_s <= '0'; 
			avalon_read_data_o <= (others => '0');
		elsif rising_edge(Clk_i) then
			irq_acknoledge_s <= '0'; 
			start_DMA_s <= '0'; 
			-- Write 
			if avalon_cs_i = '1' and avalon_wr_i = '1' then -- Write cycle
				case avalon_address_i(2 downto 0) is
					when "010" => pointer_reg_s <= avalon_write_data_i;
					when "011" => size_reg_s 	<= avalon_write_data_i;
					when "100" => 
						start_DMA_s 		<= avalon_write_data_i(0);
						irq_acknoledge_s 	<= avalon_write_data_i(2);
					when others => null;
				end case;
			end if; 

			-- Read
			case avalon_address_i(2 downto 0) is
				when "010" => avalon_read_data_o <= pointer_reg_s;
				when "011" => avalon_read_data_o <= size_reg_s;
				when "101" => avalon_read_data_o <= status_reg_s;
				when "110" => avalon_read_data_o <= cnt_reg_s;
				when others => null;
			end case;
		end if;
	end process Slave_p;

	avalon_waitrequest_o <= waitRequest_s;

	--================= STATE MACHINE DMA ==========================

	
	pState_update : process(Clk_i,reset_n_i)
	begin
	  if reset_n_i='0' then
			state_reg_ctl_s <= IDLE;
			cnt_reg_s <= (others => '0');
	  		status_reg_s <= (others => '0');
	  elsif rising_edge(clk_i) then
			state_reg_ctl_s  <= state_fut_ctl_s;
			-- address counter increment
            if state_reg_ctl_s = IDLE then
                cnt_reg_s <= pointer_reg_s;
            elsif state_reg_ctl_s = MASTER_CNT_INC then
				cnt_reg_s <= std_logic_vector(unsigned(cnt_reg_s) + x"00000002");
            end if;
			if unsigned(cnt_reg_s) >= unsigned(pointer_reg_s) + unsigned(size_reg_s) then 
				status_reg_s(0)<='1';
				status_reg_s(2) <= '1';
			end if;
			if start_DMA_s = '1'then 
				status_reg_s(0)<='0';
			end if;
			if irq_acknoledge_s = '1' then 
				status_reg_s(2) <= '0';
			end if ; 
	  end if; 
	end process pState_update;

   decode_CTL_state : process(state_reg_ctl_s,status_reg_s,waitRequest_s,master_waitrequest_i,start_DMA_s)
	begin
      state_fut_ctl_s <= state_reg_ctl_s;
	  start_lcd_DMA_s <= '0';
	  case state_reg_ctl_s is
			when IDLE =>
				if start_DMA_s = '1' then 
					state_fut_ctl_s <= MASTER_S1;
				end if;
			when MASTER_S1 =>
				state_fut_ctl_s <= MASTER_S2;
				start_lcd_DMA_s <= '1';
			when MASTER_S2 =>
				if master_waitrequest_i = '0' and waitRequest_s = '0' then 
					if status_reg_s(0)= '1' then 
						state_fut_ctl_s <= IDLE;
					else 
						state_fut_ctl_s <= MASTER_CNT_INC;
					end if;
				end if;

			when MASTER_CNT_INC =>
				state_fut_ctl_s <= MASTER_S1;
			when others => state_fut_ctl_s <= IDLE;
	  end case;
	end process decode_CTL_state;

	end_of_transaction_irq_o <= status_reg_s(2);
    master_address_o <= cnt_reg_s;
    master_read_o <= '1';

	--======================== LDC ===========================
	-- start_lcd_s start vector
	-- D_C_n_reg_s and DB_reg_s controled outside
    -- Process
	reg_wr_process :
	process(reset_n_i,Clk_i)
	begin
	  if reset_n_i='0' then
			state_reg_LCD_s		<= idle;
			WR_n_reg_s 			<= '0';
			D_C_n_reg_s			<= '0';
			DB_reg_s 			<= (others => '0');
	  elsif rising_edge(Clk_i) then
			D_C_n_reg_s			<= D_C_n_fut_s;
			DB_reg_s			<= DB_fut_s;
			state_reg_LCD_s 	<= state_fut_LCD_s;
			WR_n_reg_s			<= WR_n_fut_s;
	  end if; 
	end process;

	start_lcd_s <= '1' when avalon_cs_i = '1' and avalon_wr_i = '1' and (avalon_address_i(2 downto 0) = "001" or avalon_address_i(2 downto 0) = "000" )else '0';
	decode_state : process(state_reg_LCD_s,state_reg_ctl_s,start_lcd_s,start_lcd_DMA_s,DB_fut_s,avalon_write_data_i,master_readdata_i,avalon_address_i)
	begin
	  	state_fut_LCD_s 	<= state_reg_LCD_s;
	  	waitRequest_s <= '0';
	  	WR_n_fut_s <= '1';
		if state_reg_ctl_s = IDLE then
			D_C_n_fut_s <= avalon_address_i(0); --adress slave
		else
			D_C_n_fut_s <= '1';
		end if;
		case state_reg_LCD_s is
				when IDLE =>
	  				WR_n_fut_s <= '1';
					if state_reg_ctl_s = IDLE then
						DB_fut_s <= avalon_write_data_i(15 downto 0);
					else
						DB_fut_s <= master_readdata_i(15 downto 0);
					end if;
					if start_lcd_s = '1' or start_lcd_DMA_s = '1' then
	  					waitRequest_s <= '1';
						WR_n_fut_s <= '0';
						state_fut_LCD_s <= S1;
					end if;
				when S1 =>
					waitRequest_s <= '1';
					WR_n_fut_s <= '0';
					state_fut_LCD_s <= S2;
				when S2 =>
					waitRequest_s <= '1';
	  				WR_n_fut_s <= '1';
					state_fut_LCD_s <= S3;
				when S3 =>
					waitRequest_s <= '0';
	  				WR_n_fut_s <= '1';
					state_fut_LCD_s <= IDLE;
				when others => 
					state_fut_LCD_s <= IDLE;
		end case;
	end process;

	avalon_waitrequest_o <= waitRequest_s;

	-- 8080 interface link
	LCD_data_o <= DB_reg_s;
	LCD_D_C_n_o <= D_C_n_reg_s;
	LCD_WR_n_o <= WR_n_reg_s;
	LCD_CS_n_o <= '0';
END rtl;