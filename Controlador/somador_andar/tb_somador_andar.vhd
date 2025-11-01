library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Tipos_Elevadores.all; -- ESSENCIAL: O DUT depende deste pacote

entity tb_somador_andar is
    -- Testbench não possui portas
end entity tb_somador_andar;


architecture behavior of tb_somador_andar is

    -- 1. Declaração do Componente (Cópia exata da 'entity' do DUT)
    component somador_andar is
        generic (
            N_BITS : integer := 5;
            G_TIME_PER_FLOOR : integer := 200
        );
        port (
            clk             : in std_logic;
            reset           : in std_logic;
            motor_enable_in : in std_logic;
            move_up_in      : in std_logic;
            move_down_in    : in std_logic;
            andar_atual_out : out std_logic_vector(N_BITS - 1 downto 0);
            moving_out      : out std_logic
        );
    end component somador_andar;

    -- 2. Constantes de Teste
    constant C_N_BITS         : integer := 5;
    constant C_TIME_PER_FLOOR : integer := 200;
    constant C_CLK_PERIOD     : time    := 10 ns;

    -- 3. Sinais para conectar ao DUT
    -- Entradas
    signal s_clk             : std_logic := '0';
    signal s_reset           : std_logic;
    signal s_motor_enable_in : std_logic;
    signal s_move_up_in      : std_logic;
    signal s_move_down_in    : std_logic;
    
    -- Saídas
    signal s_andar_atual_out : std_logic_vector(C_N_BITS - 1 downto 0);
    signal s_moving_out      : std_logic;

