library IEEE;
use IEEE.std_logic_1164.all;

entity Teclado is 
    port (
        CLK   : in STD_LOGIC;                           -- clock do sistema 
        RESET : in STD_LOGIC;                           -- sinal de reset
        botoes_in : in STD_LOGIC_VECTOR(31 DOWNTO 0);   -- vetor com os botões internos pressionados
        andares_in : in STD_LOGIC_VECTOR(31 DOWNTO 0);  -- vetor com os andares pendentes (o controlador principal do elevador vai
                                                        -- apagar os andares visitados)
        botao_abrir_in : in STD_LOGIC;                  -- botão de abrir porta ('1' - apertado)
        botao_fechar_in : in STD_LOGIC;                 -- botão de fechar porta ('1' - apertado)
        botao_motor_in  : in STD_LOGIC;                 -- botão de ligar/desligar o motor ('1' - ligar, '0' - desligar)

        abrir_porta_out : out STD_LOGIC;                -- saída que diz se o controlador deve abrir a porta
        fechar_porta_out : out STD_LOGIC;               -- saída que diz se o controlador deve fechar a porta
        estado_motor_out : out STD_LOGIC;               -- saída que diz se o controlador deve ligar/desligar o motor
        andares_out : out STD_LOGIC_VECTOR(31 DOWNTO 0) -- vetor de pedidos pendentes
    );

    end entity Teclado;

    architecture Behavioral of Teclado is
    begin
        process(CLK, RESET) begin
            if RESET = '1' then
                andares_out <= (others => '0');     -- limpa os valores atuais
                fechar_porta_out <= '0';
                abrir_porta_out <= '0';
                estado_motor_out <= '0';
            elsif rising_edge(CLK) then
                andares_out <= andares_in or botoes_in; -- adiciona novos pedidos sem alterar os pendentes

                abrir_porta_out <= botao_abrir_in;      --
                fechar_porta_out <= botao_fechar_in;    -- Repassam a informação do botão apertado para o controlador
                estado_motor_out <= botao_motor_in;     --
            end if; 
        end process;
    end Behavioral;