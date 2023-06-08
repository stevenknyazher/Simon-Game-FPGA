library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity simon_game_top is
    Generic ( seed: std_logic_vector(7 downto 0) := b"1001_0110");
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (3 downto 0);
           led : out STD_LOGIC_VECTOR (3 downto 0);
           led_r : out STD_LOGIC;
           led_g : out STD_LOGIC;
           led_b : out STD_LOGIC);
end simon_game_top;

architecture Behavioral of simon_game_top is

constant ADDR_WIDTH: integer := 4;
constant DATA_WIDTH: integer := 4;
constant MAX_LEVEL: integer := 2**ADDR_WIDTH;
constant INPUT_FREQ: integer := 125_000_000;

signal rst: std_logic;
signal btn_db: std_logic_vector(3 downto 0);
signal btn_pulse: std_logic_vector(3 downto 0);
signal rgb_reg: std_logic_vector(2 downto 0);
signal pattern: std_logic_vector(DATA_WIDTH-1 downto 0);
signal level: integer:= 0;
signal led_reg: std_logic_vector(3 downto 0);
signal mem_index: integer := 0;
signal disp_counter: integer := 0;
signal r_data_reg: std_logic_vector(3 downto 0);

type state_type is (IDLE, SEQ_GEN, SEQ_DISP, USER_INP, CHECK_INP, CORR_INP, INCORR_INP, GAME_OVER);
signal current_state: state_type;

type mem_2d_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal main_array_reg: mem_2d_type;
signal user_array_reg: mem_2d_type;

component debounce is
    generic
    (
        clk_freq    : integer := 125_000_000;
        stable_time : integer := 10);
    port
    (
        clk    : in std_logic;
        rst    : in std_logic;
        button : in std_logic;
        result : out std_logic);
end component;

component single_pulse_detector is
    generic
    (
        detect_type: std_logic_vector(1 downto 0) := "00");
    port
    (
        clk          : in std_logic;
        rst          : in std_logic;
        input_signal : in std_logic;
        output_pulse : out std_logic);
end component;

component rand_gen is
    generic
    (
        input_size: integer := 8;
        output_size: integer := 4);
    port
    (
        clk, rst : in std_logic;
        seed     : in std_logic_vector(input_size - 1 downto 0);
        output   : out std_logic_vector(output_size - 1 downto 0)
    );
end component;

begin

rst <= btn(0) AND btn(3);

rand_gen_inst: rand_gen generic map(output_size => DATA_WIDTH) port map(clk => clk, rst => rst, seed => seed, output => pattern);

debounce_inst_0: debounce port map(clk => clk, rst => rst, button => btn(0), result=> btn_db(0));
debounce_inst_1: debounce port map(clk => clk, rst => rst, button => btn(1), result=> btn_db(1));
debounce_inst_2: debounce port map(clk => clk, rst => rst, button => btn(2), result=> btn_db(2));
debounce_inst_3: debounce port map(clk => clk, rst => rst, button => btn(3), result=> btn_db(3));

pulse_inst_0: single_pulse_detector generic map(detect_type => "01") port map(clk => clk, rst => rst, input_signal => btn_db(0), output_pulse => btn_pulse(0));
pulse_inst_1: single_pulse_detector generic map(detect_type => "01") port map(clk => clk, rst => rst, input_signal => btn_db(1), output_pulse => btn_pulse(1));
pulse_inst_2: single_pulse_detector generic map(detect_type => "01") port map(clk => clk, rst => rst, input_signal => btn_db(2), output_pulse => btn_pulse(2));
pulse_inst_3: single_pulse_detector generic map(detect_type => "01") port map(clk => clk, rst => rst, input_signal => btn_db(3), output_pulse => btn_pulse(3));

