-- Arquivo: top_level.vhd
-- (Com correções de integração aplicadas)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.Tipos_Elevadores.all;

-- Top_Level: integra todos os módulos do sistema de elevadores
entity Top_Level is
    -- CORREÇÃO 3 (do Testbench): Adicionado genérico para controlar o tempo da porta
    -- na simulação. Passe um valor baixo no TB (ex: 50) e mantenha o
    -- padrão alto para síntese.
    generic (
        G_DOOR_CYCLES : integer := 100_000_000
    );
    port (
        CLK : in std_logic;
        reset : in std_logic;

        -- Chamadas externas (botões nos andares)
        call_up_in : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
        call_down_in : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);

        -- Botões internos das cabines: matriz_botoes(2 DOWNTO 0) (cada vetor 0..ULTIMO_ANDAR)
        botoes_internos_in: in matriz_botoes(2 DOWNTO 0); 

        -- Botões especiais (abrir/fechar) passados do TB para cada cabine
        botao_abrir_in    : in std_logic_vector(2 DOWNTO 0);
        botao_fechar_in   : in std_logic_vector(2 DOWNTO 0);
        
        -- Entradas de sensores de andar (simuladas pelo testbench / plant)
        -- Cada elemento é std_logic_vector(4 DOWNTO 0) (andares 0..31)
        andar_sensor_in   : in matriz_andar(2 DOWNTO 0); 
        
        -- Saídas de comando para o "hardware" (3 elevadores)
        motor_up_out      : out std_logic_vector(2 DOWNTO 0);   -- sinal de sentido subir
        motor_down_out    : out std_logic_vector(2 DOWNTO 0);   -- sinal de sentido descer
        motor_enable_out  : out std_logic_vector(2 DOWNTO 0);   -- habilita motor (1 = ligar)
        
        -- Comandos de porta (para atuar em um módulo de porta físico ou simulado)
        porta_fechando_out: out std_logic_vector(2 DOWNTO 0);
        porta_abrindo_out : out std_logic_vector(2 DOWNTO 0);
        
        -- Saídas para displays 7-seg (2 displays por elevador: dezenas e unidades)
        seg7_dezenas_out  : out matriz_seg7(2 DOWNTO 0);
        seg7_unidades_out : out matriz_seg7(2 DOWNTO 0)
    );
end Top_level;

