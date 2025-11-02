library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.Tipos_Elevadores.all;

-- Controlador: máquina de estados que controla um elevador individualmente

entity Controlador is
    port (
        CLK             : in  std_logic;
        RESET           : in  std_logic;
        
        -- Entradas do Sistema / Supervisor
        andar_atual_in  : in  std_logic_vector(4 downto 0);      -- andar lido do sensor (0..31)
        andar_destino_in: in  std_logic_vector(4 downto 0);      -- destino recebido do supervisor
        direcao_req_in  : in  std_logic;                         -- direcao pedida pelo supervisor ('1' = subir)
        door_closed_in  : in  std_logic;                         -- status da porta (porta fechada)
        door_open_in    : in  std_logic;                         -- status da porta (porta aberta)

        -- Botões especiais (abrir/fechar) vindos do teclado local
        botao_abrir_in  : in std_logic;
        botao_fechar_in : in std_logic;
        
        -- Interface com o teclado: pedidos internos pendentes (entrada) e pedidos "limpos" (saída)
        botoes_pendentes_in  : in  std_logic_vector(ULTIMO_ANDAR downto 0); -- vet. pedidos atuais (keyboard -> controlador)
        botoes_pendentes_out : out std_logic_vector(ULTIMO_ANDAR downto 0); -- vet. atualizado (controlador -> keyboard)
        
        -- Saídas de controle para hardware (porta e motor)
        start_close_out : out std_logic;    -- iniciar fechamento de porta
        start_open_out  : out std_logic;    -- iniciar abertura da porta
        motor_enable_out: out std_logic;    -- habilitar motor (1 = motor ligado)
        move_up_out     : out std_logic;    -- comando de direção: subir
        move_down_out   : out std_logic     -- comando de direção: descer
    );
end Controlador;

architecture Behavioral of Controlador is

    -- Estado atual e próximo estado da FSM (definidos em Tipos_Elevadores)
    signal estado_atual, proximo_estado : t_estado := IDLE;
    
    -- Registro do vetor de botões pendentes (botoes_reg) e próximo valor (botoes_next)
    -- Padrão "reg/next" evita múltiplos drivers e é adequado para síntese.
    signal botoes_reg  : std_logic_vector(ULTIMO_ANDAR downto 0) := (others => '0');
    signal botoes_next : std_logic_vector(ULTIMO_ANDAR downto 0) := (others => '0');
    
begin


    -- - On RESET: inicializa estado e limpa pedidos
    -- - On rising_edge(CLK): atualiza estado e botoes_reg <- botoes_next
    process (CLK, RESET) is
    begin
        if RESET = '1' then
            estado_atual <= IDLE;             -- estado inicial
            botoes_reg   <= (others => '0');  -- limpa todos os pedidos
        elsif rising_edge(CLK) then
            estado_atual <= proximo_estado;   -- atualiza o estado (registro)
            botoes_reg   <= botoes_next;      -- atualiza o vetor de pedidos (registro)
        end if;
    end process;
    
    -- Saída para o teclado: vetor de pedidos pendentes é a cópia registrada
    -- (o teclado lê esse vetor para mostrar/armazenar o estado atual dos botões)
    botoes_pendentes_out <= botoes_reg;

    -- - Calcula proximo_estado e sinais de controle com base no estado atual e entradas
    -- - Usa variáveis locais para conversões numéricas (atual_int, destino_int)
    -- - Atualiza botoes_next a partir de var_botoes (copia de botoes_pendentes_in)
    process (estado_atual, andar_atual_in, andar_destino_in, direcao_req_in,
             door_closed_in, door_open_in, botoes_pendentes_in, botoes_reg,
             botao_abrir_in, botao_fechar_in) is
        -- Variáveis auxiliares para comparações inteiras
        variable atual_int    : integer := 0;
        variable destino_int  : integer := 0;
        -- var_botoes é usado para modificar localmente o vetor de pedidos antes de gravá-lo em botoes_next
        variable var_botoes   : std_logic_vector(ULTIMO_ANDAR downto 0) := (others => '0');
    begin
        -- Valores default para evitar latches e garantir comportamento determinístico
        proximo_estado   <= estado_atual;  -- por padrão permanece no mesmo estado
        motor_enable_out <= '0';           -- motor desligado por padrão
        move_up_out      <= '0';           -- sem direção por padrão
        move_down_out    <= '0';
        start_close_out  <= '0';           -- não iniciar fechamento por padrão
        start_open_out   <= '0';           -- não iniciar abertura por padrão

        -- Converte vetores binários para inteiros para facilitar comparações
        atual_int   := safe_to_integer(andar_atual_in);
        destino_int := safe_to_integer(andar_destino_in);

        -- Inicializa var_botoes com os pedidos vindos do teclado (novos pedidos entram)
        var_botoes := botoes_pendentes_in;
        -- Define botoes_next como padrão para os pedidos atuais (pode ser alterado abaixo)
        botoes_next <= botoes_pendentes_in;

        -- FSM: lógica por estado
        case estado_atual is

            when IDLE =>
                -- Se o elevador não está no destino ou se usuário pediu fechar porta,
                -- inicia procedimento de fechamento (preparar para mover)
                if (atual_int /= destino_int) or (botao_fechar_in = '1') then
                    proximo_estado <= FECHANDO_PORTA;
                else
                    proximo_estado <= IDLE; -- permanece em idle
                end if;

            when FECHANDO_PORTA =>
                -- Solicita fechamento da porta
                start_close_out <= '1';
                -- Se usuário apertar abrir durante o fechamento, aborta e abre
                if botao_abrir_in = '1' then
                    proximo_estado <= ABRINDO_PORTA;
                -- Se porta reportar que já está fechada, pode iniciar movimento
                elsif door_closed_in = '1' then
                    proximo_estado <= MOVER;
                end if;

            when MOVER =>
                -- Se ainda não chegou ao destino, liga motor e define direção
                if atual_int /= destino_int then
                    motor_enable_out <= '1';
                    if direcao_req_in = '1' then
                        move_up_out <= '1';
                    else
                        move_down_out <= '1';
                    end if;
                else
                    -- Chegou ao andar desejado: transita para rotina de chegada
                    proximo_estado <= CHEGOU_ANDAR;
                end if;

            when CHEGOU_ANDAR =>
                -- Garante que motor esteja desligado ao chegar
                motor_enable_out <= '0';
                -- Limpa o pedido do andar atual no vetor local var_botoes, para depois atualizar botoes_next
                if botoes_reg(atual_int) = '1' then
                    var_botoes(atual_int) := '0';
                end if;
                -- Em seguida, abrir porta para embarque/desembarque
                proximo_estado <= ABRINDO_PORTA;

            when ABRINDO_PORTA =>
                -- Comanda abertura da porta
                start_open_out <= '1';
                -- Aguarda sinal indicativo de porta aberta para voltar ao IDLE
                if door_open_in = '1' then
                    proximo_estado <= IDLE;
                end if;

        end case;

        -- Ao final do processo combinacional, botoes_next é atualizado com var_botoes
        botoes_next <= var_botoes;
    end process;
end architecture Behavioral;