begin

    -- 4. Instanciação do DUT (Device Under Test)
    UUT : somador_andar
        generic map (
            N_BITS           => C_N_BITS,
            G_TIME_PER_FLOOR => C_TIME_PER_FLOOR
        )
        port map (
            clk             => s_clk,
            reset           => s_reset,
            motor_enable_in => s_motor_enable_in,
            move_up_in      => s_move_up_in,
            move_down_in    => s_move_down_in,
            andar_atual_out => s_andar_atual_out,
            moving_out      => s_moving_out
        );

    -- 5. Processo de Geração de Clock
    clk_process : process
    begin
        s_clk <= '0';
        wait for C_CLK_PERIOD / 2;
        s_clk <= '1';
        wait for C_CLK_PERIOD / 2;
    end process clk_process;

    -- 6. Processo de Estímulo e Verificação
    stim_process : process
    
        -- Procedimento helper para aguardar a troca de andar
        procedure wait_for_floor_change is
        begin
            -- O DUT leva 1 ciclo para entrar em MOVENDO (a partir de PARADO)
            -- e C_TIME_PER_FLOOR ciclos para o contador (0 a 199)
            -- Total: C_TIME_PER_FLOOR + 1 ciclos
            wait for (C_TIME_PER_FLOOR + 1) * C_CLK_PERIOD;
        end procedure wait_for_floor_change;
        
        -- Procedimento helper para aguardar a parada completa
        procedure wait_for_stop is
        begin
            -- O DUT leva 1 ciclo para ver o 'stop' (entrar em PARADO)
            -- e +1 ciclo para atualizar 'moving_out' no estado PARADO
            -- Total: 2 ciclos
            wait for 2 * C_CLK_PERIOD;
        end procedure wait_for_stop;

    begin
        report "TESTBENCH: Iniciando simulacao...";
        
        -- 1. RESET INICIAL
        s_reset           <= '1';
        s_motor_enable_in <= '0';
        s_move_up_in      <= '0';
        s_move_down_in    <= '0';
        wait for 5 * C_CLK_PERIOD; 
        
        s_reset <= '0';
        wait for C_CLK_PERIOD; 
        
        -- Verificação Pós-Reset
        assert (s_andar_atual_out = std_logic_vector(to_unsigned(0, C_N_BITS)))
            report "Falha Pós-Reset: Andar nao e 0." severity error;
        assert (s_moving_out = '0')
            report "Falha Pós-Reset: moving_out nao e '0'." severity error;

        wait for 2 * C_CLK_PERIOD;

        -- 2. TESTE DE SUBIDA (0 -> 1 -> 2)
        report "TESTE: Movendo para cima (0 -> 1)";
        s_motor_enable_in <= '1';
        s_move_up_in      <= '1';
        s_move_down_in    <= '0';
        
        wait_for_floor_change; -- Espera 201 ciclos
        
        -- Verificação
        assert (s_andar_atual_out = std_logic_vector(to_unsigned(1, C_N_BITS)))
            report "Falha Subida (0->1): Andar nao atualizou para 1." severity error;
        assert (s_moving_out = '1')
            report "Falha Subida: 'moving_out' deveria ser '1'." severity error;

        report "TESTE: Movendo para cima (1 -> 2)";
        wait_for_floor_change; -- Espera +201 ciclos
        
        -- Verificação
        assert (s_andar_atual_out = std_logic_vector(to_unsigned(2, C_N_BITS)))
            report "Falha Subida (1->2): Andar nao atualizou para 2." severity error;
            
        -- 3. TESTE DE PARADA
        report "TESTE: Parando o motor no andar 2";
        s_motor_enable_in <= '0';
        s_move_up_in      <= '0'; 
        
        wait_for_stop; -- Espera 2 ciclos
        
        -- Verificação
        assert (s_moving_out = '0')
            report "Falha Parada: 'moving_out' deveria ser '0'." severity error;
            
        -- Espera um tempo para garantir que não se move
        wait for (C_TIME_PER_FLOOR * 2) * C_CLK_PERIOD;
         assert (s_andar_atual_out = std_logic_vector(to_unsigned(2, C_N_BITS)))
            report "Falha Parada: Andar mudou enquanto estava parado." severity error;

        -- 4. TESTE DE DESCIDA (2 -> 1 -> 0)
        report "TESTE: Movendo para baixo (2 -> 1)";
        s_motor_enable_in <= '1';
        s_move_up_in      <= '0';
        s_move_down_in    <= '1';
        
        wait_for_floor_change; -- Espera 201 ciclos
        
        -- Verificação
        assert (s_andar_atual_out = std_logic_vector(to_unsigned(1, C_N_BITS)))
            report "Falha Descida (2->1): Andar nao atualizou para 1." severity error;

        report "TESTE: Movendo para baixo (1 -> 0)";
        wait_for_floor_change; -- Espera +201 ciclos
        
        -- Verificação
        assert (s_andar_atual_out = std_logic_vector(to_unsigned(0, C_N_BITS)))
            report "Falha Descida (1->0): Andar nao atualizou para 0." severity error;

        -- 5. TESTE DE LIMITE (Tentar ir abaixo de 0)
        report "TESTE: Tentando mover abaixo do andar 0";
        wait_for_floor_change; -- Espera +201 ciclos
        
        -- Verificação
        assert (s_andar_atual_out = std_logic_vector(to_unsigned(0, C_N_BITS)))
            report "Falha Limite Inferior: Andar foi para valor negativo (ou wraparound)." severity error;

        -- 6. TESTE DE PARADA NO MEIO DO PERCURSO
        report "TESTE: Parando no meio do percurso (subindo de 0 para 1)";
        s_motor_enable_in <= '1';
        s_move_up_in      <= '1';
        s_move_down_in    <= '0';

        wait for (C_TIME_PER_FLOOR / 2) * C_CLK_PERIOD; -- Espera 100 ciclos
        
        assert (s_andar_atual_out = std_logic_vector(to_unsigned(0, C_N_BITS)))
            report "Falha Parada (Meio): Andar mudou antes de completar o ciclo de delay." severity error;
        
        -- Manda parar
        s_motor_enable_in <= '0';
        wait_for_stop; -- Espera 2 ciclos
        
        assert (s_moving_out = '0')
            report "Falha Parada (Meio): 'moving_out' deveria ser '0' apos parada." severity error;
            
        -- Espera o resto do tempo (e mais) para garantir que não mudou
        wait for (C_TIME_PER_FLOOR * 2) * C_CLK_PERIOD;
        
        assert (s_andar_atual_out = std_logic_vector(to_unsigned(0, C_N_BITS)))
            report "Falha Parada (Meio): Andar mudou apos parada no meio do ciclo." severity error;

        report "TESTBENCH: Simulacao concluida com sucesso.";
        wait; 
        
    end process stim_process;

end architecture behavior;
