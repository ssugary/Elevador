library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 


entity porta is
    -- max count genérico para o teste ficar mais leve
    generic (
        G_MAX_COUNT : integer := 100_000_000
    );
    port (
    -- Entradas:
        clk         : in std_logic; 
        reset       : in std_logic; 
        start_close : in std_logic; 
        start_open  : in std_logic;
    -- Saídas:
        door_closed : out std_logic;
        door_open   : out std_logic
    );
end entity porta;


architecture fsm_com_timer of porta is
    constant MAX_COUNT : integer := G_MAX_COUNT;

    -- Estados da FSM
    type t_estado is (ABRINDO, ABERTA, FECHANDO, FECHADA);
    signal estado_atual, proximo_estado : t_estado := ABERTA;
    signal timer_count : integer range 0 to MAX_COUNT := 0; 

begin
    process (clk, reset)
    begin
        -- Lógica de reset
        if reset = '1' then
            estado_atual <= ABERTA; 
            timer_count  <= 0;

        -- Na rising edge ocorre a troca dos estados
        elsif rising_edge(clk) then
            estado_atual <= proximo_estado;

            -- Se prox estado for ABRINDO ou FECHANDO, começa a contar o timer
            if (proximo_estado = FECHANDO) or (proximo_estado = ABRINDO) then
                if timer_count < MAX_COUNT then
                    timer_count <= timer_count + 1;
                else
                    timer_count <= 0; 
                end if;
            -- Se o prox estado for ABERTA ou FECHADA, o timer zera
            else
                timer_count <= 0;
            end if;
        end if;
    end process;

    process (estado_atual, start_close, start_open, timer_count)
    begin
        proximo_estado <= estado_atual; 

        -- Estados ABRINDO e FECHANDO: proximo_estado muda quando o timer chega em 100
        -- Estados ABERTA e FECHADA: proximo_estado muda quando o sinal start_open ou start_close forem igual a 1
        case estado_atual is
            when ABRINDO =>
                if timer_count = MAX_COUNT then 
                    proximo_estado <= ABERTA; 
                end if;

            when ABERTA =>
                if start_close = '1' then
                    proximo_estado <= FECHANDO; 
                end if;

            when FECHANDO =>
                if timer_count = MAX_COUNT then 
                    proximo_estado <= FECHADA; 
                end if;

            when FECHADA =>
                if start_open = '1' then
                    proximo_estado <= ABRINDO;
                end if;
                
        end case;
    end process;


    -- Saídas
    door_closed <= '1' when estado_atual = FECHADA else '0';
    door_open   <= '1' when estado_atual = ABERTA  else '0';

end architecture fsm_com_timer;
