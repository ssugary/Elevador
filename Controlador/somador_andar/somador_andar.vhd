library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity somador_andar is
    generic (
        N_BITS : integer := 4;
        G_MAX_COUNT : integer := 100_000_000
    );
    port (
    -- entradas
        clk         : in std_logic;
        is_closed   : in std_logic; 
        andar_atual : in std_logic_vector(N_BITS - 1 downto 0);
    -- saidas
        prox_andar  : out std_logic_vector(N_BITS - 1 downto 0)
    );
end entity somador_andar;

architecture behavioral of somador_andar is

    constant MAX_COUNT   : integer := G_MAX_COUNT;

    signal delay_counter : integer range 0 to MAX_COUNT;

    -- Define os estados da FSM
    type state_t is (
        PARADO,
        MOVENDO,
        PARANDO
    );
    signal state : state_t := PARADO;

    signal floor_to_increment : std_logic_vector(N_BITS - 1 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            case state is

              -- quando parado, prox andar = andar atual
                when PARADO =>
                    prox_andar <= andar_atual; 
                    delay_counter <= 0;

                    -- se a porta fechou, começa a se mover
                    if is_closed = '1' then
                        floor_to_increment <= andar_atual;
                        state <= MOVENDO;
                    end if;

                    -- se a porta abriu, para
                when MOVENDO =>
                    if is_closed = '0' then
                        state <= PARADO;

                        -- se o timer ainda não chegou no máx, continua se movendo
                    elsif delay_counter < MAX_COUNT then
                        delay_counter <= delay_counter + 1;
                        prox_andar <= floor_to_increment; 

                        -- Se o timer chegou ao máx e a porta está fechada, começa a parar
                    else
                        prox_andar <= std_logic_vector(unsigned(floor_to_increment) + 1);
                        state <= PARANDO;
                    end if;

                    -- quando começa a parar, só muda o estado para parado quando de fato parar
                when PARANDO =>
                    if is_closed = '0' then
                        state <= PARADO;
                    end if;
            end case;
        end if;
    end process;

end architecture behavioral;
