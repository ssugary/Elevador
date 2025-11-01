library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.Tipos_Elevadores.all; 

entity Supervisor_Global is
    port (
        -- Pedidos intern os por elevador: vetor de vetores (cada elemento � std_logic_vector[0..ULTIMO_ANDAR])
        botoes_in            : in matriz_botoes(2 DOWNTO 0);

        -- Pedidos externos: bot�es de subir e descer por andar (0..ULTIMO_ANDAR)
        botoes_subir_in      : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
        botoes_descer_in     : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);

        -- Feedback dos elevadores: andar atual e dire��o atual (para cada elevador)
        andaresElevadores_in : in matriz_andar(2 DOWNTO 0);
        direcaoElevadores_in : in std_logic_vector(2 DOWNTO 0);

        -- Sa�das do escalonador:
        proximoAndar_out     : out std_logic_vector(4 DOWNTO 0); -- o andar que o Supervisor decidiu para]
                                                                 -- o elevador escolhido (5 bits)
        elevadorEscolhido    : out std_logic_vector(1 DOWNTO 0);  -- �ndice do elevador escolhido (integer 0..2)
        direcao_out          : out std_logic -- dire��o associada ao pedido (1 = subir, 0 = descer)
    );
end entity;

architecture Behavioral of Supervisor_Global is 

    -- Instancia local do Supervisor_Unico por elevador:
    -- Cada Supervisor_Unico determina, a partir dos pedidos internos daquele elevador,
    -- qual � o pr�ximo andar que esse elevador deveria atender (sem considerar pedidos externos).
    component Supervisor_Unico 
        port(
            botoes_in        : in  std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            andarAtual_in    : in  std_logic_vector(4 DOWNTO 0);
            direcao_in       : in  std_logic;

            proximoAndar_out : out std_logic_vector(4 DOWNTO 0);
            direcao_out      : out std_logic
        );
    end component;

    -- Sinais internos para coletar as decis�es locais dos 3 Supervisores_Unico
    signal proximo_andar_interno : matriz_andar(2 DOWNTO 0);  -- pr�ximo andar sugerido por cada supervisor local
    signal direcao_interna       : std_logic_vector(2 DOWNTO 0); -- dire��o sugerida por cada supervisor local

begin

    -- Instancia��o do supervisor local para cada elevador (0,1,2)
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
    -- Faz a escolha do bot�o alvo (externo) e decide qual elevador atende.
    process(andaresElevadores_in, direcaoElevadores_in, proximo_andar_interno, botoes_subir_in, botoes_descer_in)
        -- Vari�veis locais para c�lculos (evitam latches e facilitam compara��es)
        variable distancias     : vector_integer(0 TO 2); -- dist�ncia calculada por elevador
        variable escolhido      : integer := -1;           -- �ndice do elevador escolhido
        variable botao_alvo     : integer := -1;           -- andar alvo externo (se houver)
        variable direcao_alvo   : std_logic;               -- dire��o associada ao botao_alvo
        variable tmp_dist       : integer;                 -- dist�ncia tempor�ria para compara��o
        variable andar_atual    : integer;                 -- convers�o do andar atual para inteiro
    begin
        -- Defaults iniciais (garante sa�das v�lidas se nada for encontrado)
        elevadorEscolhido <= (others => '1');
        proximoAndar_out <= andaresElevadores_in(0);
        direcao_out <= direcaoElevadores_in(0);

        -- 1) Identificar pedido externo (prioridade para bot�es "subir")
        -- achar_acima(botoes_subir_in, 0) retorna o menor andar > 0 que tenha bot�o subir
        botao_alvo := achar_acima(botoes_subir_in, 0);
        direcao_alvo := '1'; -- dire��o target = subir
        if botao_alvo = -1 then
            -- se n�o encontrou "subir", procura um bot�o "descer" (come�ando do topo)
            botao_alvo := achar_abaixo(botoes_descer_in, ULTIMO_ANDAR);
            direcao_alvo := '0'; -- dire��o target = descer
        end if;

        -- 2) Se n�o h� bot�es externos, usa pedidos internos (decis�o local dos Supervisores_Unico)
        if botao_alvo = -1 then
            -- Escolhe o elevador cujo pr�ximo andar sugerido (proximo_andar_interno) esteja mais pr�ximo do seu andar atual.
            -- Inicializa escolhido com o elevador 0 como refer�ncia
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

            -- Define as sa�das com base no escolhido
            if escolhido >= 0 and escolhido <= 2 then
                elevadorEscolhido <= std_logic_vector(to_unsigned(escolhido, elevadorEscolhido'length));
                proximoAndar_out <= proximo_andar_interno(escolhido);
                direcao_out <= direcao_interna(escolhido);
            else
                elevadorEscolhido <= (others => '1');
            end if;
        else
            -- 3) H� um bot�o externo: escolha do elevador que atender� esse bot�o
            -- Primeiro tenta encontrar elevador na mesma dire��o e mais pr�ximo
            -- Se n�o houver nenhum na mesma dire��o, escolhe o elevador mais pr�ximo de qualquer dire��o
            escolhido := -1;
            tmp_dist := ULTIMO_ANDAR * 2; -- valor grande inicial para compara��o

            -- Primeiro passe: considerar apenas elevadores que j� estejam na mesma dire��o (ou que j� estejam no andar alvo)
            for i in 0 TO 2 loop
                andar_atual := to_integer(unsigned(andaresElevadores_in(i)));
                -- Se elevador j� est� indo na dire��o desejada OU j� est� no andar do pedido, considerar como candidato
                if (direcaoElevadores_in(i) = direcao_alvo) or (andar_atual = botao_alvo) then
                    distancias(i) := modulo_int(botao_alvo - andar_atual);
                    if distancias(i) < tmp_dist then
                        tmp_dist := distancias(i);
                        escolhido := i; -- marca candidato mais pr�ximo
                    end if;
                end if;
            end loop;

            -- Se n�o encontrou nenhum elevador na mesma dire��o, escolhe o mais pr�ximo independentemente da dire��o
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
            
            -- Atualiza sa�das com a escolha feita
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