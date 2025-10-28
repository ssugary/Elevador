library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.Tipos_Elevadores.all; 

entity Supervisor_Global is
    port (
        botoes_in            : in matriz_botoes(2 DOWNTO 0);
        botoes_subir_in      : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
        botoes_descer_in     : in std_logic_vector(ULTIMO_ANDAR DOWNTO 0);

        andaresElevadores_in : in matriz_andar(2 DOWNTO 0);
        direcaoElevadores_in : in std_logic_vector(2 DOWNTO 0);


        proximoAndar_out     : out std_logic_vector(4 DOWNTO 0);
        elevadorEscolhido    : out integer;
        direcao_out          : out std_logic

    );
end entity;

architecture Behavioral of Supervisor_Global is 

    component Supervisor_Unico 
        port(
            botoes_in        : in  std_logic_vector(ULTIMO_ANDAR DOWNTO 0);
            andarAtual_in    : in  std_logic_vector(4 DOWNTO 0);
            direcao_in       : in  std_logic;

            proximoAndar_out : out std_logic_vector(4 DOWNTO 0);
            direcao_out      : out std_logic
        );

    end component;
    signal proximo_andar_interno : matriz_andar(2 DOWNTO 0);
    signal direcao_interna       : std_logic_vector(2 DOWNTO 0);
begin


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


    process(andaresElevadores_in, direcaoElevadores_in, proximo_andar_interno, botoes_subir_in, botoes_descer_in)
        variable distancias     : integer_vector(0 TO 2);
        variable escolhido      : integer := -1;
        variable botao_alvo     : integer := -1;
        variable direcao_alvo   : std_logic;
        variable tmp_dist       : integer;
        variable andar_atual    : integer;
    begin
        -- Inicializa
        elevadorEscolhido <= 0;
        proximoAndar_out <= andaresElevadores_in(0);
        direcao_out <= direcaoElevadores_in(0);

        -- Escolha do botão de andar externo (subir ou descer)
        botao_alvo := achar_acima(botoes_subir_in, 0);
        direcao_alvo := '1';
        if botao_alvo = -1 then
            botao_alvo := achar_abaixo(botoes_descer_in, ULTIMO_ANDAR);
            direcao_alvo := '0';
        end if;

        -- Se não há botões externos, considera botões internos
        if botao_alvo = -1 then
            -- Escolhe elevador mais próximo de acordo com botões internos
            escolhido := 0;
            tmp_dist := modulo_int(to_integer(unsigned(proximo_andar_interno(0))) - to_integer(unsigned(andaresElevadores_in(0))));
            for i in 1 to 2 loop
                distancias(i) := modulo_int(to_integer(unsigned(proximo_andar_interno(i))) - to_integer(unsigned(andaresElevadores_in(i))));
                if distancias(i) < tmp_dist then
                    tmp_dist := distancias(i);
                    escolhido := i;
                end if;
            end loop;

            elevadorEscolhido <= escolhido;
            proximoAndar_out <= proximo_andar_interno(escolhido);
            direcao_out <= direcao_interna(escolhido);

        else
            -- Botões externos: escolhe o elevador mais próximo e na mesma direção
            escolhido := -1;
            tmp_dist := ULTIMO_ANDAR * 2; -- valor grande inicial
            for i in 0 TO 2 loop
                andar_atual := to_integer(unsigned(andaresElevadores_in(i)));
                if (direcaoElevadores_in(i) = direcao_alvo) or (andar_atual = botao_alvo) then
                    distancias(i) := modulo_int(botao_alvo - andar_atual);
                    if distancias(i) < tmp_dist then
                        tmp_dist := distancias(i);
                        escolhido := i;
                    end if;
                end if;
            end loop;

            -- Se nenhum elevador está na mesma direção, escolhe o mais próximo de qualquer forma
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

            elevadorEscolhido <= escolhido;
            proximoAndar_out <= std_logic_vector(to_unsigned(botao_alvo, proximoAndar_out'length));
            direcao_out <= direcao_alvo;
        end if;
    end process;
end Behavioral;
