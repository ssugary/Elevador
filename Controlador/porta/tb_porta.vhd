library ieee;
use ieee.std_logic_1164.all;

entity tb_porta_elevador is
end entity tb_porta_elevador;

architecture testbench of tb_porta_elevador is

    -- Define o componente
    component porta is
        generic (
            G_MAX_COUNT : integer := 100_000_000
        );
        port (
            clk         : in std_logic;
            reset       : in std_logic;
            start_close : in std_logic;
            start_open  : in std_logic;
            door_closed : out std_logic;
            door_open   : out std_logic
        );
    end component;

    -- sinais de entrada
    signal s_clk         : std_logic := '0';
    signal s_reset       : std_logic;
    signal s_start_close : std_logic;
    signal s_start_open  : std_logic;
    -- sinais de saida
    signal s_door_closed : std_logic;
    signal s_door_open   : std_logic;

    -- testa somente com 100 ciclos que configuram 2 microsegundos
    -- (testando com 100 mil ciclos que seriam os 2 segundos reais estava muito pesado)
    constant CLK_PERIOD  : time := 20 ns;
    constant TEST_CYCLES : integer := 100;
    constant SIM_DELAY   : time := TEST_CYCLES * CLK_PERIOD; 

begin

    UUT : porta
        generic map (
            G_MAX_COUNT => TEST_CYCLES 
        )
        port map (
            clk         => s_clk,
            reset       => s_reset,
            start_close => s_start_close,
            start_open  => s_start_open,  
            door_closed => s_door_closed,
            door_open   => s_door_open    
        );

    -- Inicia o processo do clock que será usado em todo o TB
    processo_clk : process
    begin
        s_clk <= '0';
        wait for CLK_PERIOD / 2;
        s_clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    processo_estimulo : process
    begin
        report "Iniciando Testbench (com ciclo de abertura)...";
        s_reset       <= '1';
        s_start_close <= '0';
        s_start_open  <= '0';
        wait for 5 * CLK_PERIOD;

        -- Teste 1: verfica se o reset muda o estado inicial pra ABERTA
        assert (s_door_closed = '0' and s_door_open = '1')
            report "Falha no Teste 1: Estado inicial incorreto apos reset."
            severity error;

        s_reset <= '0';
        wait for 5 * CLK_PERIOD;

        -- Teste 2: verifica se ao mudar o reset pra 0 o estado ainda continua ABERTO
        assert (s_door_closed = '0' and s_door_open = '1')
            report "Falha no Teste 2: Nao permaneceu em ABERTA."
            severity error;

        report "Iniciando fechamento...";
        s_start_close <= '1';
        wait for CLK_PERIOD;
        s_start_close <= '0';
        
        wait for CLK_PERIOD; 
        
        -- Teste 3: Verifica se se está enviando as saídas corretas ao entrar no estado FECHANDO
        -- (Ele não pode mandar o sinal de porta aberta ou fechada até realmente estar nesse estado)
        assert (s_door_closed = '0' and s_door_open = '0')
            report "Falha no Teste 3: Saidas incorretas ao iniciar FECHANDO."
            severity error;

        wait for SIM_DELAY - (2 * CLK_PERIOD);
        
        -- Teste 4: Verifica se ele está esperando todo o tempo esperado antes de fechar a porta
        assert (s_door_closed = '0' and s_door_open = '0')
            report "Falha no Teste 4: Porta fechou cedo demais."
            severity error;
            
        wait for 3 * CLK_PERIOD; 
        
        -- Teste 5: Verifica se depois do tempo esperado ele realmente chega ao estado FECHADA
        assert (s_door_closed = '1' and s_door_open = '0')
            report "Falha no Teste 5: Nao chegou ao estado FECHADA."
            severity error;

        report "Iniciando abertura...";
        wait for 10 * CLK_PERIOD; 
        
        s_start_open <= '1';
        wait for CLK_PERIOD;
        s_start_open <= '0';
        
        wait for CLK_PERIOD; 
        
        -- Teste 6: Verificação análoga ao Teste 3, mas para o estado ABRINDO
        assert (s_door_closed = '0' and s_door_open = '0')
            report "Falha no Teste 6: Saidas incorretas ao iniciar ABRINDO."
            severity error;

        wait for SIM_DELAY - (2 * CLK_PERIOD);
        
        -- Teste 7: Verificação análoga ao teste 4, mas para o estado ABERTA
        assert (s_door_closed = '0' and s_door_open = '0')
            report "Falha no Teste 7: Porta abriu cedo demais."
            severity error;
            
        wait for 3 * CLK_PERIOD; 
        
        -- Teste 8: Verificação análoga ao teste 5, mas para o estado ABERTA
        assert (s_door_closed = '0' and s_door_open = '1')
            report "Falha no Teste 8: Nao chegou ao estado ABERTA."
            severity error;

        report "Testbench finalizado com sucesso.";
        
        wait; 
        
    end process;

end architecture testbench;
