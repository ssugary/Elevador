library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Tipos_Elevadores.all;

-- Testbench que integra TODOS os componentes:
-- Controlador + Somador + Porta + Teclado + Display
entity tb_controlador_completo is
end entity tb_controlador_completo;

architecture sim of tb_controlador_completo is

    -- Constantes de simulação
    constant CLK_PERIOD       : time    := 10 ns;
    constant DOOR_SIM_CYCLES  : integer := 100; -- Porta
    constant FLOOR_SIM_CYCLES : integer := 200; -- Somador/Motor

    -- Componente 1: O Cérebro (Controlador)
    component Controlador is
        port (
            CLK             : in  std_logic;
            RESET           : in  std_logic;
            andar_atual_in  : in  std_logic_vector(4 downto 0);
            andar_destino_in: in  std_logic_vector(4 downto 0);
            direcao_req_in  : in  std_logic;
            door_closed_in  : in  std_logic;
            door_open_in    : in  std_logic;
            botao_abrir_in  : in  std_logic;  -- VEM DO TECLADO
            botao_fechar_in : in  std_logic;  -- VEM DO TECLADO
            botoes_pendentes_in  : in  std_logic_vector(ULTIMO_ANDAR downto 0); -- VEM DO TECLADO
            botoes_pendentes_out : out std_logic_vector(ULTIMO_ANDAR downto 0); -- VAI PARA O TECLADO
            motor_enable_out : out std_logic;
            move_up_out      : out std_logic;
            move_down_out    : out std_logic;
            start_close_out  : out std_logic;
            start_open_out   : out std_logic
        );
    end component Controlador;

    -- Componente 2: O Motor (Somador)
    component somador_andar is
        generic (
            N_BITS : integer := 5;
            G_TIME_PER_FLOOR : integer := 200
        );
        port (
            clk              : in std_logic;
            reset            : in std_logic;
            motor_enable_in  : in std_logic;
            move_up_in       : in std_logic;
            move_down_in     : in std_logic;
            andar_atual_out  : out std_logic_vector(N_BITS - 1 downto 0);
            moving_out       : out std_logic
        );
    end component somador_andar;

    -- Componente 3: A Porta
    component porta is
        generic ( G_MAX_COUNT : integer := 100_000_000 );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            start_close : in  std_logic;
            start_open  : in  std_logic;
            door_closed : out std_logic;
            door_open   : out std_logic
        );
    end component porta;

    -- Componente 4: O Teclado
    component Teclado is
        port (
            botoes_in        : in  STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0);
            andares_in       : in  STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0);
            botao_abrir_in   : in  STD_LOGIC;
            botao_fechar_in  : in  STD_LOGIC;
            botao_motor_in   : in  STD_LOGIC;
            abrir_porta_out  : out STD_LOGIC;
            fechar_porta_out : out STD_LOGIC;
            estado_motor_out : out STD_LOGIC;
            andares_out      : out STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0)
        );
    end component Teclado;

    -- Componente 5: O Display
    component Led_7Segmentos_Andar is
        Port (
            entrada            : in  std_logic_vector(4 downto 0);
            segmentos_dezenas  : out std_logic_vector(6 downto 0);
            segmentos_unidades : out std_logic_vector(6 downto 0)
        );
    end component Led_7Segmentos_Andar;


    -- Sinais do Testbench (Fios para conectar os componentes)
    signal tb_clk   : std_logic := '0';
    signal tb_reset : std_logic := '1';

    -- Estímulos (Simulando o Supervisor Nível 2 e o Usuário apertando botões)
    signal s_andar_destino : std_logic_vector(4 downto 0) := (others => '0');
    signal s_direcao_req   : std_logic := '0';
    -- Botões que o *usuário* aperta (vão para o Teclado)
    signal s_botoes_internos_press : std_logic_vector(ULTIMO_ANDAR downto 0) := (others => '0');
    signal s_botao_abrir_press     : std_logic := '0';
    signal s_botao_fechar_press    : std_logic := '0';
    signal s_botao_motor_press     : std_logic := '0'; -- (Não usado pelo Controlador)

    -- Fios: Controlador <-> Somador
    signal s_andar_atual    : std_logic_vector(4 downto 0);
    signal s_motor_enable   : std_logic;
    signal s_move_up        : std_logic;
    signal s_move_down      : std_logic;

    -- Fios: Controlador <-> Porta
    signal s_door_closed, s_door_open : std_logic;
    signal s_start_close, s_start_open : std_logic;
    
    -- Fios: Teclado <-> Controlador
    signal s_teclado_para_ctrl_botoes : std_logic_vector(ULTIMO_ANDAR downto 0);
    signal s_teclado_para_ctrl_abrir  : std_logic;
    signal s_teclado_para_ctrl_fechar : std_logic;
    signal s_ctrl_para_teclado_limpar : std_logic_vector(ULTIMO_ANDAR downto 0);
    
    -- Fios: Display (Saídas para o Waveform)
    signal s_display_dezenas  : std_logic_vector(6 downto 0);
    signal s_display_unidades : std_logic_vector(6 downto 0);


