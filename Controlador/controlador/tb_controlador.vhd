library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Tipos_Elevadores.all; -- Essencial para t_direcao e matrizes

entity tb_controlador is
end entity;

architecture Sim of tb_controlador is

    -- 1. Componente a ser testado (DUT)
    -- Atualizado para bater com sua entity nova
    component Controlador
        port (
            CLK             : in  std_logic;
            RESET           : in  std_logic;
            
            andar_atual_in  : in  std_logic_vector(4 downto 0);
            andar_destino_in: in  std_logic_vector(4 downto 0);
            direcao_req_in  : in  t_direcao; -- Tipo corrigido
            
            door_closed_in  : in  std_logic;
            door_open_in    : in  std_logic;
            botao_abrir_in  : in  std_logic;
            botao_fechar_in : in  std_logic;
            
            motor_enable_out: out std_logic;
            move_up_out     : out std_logic;
            move_down_out   : out std_logic;
            start_open_out  : out std_logic;
            start_close_out : out std_logic
        );
    end component;

    -- 2. Componentes Auxiliares (Para o elevador funcionar na simulação)
    component somador_andar
        generic (G_TIME_PER_FLOOR : integer := 50);
        port (
            clk, reset, motor_enable_in, move_up_in, move_down_in : in std_logic;
            andar_atual_out : out std_logic_vector(4 downto 0);
            moving_out : out std_logic
        );
    end component;

    component porta
        generic (G_MAX_COUNT : integer := 50);
        port (
            clk, reset, start_close, start_open : in std_logic;
            door_closed, door_open : out std_logic
        );
    end component;

    -- Sinais de Clock e Reset
    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';
    constant T_CLK : time := 20 ns;

    -- Sinais de Interconexão
    signal s_andar_atual   : std_logic_vector(4 downto 0);
    signal s_andar_destino : std_logic_vector(4 downto 0) := (others => '0');
    signal s_direcao_req   : t_direcao := PARADO;

    -- Sensores da Porta
    signal s_door_closed, s_door_open : std_logic;

    -- Comandos do Controlador
    signal s_motor_enable : std_logic;
    signal s_move_up      : std_logic;
    signal s_move_down    : std_logic;
    signal s_start_open   : std_logic;
    signal s_start_close  : std_logic;

begin

    -- Gerador de Clock
    clk <= not clk after T_CLK / 2;

    -- Instância do Controlador (DUT)
    U_Controlador: Controlador
        port map (
            CLK              => clk,
            RESET            => reset,
            andar_atual_in   => s_andar_atual,
            andar_destino_in => s_andar_destino,
            direcao_req_in   => s_direcao_req, -- Recebe SUBINDO/DESCENDO/PARADO
            
            door_closed_in   => s_door_closed,
            door_open_in     => s_door_open,
            botao_abrir_in   => '0', -- Sem interação manual neste teste
            botao_fechar_in  => '0',
            
            motor_enable_out => s_motor_enable,
            move_up_out      => s_move_up,
            move_down_out    => s_move_down,
            start_open_out   => s_start_open,
            start_close_out  => s_start_close
        );

    -- Instância do Motor (Simula a física)
    U_Motor: somador_andar
        generic map (G_TIME_PER_FLOOR => 10) -- Rápido para simulação
        port map (
            clk => clk, reset => reset,
            motor_enable_in => s_motor_enable,
            move_up_in => s_move_up, move_down_in => s_move_down,
            andar_atual_out => s_andar_atual, moving_out => open
        );

    -- Instância da Porta (Simula a física)
    U_Porta: porta
        generic map (G_MAX_COUNT => 20) -- Rápida para simulação
        port map (
            clk => clk, reset => reset,
            start_close => s_start_close, start_open => s_start_open,
            door_closed => s_door_closed, door_open => s_door_open
        );

    -- Processo de Estímulo (Age como o Supervisor)
    process
    begin
        report ">>> INICIO TESTBENCH CONTROLADOR <<<" severity note;

        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- =======================================================
        -- TESTE 1: Subir do 0 para o 3
        -- =======================================================
        report "CENARIO 1: Ordenando ir para o Andar 3 (SUBINDO)";
        
        -- O Supervisor define o alvo e a direção
        s_andar_destino <= safe_to_vector(3, 5);
        s_direcao_req   <= SUBINDO;

        -- O Controlador deve:
        -- 1. Perceber que Destino (3) != Atual (0).
        -- 2. Mandar fechar porta (se estiver aberta).
        -- 3. Ligar motor (UP).
        -- 4. Parar no 3.
        -- 5. Abrir porta.

        -- Vamos esperar até o elevador chegar no 3
        wait until safe_to_integer(s_andar_atual) = 3 for 5 us;
        
        assert safe_to_integer(s_andar_atual) = 3 
            report "FALHA C1: Nao chegou no andar 3" severity error;

        report "Elevador chegou no 3. Verificando abertura de porta...";
        
        -- Espera porta abrir
        wait until s_door_open = '1' for 2 us;
        assert s_door_open = '1' report "FALHA C1: Porta nao abriu" severity error;


        -- =======================================================
        -- TESTE 2: Descer do 3 para o 1
        -- =======================================================
        wait for 200 ns;
        report "CENARIO 2: Ordenando ir para o Andar 1 (DESCENDO)";

        s_andar_destino <= safe_to_vector(1, 5);
        s_direcao_req   <= DESCENDO;

        -- Espera chegar no 1
        wait until safe_to_integer(s_andar_atual) = 1 for 5 us;

        assert safe_to_integer(s_andar_atual) = 1
            report "FALHA C2: Nao chegou no andar 1" severity error;

        report "Elevador chegou no 1. Sucesso.";
        
        -- =======================================================
        -- TESTE 3: Comando de Ficar Parado (IDLE)
        -- =======================================================
        wait for 200 ns;
        report "CENARIO 3: Mantendo posicao (IDLE)";
        
        -- Supervisor diz: Destino = Atual
        s_andar_destino <= s_andar_atual; 
        s_direcao_req   <= PARADO;

        wait for 200 ns;
        assert s_motor_enable = '0' report "FALHA C3: Motor deveria estar desligado" severity error;

        report ">>> FIM DA SIMULACAO <<<" severity note;
        wait;
    end process;

end architecture;