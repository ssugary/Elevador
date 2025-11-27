library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Tipos_Elevadores.all; -- Essencial para t_direcao e matrizes

entity tb_Supervisor_Global is
end entity;

architecture Behavioral of tb_Supervisor_Global is

    -- Declaração do componente (DUT) atualizada com t_direcao
    component Supervisor_Global
        port (
            botoes_in            : in matriz_botoes(2 DOWNTO 0);
            botoes_subir_in      : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            botoes_descer_in     : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            andaresElevadores_in : in matriz_andar(2 DOWNTO 0);
            direcaoElevadores_in : in vetor_direcao(2 DOWNTO 0);
            proximoAndar_out     : out matriz_andar(2 DOWNTO 0);
            direcao_req_out      : out vetor_direcao(2 DOWNTO 0)
        );
    end component;

    -- Sinais de Estímulo
    signal s_botoes_in            : matriz_botoes(2 DOWNTO 0) := (others => (others => '0'));
    signal s_botoes_subir_in      : std_logic_vector(ULTIMO_ANDAR DOWNTO 0) := (others => '0');
    signal s_botoes_descer_in     : std_logic_vector(ULTIMO_ANDAR DOWNTO 0) := (others => '0');
    signal s_andaresElevadores_in : matriz_andar(2 DOWNTO 0) := (others => (others => '0'));
    signal s_direcaoElevadores_in : vetor_direcao(2 DOWNTO 0) := (others => PARADO);

    -- Sinais de Monitoramento (Saídas)
    signal s_proximoAndar_out     : matriz_andar(2 DOWNTO 0);
    signal s_direcao_req_out      : vetor_direcao(2 DOWNTO 0);

    -- Tempo de propagação para a lógica combinacional estabilizar
    constant T_WAIT : time := 20 ns;

