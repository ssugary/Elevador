library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.Tipos_Elevadores.all;

entity plant_elevador is
    generic (
        -- Número de ciclos de clock que representam o tempo para deslocar um andar.
        -- Use valores pequenos (ex.: 20..200) em simulação; ajuste para síntese/medição real.
        TIME_PER_FLOOR : integer := 50
    );
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;

        -- Comandos vindos do controlador (Top_Level -> Controller -> sinais que o TB deve conectar às plantas)
        motor_enable_in: in  std_logic;  -- habilita movimento
        move_up_in     : in  std_logic;  -- direção para subir
        move_down_in   : in  std_logic;  -- direção para descer

        -- Saídas do plant (ligar ao andar_sensor_in do Top_Level no TB)
        floor_out      : out std_logic_vector(4 downto 0);
        moving_out     : out std_logic   -- indica que está em movimento (útil para debug/testbench)
    );
end entity plant_elevador;

architecture Behavioral of plant_elevador is
    -- estado interno do andar (0 .. ULTIMO_ANDAR)
    signal cur_floor    : integer range 0 to ULTIMO_ANDAR := 0;
    -- contador para tempo por andar
    signal cycle_counter: integer range 0 to TIME_PER_FLOOR := 0;
    -- sinal interno indicando movimento em progresso
    signal moving       : std_logic := '0';
begin

    -- Processo síncrono que modela o movimento entre andares
    process(clk, reset)
        variable up_cmd   : boolean;
        variable down_cmd : boolean;
    begin
        if reset = '1' then
            cur_floor     <= 0;
            cycle_counter <= 0;
            moving        <= '0';
        elsif rising_edge(clk) then
            -- converte comandos para booleanos (evita ambiguidade se ambos ativos)
            up_cmd   := (motor_enable_in = '1') and (move_up_in = '1') and not (move_down_in = '1');
            down_cmd := (motor_enable_in = '1') and (move_down_in = '1') and not (move_up_in = '1');

            if up_cmd or down_cmd then
                -- em movimento: incrementa contador
                moving <= '1';
                if cycle_counter < TIME_PER_FLOOR - 1 then
                    cycle_counter <= cycle_counter + 1;
                else
                    -- alcance de tempo por andar: atualizar andar e zerar contador
                    cycle_counter <= 0;
                    if up_cmd then
                        if cur_floor < ULTIMO_ANDAR then
                            cur_floor <= cur_floor + 1;
                        else
                            -- já no topo: mantém no topo
                            cur_floor <= ULTIMO_ANDAR;
                        end if;
                    elsif down_cmd then
                        if cur_floor > 0 then
                            cur_floor <= cur_floor - 1;
                        else
                            cur_floor <= 0;
                        end if;
                    end if;
                end if;
            else
                -- sem comando ou comandos conflitantes: para movimento e zera contador
                moving <= '0';
                cycle_counter <= 0;
            end if;
        end if;
    end process;

    -- Saídas
    floor_out  <= std_logic_vector(to_unsigned(cur_floor, floor_out'length));
    moving_out <= moving;

end architecture Behavioral;