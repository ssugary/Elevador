library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Tipos_Elevadores.all;

entity Controlador is
    port (
        CLK             : in  std_logic;
        RESET           : in  std_logic;
        
        andar_atual_in  : in  std_logic_vector(4 downto 0);
        andar_destino_in: in  std_logic_vector(4 downto 0);
        
        -- MUDANÇA: Recebe t_direcao
        direcao_req_in  : in  t_direcao; 
        
        door_closed_in  : in  std_logic;
        door_open_in    : in  std_logic;
        botao_abrir_in  : in std_logic;
        botao_fechar_in : in std_logic;
        
        -- Saídas Físicas
        motor_enable_out: out std_logic;
        move_up_out     : out std_logic;
        move_down_out   : out std_logic;
        
        start_open_out  : out std_logic;
        start_close_out : out std_logic
    );
end entity;

architecture Behavioral of Controlador is
    signal estado_atual, proximo_estado : t_estado := IDLE;
    signal timer_porta : integer range 0 to 1000 := 0; 
begin

    -- Lógica Sequencial (FSM)
    process(CLK, RESET)
    begin
        if RESET = '1' then
            estado_atual <= IDLE;
        elsif rising_edge(CLK) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    -- Lógica Combinacional
    process(estado_atual, andar_atual_in, andar_destino_in, direcao_req_in, 
            door_closed_in, door_open_in, botao_abrir_in, botao_fechar_in)
        
        variable atual_int   : integer;
        variable destino_int : integer;
    begin
        -- Default Outputs
        motor_enable_out <= '0';
        move_up_out      <= '0';
        move_down_out    <= '0';
        start_open_out   <= '0';
        start_close_out  <= '0';
        
        proximo_estado <= estado_atual;
        
        atual_int   := safe_to_integer(andar_atual_in);
        destino_int := safe_to_integer(andar_destino_in);

        case estado_atual is
            
            when IDLE =>
                -- Se destino diferente do atual, fecha porta para mover
                if atual_int /= destino_int then
                    if door_closed_in = '1' then
                        proximo_estado <= MOVER;
                    else
                        start_close_out <= '1'; -- Tenta fechar
                        proximo_estado <= FECHANDO_PORTA;
                    end if;
                elsif botao_abrir_in = '1' then
                    proximo_estado <= ABRINDO_PORTA;
                end if;

            when FECHANDO_PORTA =>
                start_close_out <= '1';
                if door_closed_in = '1' then
                    if atual_int /= destino_int then
                        proximo_estado <= MOVER;
                    else
                        proximo_estado <= IDLE;
                    end if;
                end if;

            when MOVER =>
                if atual_int = destino_int then
                    proximo_estado <= CHEGOU_ANDAR;
                else
                    motor_enable_out <= '1';
                    
                    -- MUDANÇA: Decisão baseada no t_direcao ou na geometria
                    -- Nota: É mais seguro confiar na geometria (Target > Current)
                    -- Mas se quiser obedecer estritamente o supervisor:
                    if direcao_req_in = SUBINDO then
                        move_up_out <= '1';
                    elsif direcao_req_in = DESCENDO then
                        move_down_out <= '1';
                    else
                        -- Fallback: Geometria
                        if destino_int > atual_int then move_up_out <= '1';
                        else move_down_out <= '1';
                        end if;
                    end if;
                end if;

            when CHEGOU_ANDAR =>
                -- Chegou, comanda abrir porta
                start_open_out <= '1'; 
                proximo_estado <= ABRINDO_PORTA;

            when ABRINDO_PORTA =>
                start_open_out <= '1';
                if door_open_in = '1' then
                    -- Aguarda botão fechar ou timer (simplificado aqui para IDLE)
                    if botao_fechar_in = '1' then 
                         proximo_estado <= FECHANDO_PORTA;
                    else
                         proximo_estado <= IDLE; -- Ou um estado de espera "PORTA_ABERTA"
                    end if;
                end if;
                
        end case;
    end process;
end architecture;