begin

    -- Instanciação do DUT (Device Under Test)
    DUT: Supervisor_Global port map (
        botoes_in            => s_botoes_in,
        botoes_subir_in      => s_botoes_subir_in,
        botoes_descer_in     => s_botoes_descer_in,
        andaresElevadores_in => s_andaresElevadores_in,
        direcaoElevadores_in => s_direcaoElevadores_in,
        proximoAndar_out     => s_proximoAndar_out,
        direcao_req_out      => s_direcao_req_out
    );

    -- Processo Principal de Testes
    process
    begin
        report "=======================================================" severity note;
        report " INICIANDO TESTBENCH: SUPERVISOR GLOBAL (COM ENUM) " severity note;
        report "=======================================================" severity note;

        -- -------------------------------------------------------------------
        -- CENÁRIO 1: Pedidos Internos (Sem interferência)
        -- Objetivo: Verificar se o Global repassa as decisões dos Locais.
        -- -------------------------------------------------------------------
        report ">> CENARIO 1: Pedidos Internos Basicos";
        
        -- Reset inputs
        s_botoes_in <= (others => (others => '0'));
        s_andaresElevadores_in <= (others => safe_to_vector(0, 5)); -- Todos no térreo
        s_direcaoElevadores_in <= (others => PARADO);

        -- Estímulo: Elevador 0 quer ir ao 5. Elevador 1 quer ir ao 10.
        s_botoes_in(0)(5) <= '1';
        s_botoes_in(1)(10) <= '1';

        wait for T_WAIT;

        -- Verificações
        assert (safe_to_integer(s_proximoAndar_out(0)) = 5) 
            report "FALHA C1: Elevador 0 deveria ir ao andar 5" severity error;
        assert (s_direcao_req_out(0) = SUBINDO) 
            report "FALHA C1: Elevador 0 deveria estar SUBINDO" severity error;
        assert (safe_to_integer(s_proximoAndar_out(1)) = 10) 
            report "FALHA C1: Elevador 1 deveria ir ao andar 10" severity error;

        -- -------------------------------------------------------------------
        -- CENÁRIO 2: Proximidade Simples (Chamado Externo)
        -- Objetivo: O elevador mais perto (mesmo estando parado) deve ganhar.
        -- -------------------------------------------------------------------
        report ">> CENARIO 2: Chamada Externa (Proximidade)";
        
        -- Limpa botões anteriores
        s_botoes_in <= (others => (others => '0')); 
        s_botoes_subir_in <= (others => '0');

        -- Configuração: Chamado no Andar 20 (SUBIR)
        s_botoes_subir_in(20) <= '1';

        -- Estados:
        -- Elev 0: Andar 0  (Distancia 20)
        -- Elev 1: Andar 18 (Distancia 2) -> FAVORITO
        -- Elev 2: Andar 25 (Distancia 5)
        s_andaresElevadores_in(0) <= safe_to_vector(0, 5);
        s_andaresElevadores_in(1) <= safe_to_vector(18, 5);
        s_andaresElevadores_in(2) <= safe_to_vector(25, 5);
        s_direcaoElevadores_in <= (others => PARADO); -- Todos livres

        wait for T_WAIT;

        assert (safe_to_integer(s_proximoAndar_out(1)) = 20)
            report "FALHA C2: Elevador 1 (o mais perto) deveria ganhar" severity error;
        assert (s_direcao_req_out(1) = SUBINDO)
            report "FALHA C2: Elevador 1 deveria começar a SUBIR" severity error;

        -- -------------------------------------------------------------------
        -- CENÁRIO 3: Penalidade de Direção Oposta
        -- Objetivo: Um elevador longe vindo a favor é melhor que um perto na contramão.
        -- -------------------------------------------------------------------
        report ">> CENARIO 3: Direcao Favoravel vs Contramao";

        s_botoes_subir_in <= (others => '0');
        s_botoes_subir_in(15) <= '1'; -- Alguém quer SUBIR no 15

        -- Elev 0: No 16, DESCENDO. (Distancia 1, mas está descendo -> Ruim)
        s_andaresElevadores_in(0) <= safe_to_vector(16, 5);
        s_direcaoElevadores_in(0) <= DESCENDO;

        -- Elev 1: No 10, SUBINDO. (Distancia 5, mas está indo na direção -> Bom)
        s_andaresElevadores_in(1) <= safe_to_vector(10, 5);
        s_direcaoElevadores_in(1) <= SUBINDO;

        wait for T_WAIT;

        assert (safe_to_integer(s_proximoAndar_out(1)) = 15)
            report "FALHA C3: Elevador 1 (favoravel) deveria ganhar do Elevador 0 (contramao)" severity error;
        
        -- Garante que o Elev 0 continua sua vida (não foi desviado)
        assert (safe_to_integer(s_proximoAndar_out(0)) /= 15)
            report "FALHA C3: Elevador 0 não deveria ser desviado" severity error;

        -- -------------------------------------------------------------------
        -- CENÁRIO 4: O "Bug do Já Passou" (Validando a correção)
        -- Objetivo: Elevador subindo que já passou do andar não deve parar.
        -- -------------------------------------------------------------------
        report ">> CENARIO 4: Logica 'Ja Passou'";

        s_botoes_subir_in <= (others => '0');
        s_botoes_subir_in(5) <= '1'; -- Chamado no 5 para SUBIR

        -- Elev 0: No 6, SUBINDO. (Passou do 5. Se parar, passageiros internos odeiam)
        s_andaresElevadores_in(0) <= safe_to_vector(6, 5);
        s_direcaoElevadores_in(0) <= SUBINDO;

        -- Elev 1: No 0, PARADO. (Está longe, mas é o único que pode atender)
        s_andaresElevadores_in(1) <= safe_to_vector(0, 5);
        s_direcaoElevadores_in(1) <= PARADO;

        wait for T_WAIT;

        assert (safe_to_integer(s_proximoAndar_out(1)) = 5)
            report "FALHA C4: Elevador 1 deveria ganhar (Elev 0 ja passou)" severity error;
        
        assert (s_direcao_req_out(1) = SUBINDO)
            report "FALHA C4: Elevador 1 deveria subir" severity error;

        -- -------------------------------------------------------------------
        -- CENÁRIO 5: Chamada de Descida (Validando botoes_descer_in)
        -- Objetivo: Testar lógica para pessoas querendo descer.
        -- -------------------------------------------------------------------
        report ">> CENARIO 5: Chamada para DESCER";

        s_botoes_subir_in <= (others => '0');
        s_botoes_descer_in <= (others => '0');
        s_botoes_descer_in(10) <= '1'; -- Alguém no 10 quer DESCER

        -- Elev 0: No 15, DESCENDO. (Perfeito: está acima e descendo)
        s_andaresElevadores_in(0) <= safe_to_vector(15, 5);
        s_direcaoElevadores_in(0) <= DESCENDO;

        -- Elev 1: No 5, SUBINDO. (Péssimo: está abaixo e subindo)
        s_andaresElevadores_in(1) <= safe_to_vector(5, 5);
        s_direcaoElevadores_in(1) <= SUBINDO;

        -- Elev 2: No 8, DESCENDO. (Ruim: Está descendo, mas JÁ PASSOU do 10)
        s_andaresElevadores_in(2) <= safe_to_vector(8, 5);
        s_direcaoElevadores_in(2) <= DESCENDO;

        wait for T_WAIT;

        assert (safe_to_integer(s_proximoAndar_out(0)) = 10)
            report "FALHA C5: Elevador 0 deveria ganhar chamada de descida" severity error;

        -- -------------------------------------------------------------------
        -- FINALIZAÇÃO
        -- -------------------------------------------------------------------
        report "=======================================================" severity note;
        report " TESTES CONCLUIDOS COM SUCESSO (Se nenhuma falha acima)" severity note;
        report "=======================================================" severity note;
        
        wait; -- Para a simulação
    end process;

end architecture;