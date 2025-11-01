library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Tipos_Elevadores.all; -- Para ULTIMO_ANDAR

-- Esta é a versão MODIFICADA do somador_andar.
-- Ele age como uma "Planta" ou "Motor" que obedece o Controlador.
-- Ele substitui o plant_elevator.vhd.

entity somador_andar is
    generic (
        N_BITS : integer := 5; -- 5 bits para 32 andares
        G_TIME_PER_FLOOR : integer := 200 -- Tempo (em ciclos) para trocar de andar
    );
    port (
    -- Entradas de COMANDO (Vindas do Controlador)
        clk              : in std_logic;
        reset            : in std_logic;
        motor_enable_in  : in std_logic; -- '1' = Mover, '0' = Parar
        move_up_in       : in std_logic; -- '1' = Subir
        move_down_in     : in std_logic; -- '1' = Descer
        
    -- Saídas de STATUS (Para o Controlador)
        andar_atual_out  : out std_logic_vector(N_BITS - 1 downto 0);
        moving_out       : out std_logic -- Opcional: informa se está em movimento
    );
end entity somador_andar;


architecture behavioral of somador_andar is

    constant TIME_PER_FLOOR : integer := G_TIME_PER_FLOOR;
    signal delay_counter    : integer range 0 to TIME_PER_FLOOR;

    -- Seus estados originais (removi PARANDO por simplicidade, 
    -- o controlador já faz isso no estado MOVER)
    type state_t is (
        PARADO,
        MOVENDO
    );
    signal state : state_t := PARADO;
    
    -- Registro interno que guarda o andar atual
    signal andar_reg : integer range 0 to ULTIMO_ANDAR := 0;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            state <= PARADO;
            andar_reg <= 0;
            delay_counter <= 0;
            
        elsif rising_edge(clk) then
            
            case state is

                when PARADO =>
                    delay_counter <= 0;
                    moving_out    <= '0';
                    
                    -- AGORA ele obedece o Controlador:
                    -- Se o controlador mandar ligar o motor, começa a mover.
                    if motor_enable_in = '1' then
                        state <= MOVENDO;
                    end if;

                when MOVENDO =>
                    moving_out <= '1';
                    
                    -- Se o controlador mandar parar o motor (chegou ao destino)...
                    if motor_enable_in = '0' then
                        state <= PARADO;
                    
                    -- Se o timer (delay) não chegou no máximo, continua contando
                    elsif delay_counter < TIME_PER_FLOOR - 1 then
                        delay_counter <= delay_counter + 1;
                        
                    -- Se o timer chegou ao máximo...
                    else
                        delay_counter <= 0; -- Zera o timer
                        
                        -- E atualiza o andar baseado no comando do Controlador
                        if move_up_in = '1' and andar_reg < ULTIMO_ANDAR then
                            andar_reg <= andar_reg + 1;
                        elsif move_down_in = '1' and andar_reg > 0 then
                            andar_reg <= andar_reg - 1;
                        end if;
                    end if;

            end case;
        end if;
    end process;

    -- A saída é o valor do registro interno
    andar_atual_out <= std_logic_vector(to_unsigned(andar_reg, andar_atual_out'length));

end architecture behavioral;