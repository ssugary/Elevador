library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.Tipos_Elevadores.all; 

entity Supervisor_Global is
    port (
        -- Pedidos intern os por elevador: vetor de vetores (cada elemento é std_logic_vector[0..ULTIMO_ANDAR])
        botoes_in            : in matriz_botoes(2 DOWNTO 0);

        -- Pedidos externos: botões de subir e descer por andar (0..ULTIMO_ANDAR)
        botoes_subir_in      : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
        botoes_descer_in     : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);

        -- Feedback dos elevadores: andar atual e direção atual (para cada elevador)
        andaresElevadores_in : in matriz_andar(2 DOWNTO 0);
        direcaoElevadores_in : in std_logic_vector(2 DOWNTO 0);

        -- Saídas do escalonador:
        proximoAndar_out     : out std_logic_vector(4 DOWNTO 0); -- o andar que o Supervisor decidiu para]
                                                                 -- o elevador escolhido (5 bits)
        elevadorEscolhido    : out std_logic_vector(1 DOWNTO 0);  -- índice do elevador escolhido (integer 0..2)
        direcao_out          : out std_logic -- direção associada ao pedido (1 = subir, 0 = descer)
    );
end entity;

architecture Behavioral of Supervisor_Global is 

    -- Instancia local do Supervisor_Unico por elevador:
    -- Cada Supervisor_Unico determina, a partir dos pedidos internos daquele elevador,
    -- qual é o próximo andar que esse elevador deveria atender (sem considerar pedidos externos).
    component Supervisor_Unico 
        port(
            botoes_in        : in  std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            andarAtual_in    : in  std_logic_vector(4 DOWNTO 0);
            direcao_in       : in  std_logic;

            proximoAndar_out : out std_logic_vector(4 DOWNTO 0);
            direcao_out      : out std_logic
        );
    end component;

    -- Sinais internos para coletar as decisões locais dos 3 Supervisores_Unico
    signal proximo_andar_interno : matriz_andar(2 DOWNTO 0);  -- próximo andar sugerido por cada supervisor local
    signal direcao_interna       : std_logic_vector(2 DOWNTO 0); -- direção sugerida por cada supervisor local

