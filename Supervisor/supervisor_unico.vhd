library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use work.Tipos_Elevadores.all;

entity Supervisor_Unico is
    port (
       botoes_in        : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
       andarAtual_in    : in std_logic_vector(4 DOWNTO 0);
       
       -- MUDANÇA AQUI: Tipos fortes
       direcao_in       : in t_direcao; 
       proximoAndar_out : out std_logic_vector(4 DOWNTO 0);
       direcao_out      : out t_direcao
    );
end entity Supervisor_Unico;

architecture Behavioral of Supervisor_Unico is            
begin
    process (botoes_in, andarAtual_in, direcao_in)
        variable ANDAR_ATUAL   : integer;
        variable ANDAR_PROXIMO : integer;
    begin
        ANDAR_ATUAL := safe_to_integer(andarAtual_in);
        
        -- Configuração Padrão: fica onde está e parado
        proximoAndar_out <= andarAtual_in;
        direcao_out      <= PARADO;
        
        -- Lógica de Varredura (SCAN)
        if direcao_in = DESCENDO then
            -- Se estava descendo, prioridade é continuar descendo
            ANDAR_PROXIMO := achar_abaixo(botoes_in, ANDAR_ATUAL);
            if ANDAR_PROXIMO /= -1 then
                proximoAndar_out <= safe_to_vector(ANDAR_PROXIMO, 5);
                direcao_out      <= DESCENDO;
            else
                -- Se não tem nada em baixo, procura em cima
                ANDAR_PROXIMO := achar_acima(botoes_in, ANDAR_ATUAL);
                if ANDAR_PROXIMO /= -1 then
                    proximoAndar_out <= safe_to_vector(ANDAR_PROXIMO, 5);
                    direcao_out      <= SUBINDO;
                else
                    -- Sem pedidos
                    direcao_out <= PARADO;
                end if;
            end if;
            
        else 
            -- Se estava SUBINDO ou PARADO, prioridade é buscar acima
            ANDAR_PROXIMO := achar_acima(botoes_in, ANDAR_ATUAL);
            if ANDAR_PROXIMO /= -1 then
                proximoAndar_out <= safe_to_vector(ANDAR_PROXIMO, 5);
                direcao_out      <= SUBINDO;
            else
                -- Se não tem nada em cima, procura em baixo
                ANDAR_PROXIMO := achar_abaixo(botoes_in, ANDAR_ATUAL);
                if ANDAR_PROXIMO /= -1 then
                    proximoAndar_out <= safe_to_vector(ANDAR_PROXIMO, 5);
                    direcao_out      <= DESCENDO;
                else
                    direcao_out <= PARADO;
                end if;
            end if;
        end if;
    end process;
end architecture;