library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Tipos_Elevadores.all;

entity tb_Top_Level is
end entity;

architecture Sim of tb_Top_Level is

    constant T_CLK : time := 20 ns; 

    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';

    signal btn_subir   : std_logic_vector(ULTIMO_ANDAR downto 0) := (others => '0');
    signal btn_descer  : std_logic_vector(ULTIMO_ANDAR downto 0) := (others => '0');
    signal btn_cabines : matriz_botoes(2 downto 0) := (others => (others => '0'));

    signal leds_0, leds_1, leds_2 : std_logic_vector(4 downto 0);
    signal leds_porta : std_logic_vector(2 downto 0);

begin

    DUT: entity work.Top_Level
        port map (
            clk => clk, reset => reset,
            btn_corredor_subir => btn_subir,
            btn_corredor_descer => btn_descer,
            btn_cabines_in => btn_cabines,
            leds_andar_0 => leds_0,
            leds_andar_1 => leds_1,
            leds_andar_2 => leds_2,
            leds_porta_aberta => leds_porta
        );

    clk <= not clk after T_CLK / 2;

    process
        -- Pulsa botões por 2 clocks
        procedure pulsar_interno(elev_idx : integer; andar : integer) is
        begin
            btn_cabines(elev_idx)(andar) <= '1';
            wait for T_CLK * 2;
            btn_cabines(elev_idx)(andar) <= '0';
        end procedure;

        procedure pulsar_externo_subir(andar : integer) is
        begin
            btn_subir(andar) <= '1';
            wait for T_CLK * 2;
            btn_subir(andar) <= '0';
        end procedure;
        
        procedure pulsar_externo_descer(andar : integer) is
        begin
            btn_descer(andar) <= '1';
            wait for T_CLK * 2;
            btn_descer(andar) <= '0';
        end procedure;

    begin
        report ">>> INICIO SIMULACAO SINCRONIZADA <<<";
        reset <= '1'; wait for 100 ns; reset <= '0'; wait for 100 ns;

        -- -------------------------------------------------------------------
        -- CENÁRIO 1: Elev 0 -> Andar 5
        -- -------------------------------------------------------------------
        report ">> C1: Elev 0 vai ao 5";
        pulsar_interno(0, 5);
        
        -- ESPERA INTELIGENTE: Aguarda até chegar no 5 (timeout de 20us)
        wait until safe_to_integer(leds_0) = 5 for 20 us;
        
        assert safe_to_integer(leds_0) = 5 
            report "FALHA C1: Nao chegou ao 5" severity error;
        
        -- Espera a porta fechar para garantir que está livre para o próximo
        wait for 5 us; 

        -- -------------------------------------------------------------------
        -- CENÁRIO 2: Proximidade (Call 7) -> Elev 0 (no 5) vs Elev 1 (no 0)
        -- -------------------------------------------------------------------
        report ">> C2: Proximidade (Call 7)";
        pulsar_externo_subir(7);
        
        -- O Elev 0 está perto, deve chegar rápido
        wait until safe_to_integer(leds_0) = 7 for 20 us;

        assert safe_to_integer(leds_0) = 7 
            report "FALHA C2: Elev 0 nao atendeu" severity error;
        assert safe_to_integer(leds_1) = 0 
            report "FALHA C2: Elev 1 moveu errado" severity error;
        
        wait for 5 us;

        -- -------------------------------------------------------------------
        -- PREPARAÇÃO: Mover Elev 1 para o 20
        -- -------------------------------------------------------------------
        report ">> PREPARANDO C3...";
        pulsar_interno(1, 20);
        wait until safe_to_integer(leds_1) = 20 for 100 us;
        wait for 5 us;

        -- -------------------------------------------------------------------
        -- CENÁRIO 3: Direção (Call 15 DESCER) -> Elev 1 (no 20) vs Elev 0 (no 7)
        -- -------------------------------------------------------------------
        report ">> C3: Direcao (Call 15 Descer)";
        pulsar_externo_descer(15);
        
        wait until safe_to_integer(leds_1) = 15 for 50 us;

        assert safe_to_integer(leds_1) = 15 
            report "FALHA C3: Elev 1 nao desceu" severity error;
        assert safe_to_integer(leds_0) = 7  
            report "FALHA C3: Elev 0 nao devia subir" severity error;
        
        wait for 5 us;

        -- -------------------------------------------------------------------
        -- CENÁRIO 4: Carona (Elev 2: 0 -> 2 -> 30)
        -- -------------------------------------------------------------------
        report ">> C4: Carona (Elev 2 passa no 2 indo pro 30)";
        
        -- Manda Elev 2 para o 30
        pulsar_interno(2, 30);
        wait for 200 ns; -- Pequeno delay para ele começar a processar
        
        -- Alguém chama no 2 (Caminho do Elev 2)
        pulsar_externo_subir(2);

        -- PARTE A: Verifica se ele PARA no 2
        wait until safe_to_integer(leds_2) = 2 for 20 us;
        
        assert safe_to_integer(leds_2) = 2 
            report "FALHA C4: Elev 2 pulou o andar 2!" severity error;
            
        -- Verifica se a porta abriu (confirma que parou para atender e não só passou)
        wait until leds_porta(2) = '1' for 5 us;
        assert leds_porta(2) = '1' report "FALHA C4: Porta nao abriu no 2" severity error;

        report ">> C4: Carona OK! Esperando chegar no 30...";

        -- PARTE B: Verifica se ele CONTINUA até o 30
        wait until safe_to_integer(leds_2) = 30 for 100 us;
        
        assert safe_to_integer(leds_2) = 30 
            report "FALHA C4: Nao completou viagem ao 30" severity error;

        report ">>> SUCESSO TOTAL <<<";
        wait;
    end process;

end architecture;