library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 

entity Led_7Segmentos_Andar_tb is -- Entidade do Testbench
end entity Led_7Segmentos_Andar_tb;

architecture Teste of Led_7Segmentos_Andar_tb is

    component Led_7Segmentos_Andar --Declaração
        Port (
            entrada            : in  std_logic_vector(4 downto 0);
            segmentos_dezenas  : out std_logic_vector(6 downto 0);
            segmentos_unidades : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Sinais para conectar no componente
    signal tb_entrada            : std_logic_vector(4 downto 0) := (others => '0'); -- Inicializado em 0
    signal tb_segmentos_dezenas  : std_logic_vector(6 downto 0);
    signal tb_segmentos_unidades : std_logic_vector(6 downto 0);

    
    constant C_TEMPO_TESTE : time := 10 ns; --Clock para delay de teste

begin

    DUT : Led_7Segmentos_Andar --Instanciação
    port map (
        entrada            => tb_entrada,
        segmentos_dezenas  => tb_segmentos_dezenas,
        segmentos_unidades => tb_segmentos_unidades
    );

    stimulus_process: process -- Estímulos
    begin
        -- Valores de teste
        -- Andar 0
        tb_entrada <= std_logic_vector(to_unsigned(0, tb_entrada'length));
        wait for C_TEMPO_TESTE;

        -- Andar 1
        tb_entrada <= std_logic_vector(to_unsigned(1, tb_entrada'length));
        wait for C_TEMPO_TESTE;
        
        -- Andar 10
        tb_entrada <= std_logic_vector(to_unsigned(10, tb_entrada'length));
        wait for C_TEMPO_TESTE;

        -- Andar 25
        tb_entrada <= std_logic_vector(to_unsigned(25, tb_entrada'length));
        wait for C_TEMPO_TESTE;

        -- Andar 31
        tb_entrada <= std_logic_vector(to_unsigned(31, tb_entrada'length));
        wait for C_TEMPO_TESTE;
        
        wait; 

    end process stimulus_process;

end architecture Teste;