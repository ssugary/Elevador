library IEEE;
use IEEE.std_logic_1164.all;
use work.Tipos_Elevadores.all;

entity Teclado is 
    port (
        botoes_in        : in STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0);   -- vetor com os botões internos pressionados
        andares_in       : in STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0);  -- vetor com os andares pendentes (o controlador principal do elevador vai
                                                        -- apagar os andares visitados)
        botao_abrir_in   : in STD_LOGIC;                  -- botão de abrir porta ('1' - apertado)
        botao_fechar_in  : in STD_LOGIC;                 -- botão de fechar porta ('1' - apertado)
        botao_motor_in   : in STD_LOGIC;                 -- botão de ligar/desligar o motor ('1' - ligar, '0' - desligar)

        abrir_porta_out  : out STD_LOGIC;                -- saída que diz se o controlador deve abrir a porta
        fechar_porta_out : out STD_LOGIC;               -- saída que diz se o controlador deve fechar a porta
        estado_motor_out : out STD_LOGIC;               -- saída que diz se o controlador deve ligar/desligar o motor
        andares_out : out STD_LOGIC_VECTOR(ULTIMO_ANDAR DOWNTO 0) -- vetor de pedidos pendentes
    );

    end entity Teclado;

    architecture Estructural of Teclado is
    begin
        process(botoes_in, andares_in, botao_abrir_in, botao_fechar_in, botao_motor_in) begin

            andares_out <= andares_in or botoes_in; -- adiciona novos pedidos sem alterar os pendentes

            abrir_porta_out <= botao_abrir_in;      --
            fechar_porta_out <= botao_fechar_in;    -- Repassam a informação do botão apertado para o controlador
            estado_motor_out <= botao_motor_in;     --
            
        end process;
    end Estructural;