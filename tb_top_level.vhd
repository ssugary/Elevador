library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Tipos_Elevadores.all;

entity tb_Top_Level is
end entity tb_Top_Level;

architecture sim of tb_Top_Level is

    -- Constantes de simulação
    constant CLK_PERIOD      : time    := 10 ns;
    -- Tempos curtos para simulação RÁPIDA
    constant T_PORTA_CYCLES  : integer := 50;  -- 50 ciclos para porta abrir/fechar
    constant T_ANDAR_CYCLES  : integer := 100; -- 100 ciclos para mudar de andar

    -- Componente (DUT): Top_Level
    -- (Assumindo que o genérico G_DOOR_CYCLES foi adicionado conforme a correção)
    component Top_Level
        generic (
            G_DOOR_CYCLES : integer
        );
        port (
            CLK                 : in  std_logic;
            reset               : in  std_logic;
            call_up_in          : in  std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            call_down_in        : in  std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            botoes_internos_in  : in  matriz_botoes(2 DOWNTO 0);
            botao_abrir_in      : in  std_logic_vector(2 DOWNTO 0);
            botao_fechar_in     : in  std_logic_vector(2 DOWNTO 0);
            andar_sensor_in     : in  matriz_andar(2 DOWNTO 0);
            motor_up_out        : out std_logic_vector(2 DOWNTO 0);
            motor_down_out      : out std_logic_vector(2 DOWNTO 0);
            motor_enable_out    : out std_logic_vector(2 DOWNTO 0);
            porta_fechando_out  : out std_logic_vector(2 DOWNTO 0);
            porta_abrindo_out   : out std_logic_vector(2 DOWNTO 0);
            seg7_dezenas_out    : out matriz_seg7(2 DOWNTO 0);
            seg7_unidades_out   : out matriz_seg7(2 DOWNTO 0)
        );
    end component;

    -- Componente (Plant): Simulador de motor/sensor
    component somador_andar
        generic (
            N_BITS             : integer := 5;
            G_TIME_PER_FLOOR   : integer
        );
        port (
            clk                : in  std_logic;
            reset              : in  std_logic;
            motor_enable_in    : in  std_logic;
            move_up_in         : in  std_logic;
            move_down_in       : in  std_logic;
            andar_atual_out    : out std_logic_vector(N_BITS - 1 downto 0);
            moving_out         : out std_logic
        );
    end component;

    -- Sinais do Testbench
    signal s_clk   : std_logic := '0';
    signal s_reset : std_logic := '0';

    -- Entradas do DUT
    signal s_call_up_in         : std_logic_vector(ULTIMO_ANDAR DOWNTO 0) := (others => '0');
    signal s_call_down_in       : std_logic_vector(ULTIMO_ANDAR DOWNTO 0) := (others => '0');
    signal s_botoes_internos_in : matriz_botoes(2 DOWNTO 0)                := (others => (others => '0'));
    signal s_botao_abrir_in     : std_logic_vector(2 DOWNTO 0)             := (others => '0');
    signal s_botao_fechar_in    : std_logic_vector(2 DOWNTO 0)             := (others => '0');
    signal s_andar_sensor_in    : matriz_andar(2 DOWNTO 0); -- Vem do Plant

    -- Saídas do DUT (Entradas do Plant)
    signal s_motor_up_out     : std_logic_vector(2 DOWNTO 0);
    signal s_motor_down_out   : std_logic_vector(2 DOWNTO 0);
    signal s_motor_enable_out : std_logic_vector(2 DOWNTO 0);

    -- Saídas (apenas para observação no simulador)
    signal s_porta_fechando_out : std_logic_vector(2 DOWNTO 0);
    signal s_porta_abrindo_out  : std_logic_vector(2 DOWNTO 0);
    signal s_seg7_dezenas_out   : matriz_seg7(2 DOWNTO 0);
    signal s_seg7_unidades_out  : matriz_seg7(2 DOWNTO 0);