begin

    -- Instanciação do supervisor local para cada elevador (0,1,2)
    sup0: Supervisor_Unico
        port map (
            botoes_in        => botoes_in(0),
            andarAtual_in    => andaresElevadores_in(0),
            direcao_in       => direcaoElevadores_in(0),
            proximoAndar_out => proximo_andar_interno(0),
            direcao_out      => direcao_interna(0)
        );

    sup1: Supervisor_Unico
        port map (
            botoes_in        => botoes_in(1),
            andarAtual_in    => andaresElevadores_in(1),
            direcao_in       => direcaoElevadores_in(1),
            proximoAndar_out => proximo_andar_interno(1),
            direcao_out      => direcao_interna(1)
        );

    sup2: Supervisor_Unico
        port map (
            botoes_in        => botoes_in(2),
            andarAtual_in    => andaresElevadores_in(2),
            direcao_in       => direcaoElevadores_in(2),
            proximoAndar_out => proximo_andar_interno(2),
            direcao_out      => direcao_interna(2)
        );

    -- Processo combinacional principal do Supervisor_Global.
    -- Faz a escolha do botão alvo (externo) e decide qual elevador atende.
    process(andaresElevadores_in, direcaoElevadores_in, proximo_andar_interno, botoes_subir_in, botoes_descer_in)
        -- Variáveis locais para cálculos (evitam latches e facilitam comparações)
        variable distancias     : vector_integer(0 TO 2); -- distância calculada por elevador
        variable escolhido      : integer := -1;           -- índice do elevador escolhido
        variable botao_alvo     : integer := -1;           -- andar alvo externo (se houver)
        variable direcao_alvo   : std_logic;               -- direção associada ao botao_alvo
        variable tmp_dist       : integer;                 -- distância temporária para comparação
        variable andar_atual    : integer;                 -- conversão do andar atual para inteiro
    begin
        -- Defaults iniciais (garante saídas válidas se nada for encontrado)
        elevadorEscolhido <= (others => '1');
        proximoAndar_out <= andaresElevadores_in(0);
        direcao_out <= direcaoElevadores_in(0);

        -- -------------------------
        -- 1) Identificar pedido externo (prioridade para botões "subir")
        -- -------------------------
        -- achar_acima(botoes_subir_in, 0) retorna o menor andar > 0 que tenha botão subir
        botao_alvo := achar_acima(botoes_subir_in, 0);
        direcao_alvo := '1'; -- direção target = subir
        if botao_alvo = -1 then
            -- se não encontrou "subir", procura um botão "descer" (começando do topo)
            botao_alvo := achar_abaixo(botoes_descer_in, ULTIMO_ANDAR);
            direcao_alvo := '0'; -- direção target = descer
        end if;

        -- -------------------------
        -- 2) Se não há botões externos, usa pedidos internos (decisão local dos Supervisores_Unico)
        -- -------------------------
        if botao_alvo = -1 then
            -- Escolhe o elevador cujo próximo andar sugerido (proximo_andar_interno) esteja mais próximo do seu andar atual.
            -- Inicializa escolhido com o elevador 0 como referência
            escolhido := 0;
            tmp_dist := modulo_int(to_integer(unsigned(proximo_andar_interno(0))) - to_integer(unsigned(andaresElevadores_in(0))));
            -- percorre os outros elevadores (1..2) e escolhe o menor "dist"
            for i in 1 to 2 loop
                distancias(i) := modulo_int(to_integer(unsigned(proximo_andar_interno(i))) - to_integer(unsigned(andaresElevadores_in(i))));
                if distancias(i) < tmp_dist then
                    tmp_dist := distancias(i);
                    escolhido := i;
                end if;
            end loop;

            -- Define as saídas com base no escolhido
            if escolhido >= 0 and escolhido <= 2 then
                elevadorEscolhido <= std_logic_vector(to_unsigned(escolhido, elevadorEscolhido'length));
                proximoAndar_out <= proximo_andar_interno(escolhido);
                direcao_out <= direcao_interna(escolhido);
            else
                elevadorEscolhido <= (others => '1');
            end if;
        else
            -- -------------------------
            -- 3) Há um botão externo: escolha do elevador que atenderá esse botão
            --    - Primeiro tenta encontrar elevador na mesma direção e mais próximo
            --    - Se não houver nenhum na mesma direção, escolhe o elevador mais próximo de qualquer direção
            -- -------------------------
            escolhido := -1;
            tmp_dist := ULTIMO_ANDAR * 2; -- valor grande inicial para comparação

            -- Primeiro passe: considerar apenas elevadores que já estejam na mesma direção (ou que já estejam no andar alvo)
            for i in 0 TO 2 loop
                andar_atual := to_integer(unsigned(andaresElevadores_in(i)));
                -- Se elevador já está indo na direção desejada OU já está no andar do pedido, considerar como candidato
                if (direcaoElevadores_in(i) = direcao_alvo) or (andar_atual = botao_alvo) then
                    distancias(i) := modulo_int(botao_alvo - andar_atual);
                    if distancias(i) < tmp_dist then
                        tmp_dist := distancias(i);
                        escolhido := i; -- marca candidato mais próximo
                    end if;
                end if;
            end loop;

            -- Se não encontrou nenhum elevador na mesma direção, escolhe o mais próximo independentemente da direção
            if escolhido = -1 then
                tmp_dist := ULTIMO_ANDAR * 2;
                for i in 0 TO 2 loop
                    distancias(i) := modulo_int(botao_alvo - to_integer(unsigned(andaresElevadores_in(i))));
                    if distancias(i) < tmp_dist then
                        tmp_dist := distancias(i);
                        escolhido := i;
                    end if;
                end loop;
            end if;
            
            -- Atualiza saídas com a escolha feita
            if escolhido >= 0 and escolhido <= 2 then
                elevadorEscolhido <= std_logic_vector(to_unsigned(escolhido, elevadorEscolhido'length));
                proximoAndar_out <= std_logic_vector(to_unsigned(botao_alvo, proximoAndar_out'length));
                direcao_out <= direcao_alvo;
            else
                elevadorEscolhido <= (others => '1');
            end if;
        end if;
    end process;
end Behavioral;