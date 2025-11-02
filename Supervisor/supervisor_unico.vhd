library IEEE;
use IEEE.std_logic_1164.all;                    -- por enquanto apenas funciona para 1 elevador e só está implementado para 
                                                -- achar o melhor andar que o elevador deve ir.
use IEEE.NUMERIC_STD.ALL;
use work.Tipos_Elevadores.all;


entity Supervisor_Unico is
    port (
       botoes_in        : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);        -- vetor com os botões (0..ULTIMO_ANDAR)
       andarAtual_in    : in std_logic_vector(4 DOWNTO 0);                  -- andar atual (binário 5 bits)
       direcao_in       : in std_logic;                                    -- direção atual ('0' = baixo, '1' = cima)

       proximoAndar_out : out std_logic_vector(4 DOWNTO 0);                 -- próximo andar escolhido
       direcao_out      : out std_logic                                     -- próxima direção a seguir
    );
end entity Supervisor_Unico;

architecture Behavioral of Supervisor_Unico is            
begin
    -- Processo combinacional sensível às entradas relevantes.
    -- Calcula proximoAndar_out e direcao_out sem usar registros (pure combinational logic).
    process (botoes_in, andarAtual_in, direcao_in)
        -- Variáveis locais para facilitar cálculos inteiros
        variable ANDAR_ATUAL     : integer;
        variable ANDAR_PROXIMO   : integer;
        variable ANDAR_ENCONTRADO: boolean;
        -- Constante para comparar rapidamente se o vetor de botões está vazio
        constant VETOR_ZERO : std_logic_vector(ULTIMO_ANDAR DOWNTO 0) := (others => '0');
    begin
        -- Converte a posição atual para inteiro (0..ULTIMO_ANDAR)
        ANDAR_ATUAL := safe_to_integer(andarAtual_in);
        ANDAR_ENCONTRADO := false;

        -- Defaults: evita criação de latches e garante valores caso nenhuma condição seja atendida.
        -- Por padrão, mantém o próximo andar igual ao atual e mantém a direção atual.
        proximoAndar_out <= andarAtual_in;
        direcao_out <= direcao_in;

        -- Se não houver nenhum botão pressionado, mantém defaults e sai.
        if botoes_in /= VETOR_ZERO then

            -- Se a direção atual é "subindo" ('1'), procura primeiro acima
            if direcao_in = '1' then  -- Indo para cima
                -- achar_acima: retorna o menor andar > ANDAR_ATUAL com botoes(i) = '1', ou -1 se não houver
                ANDAR_PROXIMO := achar_acima(botoes_in, ANDAR_ATUAL);
                if ANDAR_PROXIMO = -1 then
                    -- Se não encontrou acima, procura abaixo (prioridade invertida)
                    ANDAR_PROXIMO := achar_abaixo(botoes_in, ANDAR_ATUAL);
                    if ANDAR_PROXIMO /= -1 then
                        -- Se encontrou um abaixo, indica que a nova direção será "descer"
                        direcao_out <= '0'; -- muda para baixo
                    end if;
                end if;

            else  -- Se a direção atual é "descendo" ('0'), procura primeiro abaixo
                ANDAR_PROXIMO := achar_abaixo(botoes_in, ANDAR_ATUAL);
                if ANDAR_PROXIMO = -1 then
                    -- Se não encontrou abaixo, procura acima e muda direção se achar
                    ANDAR_PROXIMO := achar_acima(botoes_in, ANDAR_ATUAL);
                    if ANDAR_PROXIMO /= -1 then
                        direcao_out <= '1'; -- muda para cima
                    end if;
                end if;
            end if;

            -- Se encontrou um andar válido (retorno diferente de -1), atualiza a saída proximoAndar_out.
            -- Converte o inteiro para std_logic_vector com a largura apropriada (5 bits).
            if ANDAR_PROXIMO /= -1 then
                proximoAndar_out <= safe_to_vector(ANDAR_PROXIMO, proximoAndar_out'length);
            end if;
        end if;
    end process;
end Behavioral;