architecture Estructural of Top_Level is

    -- Componente: Supervisor_Global (escalonador nível 2)
    component Supervisor_Global
        Port (
            botoes_in            : in matriz_botoes(2 DOWNTO 0);
            botoes_subir_in      : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            botoes_descer_in     : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);

            andaresElevadores_in : in matriz_andar(2 DOWNTO 0);
            direcaoElevadores_in : in std_logic_vector(2 DOWNTO 0);

            proximoAndar_out     : out std_logic_vector(4 DOWNTO 0);
            elevadorEscolhido    : out std_logic_vector(1 DOWNTO 0);
            direcao_out          : out std_logic
        );
    end component;
    
    -- Componente: Controlador local (por elevador)
    component Controlador
        port (
            CLK                  : in  std_logic;
            RESET                : in  std_logic;
            andar_atual_in       : in  std_logic_vector(4 DOWNTO 0);
            andar_destino_in     : in  std_logic_vector(4 DOWNTO 0);
            direcao_req_in       : in  std_logic;            
            door_closed_in       : in  std_logic;
            door_open_in         : in  std_logic;            
            
            botao_abrir_in       : in std_logic;      
            botao_fechar_in      : in std_logic;     

            botoes_pendentes_in  : in  std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            botoes_pendentes_out : out std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            
            start_close_out      : out std_logic;
            start_open_out       : out std_logic;      
            motor_enable_out     : out std_logic;
            move_up_out          : out std_logic;
            move_down_out        : out std_logic
        );
    end component;

    -- Componente: porta
    -- CORREÇÃO 1 (BUG 1): Nome do componente corrigido de "porta_elevador" para "porta"
    -- CORREÇÃO 1 (BUG 3): Adicionado G_MAX_COUNT ao componente
    component porta
        generic (
            G_MAX_COUNT : integer
        );
        port (
            clk         : in std_logic; 
            reset       : in std_logic; 
            start_close : in std_logic; 
            start_open  : in std_logic; -- inicia abertura

            door_closed : out std_logic; 
            door_open   : out std_logic  -- status porta aberta
        );
    end component;

    -- Componente: Teclado (painel interno da cabine)
    component Teclado
        port (
            botoes_in        : in STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0);
            andares_in       : in STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0);
            botao_abrir_in   : in STD_LOGIC;
            botao_fechar_in  : in STD_LOGIC;
            botao_motor_in   : in STD_LOGIC;
            
            abrir_porta_out  : out STD_LOGIC;
            fechar_porta_out : out STD_LOGIC;
            estado_motor_out : out STD_LOGIC;
            andares_out      : out STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0)
        );
    end component;

    -- Componente: Display 7 segmentos (two displays per elevator)
    component Led_7Segmentos_Andar
        Port (
            entrada            : in  std_logic_vector(4 DOWNTO 0);
            segmentos_dezenas  : out std_logic_vector(6 DOWNTO 0);
            segmentos_unidades : out std_logic_vector(6 DOWNTO 0)
        );
    end component;

    -- Sinais usados para comunicação interna entre Supervisor/Controladores/Teclados/Portas
    signal s_andar_destino_sup   : std_logic_vector(4 DOWNTO 0);   -- próximo andar escolhido pelo supervisor
    signal s_elevador_escolhido  : std_logic_vector (1 DOWNTO 0);                      -- elevador escolhido pelo supervisor (0..2)
    signal s_direcao_destino_sup : std_logic;                      -- direção associada ao destino ('1' = subir)

    -- Feedback do estado dos elevadores para o supervisor
    signal s_andares_atuais  : matriz_andar(2 DOWNTO 0);         -- andares atuais lidos dos sensores
    signal s_direcoes_atuais : std_logic_vector(2 DOWNTO 0);     -- indica movimento (1 = em movimento numa direção)

    -- Vetores de pedidos internos (Teclado <-> Controlador)
    signal s_pedidos_internos : matriz_botoes(2 DOWNTO 0); -- pedidos que o teclado passa para o supervisor
    signal s_pedidos_limpos   : matriz_botoes(2 DOWNTO 0); -- pedidos pós-limpeza (controlador -> teclado)
    signal s_botao_abrir_teclado: std_logic_vector(2 DOWNTO 0); -- botão abrir da cabine (entrada do teclado)
    signal s_botao_fechar_teclado: std_logic_vector(2 DOWNTO 0); -- botão fechar da cabine

    -- Sinais de comando do controlador para "hardware"
    signal s_motor_enable: std_logic_vector(2 DOWNTO 0);
    signal s_move_up     : std_logic_vector(2 DOWNTO 0);
    signal s_move_down   : std_logic_vector(2 DOWNTO 0);

    -- Sinais entre controlador e porta
    signal s_start_close : std_logic_vector(2 DOWNTO 0);
    signal s_start_open  : std_logic_vector(2 DOWNTO 0);
    signal s_door_closed : std_logic_vector(2 DOWNTO 0);
    signal s_door_open   : std_logic_vector(2 DOWNTO 0);
    
    -- Sinais de roteamento (cada elevador tem seu destino final; por padrão é o próprio andar)
    signal s_andar_destino_elevador  : matriz_andar(2 DOWNTO 0);
    signal s_direcao_destino_elevador: std_logic_vector(2 DOWNTO 0);

