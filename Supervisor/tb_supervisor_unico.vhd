library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.Tipos_Elevadores.all; 

entity tb_Supervisor_Unico is
end entity tb_Supervisor_Unico;

architecture Teste of tb_Supervisor_Unico is
    constant ADDRESS_WIDTH : integer := 5; -- 5 bits de andar
    
    component Supervisor_Unico -- Declaração do componente de teste
        port (
            botoes_in      : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            andarAtual_in  : in std_logic_vector(ADDRESS_WIDTH - 1 DOWNTO 0);
            direcao_in     : in std_logic;
            proximoAndar_out : out std_logic_vector(ADDRESS_WIDTH - 1 DOWNTO 0);
            direcao_out      : out std_logic
        );
    end component Supervisor_Unico;

    -- Delcarando sinais DUT / Entradas e saídas
    signal s_botoes_in      : std_logic_vector(ULTIMO_ANDAR DOWNTO 0) := (others => '0');
    signal s_andarAtual_in  : std_logic_vector(ADDRESS_WIDTH - 1 DOWNTO 0) := (others => '0');
    signal s_direcao_in     : std_logic := '0';
    signal s_proximoAndar_out : std_logic_vector(ADDRESS_WIDTH - 1 DOWNTO 0);
    signal s_direcao_out      : std_logic;

    -- Função que converte inteiro para bits
    function to_slv5 (
        I : integer
    ) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(I, ADDRESS_WIDTH)); 
    end function to_slv5;

begin
    -- Instancianciando DUT / Entradas e saídas
    DUT : Supervisor_Unico
        port map (
            botoes_in      => s_botoes_in,
            andarAtual_in  => s_andarAtual_in,
            direcao_in     => s_direcao_in,
            proximoAndar_out => s_proximoAndar_out,
            direcao_out      => s_direcao_out
        );

    -- Estímulo
    stimulus_proc : process
    begin
        report "Testando!" severity note;

        -- Inicialização padrão
        s_andarAtual_in <= to_slv5(0);
        s_direcao_in <= '1'; 
        s_botoes_in <= (others => '0');
        wait for 10 ns;

        -- Teste de diferentes cenários para análise:
        -- Subindo, com chamados acima. ---
        report "Teste 1: Subindo, com chamados acima" severity note;
        s_andarAtual_in <= to_slv5(10);
        s_direcao_in <= '1';
        s_botoes_in(12) <= '1';
        s_botoes_in(20) <= '1';
        s_botoes_in(5)  <= '1'; -- Chamado abaixo
        wait for 10 ns; 
        -- Próximo andar precisa ser o 12
        -- Direção 1 

        -- Chegou ao 12 e vai subir ---
        report "Teste 2: Chegou ao 12" severity note;
        s_andarAtual_in <= to_slv5(12);
        s_botoes_in(12) <= '0'; -- Botão 12 
        wait for 10 ns;
        -- Direção 1

        -- No topo, precisa inverter e ir para o 5. ---
        report "Teste 3: Inversão de Sentido (para baixo)" severity note;
        s_andarAtual_in <= to_slv5(ULTIMO_ANDAR); -- Andar 31
        s_botoes_in(20) <= '0'; -- Botão 20 atendido (simulado)
        s_botoes_in(5)  <= '1'; -- O único chamado restante
        s_direcao_in <= '1'; -- Direção atual CIMA
        wait for 10 ns;
        -- Próximo andar é o 5. 
        -- Direção 0

        -- Descendo, com chamados abaixo e um acima. 
        report "Teste 4: Descendo (prioridade: chamados abaixo)" severity note;
        s_andarAtual_in <= to_slv5(15);
        s_direcao_in <= '0';
        s_botoes_in(8)  <= '1'; -- Chamado abaixo
        s_botoes_in(2)  <= '1'; -- Chamado mais abaixo
        s_botoes_in(30) <= '1'; -- Chamado acima (deve ser ignorado por enquanto)
        wait for 10 ns;
        -- Próximo andar é o 8
        -- Direção 0

        -- Inverteu novamente, porém, agora. Para cima
        report "Teste 5: Inversão de Sentido (para cima)" severity note;
        s_andarAtual_in <= to_slv5(2);
        s_botoes_in(8)  <= '0';
        s_botoes_in(2)  <= '0'; -- Botões 8 e 2 atendidos
        -- Nessa simulação, apenas resta atender ao andar 30. 
        wait for 10 ns;

        -- Acabaram os chamados:
        report "Teste 6: Sem chamados" severity note;
        s_andarAtual_in <= to_slv5(30);
        s_botoes_in(30) <= '0';
        s_direcao_in <= '1'; -- Direção atual = cima
        wait for 10 ns;

        report "Testbench Finalizado." severity note;
        wait; 
    end process stimulus_proc;

end architecture Teste;