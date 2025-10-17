library IEEE;
use IEEE.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;


entity Keyboard is
    port (
       botoes_in : in std_logic_vector(31 DOWNTO 0);
       andarAtual_in : in std_logic_vector(4 DOWNTO 0);
       porta_in : in std_logic;
       direcao_in : in std_logic;

       proximoAndar_out : out std_logic_vector(4 DOWNTO 0);
       direcao_out : out std_logic
       
    );
end entity Keyboard;

architecture behavior of Keyboard is 

    CONSTANT ULTIMO_ANDAR : INTEGER := 31;    
    
    begin
        process (botoes_in, andarAtual_in, porta_in, direcao_in)
        VARIABLE ANDAR_ATUAL   : INTEGER := TO_INTEGER(UNSIGNED(andarAtual_in));
        VARIABLE ANDAR_ENCONTRADO : BOOLEAN := FALSE;
        begin
           
        
            if (botoes_in = (others => '0')) then
                proximoAndar_out <= andarAtual_in;
                direcao_out <= direcao_in;
                ANDAR_ENCONTRADO := TRUE;
            end if;

            
            if not ANDAR_ENCONTRADO then
                if direcao_in = '1' then                           -- 1 cima, 0 baixo
                    for i in ANDAR_ATUAL + 1 to ULTIMO_ANDAR loop
                        if botoes_in(i) = '1' then
                            proximoAndar_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, proximoAndar_out'LENGTH));
                            direcao_out <= direcao_in;
                            ANDAR_ENCONTRADO := TRUE;
                            exit;
                        end if;
                    end loop;
                    
                    if not ANDAR_ENCONTRADO then
                        for i in ANDAR_ATUAL - 1 downto 0 loop
                            if botoes_in(i) = '1' then
                                proximoAndar_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, proximoAndar_out'LENGTH));
                                direcao_out <= not direcao_in;
                                ANDAR_ENCONTRADO := TRUE;
                                exit;
                            end if;
                        end loop;
                    end if;

                else 

                    for i in ANDAR_ATUAL - 1 downto 0 loop
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

                        
