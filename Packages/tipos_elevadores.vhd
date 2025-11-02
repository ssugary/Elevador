library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package Tipos_Elevadores is

    type matriz_andar is array (integer range <>) of std_logic_vector(4 DOWNTO 0);
    type matriz_seg7  is array (integer range<>)  of std_logic_vector(6 DOWNTO 0);
    type matriz_botoes is array (integer range <>) of STD_LOGIC_VECTOR(31 DOWNTO 0);
    type vector_integer is array (integer range <>) of integer;
    type t_estado is (IDLE, FECHANDO_PORTA, MOVER, CHEGOU_ANDAR, ABRINDO_PORTA);
    constant ULTIMO_ANDAR : integer := 31;
    function achar_acima(botoes: std_logic_vector; atual: integer) return integer;
    function achar_abaixo(botoes: std_logic_vector; atual: integer)return integer;
    function modulo_int(x : integer) return integer;
    function is_all_zero(vec: std_logic_vector) return boolean;
    function safe_to_vector(val     : integer;width   : natural) return std_logic_vector;
    function safe_to_integer(vec : std_logic_vector) return integer;
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
        if atual >= ULTIMO_ANDAR then
            return -1;
        end if;
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
        if atual <= 0 then
            return -1;
        end if;
        for i in atual - 1 downto 0 loop
            if botoes(i) = '1' then
                return i;
            end if;
        end loop;
        return -1;
    end function; 

function is_all_zero(vec: std_logic_vector) return boolean is
begin
    for i in vec'range loop
        if vec(i) /= '0' then
            return false;
        end if;
    end loop;
    return true;
end function;

function safe_to_vector(
    val     : integer;
    width   : natural
) return std_logic_vector is
    variable result : std_logic_vector(width-1 downto 0) := (others => '0');
begin
    -- Se o valor for fora do range ou indefinido (como 'U'), retorna 0
    if (val < 0) then
        result := (others => '0');
    else
        result := std_logic_vector(to_unsigned(val, width));
    end if;
    return result;
end function;

function safe_to_integer(vec : std_logic_vector) return integer is
    variable result : integer := 0;
    variable clean  : boolean := true;
begin
    for j in vec'range loop
        if vec(j) /= '0' and vec(j) /= '1' then
            clean := false;
        end if;
    end loop;
    if clean then
        result := to_integer(unsigned(vec));
    else
        result := 0;
    end if;
    return result;
end function;



end package body Tipos_Elevadores;