begin

    -- Instancia o Supervisor_Global que recebe todos os pedidos e decide qual elevador atende
    Supervisor_Global_Inst: Supervisor_Global
        port map (
            botoes_in            => s_pedidos_internos,   -- pedidos internos atualizados pelos teclados
            botoes_subir_in      => call_up_in,           -- pedidos externos "subir"
            botoes_descer_in     => call_down_in,         -- pedidos externos "descer"

            andaresElevadores_in => s_andares_atuais,     -- feedback dos sensores (plants)
            direcaoElevadores_in => s_direcoes_atuais,    -- feedback de direção/movimento
            
            proximoAndar_out     => s_andar_destino_sup,  -- destino escolhido (global)
            elevadorEscolhido    => s_elevador_escolhido, -- índice do elevador escolhido
            direcao_out          => s_direcao_destino_sup -- direção do pedido
        );

    -- Roteamento: aplica o proximoAndar_out APENAS ao elevador escolhido
    Roteamento_Supervisor_Proc: 
    process (s_elevador_escolhido, s_andar_destino_sup, s_direcao_destino_sup, andar_sensor_in)
        variable chosen_int : integer;
    begin
        -- Default: para todos os elevadores, o destino é o próprio andar atual (não forçar movimentação)
        for i in 0 to 2 loop
            s_andar_destino_elevador(i)  <= andar_sensor_in(i);
            s_direcao_destino_elevador(i) <= '0';
        end loop;
        
        -- Se o supervisor escolheu um elevador válido (0..2), roteia o destino e a direção apenas para ele
        chosen_int := to_integer(unsigned(s_elevador_escolhido));
        if chosen_int >= 0 and chosen_int <= 2 then
            s_andar_destino_elevador(chosen_int) <= s_andar_destino_sup;
            s_direcao_destino_elevador(chosen_int) <= s_direcao_destino_sup;
        end if;
        
    end process Roteamento_Supervisor_Proc;

    
    -- Geração das três instâncias do elevador (0, 1 e 2) via generate
    -- Cada iteração instancia: Teclado, Controlador, Porta e Display
    Elevador_Gerador: 
    for i in 0 to 2 generate
        
        -- Feedback: informa ao supervisor o andar atual lido pelo sensor/plant
        s_andares_atuais(i) <= andar_sensor_in(i); 

        ----------------------------------------------------
        -- C.1. Instanciação do Teclado (painel interno da cabine)
        ----------------------------------------------------

        Teclado_Inst: Teclado
            port map (
                botoes_in        => botoes_internos_in(i),  -- botões do testbench/painel
                andares_in       => s_pedidos_limpos(i),    -- pedidos pendentes (recebidos do controlador)
                
                -- Botões especiais (passados pelo top-level / testbench)
                botao_abrir_in   => botao_abrir_in(i),
                botao_fechar_in  => botao_fechar_in(i),
                botao_motor_in   => '0', -- não usado nesse design

                -- Saídas do Teclado (para o Controlador)
                abrir_porta_out  => s_botao_abrir_teclado(i),
                fechar_porta_out => s_botao_fechar_teclado(i),
                estado_motor_out => open, 
                andares_out      => s_pedidos_internos(i)  -- atualiza pedidos internos (para o Supervisor)
            );

        ----------------------------------------------------
        -- C.2. Instanciação do Controlador Local (FSM) para o elevador i
        ----------------------------------------------------
        Controlador_Inst: Controlador
            port map (
                CLK                  => CLK,
                RESET                => RESET,
                
                -- Entradas de Controle/Status
                andar_atual_in       => andar_sensor_in(i),
                andar_destino_in     => s_andar_destino_elevador(i),   -- destino (apenas se o elevador foi escolhido)
                direcao_req_in       => s_direcao_destino_elevador(i), -- direção do destino
                door_closed_in       => s_door_closed(i),
                door_open_in         => s_door_open(i),              

                -- Entradas do Teclado (Botões Especiais)
                botao_abrir_in       => s_botao_abrir_teclado(i),
                botao_fechar_in      => s_botao_fechar_teclado(i),

                -- Pedidos internos (Teclado <-> Controlador)
                botoes_pendentes_in  => s_pedidos_internos(i),
                botoes_pendentes_out => s_pedidos_limpos(i),       -- O controlador limpa o botão atendido

                -- Saídas de Comando (Motor e Porta)
                start_close_out      => s_start_close(i),
                start_open_out       => s_start_open(i),             
                motor_enable_out     => s_motor_enable(i),
                move_up_out          => s_move_up(i),
                move_down_out        => s_move_down(i)
            );
        
        -- Feedback de Direção para o Supervisor:
        -- CORREÇÃO 2 (BUG 2): A direção é '1' se move_up_out='1', '0' caso contrário.
        -- O supervisor espera '1' para subir e '0' para descer/parado.
        s_direcoes_atuais(i) <= s_move_up(i);

        ----------------------------------------------------
        -- C.3. Instanciação da Porta (FSM de porta por elevador)
        ----------------------------------------------------
        
        -- CORREÇÃO 4 (BUG 1 e 3): Nome da instância corrigido para "porta" e
        -- "generic map" adicionado para passar o G_DOOR_CYCLES.
        Porta_Inst: porta
            generic map (
                G_MAX_COUNT => G_DOOR_CYCLES
            )
            port map (
                clk         => CLK, 
                reset       => RESET, 
                start_close => s_start_close(i),
                start_open  => s_start_open(i),

                door_closed => s_door_closed(i),
                door_open   => s_door_open(i)
            );

        ----------------------------------------------------
        -- C.4. Instanciação do Display de 7 segmentos (mostra o andar atual)
        ----------------------------------------------------
        Display_Inst: Led_7Segmentos_Andar
            port map (
                entrada            => andar_sensor_in(i),
                segmentos_dezenas  => seg7_dezenas_out(i),
                segmentos_unidades => seg7_unidades_out(i)
            );

    end generate Elevador_Gerador;
    
    ----------------------------------------------------------------------
    -- D. Conexão das saídas internas para as saídas externas do Top_Level
    ----------------------------------------------------------------------
    motor_up_out       <= s_move_up;
    motor_down_out     <= s_move_down;
    motor_enable_out   <= s_motor_enable;
    porta_fechando_out <= s_start_close;
    porta_abrindo_out  <= s_start_open;
    
end architecture Estructural;
