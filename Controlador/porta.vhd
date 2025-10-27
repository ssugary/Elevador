library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

-- A porta do nosso elevador é implementada por um registrador e uma máquina de estados finitos.

entity porta_elevador is
    port (
        -- Entradas: clock, reiniciador de estados e um sinal para iniciar o fechamento da porta.
        clk         : in std_logic; 
        reset       : in std_logic; 
        start_close : in std_logic; 

        door_closed : out std_logic -- Saída: o elevador só deve se mexer se o sinal door_closed for igual a 1
    );
end entity porta_elevador;

-- define a arquitetura máquina de estados finitos com um temporizador que será utilizada pelo circuito
architecture fsm_com_timer of porta_elevador is

    -- frequência fictícia de 50Hz do clock do nosso sistema de elevador
    constant CLK_FREQUENCY : integer := 50_000_000;
    -- tempo que a porta leva pra fechar
    constant DELAY_SECONDS : integer := 2;
    -- valor máximo do contador
    constant MAX_COUNT : integer := CLK_FREQUENCY * DELAY_SECONDS;

    type t_estado is (ABERTA, FECHANDO, FECHADA);

    signal estado_atual, proximo_estado : t_estado;

    signal timer_count : integer range 0 to MAX_COUNT;

begin
  -- define o reset de estados e a sucessão de estados
    process (clk, reset)
    begin
        -- se reset = 1 reseta para o estado atual: ABERTA
        if reset = '1' then
            estado_atual <= ABERTA;
            timer_count  <= 0;
        -- se não, vai para o estado sucessor
        elsif rising_edge(clk) then
            estado_atual <= proximo_estado;
            -- se o estado sucessor for FECHANDO, passa 2s fechando a porta
            if proximo_estado = FECHANDO then
                if timer_count < MAX_COUNT - 1 then
                    timer_count <= timer_count + 1;
                else
                    timer_count <= 0; 
                end if;
            else
                timer_count <= 0;
            end if;

          end if;
    end process;


    -- define qual é o estado sucessor de cada estado (ABERTA -> FECHANDO -> FECHADA) e implementa a mudança de estados
    process (estado_atual, start_close, timer_count)
    begin
        proximo_estado <= estado_atual;

        case estado_atual is
            when ABERTA =>
                if start_close = '1' then
                    proximo_estado <= FECHANDO; 
                end if;

            when FECHANDO =>
                if timer_count = MAX_COUNT - 1 then 
                    proximo_estado <= FECHADA; 
                end if;

            when FECHADA =>
                proximo_estado <= FECHADA;

        end case;
    end process;

    -- o sinal door_closed só é verdadeiro se o estado atual for FECHADA
    door_closed <= '1' when estado_atual = FECHADA else
                   '0';

end architecture fsm_com_timer;