begin

    -- Geração de Clock
    tb_clk <= not tb_clk after CLK_PERIOD / 2;

    -- 1. Instância do Cérebro (Controlador)
    UUT_Controlador : Controlador
        port map (
            CLK             => tb_clk,
            RESET           => tb_reset,
            andar_atual_in  => s_andar_atual,    -- Feedback do Somador
            andar_destino_in=> s_andar_destino,  -- Estímulo (Supervisor)
            direcao_req_in  => s_direcao_req,    -- Estímulo (Supervisor)
            door_closed_in  => s_door_closed,    -- Feedback da Porta
            door_open_in    => s_door_open,      -- Feedback da Porta
            botao_abrir_in  => s_teclado_para_ctrl_abrir,  -- Feedback do Teclado
            botao_fechar_in => s_teclado_para_ctrl_fechar, -- Feedback do Teclado
            botoes_pendentes_in  => s_teclado_para_ctrl_botoes, -- Feedback do Teclado
            botoes_pendentes_out => s_ctrl_para_teclado_limpar, -- Comando para Teclado
            motor_enable_out => s_motor_enable, -- Comando para Somador
            move_up_out      => s_move_up,      -- Comando para Somador
            move_down_out    => s_move_down,    -- Comando para Somador
            start_close_out  => s_start_close,  -- Comando para Porta
            start_open_out   => s_start_open    -- Comando para Porta
        );

    -- 2. Instância do Motor (Somador)
    UUT_Somador : somador_andar
        generic map (
            G_TIME_PER_FLOOR => FLOOR_SIM_CYCLES
        )
        port map (
            clk              => tb_clk,
            reset            => tb_reset,
            motor_enable_in  => s_motor_enable,
            move_up_in       => s_move_up,
            move_down_in     => s_move_down,
            andar_atual_out  => s_andar_atual,
            moving_out       => open
        );

    -- 3. Instância da Porta
    UUT_Porta : porta
        generic map (
            G_MAX_COUNT => DOOR_SIM_CYCLES
        )
        port map (
            clk         => tb_clk,
            reset       => tb_reset,
            start_close => s_start_close,
            start_open  => s_start_open,
            door_closed => s_door_closed,
            door_open   => s_door_open
        );

    -- 4. Instância do Teclado
    UUT_Teclado : Teclado
        port map (
            botoes_in        => s_botoes_internos_press,  -- Estímulo (Usuário)
            andares_in       => s_ctrl_para_teclado_limpar, -- Feedback (Controlador)
            botao_abrir_in   => s_botao_abrir_press,    -- Estímulo (Usuário)
            botao_fechar_in  => s_botao_fechar_press,   -- Estímulo (Usuário)
            botao_motor_in   => s_botao_motor_press,  -- Estímulo (Usuário)
            
            abrir_porta_out  => s_teclado_para_ctrl_abrir,  -- Saída para Controlador
            fechar_porta_out => s_teclado_para_ctrl_fechar, -- Saída para Controlador
            estado_motor_out => open,                       -- Saída não utilizada
            andares_out      => s_teclado_para_ctrl_botoes  -- Saída para Controlador
        );

    -- 5. Instância do Display
    UUT_Display : Led_7Segmentos_Andar
        port map (
            entrada            => s_andar_atual,  -- Conectado no andar atual
            segmentos_dezenas  => s_display_dezenas,
            segmentos_unidades => s_display_unidades
        );


    -- Processo de Estímulo
    process
    begin
        report "TB: Iniciando simulacao (COMPLETA)." severity note;
        tb_reset <= '1';
        wait for CLK_PERIOD * 10;
        tb_reset <= '0';
        report "TB: Reset liberado. IDLE no andar 0." severity note;
        wait until rising_edge(tb_clk);

        -- Cenário 1: 0 -> 5 (Pedido pelo Supervisor)
        report "TB: Cenario 1 - Indo do andar 0 para o 5." severity note;
        s_andar_destino <= "00101";
        s_direcao_req   <= '1'; -- Subir
        
        -- O usuário também aperta o botão 5 (simulando Teclado)
        s_botoes_internos_press(5) <= '1';
        wait until rising_edge(tb_clk);
        s_botoes_internos_press(5) <= '0';
        
        report "TB: Esperando porta fechar..." severity note;
        wait until s_door_closed = '1' and rising_edge(tb_clk);
        
        report "TB: Porta fechada. Movendo (0 -> 5)..." severity note;
        wait until s_andar_atual = "00101" and rising_edge(tb_clk);
        
        report "TB: Chegou ao andar 5. Abrindo porta." severity note;
        wait until s_door_open = '1' and rising_edge(tb_clk);
        
        -- Neste ponto, verifique no waveform se s_ctrl_para_teclado_limpar(5) = '0'
        report "TB: Cenario 1 completo." severity note;
        wait for CLK_PERIOD * 50;
        
        -- Cenário 2: 5 -> 2 (Pedido pelo Usuário)
        report "TB: Cenario 2 - Indo do andar 5 para o 2." severity note;
        -- Supervisor não pede (destino = atual)
        s_andar_destino <= s_andar_atual; 
        s_direcao_req   <= '0'; -- (irrelevante, mas vamos manter)
        
        -- Usuário aperta o botão 2
        s_botoes_internos_press(2) <= '1';
        wait until rising_edge(tb_clk);
        s_botoes_internos_press(2) <= '0';
        
        -- NOTA: Seu controlador atual só obedece o Supervisor (andar_destino_in).
        -- Para este cenário 2 funcionar, o Supervisor (Nível 2)
        -- teria que ver o botão(2) e definir andar_destino_in = 2.
        -- Vamos simular o Supervisor fazendo isso:
        s_andar_destino <= "00010";

        report "TB: Esperando porta fechar..." severity note;
        wait until s_door_closed = '1' and rising_edge(tb_clk);

        report "TB: Porta fechada. Movendo (5 -> 2)..." severity note;
        wait until s_andar_atual = "00010" and rising_edge(tb_clk);
        
        report "TB: Chegou ao andar 2. Abrindo porta." severity note;
        wait until s_door_open = '1' and rising_edge(tb_clk);
        
        report "TB: Simulacao concluida." severity note;
        wait;
    end process;

end architecture sim;