library IEEE;
use IEEE.std_logic_1164.all;                    -- por enquanto apenas funciona para 1 elevador e só está implementado para 
                                                -- achar o melhor andar que o elevador deve ir.
use IEEE.NUMERIC_STD.ALL;

use work.Tipos_Elevadores.all;

entity Supervisor_Unico is
    port (
       botoes_in : in std_logic_vector(31 DOWNTO 0);        -- vetor de todos os botões
       andarAtual_in : in std_logic_vector(4 DOWNTO 0);     -- vetor com o dÃ­gito do andar atual
       direcao_in : in std_logic;                           -- direÃ§Ã£o do elevador (0 -> baixo, 1 -> cima)

       proximoAndar_out : out std_logic_vector(4 DOWNTO 0); -- vetor com o dÃ­gito do próximo andar
       direcao_out : out std_logic                          -- direÃ§Ã£o do elevador (pode mudar dependendo do próximo andar)
       
    );
end entity Supervisor_Unico;

architecture Behavioral of Supervisor_Unico is            
    begin
            process (botoes_in, andarAtual_in, direcao_in)
        variable ANDAR_ATUAL     : integer;
        variable ANDAR_PROXIMO   : integer;
        variable ANDAR_ENCONTRADO: boolean;
    begin
        ANDAR_ATUAL := to_integer(unsigned(andarAtual_in));
        ANDAR_ENCONTRADO := false;

        -- Default outputs (evita latch)
        proximoAndar_out <= andarAtual_in;
        direcao_out <= direcao_in;

        -- Verifica se há algum botão pressionado
        if botoes_in /= (others => '0') then
            if direcao_in = '1' then  -- Indo para cima
                ANDAR_PROXIMO := achar_acima(botoes_in, ANDAR_ATUAL);
                if ANDAR_PROXIMO = -1 then
                    ANDAR_PROXIMO := achar_abaixo(botoes_in, ANDAR_ATUAL);
                    if ANDAR_PROXIMO /= -1 then
                        direcao_out <= '0'; -- muda para baixo
                    end if;
                end if;
            else  -- Indo para baixo
                ANDAR_PROXIMO := achar_abaixo(botoes_in, ANDAR_ATUAL);
                if ANDAR_PROXIMO = -1 then
                    ANDAR_PROXIMO := achar_acima(botoes_in, ANDAR_ATUAL);
                    if ANDAR_PROXIMO /= -1 then
                        direcao_out <= '1'; -- muda para cima
                    end if;
                end if;
            end if;

            -- Se encontrou um andar válido, atualiza a saída
            if ANDAR_PROXIMO /= -1 then
                proximoAndar_out <= std_logic_vector(to_unsigned(ANDAR_PROXIMO, proximoAndar_out'length));
            end if;
        end if;
    end process;
end Behavioral;
                        
