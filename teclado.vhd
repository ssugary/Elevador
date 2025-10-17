library IEEE;
use IEEE.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;


entity Keyboard is
    port (
       botoes_in : in std_logic_vector(31 DOWNTO 0);        -- vetor de todos os botões
       andarAtual_in : in std_logic_vector(4 DOWNTO 0);     -- vetor com o dígito do andar atual
       direcao_in : in std_logic;                           -- direção do elevador (0 -> baixo, 1 -> cima)

       proximoAndar_out : out std_logic_vector(4 DOWNTO 0); -- vetor com o dígito do próximo andar
       direcao_out : out std_logic                          -- direção do elevador (pode mudar dependendo do próximo andar)
       
    );
end entity Keyboard;

architecture behavior of Keyboard is 

    CONSTANT ULTIMO_ANDAR : INTEGER := 31;     
    
    begin
        process (botoes_in, andarAtual_in, direcao_in)
        VARIABLE ANDAR_ATUAL   : INTEGER := TO_INTEGER(UNSIGNED(andarAtual_in)); -- Transformação do vetor em inteiro
        VARIABLE ANDAR_ENCONTRADO : BOOLEAN := TRUE;                            -- Booleano que verifica se temos algum andar para ir
        begin
           
        
            if (botoes_in = (others => '0')) then           -- Verifica se algum botão foi apertado
                proximoAndar_out <= andarAtual_in;          -- se não, define o próximo andar como o atual 
                direcao_out <= direcao_in;                   
                ANDAR_ENCONTRADO := FALSE;
            end if;


            if ANDAR_ENCONTRADO then                               -- Se achou alguém, vai verificar com base na direção
                if direcao_in = '1' then                           -- Caso a direção for para cima, vai conferir cada andar acima
                    for i in ANDAR_ATUAL + 1 to ULTIMO_ANDAR loop
                        if botoes_in(i) = '1' then
                            proximoAndar_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, proximoAndar_out'LENGTH));
                            direcao_out <= direcao_in;
                            ANDAR_ENCONTRADO := TRUE;
                            exit;                               -- Define que o retorno vai ser o primeiro andar encontrado e break
                        end if;         
                    end loop;
                    
                    if not ANDAR_ENCONTRADO then                -- Caso não ache nada acima, verifica todos os abaixo
                        for i in ANDAR_ATUAL - 1 downto 0 loop
                            if botoes_in(i) = '1' then
                                proximoAndar_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, proximoAndar_out'LENGTH));
                                direcao_out <= not direcao_in;
                                ANDAR_ENCONTRADO := TRUE;       -- Caso ache, troca a direção e define que o retorno vai ser o primeiro
                                                                -- encontrado.
                                exit;                           
                            end if;
                        end loop;
                    end if;

                else 

                    for i in ANDAR_ATUAL - 1 downto 0 loop      -- similar a lógica do último, mas faz o contrário
                        if botoes_in(i) = '1' then              
                            proximoAndar_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, proximoAndar_out'LENGTH));
                            direcao_out <= direcao_in;
                            ANDAR_ENCONTRADO := TRUE;
                            exit;
                        end if;
                    end loop;

                    if not ANDAR_ENCONTRADO then
                        for i in ANDAR_ATUAL + 1 to ULTIMO_ANDAR loop
                            if botoes_in(i) = '1' then 
                                proximoAndar_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, proximoAndar_out'LENGTH));
                                direcao_out <= not direcao_in;
                                ANDAR_ENCONTRADO := TRUE;
                                exit;
                            end if;
                        end loop;
                    end if;
            end if;
        end if;
    end process;
end behavior;

                        
