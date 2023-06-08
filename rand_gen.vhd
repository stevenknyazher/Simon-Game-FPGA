library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity rand_gen is
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
end rand_gen;

architecture Behavioral of rand_gen is

    signal currstate, nextstate : std_logic_vector(input_size - 1 downto 0);
    signal feedback: std_logic;
    constant DEFAULT_NONE_ZERO_VAL : std_logic_vector(output_size - 1 downto 0) := (0 => '1', others => '0');
    
begin

    state_reg: process(clk, rst)
    begin
        if rst = '1' then
            currstate <= seed;
        elsif rising_edge(clk) then
            currstate <= nextstate;
        end if;
    end process;

    feedback <= currstate(4) xor currstate(3) xor currstate(2) xor currstate(0);
    nextstate <= feedback & currstate(input_size - 1 downto 1);
    
    output <= "1000" when currstate(input_size - 1) = '1' else
              "0100" when currstate(input_size - 2) = '1' else
              "0010" when currstate(input_size - 3) = '1' else
              "0001" when currstate(input_size - 4) = '1' else
              "0001";
              
end Behavioral;
