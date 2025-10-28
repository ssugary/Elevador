library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.Tipos_Elevadores.all;

entity Controlador is               -- 80% disso foi gpt, não confio (estava sem tempo e fiz isso para ter uma base :p )
    port (
        CLK             : in  std_logic;
        RESET           : in  std_logic;
        
        -- INs do Sistema / Supervisor
        andar_atual_in  : in  std_logic_vector(4 downto 0);      -- LIDO do sensor de andar
        andar_destino_in: in  std_logic_vector(4 downto 0);      -- ESCOLHIDO pelo Supervisor_Global/Unico
        direcao_req_in  : in  std_logic;                         -- DIREÇÃO ESCOLHIDA pelo Supervisor
        door_closed_in  : in  std_logic;                         -- LIDO do módulo 'porta.vhd'
        
        -- IN/OUT do Teclado (Para LIMPAR chamadas internas)
        botoes_pendentes_in  : in  std_logic_vector(31 downto 0); -- LIDO do 'keyboard.vhd'
        botoes_pendentes_out : out std_logic_vector(31 downto 0); -- ENVIADO de volta ao 'keyboard.vhd'
        
        -- OUTs para o Hardware (Porta e Motor)
        start_close_out : out std_logic;                         -- ENVIADO para 'porta.vhd'
        motor_enable_out: out std_logic;                         -- LIGAR/DESLIGAR motor
        move_up_out     : out std_logic;                         -- SENTIDO para motor (Subir)
        move_down_out   : out std_logic                          -- SENTIDO para motor (Descer)
    );
    end Controlador;
    architecture Behavioral of Controlador is
    -- Definição dos estados da FSM
    signal estado_atual, proximo_estado : t_estado;
    
    -- Sinais auxiliares para limpar o botão
    signal botoes_temp : std_logic_vector(31 downto 0);

begin
    
    -- ---------------------------------------
    -- Processo 1: Máquina de Estados (Registrador de Estado)
    -- ---------------------------------------
    process (CLK, RESET) is
    begin
        if RESET = '1' then
            estado_atual <= IDLE;
            botoes_temp  <= (others => '0');
        elsif rising_edge(CLK) then
            estado_atual <= proximo_estado;
            botoes_temp  <= botoes_pendentes_in;
        end if;
    end process;
    
    botoes_pendentes_out <= botoes_temp; -- Passa os pedidos para o teclado, exceto quando limpa

    -- ---------------------------------------
    -- Processo 2: Lógica Combinacional (Próximo Estado e Saídas)
    -- ---------------------------------------
    process (estado_atual, andar_atual_in, andar_destino_in, direcao_req_in, door_closed_in, botoes_pendentes_in, botoes_temp) is
        -- Conversão para Integer, pois é mais fácil de comparar
        variable atual_int    : integer;
        variable destino_int  : integer;
    begin
        -- Default: Nenhuma ação
        proximo_estado   <= estado_atual;
        motor_enable_out <= '0';
        move_up_out      <= '0';
        move_down_out    <= '0';
        start_close_out  <= '0';

        atual_int   := to_integer(unsigned(andar_atual_in));
        destino_int := to_integer(unsigned(andar_destino_in));
        
        case estado_atual is
            
            when IDLE =>
                -- O elevador está no andar de destino ou sem destino
                if atual_int /= destino_int then
                    -- Há um novo destino. Inicia o fechamento da porta.
                    proximo_estado <= FECHANDO_PORTA;
                    
                else 
                    -- Não há novo destino ou já chegou. Fica em IDLE.
                    -- (Assumindo que em IDLE a porta pode estar aberta ou fechada)
                    proximo_estado <= IDLE;
                end if;
                
            when FECHANDO_PORTA =>
                start_close_out <= '1'; -- Sinaliza para a porta iniciar o fechamento
                
                if door_closed_in = '1' then
                    -- Porta fechou completamente (após 2s, de acordo com porta.vhd)
                    proximo_estado <= MOVER;
                end if;

            when MOVER =>
                if atual_int /= destino_int then
                    motor_enable_out <= '1'; -- Liga o motor
                    
                    -- Define a direção do movimento
                    if direcao_req_in = '1' then -- Subir
                        move_up_out <= '1';
                    else                         -- Descer
                        move_down_out <= '1';
                    end if;
                    
                else
                    -- Chegou ao destino
                    proximo_estado <= CHEGOU_ANDAR;
                end if;
                
            when CHEGOU_ANDAR =>
                -- Para o motor (garantia, mesmo que já estivesse parado)
                motor_enable_out <= '0';
                
                -- Limpa o botão que foi atendido (AQUI ESTÁ A CHAVE)
                if botoes_pendentes_in(atual_int) = '1' then
                    -- Mantém todos os outros bits, exceto o do andar atual
                    botoes_temp(atual_int) <= '0';
                end if;
                
                -- Após limpar o pedido, a próxima ação é abrir a porta
                proximo_estado <= ABRINDO_PORTA;
                
            when ABRINDO_PORTA =>
                -- Nenhuma ação é necessária aqui. A porta permanece aberta (estado ABERTA em porta.vhd)
                
                -- Transição para o IDLE para aguardar novo destino ou fechamento de porta
                -- Para que o controlador não fique parado, volta para IDLE para verificar se há um novo destino.
                proximo_estado <= IDLE; 
                
        end case;
    end process;
end architecture Behavioral;

