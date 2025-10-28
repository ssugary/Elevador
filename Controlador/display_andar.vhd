library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;  -- Necessário para unsigned/integer/conversion

entity Led_7Segmentos_Andar is
    Port (
        entrada            : in  std_logic_vector(4 downto 0); -- Vetor de entrada do andar atual (em bits)
                                                    -- Talvez seja até melhor colocar como entrada o número em inteiro mesmo mas eu não sei se pode fazer isso pois não manjo de VHDL
        segmentos_dezenas  : out std_logic_vector(6 downto 0); -- Saída do primero led (Dezenas)
        segmentos_unidades : out std_logic_vector(6 downto 0)  -- Saída do segundo led (Unidades)
    );
end entity Led_7Segmentos_Andar;

architecture Behavioral of Led_7Segmentos_Andar is

    -- Declaração de sinais inteiros. Vamos transformar os bits em decimais.
    signal valor_decimal   : integer range 0 to 31; 
    signal digito_dezenas  : integer range 0 to 3; 
    signal digito_unidades : integer range 0 to 9;
                                                    
begin


    -- Atribuindo valores para os sinais e dividindo o número em dezena e unidade para trabalhar separadamente
    valor_decimal <= to_integer(unsigned(entrada)); -- Valor_decimal = sinal que é a conversão da entrada para inteiro
    digito_dezenas  <= valor_decimal / 10;          -- Valor_dezenas = sinal que é o resto da divisão do valor decimal
    digito_unidades <= valor_decimal mod 10;        -- Valor_unidades = módulo do valor decimal
    
    -- Led Dezena
    with digito_dezenas select 
        segmentos_dezenas <= 
        --  [Saída do LED] when [Entrada]
            "0000000" when 0,  -- Andares 0 a 9
            "0110000" when 1,  -- Andares 10 a 19
            "1101101" when 2,  -- Andares 20 a 29
            "1001111" when 3,  -- Andares 30 e 31
            "1111111" when others; 

    -- Led Unidade
    with digito_unidades select 
        segmentos_unidades <= 
        --  [Saída do LED] when [Entrada]
            "1111110" when 0, 
            "0110000" when 1, 
            "1101101" when 2,
            "1111001" when 3, 
            "0110011" when 4, 
            "1011011" when 5, 
            "1011111" when 6, 
            "1110000" when 7, 
            "1111111" when 8, 
            "1111011" when 9, 
            "0000000" when others; 

end architecture Behavioral;
