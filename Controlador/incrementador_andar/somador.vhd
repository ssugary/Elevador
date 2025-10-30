library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity incrementer is
    generic (
        N : integer := 8
    );
    port (
        data_in  : in  std_logic_vector(N - 1 downto 0);
        data_out : out std_logic_vector(N - 1 downto 0)
    );
end entity incrementer;

architecture behavioral of incrementer is
begin
    data_out <= std_logic_vector(unsigned(data_in) + 1);
end architecture behavioral;