process(clk, rst)
begin
    if rst = '1' then
        current_state <= IDLE;
        rgb_reg <= (others => '0');
        level <= 0;
        main_array_reg <= (others => (others => '0'));
        user_array_reg <= (others => (others => '0'));
        led_reg <= (others => '0');
        mem_index <= 0;
        disp_counter <= 0;
        r_data_reg <= (others => '0');
    elsif rising_edge(clk) then
        if current_state = IDLE then
            current_state <= SEQ_GEN;
        elsif current_state <= SEQ_GEN then
            main_array_reg(level) <= pattern;
            if level <MAX_LEVEL-1 then
                level <= level + 1;
            else
                level <= MAX_LEVEL - 1;
            end if;
            current_state <= SEQ_DISP;
        elsif current_state <= SEQ_DISP then
            rgb_reg <= (others => '1');
            
            if disp_counter = 0 then
                r_data_reg <= main_array_reg(mem_index);
                mem_index <= mem_index + 1;
                led_reg <= (others => '0');
            elsif disp_counter = 1 then
                led_reg <= r_data_reg;
            elsif disp_counter = (INPUT_FREQ/2)-1 then
                led_reg <= (others => '0');
            elsif disp_counter = INPUT_FREQ-1 then
                if mem_index = level then
                    user_array_reg <= (others => (others => '0'));
                    current_state <= USER_INP;
                    led_reg <= (others => '0');
                    mem_index <= 0;
                end if;
            end if;
            
            if disp_counter < INPUT_FREQ-1 then
                disp_counter <= disp_counter + 1;
            else
                disp_counter <= 0;
            end if;
            
        elsif current_state <= USER_INP then
            rgb_reg <= "100";
            
            if mem_index = level then
                current_state <= CHECK_INP;
                led_reg <= (others => '0');
                mem_index <= 0;
            end if;
            
            if btn_pulse(0) = '1' then
                led_reg <= "0001";
                user_array_reg(mem_index) <= "0001";
                mem_index <= mem_index + 1;
            elsif btn_pulse(1) = '1' then
                led_reg <= "0010";
                user_array_reg(mem_index) <= "0010";
                mem_index <= mem_index + 1;
            elsif btn_pulse(2) = '1' then
                led_reg <= "0100";
                user_array_reg(mem_index) <= "0100";
                mem_index <= mem_index + 1;
            elsif btn_pulse(3) = '1' then
                led_reg <= "1000";
                user_array_reg(mem_index) <= "1000";
                mem_index <= mem_index + 1;
            end if;
            
        elsif current_state <= CHECK_INP then
            if main_array_reg(mem_index) /= user_array_reg(mem_index) then
                current_state <= INCORR_INP;
                mem_index <= 0;
                disp_counter <= 0;
            else
                if mem_index = level-1 then
                    current_state <= CORR_INP;
                    mem_index <= 0;
                    disp_counter <= 0;
                else
                    mem_index <= mem_index + 1;
                end if;
            end if;
        elsif current_state <= CORR_INP then
            rgb_reg <= "010";
            if disp_counter < INPUT_FREQ-1 then
                disp_counter <= disp_counter + 1;
            else
                disp_counter <= 0;
            end if;
            if disp_counter = INPUT_FREQ-1 then
                current_state <= SEQ_GEN;
            end if;
        elsif current_state <= INCORR_INP then
            if disp_counter = 0 then
                rgb_reg <= "001";
                mem_index <= mem_index + 1;
            elsif disp_counter = (INPUT_FREQ/2)-1 then
                rgb_reg <= "000";
            elsif disp_counter = INPUT_FREQ-1 then
                if mem_index = level - 1 then
                    current_state <= GAME_OVER;
                    mem_index <= 0;
                end if;
            end if;
            
            if disp_counter < INPUT_FREQ-1 then
                disp_counter <= disp_counter + 1;
            else
                disp_counter <= 0;
            end if;
        elsif current_state <= GAME_OVER then
            current_state <= GAME_OVER;
        else
            current_state <= GAME_OVER;
        end if;
    end if;
end process;

led <= led_reg;
led_r <= rgb_reg(0);
led_g <= rgb_reg(1);
led_b <= rgb_reg(2);

end Behavioral;
