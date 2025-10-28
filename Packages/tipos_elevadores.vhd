library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package Tipos_Elevadores is
    type matriz_andar is array (integer range <>) of std_logic_vector(4 DOWNTO 0);
    type matriz_botoes is array (integer range <>) of STD_LOGIC_VECTOR(31 DOWNTO 0);
    type t_estado is (IDLE, FECHANDO_PORTA, MOVER, CHEGOU_ANDAR, ABRINDO_PORTA);
    constant ULTIMO_ANDAR : integer := 31;
    function achar_acima(botoes: std_logic_vector; atual: integer) return integer;
    function achar_abaixo(botoes: std_logic_vector; atual: integer)return integer;
    function modulo_int(x : integer) return integer;
end package;

package body Tipos_Elevadores is
    
function modulo_int(x : integer) return integer is 
    begin
        if x < 0 then 
            return -x;
        else
            return x;
        end if;
    end function;

function achar_acima(botoes: std_logic_vector; atual: integer) return integer is
    begin
        for i in atual + 1 to ULTIMO_ANDAR loop
            if botoes(i) = '1' then
                return i;
            end if;
        end loop;
        return -1;
    end function;

    -- Função para achar o próximo andar abaixo
    function achar_abaixo(botoes: std_logic_vector; atual: integer) return integer is
    begin
        for i in atual - 1 downto 0 loop
            if botoes(i) = '1' then
                return i;
            end if;
        end loop;
        return -1;
    end function; 


end package body Tipos_Elevadores;