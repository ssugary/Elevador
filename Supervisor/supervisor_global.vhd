library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Tipos_Elevadores.all;

entity Supervisor_Global is
    port (
        -- Entradas de Dados
        botoes_in            : in matriz_botoes(2 DOWNTO 0);
        botoes_subir_in      : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
        botoes_descer_in     : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
        
        andaresElevadores_in : in matriz_andar(2 DOWNTO 0);
        
        -- MUDANÇA: Recebe vetor de tipos t_direcao
        direcaoElevadores_in : in vetor_direcao(2 DOWNTO 0); 

        -- Saídas
        proximoAndar_out     : out matriz_andar(2 DOWNTO 0);
        
        -- MUDANÇA: Envia vetor de tipos t_direcao
        direcao_req_out      : out vetor_direcao(2 DOWNTO 0)
    );
end entity;

architecture Behavioral of Supervisor_Global is 

    component Supervisor_Unico 
        port(
            botoes_in        : in  std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            andarAtual_in    : in  std_logic_vector(4 DOWNTO 0);
            direcao_in       : in  t_direcao;
            proximoAndar_out : out std_logic_vector(4 DOWNTO 0);
            direcao_out      : out t_direcao
        );
    end component;

    signal sugestao_andar_local : matriz_andar(2 DOWNTO 0);
    signal sugestao_dir_local   : vetor_direcao(2 DOWNTO 0);

begin

    -- Instanciação (Ajuste automático pelos tipos definidos no pacote)
    sup0: Supervisor_Unico port map (
        botoes_in => botoes_in(0), andarAtual_in => andaresElevadores_in(0), direcao_in => direcaoElevadores_in(0),
        proximoAndar_out => sugestao_andar_local(0), direcao_out => sugestao_dir_local(0));

    sup1: Supervisor_Unico port map (
        botoes_in => botoes_in(1), andarAtual_in => andaresElevadores_in(1), direcao_in => direcaoElevadores_in(1),
        proximoAndar_out => sugestao_andar_local(1), direcao_out => sugestao_dir_local(1));

    sup2: Supervisor_Unico port map (
        botoes_in => botoes_in(2), andarAtual_in => andaresElevadores_in(2), direcao_in => direcaoElevadores_in(2),
        proximoAndar_out => sugestao_andar_local(2), direcao_out => sugestao_dir_local(2));


    -- LÓGICA CENTRAL
    process(botoes_subir_in, botoes_descer_in, andaresElevadores_in, direcaoElevadores_in, sugestao_andar_local, sugestao_dir_local)
        
        variable andar_chamada_ext : integer;
        variable dir_chamada_ext   : t_direcao; -- Agora é do tipo t_direcao
        variable custo_atual, menor_custo, vencedor : integer;
        variable dist_simples, andar_elev_int : integer;
        
        constant PENALIDADE : integer := 50; 

    begin
        -- 1. Default: Segue o supervisor local
        proximoAndar_out <= sugestao_andar_local;
        direcao_req_out  <= sugestao_dir_local;
        
        vencedor := -1;
        andar_chamada_ext := -1;
        dir_chamada_ext := PARADO;

        -- 2. Varredura de Chamadas (Prioridade Subir)
        andar_chamada_ext := achar_acima(botoes_subir_in, -1);
        if andar_chamada_ext /= -1 then
            dir_chamada_ext := SUBINDO;
        else
            andar_chamada_ext := achar_abaixo(botoes_descer_in, ULTIMO_ANDAR + 1);
            if andar_chamada_ext /= -1 then
                dir_chamada_ext := DESCENDO;
            end if;
        end if;

        -- 3. Cálculo de Custo com t_direcao
        if andar_chamada_ext /= -1 then
            menor_custo := 1000;
            
            for i in 0 to 2 loop
                andar_elev_int := safe_to_integer(andaresElevadores_in(i));
                dist_simples   := modulo_int(andar_elev_int - andar_chamada_ext);
                custo_atual    := dist_simples;

                -- O Grande Trunfo do t_direcao: Cases explícitos
                case direcaoElevadores_in(i) is
                    
                    when PARADO =>
                        -- Elevador livre é o melhor candidato (custo puro = distância)
                        custo_atual := dist_simples;

                    when SUBINDO =>
                        if dir_chamada_ext = DESCENDO then
                            custo_atual := custo_atual + PENALIDADE; -- Contramão
                        elsif andar_elev_int > andar_chamada_ext then
                            custo_atual := custo_atual + PENALIDADE; -- Já passou subindo
                        end if;

                    when DESCENDO =>
                        if dir_chamada_ext = SUBINDO then
                            custo_atual := custo_atual + PENALIDADE; -- Contramão
                        elsif andar_elev_int < andar_chamada_ext then
                            custo_atual := custo_atual + PENALIDADE; -- Já passou descendo
                        end if;

                end case;

                if custo_atual < menor_custo then
                    menor_custo := custo_atual;
                    vencedor := i;
                end if;
            end loop;

            -- 4. Aplica ao Vencedor
            if vencedor /= -1 then
                proximoAndar_out(vencedor) <= safe_to_vector(andar_chamada_ext, 5);
                
                -- Define a direção física necessária
                if safe_to_integer(andaresElevadores_in(vencedor)) < andar_chamada_ext then
                    direcao_req_out(vencedor) <= SUBINDO;
                elsif safe_to_integer(andaresElevadores_in(vencedor)) > andar_chamada_ext then
                    direcao_req_out(vencedor) <= DESCENDO;
                else
                    direcao_req_out(vencedor) <= PARADO; -- (Raro, mas possível)
                end if;
            end if;
        end if;
    end process;
end Behavioral;