begin

    -- 1. Instanciação do DUT (Top_Level)
    UUT : Top_Level
        generic map (
            -- Passando o tempo de porta rápido para a simulação
            G_DOOR_CYCLES => T_PORTA_CYCLES 
        )
        port map (
            CLK                 => s_clk,
            reset               => s_reset,
            call_up_in          => s_call_up_in,
            call_down_in        => s_call_down_in,
            botoes_internos_in  => s_botoes_internos_in,
            botao_abrir_in      => s_botao_abrir_in,
            botao_fechar_in     => s_botao_fechar_in,
            andar_sensor_in     => s_andar_sensor_in, -- Conectado ao Plant
            motor_up_out        => s_motor_up_out,    -- Conectado ao Plant
            motor_down_out      => s_motor_down_out,  -- Conectado ao Plant
            motor_enable_out    => s_motor_enable_out, -- Conectado ao Plant
            porta_fechando_out  => s_porta_fechando_out,
            porta_abrindo_out   => s_porta_abrindo_out,
            seg7_dezenas_out    => s_seg7_dezenas_out,
            seg7_unidades_out   => s_seg7_unidades_out
        );

    -- 2. Geração dos 3 "Plant Models" (Simuladores de Elevador)
    Plant_Gerador : for i in 0 to 2 generate
        Plant_Inst : somador_andar
            generic map (
                N_BITS           => 5,
                G_TIME_PER_FLOOR => T_ANDAR_CYCLES
            )
            port map (
                clk             => s_clk,
                reset           => s_reset,
                motor_enable_in => s_motor_enable_out(i),
                move_up_in      => s_motor_up_out(i),
                move_down_in    => s_motor_down_out(i),
                andar_atual_out => s_andar_sensor_in(i),
                moving_out      => open -- não usado
            );
    end generate Plant_Gerador;


    -- 3. Processo de Clock
    Clock_Proc : process
    begin
        s_clk <= '0';
        wait for CLK_PERIOD / 2;
        s_clk <= '1';
        wait for CLK_PERIOD / 2;
    end process Clock_Proc;


    -- 4. Processo de Estímulos (Testes)
    Stimulus_Proc : process
        -- Procedimento para simular um pulso em um botão
        procedure sim_press_button(
            signal button_vector : inout std_logic_vector;
            constant floor_index : in    integer) is
        begin
            button_vector(floor_index) <= '1';
            wait for CLK_PERIOD;
            button_vector(floor_index) <= '0';
            wait for CLK_PERIOD;
        end procedure;

        -- Procedimento para simular pulso (botões internos)
        procedure sim_press_button_matrix(
            signal button_matrix : inout matriz_botoes;
            constant elev_index  : in    integer;
            constant floor_index : in    integer) is
        begin
            button_matrix(elev_index)(floor_index) <= '1';
            wait for CLK_PERIOD;
            button_matrix(elev_index)(floor_index) <= '0';
            wait for CLK_PERIOD;
        end procedure;

        -- Procedimento para esperar o tempo da porta (abrir ou fechar)
        procedure wait_door is
        begin
            wait for (T_PORTA_CYCLES + 5) * CLK_PERIOD; -- +5 ciclos de margem
        end procedure;

        -- Procedimento para esperar o movimento entre andares
        procedure wait_floors(constant num_floors : in integer) is
        begin
            wait for (T_ANDAR_CYCLES * num_floors + 10) * CLK_PERIOD; -- +10 ciclos de margem
        end procedure;

    begin
        -- Início da Simulação
        report "TB: Iniciando simulação...";
        s_reset <= '1';
        wait for 2 * CLK_PERIOD;
        s_reset <= '0';
        wait for 5 * CLK_PERIOD; -- Espera FSMs estabilizarem

        -- -----------------------------------------------------------------
        -- TESTE 1: Chamada interna (Elevador 0, Andar 5)
        -- -----------------------------------------------------------------
        report "TB: TESTE 1 - Chamada interna E0 -> Andar 5";
        -- Pressiona botão 5 no elevador 0
        sim_press_button_matrix(s_botoes_internos_in, 0, 5);

        -- O Controlador(0) deve detectar o pedido (via Supervisor) e ir para FECHANDO_PORTA
        report "TB: TESTE 1 - Esperando porta fechar...";
        wait_door;
        
        -- O Controlador(0) deve ir para MOVER (0 -> 5)
        report "TB: TESTE 1 - Esperando mover (0 -> 5)...";
        wait_floors(5);
        
        -- O Controlador(0) deve CHEGAR_ANDAR e ir para ABRINDO_PORTA
        report "TB: TESTE 1 - Esperando porta abrir no andar 5...";
        wait_door;
        
        report "TB: TESTE 1 - Elevador 0 chegou ao 5 e abriu. Em IDLE.";
        wait for 20 * CLK_PERIOD;

        -- -----------------------------------------------------------------
        -- TESTE 2: Chamada externa (Andar 10, Subir)
        -- -----------------------------------------------------------------
        report "TB: TESTE 2 - Chamada externa (Andar 10, Subir)";
        -- Pressiona botão SUBIR no andar 10
        sim_press_button(s_call_up_in, 10);
        
        -- O Supervisor Global deve alocar o elevador mais próximo (E0, que está no 5)
        report "TB: TESTE 2 - Esperando porta fechar (E0)...";
        wait_door;
        
        -- O Controlador(0) deve ir para MOVER (5 -> 10)
        report "TB: TESTE 2 - Esperando mover (5 -> 10)...";
        wait_floors(5);
        
        -- O Controlador(0) deve CHEGAR_ANDAR e ir para ABRINDO_PORTA
        report "TB: TESTE 2 - Esperando porta abrir no andar 10...";
        wait_door;

        report "TB: TESTE 2 - Elevador 0 chegou ao 10 e atendeu chamada.";
        wait for 20 * CLK_PERIOD;

        -- -----------------------------------------------------------------
        -- TESTE 3: Chamadas Múltiplas e Concorrentes
        -- -----------------------------------------------------------------
        report "TB: TESTE 3 - Chamadas múltiplas (E1->3, E2->7, Ext->Down@15)";
        
        -- Elevador 1 (parado no 0) pede andar 3
        sim_press_button_matrix(s_botoes_internos_in, 1, 3);
        
        -- Elevador 2 (parado no 0) pede andar 7
        sim_press_button_matrix(s_botoes_internos_in, 2, 7);
        
        -- Chamada externa: Andar 15, Descer
        sim_press_button(s_call_down_in, 15);
        
        -- O Supervisor deve:
        -- 1. Atender pedidos internos E1 e E2 (E1->3, E2->7)
        -- 2. Atender pedido externo (Down@15). O E0 (no andar 10) é o mais próximo.
        
        report "TB: TESTE 3 - Esperando todas as chamadas serem atendidas (simulação longa)...";
        
        -- Espera E0 (10->15), E1 (0->3), E2 (0->7) e portas
        wait_floors(15); -- Tempo suficiente para tudo acontecer
        wait_door;
        wait_door;
        wait_door;
        
        report "TB: Simulação concluída.";
        wait; -- Fim da simulação
    end process Stimulus_Proc;

end architecture sim;
