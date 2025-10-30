library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity somador_andar is
    generic (
        N_BITS : integer := 4
    );
    port (
        clk         : in std_logic;
        is_closed   : in std_logic; 
        andar_atual : in std_logic_vector(N_BITS - 1 downto 0);
        prox_andar  : out std_logic_vector(N_BITS - 1 downto 0)
    );
end entity somador_andar;

architecture behavioral of somador_andar is

    constant CLK_FREQUENCY : integer := 50_000;
    constant DELAY_SECONDS : integer := 1;
    constant MAX_COUNT     : integer := CLK_FREQUENCY * DELAY_SECONDS;

    signal delay_counter : integer range 0 to MAX_COUNT;

    type state_t is (
        IDLE,
        MOVING,
        MOVED
    );
    signal state : state_t := IDLE;

    signal floor_to_increment : std_logic_vector(N_BITS - 1 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            case state is

                when IDLE =>
                    prox_andar <= andar_atual; 
                    delay_counter <= 0;

                    if is_closed = '1' then
                        floor_to_increment <= andar_atual;
                        state <= MOVING;
                    end if;

                when DELAYING =>
                    if is_closed = '0' then
                        state <= IDLE;

                    elsif delay_counter < MAX_COUNT then
                        delay_counter <= delay_counter + 1;
                        prox_andar <= floor_to_increment; 

                    else
                        prox_andar <= std_logic_vector(unsigned(floor_to_increment) + 1);
                        state <= MOVED;
                    end if;

                when INCREMENTED =>
                    if is_closed = '0' then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end architecture behavioral;
